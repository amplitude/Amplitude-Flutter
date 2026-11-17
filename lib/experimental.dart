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
  /// sends nothing new on mobile. When true, an Amplitude instance whose
  /// configuration enables element interactions sends an
  /// `[Amplitude] Element Interacted` event for each tap on a control on iOS
  /// and Android. Web is unaffected.
  ///
  /// Each instance reads this once, when it's constructed, so set it
  /// before creating the instance. It can come from the app's own feature
  /// flag service.
  ///
  /// Capture needs the Flutter binding, as Amplitude's platform channel
  /// does: create the instance after `runApp` or
  /// `WidgetsFlutterBinding.ensureInitialized()`. Without the binding, the
  /// constructor throws when capture is on.
  ///
  /// ```dart
  /// WidgetsFlutterBinding.ensureInitialized();
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
