// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original hit-path checks, hidden-widget pruning and composite-tile
// handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'control_names.dart';
import 'fling_stops.dart';

/// Every control under [event] that could take the tap, in element-tree
/// order: each before the controls nested in it.
///
/// A control is made of the marks the walk pairs up on the hit path: the
/// Semantics boundary a control builds, its tap action, and its gesture
/// detector. A bare gesture detector with no Semantics is a control too.
///
/// [flingStops] starts watching each list the walk passes, so a later press
/// that stops one of them can be told apart.
List<HitControl> controlsHitBy(
  PointerDownEvent event, {
  required FlingStops flingStops,
}) {
  final path = _HitPath(event);
  final pairing = _Pairing();
  path.walk(flingStops, pairing.visit);
  final controls = <HitControl>[];
  for (final unit in pairing.units) {
    if (!unit.candidate) continue;
    // Null when this tap couldn't reach the control.
    int? hitIndex;
    for (final m in unit.marks) {
      final i = path.hitIndexOf(m.element);
      if (i != null && (hitIndex == null || i < hitIndex)) hitIndex = i;
    }
    if (hitIndex == null) continue;
    controls.add(HitControl._(unit, _elementOf(unit), hitIndex));
  }
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this._unit, this.element, this.hitIndex);

  final _Unit _unit;

  /// The element the control is reported as: the component that built it,
  /// or its gesture detector when it has no Semantics or nothing names it.
  final Element element;

  /// Its first position on the hit-test path. A lower index was hit first,
  /// which is also the order recognizers join the gesture arena.
  final int hitIndex;

  /// Whether it accepts input now.
  bool get enabled => _unit.enabled;

  /// Whether any of its Semantics says it is enabled or disabled. One that
  /// says nothing (a dropdown's selected item) is inert.
  bool get saysEnabled => _unit.explicitEnabled != null;

  /// Its class name (`ElevatedButton`), or its role (`Button`) on obfuscated
  /// builds and for a Semantics written inline in app code.
  String get name => _unit.isControl
      ? controlNameOf(element, role: _unit.role)
      : handlerNameOf(element.widget);
}

