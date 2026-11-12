// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original hit-path checks and hidden-widget pruning by Zohaib Farooqi and
// Wei Sun: https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'fling_stops.dart';

/// Every control under [event] that could take the tap, in element-tree
/// order: each before the controls nested in it.
///
/// For now a control is a tap handler: a GestureDetector with a tap
/// callback, or a RawGestureDetector whose tap recognizer would take a
/// primary tap.
///
/// The walk starts [FlingStops] watching each list it passes, so a later
/// press that stops one of them can be told apart.
List<HitControl> controlsHitBy(
  PointerDownEvent event,
) {
  final path = _HitPath(event);
  final controls = <HitControl>[];
  path.walk((element, parent) {
    if (!_isActiveHandler(element.widget, parent) ||
        _ownedBySelectableRegion(element)) {
      return;
    }
    final hitIndex = path.hitIndexOf(element);
    if (hitIndex != null) controls.add(HitControl._(element, hitIndex));
  });
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this.element, this.hitIndex);

  /// The element the control is reported as: its gesture detector.
  final Element element;

  /// Its position on the hit-test path. A lower index was hit first, which
  /// is also the order recognizers join the gesture arena.
  final int hitIndex;

  /// Its gesture detector's class name (`GestureDetector`).
  String get name => _nameOf(element.widget);
}

/// Obfuscated builds rename every type, the framework's included.
final bool _obfuscated = '$GestureDetector' != 'GestureDetector';

String _nameOf(Widget w) {
  if (_obfuscated) {
    return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
  }
  var name = w.runtimeType.toString();
  final generic = name.indexOf('<');
  if (generic > 0) name = name.substring(0, generic);
  return name.replaceFirst(RegExp('^_+'), '');
}

/// A GestureDetector a primary tap reaches, or a RawGestureDetector one
/// would, other than the one a GestureDetector builds.
bool _isActiveHandler(Widget w, Element? parent) {
  if (w is GestureDetector) {
    return w.onTap != null ||
        w.onTapUp != null ||
        w.onTapDown != null ||
        w.onLongPress != null ||
        w.onDoubleTap != null;
  }
  if (w is RawGestureDetector) {
    if (parent?.widget is GestureDetector) return false;
    return _acceptsPrimaryTap(w);
  }
  return false;
}

/// Whether a primary-button tap would join the arena, the check
/// [TapGestureRecognizer.isPointerAllowed] makes. Other recognizer types,
/// such as the drag recognizers a Scrollable builds, don't count. The
/// recognizer's `supportedDevices` and `allowedButtonsFilter` are ignored.
/// A button built this way (CupertinoButton is one) keeps its tap
/// recognizer while disabled but sets every callback to null.
///
/// The check only ever initializes and disposes recognizers it just built.
/// A factory can hand out a recognizer the app already holds (`() => _tap`),
/// which may be in the arena for this very pointer; initializing or
/// disposing it would break the app's control. Such a factory says nothing.
bool _acceptsPrimaryTap(RawGestureDetector w) {
  for (final factory in w.gestures.values) {
    if (factory is! GestureRecognizerFactory<TapGestureRecognizer>) continue;
    try {
      final r = factory.constructor();
      final other = factory.constructor();
      if (identical(r, other)) continue;
      try {
        // A subclass can restrict where it accepts a pointer, as
        // Scrollbar's track recognizer does, so only a plain one counts.
        if (r.runtimeType != TapGestureRecognizer) continue;
        factory.initializer(r);
        if (r.onTapDown != null ||
            r.onTapUp != null ||
            r.onTap != null ||
            r.onTapCancel != null) {
          return true;
        }
      } finally {
        r.dispose();
        other.dispose();
      }
    } catch (_) {
      // A factory that can't be built off its widget says nothing.
    }
  }
  return false;
}

/// On Flutter 3.19 a SelectableRegion (what SelectionArea builds) wraps
/// its child in a translucent RawGestureDetector with a plain tap
/// recognizer that has onTapUp set. That detector is the region's own,
/// not a target, so text under it reports nothing. It sits between the
/// region and the region's child; a handler inside the child is the
/// app's and stays a target.
bool _ownedBySelectableRegion(Element handler) {
  final below = <Widget>[handler.widget];
  SelectableRegion? region;
  handler.visitAncestorElements((a) {
    final w = a.widget;
    if (w is SelectableRegion) {
      region = w;
      return false;
    }
    below.add(w);
    return true;
  });
  final r = region;
  return r != null && !below.any((w) => identical(w, r.child));
}

