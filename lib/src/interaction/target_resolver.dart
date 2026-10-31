// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking by Zohaib Farooqi:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
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

/// Picks the gesture detector a pointer-down landed on: the one, of those
/// on Flutter's hit-test path, that the gesture arena would give the tap.
///
/// Known gaps:
/// - It reports the gesture detector, not the control that built it: a tap
///   on an ElevatedButton resolves to its InkWell's GestureDetector.
/// - A control that handles gestures in its render object is not reported:
///   Slider, and CupertinoSwitch on Flutter 3.19.
class TargetResolver {
  const TargetResolver();

  InteractionTarget? resolve(PointerDownEvent event) {
    final path = HitPath.of(event);
    final handlers = <Element>[];
    path.walk((element, parent) {
      if (_isActiveHandler(element.widget, parent) &&
          !_ownedBySelectableRegion(element)) {
        handlers.add(element);
      }
    });

    // Between handlers in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a handler and one nested inside it, the
    // deeper one wins. The walk lists ancestors before their descendants.
    Element? best;
    var bestHitIndex = 0;
    for (final handler in handlers) {
      final hitIndex = path.hitIndexOf(handler);
      if (hitIndex == null) continue;
      final current = best;
      if (current == null ||
          _isAncestor(current, handler) ||
          hitIndex < bestHitIndex) {
        best = handler;
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

  /// On Flutter 3.19 a SelectableRegion (what SelectionArea builds) wraps
  /// its child in a translucent RawGestureDetector with a plain tap
  /// recognizer that has onTapUp set. That detector is the region's own,
  /// not a target, so text under it reports nothing. It sits between the
  /// region and the region's child; a handler inside the child is the
  /// app's and stays a target.
  static bool _ownedBySelectableRegion(Element handler) {
    final below = <Widget>[handler.widget];
    SelectableRegion? region;
    handler.visitAncestorElements((a) {
      final w = a.widget;
      if (w is SelectableRegion) {
        region = w;
        return false;
      }
      below.add(w);
      return true;
    });
    final r = region;
    return r != null && !below.any((w) => identical(w, r.child));
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
