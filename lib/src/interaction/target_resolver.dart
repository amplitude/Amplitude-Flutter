// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking by Zohaib Farooqi:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'fling_stops.dart';
import 'hit_controls.dart';

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

/// Picks the control a pointer-down landed on: the one, of those on
/// Flutter's hit-test path, that the gesture arena would give the tap.
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
abstract final class TargetResolver {
  static InteractionTarget? resolve(
    PointerDownEvent event, {
    required FlingStops flingStops,
  }) {
    HitControl? best;
    for (final control in controlsHitBy(event, flingStops: flingStops)) {
      final current = best;
      if (current == null || _beats(control, current)) best = control;
    }
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target.element,
      enabled: target.enabled,
      name: target.name,
      // Not MediaQuery.maybeOf: that would subscribe the app's own widget to
      // MediaQuery changes just because it was tapped.
      gestureSettings: target.element
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .gestureSettings,
    );
  }

  /// Whether [control] takes the tap from [best], which came before it.
  ///
  /// Between controls in different branches, such as a translucent overlay
  /// and the button beneath it, the one Flutter hit first wins, as it does
  /// in the gesture arena. Between a control and one nested inside it, the
  /// deeper one wins, except that a disabled control builds no recognizer,
  /// so it can't take a tap from an enabled ancestor. A control that says
  /// nothing about being enabled (a dropdown's selected item) is inert and
  /// never displaces an ancestor.
  static bool _beats(HitControl control, HitControl best) {
    if (!_isAncestor(best.element, control.element)) {
      return control.hitIndex < best.hitIndex;
    }
    return control.enabled || (!best.enabled && control.saysEnabled);
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
