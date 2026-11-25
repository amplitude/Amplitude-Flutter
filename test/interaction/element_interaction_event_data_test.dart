import 'dart:async';

import 'package:amplitude_flutter/src/interaction/element_interaction_event_data.dart';
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'route_recorder.dart';

/// Installed in every app here, as AmplitudeNavigatorObserver would be.
var recorder = RouteRecorder();

Widget app(Widget child) => MaterialApp(
      navigatorObservers: [recorder],
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
  return ElementInteractionEventData.from(target!, routes: recorder.routes);
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
  setUp(() => recorder = RouteRecorder());
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

    // Their text is often user data. A ListTile is a Semantics button on
    // recent Flutter, so a rule based on Semantics would send its title;
    // the name rule doesn't.
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

    // A GestureDetector that dismisses the keyboard often wraps a whole
    // page, and a tap on its plain content resolves to it. Labels elsewhere
    // on the page aren't its own.
    testWidgets("not a page's labels, for a handler wrapping the page",
        (t) async {
      await t.pumpWidget(app(GestureDetector(
        onTap: () {},
        child: Column(children: [
          const Text('Welcome back', key: Key('plain')),
          Semantics(label: 'Profile of Jane Doe', child: const Text('Jane')),
          Semantics(identifier: 'profile-header', child: const Text('Hi')),
        ]),
      )));
      final data = dataAt(t, byId('plain'));
      expect(data.targetViewClass, 'GestureDetector');
      expect(data.accessibilityLabel, isNull);
      expect(data.accessibilityIdentifier, isNull);
    });

    testWidgets("an InkWell's icon label, when the icon is all it shows",
        (t) async {
      await t.pumpWidget(app(InkWell(
        key: const Key('i'),
        onTap: () {},
        child: const Icon(Icons.delete, semanticLabel: 'Delete'),
      )));
      expect(dataAt(t, byId('i')).accessibilityLabel, 'Delete');
    });

    // As on iOS and Android, which read only the tapped view's own label.
    // Semantics around the card still labels it.
    testWidgets('not a label beside other content in a bare handler',
        (t) async {
      await t.pumpWidget(app(GestureDetector(
        key: const Key('g'),
        onTap: () {},
        child: const Row(children: [
          Icon(Icons.star, semanticLabel: 'Star'),
          Text('Save'),
        ]),
      )));
      final data = dataAt(t, find.text('Save'));
      expect(data.targetViewClass, 'GestureDetector');
      expect(data.accessibilityLabel, isNull);
    });

    // Material dialogs and sheets label their route ('Alert', 'Dialog') in
    // the device's language. With one control inside, nothing with more
    // than one child stops the climb before that label.
    testWidgets("not the label of a bottom sheet it's alone in", (t) async {
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ElevatedButton(
                    key: const Key('b'),
                    onPressed: () {},
                    child: const Text('Share')),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await t.tap(byId('open'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('b')).accessibilityLabel, isNull);
    });

    testWidgets("not the label of a dialog it's alone in", (t) async {
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(actions: [
                  TextButton(
                      key: const Key('b'),
                      onPressed: () {},
                      child: const Text('OK')),
                ]),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await t.tap(byId('open'));
      await t.pumpAndSettle();
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

    // A NavigationBar item resolves to its InkWell, a known gap; its
    // destination's Tooltip sits around the item, behind a branch.
    testWidgets('a NavigationBar destination sends no label', (t) async {
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
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
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      expect(dataAt(t, byId('save')).hierarchy,
          'ElevatedButton → ListView → HomePage');
      expect(dataAt(t, byId('buy')).hierarchy,
          'TextButton → ListTile → Material → ProductCard → ListView → HomePage');
      expect(dataAt(t, byId('action')).hierarchy,
          'IconButton → NavigationToolbar → Material → AppBar → HomePage');
    });

    testWidgets('stops at the page of a pushed route or a dialog', (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
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
      await t.pumpWidget(MaterialApp(
          navigatorObservers: [recorder], home: Scaffold(body: nest(60))));
      final hierarchy = dataAt(t, byId('deep')).hierarchy!;
      expect(hierarchy.length, lessThanOrEqualTo(1024));
      expect(hierarchy, startsWith('ElevatedButton → '));
      expect(hierarchy.length,
          greaterThan(1024 - ' → LongNamedWrapperForHierarchyLimits'.length));
    });

    testWidgets('is left out on obfuscated builds', (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      final target = TargetResolver.resolve(
        PointerDownEvent(
            position: t.getCenter(byId('save')), viewId: t.view.viewId),
      )!;
      final data = ElementInteractionEventData.from(target,
          routes: recorder.routes, obfuscated: true);
      expect(data.hierarchy, isNull);
      expect(data.screenName, '/');
    });
  });

  group('Screen Name', () {
    testWidgets("is the route's name", (t) async {
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        initialRoute: '/checkout',
        routes: {'/checkout': (_) => const DetailPage()},
      ));
      expect(dataAt(t, byId('detail')).screenName, '/checkout');
    });

    testWidgets('is left out on a route with no name, as in screen views',
        (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      expect(dataAt(t, byId('save')).screenName, '/');
      await t.tap(byId('push'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('detail')).screenName, isNull);
    });

    testWidgets("in a dialog is the name of the screen it's shown over",
        (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      await t.tap(byId('dialog'));
      await t.pumpAndSettle();
      final data = dataAt(t, byId('ok'));
      expect(data.screenName, '/');
      expect(data.hierarchy, 'TextButton → Material → AlertDialog');
    });

    testWidgets("in a nested navigator is the inner route's name", (t) async {
      final inner = RouteRecorder();
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        home: Scaffold(
          body: Navigator(
            observers: [inner],
            pages: const [
              MaterialPage<void>(name: 'inner', child: DetailPage()),
            ],
            onPopPage: (_, __) => false,
          ),
        ),
      ));
      final target = TargetResolver.resolve(PointerDownEvent(
          position: t.getCenter(byId('detail')), viewId: t.view.viewId))!;
      final data =
          ElementInteractionEventData.from(target, routes: inner.routes);
      expect(data.screenName, 'inner');
      expect(data.hierarchy, 'ElevatedButton → DetailPage');
    });

    testWidgets("after a replacement is the new route's name", (t) async {
      await t.pumpWidget(MaterialApp(
        navigatorObservers: [recorder],
        routes: {
          '/': (_) => const HomePage(),
          '/checkout': (_) => const DetailPage(),
        },
      ));
      unawaited(Navigator.of(t.element(byId('save')))
          .pushReplacementNamed('/checkout'));
      await t.pumpAndSettle();
      expect(dataAt(t, byId('detail')).screenName, '/checkout');
    });

    testWidgets('forgets routes once a pop or remove disposes them', (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      final navigator = Navigator.of(t.element(byId('save')));
      final pushed =
          MaterialPageRoute<void>(builder: (_) => const DetailPage());
      unawaited(navigator.push(pushed));
      await t.pumpAndSettle();
      expect(recorder.routes.pages(), hasLength(2));

      navigator.removeRoute(pushed);
      await t.pumpAndSettle();
      expect(recorder.routes.pages(), hasLength(1));
    });

    testWidgets('forgets disposed routes at a pop, without a tap', (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      final navigator = Navigator.of(t.element(byId('save')));
      for (var i = 0; i < 2; i++) {
        unawaited(navigator
            .push(MaterialPageRoute<void>(builder: (_) => const DetailPage())));
        await t.pumpAndSettle();
      }
      navigator.pop();
      await t.pumpAndSettle();
      // Disposed, but nothing has pruned it yet.
      expect(recorder.routes.length, 3);

      navigator.pop();
      await t.pumpAndSettle();
      expect(recorder.routes.length, 2);
    });

    testWidgets("forgets a removed navigator's routes at a push, without a tap",
        (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      final navigator = Navigator.of(t.element(byId('save')));
      unawaited(navigator
          .push(MaterialPageRoute<void>(builder: (_) => const DetailPage())));
      await t.pumpAndSettle();
      expect(recorder.routes.length, 2);

      // A new app replaces the navigator without popping its routes.
      await t.pumpWidget(MaterialApp(
          key: UniqueKey(),
          navigatorObservers: [recorder],
          home: const HomePage()));
      unawaited(Navigator.of(t.element(byId('save')))
          .push(MaterialPageRoute<void>(builder: (_) => const DetailPage())));
      await t.pumpAndSettle();
      expect(recorder.routes.length, 2);
    });

    testWidgets('is still sent on obfuscated builds', (t) async {
      await t.pumpWidget(
          MaterialApp(navigatorObservers: [recorder], home: const HomePage()));
      final target = TargetResolver.resolve(PointerDownEvent(
          position: t.getCenter(byId('save')), viewId: t.view.viewId))!;
      expect(
          ElementInteractionEventData.from(target,
                  routes: recorder.routes, obfuscated: true)
              .screenName,
          '/');
    });

    testWidgets('is left out without AmplitudeNavigatorObserver', (t) async {
      await t.pumpWidget(const MaterialApp(home: HomePage()));
      final target = TargetResolver.resolve(PointerDownEvent(
          position: t.getCenter(byId('save')), viewId: t.view.viewId))!;
      final data = ElementInteractionEventData.from(target);
      expect(data.screenName, isNull);
      // Without the page, the walk runs on to the Overlay.
      expect(
          data.hierarchy, startsWith('ElevatedButton → ListView → HomePage'));
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
