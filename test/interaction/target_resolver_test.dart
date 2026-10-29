import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
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

/// An app control: a Semantics button around a GestureDetector.
class _FancyButton extends StatelessWidget {
  const _FancyButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: const SizedBox(width: 80, height: 40, child: Text('Fancy')),
        ),
      );
}

/// An app wrapper whose build returns a Material button directly.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: const Text('Primary'));
}

/// One pairing case: tapping `target` must resolve to the widget keyed
/// [expected] under [name].
class _Pairing {
  const _Pairing(this.title, this.build, this.expected, this.name);

  final String title;

  /// Builds the screen; `ran(key)` records which callback ran.
  final Widget Function(void Function(String) ran) build;
  final String expected;
  final String name;
}

ValueKey<String> _k(String id) => ValueKey(id);

Widget _wide(Widget child) => SizedBox(width: 320, child: child);

final _pairings = <_Pairing>[
  _Pairing(
    'a GestureDetector around an enabled button loses to the button',
    (ran) => GestureDetector(
      key: _k('gd'),
      onTap: () => ran('gd'),
      child: ElevatedButton(
        key: _k('target'),
        onPressed: () => ran('target'),
        child: const Text('Buy'),
      ),
    ),
    'target',
    'ElevatedButton',
  ),
  _Pairing(
    'a GestureDetector around a disabled button takes the tap',
    (ran) => GestureDetector(
      key: _k('gd'),
      onTap: () => ran('gd'),
      child: const ElevatedButton(
        key: ValueKey('target'),
        onPressed: null,
        child: Text('Buy'),
      ),
    ),
    'gd',
    'GestureDetector',
  ),
  _Pairing(
    "a GestureDetector in a CupertinoButton's child wins",
    (ran) => CupertinoButton(
      onPressed: () => ran('button'),
      child: GestureDetector(
        key: _k('target'),
        onTap: () => ran('target'),
        child: const Text('inner'),
      ),
    ),
    'target',
    'GestureDetector',
  ),
  _Pairing(
    "an ElevatedButton in a CupertinoButton's child wins",
    (ran) => CupertinoButton(
      onPressed: () => ran('button'),
      child: ElevatedButton(
        key: _k('target'),
        onPressed: () => ran('target'),
        child: const Text('inner'),
      ),
    ),
    'target',
    'ElevatedButton',
  ),
  _Pairing(
    'an InkWell in a ListTile title wins',
    (ran) => _wide(
      ListTile(
        onTap: () => ran('tile'),
        title: InkWell(
          key: _k('target'),
          onTap: () => ran('target'),
          child: const Text('link'),
        ),
      ),
    ),
    'target',
    'InkWell',
  ),
  _Pairing(
    'an ElevatedButton in a ListTile title wins',
    (ran) => _wide(
      ListTile(
        onTap: () => ran('tile'),
        title: ElevatedButton(
          key: _k('target'),
          onPressed: () => ran('target'),
          child: const Text('go'),
        ),
      ),
    ),
    'target',
    'ElevatedButton',
  ),
  _Pairing(
    "a Checkbox in a plain ListTile's trailing wins",
    (ran) => _wide(
      ListTile(
        onTap: () => ran('tile'),
        title: const Text('row'),
        trailing: Checkbox(
          key: _k('target'),
          value: false,
          onChanged: (_) => ran('target'),
        ),
      ),
    ),
    'target',
    'Checkbox',
  ),
  _Pairing(
    'a Switch inside a GestureDetector wins',
    (ran) => GestureDetector(
      onTap: () => ran('gd'),
      child: Switch(
        key: _k('target'),
        value: false,
        onChanged: (_) => ran('target'),
      ),
    ),
    'target',
    'Switch',
  ),
  _Pairing(
    'an enabled IconButton in a disabled ListTile wins',
    (ran) => _wide(
      ListTile(
        enabled: false,
        onTap: () => ran('tile'),
        title: const Text('row'),
        trailing: IconButton(
          key: _k('target'),
          onPressed: () => ran('target'),
          icon: const Icon(Icons.delete),
        ),
      ),
    ),
    'target',
    'IconButton',
  ),
  _Pairing(
    'ExcludeSemantics does not hide a control',
    (ran) => ExcludeSemantics(
      child: ElevatedButton(
        key: _k('target'),
        onPressed: () => ran('target'),
        child: const Text('Hidden'),
      ),
    ),
    'target',
    'ElevatedButton',
  ),
  _Pairing(
    'an app component with a Semantics button is named after itself',
    (ran) => _FancyButton(key: _k('target'), onTap: () => ran('target')),
    'target',
    'FancyButton',
  ),
  _Pairing(
    'an inline Semantics button is reported as its handler, by role',
    (ran) => Semantics(
      button: true,
      child: GestureDetector(
        key: _k('target'),
        behavior: HitTestBehavior.opaque,
        onTap: () => ran('target'),
        child: const SizedBox(width: 80, height: 40),
      ),
    ),
    'target',
    'Button',
  ),
  _Pairing(
    'an app component whose build returns a button is named after itself',
    (ran) => PrimaryButton(key: _k('target'), onPressed: () => ran('target')),
    'target',
    'PrimaryButton',
  ),
  _Pairing(
    'an ActionChip',
    (ran) => ActionChip(
      key: _k('target'),
      label: const Text('chip'),
      onPressed: () => ran('target'),
    ),
    'target',
    'ActionChip',
  ),
  _Pairing(
    'a FilterChip',
    (ran) => FilterChip(
      key: _k('target'),
      label: const Text('chip'),
      selected: false,
      onSelected: (_) => ran('target'),
    ),
    'target',
    'FilterChip',
  ),
  _Pairing(
    'a Radio',
    // RadioGroup replaces groupValue and onChanged from Flutter 3.35; the
    // SDK still supports 3.19.
    (ran) => Radio<int>(
      key: _k('target'),
      value: 1,
      // ignore: deprecated_member_use
      groupValue: 0,
      // ignore: deprecated_member_use
      onChanged: (_) => ran('target'),
    ),
    'target',
    'Radio',
  ),
  _Pairing(
    'a RadioListTile owns its radio',
    (ran) => _wide(
      RadioListTile<int>(
        key: _k('target'),
        value: 1,
        // ignore: deprecated_member_use
        groupValue: 0,
        // ignore: deprecated_member_use
        onChanged: (_) => ran('target'),
        title: const Text('radio'),
      ),
    ),
    'target',
    'RadioListTile',
  ),
  _Pairing(
    'a BackButton, not the IconButton it builds',
    (ran) => BackButton(key: _k('target'), onPressed: () => ran('target')),
    'target',
    'BackButton',
  ),
];

