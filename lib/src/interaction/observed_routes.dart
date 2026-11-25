import 'package:flutter/widgets.dart';

import '../screen_naming.dart';

/// The routes an Amplitude instance's navigator observers have seen, so a
/// tap can find the route it's on: its Screen Name and the page that ends
/// its Hierarchy. A route is kept until Flutter disposes it, not only until
/// it's popped: a button that closes its own dialog or page is read after
/// its `onPressed` has popped the route.
class ObservedRoutes {
  final _routes = <Route<dynamic>, _ObservedRoute>{};

  void didPush(
      Route<dynamic> route, Route<dynamic>? previous, ScreenNaming naming) {
    forgetDisposed();
    _routes[route] = _ObservedRoute(naming, previous);
  }

  void didReplace(
      Route<dynamic>? newRoute, Route<dynamic>? oldRoute, ScreenNaming naming) {
    if (newRoute != null) {
      _routes[newRoute] = _ObservedRoute(naming, _routes[oldRoute]?.previous);
    }
  }

  /// Each route that isn't disposed yet, including one animating out after
  /// a pop, by the element its page is built under. A tapped control's
  /// route is the first of these among its ancestors.
  Map<Element, Route<dynamic>> pages() {
    forgetDisposed();
    return {
      for (final route in _routes.keys)
        if (route case ModalRoute(subtreeContext: final Element page))
          page: route,
    };
  }

  @visibleForTesting
  int get length => _routes.length;

  /// Whether no navigator observer has recorded a route. With an observer
  /// installed, the page on screen is recorded before any tap on it.
  bool get isEmpty => _routes.isEmpty;

  /// Forgets routes Flutter has disposed: popped or removed ones, once
  /// their exit animation ends, and those of a navigator that was removed.
  /// A route that was just popped is still animating out, so it stays: a
  /// button that closes its own dialog or page is read after the pop.
  void forgetDisposed() =>
      _routes.removeWhere((route, _) => route.navigator == null);

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

  final ScreenNaming naming;

  /// The route this one was shown over, when it was pushed.
  final Route<dynamic>? previous;
}

/// Each Amplitude instance's observed routes. Set when the instance
/// captures taps; null otherwise, so its observers keep no routes.
final observedRoutes = Expando<ObservedRoutes>('Amplitude observed routes');
