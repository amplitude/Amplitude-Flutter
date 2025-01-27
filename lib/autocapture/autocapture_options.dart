import 'attribution_options.dart';
import 'page_views_options.dart';

/// Options for the autocapture feature.
///
/// Currently configuring autocapture is only supported on Web.
/// Refer to docs for more details.
///
/// * [Web](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture)
class AutocaptureOptions {
  /// Web specific
  ///
  /// Configures marketing attribution tracking using `AttributionOptions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-marketing-attribution)
  /// for more information. Set to `false` to disable tracking marketing attribution.
  ///
  /// Can be either `AttributionOptions` or `false`.
  final dynamic attribution;
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

  factory AutocaptureOptions.disabled() {
    return const AutocaptureOptions(
      attribution: false,
      sessions: false,
      pageViews: false,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> autocaptureOptions = {
      'sessions': sessions,
    };

    if (attribution is bool) {
      autocaptureOptions['attribution'] = attribution;
    } else {
      autocaptureOptions['attribution'] = (attribution as AttributionOptions).toMap();
    }

    if (pageViews is bool) {
      autocaptureOptions['pageViews'] = pageViews;
    } else {
      autocaptureOptions['pageViews'] = (pageViews as PageViewsOptions).toMap();
    }

    return autocaptureOptions;
  }
}