const _rawKey = ValueKey('raw');

const _box = ColoredBox(
  color: Colors.blue,
  child: SizedBox(width: 80, height: 40),
);

/// A button built on a [RawGestureDetector], the way Flutter's
/// CupertinoButton is: a disabled button keeps its tap recognizer, but sets
/// every tap callback to null.
class _RawButton extends StatelessWidget {
  const _RawButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return RawGestureDetector(
      key: _rawKey,
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (r) {
            r.onTapDown = enabled ? (_) {} : null;
            r.onTapUp = enabled ? (_) => onPressed!() : null;
            r.onTapCancel = enabled ? () {} : null;
          },
        ),
      },
      child: _box,
    );
  }
}

/// A [RawGestureDetector] whose factory hands out one recognizer its state
/// owns, rather than building a new one each time.
class _SharedRawButton extends StatefulWidget {
  const _SharedRawButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SharedRawButton> createState() => _SharedRawButtonState();
}

class _SharedRawButtonState extends State<_SharedRawButton> {
  final _tap = TapGestureRecognizer();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
        key: _rawKey,
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => _tap,
            (r) => r.onTap = widget.onTap,
          ),
        },
        child: _box,
      );
}

InteractionTarget? resolveAt(WidgetTester t, Offset at) =>
    const TargetResolver().resolve(
      PointerDownEvent(position: at, viewId: t.view.viewId),
    );

