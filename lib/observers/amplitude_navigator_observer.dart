import 'dart:async';

import 'package:flutter/widgets.dart';

import '../amplitude.dart';
import '../autocapture/autocapture.dart';
import '../events/base_event.dart';

/// Event type Amplitude uses for autocaptured screen views. Matches the native
/// iOS/Android SDK screen view event so events unify in the Amplitude UI.
const String screenViewedEventType = '[Amplitude] Screen Viewed';

/// Event property key Amplitude uses for the screen name.
const String screenNameProperty = '[Amplitude] Screen Name';

/// Derives a human-readable screen name from a route's [RouteSettings].
///
/// Return `null` to skip tracking the route.
typedef ScreenNameExtractor = String? Function(RouteSettings settings);

/// Default [ScreenNameExtractor] that uses the route's name.
String? defaultScreenNameExtractor(RouteSettings settings) => settings.name;

/// Default route filter. Only page-style routes are treated as screens, which
/// excludes dialogs, popups, and bottom sheets (typically anonymous
/// [ModalRoute]s).
bool defaultRouteFilter(Route<dynamic>? route) => route is PageRoute;

/// A [NavigatorObserver] that autocaptures Flutter screen views as
/// `[Amplitude] Screen Viewed` events.
///
/// A Flutter app runs inside a single native surface (one `FlutterViewController`
/// on iOS, one `FlutterActivity` on Android), so the native SDKs' `screenViews`
/// autocapture cannot observe Flutter route navigation. Attach this observer to
/// your app's [Navigator.observers] to autocapture screen views on every
/// platform, including web.
///
/// Capture is gated on the `screenViews` autocapture option of the [Amplitude]
/// instance passed in — if screen views are disabled the observer is a no-op.
/// Both attaching the observer AND enabling `screenViews` are required (Flutter
/// cannot inject a [NavigatorObserver] automatically).
///
/// The observer tracks Flutter route changes on every platform, including web.
/// This matters on web because a Flutter route change does not necessarily
/// change the browser URL, so route-only navigations would be missed by the
/// Browser SDK's URL-based `pageViews` autocapture.
///
/// On web, `pageViews` and this observer are independent. If you enable both, a
/// navigation that also changes the URL is captured as both
/// `[Amplitude] Page Viewed` and `[Amplitude] Screen Viewed`. To record a single
/// navigation event, disable the one you don't want — typically
/// `pageViews: PageViewsDisabled()` so the observer's route-based
/// `[Amplitude] Screen Viewed` is authoritative (keep `pageUrlEnrichment`
/// enabled to retain page-URL properties on the emitted events).
///
/// Screen names come from [RouteSettings.name] by default, so **routes must be
/// named** — via named routes, `RouteSettings(name: ...)`, or a router such as
/// go_router — to be captured. Routes with no name are skipped (with a debug-mode
/// log). Provide a custom [nameExtractor] to derive names another way.
///
/// ```dart
/// final analytics = Amplitude(Configuration(
///   apiKey: 'API_KEY',
///   autocapture: AutocaptureOptions(screenViews: true),
/// ));
///
/// MaterialApp(
///   navigatorObservers: [AmplitudeNavigatorObserver(analytics)],
///   // ...
/// );
/// ```
class AmplitudeNavigatorObserver extends NavigatorObserver {
  AmplitudeNavigatorObserver(
    this.amplitude, {
    this.nameExtractor = defaultScreenNameExtractor,
    this.routeFilter = defaultRouteFilter,
  });

  /// The Amplitude instance screen view events are tracked with.
  final Amplitude amplitude;

  /// Derives the screen name reported for a route.
  final ScreenNameExtractor nameExtractor;

  /// Decides whether a route should be tracked as a screen.
  final bool Function(Route<dynamic>? route) routeFilter;

  /// Whether screen view autocapture is enabled on [amplitude]'s configuration.
  bool get _enabled {
    return switch (amplitude.configuration.autocapture) {
      AutocaptureEnabled() => true,
      AutocaptureOptions(:final screenViews) => screenViews,
      AutocaptureDisabled() => false,
    };
  }

  void _trackScreenView(Route<dynamic>? route) {
    // Analytics must never interfere with navigation, so any failure here — a
    // throwing custom routeFilter/nameExtractor or a failed track call — is
    // swallowed and surfaced only in debug builds.
    try {
      if (!_enabled || route == null || !routeFilter(route)) {
        return;
      }
      final name = nameExtractor(route.settings);
      if (name == null || name.isEmpty) {
        assert(() {
          debugPrint(
              'AmplitudeNavigatorObserver: skipped a screen view because the '
              'route has no name. Give routes a name (named routes, '
              'RouteSettings(name: ...), or a custom nameExtractor) to capture '
              'them.');
          return true;
        }());
        return;
      }
      unawaited(
        amplitude
            .track(BaseEvent(
              screenViewedEventType,
              eventProperties: {screenNameProperty: name},
            ))
            .catchError(_onTrackError),
      );
    } catch (error, stackTrace) {
      _onTrackError(error, stackTrace);
    }
  }

  void _onTrackError(Object error, StackTrace stackTrace) {
    assert(() {
      debugPrint(
          'AmplitudeNavigatorObserver: failed to track $screenViewedEventType: '
          '$error');
      return true;
    }());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _trackScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Only treat a pop as a screen change when a page-level route was popped.
    // Dismissing a dialog, popup, or bottom sheet (a non-page route) does not
    // change the visible screen — the underlying page was already reported — so
    // popping one must not re-report `previousRoute`.
    if (routeFilter(route)) {
      _trackScreenView(previousRoute);
    }
  }
}
