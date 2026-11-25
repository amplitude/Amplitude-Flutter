import 'package:flutter/widgets.dart';

/// Which routes an `AmplitudeNavigatorObserver` counts as screens, and their
/// names, from its `routeFilter` and `nameExtractor`.
///
/// The callbacks are the app's own, so analytics never breaks navigation: a
/// throwing callback means "not a screen" or "no name", and a debug build
/// prints the error.
final class ScreenNaming {
  const ScreenNaming(this._routeFilter, this._nameExtractor);

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
