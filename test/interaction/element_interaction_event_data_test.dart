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
  final target = TargetResolver.resolve(
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

  hierarchyAndScreenName();
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          key: const ValueKey('user-42'),
          title: const Text('Jane Doe'),
          onTap: () {},
          trailing: TextButton(
              key: const Key('buy'),
              onPressed: () {},
              child: const Text('Buy')),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              key: const Key('action'),
              onPressed: () {},
              icon: const Icon(Icons.delete)),
        ]),
        body: ListView(children: [
          const ProductCard(),
          ElevatedButton(
              key: const Key('save'),
              onPressed: () {},
              child: const Text('Save')),
          ElevatedButton(
            key: const Key('push'),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DetailPage())),
            child: const Text('Push'),
          ),
          ElevatedButton(
            key: const Key('dialog'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(actions: [
                TextButton(
                    key: const Key('ok'),
                    onPressed: () {},
                    child: const Text('OK')),
              ]),
            ),
            child: const Text('Dialog'),
          ),
        ]),
      );
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
              key: const Key('detail'),
              onPressed: () {},
              child: const Text('Detail')),
        ),
      );
}

void hierarchyAndScreenName() {
  group('Hierarchy', () {
    testWidgets('keeps the components an app would recognize', (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      expect(dataAt(t, byId('save')).hierarchy,
          'ElevatedButton → ListView → HomePage');
      expect(dataAt(t, byId('buy')).hierarchy,
          'TextButton → ListTile → Material → ProductCard → ListView → HomePage');
      expect(dataAt(t, byId('action')).hierarchy,
          'IconButton → NavigationToolbar → Material → AppBar → HomePage');
    });

    testWidgets('stops at the page of a pushed route or a dialog', (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      await t.tap(byId('dialog'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('ok')).hierarchy,
          'TextButton → Material → AlertDialog');
      Navigator.of(t.element(byId('ok'))).pop();
      await t.pumpAndSettle();

      await t.tap(byId('push'));
      await t.pumpAndSettle();
      expect(
          dataAt(t, byId('detail')).hierarchy, 'ElevatedButton → DetailPage');
    });

    testWidgets('a page built without a route stops at the Overlay', (t) async {
      await t.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: [
          OverlayEntry(builder: (_) => const DetailPageBody()),
        ]),
      ));
      expect(dataAt(t, byId('bare')).hierarchy,
          'GestureDetector → DetailPageBody');
      expect(dataAt(t, byId('bare')).screenName, isNull);
    });

    testWidgets('is cut at 1,024 characters, keeping the target', (t) async {
      // A Padding between each wrapper and what it holds, so each is kept
      // and the button is still reported as itself.
      Widget nest(int depth) => depth == 0
          ? ElevatedButton(
              key: const Key('deep'), onPressed: () {}, child: const Text('Go'))
          : LongNamedWrapperForHierarchyLimits(
              child: Padding(padding: EdgeInsets.zero, child: nest(depth - 1)));
      await t.pumpWidget(MaterialApp(home: Scaffold(body: nest(60))));
      final hierarchy = dataAt(t, byId('deep')).hierarchy!;
      expect(hierarchy.length, lessThanOrEqualTo(1024));
      expect(hierarchy, startsWith('ElevatedButton → '));
      expect(hierarchy.length,
          greaterThan(1024 - ' → LongNamedWrapperForHierarchyLimits'.length));
    });

    testWidgets('is left out on obfuscated builds (Q10)', (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      final target = TargetResolver.resolve(
        PointerDownEvent(
            position: t.getCenter(byId('save')), viewId: t.view.viewId),
      )!;
      final data = ElementInteractionEventData.from(target, obfuscated: true);
      expect(data.hierarchy, isNull);
      expect(data.screenName, '/');
    });
  });

  group('Screen Name', () {
    testWidgets("is the route's name", (t) async {
      await t.pumpWidget(MaterialApp(
        initialRoute: '/checkout',
        routes: {'/checkout': (_) => const DetailPage()},
      ));
      expect(dataAt(t, byId('detail')).screenName, '/checkout');
    });

    testWidgets("falls back to an unnamed route's page widget (Q27)",
        (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      expect(dataAt(t, byId('save')).screenName, '/');
      await t.tap(byId('push'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('detail')).screenName, 'DetailPage');
      Navigator.of(t.element(byId('detail'))).pop();
      await t.pumpAndSettle();

      await t.tap(byId('dialog'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('ok')).screenName, 'AlertDialog');
    });

    testWidgets('has no fallback on obfuscated builds', (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      await t.tap(byId('push'));
      await t.pumpAndSettle();
      final target = TargetResolver.resolve(
        PointerDownEvent(
            position: t.getCenter(byId('detail')), viewId: t.view.viewId),
      )!;
      expect(
          ElementInteractionEventData.from(target, obfuscated: true).screenName,
          isNull);
    });
  });
}

class DetailPageBody extends StatelessWidget {
  const DetailPageBody({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          key: const Key('bare'),
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );
}

class LongNamedWrapperForHierarchyLimits extends StatelessWidget {
  const LongNamedWrapperForHierarchyLimits({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
