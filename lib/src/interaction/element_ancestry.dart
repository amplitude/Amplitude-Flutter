// Where a tapped control sits in the app: the `[Amplitude] Hierarchy`
// value and the page used as a fallback Screen Name. Adapted from PR #317's
// hierarchy, by Zohaib Farooqi and Wei Sun:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/widgets.dart';

import 'control_names.dart';
import 'target_resolver.dart';

/// The components between a tapped control and its route's page.
///
/// Flutter's trees are deep, so only components an app would recognize are
/// kept: public stateless and stateful widgets that aren't plumbing. Where
/// one component's build returned another directly (`HomePage` returning a
/// Scaffold, whose own Material and ScrollNotificationObserver follow), only
/// the outermost is kept. This needs no list of Flutter's classes to
/// maintain, and treats package widgets like Flutter's own. Public framework
/// internals that build something themselves (Material in a Card) remain,
/// as framework views do on iOS and Android (decision Q7).
class ElementAncestry {
  ElementAncestry(this.names, {required this.reachedPage});

  /// Android cuts Hierarchy at this length; whole entries are dropped from
  /// the outer end so that the target always stays.
  static const _maxLength = 1024;

  final List<String> names;
  final bool reachedPage;

  /// The walk stops at [page], the route's own subtree: everything above it
  /// is the same for every tap. Without a route, it stops at the nearest
  /// Overlay.
  static ElementAncestry of(InteractionTarget target, {BuildContext? page}) {
    final names = [target.name];
    var reachedPage = false;
    // Whether only elements that build nothing of their own lie between
    // here and the last kept name.
    var direct = true;
    target.element.visitAncestorElements((a) {
      if (identical(a, page)) {
        reachedPage = true;
        return false;
      }
      if (a.widget is Overlay) return false;
      if (_isAppStructure(a)) {
        final name = typeName(a.widget);
        if (direct && names.length > 1) {
          names.last = name;
        } else {
          names.add(name);
        }
        direct = true;
      } else if (!_buildsNothing(a)) {
        direct = false;
      }
      return true;
    });
    return ElementAncestry(names, reachedPage: reachedPage);
  }

  String get hierarchy {
    var end = names.length;
    String joined() => names.take(end).join(' → ');
    while (end > 1 && joined().length > _maxLength) {
      end--;
    }
    return joined();
  }

  /// The route's page widget: the outermost name, when the walk reached the
  /// page and found something around the control.
  String? get page => reachedPage && names.length > 1 ? names.last : null;
}

/// A component an app would recognize in Hierarchy.
bool _isAppStructure(Element e) {
  final w = e.widget;
  return (e is StatelessElement || e is StatefulElement) &&
      !w.runtimeType.toString().startsWith('_') &&
      !isPlumbing(w) &&
      !_isRoutePlumbing(w);
}

/// Widgets-library components that routes and lists put around every page
/// or item. Checked by type, so a rename fails to compile.
bool _isRoutePlumbing(Widget w) =>
    w is PageStorage ||
    w is TickerMode ||
    w is FocusTraversalGroup ||
    w is RestorationScope ||
    w is AutomaticKeepAlive ||
    w is SafeArea ||
    w is DisplayFeatureSubScreen;

/// Whether [e] only passes its single child through, so the component above
/// it built the component below.
bool _buildsNothing(Element e) =>
    childCount(e) <= 1 &&
    (e is StatelessElement || e is StatefulElement || isPassThrough(e));
