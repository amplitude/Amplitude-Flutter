// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'scroll_stops.dart';

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

  static final _scrollStops = ScrollStops();

  InteractionTarget? resolve(PointerDownEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    // Position on the hit-test path, which is also the order recognizers
    // join the gesture arena: a lower index was hit first, and the arena
    // gives an unresolved tap to its first member.
    final hitOrder = <RenderObject, int>{};
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject) {
        hitOrder.putIfAbsent(target, () => hitOrder.length);
      }
    }
    // Only subtrees containing something Flutter hit can hold the target.
    // Following the hit path, rather than layout geometry, keeps content
    // that a Transform or SlideTransition moved outside its box.
    final searched = _hitPathAndAncestors(hitOrder.keys);
    final units = <_Unit>[];
    // OverlayPortal content already visited from its Overlay.
    final portalContent = <Element>{};

    void startUnit(_Mark mark, [Semantics? semantics]) {
      final unit = _Unit(mark);
      units.add(unit);
      unit.add(mark, semantics);
    }

    // [above] is the nearest mark above on this path, and [branched] whether
    // an element with more than one child lies between it and here. [merge]
    // is the nearest MergeSemantics control above.
    void visit(
      Element element,
      Element? parent,
      _Mark? above,
      bool branched,
      _Unit? merge,
    ) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != event.viewId) return;
      // A component element (a button, a tile) has no render object of its
      // own; this is its nearest descendant render object. Pruning by the
      // hit path also drops hidden and blocked branches (Offstage,
      // IgnorePointer and the like) by their live render state. Their
      // widget flags can be stale: Scrollable toggles its IgnorePointer's
      // render object directly.
      final ro = element.renderObject;
      if (ro != null && !searched.contains(ro)) return;
      // A press on a flinging list only stops it. Flutter's hit test ignored
      // the content, but the hold re-enabled it before this route ran.
      if (w is Scrollable && element is StatefulElement) {
        final position = (element.state as ScrollableState).position;
        _scrollStops.watch(position);
        if (_scrollStops.stoppedInThisTask(position)) return;
      }
      final adjacent = above != null && !branched;
      _Mark? mark;

      if (w is Semantics && _isControlBoundary(w.properties)) {
        final p = w.properties;
        mark = _Mark(element, _Kind.boundary);
        final buildRoot =
            parent is StatelessElement || parent is StatefulElement;
        if (adjacent &&
            (above.kind == _Kind.handler || above.kind == _Kind.boundary) &&
            !buildRoot) {
          // Below its own handler (a ListTile's InkWell, a CupertinoButton's
          // detector, a toggle's), or the inner half of a checkbox: one
          // control. A boundary that is the root of a component's build
          // starts a control of its own, so a GestureDetector wrapped
          // around a button stays a separate control.
          above.unit.add(mark, w);
        } else if (adjacent && above.openBelow) {
          above.openBelow = false;
          above.unit.add(mark, w);
          mark.openBelow = true;
        } else if (merge != null && (p.checked != null || p.toggled != null)) {
          // A composite tile's checkbox or switch is the tile's own, even
          // across the tile's slots. A button there (an IconButton in the
          // title) is still a control of its own.
          merge.add(mark, w);
          mark.openBelow = true;
        } else {
          startUnit(mark, w);
          mark.openBelow = true;
        }
      } else if (w is Semantics && _isTapAction(w.properties)) {
        mark = _Mark(element, _Kind.action);
        if (adjacent && above.openBelow) {
          above.openBelow = false;
          above.unit.add(mark, w);
        } else {
          startUnit(mark, w);
        }
        mark.openBelow = true;
      } else if (w is MergeSemantics) {
        mark = _Mark(element, _Kind.merge);
        startUnit(mark);
        mark.openBelow = true;
      } else if (w is SelectableRegion) {
        // On Flutter 3.19 a SelectableRegion (what SelectionArea builds)
        // wraps its child in a translucent RawGestureDetector with a plain
        // tap recognizer that has onTapUp set. That detector is the
        // region's internal, not a control: text under it reports nothing,
        // and a disabled button under it is still reported as itself.
        mark = _Mark(element, _Kind.container);
        startUnit(mark);
        mark.openBelow = true;
      } else if (_isActiveHandler(w, parent)) {
        // A handler joins only an open boundary right above it. Below
        // another handler it is a control of its own: a GestureDetector in
        // a button's child is deeper in the arena and wins the tap.
        mark = _Mark(element, _Kind.handler);
        if (adjacent && above.openBelow) {
          above.openBelow = false;
          above.unit.add(mark);
        } else {
          startUnit(mark);
        }
      }

      final childAbove = mark ?? above;
      final childMerge = mark?.kind == _Kind.merge ? mark!.unit : merge;
      final childBranched =
          (mark == null && branched) || _childCount(element) > 1;
      // Portal content the tap hit is visited from its Overlay, before the
      // overlay entries: the only ancestors visited before it are also its
      // render ancestors, and it competes with page content by hit order, as
      // in the gesture arena. It is a branch of its own, outside any
      // composite above the Overlay. The walk skips it if it reaches it
      // again through the page.
      if (w is Overlay) {
        for (final content in _hitPortalContent(element, searched)) {
          if (portalContent.add(content)) {
            visit(content, _parentOf(content), childAbove, true, null);
          }
        }
      }
      element.visitChildElements((child) {
        if (portalContent.isEmpty || !portalContent.contains(child)) {
          visit(child, element, childAbove, childBranched, childMerge);
        }
      });
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null, null, false, null);

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
    // never displaces an ancestor.
    for (final unit in units) {
      if (!unit.candidate) continue;
      // Null when this tap couldn't reach the control.
      int? hitIndex;
      for (final m in unit.marks) {
        final i = hitOrder[m.element.renderObject];
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

  static Element? _parentOf(Element e) {
    Element? parent;
    e.visitAncestorElements((a) {
      parent = a;
      return false;
    });
    return parent;
  }

  /// [hit] and all of their render-tree ancestors. Transforms hit-test
  /// their children without adding themselves to the result, so the
  /// ancestors are needed to reach what they hold.
  Set<RenderObject> _hitPathAndAncestors(Iterable<RenderObject> hit) {
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
  List<Element> _hitPortalContent(
    Element overlay,
    Set<RenderObject> searched,
  ) {
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
      } else if (holder != null && searched.contains(child)) {
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
  Element? _overlayChild(Element entry, RenderObject box) {
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

  static bool _isAncestor(Element ancestor, Element element) {
    var found = false;
    element.visitAncestorElements((e) {
      found = identical(e, ancestor);
      return !found;
    });
    return found;
  }
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
  _Mark(this.element, this.kind);

  final Element element;
  final _Kind kind;
  late _Unit unit;

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
