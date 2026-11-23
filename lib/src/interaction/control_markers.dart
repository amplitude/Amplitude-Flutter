// Which widgets are markers: the parts of a control that the hit walk looks
// for. controlsHitBy (control_grouper.dart) pairs them into controls.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Which part of a control a marker is.
enum MarkerKind {
  /// A Semantics that marks a control: button, toggled, checked, enabled,
  /// textField or expanded. See [isControlSemantics].
  controlSemantics,

  /// InkResponse's tap-action Semantics: tappable, without saying what it
  /// is. See [isTapAction].
  tapAction,

  /// A MergeSemantics, which composite tiles such as CheckboxListTile build.
  mergeSemantics,

  /// A SelectableRegion, which SelectionArea builds. It wraps its child in
  /// a detector of its own that takes any tap no handler in the child
  /// does, so text under it reports nothing and a handler around it never
  /// gets the tap. On Flutter 3.19 that detector is a RawGestureDetector
  /// with a plain tap recognizer, which the region claims: the first
  /// detector below it unless that detector is in its child.
  selectableRegion,

  /// A GestureDetector or RawGestureDetector that a primary tap reaches.
  detector,
}

/// The kind of marker [element] is, or null if it is layout or paint.
/// [parent] is its parent element.
MarkerKind? markerKindOf(Element element, Element? parent) {
  final w = element.widget;
  if (w is Semantics && isControlSemantics(w.properties)) {
    return MarkerKind.controlSemantics;
  }
  if (w is Semantics && isTapAction(w.properties)) return MarkerKind.tapAction;
  if (w is MergeSemantics) return MarkerKind.mergeSemantics;
  if (w is SelectableRegion) return MarkerKind.selectableRegion;
  if (_isDetector(w, parent)) return MarkerKind.detector;
  return null;
}

/// A Semantics a control builds around itself. `currentValueLength` marks a
/// text field on Flutter 3.19, whose TextField sets no role flag; `expanded`
/// marks DropdownButton and PopupMenuButton.
bool isControlSemantics(SemanticsProperties p) =>
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
bool _isDetector(Widget w, Element? parent) {
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
