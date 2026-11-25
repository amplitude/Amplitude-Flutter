import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';
import 'package:amplitude_flutter/src/interaction/observed_routes.dart';
import 'package:amplitude_flutter/src/screen_naming.dart';
import 'package:flutter/widgets.dart';

/// Records routes as `AmplitudeNavigatorObserver` does with its default
/// routeFilter and nameExtractor, without an Amplitude instance.
class RouteRecorder extends NavigatorObserver {
  final routes = ObservedRoutes();

  static const _naming =
      ScreenNaming(defaultRouteFilter, defaultScreenNameExtractor);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.didPush(route, previousRoute, _naming);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      routes.didReplace(newRoute, oldRoute, _naming);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.forgetDisposed();
}
