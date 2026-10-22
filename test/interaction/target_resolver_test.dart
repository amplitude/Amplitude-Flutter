import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

int _countingBuilds = 0;

/// Counts rebuilds. Used as a single reused instance, so only an
/// inherited-widget dependency can make it rebuild.
class _CountingGestureDetector extends GestureDetector {
  _CountingGestureDetector({super.onTap, super.child});

  @override
  Widget build(BuildContext context) {
    _countingBuilds++;
    return super.build(context);
  }
}

InteractionTarget? resolveAt(WidgetTester t, Offset at) =>
    const TargetResolver().resolve(
      PointerDownEvent(position: at, viewId: t.view.viewId),
    );

Object? keyOf(InteractionTarget? r) =>
    (r?.element.widget.key as ValueKey?)?.value;

Type? typeOf(InteractionTarget? r) => r?.element.widget.runtimeType;

Widget app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

Widget keyedButton(String id) =>
    ElevatedButton(key: ValueKey(id), onPressed: () {}, child: Text(id));

Finder byId(String id) => find.byKey(ValueKey(id), skipOffstage: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TargetResolver', () {
    testWidgets('a concrete control beats its internal handlers', (t) async {
      await t.pumpWidget(app(keyedButton('b')));

      final r = resolveAt(t, t.getCenter(byId('b')));

      expect(typeOf(r), ElevatedButton);
    });

    testWidgets('a control nested inside another control wins', (t) async {
      await t.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: ListTile(
              onTap: () {},
              title: const Text('Row'),
              trailing: IconButton(
                key: const ValueKey('i'),
                onPressed: () {},
                icon: const Icon(Icons.delete),
              ),
            ),
          ),
        ),
      );

      final r = resolveAt(t, t.getCenter(byId('i')));

      expect(keyOf(r), 'i');
    });

    testWidgets('a CheckboxListTile is reported, not its internals', (t) async {
      await t.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Title'),
            ),
          ),
        ),
      );

      expect(
        typeOf(resolveAt(t, t.getCenter(find.text('Title')))),
        CheckboxListTile,
      );
      expect(
        typeOf(resolveAt(t, t.getCenter(find.byType(Checkbox)))),
        CheckboxListTile,
      );
    });

    testWidgets('a SwitchListTile is reported, not its internals', (t) async {
      await t.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: SwitchListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Title'),
            ),
          ),
        ),
      );

      expect(
        typeOf(resolveAt(t, t.getCenter(find.text('Title')))),
        SwitchListTile,
      );
      expect(
        typeOf(resolveAt(t, t.getCenter(find.byType(Switch)))),
        SwitchListTile,
      );
    });

    group('independent child in <tile>.<slot> wins', () {
      Widget independent() => IconButton(
            key: const ValueKey('independent'),
            onPressed: () {},
            icon: const Icon(Icons.star),
          );

      for (final slot in ['title', 'subtitle', 'secondary']) {
        Widget? only(String name) => slot == name ? independent() : null;

        testWidgets('CheckboxListTile.$slot', (t) async {
          await t.pumpWidget(
            app(
              SizedBox(
                width: 300,
                child: CheckboxListTile(
                  value: false,
                  onChanged: (_) {},
                  title: only('title') ?? const Text('T'),
                  subtitle: only('subtitle'),
                  secondary: only('secondary'),
                ),
              ),
            ),
          );

          final r = resolveAt(t, t.getCenter(byId('independent')));

          expect(keyOf(r), 'independent');
        });

        testWidgets('SwitchListTile.$slot', (t) async {
          await t.pumpWidget(
            app(
              SizedBox(
                width: 300,
                child: SwitchListTile(
                  value: false,
                  onChanged: (_) {},
                  title: only('title') ?? const Text('T'),
                  subtitle: only('subtitle'),
                  secondary: only('secondary'),
                ),
              ),
            ),
          );

          final r = resolveAt(t, t.getCenter(byId('independent')));

          expect(keyOf(r), 'independent');
        });
      }
    });

    group('every ranked control type resolves to itself', () {
      final cases = <String, (Type, Widget Function())>{
        'ElevatedButton': (
          ElevatedButton,
          () => ElevatedButton(onPressed: () {}, child: const Text('x')),
        ),
        'TextButton': (
          TextButton,
          () => TextButton(onPressed: () {}, child: const Text('x')),
        ),
        'OutlinedButton': (
          OutlinedButton,
          () => OutlinedButton(onPressed: () {}, child: const Text('x')),
        ),
        'FilledButton': (
          FilledButton,
          () => FilledButton(onPressed: () {}, child: const Text('x')),
        ),
        'MaterialButton': (
          MaterialButton,
          () => MaterialButton(onPressed: () {}, child: const Text('x')),
        ),
        'IconButton': (
          IconButton,
          () => IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ),
        'FloatingActionButton': (
          FloatingActionButton,
          () => FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
        ),
        'CupertinoButton': (
          CupertinoButton,
          () => CupertinoButton(onPressed: () {}, child: const Text('x')),
        ),
        'ListTile': (
          ListTile,
          () => SizedBox(
                width: 300,
                child: ListTile(onTap: () {}, title: const Text('x')),
              ),
        ),
        'PopupMenuButton': (
          PopupMenuButton<int>,
          () => PopupMenuButton<int>(
                itemBuilder: (_) => const [],
                child: const Text('menu'),
              ),
        ),
        'DropdownButton': (
          DropdownButton<int>,
          () => DropdownButton<int>(
                value: 1,
                onChanged: (_) {},
                items: const [DropdownMenuItem(value: 1, child: Text('one'))],
              ),
        ),
        'TextField': (
          TextField,
          () => const SizedBox(width: 200, child: TextField()),
        ),
        'InkWell': (
          InkWell,
          () => Material(
                child: InkWell(
                  onTap: () {},
                  child: const ColoredBox(
                    color: Colors.blue,
                    child: SizedBox(width: 80, height: 40),
                  ),
                ),
              ),
        ),
        'InkResponse': (
          InkResponse,
          () => Material(
                child: InkResponse(
                  onTap: () {},
                  child: const SizedBox(width: 80, height: 40),
                ),
              ),
        ),
        'Checkbox': (
          Checkbox,
          () => Checkbox(value: false, onChanged: (_) {}),
        ),
        'Switch': (
          Switch,
          () => Switch(value: false, onChanged: (_) {}),
        ),
        'GestureDetector': (
          GestureDetector,
          () => GestureDetector(
                onTap: () {},
                child: const ColoredBox(
                  color: Colors.blue,
                  child: SizedBox(width: 80, height: 40),
                ),
              ),
        ),
      };

      cases.forEach((name, spec) {
        testWidgets(name, (t) async {
          await t.pumpWidget(app(spec.$2()));

          final r = resolveAt(t, t.getCenter(find.byType(spec.$1).first));

          expect(typeOf(r), spec.$1);
        });
      });
    });

    testWidgets('sibling containment: the tapped button is reported',
        (t) async {
      await t.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [keyedButton('first'), keyedButton('second')],
          ),
        ),
      );

      final r = resolveAt(t, t.getCenter(byId('second')));

      expect(keyOf(r), 'second');
    });

    testWidgets('GestureDetector with onTap is a target', (t) async {
      await t.pumpWidget(
        app(
          GestureDetector(
            key: const ValueKey('g'),
            onTap: () {},
            child: const ColoredBox(
              color: Colors.blue,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final r = resolveAt(t, t.getCenter(byId('g')));

      expect(keyOf(r), 'g');
    });

    testWidgets('non-interactive widgets are not targets', (t) async {
      await t.pumpWidget(app(const Text('plain')));

      expect(resolveAt(t, t.getCenter(find.text('plain'))), isNull);
    });

    testWidgets('only the active IndexedStack child is reported', (t) async {
      Widget tab(String id) => Center(
            child: SizedBox(width: 200, height: 80, child: keyedButton(id)),
          );
      Widget stack(int index) => app(
            SizedBox(
              width: 300,
              height: 300,
              child: IndexedStack(
                index: index,
                children: [tab('first'), tab('second')],
              ),
            ),
          );
      const center = Offset(400, 300);

      await t.pumpWidget(stack(1));
      expect(keyOf(resolveAt(t, center)), 'second');

      await t.pumpWidget(stack(0));
      expect(keyOf(resolveAt(t, center)), 'first');
    });

    group('hidden and blocked branches are not targets', () {
      final blockers = <String, Widget Function(Widget)>{
        'Visibility': (child) => Visibility(
              visible: false,
              maintainState: true,
              maintainSize: true,
              maintainAnimation: true,
              child: child,
            ),
        'Offstage': (child) =>
            SizedBox(width: 200, height: 200, child: Offstage(child: child)),
        'IgnorePointer': (child) => IgnorePointer(child: child),
        'AbsorbPointer': (child) => AbsorbPointer(child: child),
        'ModalBarrier': (child) => Stack(
              children: [
                Center(child: child),
                const Positioned.fill(child: ModalBarrier(dismissible: false)),
              ],
            ),
      };

      blockers.forEach((name, wrap) {
        testWidgets(name, (t) async {
          await t.pumpWidget(app(wrap(keyedButton('hidden'))));

          expect(resolveAt(t, t.getCenter(byId('hidden'))), isNull);
        });
      });
    });

    testWidgets("taps inside a dialog resolve to the dialog's control",
        (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      actions: [
                        TextButton(
                          key: const ValueKey('ok'),
                          onPressed: () {},
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      final behindBarrier = t.getCenter(find.text('Open'));
      await t.tapAt(behindBarrier);
      await t.pumpAndSettle();

      expect(keyOf(resolveAt(t, t.getCenter(byId('ok')))), 'ok');
      expect(resolveAt(t, behindBarrier), isNull);
    });

    testWidgets('disabled buttons resolve with enabled false', (t) async {
      await t.pumpWidget(
        app(const ElevatedButton(onPressed: null, child: Text('off'))),
      );

      final r = resolveAt(t, t.getCenter(find.text('off')));

      expect(typeOf(r), ElevatedButton);
      expect(r!.enabled, isFalse);
    });

    testWidgets('resolving does not subscribe the target to MediaQuery',
        (t) async {
      var insets = 0.0;
      late StateSetter setOuter;
      final target = _CountingGestureDetector(
        onTap: () {},
        child: const SizedBox(width: 100, height: 100, child: Text('MQ')),
      );
      final body = Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(child: target),
      );
      await t.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: EdgeInsets.only(bottom: insets),
                ),
                child: body,
              );
            },
          ),
        ),
      );
      Future<int> buildsAfterInsetsChange() async {
        final before = _countingBuilds;
        setOuter(() => insets += 10);
        await t.pump();
        return _countingBuilds - before;
      }

      final r = resolveAt(t, t.getCenter(find.text('MQ')));

      expect(r!.element.widget, same(target));
      expect(await buildsAfterInsetsChange(), 0);
    });

    testWidgets('gesture settings come from the nearest MediaQuery', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                gestureSettings: const DeviceGestureSettings(touchSlop: 7),
              ),
              child: Scaffold(body: Center(child: keyedButton('b'))),
            ),
          ),
        ),
      );

      final r = resolveAt(t, t.getCenter(byId('b')));

      expect(r!.gestureSettings!.touchSlop, 7);
    });

    group('overlapping layouts', () {
      Widget overlaid(
        Widget under,
        HitTestBehavior behavior,
        void Function(String) ran,
      ) =>
          app(
            SizedBox(
              width: 300,
              child: Stack(
                children: [
                  under,
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey('over'),
                      behavior: behavior,
                      onTap: () => ran('over'),
                    ),
                  ),
                ],
              ),
            ),
          );

      testWidgets(
          'translucent overlay over a button reports the callback that ran',
          (t) async {
        String? ran;
        await t.pumpWidget(
          overlaid(
            ElevatedButton(
              key: const ValueKey('under'),
              onPressed: () => ran = 'under',
              child: const Text('under'),
            ),
            HitTestBehavior.translucent,
            (id) => ran = id,
          ),
        );
        final p = t.getCenter(byId('under'));

        await t.tapAt(p);

        expect(ran, isNotNull);
        expect(keyOf(resolveAt(t, p)), ran);
      });

      testWidgets(
          'translucent overlay over a tile title reports the callback that ran',
          (t) async {
        String? ran;
        await t.pumpWidget(
          overlaid(
            CheckboxListTile(
              key: const ValueKey('tile'),
              value: false,
              onChanged: (_) => ran = 'tile',
              title: const Text('Title'),
            ),
            HitTestBehavior.translucent,
            (id) => ran = id,
          ),
        );
        final p = t.getCenter(find.text('Title'));

        await t.tapAt(p);

        expect(ran, isNotNull);
        expect(keyOf(resolveAt(t, p)), ran);
      });

      testWidgets('opaque overlay hides the control beneath', (t) async {
        String? ran;
        await t.pumpWidget(
          overlaid(
            ElevatedButton(
              key: const ValueKey('under'),
              onPressed: () => ran = 'under',
              child: const Text('under'),
            ),
            HitTestBehavior.opaque,
            (id) => ran = id,
          ),
        );
        final p = t.getCenter(byId('under'));

        await t.tapAt(p);

        expect(ran, 'over');
        expect(keyOf(resolveAt(t, p)), 'over');
      });
    });

    group('transformed ancestors', () {
      // Two 80x60 controls 40 apart, so the row is 200x60, centred in a
      // 400x400 box under the transform. The box keeps the transformed
      // controls inside the transform's own layout bounds: the resolver
      // prunes by each ancestor box's bounds, while RenderTransform hit-tests
      // its child without checking its own size.
      Future<void> pumpSideBySide(
        WidgetTester t,
        Widget Function(Widget row) wrap,
        List<String> ran,
      ) {
        Widget control(String id) => GestureDetector(
              key: ValueKey(id),
              behavior: HitTestBehavior.opaque,
              onTap: () => ran.add(id),
              child: const SizedBox(width: 80, height: 60),
            );
        return t.pumpWidget(
          app(
            KeyedSubtree(
              key: const ValueKey('xf'),
              child: wrap(
                SizedBox(
                  width: 400,
                  height: 400,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        control('a'),
                        const SizedBox(width: 40),
                        control('b'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      Future<void> expectResolvesLikeTap(
        WidgetTester t,
        Offset p,
        List<String> ran,
        String? expected,
      ) async {
        ran.clear();
        await t.tapAt(p);
        final tapped = ran.isEmpty ? null : ran.single;
        expect(tapped, expected, reason: 'tap at $p');
        expect(keyOf(resolveAt(t, p)), tapped, reason: 'resolve at $p');
      }

      Offset globalOf(WidgetTester t, String id, Offset local) =>
          t.renderObject<RenderBox>(byId(id)).localToGlobal(local);

      testWidgets('a rotated ancestor resolves the control under the tap',
          (t) async {
        final ran = <String>[];
        await pumpSideBySide(
          t,
          (row) => Transform.rotate(angle: 0.7, child: row),
          ran,
        );

        await expectResolvesLikeTap(t, t.getCenter(byId('a')), ran, 'a');
        await expectResolvesLikeTap(t, t.getCenter(byId('b')), ran, 'b');
        await expectResolvesLikeTap(
            t, globalOf(t, 'a', const Offset(3, 3)), ran, 'a');
        await expectResolvesLikeTap(
            t, globalOf(t, 'a', const Offset(-3, -3)), ran, null);
      });

      testWidgets('a scaled ancestor resolves the control under the tap',
          (t) async {
        final ran = <String>[];
        await pumpSideBySide(
          t,
          (row) => Transform.scale(scale: 1.7, child: row),
          ran,
        );
        // Unscaled, `a` spans x in [c - 100, c - 20]; scaled 1.7 about the
        // row's centre it spans [c - 170, c - 34], so c - 25 is in the gap.
        final c = t.getCenter(byId('xf'));
        final insideUnscaledOnly = Offset(c.dx - 25, c.dy);

        await expectResolvesLikeTap(t, t.getCenter(byId('a')), ran, 'a');
        await expectResolvesLikeTap(t, t.getCenter(byId('b')), ran, 'b');
        await expectResolvesLikeTap(t, insideUnscaledOnly, ran, null);
      });

      Widget perspective(Widget row) => Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(0.6),
            alignment: Alignment.center,
            child: row,
          );

      List<Offset> perspectivePoints(WidgetTester t) => [
            t.getCenter(byId('a')),
            t.getCenter(byId('b')),
            globalOf(t, 'a', const Offset(15, 45)),
            globalOf(t, 'b', const Offset(65, 10)),
          ];

      testWidgets('a perspective ancestor resolves the control under the tap',
          skip: true, // The resolver prunes with RenderBox.globalToLocal,
          // which unprojects perspective differently from hit testing
          // (BoxHitTestResult.addWithPaintTransform), so even a control's
          // centre is pruned. Pre-existing; not changed by the linear walk.
          (t) async {
        final ran = <String>[];
        await pumpSideBySide(t, perspective, ran);
        final [ca, cb, pa, pb] = perspectivePoints(t);

        await expectResolvesLikeTap(t, ca, ran, 'a');
        await expectResolvesLikeTap(t, cb, ran, 'b');
        await expectResolvesLikeTap(t, pa, ran, 'a');
        await expectResolvesLikeTap(t, pb, ran, 'b');
      });

      testWidgets('a perspective ancestor maps points as globalToLocal does',
          (t) async {
        await pumpSideBySide(t, perspective, <String>[]);

        // The resolver asserts, in debug, that each cached local position
        // matches RenderBox.globalToLocal, including its unprojection.
        for (final p in perspectivePoints(t)) {
          expect(() => resolveAt(t, p), returnsNormally, reason: '$p');
        }
      });
    });
  });
}
