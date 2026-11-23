// What resolving a tap costs, next to Flutter's own hit test for the same
// point, on trees shaped to stress the walk: wide parents, deep paths, many
// controls on one path, and many routes.
//
// Run it on its own; `flutter test` with no path runs only test/, so CI
// never runs it and timings never fail a build:
//
//   flutter test benchmark/tap_resolve_benchmark_test.dart
//
// flutter test runs in debug mode, with asserts on, so the numbers are an
// upper bound: a release build is faster. The resolver runs once per
// pointer-down, not once per frame.
//
// Flutter 3.50 deprecates material.dart, but material_ui needs a newer
// Flutter than the SDK supports, as for test/ (test/analysis_options.yaml).
// ignore_for_file: deprecated_member_use
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tapKey = ValueKey('tap');

Widget _button() =>
    ElevatedButton(key: _tapKey, onPressed: () {}, child: const Text('x'));

Widget _nest(int depth, Widget Function(Widget) wrap, Widget leaf) {
  var widget = leaf;
  for (var i = 0; i < depth; i++) {
    widget = wrap(widget);
  }
  return widget;
}

/// A component whose build returns another, [depth] times, so the
/// element's render object is [depth] components down.
class _Chain extends StatelessWidget {
  const _Chain(this.depth, this.child);

  final int depth;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      depth == 0 ? child : _Chain(depth - 1, child);
}

class _Shape {
  const _Shape(this.name, this.build, {this.setUp});

  final String name;
  final Widget Function() build;

  /// Runs after the first pump, for shapes that need more than one screen.
  final Future<void> Function(WidgetTester)? setUp;
}

final _shapes = <_Shape>[
  _Shape(
    'typical: ListView.builder of 10,000 ListTiles',
    () => ListView.builder(
      itemCount: 10000,
      itemBuilder: (_, i) => ListTile(
        key: i == 3 ? _tapKey : null,
        onTap: () {},
        leading: const Icon(Icons.star),
        title: Text('Item $i'),
        trailing: Switch(value: false, onChanged: (_) {}),
      ),
    ),
  ),
  _Shape(
    'routes: 30 pushed pages, button on the top one',
    () => const SizedBox(),
    setUp: (t) async {
      final navigator = t.state<NavigatorState>(find.byType(Navigator));
      for (var i = 0; i < 30; i++) {
        navigator.push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: ListView(children: [
              if (i == 29) Center(child: _button()),
              for (var j = 0; j < 20; j++)
                ListTile(title: Text('$j'), onTap: () {}),
            ]),
          ),
        ));
      }
      await t.pumpAndSettle();
    },
  ),
  _Shape(
    'wide: Column of 2,000 built ListTiles',
    () => SingleChildScrollView(
      child: Column(children: [
        for (var i = 0; i < 2000; i++)
          ListTile(
            key: i == 0 ? _tapKey : null,
            onTap: () {},
            title: Text('$i'),
          ),
      ]),
    ),
  ),
  _Shape(
    'wide: Wrap of 10,000 GestureDetectors',
    () => SingleChildScrollView(
      child: Wrap(children: [
        for (var i = 0; i < 10000; i++)
          GestureDetector(
            key: i == 0 ? _tapKey : null,
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: const SizedBox(width: 20, height: 20),
          ),
      ]),
    ),
  ),
  _Shape(
    'wide and deep: Column of 1,000 children, each 30 components deep',
    () => SingleChildScrollView(
      child: Column(children: [
        for (var i = 0; i < 1000; i++)
          _Chain(30, i == 0 ? _button() : const SizedBox(height: 10)),
      ]),
    ),
  ),
  _Shape(
    'deep: button under 1,000 nested Paddings',
    () => Center(
      child: _nest(
        1000,
        (child) => Padding(padding: EdgeInsets.zero, child: child),
        _button(),
      ),
    ),
  ),
  _Shape(
    'deep controls: button under 200 nested GestureDetectors',
    () => Center(
      child: _nest(
        200,
        (child) => GestureDetector(onTap: () {}, child: child),
        _button(),
      ),
    ),
  ),
  _Shape(
    'overlap: 300 translucent GestureDetectors over a button',
    () => Stack(children: [
      Center(child: _button()),
      for (var i = 0; i < 300; i++)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {},
          ),
        ),
    ]),
  ),
];

int _percentile(List<int> samples, double p) {
  final sorted = [...samples]..sort();
  return sorted[((sorted.length - 1) * p).round()];
}

void main() {
  const warmUp = 50;
  const runs = 400;

  for (final shape in _shapes) {
    testWidgets(shape.name, (t) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: shape.build())));
      await shape.setUp?.call(t);
      final at = t.getCenter(find.byKey(_tapKey).last);
      final viewId = t.view.viewId;
      final event = PointerDownEvent(position: at, viewId: viewId);
      final elements =
          find.byWidgetPredicate((_) => true, skipOffstage: false).evaluate();
      final target = TargetResolver.resolve(event);

      final hitTest = <int>[];
      final resolve = <int>[];
      final watch = Stopwatch();
      for (var i = 0; i < warmUp + runs; i++) {
        watch
          ..reset()
          ..start();
        WidgetsBinding.instance.hitTestInView(HitTestResult(), at, viewId);
        watch.stop();
        if (i >= warmUp) hitTest.add(watch.elapsedMicroseconds);

        watch
          ..reset()
          ..start();
        TargetResolver.resolve(event);
        watch.stop();
        if (i >= warmUp) resolve.add(watch.elapsedMicroseconds);
      }

      // ignore: avoid_print
      print('| ${shape.name} | ${elements.length} '
          '| ${_percentile(hitTest, .5)} '
          '| ${_percentile(resolve, .5)} / ${_percentile(resolve, .95)} '
          '| ${target?.name} |');
      expect(target, isNotNull, reason: 'the tap must resolve to a control');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
