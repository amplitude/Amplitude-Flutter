import 'package:flutter/widgets.dart';

import 'hit_controls.dart';
import 'interaction_target.dart';

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
  static InteractionTarget? resolve(PointerDownEvent event) {
    HitControl? best;
    for (final control in controlsHitBy(event)) {
      if (best == null || _takesTapFrom(control, best)) {
        best = control;
      }
    }
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target.element,
      enabled: target.enabled,
      name: target.name,
    );
  }

  /// Whether [later], which comes after [current] in the element tree,
  /// takes the tap from it.
  ///
  /// The gesture arena gives an unresolved tap to the first recognizer that
  /// joined it, and recognizers join in hit-test order, so the control hit
  /// first wins. That covers nesting too: a control is hit before the
  /// controls it is nested in. A disabled control builds no recognizer, so
  /// it never takes the tap from an enabled one. Between two disabled
  /// controls, the one that says it is disabled is reported. One that says
  /// nothing about being enabled (a dropdown's selected item) is inert and
  /// never takes the tap.
  static bool _takesTapFrom(HitControl later, HitControl current) =>
      later.hitIndex < current.hitIndex &&
      (later.enabled || (!current.enabled && later.hasExplicitEnabled));
}
