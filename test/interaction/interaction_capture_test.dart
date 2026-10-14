import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/src/interaction/interaction_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InteractionCapture capture;
  late List<CapturedInteraction> events;
  void captureTest(
    String description,
    Future<void> Function(WidgetTester) body,
  ) {
    testWidgets(description, (tester) async {
      events = [];
      capture = InteractionCapture(emit: events.add, enabled: true);
      try {
        await body(tester);
      } finally {
        capture.dispose();
      }
    });
  }

  Widget app(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );
  Widget control(String id, VoidCallback tap) => GestureDetector(
        key: ValueKey(id),
        onTap: tap,
        child: SizedBox(
          width: 100,
          height: 100,
          child: ColoredBox(color: Colors.blue, child: Text(id)),
        ),
      );
  String? resource(CapturedInteraction event) =>
      event.properties['[Amplitude] Target Resource'] as String?;

  captureTest('initialized before app: ordinary events and callbacks intact', (
    t,
  ) async {
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
      await t.tap(find.byKey(const ValueKey('button')));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(callbacks, 4);
    expect(events.length, 4); // Ordinary events arrive immediately.
    await t.pump(const Duration(seconds: 1));
    expect(events.length, 4);
  });
  captureTest('out-and-back drag is permanently rejected (#317)', (t) async {
    var callbacks = 0;
    await t.pumpWidget(app(control('drag', () => callbacks++)));
    final g = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('drag'))),
    );
    await g.moveBy(const Offset(60, 0));
    await g.moveBy(const Offset(-60, 0));
    await g.up();
    expect(callbacks, 0);
    expect(events, isEmpty);
  });
  captureTest('down target survives neighboring release (#317)', (t) async {
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
    final a = t.getRect(find.byKey(const ValueKey('A')));
    final g = await t.startGesture(Offset(a.right - 2, a.center.dy));
    await g.moveBy(const Offset(4, 0));
    await g.up();
    expect(tapped, 'A');
    expect(resource(events.single), 'A');
  });
  captureTest(
    'independent child wins composite; own tile still composite (#317)',
    (t) async {
      var child = 0, tile = 0;
      await t.pumpWidget(
        app(
          CheckboxListTile(
            value: false,
            title: const Text('Setting'),
            onChanged: (_) => tile++,
            secondary: IconButton(
              key: const ValueKey('info'),
              tooltip: 'Info',
              onPressed: () => child++,
              icon: const Icon(Icons.info),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const ValueKey('info')));
      expect(child, 1);
      expect(tile, 0);
      expect(resource(events.single), 'info');
      expect(
        events.single.properties['[Amplitude] Target Class'],
        'IconButton',
      );
      await t.tap(find.text('Setting'));
      expect(tile, 1);
      expect(
        events.last.properties['[Amplitude] Target Class'],
        'CheckboxListTile',
      );
    },
  );
  captureTest(
    'navigation at release retains original screen without observer',
    (t) async {
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
      await t.tap(find.byKey(const ValueKey('navigate')));
      await t.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      expect(resource(events.single), 'navigate');
      expect(events.single.properties['[Amplitude] Screen Name'], '/');
    },
  );
  captureTest('unmount synchronously on release still uses down snapshot', (
    t,
  ) async {
    late StateSetter update;
    var shown = true;
    await t.pumpWidget(
      app(
        StatefulBuilder(
          builder: (_, set) {
            update = set;
            return shown
                ? control('remove', () {
                    update(() => shown = false);
                  })
                : const Text('Gone');
          },
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('remove')));
    await t.pump();
    expect(find.text('Gone'), findsOneWidget);
    expect(resource(events.single), 'remove');
  });
  captureTest('missing route does not prevent capture', (t) async {
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: control('unnamed', () {})),
      ),
    );
    await t.tap(find.byKey(const ValueKey('unnamed')));
    expect(resource(events.single), 'unnamed');
    expect(
      events.single.properties.containsKey('[Amplitude] Screen Name'),
      false,
    );
  });
  captureTest(
    'cancel, overlap, mouse button changes reject; long hold allowed',
    (t) async {
      await t.pumpWidget(app(control('button', () {})));
      final point = t.getCenter(find.byKey(const ValueKey('button')));
      var a = await t.startGesture(point, pointer: 1);
      await a.cancel();
      a = await t.startGesture(point, pointer: 2);
      final b = await t.startGesture(point, pointer: 3);
      await a.up();
      await b.up();
      expect(events, isEmpty);
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
      expect(events, isEmpty);
      a = await t.startGesture(point, pointer: 5);
      await t.pump(const Duration(seconds: 5));
      await a.up();
      expect(events.length, 1);
    },
  );
  captureTest('occlusion/blockers/hidden controls do not leak targets', (
    t,
  ) async {
    for (final blocker in <Widget Function(Widget)>[
      (child) => IgnorePointer(child: child),
      (child) => AbsorbPointer(child: child),
      (child) => Offstage(child: child),
      (child) => Visibility(visible: false, maintainState: true, child: child),
    ]) {
      await t.pumpWidget(app(blocker(control('hidden', () {}))));
      await t.tapAt(const Offset(400, 300));
    }
    await t.pumpWidget(
      app(
        Stack(
          children: [
            control('under', () {}),
            const Positioned.fill(child: ModalBarrier(dismissible: false)),
          ],
        ),
      ),
    );
    await t.tapAt(t.getCenter(find.byKey(const ValueKey('under'))));
    expect(events, isEmpty);
  });
  captureTest('two consumers share observation but reset independently', (
    t,
  ) async {
    final otherEvents = <CapturedInteraction>[];
    final other = InteractionCapture(emit: otherEvents.add, enabled: true);
    try {
      await t.pumpWidget(app(control('button', () {})));
      for (var i = 0; i < 4; i++) {
        await t.tap(find.byKey(const ValueKey('button')));
        await t.pump(const Duration(milliseconds: 100));
      }
      capture.reset();
      await t.pump(const Duration(seconds: 1));
      expect(events, hasLength(4));
      expect(otherEvents, hasLength(4));
      other.dispose();
      await t.tap(find.byKey(const ValueKey('button')));
      expect(events, hasLength(5));
      expect(otherEvents, hasLength(4));
    } finally {
      other.dispose();
    }
  });

  captureTest('reset between down and up discards that attempt', (t) async {
    await t.pumpWidget(app(control('button', () {})));
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('button'))),
    );
    capture.reset();
    await gesture.up();
    expect(events, isEmpty);
    await t.tap(find.byKey(const ValueKey('button')));
    expect(events, hasLength(1));
  });

  captureTest('disable and re-enable cannot revive an earlier contact', (
    t,
  ) async {
    await t.pumpWidget(app(control('button', () {})));
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('button'))),
    );
    capture.configure(enabled: false);
    capture.configure(enabled: true);
    await gesture.up();
    expect(events, isEmpty);
    await t.tap(find.byKey(const ValueKey('button')));
    expect(events, hasLength(1));
  });

  captureTest('secondary mouse input never counts as a primary attempt', (
    t,
  ) async {
    await t.pumpWidget(app(control('button', () {})));
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('button'))),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.up();
    expect(events, isEmpty);
  });
  for (final switchTile in [false, true]) {
    for (final slot in ['title', 'subtitle', 'secondary']) {
      if (!switchTile && slot == 'secondary') continue; // Existing #317 case.
      captureTest(
          'independent child in ${switchTile ? 'SwitchListTile' : 'CheckboxListTile'}.$slot',
          (t) async {
        var childTaps = 0, tileTaps = 0;
        final child = IconButton(
            key: const ValueKey('independent'),
            tooltip: 'Independent control',
            onPressed: () => childTaps++,
            icon: const Icon(Icons.info));
        final title = slot == 'title' ? child : const Text('Setting');
        final subtitle = slot == 'subtitle' ? child : null;
        final secondary = slot == 'secondary' ? child : null;
        final Widget tile = switchTile
            ? SwitchListTile(
                value: false,
                onChanged: (_) => tileTaps++,
                title: title,
                subtitle: subtitle,
                secondary: secondary)
            : CheckboxListTile(
                value: false,
                onChanged: (_) => tileTaps++,
                title: title,
                subtitle: subtitle,
                secondary: secondary);
        await t.pumpWidget(app(tile));
        await t.tap(find.byKey(const ValueKey('independent')));
        expect(childTaps, 1);
        expect(tileTaps, 0);
        expect(resource(events.single), 'independent');
        expect(
            events.single.properties['[Amplitude] Target Class'], 'IconButton');
        await t.tap(switchTile ? find.byType(Switch) : find.byType(Checkbox));
        expect(childTaps, 1);
        expect(tileTaps, 1);
        expect(events, hasLength(2));
        expect(events.last.properties['[Amplitude] Target Class'],
            switchTile ? 'SwitchListTile' : 'CheckboxListTile');
      });
    }
  }
}
