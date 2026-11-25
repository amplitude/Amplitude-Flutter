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
  /// and Android, with no wrapper widget. Web is unaffected.
  ///
  /// Only these strings are read: a Material or Cupertino button's text,
  /// `Semantics` labels, tooltips and `Semantics.identifier`. Other text,
  /// such as a list tile's title or what's typed in a field, is never read.
  /// An app can still build these strings from user data
  /// (`Text('Continue as $email')`), so check them before opting in.
  /// Taps on disabled controls, keyboard activations and accessibility
  /// actions are not sent. `[Amplitude] Hierarchy` is cut at 1,024
  /// characters. On obfuscated builds controls are named by role
  /// (`Button`), and no Hierarchy or button text is sent.
  ///
  /// `[Amplitude] Screen Name` comes from `AmplitudeNavigatorObserver`: it's
  /// the name of the tapped control's route, as the observer names it in
  /// `[Amplitude] Screen Viewed`. Without the observer on the app's
  /// navigator (one per navigator, for nested navigators), taps carry no
  /// Screen Name and Hierarchy doesn't stop at the page. A tap in a dialog
  /// gets the name of the screen the dialog was opened over. `showDialog`
  /// opens it on the root navigator by default, so a dialog opened from a
  /// nested navigator gets the root navigator's screen. Taps made before
  /// the platform SDK finishes initializing aren't captured.
  ///
  /// A tap is sent with the user and device IDs current when it's read:
  /// after the control's own `onPressed` has run, except inside a list or
  /// other scrollable, where it's read first. So a log-out button that calls
  /// `setUserId(null)` sends its tap as the logged-out user on its own, and
  /// as the logged-in user in a list.
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
