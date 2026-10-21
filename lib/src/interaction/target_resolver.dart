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
    final hitPath =
        result.path.map((e) => e.target).whereType<RenderObject>().toSet();
    Element? best;
    var bestRank = 0;
    void visit(Element element, Widget? composite, InkResponse? inkOwner) {
      if (!element.mounted) return;
      final w = element.widget;
      if (w is View && w.view.viewId != event.viewId) return;
      if (w is Visibility && !w.visible ||
          w is Offstage && w.offstage ||
          w is IgnorePointer && w.ignoring ||
          w is AbsorbPointer && w.absorbing) {
        return;
      }
      final ro = element.renderObject;
      if (ro is RenderBox &&
          (!ro.attached ||
              !ro.hasSize ||
              !ro.size.contains(ro.globalToLocal(event.position)))) {
        return;
      }
      // A global composite rank would hide independently supplied child
      // controls. Reset rank only within a public composite's explicit
      // content slots; its framework-created ListTile/Checkbox/Switch retain
      // composite ownership.
      if (composite is CheckboxListTile &&
              (identical(w, composite.secondary) ||
                  identical(w, composite.title) ||
                  identical(w, composite.subtitle)) ||
          composite is SwitchListTile &&
              (identical(w, composite.secondary) ||
                  identical(w, composite.title) ||
                  identical(w, composite.subtitle))) {
        bestRank = 0;
        composite = null;
      }
      // InkResponse/InkWell build a GestureDetector of their own with equal
      // rank; skip it so the developer's widget is reported, and resume
      // normal ranking inside the developer's `child`.
      if (inkOwner != null && identical(w, inkOwner.child)) inkOwner = null;
      final rank =
          w is GestureDetector && inkOwner != null ? 0 : _targetRank(w);
      if (rank > 0 && rank >= bestRank && _isOnHitPath(element, hitPath)) {
        best = element;
        bestRank = rank;
      }
      if (w is CheckboxListTile || w is SwitchListTile) composite = w;
      if (w is InkResponse && _targetRank(w) > 0) inkOwner = w;
      final owner = inkOwner;
      element.visitChildElements((child) => visit(child, composite, owner));
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null, null);
    final target = best;
    if (target == null) return null;
    return InteractionTarget(
      element: target,
      enabled: _enabled(target.widget),
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

  /// Whether [element] was reachable by this tap according to Flutter's hit
  /// test. Component widgets (buttons, tiles) have no render object of
  /// their own; their nearest descendant render object stands in for them.
  bool _isOnHitPath(Element element, Set<RenderObject> hitPath) {
    final renderObject = element.renderObject;
    return renderObject != null && hitPath.contains(renderObject);
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