/// The element a control is reported as: the component that built it. A
/// bare handler, or a control nothing names, is reported as its handler.
Element _elementOf(_Unit unit) {
  final handler =
      unit.marks.where((m) => m.kind == _Kind.handler).firstOrNull?.element;
  if (!unit.isControl) return handler ?? unit.top.element;
  return controlElementOf(unit.marks.map((m) => m.element)) ??
      handler ??
      unit.top.element;
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
  void walk(
    FlingStops flingStops,
    void Function(Element element, Element? parent) visit,
  ) {
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
        flingStops.watch(position);
        if (flingStops.stoppedInThisTask(position)) return;
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

/// Pairs the marks on the hit path into controls, as [_HitPath.walk] visits
/// each element after its parent.
///
/// A mark is a Semantics boundary a control builds (button, toggled,
/// checked, enabled, textField or expanded), InkResponse's tap action, a
/// MergeSemantics, a SelectableRegion, or an active gesture detector. Each
/// boundary pairs with at most one thing next to it, so a control's own
/// handler joins it while a developer's handler in its child stays a
/// control of its own.
class _Pairing {
  final units = <_Unit>[];

  /// The path from the root to the element being visited, each with what
  /// its children see. The walk is depth-first, so a visited element's
  /// parent is on this path; OverlayPortal content's real parent isn't, and
  /// the content starts a path of its own.
  final _path = <(Element, _PathState)>[];

  void visit(Element element, Element? parent) {
    var i = _path.length - 1;
    while (i >= 0 && !identical(_path[i].$1, parent)) {
      i--;
    }
    final _PathState state;
    if (i >= 0) {
      state = _path[i].$2;
      _path.length = i + 1;
    } else {
      state = _PathState.root;
    }
    final above = state.above;
    final adjacent = above != null && !state.branched;
    final w = element.widget;
    _Mark? mark;

    if (w is Semantics && isControlBoundary(w.properties)) {
      final p = w.properties;
      mark = _Mark(element, _Kind.boundary);
      final buildRoot = parent is StatelessElement || parent is StatefulElement;
      if (adjacent &&
          (above.kind == _Kind.handler || above.kind == _Kind.boundary) &&
          !buildRoot) {
        // Below its own handler (a ListTile's InkWell, a CupertinoButton's
        // detector, a toggle's), or the inner half of a checkbox: one
        // control. A boundary that is the root of a component's build
        // starts a control of its own, so a GestureDetector wrapped around
        // a button stays a separate control.
        above.unit.add(mark, w);
      } else if (adjacent && above.openBelow) {
        above.openBelow = false;
        above.unit.add(mark, w);
        mark.openBelow = true;
      } else if (state.merge != null &&
          (p.checked != null || p.toggled != null)) {
        // A composite tile's checkbox or switch is the tile's own, even
        // across the tile's slots. A button there (an IconButton in the
        // title) is still a control of its own.
        state.merge!.add(mark, w);
        mark.openBelow = true;
      } else {
        _start(mark, w);
        mark.openBelow = true;
      }
    } else if (w is Semantics && isTapAction(w.properties)) {
      mark = _Mark(element, _Kind.action);
      if (adjacent && above.openBelow) {
        above.openBelow = false;
        above.unit.add(mark, w);
      } else {
        _start(mark, w);
      }
      mark.openBelow = true;
    } else if (w is MergeSemantics) {
      mark = _Mark(element, _Kind.merge);
      _start(mark);
      mark.openBelow = true;
    } else if (w is SelectableRegion) {
      // On Flutter 3.19 a SelectableRegion (what SelectionArea builds)
      // wraps its child in a translucent RawGestureDetector with a plain tap
      // recognizer that has onTapUp set. That detector is the region's own,
      // not a control: text under it reports nothing. The region claims the
      // first handler below it unless that handler is in its child.
      mark = _Mark(element, _Kind.container, regionChild: w.child);
      _start(mark);
      mark.openBelow = true;
    } else if (_isActiveHandler(w, parent)) {
      // A handler joins only an open boundary right above it. Below another
      // handler it is a control of its own: a GestureDetector in a button's
      // child is deeper in the arena and wins the tap.
      mark = _Mark(element, _Kind.handler);
      if (adjacent && above.openBelow && !_inRegionChild(above, element)) {
        above.openBelow = false;
        above.unit.add(mark);
      } else {
        _start(mark);
      }
    }

    _path.add((
      element,
      _PathState(
        mark ?? above,
        (mark == null && state.branched) || childCount(element) > 1,
        mark?.kind == _Kind.merge ? mark!.unit : state.merge,
      )
    ));
  }

  void _start(_Mark mark, [Semantics? semantics]) {
    final unit = _Unit(mark);
    units.add(unit);
    unit.add(mark, semantics);
  }

  /// Whether [handler] is inside the child of the SelectableRegion [mark],
  /// where it is the app's, not the region's own detector.
  static bool _inRegionChild(_Mark mark, Element handler) {
    final child = mark.regionChild;
    if (child == null) return false;
    var inside = identical(handler.widget, child);
    handler.visitAncestorElements((a) {
      if (identical(a, mark.element)) return false;
      inside = inside || identical(a.widget, child);
      return !inside;
    });
    return inside;
  }
}

/// What an element's children see on their path: the nearest mark above,
/// whether a branch lies between it and here, and the nearest MergeSemantics
/// control above.
class _PathState {
  const _PathState(this.above, this.branched, this.merge);

  static const root = _PathState(null, false, null);

  final _Mark? above;
  final bool branched;
  final _Unit? merge;
}

enum _Kind { boundary, action, merge, handler, container }

/// A widget on the hit path that helps make up a control.
class _Mark {
  _Mark(this.element, this.kind, {this.regionChild});

  final Element element;
  final _Kind kind;
  late _Unit unit;

  /// For a SelectableRegion, its child: what is inside it is the app's.
  final Widget? regionChild;

  /// Whether the next mark below, with no branch between, still pairs with
  /// this one. Each boundary pairs with at most one thing below it.
  bool openBelow = false;
}

/// One control: the marks that pair into it.
class _Unit {
  _Unit(this.top);

  /// The first mark, the highest on the path.
  final _Mark top;
  final marks = <_Mark>[];
  bool _boundary = false;
  bool _action = false;
  bool _merge = false;
  bool _container = false;
  bool _handler = false;
  bool _button = false;
  bool _toggle = false;
  bool _checked = false;
  bool _textField = false;

  /// False if any of the control's Semantics says it is disabled, true if
  /// one says it is enabled and none disagree, null if none say.
  bool? explicitEnabled;

  void add(_Mark mark, [Semantics? semantics]) {
    marks.add(mark);
    mark.unit = this;
    switch (mark.kind) {
      case _Kind.boundary:
        _boundary = true;
      case _Kind.action:
        _action = true;
      case _Kind.merge:
        _merge = true;
      case _Kind.handler:
        _handler = true;
      case _Kind.container:
        _container = true;
    }
    final p = semantics?.properties;
    if (p == null) return;
    if (p.button == true) _button = true;
    if (p.toggled != null) _toggle = true;
    if (p.checked != null) _checked = true;
    if (p.textField == true || p.currentValueLength != null) {
      _textField = true;
    }
    if (p.enabled == false) {
      explicitEnabled = false;
    } else if (p.enabled == true && explicitEnabled == null) {
      explicitEnabled = true;
    }
  }

  /// A container owns what it builds but is never a target.
  bool get candidate => !_container && (_boundary || _handler);

  /// Built a Semantics for itself, as opposed to a bare handler.
  bool get isControl => _boundary || _action || _merge;

  /// A text field's recognizers aren't plain tap recognizers, so it has no
  /// handler; it is enabled unless it says otherwise.
  bool get enabled =>
      explicitEnabled != false &&
      (_handler || _textField || explicitEnabled == true);

  String get role {
    if (_textField) return 'TextField';
    if (_toggle) return 'Switch';
    if (_checked) return 'Checkbox';
    if (_button) return 'Button';
    return 'Control';
  }
}
