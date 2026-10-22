import 'package:amplitude_flutter/src/interaction/control_catalog.dart';
import 'package:amplitude_flutter/src/interaction/target_resolver.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoButton, CupertinoCheckbox, CupertinoListTile, CupertinoSwitch;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InteractionTarget? resolveAt(WidgetTester t, Offset at) =>
    const TargetResolver().resolve(
      PointerDownEvent(position: at, viewId: t.view.viewId),
    );

Widget app(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

const formKey = ValueKey('form');

/// One way to write a catalog row's control.
class _Form {
  const _Form(
    this.row,
    this.name,
    this.build, {
    this.enabled = true,
    this.reported = true,
    this.at,
  });

  final String row;
  final String name;

  /// Builds the control with [formKey], wiring `ran` to the callback a tap
  /// fires.
  final Widget Function(void Function() ran) build;
  final bool enabled;

  /// False when Flutter doesn't hit the control at all.
  final bool reported;

  /// Where to tap; the centre of the keyed control when null.
  final Offset Function(WidgetTester t)? at;
}

Widget _wide(Widget child) => SizedBox(width: 300, child: child);

const _box = ColoredBox(
  color: Colors.blue,
  child: SizedBox(width: 80, height: 40),
);

/// A button built on a [RawGestureDetector], the way Flutter's
/// CupertinoButton is: a disabled button keeps its tap recognizer, but sets
/// every tap callback to null.
class _RawButton extends StatelessWidget {
  const _RawButton({this.detectorKey, this.onPressed, this.onLongPress});

  final Key? detectorKey;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return RawGestureDetector(
      key: detectorKey,
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
        if (onLongPress != null)
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            LongPressGestureRecognizer.new,
            (r) => r.onLongPress = onLongPress,
          ),
      },
      child: _box,
    );
  }
}

PopupMenuItemBuilder<int> _menu(void Function() ran) => (_) {
      ran();
      return const [PopupMenuItem(value: 1, child: Text('one'))];
    };

/// The default, `.icon` and disabled forms of a button with an `.icon`
/// constructor.
List<_Form> _buttonForms(
  String row,
  Widget Function(VoidCallback? onPressed) plain,
  Widget Function(VoidCallback onPressed) icon,
) =>
    [
      _Form(row, 'default', plain),
      _Form(row, '.icon', icon),
      _Form(row, 'disabled', (_) => plain(null), enabled: false),
    ];

