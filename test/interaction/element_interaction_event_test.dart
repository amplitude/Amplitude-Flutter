import 'package:amplitude_flutter/src/interaction/element_interaction_event.dart';
import 'package:amplitude_flutter/src/interaction/element_interaction_event_data.dart';
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'route_recorder.dart';

/// Installed in every app here, as AmplitudeNavigatorObserver would be.
var recorder = RouteRecorder();

Finder byId(String id) => find.byKey(ValueKey(id));

ElementInteractionEvent eventAt(WidgetTester t, Finder finder) {
  final target = TargetResolver.resolve(
    PointerDownEvent(position: t.getCenter(finder), viewId: t.view.viewId),
  )!;
  return ElementInteractionEvent(
    ElementInteractionEventData.from(target, routes: recorder.routes),
    timestamp: 1767225600000,
  );
}

void main() {
  setUp(() => recorder = RouteRecorder());
  testWidgets('an Element Interacted event for a button', (t) async {
    await t.pumpWidget(MaterialApp(
      navigatorObservers: [recorder],
      home: Scaffold(
        body: Center(
          child: Semantics(
            identifier: 'checkout',
            child: ElevatedButton(
              key: const Key('b'),
              onPressed: () {},
              child: const Text('Pay'),
            ),
          ),
        ),
      ),
    ));

    final event = eventAt(t, byId('b'));

    expect(event.eventType, '[Amplitude] Element Interacted');
    expect(event.timestamp, 1767225600000);
    expect(event.eventProperties, {
      '[Amplitude] Action': 'touch',
      '[Amplitude] Target Source': 'Flutter',
      '[Amplitude] Target View Class': 'ElevatedButton',
      '[Amplitude] Target Text': 'Pay',
      '[Amplitude] Target Accessibility Identifier': 'checkout',
      // home: is the Scaffold itself, so it is the page.
      '[Amplitude] Hierarchy': 'ElevatedButton → Scaffold',
      '[Amplitude] Screen Name': '/',
    });
  });

  // Only strings a developer wrote are sent. A tile's title and a key are
  // often user data.
  testWidgets("a tile's text and key appear nowhere in its event", (t) async {
    await t.pumpWidget(MaterialApp(
      navigatorObservers: [recorder],
      home: Scaffold(
        body: ListView(children: [
          ListTile(
            key: const ValueKey('user-42'),
            title: const Text('Jane Doe', semanticsLabel: 'Jane Doe'),
            subtitle: const Text('jane@example.com'),
            onTap: () {},
          ),
        ]),
      ),
    ));

    final event = eventAt(t, find.text('Jane Doe'));

    expect(event.eventProperties!['[Amplitude] Target View Class'], 'ListTile');
    expect(event.toMap().toString(), isNot(contains('Jane')));
    expect(event.toMap().toString(), isNot(contains('jane@')));
    expect(event.toMap().toString(), isNot(contains('user-42')));
    expect(event.eventProperties!.keys, isNot(contains(contains('Resource'))));
  });
}
