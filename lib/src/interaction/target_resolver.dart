// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking by Zohaib Farooqi:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/widgets.dart';

import 'hit_controls.dart';
import 'interaction_target.dart';

/// Picks the gesture detector a pointer-down landed on: the one, of those
/// on Flutter's hit-test path, that the gesture arena would give the tap.
///
/// Known gaps:
/// - It reports the gesture detector, not the control that built it: a tap
///   on an ElevatedButton resolves to its InkWell's GestureDetector.
/// - A control that handles gestures in its render object is not reported:
///   Slider, and CupertinoSwitch on Flutter 3.19.
abstract final class TargetResolver {
  static InteractionTarget? resolve(PointerDownEvent event) {
    // Between handlers in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a handler and one nested inside it, the
    // deeper one wins. Controls come ancestors first.
    HitControl? best;
    for (final control in controlsHitBy(event)) {
      final current = best;
      if (current == null ||
          _isAncestor(current.element, control.element) ||
          control.hitIndex < current.hitIndex) {
        best = control;
      }
    }
    final target = best;
    if (target == null) return null;
    return InteractionTarget(element: target.element, name: target.name);
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
