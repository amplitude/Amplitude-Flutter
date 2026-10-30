import 'dart:async';

import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/src/interaction/flutter_element_interactions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Configuration config({
  String instanceName = 'test',
  Autocapture autocapture = const AutocaptureEnabled(),
  bool optOut = false,
}) =>
    Configuration(
      apiKey: 'key',
      instanceName: instanceName,
      autocapture: autocapture,
      optOut: optOut,
    );

Widget buttons() => MaterialApp(
      home: Scaffold(
        body: Column(children: [
          ElevatedButton(
              key: const Key('on'), onPressed: () {}, child: const Text('On')),
          const ElevatedButton(
              key: Key('off'), onPressed: null, child: Text('Off')),
        ]),
      ),
    );

/// Registers capture whose sent events land in [sent].
FlutterElementInteractions? capture(
  List<BaseEvent> sent, {
  Configuration? configuration,
  Future<bool>? isBuilt,
}) {
  final registered = FlutterElementInteractions.register(
    configuration ?? config(),
    isBuilt: isBuilt ?? Future.value(true),
    track: (event) async => sent.add(event),
  );
  addTearDown(() => registered?.unregister());
  return registered;
}

String? textOf(BaseEvent e) =>
    e.eventProperties!['[Amplitude] Target Text'] as String?;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('routing', () {
    final cases = <String, (Autocapture, bool)>{
      'AutocaptureEnabled': (const AutocaptureEnabled(), true),
      'AutocaptureDisabled': (const AutocaptureDisabled(), false),
      'default options': (const AutocaptureOptions(), false),
      'ElementInteractionsEnabled': (
        const AutocaptureOptions(
            elementInteractions: ElementInteractionsEnabled()),
        true
      ),
      // CSS fields apply to web only; mobile still captures (Q8).
      'ElementInteractionsOptions': (
        const AutocaptureOptions(
            elementInteractions: ElementInteractionsOptions()),
        true
      ),
      'ElementInteractionsDisabled': (
        const AutocaptureOptions(
            elementInteractions: ElementInteractionsDisabled()),
        false
      ),
    };
    for (final MapEntry(key: name, value: (autocapture, mobile))
        in cases.entries) {
      test('$name ${mobile ? 'captures' : "doesn't capture"} taps on mobile',
          () {
        final registered =
            capture([], configuration: config(autocapture: autocapture));
        // Web keeps the Browser SDK's DOM capture (Q8).
        expect(registered, mobile && !kIsWeb ? isNotNull : isNull);
      });
    }
  });

  group('on iOS and Android', skip: kIsWeb, () {
    testWidgets("a tap made during init is sent once ready, at the tap's time",
        (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      capture(sent, isBuilt: ready.future);
      await t.pumpWidget(buttons());

      final before = DateTime.now().millisecondsSinceEpoch;
      await t.tap(find.byKey(const Key('on')));
      final after = DateTime.now().millisecondsSinceEpoch;
      await t.pump();
      expect(sent, isEmpty);

      ready.complete(true);
      await t.pump();
      expect(sent, hasLength(1));
      expect(sent.single.eventType, '[Amplitude] Element Interacted');
      expect(sent.single.timestamp, inInclusiveRange(before, after));
    });

    testWidgets('taps waiting for init are sent in tap order', (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      capture(sent, isBuilt: ready.future);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            for (final label in ['1', '2', '3'])
              TextButton(key: Key(label), onPressed: () {}, child: Text(label)),
          ]),
        ),
      ));

      for (final label in ['1', '2', '3']) {
        await t.tap(find.byKey(Key(label)));
      }
      ready.complete(true);
      await t.pump();
      expect(sent.map(textOf), ['1', '2', '3']);
    });

    testWidgets('a failed init sends nothing, before or after it fails',
        (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      capture(sent, isBuilt: ready.future);
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      ready.complete(false);
      await t.pump();
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, isEmpty);
    });

    testWidgets('an identity reset drops taps waiting for init', (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      final registered = capture(sent, isBuilt: ready.future)!;
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      registered.resetIdentity();
      await t.tap(find.byKey(const Key('on')));
      ready.complete(true);
      await t.pump();
      expect(sent, hasLength(1));
    });

    testWidgets('opting out stops capture; opting back in resumes it',
        (t) async {
      final sent = <BaseEvent>[];
      final registered = capture(sent)!;
      await t.pumpWidget(buttons());

      registered.setOptOut(true);
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, isEmpty);

      registered.setOptOut(false);
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, hasLength(1));
    });

    testWidgets('an instance configured opted out starts with capture off',
        (t) async {
      final sent = <BaseEvent>[];
      capture(sent, configuration: config(optOut: true));
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, isEmpty);
    });

    testWidgets('a new instance with the same name replaces the capture',
        (t) async {
      final first = <BaseEvent>[];
      final second = <BaseEvent>[];
      final other = <BaseEvent>[];
      capture(first);
      capture(second);
      capture(other, configuration: config(instanceName: 'other'));
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(first, isEmpty);
      expect(second, hasLength(1));
      expect(other, hasLength(1));
    });

    testWidgets('a replaced capture that finishes init later stays stopped',
        (t) async {
      final firstReady = Completer<bool>();
      final first = <BaseEvent>[];
      final second = <BaseEvent>[];
      capture(first, isBuilt: firstReady.future);
      capture(second, isBuilt: Future.value(false));
      final third = <BaseEvent>[];
      capture(third);
      await t.pumpWidget(buttons());

      firstReady.complete(true);
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(first, isEmpty);
      expect(second, isEmpty);
      expect(third, hasLength(1));
    });

    testWidgets('a tap on a disabled control sends nothing (Q22)', (t) async {
      final sent = <BaseEvent>[];
      capture(sent);
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('off')), warnIfMissed: false);
      await t.pump();
      expect(sent, isEmpty);
    });

    testWidgets("a failing track() never reaches the app's code", (t) async {
      final registered = FlutterElementInteractions.register(
        config(),
        isBuilt: Future.value(true),
        track: (_) async => throw StateError('channel gone'),
      )!;
      addTearDown(registered.unregister);
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
