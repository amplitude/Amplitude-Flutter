import 'package:flutter/widgets.dart';

/// The control a tap landed on, as the tap listeners receive it.
class InteractionTarget {
  const InteractionTarget({
    required this.element,
    required this.enabled,
    required this.name,
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
}
