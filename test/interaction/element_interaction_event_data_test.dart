import 'package:amplitude_flutter/src/interaction/element_interaction_event_data.dart';
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
    );

Finder byId(String id) => find.byKey(ValueKey(id));

/// The event data for a pointer-down at the center of [finder], built as
/// the capture builds it: from the resolved target, while it is mounted.
ElementInteractionEventData dataAt(WidgetTester t, Finder finder) {
  final target = const TargetResolver().resolve(
    PointerDownEvent(position: t.getCenter(finder), viewId: t.view.viewId),
  );
  expect(target, isNotNull, reason: 'nothing resolved at $finder');
  return ElementInteractionEventData.from(target!);
}

/// An app wrapper whose build returns a Material button directly.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key});

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: () {}, child: const Text('Primary'));
}

/// An app control: a Semantics button around a GestureDetector.
class FancyButton extends StatelessWidget {
  const FancyButton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(onTap: () {}, child: const Text('Fancy')),
      );
}

void main() {
  group('Target Text', () {
    final buttons = <String, Widget>{
      'ElevatedButton':
          ElevatedButton(onPressed: () {}, child: const Text('Save')),
      'ElevatedButton.icon': ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Save')),
      'TextButton': TextButton(onPressed: () {}, child: const Text('Save')),
      'OutlinedButton':
          OutlinedButton(onPressed: () {}, child: const Text('Save')),
      'FilledButton': FilledButton(onPressed: () {}, child: const Text('Save')),
      'MaterialButton':
          MaterialButton(onPressed: () {}, child: const Text('Save')),
      'CupertinoButton':
          CupertinoButton(onPressed: () {}, child: const Text('Save')),
      'FloatingActionButton.extended': FloatingActionButton.extended(
          onPressed: () {}, label: const Text('Save')),
    };
    for (final MapEntry(key: name, value: button) in buttons.entries) {
      testWidgets('$name sends its text', (t) async {
        await t
            .pumpWidget(app(KeyedSubtree(key: const Key('b'), child: button)));
        expect(dataAt(t, byId('b')).targetText, 'Save');
      });
    }

    testWidgets('an app component returning a button sends its text',
        (t) async {
      await t.pumpWidget(app(const PrimaryButton(key: Key('b'))));
      final data = dataAt(t, byId('b'));
      expect(data.targetViewClass, 'PrimaryButton');
      expect(data.targetText, 'Primary');
    });

    testWidgets('an empty button text is sent as it is', (t) async {
      await t.pumpWidget(
        app(TextButton(
            key: const Key('b'), onPressed: () {}, child: const Text(''))),
      );
      expect(dataAt(t, byId('b')).targetText, '');
    });

    // Their text is often user data (decision Q29). A ListTile is a
    // Semantics button on recent Flutter, so a rule based on Semantics
    // would send its title; the name rule doesn't.
    final silent = <String, Widget>{
      'ListTile': ListTile(title: const Text('Jane Doe'), onTap: () {}),
      'InputChip':
          InputChip(label: const Text('jane@example.com'), onPressed: () {}),
      'ActionChip': ActionChip(label: const Text('Jane Doe'), onPressed: () {}),
      'DropdownButton': DropdownButton<int>(
        value: 1,
        onChanged: (_) {},
        items: const [
          DropdownMenuItem(value: 1, child: Text('Jane Doe')),
          DropdownMenuItem(value: 2, child: Text('John Doe')),
        ],
      ),
      'an app Semantics button': const FancyButton(),
      'a GestureDetector':
          GestureDetector(onTap: () {}, child: const Text('Jane Doe')),
    };
    for (final MapEntry(key: name, value: control) in silent.entries) {
      testWidgets('$name sends no text', (t) async {
        await t
            .pumpWidget(app(KeyedSubtree(key: const Key('c'), child: control)));
        expect(dataAt(t, byId('c')).targetText, isNull);
      });
    }

    testWidgets("an icon's glyph and a nested control's text are skipped",
        (t) async {
      await t.pumpWidget(app(ElevatedButton.icon(
        key: const Key('b'),
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      )));
      expect(dataAt(t, byId('b')).targetText, 'Add');
    });
  });

  group('Target Accessibility Label', () {
    testWidgets("an IconButton's tooltip", (t) async {
      await t.pumpWidget(app(IconButton(
        key: const Key('b'),
        tooltip: 'Delete',
        onPressed: () {},
        icon: const Icon(Icons.delete),
      )));
      expect(dataAt(t, byId('b')).accessibilityLabel, 'Delete');
    });

    testWidgets("an Icon's semanticLabel, before a tooltip", (t) async {
      await t.pumpWidget(app(IconButton(
        key: const Key('b'),
        tooltip: 'Favorite',
        onPressed: () {},
        icon: const Icon(Icons.star, semanticLabel: 'Star'),
      )));
      expect(dataAt(t, byId('b')).accessibilityLabel, 'Star');
    });

    testWidgets('a Semantics label just around the control', (t) async {
      await t.pumpWidget(app(Semantics(
        label: 'Checkout',
        child: ElevatedButton(
            key: const Key('b'), onPressed: () {}, child: const Text('Go')),
      )));
      expect(dataAt(t, byId('b')).accessibilityLabel, 'Checkout');
    });

    testWidgets('not a label around a group of controls', (t) async {
      await t.pumpWidget(app(Semantics(
        label: 'Toolbar',
        child: Row(children: [
          ElevatedButton(
              key: const Key('b'), onPressed: () {}, child: const Text('Go')),
          ElevatedButton(onPressed: () {}, child: const Text('Stop')),
        ]),
      )));
      expect(dataAt(t, byId('b')).accessibilityLabel, isNull);
    });

    testWidgets("not Text's semanticsLabel, which is its visible text",
        (t) async {
      await t.pumpWidget(app(ListTile(
        key: const Key('c'),
        title: const Text('Jane Doe', semanticsLabel: 'Jane Doe'),
        onTap: () {},
      )));
      expect(dataAt(t, byId('c')).accessibilityLabel, isNull);
    });

    testWidgets("not a nested control's tooltip", (t) async {
      await t.pumpWidget(app(ListTile(
        key: const Key('c'),
        title: const Text('Row'),
        onTap: () {},
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () {},
          icon: const Icon(Icons.delete),
        ),
      )));
      expect(dataAt(t, find.text('Row')).accessibilityLabel, isNull);
    });

    testWidgets('not the label of a button wrapped in a GestureDetector',
        (t) async {
      await t.pumpWidget(app(GestureDetector(
        key: const Key('g'),
        onTap: () {},
        child: ElevatedButton(
          onPressed: null,
          child: Semantics(label: 'Inner', child: const Text('Off')),
        ),
      )));
      final data = dataAt(t, byId('g'));
      expect(data.targetViewClass, 'GestureDetector');
      expect(data.accessibilityLabel, isNull);
    });

    // Q25: a NavigationBar item resolves to its InkWell (a Q28 gap); its
    // destination's Tooltip sits around the item, behind a branch.
    testWidgets('a NavigationBar destination sends no label', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list), label: 'Lists'),
          ]),
        ),
      ));
      expect(dataAt(t, find.text('Lists')).accessibilityLabel, isNull);
    });
  });

  group('Target Accessibility Identifier', () {
    testWidgets('comes from Semantics.identifier', (t) async {
      await t.pumpWidget(app(Semantics(
        identifier: 'checkout-button',
        child: TextButton(
            key: const Key('b'), onPressed: () {}, child: const Text('Pay')),
      )));
      expect(dataAt(t, byId('b')).accessibilityIdentifier, 'checkout-button');
    });

    testWidgets('never from a key', (t) async {
      await t.pumpWidget(app(TextButton(
          key: const ValueKey('user-42'),
          onPressed: () {},
          child: const Text('Pay'))));
      final data = dataAt(t, byId('user-42'));
      expect(data.accessibilityIdentifier, isNull);
      expect(
        [data.targetViewClass, data.targetText, data.accessibilityLabel],
        everyElement(isNot(contains('user-42'))),
      );
    });
  });

  testWidgets('targetElement identifies the tapped control', (t) async {
    await t.pumpWidget(app(ElevatedButton(
        key: const Key('b'), onPressed: () {}, child: const Text('Go'))));
    final data = dataAt(t, byId('b'));
    expect(data.targetElement.target, same(t.element(byId('b'))));
  });

  testWidgets('a GestureDetector around a whole page stays cheap', (t) async {
    await t.pumpWidget(app(GestureDetector(
      key: const Key('g'),
      onTap: () {},
      child: SingleChildScrollView(
        child: Column(children: [
          for (var i = 0; i < 500; i++) const Text('row'),
          Semantics(label: 'Far away', child: const SizedBox(height: 1)),
        ]),
      ),
    )));
    final data = dataAt(t, find.text('row').first);
    expect(data.targetViewClass, 'GestureDetector');
    expect(data.accessibilityLabel, isNull);
  });
}
