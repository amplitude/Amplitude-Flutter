import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/src/interaction/flutter_element_interactions.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterElementInteractions.register', () {
    final capturing = <String, Autocapture>{
      'AutocaptureEnabled': const AutocaptureEnabled(),
      'ElementInteractionsEnabled': const AutocaptureOptions(
        elementInteractions: ElementInteractionsEnabled(),
      ),
      'ElementInteractionsOptions': const AutocaptureOptions(
        elementInteractions: ElementInteractionsOptions(
          cssSelectorAllowlist: ['button'],
        ),
      ),
    };
    for (final MapEntry(key: name, value: autocapture) in capturing.entries) {
      testWidgets('$name logs each tap', (t) async {
        final stop = FlutterElementInteractions.register(config(autocapture));
        expect(stop, isNotNull);
        addTearDown(stop!);
        expect(await logsOfTap(t), ['Amplitude: tap on ElevatedButton']);
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

  // Last: nothing unsubscribes this instance, so its listener stays for
  // the rest of this file.
  testWidgets('an Amplitude instance with element interactions logs taps',
      (t) async {
    Amplitude(config(const AutocaptureEnabled()), MockMethodChannel());
    expect(await logsOfTap(t), ['Amplitude: tap on ElevatedButton']);
  });
}
