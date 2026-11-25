// What an `[Amplitude] Element Interacted` event says about a tapped
// control. Follows the approach of PR #317's label extraction, by Zohaib
// Farooqi, and its nested-label exclusion, by Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
//
// Only a button's text, Semantics labels, tooltips and identifiers are
// read. Text that is often user data, such as a list tile's title, is
// never read, though an app can still build these strings from user data.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'control_markers.dart';
import 'control_names.dart';
import 'element_ancestry.dart';
import 'interaction_target.dart';
import 'observed_routes.dart';

/// Controls whose text is sent as Target Text, by name, so the SDK imports
/// neither Material nor Cupertino and the `material_ui` and `cupertino_ui`
/// buttons of the same names match too. Any other control sends no text: a
/// tile's title or a chip's label is often user data. Obfuscated builds
/// name controls by role, so nothing matches there.
const _textButtons = {
  'ElevatedButton',
  'TextButton',
  'OutlinedButton',
  'FilledButton',
  'MaterialButton',
  'CupertinoButton',
  'FloatingActionButton',
};

/// The tapped control, as an `[Amplitude] Element Interacted` event
/// describes it. Read at release, inside the tap listener, while the
/// control is still mounted.
class ElementInteractionEventData {
  ElementInteractionEventData({
    required this.targetViewClass,
    this.targetText,
    this.accessibilityLabel,
    this.accessibilityIdentifier,
    this.hierarchy,
    this.screenName,
  });

  /// Reads [target]'s event data. [obfuscated] is only set by tests, to see
  /// what an obfuscated build sends.
  factory ElementInteractionEventData.from(
    InteractionTarget target, {
    ObservedRoutes? routes,
    bool? obfuscated,
  }) {
    obfuscated ??= isObfuscated;
    final own = _OwnContent(collectText: _sendsText(target))
      ..visit(target.element, _parentOf(target.element), inIcon: false);
    final around = _AncestorLabels.of(target.element);
    final pages = routes?.pages() ?? const <Element, Route<dynamic>>{};
    final ancestry = ElementAncestry.of(target, isPage: pages.containsKey);
    final route = pages[ancestry.page];
    return ElementInteractionEventData(
      targetViewClass: target.name,
      targetText: own.text.isEmpty ? null : own.text.join(' '),
      accessibilityLabel:
          own.label ?? around.label ?? own.tooltip ?? around.tooltip,
      accessibilityIdentifier: own.identifier ?? around.identifier,
      // Obfuscated names change and get reused between releases.
      hierarchy: obfuscated ? null : ancestry.hierarchy,
      screenName: route == null ? null : routes!.screenNameOf(route),
    );
  }

  /// The control's class name (`ElevatedButton`), or its role on obfuscated
  /// builds.
  final String targetViewClass;

  /// The text of a button in [_textButtons].
  final String? targetText;

  /// A Semantics label (an Icon's semanticLabel builds one) or, failing
  /// that, a tooltip.
  final String? accessibilityLabel;

  /// A `Semantics.identifier`. Keys are never read: they often carry data.
  final String? accessibilityIdentifier;

  /// The components around the control, target first, joined with `" → "`
  /// as iOS and Android do: `TextButton → ListTile → Material → ProductCard
  /// → ListView → HomePage`. Null on obfuscated builds.
  final String? hierarchy;

  /// The name of the screen the control is on, as
  /// `AmplitudeNavigatorObserver` names it in `[Amplitude] Screen Viewed`.
  final String? screenName;
}

/// Whether [target] is one of [_textButtons], or an app component whose
/// build returns one directly (a `PrimaryButton` returning an
/// ElevatedButton), with nothing that lays anything out in between.
bool _sendsText(InteractionTarget target) {
  if (_textButtons.contains(target.name)) return true;
  var e = target.element;
  while (childCount(e) == 1) {
    e.visitChildElements((child) => e = child);
    if (e is StatelessElement || e is StatefulElement) {
      if (_textButtons.contains(typeName(e.widget))) return true;
    } else if (!isPassThrough(e)) {
      return false;
    }
  }
  return false;
}

