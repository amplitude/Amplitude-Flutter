import 'package:flutter/widgets.dart';

/// How a navigator observer names its routes, as in its
/// `[Amplitude] Screen Viewed` events.
final class RouteNaming {
  const RouteNaming({required this.isScreen, required this.screenNameOf});

  /// Whether a route is a screen. Dialogs and popups usually aren't.
  final bool Function(Route<dynamic> route) isScreen;

  /// A screen route's name, or null when it has none.
  final String? Function(Route<dynamic> route) screenNameOf;
}

/// The live routes an Amplitude instance's navigator observers have seen,
/// so a tap can find the route it's on: its Screen Name and the page that
/// ends its Hierarchy.
class ObservedRoutes {
  final _routes = <Route<dynamic>, _ObservedRoute>{};

  void didPush(
      Route<dynamic> route, Route<dynamic>? previous, RouteNaming naming) {
    _routes[route] = _ObservedRoute(naming, previous);
  }

  void didReplace(
      Route<dynamic>? newRoute, Route<dynamic>? oldRoute, RouteNaming naming) {
    final old = oldRoute == null ? null : _routes.remove(oldRoute);
    if (newRoute != null) {
      _routes[newRoute] = _ObservedRoute(naming, old?.previous);
    }
  }

  void didRemove(Route<dynamic> route) => _routes.remove(route);

  /// Each live route, by the element its page is built under. A tapped
  /// control's route is the first of these among its ancestors.
  Map<Element, Route<dynamic>> pages() {
    // A navigator that was itself removed disposes its routes without
    // popping them.
    _routes.removeWhere((route, _) => route.navigator == null);
    return {
      for (final route in _routes.keys)
        if (route case ModalRoute(subtreeContext: final Element page))
          page: route,
    };
  }

  /// [route]'s screen name. A route that isn't a screen, such as a dialog,
  /// takes the name of the screen it was shown over.
  String? screenNameOf(Route<dynamic> route) {
    final observed = _routes[route];
    if (observed == null) return null;
    if (observed.naming.isScreen(route)) {
      return observed.naming.screenNameOf(route);
    }
    final previous = observed.previous;
    return previous == null ? null : screenNameOf(previous);
  }
}

class _ObservedRoute {
  _ObservedRoute(this.naming, this.previous);

  final RouteNaming naming;

  /// The route this one was shown over, when it was pushed.
  final Route<dynamic>? previous;
}

/// Each Amplitude instance's observed routes. Null until an
/// `AmplitudeNavigatorObserver` for that instance sees a route.
final observedRoutes = Expando<ObservedRoutes>('Amplitude observed routes');
