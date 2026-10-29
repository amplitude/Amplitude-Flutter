// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'control_names.dart';
import 'hit_path.dart';

/// The Flutter control a pointer-down landed on.
class InteractionTarget {
  const InteractionTarget({
    required this.element,
    required this.enabled,
    required this.name,
    this.gestureSettings,
  });

  /// The element of the control that takes the tap: the component that
  /// built the control's Semantics, or the GestureDetector or
  /// RawGestureDetector of a handler that has none.
  final Element element;

  /// Whether the control currently accepts input.
  final bool enabled;

  /// The control's class name (`ElevatedButton`), or its role (`Button`) on
  /// obfuscated builds and for a Semantics written inline in app code.
  final String name;

  /// Gesture settings of the nearest [MediaQuery], if any.
  final DeviceGestureSettings? gestureSettings;
}

/// Picks the control a pointer-down landed on from the Semantics widgets,
/// gesture detectors and component names on the hit-test path.
///
/// It knows no Material or Cupertino type, so it reads Flutter's own
/// controls, `material_ui`, `cupertino_ui` and app controls the same way.
/// It reads widget configuration, never the semantics tree, so it works
/// with semantics off.
///
/// Known gaps:
/// - A control that builds no Semantics is reported as its gesture
///   detector: CupertinoListTile as its GestureDetector.
/// - A control that handles gestures in its render object is not reported:
///   Slider, and CupertinoSwitch on Flutter 3.19.
/// - On Flutter 3.19, a PopupMenuButton with a child is reported as its
///   InkWell: nothing in its Semantics marks it as a control.
/// - An item built straight into a Row (a TabBar tab, a NavigationBar
///   destination) is reported as its InkWell or GestureDetector.
/// - A SubmenuButton is reported as the TextButton it builds: the
///   MenuAnchor it puts between them hides which component built it.
/// - An app component whose build returns a control directly is reported
///   as that component: a `PrimaryButton` returning an ElevatedButton.
/// - Obfuscated builds name every control by its role.
class TargetResolver {
  const TargetResolver();

  InteractionTarget? resolve(PointerDownEvent event) {
    final path = HitPath.of(event);
    final controls = _Pairing();
    path.walk(controls.visit);

    Element? best;
    _Unit? bestUnit;
    var bestHitIndex = 0;
    var bestEnabled = true;
    // Between controls in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a control and one nested inside it, the
    // deeper one wins, except that a disabled control builds no recognizer,
    // so it can't take a tap from an enabled ancestor. A control with no
    // handler and no enabled flag (a dropdown's selected item) is inert and
    // never displaces an ancestor. Controls are listed ancestors first.
    for (final unit in controls.units) {
      if (!unit.candidate) continue;
      // Null when this tap couldn't reach the control.
      int? hitIndex;
      for (final m in unit.marks) {
        final i = path.hitIndexOf(m.element);
        if (i != null && (hitIndex == null || i < hitIndex)) hitIndex = i;
      }
      if (hitIndex == null) continue;
      final element = _elementOf(unit);
      final enabled = unit.enabled;
      final current = best;
      final bool wins;
      if (current == null) {
        wins = true;
      } else if (!_isAncestor(current, element)) {
        wins = hitIndex < bestHitIndex;
      } else {
        wins = enabled || (!bestEnabled && unit.explicitEnabled != null);
      }
      if (wins) {
        best = element;
        bestUnit = unit;
        bestHitIndex = hitIndex;
        bestEnabled = enabled;
      }
    }
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target,
      enabled: bestEnabled,
      name: _nameOf(target, bestUnit!),
      // Not MediaQuery.maybeOf: that would subscribe the app's own widget to
      // MediaQuery changes just because it was tapped.
      gestureSettings: target
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .gestureSettings,
    );
  }

  /// The element a control is reported as: the component that built it.
  /// A bare handler, or a control nothing names, is reported as its
  /// handler.
  static Element _elementOf(_Unit unit) {
    final handler =
        unit.marks.where((m) => m.kind == _Kind.handler).firstOrNull?.element;
    if (!unit.isControl) return handler ?? unit.top.element;
    return controlElementOf(unit.marks.map((m) => m.element)) ??
        handler ??
        unit.top.element;
  }

  static String _nameOf(Element element, _Unit unit) => unit.isControl
      ? controlNameOf(element, role: unit.role)
      : handlerNameOf(element.widget);

  /// A GestureDetector a primary tap reaches, or a RawGestureDetector one
  /// would, other than the one a GestureDetector builds.
  static bool _isActiveHandler(Widget w, Element? parent) {
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
  static bool _acceptsPrimaryTap(RawGestureDetector w) {
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



  static bool _isAncestor(Element ancestor, Element element) {
    var found = false;
    element.visitAncestorElements((e) {
      found = identical(e, ancestor);
      return !found;
    });
    return found;
  }
}

/// Pairs the marks on the hit path into controls, as [HitPath.walk] visits
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
    } else if (TargetResolver._isActiveHandler(w, parent)) {
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

    _path.add((element, _PathState(
      mark ?? above,
      (mark == null && state.branched) ||
          childCount(element) > 1,
      mark?.kind == _Kind.merge ? mark!.unit : state.merge,
    )));
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