/// What the tapped control shows and says about itself, from its own
/// subtree. A control nested inside it, such as an IconButton in a
/// ListTile's trailing slot, is a tap target of its own, so its subtree is
/// skipped.
class _OwnContent {
  _OwnContent({required this.collectText});

  final bool collectText;
  final text = <String>[];
  String? label;
  String? tooltip;
  String? identifier;

  /// Whether the control's own Semantics boundary and handler were seen.
  /// Any later one starts a nested control.
  var _boundary = false;
  var _handler = false;

  /// The search stops after this many elements, so a control with a large
  /// subtree stays cheap; its own text and labels come long before.
  static const _maxVisited = 256;
  var _visited = 0;

  /// [owned] is whether [element] is under the control's own Semantics.
  /// Until it is, as for a bare GestureDetector or InkWell, the search stays
  /// on a single-child path: content beside other content, such as the rest
  /// of a page a GestureDetector wraps, isn't the control's own.
  void visit(
    Element element,
    Element? parent, {
    required bool inIcon,
    bool owned = false,
  }) {
    if (++_visited > _maxVisited) return;
    final w = element.widget;
    final kind = markerKindOf(element, parent);
    if (kind == MarkerKind.controlSemantics) {
      // Below the control's own handler, its Semantics is never the root of
      // a component's build (a ListTile's sits under its InkWell); one that
      // is belongs to a control wrapped in that handler. This is how the
      // resolver pairs them.
      final builtByComponent =
          parent is StatelessElement || parent is StatefulElement;
      if (_boundary || (_handler && builtByComponent)) return;
      _boundary = true;
      owned = true;
    } else if (kind == MarkerKind.detector) {
      if (_handler) return;
      _handler = true;
    }
    // Text's semanticsLabel is another reading of its visible text, so it
    // follows the Target Text rule rather than counting as a label.
    if (w is Semantics && parent?.widget is! Text) {
      _read(w.properties);
    }
    // An Icon's glyph is drawn as text; it is not the control's text.
    if (collectText && w is RichText && !inIcon) {
      text.add(w.text.toPlainText());
    }
    if (!owned && childCount(element) > 1) return;
    element.visitChildElements(
      (child) =>
          visit(child, element, inIcon: inIcon || w is Icon, owned: owned),
    );
  }

  void _read(SemanticsProperties p) {
    label ??= p.label;
    tooltip ??= p.tooltip;
    identifier ??= p.identifier;
  }
}

/// Labels and an identifier set just around the tapped control: on its
/// ancestors up to the first one with more than one child, the first that
/// is part of another control, or the dialog, sheet or page it's on, as iOS
/// and Android read them only from the control itself.
class _AncestorLabels {
  String? label;
  String? tooltip;
  String? identifier;

  static _AncestorLabels of(Element target) {
    final found = _AncestorLabels();
    target.visitAncestorElements((a) {
      final w = a.widget;
      if (childCount(a) > 1 ||
          _controlParts.contains(markerKindOf(a, _parentOf(a))) ||
          _isRouteSemantics(w)) {
        return false;
      }
      if (w is Semantics) {
        found.label ??= w.properties.label;
        found.tooltip ??= w.properties.tooltip;
        found.identifier ??= w.properties.identifier;
      }
      return true;
    });
    return found;
  }
}

/// The Semantics a dialog, sheet or page puts around its content: its label
/// ('Alert', 'Dialog') names the route, not a control in it.
bool _isRouteSemantics(Widget w) =>
    w is Semantics &&
    (w.properties.scopesRoute == true || w.properties.namesRoute == true);

/// Markers that are part of a control: a handler, a control's Semantics or
/// InkResponse's tap action.
const _controlParts = {
  MarkerKind.detector,
  MarkerKind.controlSemantics,
  MarkerKind.tapAction,
};

Element? _parentOf(Element e) {
  Element? parent;
  e.visitAncestorElements((a) {
    parent = a;
    return false;
  });
  return parent;
}
