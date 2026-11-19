import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../amplitude.dart';
import '../events/base_event.dart';
import 'amplitude_navigator_observer.dart'
    show AmplitudeNavigatorObserver, screenNameProperty;

/// Event type for autocaptured element interactions. Matches the native
/// iOS/Android SDK element interaction event so events unify in the
/// Amplitude UI.
const String elementInteractedEventType = '[Amplitude] Element Interacted';

/// Event property key for the interaction kind (always `touch`).
const String elementActionProperty = '[Amplitude] Action';

/// Event property key for the tapped widget's runtime type.
const String elementTargetClassProperty = '[Amplitude] Target Class';

/// Event property key for the human-readable label of the tapped widget.
const String elementTargetTextProperty = '[Amplitude] Target Text';

/// Event property key for the developer-assigned [ValueKey] of the tapped
/// widget, when present.
const String elementTargetResourceProperty = '[Amplitude] Target Resource';

/// Event property key identifying the UI framework that produced the event.
const String elementTargetSourceProperty = '[Amplitude] Target Source';

/// Event property key for the widget-type hierarchy above the tapped widget.
const String elementHierarchyProperty = '[Amplitude] Hierarchy';

/// Maximum length of the reported target text.
const int _maxTargetTextLength = 128;

/// Maximum number of widget types reported in the hierarchy.
const int _maxHierarchyDepth = 10;

/// Maximum number of elements visited when deriving a target label.
const int _maxLabelSearchNodes = 256;

/// Decides whether a tapped widget should be reported. Return `false` to
/// exclude [widget] and everything inside it from reporting; an interactive
/// ancestor outside the excluded widget is still reported, if any.
typedef ElementTargetFilter = bool Function(Widget widget);

/// Supplies the screen name attached to element interaction events.
typedef ScreenNameProvider = String? Function();

/// Supplies extra event properties merged into every element interaction
/// event (e.g. organization/tenant context).
typedef ElementPropertiesProvider = Map<String, Object?> Function();

/// Default [ScreenNameProvider]: the most recent screen tracked by an
/// [AmplitudeNavigatorObserver].
String? defaultScreenNameProvider() =>
    AmplitudeNavigatorObserver.currentScreenName;

/// Autocaptures taps on interactive Flutter widgets as
/// `[Amplitude] Element Interacted` events.
///
/// A Flutter app renders every widget itself — natively it is a single view
/// (one `FlutterActivity`/`FlutterViewController`, or a canvas on web), so
/// neither the native SDKs' element interaction autocapture nor the Browser
/// SDK's DOM click capture can see individual widgets. This widget closes
/// that gap in Dart: wrap your app with it and taps on buttons, list tiles,
/// toggles, `InkWell`s, and `GestureDetector`s are captured on every
/// platform, including web.
///
/// ```dart
/// runApp(AmplitudeElementTapDetector(
///   amplitude: amplitude,
///   child: const MyApp(),
/// ));
/// ```
///
/// On each qualifying tap (a primary-button pointer that goes down and up
/// within the touch slop) the widget walks its element tree along the tap
/// position and reports the deepest interactive widget hit. Concrete
/// controls (buttons, tiles, toggles) take precedence over the generic
/// gesture handlers they are built from, so an `ElevatedButton` is reported
/// as `ElevatedButton`, not as its internal `InkWell`, and a
/// `CheckboxListTile` is reported as itself, not as the `ListTile` or
/// `Checkbox` it is built from. Only widgets on
/// Flutter's own hit-test path for the tap are eligible: widgets occluded
/// by a dialog's barrier, inside an `IgnorePointer` or `AbsorbPointer`, and
/// mounted-but-hidden subtrees (`Offstage`, invisible `Visibility`, and
/// therefore the inactive children of a keep-alive `IndexedStack`) are
/// never reported.
///
/// Reported properties:
/// * `[Amplitude] Action` — always `touch`.
/// * `[Amplitude] Target Class` — the widget's runtime type.
/// * `[Amplitude] Target Text` — the widget's `Semantics` label, `Tooltip`
///   message, or descendant `Text` content (first available, in that
///   order), ignoring nested interactive widgets the tap did not pass
///   through.
/// * `[Amplitude] Target Resource` — the widget's [ValueKey] value, if any.
/// * `[Amplitude] Hierarchy` — up to 10 non-private ancestor widget types.
/// * `[Amplitude] Screen Name` — from [screenNameProvider]; by default the
///   last screen tracked by an [AmplitudeNavigatorObserver].
/// * `[Amplitude] Target Source` — always `Flutter`.
///
/// Capture is controlled by constructing this widget (plus [enabled]) and is
/// deliberately independent of the `elementInteractions` autocapture option:
/// that option configures the Browser SDK's DOM capture, which on Flutter
/// web only ever sees the framework's canvas host elements. Typical Flutter
/// web setups disable the DOM capture and use this widget instead. If both
/// are enabled on web, taps may be reported twice (once per mechanism).
///
/// Analytics must never interfere with the app: all capture work runs after
/// the tap is released, never blocks gesture handling, and any internal
/// failure is swallowed (surfaced as a debug-mode log only).
///
/// Widgets without discoverable text (e.g. a custom-painted icon inside a
/// `GestureDetector`) report only their type. Give key interactive widgets a
/// `Semantics` label, `Tooltip`, or [ValueKey] to make their events
/// identifiable — this also improves accessibility.
class AmplitudeElementTapDetector extends StatefulWidget {
  const AmplitudeElementTapDetector({
    super.key,
    required this.amplitude,
    required this.child,
    this.enabled = true,
    this.targetFilter,
    this.screenNameProvider = defaultScreenNameProvider,
    this.propertiesProvider,
  });

