import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/observers/amplitude_element_tap_detector.dart';
import 'package:amplitude_flutter/observers/amplitude_navigator_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Reuses the MockMethodChannel generated for amplitude_test.dart.
import '../amplitude_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMethodChannel mockChannel;

  Amplitude buildAmplitude({Autocapture? autocapture}) {
    mockChannel = MockMethodChannel();
    when(mockChannel.invokeMethod('init', any)).thenAnswer((_) async => null);
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);
    return Amplitude(
      Configuration(
        apiKey: 'k',
        autocapture: autocapture ?? const AutocaptureOptions(),
      ),
      mockChannel,
    );
  }

  Widget wrap(
    Amplitude amplitude,
    Widget child, {
    bool enabled = true,
    ElementTargetFilter? targetFilter,
    ScreenNameProvider? screenNameProvider,
    ElementPropertiesProvider? propertiesProvider,
  }) {
    return AmplitudeElementTapDetector(
      amplitude: amplitude,
      enabled: enabled,
      targetFilter: targetFilter,
      screenNameProvider: screenNameProvider ?? defaultScreenNameProvider,
      propertiesProvider: propertiesProvider,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  Map<String, dynamic> capturedTrackEvent() {
    final args = verify(mockChannel.invokeMethod('track', captureAny))
        .captured
        .single as Map;
    return (args['event'] as Map).cast<String, dynamic>();
  }

  Map<String, dynamic> capturedEventProperties() =>
      (capturedTrackEvent()['event_properties'] as Map).cast<String, dynamic>();

  setUp(() {
    AmplitudeNavigatorObserver.currentScreenName = null;
  });

  group('AmplitudeElementTapDetector', () {
    testWidgets('tapping an ElevatedButton tracks an element interaction',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      final event = capturedTrackEvent();
      expect(event['event_type'], elementInteractedEventType);
      final props = (event['event_properties'] as Map).cast<String, dynamic>();
      expect(props[elementActionProperty], 'touch');
      expect(props[elementTargetClassProperty], 'ElevatedButton');
      expect(props[elementTargetTextProperty], 'Save');
      expect(props[elementTargetSourceProperty], 'Flutter');
      expect(props[elementHierarchyProperty], isA<List<dynamic>>());
      expect((props[elementHierarchyProperty] as List).first, 'ElevatedButton');
    });

    testWidgets('a concrete control beats its internal gesture handlers',
        (tester) async {
      // ElevatedButton is built from an InkWell; the button must be reported,
      // not its internals.
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Go')),
      ));

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(capturedEventProperties()[elementTargetClassProperty],
          'ElevatedButton');
    });

    testWidgets('a control nested inside another control wins', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        SizedBox(
          width: 300,
          child: ListTile(
            onTap: () {},
            title: const Text('Row title'),
            trailing: IconButton(
              tooltip: 'Delete row',
              onPressed: () {},
              icon: const Icon(Icons.delete),
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'IconButton');
      expect(props[elementTargetTextProperty], 'Delete row');
    });

    testWidgets('a CheckboxListTile is reported, not its internals',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        CheckboxListTile(
          value: false,
          onChanged: (_) {},
          title: const Text('Enable Wi-Fi'),
        ),
      ));

      await tester.tap(find.text('Enable Wi-Fi'));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'CheckboxListTile');
      expect(props[elementTargetTextProperty], 'Enable Wi-Fi');
    });

    testWidgets('tapping the checkbox itself reports the CheckboxListTile',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        CheckboxListTile(
          value: false,
          onChanged: (_) {},
          title: const Text('Enable Wi-Fi'),
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'CheckboxListTile');
      expect(props[elementTargetTextProperty], 'Enable Wi-Fi');
    });

    testWidgets('a SwitchListTile is reported, not its internals',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        SwitchListTile(
          value: false,
          onChanged: (_) {},
          title: const Text('Dark mode'),
        ),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'SwitchListTile');
      expect(props[elementTargetTextProperty], 'Dark mode');
    });

    testWidgets('sibling containment: the tapped button is reported',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: () {}, child: const Text('Left')),
            TextButton(onPressed: () {}, child: const Text('Right')),
          ],
        ),
      ));

      await tester.tap(find.text('Right'));
      await tester.pump();

      expect(capturedEventProperties()[elementTargetTextProperty], 'Right');
    });

    testWidgets('GestureDetector with onTap is captured', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFF000000),
            child: const Text('Custom'),
          ),
        ),
      ));

      await tester.tap(find.text('Custom'));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'GestureDetector');
      expect(props[elementTargetTextProperty], 'Custom');
    });

    testWidgets('Semantics label wins over descendant text', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(
          onPressed: () {},
          child: Semantics(
            label: 'Submit order',
            child: const Text('OK'),
          ),
        ),
      ));

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(
          capturedEventProperties()[elementTargetTextProperty], 'Submit order');
    });

    testWidgets("a nested control's label does not become the target text",
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ListTile(
          onTap: () {},
          title: const Text('Wi-Fi'),
          trailing: IconButton(
            onPressed: () {},
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
          ),
        ),
      ));

      await tester.tap(find.text('Wi-Fi'));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'ListTile');
      expect(props[elementTargetTextProperty], 'Wi-Fi');
    });

    testWidgets('tapping the nested control itself reports its own label',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ListTile(
          onTap: () {},
          title: const Text('Wi-Fi'),
          trailing: IconButton(
            onPressed: () {},
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'IconButton');
      expect(props[elementTargetTextProperty], 'Delete');
    });

    testWidgets('a ValueKey is reported as the target resource',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(
          key: const ValueKey('save-button'),
          onPressed: () {},
          child: const Text('Save'),
        ),
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(capturedEventProperties()[elementTargetResourceProperty],
          'save-button');
    });

    testWidgets('only the active IndexedStack child is reported',
        (tester) async {
      // Keep-alive tabs: IndexedStack lays out ALL children at full size but
      // paints and hit-tests only the active one. A hidden tab's button
      // occupying the same coordinates must never claim the tap.
      final amplitude = buildAmplitude();
      Widget tab(String label) => Center(
            child: SizedBox(
              width: 200,
              height: 80,
              child: ElevatedButton(onPressed: () {}, child: Text(label)),
            ),
          );
      await tester.pumpWidget(wrap(
        amplitude,
        SizedBox(
          width: 300,
          height: 300,
          child: IndexedStack(index: 0, children: [tab('Tab A'), tab('Tab B')]),
        ),
      ));

      await tester.tap(find.text('Tab A'));
      await tester.pump();

      expect(capturedEventProperties()[elementTargetTextProperty], 'Tab A');
    });

    testWidgets('switching the IndexedStack index reports the new active tab',
        (tester) async {
      final amplitude = buildAmplitude();
      Widget tab(String label) => Center(
            child: SizedBox(
              width: 200,
              height: 80,
              child: ElevatedButton(onPressed: () {}, child: Text(label)),
            ),
          );
      Widget build(int index) => wrap(
            amplitude,
            SizedBox(
              width: 300,
              height: 300,
              child: IndexedStack(
                  index: index, children: [tab('Tab A'), tab('Tab B')]),
            ),
          );

      await tester.pumpWidget(build(1));
      await tester.tap(find.text('Tab B'));
      await tester.pump();

      expect(capturedEventProperties()[elementTargetTextProperty], 'Tab B');
    });

    testWidgets('an invisible Visibility.maintain subtree is not reported',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        Visibility.maintain(
          visible: false,
          child: ElevatedButton(onPressed: () {}, child: const Text('Ghost')),
        ),
      ));

      await tester.tapAt(tester.getCenter(find.text('Ghost')));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('an Offstage subtree is not reported', (tester) async {
      // Under tight constraints an offstage RenderBox keeps its full size, so
      // geometric containment alone would not prune it.
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        SizedBox(
          width: 200,
          height: 200,
          child: Offstage(
            child:
                ElevatedButton(onPressed: () {}, child: const Text('Offstage')),
          ),
        ),
      ));

      await tester
          .tapAt(tester.getCenter(find.text('Offstage', skipOffstage: false)));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('a widget behind a dialog barrier is not reported',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(AmplitudeElementTapDetector(
        amplitude: amplitude,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(title: Text('Dialog')),
                  ),
                  child: const Text('Covered'),
                ),
              ),
            ),
          ),
        ),
      ));

      final buttonCenter = tester.getCenter(find.text('Covered'));
      await tester.tapAt(buttonCenter);
      await tester.pumpAndSettle();
      clearInteractions(mockChannel);

      // The dialog's barrier now covers the button. Its geometry still
      // contains the tap position, but the tap can only reach the barrier.
      await tester.tapAt(buttonCenter);
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('a button inside IgnorePointer is not reported',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        IgnorePointer(
          child: ElevatedButton(onPressed: () {}, child: const Text('Ignored')),
        ),
      ));

      await tester.tapAt(tester.getCenter(find.text('Ignored')));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('a button inside AbsorbPointer is not reported',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        AbsorbPointer(
          child:
              ElevatedButton(onPressed: () {}, child: const Text('Absorbed')),
        ),
      ));

      await tester.tapAt(tester.getCenter(find.text('Absorbed')));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('taps on non-interactive widgets are not tracked',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(amplitude, const Text('Just text')));

      await tester.tap(find.text('Just text'));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('disabled buttons are not tracked', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ));

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('drags and scrolls are not tracked', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        SizedBox(
          height: 200,
          child: ListView(
            children: [
              ListTile(onTap: () {}, title: const Text('Item 1')),
              ListTile(onTap: () {}, title: const Text('Item 2')),
              ListTile(onTap: () {}, title: const Text('Item 3')),
            ],
          ),
        ),
      ));

      await tester.drag(find.text('Item 1'), const Offset(0, -80));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('enabled: false disables capture', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
        enabled: false,
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('targetFilter can veto a widget', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
        targetFilter: (widget) => widget is! ElevatedButton,
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      verifyNever(mockChannel.invokeMethod('track', any));
    });

    testWidgets('screen name from the navigator observer is attached',
        (tester) async {
      final amplitude = buildAmplitude();
      AmplitudeNavigatorObserver.currentScreenName = '/settings';
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(capturedEventProperties()[screenNameProperty], '/settings');
    });

    testWidgets('custom screenNameProvider overrides the default',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
        screenNameProvider: () => 'customScreen',
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(capturedEventProperties()[screenNameProperty], 'customScreen');
    });

    testWidgets('propertiesProvider properties are merged into the event',
        (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(onPressed: () {}, child: const Text('Save')),
        propertiesProvider: () => {
          'organization_id': 'org-1',
          'organization_name': 'Acme',
        },
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props['organization_id'], 'org-1');
      expect(props['organization_name'], 'Acme');
    });

    testWidgets('taps inside a dialog are captured', (tester) async {
      final amplitude = buildAmplitude();
      await tester.pumpWidget(AmplitudeElementTapDetector(
        amplitude: amplitude,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      actions: [
                        TextButton(
                            onPressed: () {}, child: const Text('Confirm')),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      clearInteractions(mockChannel);

      await tester.tap(find.text('Confirm'));
      await tester.pump();

      final props = capturedEventProperties();
      expect(props[elementTargetClassProperty], 'TextButton');
      expect(props[elementTargetTextProperty], 'Confirm');
    });

    testWidgets('a failing track never breaks the tap', (tester) async {
      final amplitude = buildAmplitude();
      when(mockChannel.invokeMethod('track', any))
          .thenThrow(Exception('track boom'));
      var tapped = false;
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(
          onPressed: () => tapped = true,
          child: const Text('Save'),
        ),
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('long target text is truncated to 128 characters',
        (tester) async {
      final amplitude = buildAmplitude();
      final longText = 'x' * 500;
      await tester.pumpWidget(wrap(
        amplitude,
        ElevatedButton(
          onPressed: () {},
          child: Text(longText, overflow: TextOverflow.ellipsis),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      final text =
          capturedEventProperties()[elementTargetTextProperty] as String;
      expect(text.length, 128);
    });
  });

  group('AmplitudeNavigatorObserver.currentScreenName', () {
    testWidgets('is updated as screens are tracked', (tester) async {
      final amplitude = buildAmplitude(
          autocapture: const AutocaptureOptions(screenViews: true));
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
      expect(AmplitudeNavigatorObserver.currentScreenName, '/');

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(AmplitudeNavigatorObserver.currentScreenName, '/details');
    });
  });
}
