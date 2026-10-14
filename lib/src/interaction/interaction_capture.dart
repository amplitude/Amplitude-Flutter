import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'target_resolver.dart';

class CapturedInteraction {
  CapturedInteraction(this.properties);
  final String type = '[Amplitude] Element Interacted';
  final Map<String, Object?> properties;
}

/// Per-instance consumers. The observer and target resolution are shared.
class InteractionCapture {
  InteractionCapture({required this.emit, required bool enabled}) {
    WidgetsFlutterBinding.ensureInitialized();
    configure(enabled: enabled);
  }

  final void Function(CapturedInteraction) emit;
  bool _disposed = false;
  int generation = 0;

  void configure({required bool enabled}) {
    if (_disposed) return;
    reset();
    if (enabled) {
      _PointerObserver.instance.add(this);
    } else {
      _PointerObserver.instance.remove(this);
    }
  }

  void reset() {
    generation++;
  }

  void dispose() {
    if (_disposed) return;
    reset();
    _PointerObserver.instance.remove(this);
    _disposed = true;
  }

  void _complete(TargetSnapshot snapshot) {
    if (snapshot.enabled) emit(CapturedInteraction(snapshot.properties));
  }
}

class _Attempt {
  _Attempt(this.down, this.snapshot, this.slop, this.consumers);
  final PointerDownEvent down;
  final TargetSnapshot? snapshot;
  final double slop;
  final Map<InteractionCapture, int> consumers;
  bool valid = true;
}

class _PointerObserver {
  static final instance = _PointerObserver();
  final _consumers = <InteractionCapture>{};
  final _contacts = <int, _Attempt>{};

  void add(InteractionCapture capture) {
    if (_consumers.isEmpty) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(_observe);
    }
    _consumers.add(capture);
  }

  void remove(InteractionCapture capture) {
    if (!_consumers.remove(capture)) return;
    for (final attempt in _contacts.values) {
      attempt.consumers.remove(capture);
    }
    if (_consumers.isEmpty) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_observe);
      _contacts.clear();
    }
  }

  void _observe(PointerEvent event) {
    try {
      if (event is PointerDownEvent) {
        var overlapping = false;
        for (final attempt in _contacts.values) {
          if (attempt.down.viewId == event.viewId) {
            overlapping = true;
            attempt.valid = false;
          }
        }
        final snapshot = TargetResolver().resolve(event);
        final attempt = _Attempt(
          event,
          snapshot,
          computeHitSlop(event.kind, snapshot?.gestureSettings),
          {for (final capture in _consumers) capture: capture.generation},
        )..valid = !overlapping && event.buttons == kPrimaryButton;
        _contacts[event.pointer] = attempt;
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
        final attempt = _contacts.remove(event.pointer);
        final snapshot = attempt?.snapshot;
        if (attempt == null ||
            !attempt.valid ||
            snapshot == null ||
            event.viewId != attempt.down.viewId ||
            (event.position - attempt.down.position).distance > attempt.slop) {
          return;
        }
        // Gesture callbacks can unmount the target before this global route.
        // Only the pointer-down snapshot is read after release.
        for (final entry in attempt.consumers.entries.toList()) {
          final capture = entry.key;
          if (_consumers.contains(capture) &&
              capture.generation == entry.value) {
            try {
              capture._complete(snapshot);
            } catch (error) {
              _report(error);
            }
          }
        }
      }
    } catch (error) {
      _contacts.remove(event.pointer);
      _report(error);
    }
  }

  void _report(Object error) {
    assert(() {
      debugPrint('Amplitude interaction capture: $error');
      return true;
    }());
  }
}
