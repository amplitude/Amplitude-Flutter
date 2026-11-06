import 'dart:async';

import 'package:flutter/widgets.dart';

/// Remembers which scroll positions stopped scrolling during the current
/// event-loop task.
///
/// A press on a scrolling list holds the scroll from inside the press's own
/// dispatch, before the global pointer route runs. Flutter's hit test for
/// that press ignored the list's content, but by the time the route runs the
/// content takes pointers again. A position that stopped in this task tells
/// the two apart from one that went idle on its own earlier.
///
/// Known gaps:
/// - A position is watched only once a press reaches its list, so a press
///   that stops a scroll no press started (`animateTo`, a mouse wheel, a
///   trackpad) on a list no press has reached yet is still reported.
/// - A position replaced mid-fling (`didChangeDependencies` creates a new
///   one) is the same case: the new position isn't watched yet.
/// - Where an overscrolled ballistic doesn't ignore pointers (on 3.44,
///   `ScrollPosition.shouldIgnorePointer` is false out of range), a press
///   during the iOS or macOS bounce-back is dropped, although `onTap` ran.
class FlingStops {
  final _watched = Expando<bool>();
  final _stopped = <ScrollPosition>{};

  /// Starts tracking [position]. Calling it again for the same position does
  /// nothing.
  ///
  /// The listener is never removed. It lives as long as the position's
  /// notifier, which the position disposes with itself, and [_watched] holds
  /// positions weakly, so nothing here keeps a list alive. Removing it when
  /// capture stops would need a strong list of every position watched. Its
  /// cost while capture is off is one set insertion per scroll stop.
  void watch(ScrollPosition position) {
    if (_watched[position] ?? false) return;
    _watched[position] = true;
    final scrolling = position.isScrollingNotifier;
    scrolling.addListener(() {
      if (scrolling.value) return;
      // Cleared before the next event-loop task.
      if (_stopped.isEmpty) scheduleMicrotask(_stopped.clear);
      _stopped.add(position);
    });
  }

  /// Whether [position] stopped scrolling during the current event-loop
  /// task.
  bool stoppedInThisTask(ScrollPosition position) =>
      _stopped.contains(position);
}
