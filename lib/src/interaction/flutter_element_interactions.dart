import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../autocapture/autocapture.dart';
import '../../autocapture/element_interactions.dart';
import '../../configuration.dart';
import '../../events/base_event.dart';
import 'element_interaction_event.dart';
import 'element_interaction_event_data.dart';
import 'tap_capture.dart';

/// Sends an `[Amplitude] Element Interacted` event for each tap on a control,
/// for one Amplitude instance, on iOS and Android.
///
/// Everything here runs on the UI thread: the event data is read inside the
/// pointer route at pointer-down, and the event is sent from the release.
class FlutterElementInteractions {
  FlutterElementInteractions._(
    this._isBuilt,
    this._track, {
    required bool enabled,
  }) {
    _taps = TapCapture(
      buildSnapshot: ElementInteractionEventData.from,
      onTap: _onTap,
      enabled: enabled,
    );
  }

  /// The capture for each instance name. The platform SDKs address
  /// instances by name, so a new instance with a name already in use
  /// replaces the old one's capture instead of counting every tap twice.
  static final _registered = <String, FlutterElementInteractions>{};

  /// Starts capturing taps for an instance with [configuration], replacing
  /// any capture for its name. Returns null when its configuration doesn't
  /// capture element interactions on this platform.
  static FlutterElementInteractions? register(
    Configuration configuration, {
    required Future<bool> isBuilt,
    required Future<void> Function(BaseEvent) track,
  }) {
    final name = configuration.instanceName;
    _registered.remove(name)?.unregister();
    if (!_capturesTaps(configuration.autocapture)) return null;
    return _registered[name] = FlutterElementInteractions._(
      isBuilt,
      track,
      enabled: !configuration.optOut,
    );
  }

  /// Web keeps the Browser SDK's DOM capture until Flutter's own pointer
  /// capture comes to web (Q8). On iOS and Android any element interaction
  /// setting but disabled captures taps: CSS fields only apply to web, and
  /// an app tuning them shouldn't silently lose mobile capture.
  static bool _capturesTaps(Autocapture autocapture) =>
      !kIsWeb &&
      switch (autocapture) {
        AutocaptureEnabled() => true,
        AutocaptureDisabled() => false,
        AutocaptureOptions(:final elementInteractions) =>
          elementInteractions is! ElementInteractionsDisabled,
      };

  final Future<bool> _isBuilt;
  final Future<void> Function(BaseEvent) _track;
  late final TapCapture<ElementInteractionEventData> _taps;

  /// Changes whenever taps made so far must not be sent: an identity reset,
  /// opt-out or [unregister]. A tap waiting for init is dropped if it has.
  int _generation = 0;

  /// Stops capturing taps, and drops taps waiting to be sent.
  void unregister() {
    _generation++;
    _taps.dispose();
  }

  /// The user or device changed. Taps made before it, including ones still
  /// waiting for init, are never credited to the new identity.
  void resetIdentity() {
    _generation++;
    _taps.reset();
  }

  void setOptOut(bool optOut) {
    _generation++;
    _taps.configure(enabled: !optOut);
  }

  void _onTap(TapObservation<ElementInteractionEventData> tap) {
    // A disabled control runs no action, and iOS and web send nothing for
    // it (Q22).
    if (!tap.enabled) return;
    final event = ElementInteractionEvent(
      tap.snapshot,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    unawaited(_send(event, _generation));
  }

  /// Sends [event] once the platform SDK is ready. A tap made while it
  /// initializes waits here, in tap order, and keeps the time it was made.
  /// Calls to `track()` from the app don't wait; automatic events do, so a
  /// failed init sends none: on iOS it keeps no instance, so an event would
  /// reach an older instance with the same name, or get no reply. Both
  /// platforms always settle `isBuilt`.
  Future<void> _send(ElementInteractionEvent event, int generation) async {
    try {
      if (!await _isBuilt || generation != _generation) return;
      await _track(event);
    } catch (error, stack) {
      assert(() {
        debugPrint('Amplitude element interactions: $error\n$stack');
        return true;
      }());
    }
  }
}
