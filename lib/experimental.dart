/// **EXPERIMENTAL**: may change or be removed without notice, including in
/// a minor or patch release.
///
/// Opt-in import for experimental Amplitude features:
///
/// ```dart
/// import 'package:amplitude_flutter/experimental.dart';
/// ```
library;

/// **EXPERIMENTAL**: may change or be removed without notice.
///
/// Switches for features that are still being tried out. Each is off by
/// default, and the SDK has no remote config yet to turn them off in the
/// field, so an app only gets them by setting them here.
abstract final class AmplitudeExperimental {
  /// Whether element interactions are captured on iOS and Android.
  ///
  /// Off by default, so an app that enabled element interactions for web
  /// captures nothing new on mobile. When true, an Amplitude instance whose
  /// configuration enables element interactions captures taps on controls
  /// on iOS and Android. Web is unaffected.
  ///
  /// Each instance reads this once, when it's constructed, so set it
  /// before creating the instance. It can come from the app's own feature
  /// flag service:
  ///
  /// ```dart
  /// AmplitudeExperimental.mobileElementInteractions =
  ///     remoteConfig.getBool('amplitude_element_interactions');
  /// final amplitude = Amplitude(Configuration(
  ///   apiKey: 'your_api_key',
  ///   autocapture: const AutocaptureOptions(
  ///     elementInteractions: ElementInteractionsEnabled(),
  ///   ),
  /// ));
  /// ```
  static bool mobileElementInteractions = false;
}
