// Which element a control is reported as, and what it is called.
//
// Maintenance: two lists here are judgement calls about Flutter's own
// widgets, not facts any API exposes. `isPlumbing` names the
// widgets-library components controls build around their parts, and
// `isPassThrough` the elements allowed between a control's component and
// its Semantics. A Flutter release that adds a wrapper inside a control can
// make a name fall back to the control's handler or role. The real-tap
// tests pin the reported name of every control form, and CI runs them on
// the latest stable Flutter, so such a change fails CI rather than
// changing event values. Fix it here, by adding the new wrapper to the
// right list. The event data (element_interaction_event_data.dart) reads
// the same lists to build Hierarchy and to find the tapped control's own
// text.
import 'package:flutter/widgets.dart';

import 'control_markers.dart';

/// The component that built a control, found from the elements that make
/// it up ([markers], highest first), or null if none of them leads to one.
///
/// This is the first stateless or stateful ancestor that isn't
/// widgets-library plumbing, then up through the components whose build
/// returned it directly: from a private `_IconButtonM3` to the public
/// `IconButton`, from `InkWell` to the `ListTile` that built it.
///
/// The search passes only elements that don't lay anything out. A layout
/// widget (Center, Padding) or a branch first means the Semantics was
/// written inline in app code. It starts from the highest marker; when
/// something the control doesn't build sits above it (an Autocomplete
/// option's list wraps its Semantics in IndexedSemantics), a lower marker,
/// such as the InkWell's own, can still lead to the control.
Element? controlElementOf(Iterable<Element> markers) {
  for (final marker in markers) {
    final found = _builderOf(marker);
    if (found != null) return found;
  }
  return null;
}

/// What a control reported as [element] is called: its class name, or its
/// [role] on obfuscated builds and when [element] is not a component that
/// built it (a Semantics written inline in app code).
String controlNameOf(Element element, {required String role}) {
  final w = element.widget;
  if (isObfuscated ||
      w is Semantics ||
      w is GestureDetector ||
      w is RawGestureDetector) {
    return role;
  }
  return typeName(w);
}

/// What a bare gesture detector, with no Semantics of its own, is called.
String handlerNameOf(Widget w) {
  if (isObfuscated) {
    return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
  }
  return typeName(w);
}

/// How many child elements [e] has.
int childCount(Element e) {
  var n = 0;
  e.visitChildElements((_) => n++);
  return n;
}

/// Obfuscated builds rename every type, the framework's included.
final bool isObfuscated = '$Semantics' != 'Semantics';

/// The component that built [start], or null if a layout widget or a branch
/// comes first.
Element? _builderOf(Element start) {
  Element? builder;
  // The ancestor just passed lays something out. Only a gesture detector
  // directly above excuses it: GestureDetector's private _GestureSemantics
  // is its own.
  var afterLayout = false;
  start.visitAncestorElements((a) {
    if (childCount(a) > 1) return false;
    final w = a.widget;
    if (afterLayout && w is! GestureDetector && w is! RawGestureDetector) {
      return false;
    }
    if (_isNamedComponent(a)) {
      builder = _outermostBuilder(a);
      return false;
    }
    afterLayout = !isPassThrough(a);
    return true;
  });
  return builder;
}

/// From [component], up through the components whose build returned it
/// directly. A flagless `Semantics()` between two of them (PopupMenuButton
/// wraps its IconButton in one) is passed over.
Element _outermostBuilder(Element component) {
  var outermost = component;
  var afterSemantics = false;
  component.visitAncestorElements((a) {
    if (_isNamedComponent(a)) {
      outermost = a;
      afterSemantics = false;
      return true;
    }
    if (afterSemantics || !_isFlagless(a.widget)) return false;
    afterSemantics = true;
    return true;
  });
  return outermost;
}

bool _isNamedComponent(Element e) =>
    (e is StatelessElement || e is StatefulElement) && !isPlumbing(e.widget);

/// Widgets-library components that controls build around their parts.
bool isPlumbing(Widget w) =>
    w is GestureDetector ||
    w is RawGestureDetector ||
    w is Focus ||
    w is Actions ||
    w is Shortcuts ||
    w is FocusableActionDetector ||
    w is ExcludeFocus ||
    w is Builder ||
    w is StatefulBuilder ||
    w is ListenableBuilder ||
    w is ValueListenableBuilder ||
    w is KeyedSubtree ||
    w is AnimatedDefaultTextStyle;

/// Elements between a control's component and its Semantics that don't lay
/// anything out: inherited and proxy elements, plumbing, and render widgets
/// that only route pointers or semantics, or only paint.
bool isPassThrough(Element e) {
  if (e is ProxyElement) return true;
  final w = e.widget;
  return isPlumbing(w) ||
      w is MouseRegion ||
      w is Listener ||
      w is IgnorePointer ||
      w is AbsorbPointer ||
      w is TapRegion ||
      w is Semantics ||
      w is MergeSemantics ||
      w is ExcludeSemantics ||
      w is BlockSemantics ||
      // CupertinoSwitch fades its toggleable with Opacity.
      w is Opacity ||
      w is FadeTransition ||
      w is RepaintBoundary ||
      w is CustomPaint ||
      w is ClipRect ||
      w is ClipRRect ||
      w is ClipPath ||
      w is DecoratedBox ||
      w is ColoredBox;
}

bool _isFlagless(Widget w) =>
    w is Semantics &&
    !isControlSemantics(w.properties) &&
    !isTapAction(w.properties);

/// The runtime type's name without type arguments (`DropdownButton<int>` is
/// `DropdownButton`). A private name drops its underscore and a `With…` or
/// `M2`/`M3` suffix: Flutter 3.19's `_ElevatedButtonWithIcon` is
/// `ElevatedButton`.
String typeName(Widget w) {
  var name = w.runtimeType.toString();
  final generic = name.indexOf('<');
  if (generic > 0) {
    name = name.substring(0, generic);
  }
  if (name.startsWith('_')) {
    name = name.replaceFirst(RegExp('^_+'), '');
    final m = RegExp(r'^(.+?)(With[A-Z]\w*|M[23])$').firstMatch(name);
    if (m != null) {
      name = m.group(1)!;
    }
  }
  return name;
}
