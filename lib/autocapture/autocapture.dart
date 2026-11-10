import 'attribution.dart';
import 'element_interactions.dart';
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
  /// Configures autocapturing page view events. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#track-page-views)
  /// for more information.
  ///
  /// Use [PageViewsOptions] for granular control, or [PageViewsEnabled]/
  /// [PageViewsDisabled] to toggle it.
  ///
  /// Defaults to [PageViewsDisabled]. On Flutter, navigation is captured
  /// cross-platform by [AmplitudeNavigatorObserver] via [screenViews]
  /// (`[Amplitude] Screen Viewed`), which is consistent with iOS and Android;
  /// the web-only, URL-based page view autocapture is therefore opt-in so a
  /// navigation is not double-counted as both a screen view and a page view.
  /// Enable it (e.g. `pageViews: PageViewsOptions()`) if you also want the
  /// Browser SDK's `[Amplitude] Page Viewed` events.
  final PageViews pageViews;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to capture app lifecycle events (e.g., `[Amplitude] Application Started`,
  /// `[Amplitude] Application Installed`, `[Amplitude] Application Updated`).
  final bool appLifecycles;

  /// Mobile (Android) specific
  ///
  /// Whether to capture deep link events (`[Amplitude] Deep Link Opened`).
  final bool deepLinks;

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to capture screen view events (`[Amplitude] Screen Viewed`).
  ///
  /// On Flutter, screen views are delivered by attaching an
  /// `AmplitudeNavigatorObserver` to your app's `navigatorObservers`. The native
  /// SDK screen view autocapture cannot observe Flutter route navigation because
  /// a Flutter app runs inside a single native surface (one `FlutterViewController`
  /// on iOS, one `FlutterActivity` on Android).
  final bool screenViews;

  /// Web specific
  ///
  /// Whether to capture form interaction events (`[Amplitude] Form Started`,
  /// `[Amplitude] Form Submitted`).
  ///
  /// Exposed as a simple on/off toggle; unlike [elementInteractions], the
  /// Browser SDK's object configuration for form interactions is not surfaced by
  /// this Flutter SDK.
  ///
  /// Defaults to `false`. This is DOM-based capture and carries the Flutter web
  /// semantics requirement described on [elementInteractions]: text fields are
  /// only captured when they render as real `<input>`/`<form>` nodes in the
  /// accessibility tree.
  final bool formInteractions;

  /// Web specific
  ///
  /// Whether to capture file download events (`[Amplitude] File Downloaded`).
  ///
  /// Defaults to `false`. This is DOM-based capture and carries the Flutter web
  /// semantics requirement described on [elementInteractions]; downloads are only
  /// detected for real `<a download>` anchors, which Flutter web apps rarely
  /// render.
  final bool fileDownloads;

  /// Web specific
  ///
  /// Configures element interaction (click) tracking using `ElementInteractions`. See [docs](https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#autocapture)
  /// for more information. Set to `ElementInteractionsDisabled()` to disable tracking clicks.
  ///
  /// Disabled by default.
  ///
  /// > **Flutter web requirement.** DOM-based capture (this option,
  /// > [formInteractions], and [fileDownloads]) only sees real DOM nodes. With
  /// > the default CanvasKit renderer the UI is painted to a `<canvas>`, so the
  /// > Browser SDK can only observe elements from Flutter's accessibility
  /// > semantics tree, which must be enabled globally (e.g. via
  /// > `SemanticsBinding.instance.ensureSemantics()`). Enabling semantics
  /// > app-wide has a runtime cost and known side effects, so it is not
  /// > recommended unless your app already relies on semantics. Semantic widgets
  /// > render as `<flt-semantics>` nodes carrying ARIA roles rather than native
  /// > HTML tags, so [ElementInteractionsOptions] defaults its
  /// > `cssSelectorAllowlist` to a Flutter-aware set
  /// > ([ElementInteractionsOptions.defaultCssSelectorAllowlist]).
  ///
  /// Can be either `ElementInteractionsOptions`, `ElementInteractionsEnabled` or
  /// `ElementInteractionsDisabled`.
  final ElementInteractions elementInteractions;

  /// Web specific
  ///
  /// Whether to enrich events with page URL information (previous page, page
  /// type) and enrich page view events with additional URL data.
  ///
  /// Defaults to `false`. Requires Browser SDK >= 2.29.0 (older versions ignore
  /// the option). Enable it alongside [screenViews]/[pageViews] to attach
  /// page-URL properties to navigation events.
  final bool pageUrlEnrichment;

  const AutocaptureOptions({
    this.attribution = const AttributionOptions(),
    this.sessions = true,
    this.pageViews = const PageViewsDisabled(),
    this.appLifecycles = false,
    this.deepLinks = false,
    this.screenViews = false,
    this.formInteractions = false,
    this.fileDownloads = false,
    this.elementInteractions = const ElementInteractionsDisabled(),
    this.pageUrlEnrichment = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': Attribution.toMapOrBool(attribution),
      'pageViews': PageViews.toMapOrBool(pageViews),
      'appLifecycles': appLifecycles,
      'deepLinks': deepLinks,
      'screenViews': screenViews,
      'formInteractions': formInteractions,
      'fileDownloads': fileDownloads,
      'elementInteractions':
          ElementInteractions.toMapOrBool(elementInteractions),
      'pageUrlEnrichment': pageUrlEnrichment,
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

  /// Mobile (iOS and Android) specific
  ///
  /// Whether to capture screen view events (`[Amplitude] Screen Viewed`).
  final bool screenViews = true;

  /// Web specific
  ///
  /// Whether to capture form interaction events.
  final bool formInteractions = true;

  /// Web specific
  ///
  /// Whether to capture file download events.
  final bool fileDownloads = true;

  /// Web specific
  ///
  /// Whether to capture element interaction (click) events.
  final bool elementInteractions = true;

  /// Web specific
  ///
  /// Whether to enrich events with page URL information.
  final bool pageUrlEnrichment = true;

  const AutocaptureEnabled();

  Map<String, dynamic> toMap() {
    return {
      'sessions': sessions,
      'attribution': attribution,
      'pageViews': pageViews,
      'appLifecycles': appLifecycles,
      'deepLinks': deepLinks,
      'screenViews': screenViews,
      'formInteractions': formInteractions,
      'fileDownloads': fileDownloads,
      // Serialize via ElementInteractionsEnabled so the "enable everything"
      // sentinel applies the Flutter-aware cssSelectorAllowlist on web instead of
      // a bare `true` (which would capture no Flutter widgets).
      'elementInteractions':
          ElementInteractions.toMapOrBool(const ElementInteractionsEnabled()),
      'pageUrlEnrichment': pageUrlEnrichment,
    };
  }
}
