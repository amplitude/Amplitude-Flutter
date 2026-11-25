import 'package:flutter/widgets.dart';

import 'control_markers.dart';
import 'control_names.dart';
import 'hit_path.dart';

// How grouping works
//
// controlsHitBy hit-tests a pointer-down, walks the hit path from the root
// down and pairs the markers it finds into groups, one per control.
//
// - Marker (_ControlMarker): one widget of a control. Its MarkerKind,
//   from markerKindOf in control_markers.dart, names the widget it comes
//   from: controlSemantics, tapAction, mergeSemantics, selectableRegion or
//   detector. Every other widget is skipped.
// - Group (MarkerGroup): the markers the walk paired, such as the button's
//   Semantics and its GestureDetector above.
// - Control: a group that can be a target and that the tap reached.
//   controlsHitBy returns only these, less any a SelectableRegion's
//   detector takes the tap from.
// - _PathAbove: what the walk knows about the path above the current
//   element: the nearest marker, whether a Row, Column or Stack forks the
//   path between that marker and here, the tile the element is inside, and
//   whether it is inside a SelectableRegion's child.
// - Pairing: a marker joins the group of the marker directly above it when
//   nothing forks between them and that marker can still pair below.
//   Otherwise it starts a group of its own. A SelectableRegion pairs only
//   with its own detector, never with anything in its child. Each kind's
//   method in _ControlGrouper holds its other exceptions.

/// The controls [event] hit: the groups of markers on its hit path that can
/// be a target and that the tap reached, in element-tree order, each before
/// the controls nested in it.
///
/// A control hit after a SelectableRegion is left out. The region's own
/// detector joins the arena before it and takes the tap: a GestureDetector
/// or ListTile around a SelectionArea never runs on a tap on its text.
///
/// Hit-tests [event] itself, so call it once per pointer-down.
List<MarkerGroup> controlsHitBy(PointerDownEvent event) {
  final path = HitPath(event);
  final grouper = _ControlGrouper(path);
  path.walk(_PathAbove.none, grouper.visit);
  int? region;
  for (final group in grouper.groups) {
    final hit = group._hitIndex;
    if (hit != null &&
        group._has(MarkerKind.selectableRegion) &&
        (region == null || hit < region)) {
      region = hit;
    }
  }
  return [
    for (final group in grouper.groups)
      if (group._isControl && (region == null || group._hitIndex! < region))
        group,
  ];
}

/// Groups the markers on the hit path into controls, as the walk visits
/// each element after its parent. [visit] asks [_markerFor] whether the
/// element is a marker and returns what its children see. Each kind of
/// marker has its own method below.
class _ControlGrouper {
  _ControlGrouper(this._path);

  final HitPath _path;
  final groups = <MarkerGroup>[];

  _PathAbove visit(Element element, Element? parent, _PathAbove above) {
    final marker = _markerFor(element, parent, above);
    return above.forChildrenOf(element, marker);
  }

  /// The marker [element] is, already in a group, or null if it is layout or
  /// paint.
  _ControlMarker? _markerFor(
      Element element, Element? parent, _PathAbove above) {
    final kind = markerKindOf(element, parent);
    if (kind == null) return null;
    final marker = _ControlMarker(element, kind, _path.hitIndexOf(element));
    switch (kind) {
      case MarkerKind.controlSemantics:
        _controlSemantics(marker, parent, above);
      case MarkerKind.tapAction:
        _tapAction(marker, above);
      case MarkerKind.mergeSemantics || MarkerKind.selectableRegion:
        _startOpen(marker);
      case MarkerKind.detector:
        _detector(marker, above);
    }
    return marker;
  }

