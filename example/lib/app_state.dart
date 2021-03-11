import 'package:amplitude_flutter/amplitude.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppState extends InheritedWidget {
  const AppState({
    Key? key,
    required this.analytics,
    required this.setMessage,
    required Widget child,
  }) : super(key: key, child: child);

  final Amplitude analytics;
  final ValueSetter<String> setMessage;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>()!;
  }
}
