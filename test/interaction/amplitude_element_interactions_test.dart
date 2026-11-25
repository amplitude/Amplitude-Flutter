import 'dart:async';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/experimental.dart';
import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';
import 'package:amplitude_flutter/src/interaction/observed_routes.dart';
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

    group('Screen Name', () {
      /// The Screen Name of each Element Interacted event, in tap order.
      List<String?> screens(MockMethodChannel channel) => tracked(channel)
          .where((e) => e['event_type'] == '[Amplitude] Element Interacted')
          .map((e) => (e['event_properties'] as Map)['[Amplitude] Screen Name']
              as String?)
          .toList();

      Widget app({NavigatorObserver? observer}) => MaterialApp(
            navigatorObservers: [if (observer != null) observer],
            routes: {
              '/': (_) => Scaffold(
                    body: Builder(
                      builder: (context) => Column(children: [
                        ElevatedButton(
                            key: const Key('home'),
                            onPressed: () {},
                            child: const Text('Home')),
                        ElevatedButton(
                            key: const Key('push'),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/checkout'),
                            child: const Text('Checkout')),
                      ]),
                    ),
                  ),
              '/checkout': (_) => Scaffold(
                    body: Builder(
                      builder: (context) => Column(children: [
                        ElevatedButton(
                            key: const Key('pay'),
                            onPressed: () {},
                            child: const Text('Pay')),
                        ElevatedButton(
                            key: const Key('dialog'),
                            onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (dialog) => AlertDialog(actions: [
                                    TextButton(
                                        key: const Key('ok'),
                                        onPressed: () {},
                                        child: const Text('OK')),
                                    TextButton(
                                        key: const Key('close'),
                                        onPressed: () =>
                                            Navigator.of(dialog).pop(),
                                        child: const Text('Close')),
                                  ]),
                                ),
                            child: const Text('Help')),
                        ElevatedButton(
                            key: const Key('done'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Done')),
                      ]),
                    ),
                  ),
            },
          );

      Future<Amplitude> ready(MockMethodChannel channel) async {
        final amplitude = Amplitude(config(), channel);
        await amplitude.isBuilt;
        return amplitude;
      }

      testWidgets('is the screen of the route the control is on', (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t
            .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));

        await t.tap(find.byKey(const Key('home')));
        await t.tap(find.byKey(const Key('push')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('pay')));
        await t.tap(find.byKey(const Key('dialog')));
        await t.pumpAndSettle();
        // A dialog isn't a screen: the page under it still is.
        await t.tap(find.byKey(const Key('ok')));
        final navigator = Navigator.of(t.element(find.byKey(const Key('ok'))));
        navigator.pop();
        await t.pumpAndSettle();
        navigator.pop();
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('home')));
        await t.pump();

        expect(screens(channel),
            ['/', '/', '/checkout', '/checkout', '/checkout', '/']);
      });

      // Outside a scrollable, onPressed runs before the tap listener, so
      // the route is already popped when the tap is read.
      testWidgets('is kept by a button that closes its own dialog or page',
          (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t
            .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));
        await t.tap(find.byKey(const Key('push')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('dialog')));
        await t.pumpAndSettle();

        await t.tap(find.byKey(const Key('close')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('done')));
        await t.pumpAndSettle();

        final events = tracked(channel)
            .where((e) => e['event_type'] == '[Amplitude] Element Interacted')
            .map((e) => e['event_properties'] as Map)
            .toList();
        expect(events.map((p) => p['[Amplitude] Screen Name']),
            ['/', '/checkout', '/checkout', '/checkout']);
        expect(events.last['[Amplitude] Hierarchy'],
            isNot(contains('Transition')));
      });

      testWidgets("uses the observer's nameExtractor, as Screen Viewed does",
          (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t.pumpWidget(app(
          observer: AmplitudeNavigatorObserver(amplitude,
              nameExtractor: (settings) => 'Screen ${settings.name}'),
        ));

        await t.tap(find.byKey(const Key('home')));
        await t.pump();
        expect(screens(channel), ['Screen /']);
      });

      testWidgets('is sent with screen views turned off', (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = Amplitude(
            config(
                autocapture: const AutocaptureOptions(
                    elementInteractions: ElementInteractionsEnabled())),
            channel);
        await amplitude.isBuilt;
        await t
            .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));

        await t.tap(find.byKey(const Key('home')));
        await t.pump();
        final events = tracked(channel);
        expect(events.map((e) => e['event_type']),
            ['[Amplitude] Element Interacted']);
        expect((events.single['event_properties'] as Map)[screenNameProperty],
            '/');
      });

      testWidgets('is left out when the nameExtractor throws', (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t.pumpWidget(app(
          observer: AmplitudeNavigatorObserver(amplitude,
              nameExtractor: (_) => throw Exception('extractor boom')),
        ));

        await t.tap(find.byKey(const Key('home')));
        await t.pump();
        expect(screens(channel), [null]);
      });

      testWidgets('the observer keeps routes only while taps are captured',
          (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t
            .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));
        expect(observedRoutes[amplitude]!.pages(), hasLength(1));
      });

      final notCapturing = <String, Amplitude Function(MockMethodChannel)>{
        "an app that didn't opt in": (channel) {
          AmplitudeExperimental.mobileElementInteractions = false;
          return Amplitude(config(), channel);
        },
        'element interactions turned off': (channel) => Amplitude(
            config(autocapture: const AutocaptureDisabled()), channel),
      };
      for (final MapEntry(key: name, value: create) in notCapturing.entries) {
        testWidgets('the observer keeps no routes for $name', (t) async {
          final channel = channelReplyingTo(Completer<void>()..complete());
          final amplitude = create(channel);
          await amplitude.isBuilt;
          await t
              .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));
          await t.tap(find.byKey(const Key('push')));
          await t.pumpAndSettle();
          expect(observedRoutes[amplitude], isNull);
        });
      }

      for (final observed in [false, true]) {
        testWidgets(
            observed
                ? "isn't hinted at with AmplitudeNavigatorObserver"
                : 'is hinted at once in debug without '
                    'AmplitudeNavigatorObserver', (t) async {
          final channel = channelReplyingTo(Completer<void>()..complete());
          final amplitude = await ready(channel);
          final printed = <String?>[];
          final original = debugPrint;
          debugPrint = (message, {wrapWidth}) => printed.add(message);
          try {
            await t.pumpWidget(app(
                observer:
                    observed ? AmplitudeNavigatorObserver(amplitude) : null));
            await t.tap(find.byKey(const Key('home')));
            await t.tap(find.byKey(const Key('home')));
            await t.pump();
          } finally {
            debugPrint = original;
          }
          expect(
              printed
                  .where((m) => m!.contains('add AmplitudeNavigatorObserver')),
              hasLength(observed ? 0 : 1));
        });
      }

      testWidgets('is left out without AmplitudeNavigatorObserver', (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        await ready(channel);
        await t.pumpWidget(app());

        await t.tap(find.byKey(const Key('home')));
        await t.pump();
        expect(screens(channel), [null]);
      });

      testWidgets('is left out on a route with no name', (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        final amplitude = await ready(channel);
        await t
            .pumpWidget(app(observer: AmplitudeNavigatorObserver(amplitude)));
        Navigator.of(t.element(find.byKey(const Key('home')))).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: ElevatedButton(
                  key: const Key('unnamed'),
                  onPressed: () {},
                  child: const Text('Go')),
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.tap(find.byKey(const Key('unnamed')));
        await t.pump();
        expect(screens(channel), [null]);
      });

      testWidgets("isn't taken from another instance's observer", (t) async {
        final channel = channelReplyingTo(Completer<void>()..complete());
        await ready(channel);
        final otherChannel = channelReplyingTo(Completer<void>()..complete());
        final other = Amplitude(
          Configuration(apiKey: 'key', instanceName: 'other'),
          otherChannel,
        );
        await other.isBuilt;
        await t.pumpWidget(app(observer: AmplitudeNavigatorObserver(other)));

        await t.tap(find.byKey(const Key('home')));
        await t.pump();
        expect(screens(channel), [null]);
      });
    });
  });
}
