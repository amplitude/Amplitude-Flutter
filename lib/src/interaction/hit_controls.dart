// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original hit-path checks, hidden-widget pruning and composite-tile
// handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

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
// on the hit path from the root down. _ControlGrouper records each marker it
// passes and groups the markers into controls. TargetResolver then picks the
// control that takes the tap.
//
// - Marker (_ControlMarker): one widget of a control. Its _MarkerKind names
//   the widget it comes from: controlSemantics, tapAction, mergeSemantics,
//   selectableRegion or detector. Every other widget is skipped.
// - Group (_MarkerGroup): the markers that make up one control, such as
//   the button's Semantics and its GestureDetector above. A group the tap
//   reaches becomes a HitControl. Only candidate groups can be reported.
// - _PathAbove: what the walk knows about the path above the current
//   element: the nearest marker, whether a Row, Column or Stack forks the path
//   between that marker and here, and the tile the element is inside.
// - Pairing: a marker joins the group of the marker directly above it when
//   nothing forks between them and that marker can still pair below.
//   Otherwise it starts a group of its own. Each kind's method in
//   _ControlGrouper holds its exceptions.

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
  final grouper = _ControlGrouper();
  path.walk(grouper.visit);
  final controls = <HitControl>[];
  for (final group in grouper.groups) {
    if (!group.candidate) continue;
    // Null when this tap couldn't reach the control.
    int? hitIndex;
    for (final m in group.markers) {
      final i = path.hitIndexOf(m.element);
      if (i != null && (hitIndex == null || i < hitIndex)) {
        hitIndex = i;
      }
    }
    if (hitIndex == null) continue;
    controls.add(HitControl._(group, _elementOf(group), hitIndex));
  }
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this._group, this.element, this.hitIndex);

  final _MarkerGroup _group;

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

/// The element a control is reported as: the component that built it. A
/// bare handler, or a control nothing names, is reported as its handler.
Element _elementOf(_MarkerGroup group) {
  final handler = group.markers
      .where((m) => m.kind == _MarkerKind.detector)
      .firstOrNull
      ?.element;
  if (!group.hasSemantics) return handler ?? group.top.element;
  return controlElementOf(group.markers.map((m) => m.element)) ??
      handler ??
      group.top.element;
}

