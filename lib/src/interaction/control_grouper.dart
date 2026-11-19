import 'package:flutter/widgets.dart';

import 'control_markers.dart';
import 'control_names.dart';
import 'hit_path.dart';

// How grouping works
//
// groupControls walks the hit path from the root down and pairs the
// markers it finds into groups, one per control.
//
// - Marker (_ControlMarker): one widget of a control. Its MarkerKind,
//   from markerKindOf in control_markers.dart, names the widget it comes
//   from: controlSemantics, tapAction, mergeSemantics, selectableRegion or
//   detector. Every other widget is skipped.
// - Group (MarkerGroup): the markers that make up one control, such as
//   the button's Semantics and its GestureDetector above. Only candidate
//   groups the tap reaches can be reported.
// - _PathAbove: what the walk knows about the path above the current
//   element: the nearest marker, whether a Row, Column or Stack forks the
//   path between that marker and here, and the tile the element is inside.
// - Pairing: a marker joins the group of the marker directly above it when
//   nothing forks between them and that marker can still pair below.
//   Otherwise it starts a group of its own. Each kind's method in
//   _ControlGrouper holds its exceptions.

/// The controls on [path]: the markers the walk passes, paired into
/// groups, in element-tree order, each before the controls nested in it.
List<MarkerGroup> groupControls(HitPath path) {
  final grouper = _ControlGrouper(path.hitIndexOf);
  path.walk(_PathAbove.none, grouper.visit);
  return grouper.groups;
}

/// Groups the markers on the hit path into controls, as the walk visits
/// each element after its parent. [visit] asks [_markerFor] whether the
/// element is a marker and returns what its children see. Each kind of
/// marker has its own method below.
class _ControlGrouper {
  _ControlGrouper(this._hitIndexOf);

  final int? Function(Element element) _hitIndexOf;
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
    final marker = _ControlMarker(element, kind);
    return switch (kind) {
      MarkerKind.controlSemantics =>
        _controlSemantics(marker, element.widget as Semantics, parent, above),
      MarkerKind.tapAction =>
        _tapAction(marker, element.widget as Semantics, above),
      MarkerKind.mergeSemantics ||
      MarkerKind.selectableRegion =>
        _startOpen(marker),
      MarkerKind.detector => _detector(marker, above),
    };
  }

  /// A Semantics that marks a control: button, toggled, checked, enabled,
  /// textField or expanded.
  _ControlMarker _controlSemantics(
    _ControlMarker marker,
    Semantics w,
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
  _ControlMarker _tapAction(
      _ControlMarker marker, Semantics w, _PathAbove above) {
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
  _ControlMarker _detector(_ControlMarker marker, _PathAbove above) {
    final markerDirectlyAbove = above.markerDirectlyAbove;
    if (markerDirectlyAbove != null &&
        markerDirectlyAbove.canPairBelow &&
        !_inRegionChild(markerDirectlyAbove, marker.element)) {
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
    final group = MarkerGroup._(marker, _hitIndexOf);
    groups.add(group);
    group._add(marker, semantics);
  }

  /// [marker] joins the group of [markerAbove], which then can't pair below
  /// again: a marker pairs with at most one thing below it.
  void _pair(_ControlMarker markerAbove, _ControlMarker marker,
      [Semantics? semantics]) {
    markerAbove.canPairBelow = false;
    markerAbove.group._add(marker, semantics);
  }
}

/// Whether [handler] is inside the child of the SelectableRegion [marker],
/// where it is the app's, not the region's own detector.
bool _inRegionChild(_ControlMarker marker, Element handler) {
  final region = marker.element.widget;
  if (region is! SelectableRegion) return false;
  final child = region.child;
  var inside = identical(handler.widget, child);
  handler.visitAncestorElements((a) {
    if (identical(a, marker.element)) return false;
    inside = inside || identical(a.widget, child);
    return !inside;
  });
  return inside;
}

/// One control: the markers that pair into it.
class MarkerGroup {
  MarkerGroup._(this._top, this._hitIndexOf);

  /// The first marker, the highest on the path.
  final _ControlMarker _top;
  final int? Function(Element element) _hitIndexOf;
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
  int? _hitIndex;

  void _add(_ControlMarker marker, [Semantics? semantics]) {
    _markers.add(marker);
    marker.group = this;
    final hit = _hitIndexOf(marker.element);
    if (hit != null && (_hitIndex == null || hit < _hitIndex!)) {
      _hitIndex = hit;
    }
    switch (marker.kind) {
      case MarkerKind.controlSemantics:
        _controlSemantics = true;
      case MarkerKind.tapAction:
        _tapAction = true;
      case MarkerKind.mergeSemantics:
        _mergeSemantics = true;
      case MarkerKind.detector:
        _detector = true;
      case MarkerKind.selectableRegion:
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

  /// The first position any of its markers has on the hit-test path, or
  /// null if the tap didn't reach it. A lower index was hit first, which is
  /// also the order recognizers join the gesture arena. A component element
  /// (a button, a tile) has no render object of its own and stands in for
  /// its nearest descendant one.
  int? get hitIndex => _hitIndex;

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
        .where((m) => m.kind == MarkerKind.detector)
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
        marker?.kind == MarkerKind.mergeSemantics
            ? marker!.group
            : enclosingTile,
      );
}

/// A widget on the hit path that helps make up a control.
class _ControlMarker {
  _ControlMarker(this.element, this.kind);

  final Element element;
  final MarkerKind kind;
  late MarkerGroup group;

  /// This marker hasn't paired with anything below it yet, so the next marker
  /// directly under it can join its group. Each marker pairs with at most one
  /// thing below it.
  bool canPairBelow = false;
}
