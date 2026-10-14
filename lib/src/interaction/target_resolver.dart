// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb.
// Original target ranking, label extraction and hierarchy by Zohaib Farooqi
// and Wei Sun: https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const _maxLabelSearchNodes = 256,
    _maxTargetTextLength = 128,
    _maxHierarchyDepth = 10;

class TargetSnapshot {
  TargetSnapshot(this.properties, this.enabled, this.gestureSettings);
  final Map<String, Object?> properties;
  final bool enabled;
  final DeviceGestureSettings? gestureSettings;
}

class TargetResolver {
  TargetSnapshot? resolve(PointerDownEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    final hitPath =
        result.path.map((e) => e.target).whereType<RenderObject>().toSet();
    Element? best;
    var bestRank = 0;
    void visit(Element element, Widget? composite) {
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
      // PR's global composite rank hid independently supplied child controls.
      // Reset rank only within a public composite's explicit content slots;
      // its framework-created ListTile/Checkbox/Switch retain composite ownership.
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
      final rank = _targetRank(w);
      if (rank > 0 && rank >= bestRank && _isOnHitPath(element, hitPath)) {
        best = element;
        bestRank = rank;
      }
      if (w is CheckboxListTile || w is SwitchListTile) composite = w;
      element.visitChildElements((child) => visit(child, composite));
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    visit(root, null);
    final target = best;
    if (target == null) return null;
    final w = target.widget;
    final label = _describeTarget(target, hitPath);
    final key = w.key;
    final route = ModalRoute.of(target)?.settings.name;
    return TargetSnapshot(
      Map.unmodifiable({
        '[Amplitude] Action': 'tap',
        '[Amplitude] Target Source': 'Flutter',
        '[Amplitude] Target Class': _className(w) ?? 'Flutter control',
        if (label != null) '[Amplitude] Target Text': label,
        if (key is ValueKey && key.value != null)
          '[Amplitude] Target Resource': key.value.toString(),
        '[Amplitude] Hierarchy': _hierarchy(target),
        if (route != null && route.isNotEmpty) '[Amplitude] Screen Name': route,
      }),
      _enabled(w),
      MediaQuery.maybeOf(target)?.gestureSettings,
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
      return w.onChanged != null && (w.items?.isNotEmpty ?? false);
    }
    if (w is ListTile) return w.enabled;
    return true;
  }

  String? _className(Widget w) {
    if (w is ElevatedButton) return 'ElevatedButton';
    if (w is TextButton) return 'TextButton';
    if (w is OutlinedButton) return 'OutlinedButton';
    if (w is FilledButton) return 'FilledButton';
    if (w is MaterialButton) return 'MaterialButton';
    if (w is IconButton) return 'IconButton';
    if (w is FloatingActionButton) return 'FloatingActionButton';
    if (w is CupertinoButton) return 'CupertinoButton';
    if (w is CheckboxListTile) return 'CheckboxListTile';
    if (w is SwitchListTile) return 'SwitchListTile';
    if (w is ListTile) return 'ListTile';
    if (w is Checkbox) return 'Checkbox';
    if (w is Switch) return 'Switch';
    if (w is PopupMenuButton) return 'PopupMenuButton';
    if (w is DropdownButton) return 'DropdownButton';
    if (w is TextField) return 'TextField';
    if (w is InkWell) return 'InkWell';
    if (w is InkResponse) return 'InkResponse';
    if (w is GestureDetector) return 'GestureDetector';
    if (w is Scaffold) return 'Scaffold';
    if (w is MaterialApp) return 'MaterialApp';
    if (w is Center) return 'Center';
    if (w is Row) return 'Row';
    if (w is Column) return 'Column';
    if (w is Padding) return 'Padding';
    if (w is SizedBox) return 'SizedBox';
    if (w is Semantics) return 'Semantics';
    if (w is Tooltip) return 'Tooltip';
    if (w is Material) return 'Material';
    if (w is Text) return 'Text';
    if (w is RichText) return 'RichText';
    if (w is View) return 'View';
    if (w is Directionality) return 'Directionality';
    if (w is Builder) return 'Builder';
    return null;
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
    if (w is ButtonStyleButton &&
        !(w is ElevatedButton ||
            w is TextButton ||
            w is OutlinedButton ||
            w is FilledButton)) {
      return 0;
    }
    if (w is ButtonStyleButton) {
      return 2;
    }
    if (w is MaterialButton) {
      return 2;
    }
    if (w is IconButton) {
      return 2;
    }
    if (w is FloatingActionButton) {
      return 2;
    }
    if (w is CupertinoButton) {
      return 2;
    }
    if (w is ListTile) {
      return (w.onTap != null || w.onLongPress != null) ? 2 : 0;
    }
    if (w is CheckboxListTile) {
      return 3;
    }
    if (w is SwitchListTile) {
      return 3;
    }
    if (w is Checkbox) {
      return 2;
    }
    if (w is Switch) {
      return 2;
    }
    if (w is PopupMenuButton) {
      return w.enabled ? 2 : 0;
    }
    if (w is DropdownButton) {
      return 2;
    }
    if (w is TextField) {
      return (w.enabled ?? true) ? 2 : 0;
    }
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

  /// Derives a human-readable label for [target]: its `Semantics` label,
  /// `Tooltip` message, or descendant `Text` content, in that order.
  ///
  /// Nested interactive widgets the tap did not pass through are excluded:
  /// they are tap targets in their own right, so their labels (a trailing
  /// `IconButton`'s tooltip inside a `ListTile`, say) describe them and not
  /// [target]. The target's own internals stay included, because the render
  /// objects a tap travels through are always on [hitPath].
  String? _describeTarget(Element target, Set<RenderObject> hitPath) {
    String? semanticsLabel;
    String? tooltip;
    String? text;
    var visited = 0;

    void visit(Element element) {
      if (semanticsLabel != null || visited >= _maxLabelSearchNodes) {
        return;
      }
      visited++;
      final w = element.widget;
      if (!identical(element, target) &&
          _targetRank(w) > 0 &&
          !_isOnHitPath(element, hitPath)) {
        return;
      }
      if (w is Semantics) {
        final label = w.properties.label;
        if (label != null && label.isNotEmpty) {
          semanticsLabel = label;
          return;
        }
      } else if (w is Tooltip) {
        final message = w.message;
        if (message != null && message.isNotEmpty) {
          tooltip ??= message;
        }
      } else if (w is Text) {
        final data = w.data ?? w.textSpan?.toPlainText();
        if (data != null && data.isNotEmpty) {
          text ??= data;
        }
      } else if (w is RichText) {
        final data = w.text.toPlainText();
        if (data.isNotEmpty) {
          text ??= data;
        }
      } else if (w is Icon) {
        final label = w.semanticLabel;
        if (label != null && label.isNotEmpty) {
          tooltip ??= label;
        }
      }
      element.visitChildElements(visit);
    }

    visit(target);
    final label = semanticsLabel ?? tooltip ?? text;
    if (label == null) {
      return null;
    }
    final normalized = label.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized.length > _maxTargetTextLength
        ? normalized.substring(0, _maxTargetTextLength)
        : normalized;
  }

  /// Collects up to [_maxHierarchyDepth] non-private widget types from
  /// [target] upward, target first.
  List<String> _hierarchy(Element target) {
    final names = <String>[];
    void add(Widget w) {
      final name = _className(w) ?? w.runtimeType.toString();
      if (!name.startsWith('_') && !name.startsWith('minified:')) {
        names.add(name);
      }
    }

    add(target.widget);
    target.visitAncestorElements((element) {
      if (names.length >= _maxHierarchyDepth) {
        return false;
      }
      add(element.widget);
      return true;
    });
    return names;
  }
}
