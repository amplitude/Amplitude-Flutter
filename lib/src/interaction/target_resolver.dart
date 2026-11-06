// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking by Zohaib Farooqi:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/widgets.dart';

import 'interaction_target.dart';
import 'tap_handlers.dart';

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
    // deeper one wins. Handlers come ancestors first.
    Element? best;
    var bestHitIndex = 0;
    for (final (handler, hitIndex) in tapHandlersHitBy(event)) {
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
    return InteractionTarget(element: target, name: _nameOf(target.widget));
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

  static bool _isAncestor(Element ancestor, Element element) {
    var found = false;
    element.visitAncestorElements((e) {
      found = identical(e, ancestor);
      return !found;
    });
    return found;
  }
}
