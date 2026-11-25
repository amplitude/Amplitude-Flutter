// Adapted from PR #317 at a05e71683c4e6a30304d1219dad08d0b1e50d4fb:
// checking candidates against Flutter's hit-test path, by Wei Sun, and
// never reporting hidden widgets, by Zohaib Farooqi:
// https://github.com/amplitude/Amplitude-Flutter/pull/317.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'fling_stops.dart';

/// What a pointer-down hit: Flutter's hit-test path for it, and a walk of
/// the element tree along that path. Knows nothing about controls.
class HitPath {
  /// Hit-tests [event] in its view, the way Flutter's gesture binding does.
  HitPath(PointerDownEvent event) : _viewId = event.viewId {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, _viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject) {
        _hitOrder.putIfAbsent(target, () => _hitOrder.length);
      }
    }
    _searched = _withAncestors(_hitOrder.keys);
  }

  final int _viewId;

  /// Position on the hit-test path, which is also the order recognizers
  /// join the gesture arena: a lower index was hit first, and the arena
  /// gives an unresolved tap to its first member.
  final _hitOrder = <RenderObject, int>{};

  /// The render objects whose subtrees can hold the target: everything hit,
  /// and their ancestors. Following the hit path, rather than layout
  /// geometry, keeps content that a Transform or SlideTransition moved
  /// outside its box.
  late final Set<RenderObject> _searched;

  /// [element]'s position on the hit-test path, or null if the tap didn't
  /// hit it. A component element (a button, a tile) has no render object
  /// of its own and stands in for its nearest descendant one.
  int? hitIndexOf(Element element) => _hitOrder[element.renderObject];

  /// Calls [visit] for each element in the subtrees the tap hit, each
  /// before its children, from the root down.
  ///
  /// [visit] gets the element, its parent (null for the root) and what its
  /// parent's visit returned ([top] for the root), and returns what the
  /// element's children get.
  ///
  /// OverlayPortal content is visited from its Overlay, before the overlay
  /// entries, with its real parent and [top]: that parent lives in the
  /// page, which the walk may never visit. The only ancestors visited
  /// before the content are also its render ancestors, so it competes with
  /// page content by hit order, as in the gesture arena.
  void walk<T>(
    T top,
    T Function(Element element, Element? parent, T above) visit,
  ) {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    // Portal content already visited from its Overlay, to skip if the walk
    // reaches it again through the page.
    final portalContent = <Element>{};

    void step(Element element, Element? parent, T above) {
      if (!_reaches(element)) return;
      final below = visit(element, parent, above);
      if (element.widget is Overlay) {
        for (final content in _hitPortalContent(element)) {
          if (portalContent.add(content)) {
            step(content, _parentOf(content), top);
          }
        }
      }
      element.visitChildElements((child) {
        if (!portalContent.contains(child)) {
          step(child, element, below);
        }
      });
    }

    step(root, null, top);
  }

  /// Whether the tap can have hit anything in [element]'s subtree.
  bool _reaches(Element element) {
    if (!element.mounted) return false;
    final w = element.widget;
    if (w is View && w.view.viewId != _viewId) return false;
    // Pruning by the hit path also drops hidden and blocked branches
    // (Offstage, IgnorePointer and the like) by their live render state.
    // Their widget flags can be stale: Scrollable toggles its
    // IgnorePointer's render object directly.
    final ro = element.renderObject;
    if (ro != null && !_searched.contains(ro)) return false;
    // A press on a flinging list only stops it. Flutter's hit test ignored
    // the content, but the hold re-enabled it before this route ran.
    if (w is Scrollable && element is StatefulElement) {
      final position = (element.state as ScrollableState).position;
      if (FlingStops.instance.stoppedInThisTask(position)) return false;
      FlingStops.instance.watch(position);
    }
    return true;
  }

  /// The elements of OverlayPortal content in [overlay] that the tap hit.
  ///
  /// A portal's overlay child is a render child of the Overlay, painted right
  /// after the overlay entry holding the portal, but its element stays under
  /// the portal. Flutter can hit the overlay child without hitting that
  /// entry, so the walk would prune the entry before reaching the content.
  List<Element> _hitPortalContent(Element overlay) {
    Element? theater;
    overlay.visitChildElements((e) => theater = e);
    final entryOf = <RenderObject, Element>{};
    theater?.visitChildElements((entry) {
      final box = entry.renderObject;
      if (box != null) {
        entryOf[box] = entry;
      }
    });
    final content = <Element>[];
    Element? entry;
    // In paint order: each entry, then the overlay children it hosts.
    theater?.renderObject?.visitChildren((child) {
      final next = entryOf[child];
      final holder = entry;
      if (next != null) {
        entry = next;
      } else if (holder != null && _searched.contains(child)) {
        final found = _overlayChild(holder, child);
        if (found != null) {
          content.add(found);
        }
      }
    });
    return content;
  }
}

/// [hit] and all of their render-tree ancestors. Transforms hit-test their
/// children without adding themselves to the result, so the ancestors are
/// needed to reach what they hold.
Set<RenderObject> _withAncestors(Iterable<RenderObject> hit) {
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

/// The element under [entry] whose render object is [box], an overlay
/// child. Flutter keeps an overlay child deeper in the render tree than its
/// OverlayPortal so the portal lays out first; nothing at [box]'s depth or
/// deeper can lead to the portal.
Element? _overlayChild(Element entry, RenderObject box) {
  Element? found;
  void search(Element e) {
    if (found != null) return;
    if (e is RenderObjectElement) {
      if (identical(e.renderObject, box)) {
        found = e;
        return;
      }
      if (e.renderObject.depth >= box.depth) return;
    }
    e.visitChildElements(search);
  }

  search(entry);
  return found;
}

Element? _parentOf(Element e) {
  Element? parent;
  e.visitAncestorElements((a) {
    parent = a;
    return false;
  });
  return parent;
}
