import 'package:flutter/widgets.dart';

import 'control_markers.dart';
import 'hit_path.dart';

/// Every control under [event] that could take the tap, in element-tree
/// order: each before the controls nested in it.
///
/// For now a control is a tap handler: a GestureDetector with a tap
/// callback, or a RawGestureDetector whose tap recognizer would take a
/// primary tap.
///
/// The walk starts [FlingStops] watching each list it passes, so a later
/// press that stops one of them can be told apart.
List<HitControl> controlsHitBy(
  PointerDownEvent event,
) {
  final path = HitPath(event);
  final controls = <HitControl>[];
  path.walk((element, parent) {
    if (!isActiveHandler(element.widget, parent) ||
        _ownedBySelectableRegion(element)) {
      return;
    }
    final hitIndex = path.hitIndexOf(element);
    if (hitIndex != null) {
      controls.add(HitControl._(element, hitIndex));
    }
  });
  return controls;
}

/// A control under a pointer-down.
class HitControl {
  HitControl._(this.element, this.hitIndex);

  /// The element the control is reported as: its gesture detector.
  final Element element;

  /// Its position on the hit-test path. A lower index was hit first, which
  /// is also the order recognizers join the gesture arena.
  final int hitIndex;

  /// Its gesture detector's class name (`GestureDetector`).
  String get name => _nameOf(element.widget);
}

/// Obfuscated builds rename every type, the framework's included.
final bool _obfuscated = '$GestureDetector' != 'GestureDetector';

String _nameOf(Widget w) {
  if (_obfuscated) {
    return w is GestureDetector ? 'GestureDetector' : 'RawGestureDetector';
  }
  var name = w.runtimeType.toString();
  final generic = name.indexOf('<');
  if (generic > 0) {
    name = name.substring(0, generic);
  }
  return name.replaceFirst(RegExp('^_+'), '');
}

/// On Flutter 3.19 a SelectableRegion (what SelectionArea builds) wraps
/// its child in a translucent RawGestureDetector with a plain tap
/// recognizer that has onTapUp set. That detector is the region's own,
/// not a target, so text under it reports nothing. It sits between the
/// region and the region's child; a handler inside the child is the
/// app's and stays a target.
bool _ownedBySelectableRegion(Element handler) {
  final below = <Widget>[handler.widget];
  SelectableRegion? region;
  handler.visitAncestorElements((a) {
    final w = a.widget;
    if (w is SelectableRegion) {
      region = w;
      return false;
    }
    below.add(w);
    return true;
  });
  final r = region;
  return r != null && !below.any((w) => identical(w, r.child));
}
