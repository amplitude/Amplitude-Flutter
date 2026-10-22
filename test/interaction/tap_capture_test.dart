import 'package:amplitude_flutter/src/interaction/tap_capture.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TapCapture<Object?> keyCapture(List<TapObservation<Object?>> out) {
  final capture = TapCapture<Object?>(
    buildSnapshot: (t) => (t.element.widget.key as ValueKey?)?.value,
    onTap: out.add,
    enabled: true,
  );
  addTearDown(capture.dispose);
  return capture;
}

Widget app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

Widget control(String id, VoidCallback tap) => GestureDetector(
      key: ValueKey(id),
      onTap: tap,
      child: SizedBox(
        width: 100,
        height: 100,
        child: ColoredBox(color: Colors.blue, child: Text(id)),
      ),
    );

Finder byId(String id) => find.byKey(ValueKey(id));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TapCapture', () {
    testWidgets('created before runApp: observations and app callbacks intact',
        (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      var callbacks = 0;
      await t.pumpWidget(
        app(
          ElevatedButton(
            key: const ValueKey('button'),
            onPressed: () => callbacks++,
            child: const Text('Button'),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await t.tap(byId('button'));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(callbacks, 4);
      expect(out.length, 4); // Observations arrive immediately.
      await t.pump(const Duration(seconds: 1));
      expect(out.length, 4);
    });

    testWidgets('out-and-back drag is permanently rejected (#317)', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      var callbacks = 0;
      await t.pumpWidget(app(control('drag', () => callbacks++)));
      final g = await t.startGesture(t.getCenter(byId('drag')));
      await g.moveBy(const Offset(60, 0));
      await g.moveBy(const Offset(-60, 0));
      await g.up();
      expect(callbacks, 0);
      expect(out, isEmpty);
    });

    testWidgets('down target survives neighboring release (#317)', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      var tapped = '';
      await t.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              control('A', () => tapped = 'A'),
              control('B', () => tapped = 'B'),
            ],
          ),
        ),
      );
      final a = t.getRect(byId('A'));
      final g = await t.startGesture(Offset(a.right - 2, a.center.dy));
      await g.moveBy(const Offset(4, 0));
      await g.up();
      expect(tapped, 'A');
      expect(out.single.snapshot, 'A');
    });

    testWidgets('unmount on release still uses the down snapshot', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      late StateSetter update;
      var shown = true;
      await t.pumpWidget(
        app(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return shown
                  ? control('remove', () => update(() => shown = false))
                  : const Text('Gone');
            },
          ),
        ),
      );
      await t.tap(byId('remove'));
      await t.pump();
      expect(find.text('Gone'), findsOneWidget);
      expect(out.single.snapshot, 'remove');
    });

    testWidgets('navigation at release keeps the pressed target', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      final navigator = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          routes: {'/next': (_) => const Scaffold(body: Text('Next'))},
          home: Scaffold(
            body: ElevatedButton(
              key: const ValueKey('navigate'),
              onPressed: () =>
                  navigator.currentState!.pushReplacementNamed('/next'),
              child: const Text('Navigate'),
            ),
          ),
        ),
      );
      await t.tap(byId('navigate'));
      await t.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      expect(out.single.snapshot, 'navigate');
    });

    testWidgets('cancel, overlapping pointers and button changes reject',
        (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final point = t.getCenter(byId('button'));
      var a = await t.startGesture(point, pointer: 1);
      await a.cancel();
      a = await t.startGesture(point, pointer: 2);
      final b = await t.startGesture(point, pointer: 3);
      await a.up();
      await b.up();
      expect(out, isEmpty);
      final mouse = await t.startGesture(
        point,
        pointer: 4,
        kind: PointerDeviceKind.mouse,
      );
      await t.sendEventToBinding(
        PointerMoveEvent(
          pointer: 4,
          kind: PointerDeviceKind.mouse,
          position: point,
          buttons: kSecondaryButton,
        ),
      );
      await mouse.up();
      expect(out, isEmpty);
    });

    testWidgets('a long hold is still a tap', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      await t.pump(const Duration(seconds: 5));
      await g.up();
      expect(out.length, 1);
    });

    testWidgets('secondary mouse input never counts', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(
        t.getCenter(byId('button')),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await g.up();
      expect(out, isEmpty);
    });

    testWidgets('drags and scrolls are not delivered', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                key: const ValueKey('button'),
                onPressed: () {},
                child: const Text('Button'),
              ),
              SizedBox(
                height: 200,
                width: 300,
                child: ListView(
                  children: [
                    for (var i = 1; i <= 6; i++)
                      ListTile(onTap: () {}, title: Text('Item $i')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await t.drag(byId('button'), const Offset(0, 80));
      await t.pump();
      await t.drag(find.text('Item 1'), const Offset(0, -80));
      await t.pump();
      expect(out, isEmpty);
    });

    testWidgets('two consumers share observation but reset independently',
        (t) async {
      final outA = <TapObservation<Object?>>[];
      final outB = <TapObservation<Object?>>[];
      final a = keyCapture(outA);
      final b = keyCapture(outB);
      await t.pumpWidget(app(control('button', () {})));
      for (var i = 0; i < 4; i++) {
        await t.tap(byId('button'));
        await t.pump(const Duration(milliseconds: 100));
      }
      a.reset();
      await t.pump(const Duration(seconds: 1));
      expect(outA, hasLength(4));
      expect(outB, hasLength(4));
      b.dispose();
      await t.tap(byId('button'));
      expect(outA, hasLength(5));
      expect(outB, hasLength(4));
    });

    testWidgets('reset between down and up discards that attempt', (t) async {
      final out = <TapObservation<Object?>>[];
      final capture = keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      capture.reset();
      await g.up();
      expect(out, isEmpty);
      await t.tap(byId('button'));
      expect(out, hasLength(1));
    });

    testWidgets('disable and re-enable cannot revive an earlier contact',
        (t) async {
      final out = <TapObservation<Object?>>[];
      final capture = keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      capture.configure(enabled: false);
      capture.configure(enabled: true);
      await g.up();
      expect(out, isEmpty);
      await t.tap(byId('button'));
      expect(out, hasLength(1));
    });

    testWidgets('a consumer added mid-gesture gets nothing for it', (t) async {
      final early = <TapObservation<Object?>>[];
      keyCapture(early);
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      final joined = <TapObservation<Object?>>[];
      keyCapture(joined);
      await g.up();
      expect(early, hasLength(1));
      expect(joined, isEmpty);
      await t.tap(byId('button'));
      expect(joined, hasLength(1));
    });

    testWidgets('no snapshot is built for a press that cannot become a tap',
        (t) async {
      final snapshots = <Object?>[];
      final out = <TapObservation<Object?>>[];
      final capture = TapCapture<Object?>(
        buildSnapshot: (target) {
          final key = (target.element.widget.key as ValueKey?)?.value;
          snapshots.add(key);
          return key;
        },
        onTap: out.add,
        enabled: true,
      );
      addTearDown(capture.dispose);
      await t.pumpWidget(app(control('button', () {})));
      final point = t.getCenter(byId('button'));

      final secondary = await t.startGesture(
        point,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await secondary.up();
      expect(snapshots, isEmpty);

      final first = await t.startGesture(point, pointer: 7);
      final second = await t.startGesture(point, pointer: 8);
      await second.up();
      await first.up();
      expect(snapshots, ['button']); // Only the first press.
      expect(out, isEmpty);

      await t.tap(byId('button'));
      expect(snapshots, ['button', 'button']);
      expect(out.single.snapshot, 'button');
    });

    testWidgets('a throwing consumer never breaks the app or other consumers',
        (t) async {
      final xDelivered = <TapObservation<Object?>>[];
      final x = TapCapture<Object?>(
        buildSnapshot: (_) => throw StateError('snapshot'),
        onTap: xDelivered.add,
        enabled: true,
      );
      addTearDown(x.dispose);
      final y = TapCapture<Object?>(
        buildSnapshot: (_) => null,
        onTap: (_) => throw StateError('onTap'),
        enabled: true,
      );
      addTearDown(y.dispose);
      final z = <TapObservation<Object?>>[];
      keyCapture(z);
      var callbacks = 0;
      await t.pumpWidget(app(control('button', () => callbacks++)));
      await t.tap(byId('button'));
      expect(callbacks, 1);
      expect(z, hasLength(1));
      await t.tap(byId('button'));
      expect(callbacks, 2);
      expect(z, hasLength(2));
      expect(xDelivered, isEmpty); // Its snapshot threw at pointer-down.
    });

    testWidgets('disabled targets are delivered with enabled false', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(
        app(
          const ElevatedButton(
            key: ValueKey('off'),
            onPressed: null,
            child: Text('Off'),
          ),
        ),
      );
      await t.tap(byId('off'));
      expect(out.single.snapshot, 'off');
      expect(out.single.enabled, false);
    });

    testWidgets('the snapshot is taken at pointer-down', (t) async {
      final order = <String>[];
      final capture = TapCapture<void>(
        buildSnapshot: (t) => order.add('snapshot:${t.element.mounted}'),
        onTap: (_) {},
        enabled: true,
      );
      addTearDown(capture.dispose);
      await t.pumpWidget(app(control('button', () => order.add('callback'))));
      await t.tap(byId('button'));
      expect(order, ['snapshot:true', 'callback']);
    });

    testWidgets('observations carry the real down and up events', (t) async {
      final out = <TapObservation<Object?>>[];
      keyCapture(out);
      await t.pumpWidget(app(control('button', () {})));
      final p = t.getCenter(byId('button'));
      final g = await t.startGesture(p);
      await t.pump(const Duration(milliseconds: 50));
      await g.moveBy(const Offset(3, 0));
      await g.up();
      final observation = out.single;
      expect(observation.down.position, p);
      expect(observation.up.position, p + const Offset(3, 0));
      expect(observation.up.pointer, observation.down.pointer);
      expect(
        observation.up.timeStamp >= observation.down.timeStamp,
        isTrue,
      );
    });
  });
}
