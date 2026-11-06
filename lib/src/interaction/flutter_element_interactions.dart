import 'package:flutter/foundation.dart';

import '../../autocapture/autocapture.dart';
import '../../autocapture/element_interactions.dart';
import '../../configuration.dart';
import 'pointer_observer.dart';
import 'target_resolver.dart';

/// Element interaction capture for one Amplitude instance on iOS and
/// Android.
///
/// For now each tap on a control is only logged, in debug builds.
abstract final class FlutterElementInteractions {
  /// Starts capturing taps if [configuration] enables element interactions
  /// on this platform. Returns a function that stops it, or null when
  /// nothing was started.
  static VoidCallback? register(Configuration configuration) {
    if (!_capturesTaps(configuration.autocapture)) return null;
    return PointerObserver.instance.subscribe(_onTap);
  }

  /// Web keeps the Browser SDK's DOM capture. On iOS and Android any
  /// element interaction setting but disabled captures taps: the CSS
  /// options only apply to web, and an app tuning them shouldn't silently
  /// lose mobile capture.
  static bool _capturesTaps(Autocapture autocapture) =>
      !kIsWeb &&
      switch (autocapture) {
        AutocaptureEnabled() => true,
        AutocaptureDisabled() => false,
        AutocaptureOptions(:final elementInteractions) =>
          elementInteractions is! ElementInteractionsDisabled,
      };

  static void _onTap(InteractionTarget target) {
    assert(() {
      debugPrint(
        'Amplitude: tap on ${target.name}'
        '${target.enabled ? '' : ' (disabled)'}',
      );
      return true;
    }());
  }
}
