// Which widgets are markers: the parts of a control that the hit walk looks
// for. ControlGrouper (control_grouper.dart) pairs them into controls.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A Semantics a control builds around itself. `currentValueLength` marks a
/// text field on Flutter 3.19, whose TextField sets no role flag; `expanded`
/// marks DropdownButton and PopupMenuButton.
bool isControlBoundary(SemanticsProperties p) =>
    p.button == true ||
    p.toggled != null ||
    p.checked != null ||
    p.textField == true ||
    p.currentValueLength != null ||
    p.enabled != null ||
    p.expanded != null;

/// A Semantics with only a tap action: InkResponse's, around its
/// GestureDetector.
bool isTapAction(SemanticsProperties p) =>
    p.onTap != null || p.onLongPress != null;

/// A GestureDetector a primary tap reaches, or a RawGestureDetector one
/// would, other than the one a GestureDetector builds.
bool isActiveHandler(Widget w, Element? parent) {
  if (w is GestureDetector) {
    // The callbacks for which it builds a TapGestureRecognizer. Long-press
    // and double-tap recognizers give up on a short press.
    return w.onTap != null ||
        w.onTapUp != null ||
        w.onTapDown != null ||
        w.onTapCancel != null;
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
