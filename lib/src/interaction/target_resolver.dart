// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
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

  /// The element that takes the tap: the GestureDetector or
  /// RawGestureDetector the gesture arena gives it to.
  final Element element;

  /// Whether the control currently accepts input.
  final bool enabled;

  /// The class name of [element]'s widget (`GestureDetector`).
  final String name;

  /// Gesture settings of the nearest [MediaQuery], if any.
  final DeviceGestureSettings? gestureSettings;
}

/// Picks the gesture detector a pointer-down landed on by walking the
/// element tree along Flutter's hit-test path and keeping the one the
/// gesture arena would give the tap.
///
/// Known gaps:
/// - It reports the gesture detector, not the control that built it: a tap
///   on an ElevatedButton resolves to its InkWell's GestureDetector.
/// - A control that handles gestures in its render object is not reported:
///   Slider, and CupertinoSwitch on Flutter 3.19.
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

    void startUnit(_Mark mark) {
      final unit = _Unit(mark);
      units.add(unit);
      unit.add(mark);
    }

    // [above] is the nearest mark above on this path, and [branched] whether
    // an element with more than one child lies between it and here.
    void visit(Element element, Element? parent, _Mark? above, bool branched) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != event.viewId) return;
      // A component element has no render object of its own; this is its
      // nearest descendant render object. Pruning by the hit path also drops
      // hidden and blocked branches (Offstage, IgnorePointer and the like)
      // by their live render state. Their widget flags can be stale:
      // Scrollable toggles its IgnorePointer's render object directly.
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

      if (w is SelectableRegion) {
        // On Flutter 3.19 a SelectableRegion (what SelectionArea builds)
        // wraps its child in a translucent RawGestureDetector with a plain
        // tap recognizer that has onTapUp set. That detector is the
        // region's internal, not a target: text under it reports nothing.
        mark = _Mark(element, _Kind.container);
        startUnit(mark);
        mark.openBelow = true;
      } else if (_isActiveHandler(w, parent)) {
        // A handler under another handler is a target of its own: it is
        // deeper in the arena and wins the tap.
        mark = _Mark(element, _Kind.handler);
        if (adjacent && above.openBelow) {
          above.openBelow = false;
          above.unit.add(mark);
        } else {
          startUnit(mark);
        }
      }

      final childAbove = mark ?? above;
      final childBranched =
          (mark == null && branched) || _childCount(element) > 1;
      element.visitChildElements(
        (child) => visit(child, element, childAbove, childBranched),
      );
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null, null, false);

    Element? best;
    var bestHitIndex = 0;
    // Between handlers in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a handler and one nested inside it, the
    // deeper one wins.
    for (final unit in units) {
      if (!unit.candidate) continue;
      // Null when this tap couldn't reach the handler.
      int? hitIndex;
      for (final m in unit.marks) {
        final i = hitOrder[m.element.renderObject];
        if (i != null && (hitIndex == null || i < hitIndex)) hitIndex = i;
      }
      if (hitIndex == null) continue;
      final element = unit.top.element;
      final current = best;
      if (current == null ||
          _isAncestor(current, element) ||
          hitIndex < bestHitIndex) {
        best = element;
        bestHitIndex = hitIndex;
      }
    }
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target,
      enabled: true,
      name: _nameOf(target.widget),
      // Not MediaQuery.maybeOf: that would subscribe the app's own widget to
      // MediaQuery changes just because it was tapped.
      gestureSettings: target
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .gestureSettings,
    );
  }

  /// Obfuscated builds rename every type, the framework's included.
  static final bool _obfuscated = '$GestureDetector' != 'GestureDetector';

  static String _nameOf(Widget w) {
    if (_obfuscated) {
      return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
    }
    return _typeName(w);
  }

  /// The runtime type's name without type arguments. A private name drops
  /// its underscore.
  static String _typeName(Widget w) {
    var name = w.runtimeType.toString();
    final generic = name.indexOf('<');
    if (generic > 0) name = name.substring(0, generic);
    return name.replaceFirst(RegExp('^_+'), '');
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

  static bool _isAncestor(Element ancestor, Element element) {
    var found = false;
    element.visitAncestorElements((e) {
      found = identical(e, ancestor);
      return !found;
    });
    return found;
  }
}

enum _Kind { handler, container }

/// A widget on the hit path that takes part in the gesture arena.
class _Mark {
  _Mark(this.element, this.kind);

  final Element element;
  final _Kind kind;
  late _Unit unit;

  /// Whether the next handler below, with no branch between, belongs to
  /// this mark: a SelectableRegion's own detector.
  bool openBelow = false;
}

/// One tap target, or a container and the detector it owns.
class _Unit {
  _Unit(this.top);

  /// The first mark, the highest on the path.
  final _Mark top;
  final marks = <_Mark>[];
  bool _container = false;

  void add(_Mark mark) {
    marks.add(mark);
    mark.unit = this;
    if (mark.kind == _Kind.container) _container = true;
  }

  /// A container owns what it builds but is never a target.
  bool get candidate => !_container;
}
