import 'package:flutter/widgets.dart';

import 'control_grouper.dart';
import 'control_names.dart';
import 'hit_path.dart';
import 'interaction_target.dart';

// How resolving works
//
// A control is made of several widgets. A tap on an ElevatedButton passes
// through these, and two of them matter:
//
//   ElevatedButton
//     Semantics(button: true)   <- a marker: says "a button, enabled"
//       Material, InkWell internals
//         GestureDetector       <- a marker: receives the tap
//           Padding, Text       (layout and paint, not markers)
//
// 1. HitPath (hit_path.dart) hit-tests the pointer-down and walks the
//    elements on the hit path from the root down.
// 2. ControlGrouper (control_grouper.dart) pairs the markers the walk
//    passes into groups, one per control, each with its first position on
//    the hit path.
// 3. resolve picks the group the gesture arena would give the tap.

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
    final path = HitPath(event);
    final grouper = ControlGrouper(path.hitIndexOf);
    path.walk(grouper.visit);
    MarkerGroup? best;
    for (final control in grouper.groups) {
      if (!control.candidate || control.hitIndex == null) continue;
      if (best == null || _takesTapFrom(control, best)) {
        best = control;
      }
    }
    if (best == null) return null;
    final element = best.reportedElement;
    return InteractionTarget(
      element: element,
      enabled: best.enabled,
      name: best.hasSemantics
          ? controlNameOf(element, role: best.role)
          : handlerNameOf(element.widget),
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
  static bool _takesTapFrom(MarkerGroup later, MarkerGroup current) =>
      later.hitIndex! < current.hitIndex! &&
      (later.enabled || (!current.enabled && later.explicitEnabled != null));
}
