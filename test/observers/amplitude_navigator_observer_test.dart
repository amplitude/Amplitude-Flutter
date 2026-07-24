import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Reuses the MockMethodChannel generated for amplitude_test.dart.
import '../amplitude_test.mocks.dart';

/// A route that is not a [PageRoute], used to verify the default route filter.
class _NonPageRoute extends Route<dynamic> {
  _NonPageRoute(RouteSettings settings) : super(settings: settings);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMethodChannel mockChannel;

  Amplitude buildAmplitude(Autocapture autocapture) {
    mockChannel = MockMethodChannel();
    when(mockChannel.invokeMethod('init', any)).thenAnswer((_) async => null);
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);
    return Amplitude(
      Configuration(apiKey: 'k', autocapture: autocapture),
      mockChannel,
    );
  }

  Route<dynamic> pageRoute(String? name) => MaterialPageRoute<dynamic>(
        settings: RouteSettings(name: name),
        builder: (_) => const SizedBox(),
      );

  Map<String, dynamic> capturedTrackEvent() {
    final args =
        verify(mockChannel.invokeMethod('track', captureAny)).captured.single
            as Map;
    return (args['event'] as Map).cast<String, dynamic>();
  }

  group('AmplitudeNavigatorObserver', () {
    test('didPush tracks a screen view for the pushed route', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(pageRoute('/home'), null);

      final event = capturedTrackEvent();
      expect(event['event_type'], screenViewedEventType);
      expect(event['event_properties'], {screenNameProperty: '/home'});
    });

    test('didReplace tracks the new route', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didReplace(
        newRoute: pageRoute('/new'),
        oldRoute: pageRoute('/old'),
      );

      final event = capturedTrackEvent();
      expect(event['event_properties'], {screenNameProperty: '/new'});
    });

    test('didPop tracks the revealed previous route', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPop(pageRoute('/top'), pageRoute('/below'));

      final event = capturedTrackEvent();
      expect(event['event_properties'], {screenNameProperty: '/below'});
    });

    test('dismissing a dialog/popup does not re-track the underlying page', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      // A non-PageRoute (dialog) is popped while a page is underneath; the page
      // was already reported when pushed, so popping the dialog must not re-fire.
      observer.didPop(
        _NonPageRoute(const RouteSettings(name: '/dialog')),
        pageRoute('/home'),
      );

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    test('AutocaptureEnabled enables screen view capture', () {
      final amplitude = buildAmplitude(const AutocaptureEnabled());
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(pageRoute('/home'), null);

      verify(mockChannel.invokeMethod('track', any)).called(1);
    });

    test('does not track when screenViews is disabled', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: false));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(pageRoute('/home'), null);

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    test('does not track when autocapture is fully disabled', () {
      final amplitude = buildAmplitude(const AutocaptureDisabled());
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(pageRoute('/home'), null);

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    test('does not track routes with a null or empty name', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(pageRoute(null), null);
      observer.didPush(pageRoute(''), null);

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    test('default route filter ignores non-PageRoutes (e.g. dialogs)', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      observer.didPush(
          _NonPageRoute(const RouteSettings(name: '/dialog')), null);

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    test('uses a custom nameExtractor when provided', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(
        amplitude,
        nameExtractor: (settings) => 'screen:${settings.name}',
      );

      observer.didPush(pageRoute('/home'), null);

      final event = capturedTrackEvent();
      expect(event['event_properties'], {screenNameProperty: 'screen:/home'});
    });

    testWidgets('tracks screen views through a real MaterialApp navigation',
        (tester) async {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(amplitude);

      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [observer],
        routes: {
          '/': (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/details'),
                  child: const Text('Go'),
                ),
              ),
          '/details': (context) => const Scaffold(body: Text('Details')),
        },
      ));
      await tester.pumpAndSettle();

      // Initial route is tracked on first frame.
      expect(capturedTrackEvent()['event_properties'],
          {screenNameProperty: '/'});

      clearInteractions(mockChannel);
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(capturedTrackEvent()['event_properties'],
          {screenNameProperty: '/details'});
    });

    test('a failing track never breaks navigation', () async {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      when(mockChannel.invokeMethod('track', any))
          .thenThrow(Exception('track boom'));
      final observer = AmplitudeNavigatorObserver(amplitude);

      expect(() => observer.didPush(pageRoute('/home'), null), returnsNormally);
      // Let the rejected track future settle; the observer handles it.
      await Future<void>.delayed(Duration.zero);
    });

    test('a throwing nameExtractor never breaks navigation', () {
      final amplitude =
          buildAmplitude(const AutocaptureOptions(screenViews: true));
      final observer = AmplitudeNavigatorObserver(
        amplitude,
        nameExtractor: (_) => throw Exception('extractor boom'),
      );

      expect(() => observer.didPush(pageRoute('/home'), null), returnsNormally);
      verifyNever(mockChannel.invokeMethod('track', any));
    });
  });
}
