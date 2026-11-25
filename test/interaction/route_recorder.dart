import 'package:amplitude_flutter/src/interaction/observed_routes.dart';
import 'package:flutter/widgets.dart';

/// Records routes as `AmplitudeNavigatorObserver` does with its default
/// routeFilter and nameExtractor, without an Amplitude instance.
class RouteRecorder extends NavigatorObserver {
  final routes = ObservedRoutes();

  static final _naming = RouteNaming(
    isScreen: (route) => route is PageRoute,
    screenNameOf: (route) {
      final name = route.settings.name;
      return name == null || name.isEmpty ? null : name;
    },
  );

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.didPush(route, previousRoute, _naming);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      routes.didReplace(newRoute, oldRoute, _naming);
}
