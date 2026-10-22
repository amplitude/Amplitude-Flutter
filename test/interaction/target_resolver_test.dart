import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Joins the hit path without ending it, as a translucent box with nothing
/// hit beneath it does, and handles nothing.
class _HitButNotHandled extends SingleChildRenderObjectWidget {
  const _HitButNotHandled();

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitButNotHandled();
}

class _RenderHitButNotHandled extends RenderProxyBoxWithHitTestBehavior {
  _RenderHitButNotHandled() : super(behavior: HitTestBehavior.translucent);
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

        // The overlay joined the arena first, so it wins the unresolved tap.
        expect(ran, 'over');
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

        // The overlay joined the arena first, so it wins the unresolved tap.
        expect(ran, 'over');
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

    group('nested handlers follow the gesture arena', () {
      // Real-tap oracle: the callback that ran must be the one resolved.
      Future<void> expectResolvesLikeTap(
        WidgetTester t,
        Offset p,
        List<String> ran,
        String expected,
      ) async {
        final resolved = keyOf(resolveAt(t, p));
        ran.clear();
        await t.tapAt(p);
        await t.pump(const Duration(seconds: 1));
        expect(ran, [expected], reason: 'callback that ran at $p');
        expect(resolved, expected, reason: 'resolved at $p');
      }

      testWidgets('a GestureDetector in a ListTile title wins', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            SizedBox(
              width: 300,
              child: ListTile(
                key: const ValueKey('tile'),
                onTap: () => ran.add('tile'),
                title: GestureDetector(
                  key: const ValueKey('link'),
                  onTap: () => ran.add('link'),
                  child: const Text('link'),
                ),
              ),
            ),
          ),
        );

        await expectResolvesLikeTap(t, t.getCenter(byId('link')), ran, 'link');
      });

      testWidgets("an InkWell in an ElevatedButton's child wins", (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            ElevatedButton(
              key: const ValueKey('btn'),
              onPressed: () => ran.add('btn'),
              child: InkWell(
                key: const ValueKey('ink'),
                onTap: () => ran.add('ink'),
                child: const Text('ink'),
              ),
            ),
          ),
        );

        await expectResolvesLikeTap(t, t.getCenter(byId('ink')), ran, 'ink');
      });

      testWidgets("a GestureDetector in an InkWell's child wins", (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            Material(
              child: InkWell(
                key: const ValueKey('ink'),
                onTap: () => ran.add('ink'),
                child: GestureDetector(
                  key: const ValueKey('gd'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ran.add('gd'),
                  child: const SizedBox(width: 80, height: 40),
                ),
              ),
            ),
          ),
        );

        await expectResolvesLikeTap(t, t.getCenter(byId('gd')), ran, 'gd');
      });

      testWidgets('a disabled control in an enabled tile credits the tile',
          (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            SizedBox(
              width: 300,
              child: ListTile(
                key: const ValueKey('tile'),
                onTap: () => ran.add('tile'),
                title: const Text('Row'),
                trailing: const IconButton(
                  key: ValueKey('icon'),
                  onPressed: null,
                  icon: Icon(Icons.delete),
                ),
              ),
            ),
          ),
        );
        final p = t.getCenter(byId('icon'));

        await expectResolvesLikeTap(t, p, ran, 'tile');
        expect(resolveAt(t, p)!.enabled, isTrue);
      });

      testWidgets("a slot doesn't carry into its control's own internals",
          (t) async {
        // The `secondary` slot is moved over the tile's own checkbox, so
        // the hit path runs through the slot first and then the checkbox.
        // Leaving the slot must not leave the tile's internals: if it did,
        // the checkbox the tile builds would be reported instead of the
        // tile.
        final ran = <String>[];
        Widget tile(Offset shift) => app(
              SizedBox(
                width: 300,
                child: CheckboxListTile(
                  key: const ValueKey('tile'),
                  value: false,
                  onChanged: (_) => ran.add('tile'),
                  title: const Text('Title'),
                  secondary: Transform.translate(
                    offset: shift,
                    child: const SizedBox(
                      key: ValueKey('shifted'),
                      width: 24,
                      height: 24,
                      child: _HitButNotHandled(),
                    ),
                  ),
                ),
              ),
            );
        await t.pumpWidget(tile(Offset.zero));
        final shift =
            t.getCenter(find.byType(Checkbox)) - t.getCenter(byId('shifted'));
        await t.pumpWidget(tile(shift));
        final p = t.getCenter(find.byType(Checkbox));
        final hitPath = t.hitTestOnBinding(p).path.map((e) => e.target);
        expect(
            hitPath, contains(t.renderObject(find.byType(_HitButNotHandled))));
        expect(hitPath, contains(t.renderObject(find.byType(Checkbox))));

        await expectResolvesLikeTap(t, p, ran, 'tile');
      });
    });

    testWidgets('an invisible control that keeps interactivity is a target',
        (t) async {
      final ran = <String>[];
      await t.pumpWidget(
        app(
          Visibility(
            visible: false,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            maintainInteractivity: true,
            child: ElevatedButton(
              key: const ValueKey('ghost'),
              onPressed: () => ran.add('ghost'),
              child: const Text('ghost'),
            ),
          ),
        ),
      );
      final p = t.getCenter(byId('ghost'));
      final resolved = keyOf(resolveAt(t, p));

      await t.tapAt(p);

      expect(ran, ['ghost']);
      expect(resolved, 'ghost');
    });

    group('transformed ancestors', () {
      // Fixture layout: two 80x60 controls 40 apart form a 200x60 row,
      // centred in a 400x400 box under the transform.
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
          (t) async {
        final ran = <String>[];
        await pumpSideBySide(t, perspective, ran);
        final [ca, cb, pa, pb] = perspectivePoints(t);

        await expectResolvesLikeTap(t, ca, ran, 'a');
        await expectResolvesLikeTap(t, cb, ran, 'b');
        await expectResolvesLikeTap(t, pa, ran, 'a');
        await expectResolvesLikeTap(t, pb, ran, 'b');
      });

      // In the next three tests the control leaves the layout box of the
      // Transform (or SlideTransition's FractionalTranslation) itself, whose
      // hitTest skips its own bounds check. A plain box such as SizedBox
      // around it would check its bounds, and the tap would miss.
      Widget recorder(String id, double size, List<String> ran) =>
          GestureDetector(
            key: ValueKey(id),
            behavior: HitTestBehavior.opaque,
            onTap: () => ran.add(id),
            child: SizedBox(width: size, height: size),
          );

      testWidgets(
          "content translated outside its parent's box resolves to the control",
          (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            Transform.translate(
              offset: const Offset(150, 0),
              child: recorder('moved', 80, ran),
            ),
          ),
        );

        await expectResolvesLikeTap(
            t, t.getCenter(byId('moved')), ran, 'moved');
      });

      testWidgets(
          "content scaled beyond its parent's box resolves to the control",
          (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            Transform.scale(
              scale: 3,
              child: recorder('big', 60, ran),
            ),
          ),
        );
        // Scaled 3x about its centre, `big` spans 90 either side of it; the
        // transform's own 60x60 box spans only 30.
        final p = t.getCenter(byId('big')) + const Offset(50, 0);

        await expectResolvesLikeTap(t, p, ran, 'big');
      });

      testWidgets('a control mid-SlideTransition resolves to the control',
          (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            SlideTransition(
              position: const AlwaysStoppedAnimation(Offset(1.5, 0)),
              child: recorder('sliding', 100, ran),
            ),
          ),
        );

        await expectResolvesLikeTap(
            t, t.getCenter(byId('sliding')), ran, 'sliding');
      });

      testWidgets('OverlayPortal content resolves to the control',
          skip: true, // The overlay child renders under the Overlay's
          // theater, which hit-tests it and stops, so the page subtree holding
          // the OverlayPortal element (route transitions down to its parent)
          // is off the hit path and pruned before the walk reaches the
          // portal. Exempting OverlayPortal itself from pruning can't help.
          (t) async {
        final ran = <String>[];
        final controller = OverlayPortalController();
        await t.pumpWidget(
          app(
            OverlayPortal(
              controller: controller,
              overlayChildBuilder: (_) => Positioned(
                left: 300,
                top: 300,
                child: recorder('portal', 80, ran),
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        );
        controller.show();
        await t.pump();

        await expectResolvesLikeTap(
            t, t.getCenter(byId('portal')), ran, 'portal');
      });
    });

    group('scrolling', () {
      testWidgets('a list rebuilt mid-fling still reports taps once it settles',
          (t) async {
        final taps = <int>[];
        final notifier = ValueNotifier<int>(0);
        addTearDown(notifier.dispose);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: notifier,
                builder: (_, v, __) => ListView.builder(
                  controller: controller,
                  itemCount: 2000,
                  itemBuilder: (_, i) => ListTile(
                    key: ValueKey(i),
                    title: Text('Item $i $v'),
                    onTap: () => taps.add(i),
                  ),
                ),
              ),
            ),
          ),
        );

        await t.fling(find.byType(ListView), const Offset(0, -300), 3000);
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
        notifier.value++;
        await t.pump();
        await t.pumpAndSettle();

        // Scrollable flips its IgnorePointer through the render object, so
        // a rebuild mid-fling leaves the widget saying `ignoring: true`.
        final ignorePointer = t.widget<IgnorePointer>(
          find
              .descendant(
                of: find.byType(Scrollable),
                matching: find.byType(IgnorePointer),
              )
              .first,
        );
        expect(ignorePointer.ignoring, isTrue);

        final p = t.getCenter(find.byType(ListView));
        final resolved = keyOf(resolveAt(t, p));
        await t.tapAt(p);
        await t.pump(const Duration(seconds: 1));

        expect(taps, hasLength(1), reason: 'callback that ran at $p');
        expect(resolved, taps.single, reason: 'resolved at $p');
      });
    });
  });
}
