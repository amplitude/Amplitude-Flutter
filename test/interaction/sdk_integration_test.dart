import 'dart:async';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('amplitude_capture_integration_test');
  const widgets = AutocaptureOptions(
    elementInteractions: ElementInteractionsEnabled(),
  );
  late List<MethodCall> calls;
  late List<Amplitude> instances;
  Future<void> Function()? initialize;
  bool failTrack = false;

  List<Map> events() => calls
      .where((c) => c.method == 'track')
      .map((c) => (c.arguments as Map)['event'] as Map)
      .toList();
  dynamic platformOptions() =>
      (calls.firstWhere((c) => c.method == 'init').arguments
          as Map)['autocapture'];
  Amplitude sdk({
    Autocapture autocapture = widgets,
    String name = 'integration',
    bool optOut = false,
  }) {
    final result = Amplitude(
      Configuration(
        apiKey: 'offline-test',
        instanceName: name,
        autocapture: autocapture,
        optOut: optOut,
      ),
      channel,
    );
    instances.add(result);
    return result;
  }

  Future<void> mount(WidgetTester tester, {VoidCallback? callback}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: callback ?? () {},
                child: const Text('Capture'),
              ),
            ),
          ),
        ),
      );
  Future<void> tap(WidgetTester tester) async {
    await tester.tap(find.text('Capture'));
    await tester.pump();
  }

  setUp(() {
    calls = [];
    instances = [];
    initialize = null;
    failTrack = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'init') await initialize?.call();
      if (call.method == 'track' && failTrack) {
        throw PlatformException(code: 'offline-failure');
      }
      return null;
    });
  });
  tearDown(() async {
    for (final instance in instances) {
      await instance.setOptOut(true);
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final option in [widgets, const AutocaptureEnabled()]) {
    testWidgets(
      'simple flags retain Browser routing on web: ${option.runtimeType}',
      (t) async {
        final amplitude = sdk(autocapture: option);
        var callbacks = 0;
        await mount(t, callback: () => callbacks++);
        await tap(t);
        expect(callbacks, 1);
        expect(
          platformOptions()['elementInteractions'],
          kIsWeb ? const ElementInteractionsOptions().toMap() : false,
        );
        expect(events(), hasLength(kIsWeb ? 0 : 1));
        if (!kIsWeb) {
          final event = events().single;
          expect(event['event_type'], '[Amplitude] Element Interacted');
          expect(
            event['event_properties']['[Amplitude] Target Class'],
            'ElevatedButton',
          );
          expect(event['event_properties']['[Amplitude] Screen Name'], '/');
          expect(
            event['timestamp'],
            isNull,
          ); // Existing adapter/session enrichment.
        }
        await amplitude.track(BaseEvent('Manual'));
        expect(events().last['event_type'], 'Manual');
      },
    );
  }
  testWidgets(
    'explicit Browser filters retain all options and no Flutter duplicate',
    (t) async {
      sdk(
        autocapture: const AutocaptureOptions(
          elementInteractions: ElementInteractionsOptions(
            cssSelectorAllowlist: ['.tracked'],
            actionClickAllowlist: ['.parent'],
            dataAttributePrefix: 'data-custom-',
            pageUrlAllowlist: ['https://example.test/'],
          ),
        ),
      );
      await mount(t);
      await tap(t);
      expect(platformOptions()['elementInteractions'], {
        'cssSelectorAllowlist': ['.tracked'],
        'actionClickAllowlist': ['.parent'],
        'dataAttributePrefix': 'data-custom-',
        'pageUrlAllowlist': ['https://example.test/'],
      });
      expect(events(), isEmpty);
    },
  );
  for (final option in [
    const AutocaptureDisabled(),
    const AutocaptureOptions(),
  ]) {
    testWidgets('disabled capture has no observer: ${option.runtimeType}', (
      t,
    ) async {
      sdk(autocapture: option);
      await mount(t);
      await tap(t);
      expect(events(), isEmpty);
    });
  }
  group('Flutter capture lifecycle', () {
    for (final boundary in ['user', 'device', 'reset', 'optOut']) {
      testWidgets('$boundary between down/up discards pending attempt', (
        t,
      ) async {
        final amplitude = sdk();
        await mount(t);
        final gesture = await t.startGesture(t.getCenter(find.text('Capture')));
        switch (boundary) {
          case 'user':
            await amplitude.setUserId('new-user');
          case 'device':
            await amplitude.setDeviceId('new-device');
          case 'reset':
            await amplitude.reset();
          case 'optOut':
            await amplitude.setOptOut(true);
            await amplitude.setOptOut(false);
        }
        await gesture.up();
        await t.pump();
        expect(events(), isEmpty);
        await tap(t);
        expect(events(), hasLength(1));
      });
    }
    testWidgets('initial opt-out observes only after opt-in', (t) async {
      final amplitude = sdk(optOut: true);
      await mount(t);
      await tap(t);
      expect(events(), isEmpty);
      await amplitude.setOptOut(false);
      await tap(t);
      expect(events(), hasLength(1));
      await amplitude.setOptOut(true);
      await tap(t);
      expect(events(), hasLength(1));
    });
    for (final resetWaiting in [false, true]) {
      testWidgets('initialization queues capture; reset=$resetWaiting', (
        t,
      ) async {
        final ready = Completer<void>();
        initialize = () => ready.future;
        final amplitude = sdk();
        await mount(t);
        await tap(t);
        expect(events(), isEmpty);
        if (resetWaiting) await amplitude.reset();
        ready.complete();
        await t.pump();
        expect(events(), hasLength(resetWaiting ? 0 : 1));
      });
    }
    testWidgets('failed initialization removes observation', (t) async {
      initialize = () async => throw StateError('test init failure');
      final amplitude = sdk();
      await mount(t);
      expect(await amplitude.isBuilt, false);
      await tap(t);
      expect(events(), isEmpty);
    });
    testWidgets('replacement discards queued old events', (t) async {
      final ready = Completer<void>();
      initialize = () => ready.future;
      sdk();
      await mount(t);
      await tap(t);
      initialize = null;
      sdk();
      ready.complete();
      await t.pump();
      expect(events(), isEmpty);
      await tap(t);
      expect(events(), hasLength(1));
    });
    testWidgets('replacing with disabled config removes capture', (t) async {
      sdk();
      await mount(t);
      await tap(t);
      expect(events(), hasLength(1));
      sdk(autocapture: const AutocaptureDisabled());
      await tap(t);
      expect(events(), hasLength(1));
    });
    testWidgets(
      'stale references reset/opt-out current owner; other instance remains',
      (t) async {
        final original = sdk();
        sdk();
        sdk(name: 'second');
        await mount(t);
        final gesture = await t.startGesture(t.getCenter(find.text('Capture')));
        await original.reset();
        await gesture.up();
        await t.pump();
        expect(events(), hasLength(1));
        expect(
          calls.lastWhere((c) => c.method == 'track').arguments['instanceName'],
          'second',
        );
        await original.setOptOut(true);
        await tap(t);
        expect(events(), hasLength(2));
        await original.setOptOut(false);
        await tap(t);
        expect(events(), hasLength(4));
      },
    );
    testWidgets('delivery failure leaves callback and later capture intact', (
      t,
    ) async {
      sdk();
      var callbacks = 0;
      await mount(t, callback: () => callbacks++);
      failTrack = true;
      await tap(t);
      expect(callbacks, 1);
      failTrack = false;
      await tap(t);
      expect(callbacks, 2);
      expect(events(), hasLength(2));
    });
  }, skip: kIsWeb);
}