  /// The Amplitude instance element interaction events are tracked with.
  final Amplitude amplitude;

  /// The subtree (typically the whole app) whose taps are captured.
  final Widget child;

  /// Whether capture is active. When `false` the widget only passes events
  /// through to [child].
  final bool enabled;

  /// Optional veto over which widgets are reported.
  final ElementTargetFilter? targetFilter;

  /// Supplies the `[Amplitude] Screen Name` property.
  final ScreenNameProvider? screenNameProvider;

  /// Supplies extra properties merged into every captured event.
  final ElementPropertiesProvider? propertiesProvider;

  @override
  State<AmplitudeElementTapDetector> createState() =>
      _AmplitudeElementTapDetectorState();
}

class _AmplitudeElementTapDetectorState
    extends State<AmplitudeElementTapDetector> {
  /// Pointer-down positions by pointer id, to distinguish taps from drags.
  final Map<int, Offset> _downPositions = {};

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) {
      return;
    }
    if (event.buttons & kPrimaryButton == 0) {
      return;
    }
    // Defensive bound: up/cancel normally clears entries, but never let a
    // platform quirk grow this map without limit.
    if (_downPositions.length > 20) {
      _downPositions.clear();
    }
    _downPositions[event.pointer] = event.position;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _downPositions.remove(event.pointer);
  }

  void _onPointerUp(PointerUpEvent event) {
    final downPosition = _downPositions.remove(event.pointer);
    if (!widget.enabled || downPosition == null) {
      return;
    }
    if ((event.position - downPosition).distance > kTouchSlop) {
      return; // A drag or scroll, not a tap.
    }
    // Analytics must never interfere with the app, so any failure while
    // resolving or tracking the target is swallowed and surfaced only in
    // debug builds.
    try {
      final hitPath = _hitPath(event);
      final target = _findTarget(event.position, hitPath);
      if (target == null) {
        return;
      }
      _trackTap(target, hitPath);
    } catch (error, stackTrace) {
      _onTrackError(error, stackTrace);
    }
  }

  /// The render objects Flutter's own hit test visits for [event]'s
  /// position: the ground truth for which widgets could have received the
  /// tap. Overlays (a dialog's barrier), [IgnorePointer], [AbsorbPointer],
  /// and hidden subtrees (an inactive [IndexedStack] child, [Offstage]) all
  /// keep their contents off this path.
  Set<RenderObject> _hitPath(PointerUpEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    return result.path
        .map((entry) => entry.target)
        .whereType<RenderObject>()
        .toSet();
  }

  /// Walks the element tree along [position] and returns the deepest
  /// interactive element hit, preferring concrete controls over the generic
  /// gesture handlers they are built from. Only elements whose render
  /// object is on [hitPath] are eligible, so a widget that could not have
  /// received the tap (occluded, ignored, or hidden) is never reported.
  Element? _findTarget(Offset position, Set<RenderObject> hitPath) {
    Element? best;
    var bestRank = 0;

    void visit(Element element) {
      // Cheap traversal prunes. Mounted-but-hidden subtrees keep real
      // geometry, so skipping them here avoids descending into subtrees
      // (inactive keep-alive tab bodies, Offstage widgets) that the hit-path
      // check below would reject candidate by candidate anyway.
      final w = element.widget;
      if (w is Visibility && !w.visible) {
        return;
      }
      if (w is Offstage && w.offstage) {
        return;
      }
      final renderObject = element.renderObject;
      if (renderObject is RenderBox) {
        if (!renderObject.attached || !renderObject.hasSize) {
          return;
        }
        if (!renderObject.size.contains(renderObject.globalToLocal(position))) {
          return;
        }
      }
      // Non-box render objects (slivers) and elements with no render object
      // are descended into without pruning.
      final rank = _targetRank(w);
      if (rank > 0) {
        if (!(widget.targetFilter?.call(w) ?? true)) {
          return; // Vetoed: exclude this widget and its internals entirely.
        }
        // A candidate must lie on the tap's hit-test path: a widget whose
        // geometry contains the position can still be occluded (under a
        // dialog's ModalBarrier) or unreachable (inside IgnorePointer or
        // AbsorbPointer), and Flutter's hit test is the ground truth for
        // which widgets the tap could actually reach.
        if (rank >= bestRank && _isOnHitPath(element, hitPath)) {
          best = element;
          bestRank = rank;
        }
      }
      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return best;
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
    if (w.runtimeType.toString().startsWith('_')) {
      return 0;
    }
    if (w is ButtonStyleButton) {
      return (w.onPressed != null || w.onLongPress != null) ? 2 : 0;
    }
    if (w is MaterialButton) {
      return (w.onPressed != null || w.onLongPress != null) ? 2 : 0;
    }
    if (w is IconButton) {
      return w.onPressed != null ? 2 : 0;
    }
    if (w is FloatingActionButton) {
      return w.onPressed != null ? 2 : 0;
    }
    if (w is CupertinoButton) {
      return w.onPressed != null ? 2 : 0;
    }
    if (w is ListTile) {
      return (w.onTap != null || w.onLongPress != null) ? 2 : 0;
    }
    if (w is CheckboxListTile) {
      return w.onChanged != null ? 3 : 0;
    }
    if (w is SwitchListTile) {
      return w.onChanged != null ? 3 : 0;
    }
    if (w is Checkbox) {
      return w.onChanged != null ? 2 : 0;
    }
    if (w is Switch) {
      return w.onChanged != null ? 2 : 0;
    }
    if (w is PopupMenuButton) {
      return w.enabled ? 2 : 0;
    }
    if (w is DropdownButton) {
      return w.onChanged != null ? 2 : 0;
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
      final name = w.runtimeType.toString();
      if (!name.startsWith('_')) {
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

  void _trackTap(Element target, Set<RenderObject> hitPath) {
    final targetWidget = target.widget;
    final targetText = _describeTarget(target, hitPath);
    final key = targetWidget.key;
    final resource = key is ValueKey ? key.value?.toString() : null;
    final screenName = widget.screenNameProvider?.call();

    final properties = <String, Object?>{
      elementActionProperty: 'touch',
      elementTargetClassProperty: targetWidget.runtimeType.toString(),
      if (targetText != null) elementTargetTextProperty: targetText,
      if (resource != null && resource.isNotEmpty)
        elementTargetResourceProperty: resource,
      elementTargetSourceProperty: 'Flutter',
      elementHierarchyProperty: _hierarchy(target),
      if (screenName != null && screenName.isNotEmpty)
        screenNameProperty: screenName,
      ...?widget.propertiesProvider?.call(),
    };

    unawaited(
      widget.amplitude
          .track(BaseEvent(
            elementInteractedEventType,
            eventProperties: properties,
          ))
          .catchError(_onTrackError),
    );
  }

  void _onTrackError(Object error, StackTrace stackTrace) {
    assert(() {
      debugPrint('AmplitudeElementTapDetector: failed to track '
          '$elementInteractedEventType: $error');
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
