import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppState extends InheritedWidget {
  const AppState({
    Key key,
    @required this.setMessage,
    @required Widget child,
  }) : super(key: key, child: child);

//  final AmplitudeFlutter analytics;
  final ValueSetter<String> setMessage;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  static AppState of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AppState);
  }
}
