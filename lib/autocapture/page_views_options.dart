class PageViewsOptions {
  /// Web specific
  ///
  /// Provides advanced configuration options for tracking page views in a single-page application.
  ///
  /// Options:
  /// - `all`: Track page view events on any navigation change to the URL, including changes to the URL fragment.
  ///   For example, navigating from `https://amplitude.com/#company` to `https://amplitude.com/#blog`.
  ///
  /// - `pathOnly`: Track page view events only on navigation changes to the URL path.
  ///   For example, navigating from `https://amplitude.com/company` to `https://amplitude.com/blog`.
  ///
  /// If omitted, the default behavior is to track page view events on any navigation change to the URL.
  /// See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  final String? trackHistoryChanges;
  /// Web specific
  ///
  /// Customize the event_type for page view event. If no event_type is provided, the default event_type is
  /// `[Amplitude] Page Viewed`.
  final String? eventType;

  /// Web specific
  ///
  /// Configuration for autocapturing page view events.
  ///
  /// See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture) for more information.
  const PageViewsOptions({
    this.trackHistoryChanges = 'all',
    this.eventType = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'trackHistoryChanges': trackHistoryChanges,
      'eventType': eventType,
    };
  }
}