  /// A Semantics that marks a control: button, toggled, checked, enabled,
  /// textField or expanded.
  void _controlSemantics(
    _ControlMarker marker,
    Element? parent,
    _PathAbove above,
  ) {
    final markerDirectlyAbove = above.markerDirectlyAbove;
    final buildRoot = parent is StatelessElement || parent is StatefulElement;
    if (markerDirectlyAbove != null &&
        (markerDirectlyAbove.kind == MarkerKind.detector ||
            markerDirectlyAbove.kind == MarkerKind.controlSemantics) &&
        !buildRoot) {
      // Below its own handler (a ListTile's InkWell, a CupertinoButton's
      // detector, a toggle's), or the inner half of a checkbox: one
      // control. A Semantics that is the root of a component's build
      // starts a control of its own, so a GestureDetector wrapped around
      // a button stays a separate control.
      markerDirectlyAbove.group._add(marker);
      return;
    }
    final p = (marker.element.widget as Semantics).properties;
    if (markerDirectlyAbove != null &&
        markerDirectlyAbove.canPairBelow &&
        !above.reachesRegionChild(marker.element)) {
      _pair(markerDirectlyAbove, marker);
    } else if (above.enclosingTile != null &&
        (p.checked != null || p.toggled != null)) {
      // A composite tile's checkbox or switch is the tile's own, even
      // across the tile's slots. A button there (an IconButton in the
      // title) is still a control of its own.
      above.enclosingTile!._add(marker);
    } else {
      _start(marker);
    }
    marker.canPairBelow = true;
  }

  /// InkResponse's tap action: tappable, without saying what it is.
  void _tapAction(_ControlMarker marker, _PathAbove above) {
    final markerDirectlyAbove = above.markerDirectlyAbove;
    if (markerDirectlyAbove != null &&
        markerDirectlyAbove.canPairBelow &&
        !above.reachesRegionChild(marker.element)) {
      _pair(markerDirectlyAbove, marker);
    } else {
      _start(marker);
    }
    marker.canPairBelow = true;
  }

  /// An active gesture detector. It joins only a marker directly above it
  /// that can still pair below. Below another detector it is a control of
  /// its own: a GestureDetector in a button's child is deeper in the arena
  /// and wins the tap. Inside a SelectableRegion's child it is the app's,
  /// not the region's own detector.
  void _detector(_ControlMarker marker, _PathAbove above) {
    final markerDirectlyAbove = above.markerDirectlyAbove;
    if (markerDirectlyAbove != null &&
        markerDirectlyAbove.canPairBelow &&
        !above.reachesRegionChild(marker.element)) {
      _pair(markerDirectlyAbove, marker);
    } else {
      _start(marker);
    }
  }

  /// Starts a group with [marker], which can then pair with the marker
  /// directly below it.
  void _startOpen(_ControlMarker marker) {
    _start(marker);
    marker.canPairBelow = true;
  }

  void _start(_ControlMarker marker) {
    final group = MarkerGroup._();
    groups.add(group);
    group._add(marker);
  }

  /// [marker] joins the group of [markerAbove], which then can't pair below
  /// again: a marker pairs with at most one thing below it.
  void _pair(_ControlMarker markerAbove, _ControlMarker marker) {
    markerAbove.canPairBelow = false;
    markerAbove.group._add(marker);
  }
}

/// One control: the markers that pair into it.
class MarkerGroup {
  MarkerGroup._();

  /// Its markers, the highest on the path first.
  final _markers = <_ControlMarker>[];
  final _kinds = <MarkerKind>{};
  bool _button = false;
  bool _toggle = false;
  bool _checked = false;
  bool _textField = false;
  bool? _explicitEnabled;
  int? _hitIndex;

