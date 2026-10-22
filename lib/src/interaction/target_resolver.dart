// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The Flutter control a pointer-down landed on.
class InteractionTarget {
  const InteractionTarget({
    required this.element,
    required this.enabled,
    this.gestureSettings,
  });

  /// The element of the control the developer wrote.
  final Element element;

  /// Whether the control currently accepts input.
  final bool enabled;

  /// Gesture settings of the nearest [MediaQuery], if any.
  final DeviceGestureSettings? gestureSettings;
}

/// Picks the control a pointer-down landed on by walking the element tree
/// and keeping the most specific interactive widget on the hit-test path.
class TargetResolver {
  const TargetResolver();

  InteractionTarget? resolve(PointerDownEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    // Position on the hit-test path, which is also the order recognizers
    // join the gesture arena: a lower index was hit first, and the arena
    // gives an unresolved tap to its first member.
    final hitOrder = <RenderObject, int>{};
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject) {
        hitOrder.putIfAbsent(target, () => hitOrder.length);
      }
    }
    // Only subtrees containing something Flutter hit can hold the target.
    // Following the hit path, rather than layout geometry, keeps content
    // that a Transform or SlideTransition moved outside its box.
    final searched = _hitPathAndAncestors(hitOrder.keys);
    Element? best;
    var bestRank = 0;
    var bestHitIndex = 0;
    var bestEnabled = true;
    // Between controls in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a control and one nested inside it, rank
    // decides (ties go to the deeper one), except that a disabled control
    // builds no recognizer, so it can't take a tap from an enabled ancestor.
    bool beatsBest(Element candidate, int rank, int hitIndex, bool enabled) {
      final current = best;
      if (current == null) return true;
      if (!_isAncestor(current, candidate)) return hitIndex < bestHitIndex;
      if (!enabled && bestEnabled) return false;
      return rank >= bestRank;
    }

    // [slots] holds the developer-supplied slots of the nearest ranked
    // control above [element] whose slots haven't been entered yet.
    void visit(Element element, List<Widget?>? slots, InkResponse? inkOwner) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != event.viewId) return;
      // Early exits only: hit-path pruning below would also drop these
      // branches, since Flutter doesn't hit them.
      if (w is Visibility && !w.visible && !w.maintainInteractivity ||
          w is Offstage && w.offstage ||
          w is IgnorePointer && w.ignoring ||
          w is AbsorbPointer && w.absorbing) {
        return;
      }
      // A component element (a button, a tile) has no render object of its
      // own; this is its nearest descendant render object, which stands in
      // for it both here and in [hitOrder].
      final ro = element.renderObject;
      if (ro != null && !searched.contains(ro)) return;
      // A developer handler inside a ranked control's slot (a
      // GestureDetector in a ListTile title, an InkWell in a button's child)
      // is deeper in the arena and wins the tap, so reset the rank on
      // entering a slot. Framework internals between the control and its
      // slots keep the control's rank, since they aren't the slot widget.
      // The rank is restored on leaving the slot so the reset can't leak
      // into sibling branches, such as a CheckboxListTile's own checkbox.
      final inSlot = slots != null && slots.any((s) => identical(s, w));
      final bestOutsideSlot = best;
      final rankOutsideSlot = bestRank;
      if (inSlot) {
        bestRank = 0;
        slots = null;
      }
      // InkResponse/InkWell build a GestureDetector of their own with equal
      // rank; skip it so the developer's widget is reported, and resume
      // normal ranking inside the developer's `child`.
      if (inkOwner != null && identical(w, inkOwner.child)) inkOwner = null;
      final rank =
          w is GestureDetector && inkOwner != null ? 0 : _targetRank(w);
      // Null when this tap couldn't reach the element.
      final hitIndex = rank > 0 ? hitOrder[ro] : null;
      if (hitIndex != null) {
        final enabled = _enabled(w);
        if (beatsBest(element, rank, hitIndex, enabled)) {
          best = element;
          bestRank = rank;
          bestHitIndex = hitIndex;
          bestEnabled = enabled;
        }
      }
      if (slots == null && rank > 0) slots = _developerSlots(w);
      if (w is InkResponse && rank > 0) inkOwner = w;
      final childSlots = slots;
      final owner = inkOwner;
      element.visitChildElements((child) => visit(child, childSlots, owner));
      if (inSlot && identical(best, bestOutsideSlot)) {
        bestRank = rankOutsideSlot;
      }
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null, null);
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target,
      enabled: bestEnabled,
      // Not MediaQuery.maybeOf: that would subscribe the app's own widget to
      // MediaQuery changes just because it was tapped.
      gestureSettings: target
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .gestureSettings,
    );
  }

  bool _enabled(Widget w) {
    if (w is ButtonStyleButton) {
      return w.onPressed != null || w.onLongPress != null;
    }
    if (w is MaterialButton) {
      return w.onPressed != null || w.onLongPress != null;
    }
    if (w is IconButton) return w.onPressed != null;
    if (w is FloatingActionButton) return w.onPressed != null;
    if (w is CupertinoButton) return w.onPressed != null;
    if (w is CheckboxListTile) return w.onChanged != null;
    if (w is SwitchListTile) return w.onChanged != null;
    if (w is Checkbox) return w.onChanged != null;
    if (w is Switch) return w.onChanged != null;
    if (w is DropdownButton) {
      // `w is DropdownButton` matches any DropdownButton<T>; reading the
      // typed getters through the static type throws a cast error for
      // every real (typed) dropdown, so read them dynamically.
      final dynamic dropdown = w;
      return dropdown.onChanged != null &&
          ((dropdown.items as List?)?.isNotEmpty ?? false);
    }
    if (w is ListTile) return w.enabled;
    return true;
  }

  /// The slots of [w] that hold developer-supplied widgets, or null when
  /// [w] has none. Only the widget passed in a slot counts as entering it.
  List<Widget?>? _developerSlots(Widget w) => switch (w) {
        ButtonStyleButton() => [w.child],
        MaterialButton() => [w.child],
        CupertinoButton() => [w.child],
        FloatingActionButton() => [w.child],
        ListTile() => [w.leading, w.title, w.subtitle, w.trailing],
        CheckboxListTile() => [w.secondary, w.title, w.subtitle],
        SwitchListTile() => [w.secondary, w.title, w.subtitle],
        _ => null,
      };

  /// [hit] and all of their render-tree ancestors. Transforms hit-test
  /// their children without adding themselves to the result, so the
  /// ancestors are needed to reach what they hold.
  Set<RenderObject> _hitPathAndAncestors(Iterable<RenderObject> hit) {
    final searched = <RenderObject>{};
    for (final target in hit) {
      RenderObject? ro = target;
      // Stops at the first one already added: its ancestors are in too.
      while (ro != null && searched.add(ro)) {
        ro = ro.parent;
      }
    }
    return searched;
  }

  bool _isAncestor(Element ancestor, Element element) {
    var found = false;
    element.visitAncestorElements((e) {
      found = identical(e, ancestor);
      return !found;
    });
    return found;
  }

  /// Ranks how specifically [w] identifies an interaction target.
  ///
  /// Returns 0 for non-interactive widgets. Concrete controls rank above the
  /// generic handlers (`InkResponse`, `GestureDetector`) they are built
  /// from, and composite controls that build other public controls rank
  /// above those (`CheckboxListTile` builds a `ListTile` and a `Checkbox`),
  /// so during the deepest-wins descent a control is not displaced by its
  /// own internals, while a deeper control nested inside another (e.g. an
  /// `IconButton` inside a `ListTile`) still wins.
  int _targetRank(Widget w) {
    // Private widgets are framework/library internals (e.g. Material 3's
    // IconButton builds a private ButtonStyleButton subclass). Reporting
    // them would displace the public widget the developer actually wrote.
    if (w is ButtonStyleButton) {
      return w is ElevatedButton ||
              w is TextButton ||
              w is OutlinedButton ||
              w is FilledButton
          ? 2
          : 0;
    }
    if (w is MaterialButton ||
        w is IconButton ||
        w is FloatingActionButton ||
        w is CupertinoButton ||
        w is Checkbox ||
        w is Switch ||
        w is DropdownButton) {
      return 2;
    }
    if (w is ListTile) {
      return (w.onTap != null || w.onLongPress != null) ? 2 : 0;
    }
    if (w is CheckboxListTile || w is SwitchListTile) return 3;
    if (w is PopupMenuButton) return w.enabled ? 2 : 0;
    if (w is TextField) return (w.enabled ?? true) ? 2 : 0;
    if (w is InkResponse) {
      // Includes InkWell.
      return (w.onTap != null || w.onLongPress != null || w.onDoubleTap != null)
          ? 1
          : 0;
    }
    if (w is GestureDetector) {
      return (w.onTap != null ||
              w.onTapUp != null ||
              w.onTapDown != null ||
              w.onLongPress != null ||
              w.onDoubleTap != null)
          ? 1
          : 0;
    }
    return 0;
  }
}
