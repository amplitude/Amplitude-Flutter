import 'package:flutter/widgets.dart';

/// The control a tap landed on, as the tap listeners receive it.
class InteractionTarget {
  const InteractionTarget({required this.element, required this.name});

  /// The element that takes the tap: the GestureDetector or
  /// RawGestureDetector the gesture arena gives it to.
  final Element element;

  /// The class name of [element]'s widget (`GestureDetector`).
  final String name;
}