  void _add(_ControlMarker marker) {
    _markers.add(marker);
    _kinds.add(marker.kind);
    marker.group = this;
    final hit = marker.hitIndex;
    if (hit != null && (_hitIndex == null || hit < _hitIndex!)) {
      _hitIndex = hit;
    }
    final w = marker.element.widget;
    if (w is! Semantics) return;
    final p = w.properties;
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

  bool _has(MarkerKind kind) => _kinds.contains(kind);

  /// The first position any of its markers has on the hit-test path, or
  /// null if the tap didn't reach it: never null for a control. A lower
  /// index was hit first, which is also the order recognizers join the
  /// gesture arena. A component element (a button, a tile) has no render
  /// object of its own and stands in for its nearest descendant one.
  int? get hitIndex => _hitIndex;

  /// Whether it is a control: the tap reached it and it can be a target. A
  /// container (a SelectableRegion) owns what it builds but is never one.
  bool get _isControl =>
      _hitIndex != null &&
      !_has(MarkerKind.selectableRegion) &&
      (_has(MarkerKind.controlSemantics) || _has(MarkerKind.detector));

  /// Built a Semantics for itself, as opposed to a bare handler.
  bool get _hasSemantics =>
      _has(MarkerKind.controlSemantics) ||
      _has(MarkerKind.tapAction) ||
      _has(MarkerKind.mergeSemantics);

  /// False if any of the control's Semantics says it is disabled, true if
  /// one says it is enabled and none disagree, null if none say.
  bool? get explicitEnabled => _explicitEnabled;

  /// A text field's recognizers aren't plain tap recognizers, so it has no
  /// handler; it is enabled unless it says otherwise.
  bool get enabled =>
      _explicitEnabled != false &&
      (_has(MarkerKind.detector) || _textField || _explicitEnabled == true);

  String get _role {
    if (_textField) return 'TextField';
    if (_toggle) return 'Switch';
    if (_checked) return 'Checkbox';
    if (_button) return 'Button';
    return 'Control';
  }

  /// The element the control is reported as: the component that built it.
  /// A bare handler, or a control nothing names, is reported as its
  /// handler. Worked out on first read, so read it once grouping is done.
  late final Element reportedElement = _findReportedElement();

  Element _findReportedElement() {
    final handler = _markers
        .where((m) => m.kind == MarkerKind.detector)
        .firstOrNull
        ?.element;
    final top = _markers.first.element;
    if (!_hasSemantics) return handler ?? top;
    return controlElementOf(_markers.map((m) => m.element)) ?? handler ?? top;
  }

  /// What the control is called: its class name (`ElevatedButton`), or its
  /// role (`Button`) on obfuscated builds and for a Semantics written inline
  /// in app code. A bare handler is called by its detector's class.
  String get name => _hasSemantics
      ? controlNameOf(reportedElement, role: _role)
      : handlerNameOf(reportedElement.widget);
}

/// What the walk knows about the path above an element.
/// [_ControlGrouper.visit] builds one per element and hands it to the
/// element's children.
class _PathAbove {
  const _PathAbove({
    this.nearestMarker,
    this.forkedSinceMarker = false,
    this.enclosingTile,
    this.inRegionChild = false,
  });

  static const none = _PathAbove();

  /// The closest marker higher up the path.
  final _ControlMarker? nearestMarker;

  /// Whether a widget with several children (a Row, Column or Stack) sits
  /// between [nearestMarker] and here. A fork means the element is in one of
  /// several slots, not directly under the marker.
  final bool forkedSinceMarker;

  /// The group of the MergeSemantics the element is inside, such as a
  /// CheckboxListTile. The tile claims the checkbox or switch below it.
  final MarkerGroup? enclosingTile;

  /// Whether [nearestMarker] is a SelectableRegion and the path from it to
  /// here has passed through the region's child. Everything there is the
  /// app's content; the region's own detector sits between the region and
  /// its child.
  final bool inRegionChild;

  /// [nearestMarker] when nothing forks between it and here, otherwise null.
  /// Only this marker can be paired with.
  _ControlMarker? get markerDirectlyAbove =>
      forkedSinceMarker ? null : nearestMarker;

  /// Whether [element], whose parent this describes, is the child of the
  /// SelectableRegion [nearestMarker] or inside it.
  bool reachesRegionChild(Element element) {
    if (inRegionChild) return true;
    final region = nearestMarker?.element.widget;
    return region is SelectableRegion &&
        identical(element.widget, region.child);
  }

  /// What is above the children of [element], which is [marker] if it is one.
  _PathAbove forChildrenOf(Element element, _ControlMarker? marker) =>
      _PathAbove(
        nearestMarker: marker ?? nearestMarker,
        forkedSinceMarker:
            (marker == null && forkedSinceMarker) || childCount(element) > 1,
        enclosingTile: marker?.kind == MarkerKind.mergeSemantics
            ? marker!.group
            : enclosingTile,
        inRegionChild: marker == null && reachesRegionChild(element),
      );
}

/// A widget on the hit path that helps make up a control.
class _ControlMarker {
  _ControlMarker(this.element, this.kind, this.hitIndex);

  final Element element;
  final MarkerKind kind;

  /// Its position on the hit-test path, or null if the tap didn't hit it.
  final int? hitIndex;
  late MarkerGroup group;

  /// This marker hasn't paired with anything below it yet, so the next marker
  /// directly under it can join its group. Each marker pairs with at most one
  /// thing below it.
  bool canPairBelow = false;
}
