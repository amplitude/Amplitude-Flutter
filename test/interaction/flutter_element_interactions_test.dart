import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/experimental.dart';
import 'package:amplitude_flutter/src/interaction/flutter_element_interactions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../amplitude_test.mocks.dart';

Configuration config([Autocapture? autocapture]) =>
    Configuration(apiKey: 'key', autocapture: autocapture);

Widget button() => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('b'),
            onPressed: () {},
            child: const Text('Pay'),
          ),
        ),
      ),
    );

/// Taps the button and returns what was logged with [debugPrint]. The test
/// binding checks that [debugPrint] is restored before tear-down.
Future<List<String>> logsOfTap(WidgetTester t) async {
  final logs = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
  try {
    await t.pumpWidget(button());
    await t.tap(find.byKey(const Key('b')));
  } finally {
    debugPrint = original;
  }
  return logs;
}

/// Configurations that enable element interactions.
const capturing = <String, Autocapture>{
  'AutocaptureEnabled': AutocaptureEnabled(),
  'ElementInteractionsEnabled': AutocaptureOptions(
    elementInteractions: ElementInteractionsEnabled(),
  ),
  'ElementInteractionsOptions': AutocaptureOptions(
    elementInteractions: ElementInteractionsOptions(
      cssSelectorAllowlist: ['button'],
    ),
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AmplitudeExperimental.mobileElementInteractions = false);

  test('mobile capture is off unless the app opts in', () {
    expect(AmplitudeExperimental.mobileElementInteractions, isFalse);
  });

  group('without the opt-in', () {
    setUp(() => AmplitudeExperimental.mobileElementInteractions = false);

    for (final MapEntry(key: name, value: autocapture) in capturing.entries) {
      testWidgets('$name starts nothing', (t) async {
        expect(
            FlutterElementInteractions.register(config(autocapture)), isNull);
        expect(await logsOfTap(t), isEmpty);
      });
    }

    testWidgets('an Amplitude instance with element interactions logs nothing',
        (t) async {
      Amplitude(config(const AutocaptureEnabled()), MockMethodChannel());
      expect(await logsOfTap(t), isEmpty);
    });
  });

  group('with the opt-in', () {
    setUp(() => AmplitudeExperimental.mobileElementInteractions = true);

    registerTests();

    // Last: nothing unsubscribes this instance, so its listener stays for
    // the rest of this file.
    testWidgets('an Amplitude instance with element interactions logs taps',
        skip: kIsWeb, (t) async {
      Amplitude(config(const AutocaptureEnabled()), MockMethodChannel());
      expect(await logsOfTap(t), ['Amplitude: tap on ElevatedButton']);
    });
  });
}

void registerTests() {
  group('FlutterElementInteractions.register', () {
    for (final MapEntry(key: name, value: autocapture) in capturing.entries) {
      testWidgets('$name logs each tap on iOS and Android', skip: kIsWeb,
          (t) async {
        final stop = FlutterElementInteractions.register(config(autocapture));
        expect(stop, isNotNull);
        addTearDown(stop!);
        expect(await logsOfTap(t), ['Amplitude: tap on ElevatedButton']);
      });
      // Web keeps the Browser SDK's DOM capture.
      test('$name captures nothing on web', skip: !kIsWeb, () {
        expect(
            FlutterElementInteractions.register(config(autocapture)), isNull);
      });
    }

    final notCapturing = <String, Autocapture?>{
      'the default configuration': null,
      'AutocaptureDisabled': const AutocaptureDisabled(),
      'ElementInteractionsDisabled': const AutocaptureOptions(
        elementInteractions: ElementInteractionsDisabled(),
      ),
    };
    for (final MapEntry(key: name, value: autocapture)
        in notCapturing.entries) {
      testWidgets('$name starts nothing', (t) async {
        expect(
            FlutterElementInteractions.register(config(autocapture)), isNull);
        expect(await logsOfTap(t), isEmpty);
      });
    }
  });
}
