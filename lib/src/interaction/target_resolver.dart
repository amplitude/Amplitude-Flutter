// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, hit-path checks, hidden-widget pruning and
// composite-tile handling by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'control_catalog.dart';

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
    var bestHitIndex = 0;
    var bestEnabled = true;
    // Between controls in different branches, such as a translucent overlay
    // and the button beneath it, the one Flutter hit first wins, as it does
    // in the gesture arena. Between a control and one nested inside it, the
    // deeper one wins, except that a disabled control builds no recognizer,
    // so it can't take a tap from an enabled ancestor.
    bool beatsBest(Element candidate, int hitIndex, bool enabled) {
      final current = best;
      if (current == null) return true;
      if (!_isAncestor(current, candidate)) return hitIndex < bestHitIndex;
      if (!enabled && bestEnabled) return false;
      return true;
    }

    // [owner] is the nearest enclosing control whose internals the walk is
    // in. It is null at the top and inside a developer-supplied slot.
    void visit(Element element, _Owner? owner) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != event.viewId) return;
      // A component element (a button, a tile) has no render object of its
      // own; this is its nearest descendant render object, which stands in
      // for it both here and in [hitOrder]. Pruning by the hit path also
      // drops hidden and blocked branches (Offstage, IgnorePointer and the
      // like) by their live render state. Their widget flags can be stale:
      // Scrollable toggles its IgnorePointer's render object directly.
      final ro = element.renderObject;
      if (ro != null && !searched.contains(ro)) return;
      // A developer handler inside a control's slot (a GestureDetector in a
      // ListTile title, an InkWell in a button's child) is deeper in the
      // arena and wins the tap, so entering a slot leaves the control's
      // internals. Framework widgets between the control and its slots
      // aren't the slot widget, so they stay internal.
      if (owner != null && owner.slots.any((s) => identical(s, w))) {
        owner = null;
      }
      final spec = controlRowOfType(w);
      var childOwner = owner;
      // The generic handlers a control is built from (a button's InkWell, an
      // InkWell's own GestureDetector) and the controls it lists in `builds`
      // (a CheckboxListTile's ListTile and Checkbox), and what those build,
      // are its internals, not targets. They are ruled out before isActive
      // runs.
      final internal = owner != null &&
          spec != null &&
          (spec.generic || owner.spec.buildsTransitively.contains(spec));
      if (spec != null && !internal && spec.isActive(w)) {
        // Null when this tap couldn't reach the element.
        final hitIndex = hitOrder[ro];
        if (hitIndex != null) {
          final enabled = spec.isEnabled(w);
          if (beatsBest(element, hitIndex, enabled)) {
            best = element;
            bestHitIndex = hitIndex;
            bestEnabled = enabled;
          }
        }
        // Even when it wasn't hit, or lost: what it builds is still its own.
        childOwner = _Owner(spec, spec.slots(w));
      }
      element.visitChildElements((child) => visit(child, childOwner));
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null);
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
}

/// A control whose internals the walk is in, and its developer slots.
class _Owner {
  _Owner(this.spec, this.slots);

  final ControlSpec spec;
  final List<Widget?> slots;
}
