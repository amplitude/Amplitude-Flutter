import 'attribution.dart';
import 'page_views.dart';


/// Autocapture configuration.
///
/// Disable or enable autocapture by using class extensions [AutocaptureDisabled]/[AutocaptureEnabled],
/// or use [AutocaptureOptions] for more granular control.
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
/// Currently configuring autocapture is only supported on Web.
/// Refer to [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture) for more details.
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
  /// Web specific
  ///
  /// Whether to capture session start and end events.
  /// See https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-sessions
  final bool sessions;
  /// Web specific
  ///
  /// Configuration for autocapturing page view events using `PageViewsOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  /// for more information. Set to `false` to disable tracking page views.
  ///
  /// Can be either `PageViewsOptions` or `false`.
  final dynamic pageViews;

  const AutocaptureOptions({
    this.attribution = const AttributionOptions(),
    this.sessions = true,
    this.pageViews = const PageViewsOptions(),
  });

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': Attribution.toMapOrBool(attribution),
      'pageViews': PageViews.toMapOrBool(pageViews),
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

/// Enable autocapture.
///
/// Note: While the underlying Browser SDK takes in true, we opt to rather use a map as not all options are supported in Flutter.
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
  /// Web specific
  ///
  /// Whether to capture session start and end events.
  /// See https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-sessions
  final bool sessions = true;
  /// Web specific
  ///
  /// Configuration for autocapturing page view events using `PageViewsOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  /// for more information. Set to `false` to disable tracking page views.
  ///
  /// Can be either `PageViewsOptions` or `false`.
  final bool pageViews = true;

  const AutocaptureEnabled();

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': attribution,
      'pageViews': pageViews,
    };
  }
}
