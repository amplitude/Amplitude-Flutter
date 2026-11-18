// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original hit-path checks, hidden-widget pruning and composite-tile
// handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'control_grouper.dart';
import 'control_names.dart';
import 'fling_stops.dart';

// How this file works
//
// A control is made of several widgets. A tap on an ElevatedButton passes
// through these, and two of them matter:
//
//   ElevatedButton
//     Semantics(button: true)   <- a marker: says "a button, enabled"
//       Material, InkWell internals
//         GestureDetector       <- a marker: receives the tap
//           Padding, Text       (layout and paint, not markers)
//
// controlsHitBy hit-tests a pointer-down (_HitPath) and walks the elements
// on the hit path from the root down. ControlGrouper (control_grouper.dart)
// pairs the markers it passes into groups, one per control, and each group
// the tap reaches becomes a HitControl. TargetResolver then picks the
// control that takes the tap.

/// Every control under [event] that could take the tap, in element-tree
/// order: each before the controls nested in it.
///
/// A control is made of the markers the walk pairs up on the hit path: the
/// Semantics a control builds, its tap action, and its gesture
/// detector. A bare gesture detector with no Semantics is a control too.
///
/// The walk starts [FlingStops] watching each list it passes, so a later
/// press that stops one of them can be told apart.
List<HitControl> controlsHitBy(
  PointerDownEvent event,
) {
  final path = _HitPath(event);
  final grouper = ControlGrouper();
  path.walk(grouper.visit);
  final controls = <HitControl>[];
  for (final group in grouper.groups) {
    if (!group.candidate) continue;
    // Null when this tap couldn't reach the control.
    int? hitIndex;
    for (final element in group.elements) {
      final i = path.hitIndexOf(element);
      if (i != null && (hitIndex == null || i < hitIndex)) {
        hitIndex = i;
      }
    }
    if (hitIndex == null) continue;
    controls.add(HitControl._(group, group.reportedElement, hitIndex));
  }
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this._group, this.element, this.hitIndex);

  final MarkerGroup _group;

  /// The element the control is reported as: the component that built it,
  /// or its gesture detector when it has no Semantics or nothing names it.
  final Element element;

  /// Its first position on the hit-test path. A lower index was hit first,
  /// which is also the order recognizers join the gesture arena.
  final int hitIndex;

  /// Whether it accepts input now.
  bool get enabled => _group.enabled;

  /// Whether any of its Semantics says it is enabled or disabled. One that
  /// says nothing (a dropdown's selected item) is inert.
  bool get hasExplicitEnabled => _group.explicitEnabled != null;

  /// Its class name (`ElevatedButton`), or its role (`Button`) on obfuscated
  /// builds and for a Semantics written inline in app code.
  String get name => _group.hasSemantics
      ? controlNameOf(element, role: _group.role)
      : handlerNameOf(element.widget);
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
        if (FlingStops.instance.stoppedInThisTask(position)) return;
        FlingStops.instance.watch(position);
      }
      visit(element, parent);
      if (w is Overlay) {
        for (final content in _hitPortalContent(element)) {
          if (portalContent.add(content)) {
            step(content, _parentOf(content));
          }
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
      if (box != null) {
        entryOf[box] = entry;
      }
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
        if (found != null) {
          content.add(found);
        }
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