/// A GestureDetector a primary tap reaches, or a RawGestureDetector one
/// would, other than the one a GestureDetector builds.
bool isActiveHandler(Widget w, Element? parent) {
  if (w is GestureDetector) {
    // The callbacks for which it builds a TapGestureRecognizer. Long-press
    // and double-tap recognizers give up on a short press.
    return w.onTap != null ||
        w.onTapUp != null ||
        w.onTapDown != null ||
        w.onTapCancel != null;
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

/// Groups the markers on the hit path into controls, as [_HitPath.walk] visits
/// each element after its parent. [visit] finds what is above the element,
/// asks [_markerFor] whether the element is a marker, and records what its
/// children will see. Each kind of marker has its own method below.
class _ControlGrouper {
  final groups = <_MarkerGroup>[];

  /// The path from the root to the element being visited, each with what is
  /// above its children. The walk is depth-first, so a visited element's
  /// parent is on this path; OverlayPortal content's real parent isn't, and
  /// the content starts a path of its own.
  final _path = <(Element, _PathAbove)>[];

  void visit(Element element, Element? parent) {
    final above = _aboveChildrenOf(parent);
    final marker = _markerFor(element, parent, above);
    _path.add((element, above.forChildrenOf(element, marker)));
  }

  /// What is above [parent]'s children. Trims [_path] back to [parent], so
  /// it holds only the current element's ancestors.
  _PathAbove _aboveChildrenOf(Element? parent) {
    var i = _path.length - 1;
    while (i >= 0 && !identical(_path[i].$1, parent)) {
      i--;
    }
    if (i < 0) return _PathAbove.none;
    _path.length = i + 1;
    return _path[i].$2;
  }

  /// The marker [element] is, already in a group, or null if it is layout or
  /// paint.
  _ControlMarker? _markerFor(
      Element element, Element? parent, _PathAbove above) {
    final w = element.widget;
    if (w is Semantics && isControlBoundary(w.properties)) {
      return _controlSemantics(element, w, parent, above);
    }
    if (w is Semantics && isTapAction(w.properties)) {
      return _tapAction(element, w, above);
    }
    if (w is MergeSemantics) {
      return _startOpen(_ControlMarker(element, _MarkerKind.mergeSemantics));
    }
    if (w is SelectableRegion) {
      // On Flutter 3.19 a SelectableRegion (what SelectionArea builds)
      // wraps its child in a translucent RawGestureDetector with a plain tap
      // recognizer that has onTapUp set. That detector is the region's own,
      // not a control: text under it reports nothing. The region claims the
      // first handler below it unless that handler is in its child.
      return _startOpen(
        _ControlMarker(element, _MarkerKind.selectableRegion,
            regionChild: w.child),
      );
    }
    if (isActiveHandler(w, parent)) return _detector(element, above);
    return null;
  }

  /// A Semantics that marks a control: button, toggled, checked, enabled,
  /// textField or expanded.
  _ControlMarker _controlSemantics(
    Element element,
    Semantics w,
    Element? parent,
    _PathAbove above,
  ) {
    final marker = _ControlMarker(element, _MarkerKind.controlSemantics);
    final markerDirectlyAbove = above.markerDirectlyAbove;
    final buildRoot = parent is StatelessElement || parent is StatefulElement;
    if (markerDirectlyAbove != null &&
        (markerDirectlyAbove.kind == _MarkerKind.detector ||
            markerDirectlyAbove.kind == _MarkerKind.controlSemantics) &&
        !buildRoot) {
      // Below its own handler (a ListTile's InkWell, a CupertinoButton's
      // detector, a toggle's), or the inner half of a checkbox: one
      // control. A Semantics that is the root of a component's build
      // starts a control of its own, so a GestureDetector wrapped around
      // a button stays a separate control.
      markerDirectlyAbove.group.add(marker, w);
      return marker;
    }
    final p = w.properties;
    if (markerDirectlyAbove != null && markerDirectlyAbove.canPairBelow) {
      _pair(markerDirectlyAbove, marker, w);
    } else if (above.enclosingTile != null &&
        (p.checked != null || p.toggled != null)) {
      // A composite tile's checkbox or switch is the tile's own, even
      // across the tile's slots. A button there (an IconButton in the
      // title) is still a control of its own.
      above.enclosingTile!.add(marker, w);
    } else {
      _start(marker, w);
    }
    marker.canPairBelow = true;
    return marker;
  }

  /// InkResponse's tap action: tappable, without saying what it is.
  _ControlMarker _tapAction(Element element, Semantics w, _PathAbove above) {
    final marker = _ControlMarker(element, _MarkerKind.tapAction);
    final markerDirectlyAbove = above.markerDirectlyAbove;
    if (markerDirectlyAbove != null && markerDirectlyAbove.canPairBelow) {
      _pair(markerDirectlyAbove, marker, w);
    } else {
      _start(marker, w);
    }
    marker.canPairBelow = true;
    return marker;
  }

  /// An active gesture detector. It joins only a marker directly above it that
  /// can still pair below. Below another detector it is a control of its
  /// own: a GestureDetector in a button's child is deeper in the arena and
  /// wins the tap.
  _ControlMarker _detector(Element element, _PathAbove above) {
    final marker = _ControlMarker(element, _MarkerKind.detector);
    final markerDirectlyAbove = above.markerDirectlyAbove;
    if (markerDirectlyAbove != null &&
        markerDirectlyAbove.canPairBelow &&
        !_inRegionChild(markerDirectlyAbove, element)) {
      _pair(markerDirectlyAbove, marker);
    } else {
      _start(marker);
    }
    return marker;
  }

  /// Starts a group with [marker], which can then pair with the marker directly
  /// below it.
  _ControlMarker _startOpen(_ControlMarker marker) {
    _start(marker);
    marker.canPairBelow = true;
    return marker;
  }

  void _start(_ControlMarker marker, [Semantics? semantics]) {
    final group = _MarkerGroup(marker);
    groups.add(group);
    group.add(marker, semantics);
  }

  /// [marker] joins the group of [markerAbove], which then can't pair below
  /// again: a marker pairs with at most one thing below it.
  static void _pair(_ControlMarker markerAbove, _ControlMarker marker,
      [Semantics? semantics]) {
    markerAbove.canPairBelow = false;
    markerAbove.group.add(marker, semantics);
  }

  /// Whether [handler] is inside the child of the SelectableRegion [marker],
  /// where it is the app's, not the region's own detector.
  static bool _inRegionChild(_ControlMarker marker, Element handler) {
    final child = marker.regionChild;
    if (child == null) return false;
    var inside = identical(handler.widget, child);
    handler.visitAncestorElements((a) {
      if (identical(a, marker.element)) return false;
      inside = inside || identical(a.widget, child);
      return !inside;
    });
    return inside;
  }
}

/// What the walk knows about the path above an element. [_ControlGrouper.visit]
/// builds one per element and hands it to the element's children.
class _PathAbove {
  const _PathAbove(
      this.nearestMarker, this.forkedSinceMarker, this.enclosingTile);

  static const none = _PathAbove(null, false, null);

  /// The closest marker higher up the path.
  final _ControlMarker? nearestMarker;

  /// Whether a widget with several children (a Row, Column or Stack) sits
  /// between [nearestMarker] and here. A fork means the element is in one of
  /// several slots, not directly under the marker.
  final bool forkedSinceMarker;

  /// The group of the MergeSemantics the element is inside, such as a
  /// CheckboxListTile. The tile claims the checkbox or switch below it.
  final _MarkerGroup? enclosingTile;

  /// [nearestMarker] when nothing forks between it and here, otherwise null.
  /// Only this marker can be paired with.
  _ControlMarker? get markerDirectlyAbove =>
      forkedSinceMarker ? null : nearestMarker;

  /// What is above the children of [element], which is [marker] if it is one.
  _PathAbove forChildrenOf(Element element, _ControlMarker? marker) =>
      _PathAbove(
        marker ?? nearestMarker,
        (marker == null && forkedSinceMarker) || childCount(element) > 1,
        marker?.kind == _MarkerKind.mergeSemantics
            ? marker!.group
            : enclosingTile,
      );
}

/// Which widget a marker comes from.
enum _MarkerKind {
  /// A Semantics that marks a control: button, toggled, checked, enabled,
  /// textField or expanded.
  controlSemantics,

  /// InkResponse's tap-action Semantics: tappable, without saying what it is.
  tapAction,

  /// A MergeSemantics, which composite tiles such as CheckboxListTile build.
  mergeSemantics,

  /// A SelectableRegion, which SelectionArea builds.
  selectableRegion,

  /// A GestureDetector or RawGestureDetector that a primary tap reaches.
  detector,
}

/// A widget on the hit path that helps make up a control.
class _ControlMarker {
  _ControlMarker(this.element, this.kind, {this.regionChild});

  final Element element;
  final _MarkerKind kind;
  late _MarkerGroup group;

  /// For a SelectableRegion, its child: what is inside it is the app's.
  final Widget? regionChild;

  /// This marker hasn't paired with anything below it yet, so the next marker
  /// directly under it can join its group. Each marker pairs with at most one
  /// thing below it.
  bool canPairBelow = false;
}

/// One control: the markers that pair into it.
class _MarkerGroup {
  _MarkerGroup(this.top);

  /// The first marker, the highest on the path.
  final _ControlMarker top;
  final markers = <_ControlMarker>[];
  bool _controlSemantics = false;
  bool _tapAction = false;
  bool _mergeSemantics = false;
  bool _selectableRegion = false;
  bool _detector = false;
  bool _button = false;
  bool _toggle = false;
  bool _checked = false;
  bool _textField = false;

  /// False if any of the control's Semantics says it is disabled, true if
  /// one says it is enabled and none disagree, null if none say.
  bool? explicitEnabled;

  void add(_ControlMarker marker, [Semantics? semantics]) {
    markers.add(marker);
    marker.group = this;
    switch (marker.kind) {
      case _MarkerKind.controlSemantics:
        _controlSemantics = true;
      case _MarkerKind.tapAction:
        _tapAction = true;
      case _MarkerKind.mergeSemantics:
        _mergeSemantics = true;
      case _MarkerKind.detector:
        _detector = true;
      case _MarkerKind.selectableRegion:
        _selectableRegion = true;
    }
    final p = semantics?.properties;
    if (p == null) return;
    _button |= p.button == true;
    _toggle |= p.toggled != null;
    _checked |= p.checked != null;
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
  bool get candidate => !_selectableRegion && (_controlSemantics || _detector);

  /// Built a Semantics for itself, as opposed to a bare handler.
  bool get hasSemantics => _controlSemantics || _tapAction || _mergeSemantics;

  /// A text field's recognizers aren't plain tap recognizers, so it has no
  /// handler; it is enabled unless it says otherwise.
  bool get enabled =>
      explicitEnabled != false &&
      (_detector || _textField || explicitEnabled == true);

  String get role {
    if (_textField) return 'TextField';
    if (_toggle) return 'Switch';
    if (_checked) return 'Checkbox';
    if (_button) return 'Button';
    return 'Control';
  }
}
