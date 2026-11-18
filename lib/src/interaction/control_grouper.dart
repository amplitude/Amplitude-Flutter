import 'package:flutter/widgets.dart';

import 'control_markers.dart';
import 'control_names.dart';

// How grouping works
//
// ControlGrouper is handed each element on the hit path, from the root
// down (hit_controls.dart walks it), and pairs the markers it finds into
// groups, one per control.
//
// - Marker (_ControlMarker): one widget of a control. Its _MarkerKind names
//   the widget it comes from: controlSemantics, tapAction, mergeSemantics,
//   selectableRegion or detector. control_markers.dart says which widgets
//   are markers. Every other widget is skipped.
// - Group (MarkerGroup): the markers that make up one control, such as
//   the button's Semantics and its GestureDetector above. A group the tap
//   reaches becomes a HitControl. Only candidate groups can be reported.
// - _PathAbove: what the walk knows about the path above the current
//   element: the nearest marker, whether a Row, Column or Stack forks the
//   path between that marker and here, and the tile the element is inside.
// - Pairing: a marker joins the group of the marker directly above it when
//   nothing forks between them and that marker can still pair below.
//   Otherwise it starts a group of its own. Each kind's method in
//   ControlGrouper holds its exceptions.

/// Groups the markers on the hit path into controls, as the walk visits
/// each element after its parent. [visit] finds what is above the element,
/// asks [_markerFor] whether the element is a marker, and records what its
/// children will see. Each kind of marker has its own method below.
class ControlGrouper {
  final groups = <MarkerGroup>[];

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
      markerDirectlyAbove.group._add(marker, w);
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
      above.enclosingTile!._add(marker, w);
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

  /// An active gesture detector. It joins only a marker directly above it
  /// that can still pair below. Below another detector it is a control of
  /// its own: a GestureDetector in a button's child is deeper in the arena
  /// and wins the tap.
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

  /// Starts a group with [marker], which can then pair with the marker
  /// directly below it.
  _ControlMarker _startOpen(_ControlMarker marker) {
    _start(marker);
    marker.canPairBelow = true;
    return marker;
  }

  void _start(_ControlMarker marker, [Semantics? semantics]) {
    final group = MarkerGroup._(marker);
    groups.add(group);
    group._add(marker, semantics);
  }

  /// [marker] joins the group of [markerAbove], which then can't pair below
  /// again: a marker pairs with at most one thing below it.
  static void _pair(_ControlMarker markerAbove, _ControlMarker marker,
      [Semantics? semantics]) {
    markerAbove.canPairBelow = false;
    markerAbove.group._add(marker, semantics);
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

/// One control: the markers that pair into it.
class MarkerGroup {
  MarkerGroup._(this._top);

  /// The first marker, the highest on the path.
  final _ControlMarker _top;
  final _markers = <_ControlMarker>[];
  bool _controlSemantics = false;
  bool _tapAction = false;
  bool _mergeSemantics = false;
  bool _selectableRegion = false;
  bool _detector = false;
  bool _button = false;
  bool _toggle = false;
  bool _checked = false;
  bool _textField = false;
  bool? _explicitEnabled;

  void _add(_ControlMarker marker, [Semantics? semantics]) {
    _markers.add(marker);
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
      _explicitEnabled = false;
    } else if (p.enabled == true && _explicitEnabled == null) {
      _explicitEnabled = true;
    }
  }

  /// The elements of its markers, highest first.
  Iterable<Element> get elements => _markers.map((m) => m.element);

  /// A container owns what it builds but is never a target.
  bool get candidate => !_selectableRegion && (_controlSemantics || _detector);

  /// Built a Semantics for itself, as opposed to a bare handler.
  bool get hasSemantics => _controlSemantics || _tapAction || _mergeSemantics;

  /// False if any of the control's Semantics says it is disabled, true if
  /// one says it is enabled and none disagree, null if none say.
  bool? get explicitEnabled => _explicitEnabled;

  /// A text field's recognizers aren't plain tap recognizers, so it has no
  /// handler; it is enabled unless it says otherwise.
  bool get enabled =>
      _explicitEnabled != false &&
      (_detector || _textField || _explicitEnabled == true);

  String get role {
    if (_textField) return 'TextField';
    if (_toggle) return 'Switch';
    if (_checked) return 'Checkbox';
    if (_button) return 'Button';
    return 'Control';
  }

  /// The element the control is reported as: the component that built it.
  /// A bare handler, or a control nothing names, is reported as its
  /// handler.
  Element get reportedElement {
    final handler = _markers
        .where((m) => m.kind == _MarkerKind.detector)
        .firstOrNull
        ?.element;
    if (!hasSemantics) return handler ?? _top.element;
    return controlElementOf(elements) ?? handler ?? _top.element;
  }
}

/// What the walk knows about the path above an element.
/// [ControlGrouper.visit] builds one per element and hands it to the
/// element's children.
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
  final MarkerGroup? enclosingTile;

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
  late MarkerGroup group;

  /// For a SelectableRegion, its child: what is inside it is the app's.
  final Widget? regionChild;

  /// This marker hasn't paired with anything below it yet, so the next marker
  /// directly under it can join its group. Each marker pairs with at most one
  /// thing below it.
  bool canPairBelow = false;
}
