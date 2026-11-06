import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../autocapture/autocapture.dart';
import '../../autocapture/element_interactions.dart';
import '../../configuration.dart';
import '../../events/base_event.dart';
import 'element_interaction_event.dart';
import 'element_interaction_event_data.dart';
import 'pointer_observer.dart';
import 'interaction_target.dart';

/// Sends an `[Amplitude] Element Interacted` event for each tap on a control,
/// for one Amplitude instance, on iOS and Android.
///
/// Everything here runs on the UI thread: the event data is read inside the
/// tap listener at release, and the event is sent from there.
class FlutterElementInteractions {
  FlutterElementInteractions._(this._isBuilt, this._track,
      {required bool optOut}) {
    if (!optOut) _start();
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
      optOut: configuration.optOut,
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

  /// Stops the tap listener; null while not listening.
  VoidCallback? _unsubscribe;

  /// Changes whenever taps waiting for init must not be sent: an identity
  /// reset, opt-out or [unregister].
  int _generation = 0;

  void _start() => _unsubscribe ??= PointerObserver.instance.subscribe(_onTap);

  void _stop() {
    _unsubscribe?.call();
    _unsubscribe = null;
  }

  /// Stops capturing taps, and drops taps waiting to be sent.
  void unregister() {
    _generation++;
    _stop();
  }

  /// The user or device changed. Taps waiting for init are never credited
  /// to the new identity. A tap is credited to whoever is identified at
  /// release, when the app's own callback runs, as the native SDKs do.
  void resetIdentity() {
    _generation++;
  }

  void setOptOut(bool optOut) {
    _generation++;
    optOut ? _stop() : _start();
  }

  void _onTap(InteractionTarget target) {
    // A disabled control runs no action, and iOS and web send nothing for
    // it (Q22).
    if (!target.enabled) return;
    // Read now: the control is mounted during this call, but a frame can
    // unmount it while the event waits for init.
    final event = ElementInteractionEvent(
      ElementInteractionEventData.from(target),
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
