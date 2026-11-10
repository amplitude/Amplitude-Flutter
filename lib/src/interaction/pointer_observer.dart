import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'interaction_target.dart';
import 'target_resolver.dart';

/// Watches every pointer in the app and calls its listeners when one makes
/// a tap on a control.
///
/// A tap is one primary pointer that goes down and up in the same view,
/// never moving past Flutter's tap slop, with no other pointer down in that
/// view meanwhile. There is no time limit, so a long hold counts.
///
/// The control is resolved at pointer-down, as Flutter binds a pointer to
/// what it hit then and reuses that for the rest of the gesture. Listeners
/// are called at release, after the app's own gesture callbacks.
///
/// Needs the Flutter binding: subscribe after `runApp` or
/// `WidgetsFlutterBinding.ensureInitialized()`. `Amplitude` already needs it
/// for its method channel.
class PointerObserver {
  PointerObserver._();

  static final instance = PointerObserver._();

  final _listeners = <void Function(InteractionTarget)>[];
  final _attempts = <int, _Attempt>{};
  final _slops = <DeviceGestureSettings?, double>{};

  /// Calls [listener] at release with the control each tap from now on
  /// landed on. Returns a function that stops it.
  ///
  /// The target's element is mounted for the duration of the call, so read
  /// what you need from it synchronously: after an `await`, a frame can
  /// unmount it.
  ///
  /// The first listener adds a global route to Flutter's pointer router,
  /// and removing the last one removes it.
  VoidCallback subscribe(void Function(InteractionTarget target) listener) {
    if (_listeners.isEmpty) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(_observe);
    }
    _listeners.add(listener);
    var subscribed = true;
    return () {
      if (!subscribed) return;
      subscribed = false;
      _listeners.remove(listener);
      if (_listeners.isEmpty) {
        WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_observe);
        _attempts.clear();
      }
    };
  }

  /// Flutter's pointer router calls this for every pointer event, after
  /// the routes of the recognizers tracking that pointer.
  void _observe(PointerEvent event) {
    try {
      if (event is PointerDownEvent) {
        _down(event);
      } else if (event is PointerMoveEvent) {
        final attempt = _attempts[event.pointer];
        if (attempt != null &&
            (event.buttons != kPrimaryButton ||
                event.viewId != attempt.down.viewId ||
                (event.position - attempt.down.position).distance >
                    attempt.slop)) {
          attempt.valid = false;
        }
      } else if (event is PointerCancelEvent) {
        _attempts.remove(event.pointer);
      } else if (event is PointerUpEvent) {
        _up(event);
      }
    } catch (error, stack) {
      _attempts.remove(event.pointer);
      _report(error, stack);
    }
  }

  void _down(PointerDownEvent event) {
    var overlapping = false;
    for (final attempt in _attempts.values) {
      if (attempt.down.viewId == event.viewId) {
        overlapping = true;
        attempt.valid = false;
      }
    }
    // Resolved even for a press that can't become a tap: the slop comes
    // from the target's gesture settings.
    InteractionTarget? target;
    try {
      target = TargetResolver.resolve(event);
    } catch (error, stack) {
      _report(error, stack);
    }
    // Recorded even when it can't become a tap, so a second pointer that
    // lands during it isn't reported as a tap either.
    _attempts[event.pointer] = _Attempt(
      event,
      target,
      _tapSlop(_gestureSettingsOf(target?.element)),
    )..valid = !overlapping && event.buttons == kPrimaryButton;
  }

  /// Gesture settings of the nearest [MediaQuery] above [element], if any.
  /// Not `MediaQuery.maybeOf`: that would subscribe the app's own widget to
  /// MediaQuery changes just because it was tapped.
  static DeviceGestureSettings? _gestureSettingsOf(Element? element) => element
      ?.getInheritedWidgetOfExactType<MediaQuery>()
      ?.data
      .gestureSettings;

  /// The slop Flutter's tap recognizer uses: 18 px for every pointer kind on
  /// 3.19; from 3.35, `gestureSettings.touchSlop`, or 18 px when the
  /// platform gives none.
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
    final attempt = _attempts.remove(event.pointer);
    final target = attempt?.target;
    if (attempt == null ||
        target == null ||
        !attempt.valid ||
        event.viewId != attempt.down.viewId ||
        (event.position - attempt.down.position).distance > attempt.slop) {
      return;
    }
    // The app's gesture callbacks for this release have already run, but
    // they only schedule rebuilds: the tree changes at the next frame. An
    // element unmounted during the press took its recognizers with it.
    if (!target.element.mounted) return;
    for (final listener in _listeners.toList()) {
      try {
        listener(target);
      } catch (error, stack) {
        _report(error, stack);
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

/// An attempt at a tap: one pointer, from pointer-down until it is
/// released or cancelled.
class _Attempt {
  _Attempt(this.down, this.target, this.slop);

  final PointerDownEvent down;

  /// The control the pointer-down landed on, if any.
  final InteractionTarget? target;

  /// How far the pointer may move from [down] and still be a tap: Flutter's
  /// tap slop for the target's gesture settings, read at pointer-down.
  final double slop;

  /// Whether this can still become a tap. It turns false when the pointer
  /// moves past [slop], another pointer goes down in the same view, or the
  /// buttons change, and it never turns true again: a drag that comes back
  /// within the slop is still not a tap.
  bool valid = true;
}
