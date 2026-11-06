// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original hit-path checks and hidden-widget pruning by Zohaib Farooqi and
// Wei Sun: https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Every control under [event] that could take the tap, in element-tree
/// order: each before the controls nested in it.
///
/// For now a control is a tap handler: a GestureDetector with a tap
/// callback, or a RawGestureDetector whose tap recognizer would take a
/// primary tap.
List<HitControl> controlsHitBy(
  PointerDownEvent event,
) {
  final path = _HitPath(event);
  final controls = <HitControl>[];
  path.walk((element, parent) {
    if (!_isActiveHandler(element.widget, parent)) return;
    final hitIndex = path.hitIndexOf(element);
    if (hitIndex != null) controls.add(HitControl._(element, hitIndex));
  });
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this.element, this.hitIndex);

  /// The element the control is reported as: its gesture detector.
  final Element element;

  /// Its position on the hit-test path. A lower index was hit first, which
  /// is also the order recognizers join the gesture arena.
  final int hitIndex;

  /// Its gesture detector's class name (`GestureDetector`).
  String get name => _nameOf(element.widget);
}

/// Obfuscated builds rename every type, the framework's included.
final bool _obfuscated = '$GestureDetector' != 'GestureDetector';

String _nameOf(Widget w) {
  if (_obfuscated) {
    return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
  }
  var name = w.runtimeType.toString();
  final generic = name.indexOf('<');
  if (generic > 0) name = name.substring(0, generic);
  return name.replaceFirst(RegExp('^_+'), '');
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
  void walk(void Function(Element element, Element? parent) visit) {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;

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
      visit(element, parent);
      element.visitChildElements((child) => step(child, element));
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
}