/// Real-tap oracle. Resolves a pointer-down at [at] while everything is
/// still mounted, expects the resolved element to match [resolvedTo], then
/// taps there for real and expects exactly the callback [expected] to have
/// run ([ran] records them). By default the resolver must pick the widget
/// keyed [expected], or nothing when [expected] is null.
Future<void> expectResolvesLikeTap(
  WidgetTester t,
  Offset at,
  List<String> ran,
  String? expected, {
  Matcher? resolvedTo,
}) async {
  final resolved = resolveAt(t, at)?.element;
  // Checked before tapping: the tap can close a menu and unmount it.
  expect(
    resolved,
    resolvedTo ??
        (expected == null ? isNull : same(t.element(byId(expected)))),
    reason: 'resolved at $at',
  );
  ran.clear();
  await t.tapAt(at);
  await t.pumpAndSettle();
  expect(ran, expected == null ? isEmpty : [expected], reason: 'ran at $at');
}

Object? keyOf(InteractionTarget? r) =>
    (r?.element.widget.key as ValueKey?)?.value;

Type? typeOf(InteractionTarget? r) => r?.element.widget.runtimeType;

Widget app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

Widget keyedButton(String id) =>
    ElevatedButton(key: ValueKey(id), onPressed: () {}, child: Text(id));

