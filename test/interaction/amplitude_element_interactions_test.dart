import 'dart:async';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/experimental.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../amplitude_test.mocks.dart';

const instanceName = 'element-interactions';

Configuration config({Autocapture autocapture = const AutocaptureEnabled()}) =>
    Configuration(
      apiKey: 'key',
      instanceName: instanceName,
      autocapture: autocapture,
    );

Widget button() => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
              key: const Key('b'), onPressed: () {}, child: const Text('Pay')),
        ),
      ),
    );

/// A channel whose init replies when [ready] completes.
MockMethodChannel channelReplyingTo(Completer<void> ready) {
  final channel = MockMethodChannel();
  when(channel.invokeMethod<void>('init', any)).thenAnswer((_) => ready.future);
  when(channel.invokeMethod('track', any)).thenAnswer((_) async => null);
  return channel;
}

/// The event maps sent through `track` on [channel].
List<Map<Object?, Object?>> tracked(MockMethodChannel channel) => verify(
      channel.invokeMethod('track', captureAny),
    )
        .captured
        .map((args) => (args as Map)['event'] as Map<Object?, Object?>)
        .toList();

int trackCount(MockMethodChannel channel) =>
    verify(channel.invokeMethod('track', any)).callCount;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => AmplitudeExperimental.mobileElementInteractions = true);
  tearDown(() => AmplitudeExperimental.mobileElementInteractions = false);

  // Each Amplitude here captures taps until another one with the same
  // instance name replaces it; this one has capture off.
  tearDown(() {
    final channel = MockMethodChannel();
    when(channel.invokeMethod<void>('init', any)).thenAnswer((_) async {});
    Amplitude(config(autocapture: const AutocaptureDisabled()), channel);
  });

  test('the default configuration captures no taps', () {
    expect(Configuration(apiKey: 'key').autocapture, isA<AutocaptureOptions>());
    expect(
      (Configuration(apiKey: 'key').autocapture as AutocaptureOptions)
          .elementInteractions,
      isA<ElementInteractionsDisabled>(),
    );
  });

  group('on iOS and Android', skip: kIsWeb, () {
    testWidgets("an app that didn't opt in sends nothing", (t) async {
      AmplitudeExperimental.mobileElementInteractions = false;
      final channel = channelReplyingTo(Completer<void>()..complete());
      await Amplitude(config(), channel).isBuilt;
      await t.pumpWidget(button());

      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      verifyNever(channel.invokeMethod('track', any));
    });

    testWidgets("a tap made during init isn't tracked; one after it is",
        (t) async {
      final ready = Completer<void>();
      final channel = channelReplyingTo(ready);
      final amplitude = Amplitude(config(), channel);
      await t.pumpWidget(button());

      await t.tap(find.byKey(const Key('b')));
      ready.complete();
      await amplitude.isBuilt;
      await t.pump();
      verifyNever(channel.invokeMethod('track', any));

      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      final event = tracked(channel).single;
      expect(event['event_type'], '[Amplitude] Element Interacted');
      expect(event['timestamp'], isA<int>());
      expect(
        (event['event_properties'] as Map)['[Amplitude] Target Text'],
        'Pay',
      );
    });

    testWidgets("the app's own track() isn't delayed by init (#324)",
        (t) async {
      final channel = channelReplyingTo(Completer<void>());
      final amplitude = Amplitude(config(), channel);

      unawaited(amplitude.track(BaseEvent('Manual')));
      await t.pump();
      expect(tracked(channel).single['event_type'], 'Manual');
    });

    testWidgets('a failed init tracks no taps', (t) async {
      final channel = MockMethodChannel();
      when(channel.invokeMethod<void>('init', any))
          .thenThrow(PlatformException(code: 'amplitude_init_failed'));
      when(channel.invokeMethod('track', any)).thenAnswer((_) async => null);
      final amplitude = Amplitude(config(), channel);
      expect(await amplitude.isBuilt, isFalse);
      await t.pumpWidget(button());

      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      verifyNever(channel.invokeMethod('track', any));
    });

    final resets = <String, Future<void> Function(Amplitude)>{
      'setUserId': (a) => a.setUserId('next user'),
      'setDeviceId': (a) => a.setDeviceId('next device'),
      'reset': (a) => a.reset(),
    };
    for (final MapEntry(key: name, value: changeIdentity) in resets.entries) {
      for (final MapEntry(key: layout, value: scrolls) in {
        'in a list': true,
        'on its own': false,
      }.entries) {
        // In a list the button's onPressed runs after the tap listener, once
        // the scroll gesture gives up; on its own it runs before.
        testWidgets(
            "$name in a tapped button's onPressed, $layout, "
            'still tracks the tap', (t) async {
          final channel = channelReplyingTo(Completer<void>()..complete());
          final amplitude = Amplitude(config(), channel);
          await amplitude.isBuilt;
          final logOut = ElevatedButton(
            key: const Key('b'),
            onPressed: () => unawaited(changeIdentity(amplitude)),
            child: const Text('Log out'),
          );
          await t.pumpWidget(MaterialApp(
            home: Scaffold(
              body: scrolls
                  ? ListView(children: [logOut])
                  : Center(child: logOut),
            ),
          ));

          await t.tap(find.byKey(const Key('b')));
          await t.pump();
          expect(tracked(channel).single['event_type'],
              '[Amplitude] Element Interacted');
        });
      }
    }

    testWidgets('setOptOut stops capture and updates the configuration',
        (t) async {
      final ready = Completer<void>()..complete();
      final channel = channelReplyingTo(ready);
      final amplitude = Amplitude(config(), channel);
      await amplitude.isBuilt;
      await t.pumpWidget(button());

      await amplitude.setOptOut(true);
      expect(amplitude.configuration.optOut, isTrue);
      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      verifyNever(channel.invokeMethod('track', any));

      await amplitude.setOptOut(false);
      expect(amplitude.configuration.optOut, isFalse);
      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      expect(trackCount(channel), 1);
    });

    testWidgets('a new instance with the same name takes over capture',
        (t) async {
      final ready = Completer<void>()..complete();
      final first = channelReplyingTo(ready);
      final second = channelReplyingTo(ready);
      Amplitude(config(), first);
      await Amplitude(config(), second).isBuilt;
      await t.pumpWidget(button());

      await t.tap(find.byKey(const Key('b')));
      await t.pump();
      verifyNever(first.invokeMethod('track', any));
      expect(trackCount(second), 1);
    });
  });
}
