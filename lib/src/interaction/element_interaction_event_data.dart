// What an `[Amplitude] Element Interacted` event says about a tapped
// control. Adapted from PR #317's label extraction and nested-label
// exclusion, by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
//
// Only strings a developer wrote are read (ADR-0004): a button's text,
// Semantics labels, tooltips and identifiers. Text that is often user data,
// such as a list tile's title, is never read.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'control_names.dart';
import 'element_ancestry.dart';
import 'hit_controls.dart';
import 'interaction_target.dart';

/// Controls whose text is sent as Target Text (decision Q29), by name, so
/// the SDK imports neither Material nor Cupertino and the `material_ui` and
/// `cupertino_ui` buttons of the same names match too. Any other control
/// sends no text: a tile's title or a chip's label is often user data.
/// Obfuscated builds name controls by role, so nothing matches there.
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
    required this.targetElement,
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
    bool? obfuscated,
  }) {
    obfuscated ??= isObfuscated;
    final own = _OwnContent(collectText: _sendsText(target))
      ..visit(target.element, _parentOf(target.element), inIcon: false);
    final around = _AncestorLabels.of(target.element);
    // Registers the tapped element as dependent on its route, so it
    // rebuilds when the route changes: about 2 rebuilds per navigation,
    // measured acceptable (decision Q9).
    final route = ModalRoute.of(target.element);
    final ancestry = ElementAncestry.of(target, page: route?.subtreeContext);
    final routeName = route?.settings.name;
    return ElementInteractionEventData(
      targetElement: WeakReference(target.element),
      targetViewClass: target.name,
      targetText: own.text.isEmpty ? null : own.text.join(' '),
      accessibilityLabel:
          own.label ?? around.label ?? own.tooltip ?? around.tooltip,
      accessibilityIdentifier: own.identifier ?? around.identifier,
      // Obfuscated names change and get reused between releases (Q10).
      hierarchy: obfuscated ? null : ancestry.hierarchy,
      // An unnamed route (most Navigator.push calls) falls back to its page
      // widget's class, as iOS falls back to a view controller's type
      // (Q27).
      screenName: routeName != null && routeName.isNotEmpty
          ? routeName
          : (obfuscated ? null : ancestry.page),
    );
  }

  /// The tapped control's element. Nothing reads it yet: rage detection
  /// compares taps by the element they landed on, as iOS does with its
  /// view identifier. Weak, so an event waiting to be sent never keeps an
  /// unmounted subtree alive.
  final WeakReference<Element> targetElement;

  /// The control's class name (`ElevatedButton`), or its role on obfuscated
  /// builds (decision Q26).
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

  /// The route's name, else the class of its page widget.
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
/// skipped (decision Q11).
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

  /// A GestureDetector that dismisses the keyboard often wraps a whole page,
  /// and every tap on plain content resolves to it. The search stops after
  /// this many elements so such a tap stays cheap; a control's own text and
  /// labels come long before.
  static const _maxVisited = 256;
  var _visited = 0;

  void visit(Element element, Element? parent, {required bool inIcon}) {
    if (++_visited > _maxVisited) return;
    final w = element.widget;
    if (w is Semantics && isControlBoundary(w.properties)) {
      // Below the control's own handler, its Semantics is never the root of
      // a component's build (a ListTile's sits under its InkWell); one that
      // is belongs to a control wrapped in that handler. This is how the
      // resolver pairs them.
      final builtByComponent =
          parent is StatelessElement || parent is StatefulElement;
      if (_boundary || (_handler && builtByComponent)) return;
      _boundary = true;
    } else if (isActiveHandler(w, parent)) {
      if (_handler) return;
      _handler = true;
    }
    // Text's semanticsLabel is another reading of its visible text, so it
    // follows the Target Text rule rather than counting as a label.
    if (w is Semantics && parent?.widget is! Text) _read(w.properties);
    // An Icon's glyph is drawn as text; it is not the control's text.
    if (collectText && w is RichText && !inIcon) {
      text.add(w.text.toPlainText());
    }
    element.visitChildElements(
      (child) => visit(child, element, inIcon: inIcon || w is Icon),
    );
  }

  void _read(SemanticsProperties p) {
    label ??= p.label;
    tooltip ??= p.tooltip;
    identifier ??= p.identifier;
  }
}

/// Labels and an identifier set just around the tapped control: on its
/// ancestors up to the first one with more than one child, or the first
/// that is part of another control (decision Q11), as iOS and Android read
/// them only from the control itself.
class _AncestorLabels {
  String? label;
  String? tooltip;
  String? identifier;

  static _AncestorLabels of(Element target) {
    final found = _AncestorLabels();
    target.visitAncestorElements((a) {
      final w = a.widget;
      if (childCount(a) > 1 ||
          isActiveHandler(w, _parentOf(a)) ||
          (w is Semantics &&
              (isControlBoundary(w.properties) || isTapAction(w.properties)))) {
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

Element? _parentOf(Element e) {
  Element? parent;
  e.visitAncestorElements((a) {
    parent = a;
    return false;
  });
  return parent;
}
