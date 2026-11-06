import 'dart:ui' as ui;

import 'package:amplitude_flutter/src/interaction/pointer_observer.dart';
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Subscribes until the test ends, recording the key of each tapped
/// control.
List<Object?> observeKeys() {
  final out = <Object?>[];
  addTearDown(
    PointerObserver.instance.subscribe(
      (t) => out.add((t.element.widget.key as ValueKey?)?.value),
    ),
  );
  return out;
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

/// A [RawGestureDetector] whose factory hands out one recognizer its state
/// owns, rather than building a new one each time.
class _SharedTapButton extends StatefulWidget {
  const _SharedTapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SharedTapButton> createState() => _SharedTapButtonState();
}

class _SharedTapButtonState extends State<_SharedTapButton> {
  final _tap = TapGestureRecognizer();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
        key: const ValueKey('shared'),
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => _tap,
            (r) => r.onTap = widget.onTap,
          ),
        },
        child: const SizedBox(width: 80, height: 40),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PointerObserver', () {
    testWidgets(
        'subscribed before the app is built: taps and app callbacks intact',
        (t) async {
      final out = observeKeys();
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
      expect(out.length, 4); // Taps arrive at release, with no delay.
      await t.pump(const Duration(seconds: 1));
      expect(out.length, 4);
    });

    testWidgets('out-and-back drag is permanently rejected (#317)', (t) async {
      final out = observeKeys();
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
      final out = observeKeys();
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
      expect(out.single, 'A');
    });

    testWidgets('a control the app removes on release is still reported',
        (t) async {
      final out = observeKeys();
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
      expect(out.single, 'remove');
    });

    testWidgets('navigation at release keeps the pressed target', (t) async {
      final out = observeKeys();
      final navigator = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          routes: {'/next': (_) => const Scaffold(body: Text('Next'))},
          home: Scaffold(
            body: control(
              'navigate',
              () => navigator.currentState!.pushReplacementNamed('/next'),
            ),
          ),
        ),
      );
      await t.tap(byId('navigate'));
      await t.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      expect(out.single, 'navigate');
    });

    testWidgets('cancel, overlapping pointers and button changes reject',
        (t) async {
      final out = observeKeys();
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
      final out = observeKeys();
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      await t.pump(const Duration(seconds: 5));
      await g.up();
      expect(out.length, 1);
    });

    testWidgets('a mouse click that drifts 5 px still counts', (t) async {
      final out = observeKeys();
      var ran = false;
      await t.pumpWidget(app(control('a', () => ran = true)));
      final g = await t.startGesture(
        t.getCenter(byId('a')),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(5, 0));
      await g.up();
      expect(ran, isTrue);
      expect(out.single, 'a');
    });

    testWidgets('a mouse drag past the tap slop does not count', (t) async {
      final out = observeKeys();
      var ran = false;
      await t.pumpWidget(app(control('a', () => ran = true)));
      final g = await t.startGesture(
        t.getCenter(byId('a')),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(kTouchSlop + 2, 0));
      await g.up();
      expect(ran, isFalse);
      expect(out, isEmpty);
    });

    testWidgets("touch slop follows Flutter's tap recognizer", (t) async {
      t.view.gestureSettings = ui.GestureSettings(
        physicalTouchSlop: 8 * t.view.devicePixelRatio,
      );
      addTearDown(t.view.resetGestureSettings);
      final out = observeKeys();
      var ran = false;
      await t.pumpWidget(app(control('a', () => ran = true)));
      final g = await t.startGesture(t.getCenter(byId('a')));
      await g.moveBy(const Offset(12, 0));
      await g.up();
      // 3.19's tap recognizer ignores the platform slop; later ones use it.
      expect(out.isNotEmpty, ran);
    });

    testWidgets('secondary mouse input never counts', (t) async {
      final out = observeKeys();
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
      final out = observeKeys();
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

    testWidgets('every listener gets each tap until it unsubscribes',
        (t) async {
      final a = observeKeys();
      final b = <InteractionTarget>[];
      final stopB = PointerObserver.instance.subscribe(b.add);
      await t.pumpWidget(app(control('button', () {})));
      for (var i = 0; i < 2; i++) {
        await t.tap(byId('button'));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(a, hasLength(2));
      expect(b, hasLength(2));
      stopB();
      stopB(); // A second call does nothing.
      await t.tap(byId('button'));
      expect(a, hasLength(3));
      expect(b, hasLength(2));
    });

    testWidgets('unsubscribing every listener forgets presses in progress',
        (t) async {
      final out = <InteractionTarget>[];
      var stop = PointerObserver.instance.subscribe(out.add);
      addTearDown(() => stop());
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      stop();
      stop = PointerObserver.instance.subscribe(out.add);
      await g.up();
      expect(out, isEmpty);
      await t.tap(byId('button'));
      expect(out, hasLength(1));
    });

    testWidgets('a listener added mid-press gets that tap', (t) async {
      final early = observeKeys();
      await t.pumpWidget(app(control('button', () {})));
      final g = await t.startGesture(t.getCenter(byId('button')));
      final joined = observeKeys();
      await g.up();
      expect(early, ['button']);
      expect(joined, ['button']);
    });

    testWidgets('a throwing listener never breaks the app or other listeners',
        (t) async {
      addTearDown(
        PointerObserver.instance.subscribe((_) => throw StateError('listener')),
      );
      final out = observeKeys();
      var callbacks = 0;
      await t.pumpWidget(app(control('button', () => callbacks++)));
      await t.tap(byId('button'));
      expect(callbacks, 1);
      expect(out, hasLength(1));
      await t.tap(byId('button'));
      expect(callbacks, 2);
      expect(out, hasLength(2));
    });

    testWidgets('capture never disposes a recognizer the app shares',
        (t) async {
      observeKeys();
      var callbacks = 0;
      await t.pumpWidget(app(_SharedTapButton(onTap: () => callbacks++)));
      await t.tap(byId('shared'));
      await t.pump();
      await t.tap(byId('shared'));
      await t.pump();
      expect(callbacks, 2);
    });

    testWidgets(
        "listeners run at release, after the app's callback, while mounted",
        (t) async {
      final order = <String>[];
      addTearDown(
        PointerObserver.instance.subscribe(
          (t) => order.add('listener:${t.element.mounted}'),
        ),
      );
      await t.pumpWidget(app(control('button', () => order.add('callback'))));
      await t.tap(byId('button'));
      expect(order, ['callback', 'listener:true']);
    });

    testWidgets('a control removed during the press is not reported',
        (t) async {
      final out = observeKeys();
      late StateSetter update;
      var shown = true;
      var ran = 0;
      await t.pumpWidget(
        app(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return shown
                  ? control('removed', () => ran++)
                  : const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(byId('removed')));
      update(() => shown = false);
      await t.pump();
      await g.up();
      expect(ran, 0, reason: "Flutter drops the removed control's tap");
      expect(out, isEmpty);
    });
  });

  group('scrolling', () {
    // A list of keyed rows whose callbacks record their key. Rebuilds
    // whenever [rebuild] changes, if given.
    Widget rows(
      List<Object?> taps, {
      ScrollController? controller,
      ValueNotifier<int>? rebuild,
    }) {
      Widget list(int v) => ListView.builder(
            controller: controller,
            itemCount: 2000,
            itemBuilder: (_, i) => GestureDetector(
              key: ValueKey(i),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps.add(i),
              child: SizedBox(height: 56, child: Text('Item $i $v')),
            ),
          );
      return MaterialApp(
        home: Scaffold(
          body: rebuild == null
              ? list(0)
              : ValueListenableBuilder<int>(
                  valueListenable: rebuild,
                  builder: (_, v, __) => list(v),
                ),
        ),
      );
    }

    Future<void> flingAndRun(WidgetTester t, Offset by) async {
      await t.fling(find.byType(ListView), by, 3000);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'a press that stops a fling is not a tap',
      (t) async {
        final out = observeKeys();
        final taps = <Object?>[];
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await t.pumpWidget(rows(taps, controller: controller));

        await t.tap(find.text('Item 2 0'));
        await t.pump();
        expect(taps, [2]);
        expect(out, taps);

        await flingAndRun(t, const Offset(0, -300));
        expect(controller.position.isScrollingNotifier.value, isTrue);
        final point = t.getCenter(find.byType(ListView));
        await t.tapAt(point);
        final offsetAtTap = controller.offset;
        await t.pumpAndSettle();
        expect(controller.offset, offsetAtTap, reason: 'the press stopped it');
        expect(taps, [2], reason: 'stopping a fling runs no onTap');
        expect(out, taps);

        await t.tapAt(point);
        await t.pump();
        expect(taps, hasLength(2), reason: 'the same point, once idle');
        expect(out, taps);
      },
      variant: TargetPlatformVariant(
        {TargetPlatform.android, TargetPlatform.iOS},
      ),
    );

    testWidgets(
        'a press that stops a fling credits the control around the list',
        (t) async {
      final out = observeKeys();
      final taps = <Object?>[];
      await t.pumpWidget(
        app(
          GestureDetector(
            key: const ValueKey('card'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps.add('card'),
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 2000,
                itemBuilder: (_, i) => GestureDetector(
                  key: ValueKey(i),
                  onTap: () => taps.add(i),
                  child: SizedBox(width: 100, child: Text('Tile $i')),
                ),
              ),
            ),
          ),
        ),
      );

      await flingAndRun(t, const Offset(-300, 0));
      await t.tapAt(t.getCenter(find.byType(ListView)));
      await t.pumpAndSettle();
      expect(taps, ['card']);
      expect(out, taps);
    });

    testWidgets('a tap after a fling ends on its own still counts', (t) async {
      final out = observeKeys();
      final taps = <Object?>[];
      await t.pumpWidget(rows(taps));

      await t.fling(find.byType(ListView), const Offset(0, -300), 3000);
      await t.pumpAndSettle();
      await t.tapAt(t.getCenter(find.byType(ListView)));
      await t.pump();
      expect(taps, hasLength(1));
      expect(out, taps);
    });

    testWidgets('a press that stops a rebuilt list is not a tap', (t) async {
      final out = observeKeys();
      final taps = <Object?>[];
      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);
      await t.pumpWidget(rows(taps, rebuild: rebuild));

      await flingAndRun(t, const Offset(0, -300));
      rebuild.value++;
      await t.pump();
      final point = t.getCenter(find.byType(ListView));
      await t.tapAt(point);
      await t.pumpAndSettle();
      expect(taps, isEmpty, reason: 'stopping a fling runs no onTap');
      expect(out, isEmpty);

      await t.tapAt(point);
      await t.pump();
      expect(taps, hasLength(1));
      expect(out, taps);
    });
  });
}