/// What a pointer-down hit: Flutter's hit-test path for it, and a walk of
/// the element tree along that path. Knows nothing about controls.
class _HitPath {
  /// Hit-tests [event] in its view, the way Flutter's gesture binding does.
  _HitPath(PointerDownEvent event) : _viewId = event.viewId {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, _viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject) {
        _hitOrder.putIfAbsent(target, () => _hitOrder.length);
      }
    }
    _searched = _withAncestors(_hitOrder.keys);
  }

  final int _viewId;

  /// Position on the hit-test path, which is also the order recognizers
  /// join the gesture arena: a lower index was hit first, and the arena
  /// gives an unresolved tap to its first member.
  final _hitOrder = <RenderObject, int>{};

  /// The render objects whose subtrees can hold the target: everything hit,
  /// and their ancestors. Following the hit path, rather than layout
  /// geometry, keeps content that a Transform or SlideTransition moved
  /// outside its box.
  late final Set<RenderObject> _searched;

  /// [element]'s position on the hit-test path, or null if the tap didn't
  /// hit it. A component element (a button, a tile) has no render object
  /// of its own and stands in for its nearest descendant one.
  int? hitIndexOf(Element element) => _hitOrder[element.renderObject];

  /// Calls [visit] for each element in the subtrees the tap hit, each
  /// before its children. [visit]'s `parent` is the element's parent, or
  /// null for the root.
  ///
  /// OverlayPortal content is visited from its Overlay, before the overlay
  /// entries, with its real parent: that parent lives in the page, which the
  /// walk may never visit. The only ancestors visited before the content are
  /// also its render ancestors, so it competes with page content by hit
  /// order, as in the gesture arena.
  void walk(void Function(Element element, Element? parent) visit) {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    final portalContent = <Element>{};

    void step(Element element, Element? parent) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != _viewId) return;
      // Pruning by the hit path also drops hidden and blocked branches
      // (Offstage, IgnorePointer and the like) by their live render state.
      // Their widget flags can be stale: Scrollable toggles its
      // IgnorePointer's render object directly.
      final ro = element.renderObject;
      if (ro != null && !_searched.contains(ro)) return;
      // A press on a flinging list only stops it. Flutter's hit test ignored
      // the content, but the hold re-enabled it before this route ran.
      if (w is Scrollable && element is StatefulElement) {
        final position = (element.state as ScrollableState).position;
        FlingStops.instance.watch(position);
        if (FlingStops.instance.stoppedInThisTask(position)) return;
      }
      visit(element, parent);
      if (w is Overlay) {
        for (final content in _hitPortalContent(element)) {
          if (portalContent.add(content)) step(content, _parentOf(content));
        }
      }
      element.visitChildElements((child) {
        // The walk skips portal content if it reaches it again through the
        // page.
        if (portalContent.isEmpty || !portalContent.contains(child)) {
          step(child, element);
        }
      });
    }

    step(root, null);
  }

  /// [hit] and all of their render-tree ancestors. Transforms hit-test
  /// their children without adding themselves to the result, so the
  /// ancestors are needed to reach what they hold.
  static Set<RenderObject> _withAncestors(Iterable<RenderObject> hit) {
    final searched = <RenderObject>{};
    for (final target in hit) {
      RenderObject? ro = target;
      // Stops at the first one already added: its ancestors are in too.
      while (ro != null && searched.add(ro)) {
        ro = ro.parent;
      }
    }
    return searched;
  }

  /// The elements of OverlayPortal content in [overlay] that the tap hit.
  ///
  /// A portal's overlay child is a render child of the Overlay, painted right
  /// after the overlay entry holding the portal, but its element stays under
  /// the portal. Flutter can hit the overlay child without hitting that
  /// entry, so the walk would prune the entry before reaching the content.
  List<Element> _hitPortalContent(Element overlay) {
    Element? theater;
    overlay.visitChildElements((e) => theater = e);
    final entryOf = <RenderObject, Element>{};
    theater?.visitChildElements((entry) {
      final box = entry.renderObject;
      if (box != null) entryOf[box] = entry;
    });
    final content = <Element>[];
    Element? entry;
    // In paint order: each entry, then the overlay children it hosts.
    theater?.renderObject?.visitChildren((child) {
      final next = entryOf[child];
      final holder = entry;
      if (next != null) {
        entry = next;
      } else if (holder != null && _searched.contains(child)) {
        final found = _overlayChild(holder, child);
        if (found != null) content.add(found);
      }
    });
    return content;
  }

  /// The element under [entry] whose render object is [box], an overlay
  /// child. Flutter keeps an overlay child deeper in the render tree than
  /// its OverlayPortal so the portal lays out first; nothing at [box]'s
  /// depth or deeper can lead to the portal.
  static Element? _overlayChild(Element entry, RenderObject box) {
    Element? found;
    void search(Element e) {
      if (found != null) return;
      if (e is RenderObjectElement) {
        if (identical(e.renderObject, box)) {
          found = e;
          return;
        }
        if (e.renderObject.depth >= box.depth) return;
      }
      e.visitChildElements(search);
    }

    search(entry);
    return found;
  }

  static Element? _parentOf(Element e) {
    Element? parent;
    e.visitAncestorElements((a) {
      parent = a;
      return false;
    });
    return parent;
  }
}
