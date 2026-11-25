import 'package:flutter/widgets.dart';

/// Which routes a navigator observer counts as screens, and their names, for
/// both its `[Amplitude] Screen Viewed` events and element interactions.
///
/// The callbacks are the app's own, so analytics never breaks navigation: a
/// throwing callback means "not a screen" or "no name", and a debug build
/// prints the error.
final class RouteNaming {
  const RouteNaming(this._routeFilter, this._nameExtractor);

  final bool Function(Route<dynamic>? route) _routeFilter;
  final String? Function(RouteSettings settings) _nameExtractor;

  /// Whether [route] is a screen. Dialogs and popups usually aren't.
  bool isScreen(Route<dynamic> route) {
    try {
      return _routeFilter(route);
    } catch (error) {
      _report('decide whether a route is a screen', error);
      return false;
    }
  }

  /// [route]'s screen name, or null when it has none.
  String? screenNameOf(Route<dynamic> route) {
    try {
      final name = _nameExtractor(route.settings);
      return name == null || name.isEmpty ? null : name;
    } catch (error) {
      _report('name a route', error);
      return null;
    }
  }

  static void _report(String action, Object error) {
    assert(() {
      debugPrint('AmplitudeNavigatorObserver: failed to $action: $error');
      return true;
    }());
  }
}

/// The routes an Amplitude instance's navigator observers have seen, so a
/// tap can find the route it's on: its Screen Name and the page that ends
/// its Hierarchy. A route is kept until Flutter disposes it, not only until
/// it's popped: a button that closes its own dialog or page is read after
/// its `onPressed` has popped the route.
class ObservedRoutes {
  final _routes = <Route<dynamic>, _ObservedRoute>{};

  void didPush(
      Route<dynamic> route, Route<dynamic>? previous, RouteNaming naming) {
    _forgetDisposed();
    _routes[route] = _ObservedRoute(naming, previous);
  }

  void didReplace(
      Route<dynamic>? newRoute, Route<dynamic>? oldRoute, RouteNaming naming) {
    if (newRoute != null) {
      _routes[newRoute] = _ObservedRoute(naming, _routes[oldRoute]?.previous);
    }
  }

  /// A route was popped. It stays until Flutter disposes it; routes that
  /// were disposed since are forgotten now.
  void didPop() => _forgetDisposed();

  /// Each route that isn't disposed yet, including one animating out after
  /// a pop, by the element its page is built under. A tapped control's
  /// route is the first of these among its ancestors.
  Map<Element, Route<dynamic>> pages() {
    _forgetDisposed();
    return {
      for (final route in _routes.keys)
        if (route case ModalRoute(subtreeContext: final Element page))
          page: route,
    };
  }

  @visibleForTesting
  int get length => _routes.length;

  /// Forgets routes Flutter has disposed: popped or removed ones, once
  /// their exit animation ends, and those of a navigator that was removed.
  void _forgetDisposed() =>
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

  final RouteNaming naming;

  /// The route this one was shown over, when it was pushed.
  final Route<dynamic>? previous;
}

/// Each Amplitude instance's observed routes. Set when the instance
/// captures taps; null otherwise, so its observers keep no routes.
final observedRoutes = Expando<ObservedRoutes>('Amplitude observed routes');
