import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'target_resolver.dart';

/// Builds a consumer's own record of the pressed control at pointer-down,
/// while the target is still mounted.
typedef TapSnapshotBuilder<T> = T Function(InteractionTarget target);

/// A completed tap on a control, as seen by one consumer.
class TapObservation<T> {
  const TapObservation({
    required this.snapshot,
    required this.enabled,
    required this.down,
    required this.up,
  });

  /// What the consumer's [TapSnapshotBuilder] returned at pointer-down.
  final T snapshot;

  /// Whether the control accepted input at pointer-down.
  final bool enabled;

  final PointerDownEvent down;
  final PointerUpEvent up;
}

/// One consumer of taps. The pointer observer and target resolution are
/// shared between every [TapCapture].
class TapCapture<T> implements _TapConsumer {
  TapCapture({
    required TapSnapshotBuilder<T> buildSnapshot,
    required void Function(TapObservation<T>) onTap,
    required bool enabled,
  })  : _buildSnapshot = buildSnapshot,
        _onTap = onTap {
    WidgetsFlutterBinding.ensureInitialized();
    configure(enabled: enabled);
  }

  final TapSnapshotBuilder<T> _buildSnapshot;
  final void Function(TapObservation<T>) _onTap;
  bool _disposed = false;

  @override
  int _generation = 0;

  void configure({required bool enabled}) {
    if (_disposed) return;
    reset();
    if (enabled) {
      _PointerObserver.instance.add(this);
    } else {
      _PointerObserver.instance.remove(this);
    }
  }

  /// Discards every attempt that is still in progress for this consumer.
  void reset() {
    _generation++;
  }

  void dispose() {
    if (_disposed) return;
    reset();
    _PointerObserver.instance.remove(this);
    _disposed = true;
  }

  @override
  void Function(PointerUpEvent) _begin(
    InteractionTarget target,
    PointerDownEvent down,
  ) {
    final snapshot = _buildSnapshot(target);
    final enabled = target.enabled;
    return (up) => _onTap(
          TapObservation(
            snapshot: snapshot,
            enabled: enabled,
            down: down,
            up: up,
          ),
        );
  }
}

/// The shared observer's non-generic view of a [TapCapture].
abstract class _TapConsumer {
  int get _generation;

  /// Takes the consumer's snapshot and returns how to deliver it on release.
  void Function(PointerUpEvent) _begin(
    InteractionTarget target,
    PointerDownEvent down,
  );
}

class _Pending {
  _Pending(this.generation, this.deliver);
  final int generation;
  final void Function(PointerUpEvent) deliver;
}

class _Attempt {
  _Attempt(this.down, this.slop, this.consumers);
  final PointerDownEvent down;
  final double slop;
  final Map<_TapConsumer, _Pending> consumers;
  bool valid = true;
}

/// The only owner of the global pointer route.
class _PointerObserver {
  static final instance = _PointerObserver();
  final _consumers = <_TapConsumer>{};
  final _contacts = <int, _Attempt>{};
  final _slops = <DeviceGestureSettings?, double>{};

  void add(_TapConsumer consumer) {
    if (_consumers.isEmpty) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(_observe);
    }
    _consumers.add(consumer);
  }

  void remove(_TapConsumer consumer) {
    if (!_consumers.remove(consumer)) return;
    for (final attempt in _contacts.values) {
      attempt.consumers.remove(consumer);
    }
    if (_consumers.isEmpty) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_observe);
      _contacts.clear();
    }
  }

  void _observe(PointerEvent event) {
    try {
      if (event is PointerDownEvent) {
        _down(event);
      } else if (event is PointerMoveEvent) {
        final attempt = _contacts[event.pointer];
        if (attempt != null &&
            (event.buttons != kPrimaryButton ||
                event.viewId != attempt.down.viewId ||
                (event.position - attempt.down.position).distance >
                    attempt.slop)) {
          attempt.valid = false;
        }
      } else if (event is PointerCancelEvent) {
        _contacts.remove(event.pointer);
      } else if (event is PointerUpEvent) {
        _up(event);
      }
    } catch (error, stack) {
      _contacts.remove(event.pointer);
      _report(error, stack);
    }
  }

  void _down(PointerDownEvent event) {
    var overlapping = false;
    for (final attempt in _contacts.values) {
      if (attempt.down.viewId == event.viewId) {
        overlapping = true;
        attempt.valid = false;
      }
    }
    final valid = !overlapping && event.buttons == kPrimaryButton;
    // Resolved even for an attempt that is already invalid: the target's
    // gesture settings give the slop.
    InteractionTarget? target;
    try {
      target = const TargetResolver().resolve(event);
    } catch (error, stack) {
      _report(error, stack);
    }
    final consumers = <_TapConsumer, _Pending>{};
    // No consumer builds a snapshot for a press that can't become a tap.
    if (target != null && valid) {
      for (final consumer in _consumers.toList()) {
        try {
          consumers[consumer] =
              _Pending(consumer._generation, consumer._begin(target, event));
        } catch (error, stack) {
          _report(error, stack);
        }
      }
    }
    // Recorded even when invalid or without a target, so an overlapping
    // down still invalidates it.
    _contacts[event.pointer] = _Attempt(
      event,
      _tapSlop(target?.gestureSettings),
      consumers,
    )..valid = valid;
  }

  /// The slop Flutter's tap recognizer uses, for every pointer kind: 18 px on
  /// 3.19, and the platform touch slop on later versions.
  double _tapSlop(DeviceGestureSettings? settings) =>
      _slops.putIfAbsent(settings, () {
        final recognizer = TapGestureRecognizer()..gestureSettings = settings;
        try {
          return recognizer.preAcceptSlopTolerance ?? kTouchSlop;
        } finally {
          recognizer.dispose();
        }
      });

  void _up(PointerUpEvent event) {
    final attempt = _contacts.remove(event.pointer);
    if (attempt == null ||
        !attempt.valid ||
        event.viewId != attempt.down.viewId ||
        (event.position - attempt.down.position).distance > attempt.slop) {
      return;
    }
    // Gesture callbacks can unmount the target before this global route.
    // Only the pointer-down snapshot is read after release.
    for (final MapEntry(key: consumer, value: pending)
        in attempt.consumers.entries.toList()) {
      if (_consumers.contains(consumer) &&
          consumer._generation == pending.generation) {
        try {
          pending.deliver(event);
        } catch (error, stack) {
          _report(error, stack);
        }
      }
    }
  }

  void _report(Object error, StackTrace stack) {
    assert(() {
      debugPrint('Amplitude tap capture: $error\n$stack');
      return true;
    }());
  }
}
