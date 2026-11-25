import 'dart:async';

import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/experimental.dart';
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
    routes: () => null,
  );
  addTearDown(() => registered?.unregister());
  return registered;
}

String? textOf(BaseEvent e) =>
    e.eventProperties!['[Amplitude] Target Text'] as String?;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final optedIn = AmplitudeExperimental.mobileElementInteractions;
  setUp(() => AmplitudeExperimental.mobileElementInteractions = true);
  tearDown(() => AmplitudeExperimental.mobileElementInteractions = false);

  test('mobile capture is off unless the app opts in', () {
    expect(optedIn, isFalse);
  });

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
      // CSS fields apply to web only; mobile still captures.
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
        // Web keeps the Browser SDK's DOM capture.
        expect(registered, mobile && !kIsWeb ? isNotNull : isNull);
      });
      test("$name doesn't capture taps without the opt-in", () {
        AmplitudeExperimental.mobileElementInteractions = false;
        expect(capture([], configuration: config(autocapture: autocapture)),
            isNull);
      });
    }
  });

  group('on iOS and Android', skip: kIsWeb, () {
    testWidgets("a tap made during init isn't sent, as on Android", (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      capture(sent, isBuilt: ready.future);
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      ready.complete(true);
      await t.pump();
      expect(sent, isEmpty);
    });

    testWidgets("once ready, a tap is sent at the tap's time", (t) async {
      final sent = <BaseEvent>[];
      capture(sent);
      await t.pumpWidget(buttons());
      await t.pump();

      final before = DateTime.now().millisecondsSinceEpoch;
      final gesture =
          await t.startGesture(t.getCenter(find.byKey(const Key('on'))));
      await gesture.up();
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(sent, hasLength(1));
      expect(sent.single.eventType, '[Amplitude] Element Interacted');
      expect(sent.single.timestamp, inInclusiveRange(before, after));
    });

    testWidgets('opting back in during init still waits for init', (t) async {
      final ready = Completer<bool>();
      final sent = <BaseEvent>[];
      final registered = capture(sent,
          configuration: config(optOut: true), isBuilt: ready.future)!;
      await t.pumpWidget(buttons());

      registered.setOptOut(false);
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, isEmpty);

      ready.complete(true);
      await t.pump();
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(sent, hasLength(1));
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

    testWidgets('opting a replaced capture back in leaves it stopped',
        (t) async {
      final first = <BaseEvent>[];
      final second = <BaseEvent>[];
      final replaced = capture(first)!;
      capture(second);
      await t.pumpWidget(buttons());

      replaced.setOptOut(false);
      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(first, isEmpty);
      expect(second, hasLength(1));
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

    testWidgets("doesn't make the tapped widget rebuild on navigation",
        (t) async {
      final sent = <BaseEvent>[];
      capture(sent);
      final navigator = GlobalKey<NavigatorState>();
      await t.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: CountingButton()),
      ));
      await t.tap(find.byType(CountingButton));
      await t.pump();
      expect(sent, hasLength(1));
      final state = t.state<_CountingButtonState>(find.byType(CountingButton));
      final dependencies = state.dependencyChanges;
      final builds = state.builds;

      unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('next')))));
      await t.pumpAndSettle();
      navigator.currentState!.pop();
      await t.pumpAndSettle();
      expect(state.dependencyChanges, dependencies);
      expect(state.builds, builds);
    });

    testWidgets('without AmplitudeNavigatorObserver, hints once in debug',
        (t) async {
      final printed = <String?>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message);
      final sent = <BaseEvent>[];
      try {
        capture(sent);
        await t.pumpWidget(buttons());
        await t.tap(find.byKey(const Key('on')));
        await t.tap(find.byKey(const Key('on')));
        await t.pump();
      } finally {
        debugPrint = original;
      }
      expect(sent, hasLength(2));
      expect(printed.where((m) => m!.contains('AmplitudeNavigatorObserver')),
          hasLength(1));
    });

    testWidgets('a tap on a disabled control sends nothing', (t) async {
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
        routes: () => null,
      )!;
      addTearDown(registered.unregister);
      await t.pumpWidget(buttons());

      await t.tap(find.byKey(const Key('on')));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}

/// An app's own button that counts its dependency changes and builds.
class CountingButton extends StatefulWidget {
  const CountingButton({super.key});

  @override
  State<CountingButton> createState() => _CountingButtonState();
}

class _CountingButtonState extends State<CountingButton> {
  int dependencyChanges = 0;
  int builds = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dependencyChanges++;
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return ElevatedButton(onPressed: () {}, child: const Text('Pay'));
  }
}