final _forms = <_Form>[
  ..._buttonForms(
    'ElevatedButton',
    (onPressed) => ElevatedButton(
      key: formKey,
      onPressed: onPressed,
      child: const Text('x'),
    ),
    (onPressed) => ElevatedButton.icon(
      key: formKey,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('x'),
    ),
  ),
  ..._buttonForms(
    'TextButton',
    (onPressed) =>
        TextButton(key: formKey, onPressed: onPressed, child: const Text('x')),
    (onPressed) => TextButton.icon(
      key: formKey,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('x'),
    ),
  ),
  ..._buttonForms(
    'OutlinedButton',
    (onPressed) => OutlinedButton(
      key: formKey,
      onPressed: onPressed,
      child: const Text('x'),
    ),
    (onPressed) => OutlinedButton.icon(
      key: formKey,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('x'),
    ),
  ),
  _Form(
    'FilledButton',
    'default',
    (ran) => FilledButton(key: formKey, onPressed: ran, child: const Text('x')),
  ),
  _Form(
    'FilledButton',
    '.icon',
    (ran) => FilledButton.icon(
      key: formKey,
      onPressed: ran,
      icon: const Icon(Icons.add),
      label: const Text('x'),
    ),
  ),
  _Form(
    'FilledButton',
    '.tonal',
    (ran) => FilledButton.tonal(
      key: formKey,
      onPressed: ran,
      child: const Text('x'),
    ),
  ),
  _Form(
    'FilledButton',
    '.tonalIcon',
    (ran) => FilledButton.tonalIcon(
      key: formKey,
      onPressed: ran,
      icon: const Icon(Icons.add),
      label: const Text('x'),
    ),
  ),
  _Form(
    'FilledButton',
    'disabled',
    (_) => const FilledButton(key: formKey, onPressed: null, child: Text('x')),
    enabled: false,
  ),
  _Form(
    'MaterialButton',
    'default',
    (ran) =>
        MaterialButton(key: formKey, onPressed: ran, child: const Text('x')),
  ),
  _Form(
    'MaterialButton',
    'disabled',
    (_) =>
        const MaterialButton(key: formKey, onPressed: null, child: Text('x')),
    enabled: false,
  ),
  _Form(
    'IconButton',
    'default',
    (ran) =>
        IconButton(key: formKey, onPressed: ran, icon: const Icon(Icons.add)),
  ),
  _Form(
    'IconButton',
    '.filled',
    (ran) => IconButton.filled(
      key: formKey,
      onPressed: ran,
      icon: const Icon(Icons.add),
    ),
  ),
  _Form(
    'IconButton',
    '.filledTonal',
    (ran) => IconButton.filledTonal(
      key: formKey,
      onPressed: ran,
      icon: const Icon(Icons.add),
    ),
  ),
  _Form(
    'IconButton',
    '.outlined',
    (ran) => IconButton.outlined(
      key: formKey,
      onPressed: ran,
      icon: const Icon(Icons.add),
    ),
  ),
  _Form(
    'IconButton',
    'Material 2',
    (ran) => Theme(
      data: ThemeData(useMaterial3: false),
      child: IconButton(
        key: formKey,
        onPressed: ran,
        icon: const Icon(Icons.add),
      ),
    ),
  ),
  _Form(
    'IconButton',
    'disabled',
    (_) =>
        const IconButton(key: formKey, onPressed: null, icon: Icon(Icons.add)),
    enabled: false,
  ),
  _Form(
    'FloatingActionButton',
    'default',
    (ran) => FloatingActionButton(
      key: formKey,
      onPressed: ran,
      child: const Icon(Icons.add),
    ),
  ),
  _Form(
    'FloatingActionButton',
    '.small',
    (ran) => FloatingActionButton.small(
      key: formKey,
      onPressed: ran,
      child: const Icon(Icons.add),
    ),
  ),
  _Form(
    'FloatingActionButton',
    '.large',
    (ran) => FloatingActionButton.large(
      key: formKey,
      onPressed: ran,
      child: const Icon(Icons.add),
    ),
  ),
  _Form(
    'FloatingActionButton',
    '.extended',
    (ran) => FloatingActionButton.extended(
      key: formKey,
      onPressed: ran,
      label: const Text('x'),
    ),
  ),
  _Form(
    'FloatingActionButton',
    'disabled',
    (_) => const FloatingActionButton(
      key: formKey,
      onPressed: null,
      child: Icon(Icons.add),
    ),
    enabled: false,
  ),
  _Form(
    'CupertinoButton',
    'default',
    (ran) =>
        CupertinoButton(key: formKey, onPressed: ran, child: const Text('x')),
  ),
  _Form(
    'CupertinoButton',
    '.filled',
    (ran) => CupertinoButton.filled(
      key: formKey,
      onPressed: ran,
      child: const Text('x'),
    ),
  ),
  _Form(
    'CupertinoButton',
    'disabled',
    (_) =>
        const CupertinoButton(key: formKey, onPressed: null, child: Text('x')),
    enabled: false,
  ),
  _Form(
    'CupertinoSwitch',
    'default',
    (ran) =>
        CupertinoSwitch(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'CupertinoSwitch',
    'disabled',
    (_) => const CupertinoSwitch(key: formKey, value: false, onChanged: null),
    enabled: false,
  ),
  _Form(
    'CupertinoCheckbox',
    'default',
    (ran) =>
        CupertinoCheckbox(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'CupertinoCheckbox',
    'disabled',
    (_) => const CupertinoCheckbox(key: formKey, value: false, onChanged: null),
    enabled: false,
  ),
  _Form(
    'CupertinoListTile',
    'default',
    (ran) => _wide(
      CupertinoListTile(key: formKey, onTap: ran, title: const Text('x')),
    ),
  ),
  _Form(
    'CupertinoListTile',
    '.notched',
    (ran) => _wide(
      CupertinoListTile.notched(
        key: formKey,
        onTap: ran,
        title: const Text('x'),
      ),
    ),
  ),
  // Without onTap it has no handler.
  _Form(
    'CupertinoListTile',
    'disabled',
    (_) => _wide(const CupertinoListTile(key: formKey, title: Text('x'))),
    enabled: false,
    reported: false,
  ),
  _Form(
    'Checkbox',
    'default',
    (ran) => Checkbox(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'Checkbox',
    '.adaptive',
    (ran) =>
        Checkbox.adaptive(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'Checkbox',
    'disabled',
    (_) => const Checkbox(key: formKey, value: false, onChanged: null),
    enabled: false,
  ),
  _Form(
    'Switch',
    'default',
    (ran) => Switch(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'Switch',
    '.adaptive',
    (ran) =>
        Switch.adaptive(key: formKey, value: false, onChanged: (_) => ran()),
  ),
  _Form(
    'Switch',
    'disabled',
    (_) => const Switch(key: formKey, value: false, onChanged: null),
    enabled: false,
  ),
  _Form(
    'DropdownButton',
    'default',
    (ran) => DropdownButton<int>(
      key: formKey,
      value: 1,
      onTap: ran,
      onChanged: (_) {},
      items: const [DropdownMenuItem(value: 1, child: Text('one'))],
    ),
  ),
  _Form(
    'DropdownButton',
    'disabled',
    (ran) => DropdownButton<int>(
      key: formKey,
      value: 1,
      onTap: ran,
      onChanged: null,
      items: const [DropdownMenuItem(value: 1, child: Text('one'))],
    ),
    enabled: false,
  ),
  _Form(
    'ListTile',
    'onTap',
    (ran) => _wide(ListTile(key: formKey, onTap: ran, title: const Text('x'))),
  ),
  _Form(
    'ListTile',
    'disabled',
    (ran) => _wide(
      ListTile(
        key: formKey,
        enabled: false,
        onTap: ran,
        title: const Text('x'),
      ),
    ),
    enabled: false,
  ),
  _Form(
    'CheckboxListTile',
    'title',
    (ran) => _wide(
      CheckboxListTile(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.text('title')),
  ),
  _Form(
    'CheckboxListTile',
    'checkbox',
    (ran) => _wide(
      CheckboxListTile(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.byType(Checkbox)),
  ),
  _Form(
    'CheckboxListTile',
    '.adaptive',
    (ran) => _wide(
      CheckboxListTile.adaptive(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
  ),
  // On iOS the inner control is the CupertinoCheckbox that Checkbox.adaptive
  // builds.
  _Form(
    'CheckboxListTile',
    '.adaptive checkbox',
    (ran) => _wide(
      CheckboxListTile.adaptive(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.byType(Checkbox)),
  ),
  _Form(
    'CheckboxListTile',
    'disabled',
    (_) => _wide(
      const CheckboxListTile(
        key: formKey,
        value: false,
        onChanged: null,
        title: Text('title'),
      ),
    ),
    enabled: false,
  ),
  _Form(
    'SwitchListTile',
    'title',
    (ran) => _wide(
      SwitchListTile(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.text('title')),
  ),
  _Form(
    'SwitchListTile',
    'switch',
    (ran) => _wide(
      SwitchListTile(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.byType(Switch)),
  ),
  _Form(
    'SwitchListTile',
    '.adaptive',
    (ran) => _wide(
      SwitchListTile.adaptive(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
  ),
  _Form(
    'SwitchListTile',
    '.adaptive switch',
    (ran) => _wide(
      SwitchListTile.adaptive(
        key: formKey,
        value: false,
        onChanged: (_) => ran(),
        title: const Text('title'),
      ),
    ),
    at: (t) => t.getCenter(find.byType(Switch)),
  ),
  _Form(
    'SwitchListTile',
    'disabled',
    (_) => _wide(
      const SwitchListTile(
        key: formKey,
        value: false,
        onChanged: null,
        title: Text('title'),
      ),
    ),
    enabled: false,
  ),
  _Form(
    'PopupMenuButton',
    'child',
    (ran) => PopupMenuButton<int>(
      key: formKey,
      itemBuilder: _menu(ran),
      child: const Text('menu'),
    ),
  ),
  _Form(
    'PopupMenuButton',
    'icon',
    (ran) => PopupMenuButton<int>(key: formKey, itemBuilder: _menu(ran)),
  ),
  _Form(
    'PopupMenuButton',
    'disabled icon',
    (ran) => PopupMenuButton<int>(
      key: formKey,
      enabled: false,
      itemBuilder: _menu(ran),
    ),
    enabled: false,
  ),
  _Form(
    'TextField',
    'default',
    (ran) => _wide(TextField(key: formKey, onTap: ran)),
  ),
  // Flutter ignores pointers inside a disabled field.
  _Form(
    'TextField',
    'disabled',
    (ran) => _wide(TextField(key: formKey, enabled: false, onTap: ran)),
    enabled: false,
    reported: false,
  ),
  _Form(
    'InkResponse',
    'InkWell',
    (ran) => InkWell(key: formKey, onTap: ran, child: _box),
  ),
  _Form(
    'InkResponse',
    'InkResponse',
    (ran) => InkResponse(key: formKey, onTap: ran, child: _box),
  ),
  _Form(
    'GestureDetector',
    'onTap',
    (ran) => GestureDetector(key: formKey, onTap: ran, child: _box),
  ),
  // The plain and disabled buttons have tests of their own below.
  _Form(
    'RawGestureDetector',
    'button with a long press',
    (ran) =>
        _RawButton(detectorKey: formKey, onPressed: ran, onLongPress: () {}),
  ),
];

void main() {
  test('controlSpecOf matches rows by type and activity', () {
    // A disabled control is still a control; only its enabled state differs.
    expect(
      controlSpecOf(const ElevatedButton(onPressed: null, child: Text('a')))
          ?.name,
      'ElevatedButton',
    );
    expect(controlSpecOf(const ListTile(title: Text('a'))), isNull);
    expect(controlSpecOf(ListTile(onTap: () {}))?.name, 'ListTile');
    expect(controlSpecOf(GestureDetector(child: const Text('a'))), isNull);
    expect(
      controlSpecOf(
        DropdownButton<String>(items: const [], onChanged: (_) {}),
      )?.name,
      'DropdownButton',
    );
  });

  test('every builds entry is a catalog row', () {
    for (final row in controlCatalog) {
      for (final built in row.builds) {
        expect(controlCatalog, contains(built), reason: row.name);
      }
    }
  });

  test('catalog row names are unique', () {
    final names = controlCatalog.map((r) => r.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('every catalog row has at least one form', () {
    final rows = controlCatalog.map((r) => r.name).toSet();
    expect(rows.difference(_forms.map((f) => f.row).toSet()), isEmpty);
  });

  // Real-tap oracle: tap for real, and the control whose callback ran must
  // be the one resolved.
  group('every control form resolves like a tap', () {
    for (final form in _forms) {
      testWidgets(
        '${form.row} ${form.name}',
        variant: TargetPlatformVariant(
          {TargetPlatform.android, TargetPlatform.iOS},
        ),
        (t) async {
          var ran = 0;
          await t.pumpWidget(app(form.build(() => ran++)));
          final keyed = find.byKey(formKey).first;
          final p = form.at?.call(t) ?? t.getCenter(keyed);

          final r = resolveAt(t, p);
          await t.tapAt(p);
          await t.pump(const Duration(seconds: 1));

          expect(ran, form.enabled ? 1 : 0, reason: 'callback runs');
          if (form.reported) {
            expect(r?.element, same(t.element(keyed)));
            expect(controlSpecOf(r!.element.widget)?.name, form.row);
            expect(r.enabled, form.enabled);
          } else {
            expect(r, isNull);
          }
        },
      );
    }
  });

  testWidgets('a RawGestureDetector button is a target', (t) async {
    var ran = 0;
    await t.pumpWidget(
      app(_RawButton(detectorKey: formKey, onPressed: () => ran++)),
    );
    final p = t.getCenter(find.byKey(formKey));

    final r = resolveAt(t, p);
    await t.tapAt(p);

    expect(ran, 1);
    expect(r?.element, same(t.element(find.byKey(formKey))));
    expect(r!.enabled, isTrue);
  });

  // The tap recognizer stays, but with no callbacks it never joins the
  // arena.
  testWidgets('a RawGestureDetector button with its tap callbacks off is not',
      (t) async {
    await t.pumpWidget(app(const _RawButton(detectorKey: formKey)));

    expect(resolveAt(t, t.getCenter(find.byKey(formKey))), isNull);
  });

  const tileKey = ValueKey('tile');

  /// Taps a [_RawButton] in a tappable ListTile's trailing, and checks the
  /// resolver credits whichever of the two ran.
  Future<void> tapButtonInTile(WidgetTester t, {required bool enabled}) async {
    var tile = 0;
    var button = 0;
    await t.pumpWidget(
      app(
        _wide(
          ListTile(
            key: tileKey,
            onTap: () => tile++,
            title: const Text('x'),
            trailing: _RawButton(
              detectorKey: formKey,
              onPressed: enabled ? () => button++ : null,
            ),
          ),
        ),
      ),
    );
    final p = t.getCenter(find.byKey(formKey));

    final r = resolveAt(t, p);
    await t.tapAt(p);
    await t.pump(const Duration(seconds: 1));

    expect((tile, button), enabled ? (0, 1) : (1, 0));
    final ran = enabled ? formKey : tileKey;
    expect(r?.element, same(t.element(find.byKey(ran))));
    expect(r!.enabled, isTrue);
  }

  testWidgets(
    "a RawGestureDetector button in a ListTile's trailing takes the tap",
    (t) => tapButtonInTile(t, enabled: true),
  );

  testWidgets(
    'the same button disabled credits the ListTile',
    (t) => tapButtonInTile(t, enabled: false),
  );

  testWidgets("a scrollable's drag detector is not a target", (t) async {
    await t.pumpWidget(app(ListView(children: const [SizedBox(height: 40)])));

    expect(resolveAt(t, t.getCenter(find.byType(ListView))), isNull);
  });

  testWidgets(
      "a developer IconButton in a PopupMenuButton's child takes the tap",
      (t) async {
    var ran = 0;
    await t.pumpWidget(
      app(
        PopupMenuButton<int>(
          itemBuilder: (_) => const [PopupMenuItem(value: 1, child: Text('1'))],
          child: IconButton(
            key: const ValueKey('icon'),
            onPressed: () => ran++,
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );
    final p = t.getCenter(find.byKey(const ValueKey('icon')));

    final r = resolveAt(t, p);
    await t.tapAt(p);
    await t.pump(const Duration(seconds: 1));

    expect(ran, 1);
    expect((r?.element.widget.key as ValueKey?)?.value, 'icon');
  });
}
