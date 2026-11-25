import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../autocapture/autocapture.dart';
import '../../autocapture/element_interactions.dart';
import '../../configuration.dart';
import '../../events/base_event.dart';
import '../../experimental.dart';
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
  FlutterElementInteractions._(Future<bool> isBuilt, this._track,
      {required bool optOut})
      : _optOut = optOut {
    isBuilt.then((built) {
      _ready = built;
      _update();
    }, onError: (Object _) {});
  }

  /// The capture for each instance name. The platform SDKs address
  /// instances by name, so a new instance with a name already in use
  /// replaces the old one's capture instead of counting every tap twice.
  static final _registered = <String, FlutterElementInteractions>{};

  /// Starts capturing taps for an instance with [configuration], replacing
  /// any capture for its name. Returns null unless the app opted in with
  /// [AmplitudeExperimental.mobileElementInteractions] and its
  /// configuration captures element interactions on this platform.
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

  /// Web keeps the Browser SDK's DOM capture. On iOS and Android, once the
  /// app opted in, any element interaction setting but disabled captures
  /// taps: CSS fields only apply to web, and an app tuning them shouldn't
  /// silently lose mobile capture.
  static bool _capturesTaps(Autocapture autocapture) =>
      !kIsWeb &&
      AmplitudeExperimental.mobileElementInteractions &&
      switch (autocapture) {
        AutocaptureEnabled() => true,
        AutocaptureDisabled() => false,
        AutocaptureOptions(:final elementInteractions) =>
          elementInteractions is! ElementInteractionsDisabled,
      };

  final Future<void> Function(BaseEvent) _track;

  /// Stops the tap listener; null while not listening.
  VoidCallback? _unsubscribe;

  /// Whether the platform SDK finished init. Taps before then aren't
  /// captured, as on Android, which installs its own tap capture during
  /// init. A failed init never captures: on iOS it keeps no instance, so an
  /// event would reach an older instance with the same name, or get no
  /// reply.
  bool _ready = false;

  bool _optOut;

  /// Set once replaced or stopped for good; opting back in must not restart
  /// it, or a tap would count once for each capture with this name.
  bool _unregistered = false;

  /// Listens for taps only while ready, opted in and registered.
  void _update() {
    if (_ready && !_optOut && !_unregistered) {
      _unsubscribe ??= PointerObserver.instance.subscribe(_onTap);
    } else {
      _unsubscribe?.call();
      _unsubscribe = null;
    }
  }

  /// Stops capturing taps for good.
  void unregister() {
    _unregistered = true;
    _update();
  }

  void setOptOut(bool optOut) {
    _optOut = optOut;
    _update();
  }

  void _onTap(InteractionTarget target) {
    // A disabled control runs no action, and iOS and web send nothing for
    // it.
    if (!target.enabled) return;
    final event = ElementInteractionEvent(
      ElementInteractionEventData.from(target),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    unawaited(_send(event));
  }

  /// Sends [event] now, during the tap: `track` is called before the first
  /// `await`. The platform SDK credits it to whoever is identified at that
  /// moment, as it does the app's own `track()` calls.
  Future<void> _send(ElementInteractionEvent event) async {
    try {
      await _track(event);
    } catch (error, stack) {
      assert(() {
        debugPrint('Amplitude element interactions: $error\n$stack');
        return true;
      }());
    }
  }
}
