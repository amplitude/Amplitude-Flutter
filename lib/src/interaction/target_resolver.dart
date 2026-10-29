// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

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

  /// The element a control is reported as.
  ///
  /// A bare handler is reported as itself. Otherwise this is the component
  /// that built the control's top mark: the first stateless or stateful
  /// ancestor that isn't widgets-library plumbing, then up through the
  /// components whose build returned it directly (from a private
  /// `_IconButtonM3` to the public `IconButton`, from `InkWell` to the
  /// `ListTile` that built it).
  ///
  /// The search passes only elements that don't lay anything out. A layout
  /// widget (Center, Padding) or a branch first means the Semantics was
  /// written inline in app code. If no mark of the control names it, the
  /// control is reported as its handler.
  static Element _elementOf(_Unit unit) {
    if (!unit.isControl) return unit.top.element;
    // From the top mark first. When something a control doesn't build sits
    // above it (an Autocomplete option's list wraps its Semantics in
    // IndexedSemantics), a lower mark, such as the InkWell's own, can still
    // name the control.
    for (final mark in unit.marks) {
      final found = _builderOf(mark.element);
      if (found != null) return found;
    }
    return unit.marks
            .where((m) => m.kind == _Kind.handler)
            .firstOrNull
            ?.element ??
        unit.top.element;
  }

  /// The component that built [start], or null if a layout widget or a
  /// branch comes first.
  static Element? _builderOf(Element start) {
    // The ancestors up to the first one with more than one child.
    final up = <Element>[];
    start.visitAncestorElements((a) {
      up.add(a);
      return _childCount(a) <= 1;
    });
    for (var i = 0; i < up.length; i++) {
      if (_childCount(up[i]) > 1) return null;
      if (_isNamedComponent(up[i])) return _outermostBuilder(up, i);
      // GestureDetector's private _GestureSemantics is its own.
      final builtByHandler = i + 1 < up.length &&
          (up[i + 1].widget is GestureDetector ||
              up[i + 1].widget is RawGestureDetector);
      if (!_isPassThrough(up[i]) && !builtByHandler) return null;
    }
    return null;
  }

  /// From `up[i]`, up through the components whose build returned it
  /// directly. A flagless `Semantics()` between two of them (PopupMenuButton
  /// wraps its IconButton in one) is passed over.
  static Element _outermostBuilder(List<Element> up, int i) {
    while (i + 1 < up.length) {
      if (_isNamedComponent(up[i + 1])) {
        i++;
      } else if (i + 2 < up.length &&
          _isFlagless(up[i + 1].widget) &&
          _isNamedComponent(up[i + 2])) {
        i += 2;
      } else {
        break;
      }
    }
    return up[i];
  }

  static bool _isNamedComponent(Element e) =>
      (e is StatelessElement || e is StatefulElement) && !_isPlumbing(e.widget);

  /// Widgets-library components that controls build around their parts.
  static bool _isPlumbing(Widget w) =>
      w is GestureDetector ||
      w is RawGestureDetector ||
      w is Focus ||
      w is Actions ||
      w is Shortcuts ||
      w is FocusableActionDetector ||
      w is ExcludeFocus ||
      w is Builder ||
      w is StatefulBuilder ||
      w is ListenableBuilder ||
      w is ValueListenableBuilder ||
      w is KeyedSubtree ||
      w is AnimatedDefaultTextStyle;

  /// Elements between a control's component and its Semantics that don't lay
  /// anything out: inherited and proxy elements, plumbing, and render
  /// widgets that only route pointers or semantics, or only paint.
  static bool _isPassThrough(Element e) {
    if (e is ProxyElement) return true;
    final w = e.widget;
    return _isPlumbing(w) ||
        w is MouseRegion ||
        w is Listener ||
        w is IgnorePointer ||
        w is AbsorbPointer ||
        w is TapRegion ||
        w is Semantics ||
        w is MergeSemantics ||
        w is ExcludeSemantics ||
        w is BlockSemantics ||
        // CupertinoSwitch fades its toggleable with Opacity.
        w is Opacity ||
        w is FadeTransition ||
        w is RepaintBoundary ||
        w is CustomPaint ||
        w is ClipRect ||
        w is ClipRRect ||
        w is ClipPath ||
        w is DecoratedBox ||
        w is ColoredBox;
  }

  static bool _isFlagless(Widget w) =>
      w is Semantics &&
      !_isControlBoundary(w.properties) &&
      !_isTapAction(w.properties);

  /// Obfuscated builds rename every type, the framework's included.
  static final bool _obfuscated = '$Semantics' != 'Semantics';

  static String _nameOf(Element element, _Unit unit) {
    final w = element.widget;
    if (!unit.isControl) {
      return _obfuscated
          ? (w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector')
          : _typeName(w);
    }
    if (_obfuscated ||
        w is Semantics ||
        w is GestureDetector ||
        w is RawGestureDetector) {
      return unit.role;
    }
    return _typeName(w);
  }

  /// The runtime type's name without type arguments (`DropdownButton<int>`
  /// is `DropdownButton`). A private name drops its underscore and a `With…`
  /// or `M2`/`M3` suffix: Flutter 3.19's `_ElevatedButtonWithIcon` is
  /// `ElevatedButton`.
  static String _typeName(Widget w) {
    var name = w.runtimeType.toString();
    final generic = name.indexOf('<');
    if (generic > 0) name = name.substring(0, generic);
    if (name.startsWith('_')) {
      name = name.replaceFirst(RegExp('^_+'), '');
      final m = RegExp(r'^(.+?)(With[A-Z]\w*|M[23])$').firstMatch(name);
      if (m != null) name = m.group(1)!;
    }
    return name;
  }

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

  static int _childCount(Element e) {
    var n = 0;
    e.visitChildElements((_) => n++);
    return n;
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

  /// What each visited element's children see on their path.
  final _below = <Element, _PathState>{};

  void visit(Element element, Element? parent) {
    final state = (parent == null ? null : _below[parent]) ?? _PathState.root;
    final above = state.above;
    final adjacent = above != null && !state.branched;
    final w = element.widget;
    _Mark? mark;

    if (w is Semantics && _isControlBoundary(w.properties)) {
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
    } else if (w is Semantics && _isTapAction(w.properties)) {
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

    _below[element] = _PathState(
      mark ?? above,
      (mark == null && state.branched) ||
          TargetResolver._childCount(element) > 1,
      mark?.kind == _Kind.merge ? mark!.unit : state.merge,
    );
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

/// A Semantics a control builds around itself. `currentValueLength` marks a
/// text field on Flutter 3.19, whose TextField sets no role flag; `expanded`
/// marks DropdownButton and PopupMenuButton.
bool _isControlBoundary(SemanticsProperties p) =>
    p.button == true ||
    p.toggled != null ||
    p.checked != null ||
    p.textField == true ||
    p.currentValueLength != null ||
    p.enabled != null ||
    p.expanded != null;

/// A Semantics with only a tap action: InkResponse's, around its
/// GestureDetector.
bool _isTapAction(SemanticsProperties p) =>
    p.onTap != null || p.onLongPress != null;

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
