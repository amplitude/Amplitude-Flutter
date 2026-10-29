// Which element a control is reported as, and what it is called.
//
// Maintenance: two lists here are judgement calls about Flutter's own
// widgets, not facts any API exposes. `_isPlumbing` names the
// widgets-library components controls build around their parts, and
// `_isPassThrough` the elements allowed between a control's component and
// its Semantics. A Flutter release that adds a wrapper inside a control can
// make a name fall back to the control's handler or role. The real-tap
// tests pin the reported name of every control form, and CI runs them on
// the latest stable Flutter, so such a change fails CI rather than
// changing event values. Fix it here, by adding the new wrapper to the
// right list. See the decision log, Q26 and Q28.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A Semantics a control builds around itself. `currentValueLength` marks a
/// text field on Flutter 3.19, whose TextField sets no role flag; `expanded`
/// marks DropdownButton and PopupMenuButton.
bool isControlBoundary(SemanticsProperties p) =>
    p.button == true ||
    p.toggled != null ||
    p.checked != null ||
    p.textField == true ||
    p.currentValueLength != null ||
    p.enabled != null ||
    p.expanded != null;

/// A Semantics with only a tap action: InkResponse's, around its
/// GestureDetector.
bool isTapAction(SemanticsProperties p) =>
    p.onTap != null || p.onLongPress != null;

/// The component that built a control, found from the elements that make
/// it up ([marks], highest first), or null if none of them leads to one.
///
/// This is the first stateless or stateful ancestor that isn't
/// widgets-library plumbing, then up through the components whose build
/// returned it directly: from a private `_IconButtonM3` to the public
/// `IconButton`, from `InkWell` to the `ListTile` that built it.
///
/// The search passes only elements that don't lay anything out. A layout
/// widget (Center, Padding) or a branch first means the Semantics was
/// written inline in app code. It starts from the highest mark; when
/// something the control doesn't build sits above it (an Autocomplete
/// option's list wraps its Semantics in IndexedSemantics), a lower mark,
/// such as the InkWell's own, can still lead to the control.
Element? controlElementOf(Iterable<Element> marks) {
  for (final mark in marks) {
    final found = _builderOf(mark);
    if (found != null) return found;
  }
  return null;
}

/// What a control reported as [element] is called: its class name, or its
/// [role] on obfuscated builds and when [element] is not a component that
/// built it (a Semantics written inline in app code).
String controlNameOf(Element element, {required String role}) {
  final w = element.widget;
  if (_obfuscated ||
      w is Semantics ||
      w is GestureDetector ||
      w is RawGestureDetector) {
    return role;
  }
  return _typeName(w);
}

/// What a bare gesture detector, with no Semantics of its own, is called.
String handlerNameOf(Widget w) {
  if (_obfuscated) {
    return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
  }
  return _typeName(w);
}

/// How many child elements [e] has.
int childCount(Element e) {
  var n = 0;
  e.visitChildElements((_) => n++);
  return n;
}

/// Obfuscated builds rename every type, the framework's included.
final bool _obfuscated = '$Semantics' != 'Semantics';

/// The component that built [start], or null if a layout widget or a branch
/// comes first.
Element? _builderOf(Element start) {
  // The ancestors up to the first one with more than one child.
  final up = <Element>[];
  start.visitAncestorElements((a) {
    up.add(a);
    return childCount(a) <= 1;
  });
  for (var i = 0; i < up.length; i++) {
    if (childCount(up[i]) > 1) return null;
    if (_isNamedComponent(up[i])) return _outermostBuilder(up, i);
    // GestureDetector's private _GestureSemantics is its own.
    final builtByHandler = i + 1 < up.length &&
        (up[i + 1].widget is GestureDetector ||
            up[i + 1].widget is RawGestureDetector);
    if (!_isPassThrough(up[i]) && !builtByHandler) return null;
  }
  return null;
}

/// From `up[i]`, up through the components whose build returned it
/// directly. A flagless `Semantics()` between two of them (PopupMenuButton
/// wraps its IconButton in one) is passed over.
Element _outermostBuilder(List<Element> up, int i) {
  while (i + 1 < up.length) {
    if (_isNamedComponent(up[i + 1])) {
      i++;
    } else if (i + 2 < up.length &&
        _isFlagless(up[i + 1].widget) &&
        _isNamedComponent(up[i + 2])) {
      i += 2;
    } else {
      break;
    }
  }
  return up[i];
}

bool _isNamedComponent(Element e) =>
    (e is StatelessElement || e is StatefulElement) && !_isPlumbing(e.widget);

/// Widgets-library components that controls build around their parts.
bool _isPlumbing(Widget w) =>
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
bool _isPassThrough(Element e) {
  if (e is ProxyElement) return true;
  final w = e.widget;
  return _isPlumbing(w) ||
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
    !isControlBoundary(w.properties) &&
    !isTapAction(w.properties);

/// The runtime type's name without type arguments (`DropdownButton<int>` is
/// `DropdownButton`). A private name drops its underscore and a `With…` or
/// `M2`/`M3` suffix: Flutter 3.19's `_ElevatedButtonWithIcon` is
/// `ElevatedButton`.
String _typeName(Widget w) {
  var name = w.runtimeType.toString();
  final generic = name.indexOf('<');
  if (generic > 0) name = name.substring(0, generic);
  if (name.startsWith('_')) {
    name = name.replaceFirst(RegExp('^_+'), '');
    final m = RegExp(r'^(.+?)(With[A-Z]\w*|M[23])$').firstMatch(name);
    if (m != null) name = m.group(1)!;
  }
  return name;
}
