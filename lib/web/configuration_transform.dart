import '../constants.dart';

/// Autocapture keys that only apply to the native (iOS/Android) SDKs. The
/// Browser SDK ignores unknown keys, but they are stripped from the web
/// payload for cleanliness.
const List<String> _mobileOnlyAutocaptureKeys = [
  'appLifecycles',
  'deepLinks',
  'screenViews',
];

/// Transforms the cross-platform configuration map produced by
/// [Configuration.toMap] into the shape the Browser SDK expects.
///
/// Kept free of `dart:js_interop` so it can be unit tested under `flutter test`
/// without the `chrome` platform. [AmplitudeFlutterPlugin.getConfiguration]
/// calls this and then `jsify()`s the result.
Map<String, dynamic> transformWebConfiguration(Map<String, dynamic> input) {
  final config = Map<String, dynamic>.from(input);

  // defaultTracking is superseded by autocapture on web.
  config.remove('defaultTracking');

  // The Browser SDK expects a numeric LogLevel index, not a name.
  if (config['logLevel'] is String) {
    config['logLevel'] =
        LogLevel.values.byName(config['logLevel'] as String).index;
  }

  // The Browser SDK expects an uppercased server zone (US/EU).
  if (config['serverZone'] is String) {
    config['serverZone'] = (config['serverZone'] as String).toUpperCase();
  }

  // `AutocaptureDisabled` serializes the whole value as `false` (not a Map), so
  // it is left untouched here.
  //
  // `pageViews` is passed through exactly as configured. It is intentionally NOT
  // auto-disabled when `screenViews` is enabled: the AmplitudeNavigatorObserver
  // is opt-in and cannot be detected here, so disabling `pageViews` could leave a
  // web app that never attached the observer with no navigation autocapture at
  // all. See AmplitudeNavigatorObserver for how to avoid double-counting on web
  // (disable `pageViews` yourself when you rely on the observer).
  final autocapture = config['autocapture'];
  if (autocapture is Map) {
    final resolved = Map<String, dynamic>.from(autocapture);
    // Strip mobile-only autocapture keys the Browser SDK doesn't understand.
    for (final key in _mobileOnlyAutocaptureKeys) {
      resolved.remove(key);
    }
    config['autocapture'] = resolved;
  }

  return config;
}
