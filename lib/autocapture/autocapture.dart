import 'attribution.dart';
import 'page_views.dart';

/// Autocapture configuration.
///
/// Disable or enable Flutter-supported autocapture options by using
/// [AutocaptureDisabled]/[AutocaptureEnabled], or use [AutocaptureOptions] for
/// more granular control.
sealed class Autocapture {
  const Autocapture();

  static dynamic toMapOrBool(Autocapture autocapture) {
    return switch (autocapture) {
      AutocaptureOptions() => autocapture.toMap(),
      AutocaptureEnabled() => autocapture.toMap(),
      AutocaptureDisabled() => false,
      Type() => throw UnimplementedError(),
    };
  }
}

/// Options for the autocapture feature.
///
/// Flutter supports the autocapture options exposed by this class. The
/// underlying Web, iOS, and Android SDKs may support additional autocapture
/// options that are not exposed by this Flutter SDK.
///
/// For platform behavior details, see:
/// [Web](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture-replaces-defaulttracking),
/// [iOS](https://amplitude.com/docs/sdks/analytics/ios/ios-swift-sdk#autocapture),
/// [Android](https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#autocapture).
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureOptions(
///             attribution: AttributionOptions(),
///             sessions: true,
///             pageViews: PageViewsOptions(),
///             appLifecycles: true,
///             deepLinks: true,
///         ),
///     )
/// );
/// ```
class AutocaptureOptions extends Autocapture {
  /// Web specific
  ///
  /// Configures marketing attribution tracking using `AttributionOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-marketing-attribution)
  /// for more information. Set to `false` to disable tracking marketing attribution.
  ///
  /// Can be either `AttributionOptions` or `false`.
  final Attribution attribution;

  /// Cross-platform
  ///
  /// Whether to capture session start and end events.
  /// See [Web docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-sessions).
  /// See [iOS docs](https://amplitude.com/docs/sdks/analytics/ios/ios-swift-sdk#track-sessions).
  /// See [Android docs](https://amplitude.com/docs/sdks/analytics/android/android-kotlin-sdk#track-sessions).
  final bool sessions;

  /// Web specific
  ///
  /// Configuration for autocapturing page view events using `PageViewsOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  /// for more information. Set to `false` to disable tracking page views.
  ///
  /// Can be either `PageViewsOptions` or `false`.
  final dynamic pageViews;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to capture app lifecycle events (e.g., `[Amplitude] Application Started`,
  /// `[Amplitude] Application Installed`, `[Amplitude] Application Updated`).
  final bool appLifecycles;

  /// Mobile (Android) specific
  ///
  /// Whether to capture deep link events (`[Amplitude] Deep Link Opened`).
  final bool deepLinks;

  const AutocaptureOptions({
    this.attribution = const AttributionOptions(),
    this.sessions = true,
    this.pageViews = const PageViewsOptions(),
    this.appLifecycles = false,
    this.deepLinks = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': Attribution.toMapOrBool(attribution),
      'pageViews': PageViews.toMapOrBool(pageViews),
      'appLifecycles': appLifecycles,
      'deepLinks': deepLinks,
    };
  }
}

/// Disable autocapture.
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureDisabled(),
///     )
/// );
/// ```
class AutocaptureDisabled extends Autocapture {
  const AutocaptureDisabled();
}

/// Enable all Flutter-supported autocapture options.
///
/// The underlying platform SDKs may support additional autocapture options that
/// are not exposed by this Flutter SDK. Each platform adapter translates only
/// the options it supports.
///
/// Example usage:
///
///```dart
/// var analytics = Amplitude(
///     Configuration(
///         apiKey: 'your_api_key',
///         autocapture: AutocaptureEnabled(),
///     )
/// );
/// ```
class AutocaptureEnabled extends Autocapture {
  /// Web specific
  ///
  /// Configures marketing attribution tracking using `AttributionOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-marketing-attribution)
  /// for more information. Set to `false` to disable tracking marketing attribution.
  ///
  /// Can be either `AttributionOptions` or `false`.
  final bool attribution = true;

  /// Cross-platform
  ///
  /// Whether to capture session start and end events.
  final bool sessions = true;

  /// Web specific
  ///
  /// Configuration for autocapturing page view events using `PageViewsOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  /// for more information. Set to `false` to disable tracking page views.
  ///
  /// Can be either `PageViewsOptions` or `false`.
  final bool pageViews = true;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to capture app lifecycle events (e.g., `[Amplitude] Application Started`,
  /// `[Amplitude] Application Installed`, `[Amplitude] Application Updated`).
  final bool appLifecycles = true;

  /// Mobile (Android) specific
  ///
  /// Whether to capture deep link events (`[Amplitude] Deep Link Opened`).
  final bool deepLinks = true;

  const AutocaptureEnabled();

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': attribution,
      'pageViews': pageViews,
      'appLifecycles': appLifecycles,
      'deepLinks': deepLinks,
    };
  }
}