/// A tap target: a keyed GestureDetector the size of a small button.
Widget keyedDetector(String id) => GestureDetector(
      key: ValueKey(id),
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(width: 88, height: 40, child: Text(id)),
    );

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
            children: [keyedDetector('first'), keyedDetector('second')],
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

    group('gesture detectors', () {
      testWidgets('a RawGestureDetector button is a target', (t) async {
        var ran = 0;
        await t.pumpWidget(app(_RawButton(onPressed: () => ran++)));
        final p = t.getCenter(find.byKey(_rawKey));

        final r = resolveAt(t, p);
        await t.tapAt(p);

        expect(ran, 1);
        expect(r?.element, same(t.element(find.byKey(_rawKey))));
        expect(r!.name, 'RawGestureDetector');
        expect(r.enabled, isTrue);
      });

      // The tap recognizer stays, but with no callbacks it never joins the
      // arena.
      testWidgets(
          'a RawGestureDetector button with its tap callbacks off is not',
          (t) async {
        await t.pumpWidget(app(const _RawButton()));

        expect(resolveAt(t, t.getCenter(find.byKey(_rawKey))), isNull);
      });

      // The check would have to initialize and dispose the app's own
      // recognizer to read it, so such a button is never reported.
      testWidgets('a RawGestureDetector button sharing its recognizer is not',
          (t) async {
        var ran = 0;
        await t.pumpWidget(app(_SharedRawButton(onTap: () => ran++)));
        final p = t.getCenter(find.byKey(_rawKey));

        final r = resolveAt(t, p);
        await t.tapAt(p);

        expect(ran, 1);
        expect(r, isNull);
      });

      testWidgets("a RawGestureDetector button in a ListTile's trailing wins",
          (t) async {
        var tile = 0;
        var button = 0;
        await t.pumpWidget(
          app(
            SizedBox(
              width: 300,
              child: ListTile(
                onTap: () => tile++,
                title: const Text('x'),
                trailing: _RawButton(onPressed: () => button++),
              ),
            ),
          ),
        );
        final p = t.getCenter(find.byKey(_rawKey));

        final r = resolveAt(t, p);
        await t.tapAt(p);
        await t.pump(const Duration(seconds: 1));

        expect((tile, button), (0, 1));
        expect(r?.element, same(t.element(find.byKey(_rawKey))));
      });

      testWidgets("a scrollable's drag detector is not a target", (t) async {
        await t.pumpWidget(
          app(ListView(children: const [SizedBox(height: 40)])),
        );

        expect(resolveAt(t, t.getCenter(find.byType(ListView))), isNull);
      });

      // A Scrollbar wraps its scrollable in a RawGestureDetector whose track
      // recognizer, a TapGestureRecognizer subclass, takes only pointers
      // over the track.
      testWidgets(
        'a tap on plain content inside a Scrollbar reports nothing',
        variant: TargetPlatformVariant(
          {TargetPlatform.iOS, TargetPlatform.macOS},
        ),
        (t) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);
          await t.pumpWidget(
            app(
              Scrollbar(
                controller: controller,
                thumbVisibility: true,
                child: ListView(
                  controller: controller,
                  children: [
                    for (var i = 0; i < 50; i++) Text('row $i'),
                  ],
                ),
              ),
            ),
          );
          // The Scrollbar turns on its gestures once it sees the metrics.
          await t.pump();
          final p = t.getCenter(find.text('row 3'));

          final r = resolveAt(t, p);
          await t.tapAt(p);
          await t.pump(const Duration(seconds: 1));

          expect(r, isNull);
        },
      );

      // On Flutter 3.19 a SelectableRegion builds a translucent
      // RawGestureDetector whose plain tap recognizer has onTapUp set.
      testWidgets(
        'plain text inside a SelectionArea reports nothing',
        variant: TargetPlatformVariant(
          {TargetPlatform.android, TargetPlatform.iOS},
        ),
        (t) async {
          await t.pumpWidget(
            app(const SelectionArea(child: Text('plain text'))),
          );

          expect(resolveAt(t, t.getCenter(find.text('plain text'))), isNull);
        },
      );

      // The region's own detector is the first handler below it; one in its
      // child is below that and still takes the tap.
      testWidgets(
        'a GestureDetector inside a SelectionArea is a target',
        variant: TargetPlatformVariant(
          {TargetPlatform.android, TargetPlatform.iOS},
        ),
        (t) async {
          final ran = <String>[];
          await t.pumpWidget(
            app(
              SelectionArea(
                child: GestureDetector(
                  key: const ValueKey('link'),
                  onTap: () => ran.add('link'),
                  child: const Text('link'),
                ),
              ),
            ),
          );

          await expectResolvesLikeTap(
            t,
            t.getCenter(byId('link')),
            ran,
            'link',
          );
        },
      );
    });

    testWidgets('only the active IndexedStack child is reported', (t) async {
      Widget tab(String id) => Center(
            child: SizedBox(width: 200, height: 80, child: keyedDetector(id)),
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
          await t.pumpWidget(app(wrap(keyedDetector('hidden'))));

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
                      actions: [keyedDetector('ok')],
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
              child: Scaffold(body: Center(child: keyedDetector('b'))),
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

    // Real-tap oracle: the control whose callback ran must be the one
    // resolved, under the name the control is reported by.
    group('Semantics pairing', () {
      for (final c in _pairings) {
        testWidgets(c.title, (t) async {
          final ran = <String>[];
          await t.pumpWidget(app(c.build(ran.add)));
          final p = t.getCenter(byId('target'));

          final r = resolveAt(t, p);
          await t.tapAt(p);
          await t.pump(const Duration(seconds: 1));

          expect(ran, [c.expected], reason: 'callback that ran');
          expect(keyOf(r), c.expected);
          expect(r!.name, c.name);
          expect(r.enabled, isTrue);
        });
      }
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
            child: GestureDetector(
              key: const ValueKey('ghost'),
              behavior: HitTestBehavior.opaque,
              onTap: () => ran.add('ghost'),
              child: const SizedBox(width: 88, height: 40),
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

      testWidgets('OverlayPortal content resolves to the control', (t) async {
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

    group('OverlayPortal content', () {
      Widget item(String id, List<String> ran, {Widget? trailingIcon}) =>
          MenuItemButton(
            key: ValueKey(id),
            onPressed: () => ran.add(id),
            trailingIcon: trailingIcon,
            child: Text(id),
          );

      Widget menu(List<Widget> children) => MenuAnchor(
            menuChildren: children,
            builder: (context, controller, child) => TextButton(
              onPressed: () => controller.open(),
              child: const Text('Edit'),
            ),
          );

      Future<void> openMenu(WidgetTester t) async {
        await t.tap(find.text('Edit'));
        await t.pumpAndSettle();
      }

      testWidgets('an open MenuAnchor item', (t) async {
        final ran = <String>[];
        await t.pumpWidget(app(menu([item('copy', ran), item('paste', ran)])));
        await openMenu(t);

        await expectResolvesLikeTap(t, t.getCenter(byId('paste')), ran, 'paste');
      });

      testWidgets('an item in an open submenu', (t) async {
        // The submenu's OverlayPortal is inside the first menu's content.
        final ran = <String>[];
        await t.pumpWidget(
          app(
            menu([
              SubmenuButton(
                menuChildren: [item('deep', ran)],
                child: const Text('More'),
              ),
            ]),
          ),
        );
        await openMenu(t);
        await t.tap(find.text('More'));
        await t.pumpAndSettle();

        await expectResolvesLikeTap(t, t.getCenter(byId('deep')), ran, 'deep');
      });

      testWidgets("a control in a menu item's trailingIcon wins", (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            menu([
              item(
                'row',
                ran,
                trailingIcon: IconButton(
                  key: const ValueKey('pin'),
                  onPressed: () => ran.add('pin'),
                  icon: const Icon(Icons.push_pin),
                ),
              ),
            ]),
          ),
        );
        await openMenu(t);

        await expectResolvesLikeTap(t, t.getCenter(byId('pin')), ran, 'pin');
      });

      testWidgets('a disabled menu item resolves with enabled false',
          (t) async {
        await t.pumpWidget(
          app(
            menu([
              const MenuItemButton(
                key: ValueKey('off'),
                onPressed: null,
                child: Text('off'),
              ),
            ]),
          ),
        );
        await openMenu(t);

        final r = resolveAt(t, t.getCenter(byId('off')));

        expect(keyOf(r), 'off');
        expect(r!.name, 'MenuItemButton');
        expect(r.enabled, isFalse);
      });

      testWidgets('a SubmenuButton resolves to the TextButton it builds',
          (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            menu([
              SubmenuButton(
                key: const ValueKey('more'),
                onOpen: () => ran.add('more'),
                menuChildren: [item('deep', ran)],
                child: const Text('More'),
              ),
            ]),
          ),
        );
        await openMenu(t);
        // A known gap: the MenuAnchor between them hides that the submenu
        // built this TextButton.
        final button = find.descendant(
          of: byId('more'),
          matching: find.byType(TextButton),
        );

        await expectResolvesLikeTap(
          t,
          t.getCenter(button),
          ran,
          'more',
          resolvedTo: same(t.element(button)),
        );
      });

      // Menu toggles pass their key on to the MenuItemButton they build, so
      // these tests find them by type.
      testWidgets('a CheckboxMenuButton in an open menu', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            menu([
              CheckboxMenuButton(
                value: false,
                onChanged: (_) => ran.add('bold'),
                child: const Text('Bold'),
              ),
            ]),
          ),
        );
        await openMenu(t);
        final toggle = find.byType(CheckboxMenuButton);
        // The checkbox it shows ignores pointers, so the item takes the tap.
        final box = t.getCenter(find.byType(Checkbox));

        await expectResolvesLikeTap(
          t,
          t.getCenter(toggle),
          ran,
          'bold',
          resolvedTo: same(t.element(toggle)),
        );
        await openMenu(t);
        await expectResolvesLikeTap(
          t,
          box,
          ran,
          'bold',
          resolvedTo: same(t.element(toggle)),
        );
      });

      testWidgets('a RadioMenuButton in an open menu', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            menu([
              RadioMenuButton<String>(
                value: 'left',
                // RadioGroup replaces groupValue and onChanged from Flutter
                // 3.35; the SDK still supports 3.19.
                // ignore: deprecated_member_use
                groupValue: 'right',
                // ignore: deprecated_member_use
                onChanged: (_) => ran.add('left'),
                child: const Text('Left'),
              ),
            ]),
          ),
        );
        await openMenu(t);

        await expectResolvesLikeTap(
          t,
          t.getCenter(find.byType(RadioMenuButton<String>)),
          ran,
          'left',
          resolvedTo: same(t.element(find.byType(RadioMenuButton<String>))),
        );
      });

      testWidgets('menu items are named after themselves', (t) async {
        await t.pumpWidget(
          app(
            menu([
              const CheckboxMenuButton(
                value: false,
                onChanged: null,
                child: Text('check'),
              ),
              RadioMenuButton<String>(
                value: 'a',
                // ignore: deprecated_member_use
                groupValue: 'b',
                // ignore: deprecated_member_use
                onChanged: (_) {},
                child: const Text('radio'),
              ),
              MenuItemButton(onPressed: () {}, child: const Text('plain')),
            ]),
          ),
        );
        await openMenu(t);

        final check =
            resolveAt(t, t.getCenter(find.byType(CheckboxMenuButton)));
        final radio =
            resolveAt(t, t.getCenter(find.byType(RadioMenuButton<String>)));
        final plain = resolveAt(t, t.getCenter(find.text('plain')));

        expect(typeOf(check), CheckboxMenuButton);
        expect(check!.name, 'CheckboxMenuButton');
        expect(check.enabled, isFalse);
        expect(typeOf(radio), RadioMenuButton<String>);
        expect(radio!.name, 'RadioMenuButton');
        expect(radio.enabled, isTrue);
        expect(plain!.name, 'MenuItemButton');
      });

      testWidgets('a DropdownMenu entry', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            DropdownMenu<String>(
              onSelected: (value) => ran.add(value!),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'apple', label: 'Apple'),
                DropdownMenuEntry(value: 'pear', label: 'Pear'),
              ],
            ),
          ),
        );
        await t.tap(find.byType(TextField));
        await t.pumpAndSettle();
        // DropdownMenu also lays out hidden copies of its entries to size
        // itself; only the copy in the open menu is hit.
        final pear = find.widgetWithText(MenuItemButton, 'Pear').hitTestable();

        await expectResolvesLikeTap(
          t,
          t.getCenter(pear),
          ran,
          'pear',
          resolvedTo: same(t.element(pear)),
        );
      });

      testWidgets('an Autocomplete option', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          app(
            SizedBox(
              width: 300,
              child: Autocomplete<String>(
                optionsBuilder: (value) => ['apple', 'apricot', 'banana']
                    .where((option) => option.startsWith(value.text)),
                onSelected: ran.add,
              ),
            ),
          ),
        );
        await t.enterText(find.byType(TextField), 'ap');
        await t.pumpAndSettle();
        final apricot = find
            .ancestor(of: find.text('apricot'), matching: find.byType(InkWell))
            .first;

        await expectResolvesLikeTap(
          t,
          t.getCenter(apricot),
          ran,
          'apricot',
          resolvedTo: same(t.element(apricot)),
        );
      });

      testWidgets('content a nested page shows in the root Overlay',
          (t) async {
        // The portal's entry belongs to the root Overlay, not the nested
        // Navigator's Overlay nearest to it.
        final ran = <String>[];
        final controller = OverlayPortalController();
        await t.pumpWidget(
          app(
            SizedBox(
              width: 200,
              height: 200,
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  // Its replacement, OverlayPortal's overlayLocation, is
                  // newer than the Flutter 3.19 this package supports.
                  // ignore: deprecated_member_use
                  builder: (_) => OverlayPortal.targetsRootOverlay(
                    controller: controller,
                    overlayChildBuilder: (_) => Positioned(
                      left: 20,
                      top: 20,
                      child: GestureDetector(
                        key: const ValueKey('root'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ran.add('root'),
                        child: const SizedBox(width: 80, height: 80),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        controller.show();
        await t.pump();

        await expectResolvesLikeTap(t, t.getCenter(byId('root')), ran, 'root');
      });

      testWidgets('a page control beside an open menu', (t) async {
        final ran = <String>[];
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: menu([item('copy', ran)]),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      key: const ValueKey('page'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ran.add('page'),
                      child: const SizedBox(width: 88, height: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await openMenu(t);

        await expectResolvesLikeTap(t, t.getCenter(byId('page')), ran, 'page');
      });

      testWidgets('a translucent layer in portal content over a page control',
          (t) async {
        // Flutter hits both the layer and the button beneath it, so the walk
        // also reaches the portal through the page; the layer joined the
        // arena first and wins.
        final ran = <String>[];
        final controller = OverlayPortalController();
        await t.pumpWidget(
          app(
            OverlayPortal(
              controller: controller,
              overlayChildBuilder: (_) => Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('layer'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => ran.add('layer'),
                ),
              ),
              child: ElevatedButton(
                key: const ValueKey('page'),
                onPressed: () => ran.add('page'),
                child: const Text('page'),
              ),
            ),
          ),
        );
        controller.show();
        await t.pump();

        await expectResolvesLikeTap(t, t.getCenter(byId('page')), ran, 'layer');
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
                  itemBuilder: (_, i) => GestureDetector(
                    key: ValueKey(i),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps.add(i),
                    child: SizedBox(height: 56, child: Text('Item $i $v')),
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
