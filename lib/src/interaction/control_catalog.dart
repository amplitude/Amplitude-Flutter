import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';

/// One row of the catalog: how to recognize a Flutter control and read it.
class ControlSpec {
  ControlSpec._({
    required this.name,
    required bool Function(Widget w) isType,
    required bool Function(Widget w) isActive,
    required bool Function(Widget w) isEnabled,
    required List<Widget?> Function(Widget w) slots,
    required this.builds,
    required this.generic,
  })  : _isType = isType,
        _isActive = isActive,
        _isEnabled = isEnabled,
        _slots = slots;

  /// The only way to make a row. Built-in rows and any later registration
  /// API or companion package describe a control the same way.
  ///
  /// [isActive] says whether a widget of type [T] is a control at all (a
  /// ListTile without handlers is not); [isEnabled] whether it currently
  /// accepts input. [slots] are the developer-supplied widgets it renders,
  /// and [builds] the catalog rows it builds outside those slots, which
  /// belong to it rather than being targets of their own. [generic] marks
  /// the handlers concrete controls are built from (InkResponse and
  /// GestureDetector), which are never targets inside another control.
  static ControlSpec of<T extends Widget>({
    required String name,
    bool Function(T w)? isActive,
    bool Function(T w)? isEnabled,
    List<Widget?> Function(T w)? slots,
    List<ControlSpec> builds = const [],
    bool generic = false,
  }) =>
      ControlSpec._(
        name: name,
        isType: (w) => w is T,
        isActive: isActive == null ? _always : (w) => isActive(w as T),
        isEnabled: isEnabled == null ? _always : (w) => isEnabled(w as T),
        slots: slots == null ? _noSlots : (w) => slots(w as T),
        builds: builds,
        generic: generic,
      );

  static bool _always(Widget w) => true;
  static List<Widget?> _noSlots(Widget w) => const [];

  final String name;
  final List<ControlSpec> builds;
  final bool generic;
  final bool Function(Widget w) _isType;
  final bool Function(Widget w) _isActive;
  final bool Function(Widget w) _isEnabled;
  final List<Widget?> Function(Widget w) _slots;

  /// Whether [w] has this row's type. [controlRowOfType] caches the answer
  /// per runtime type.
  bool isType(Widget w) => _isType(w);
  bool isActive(Widget w) => _isActive(w);
  bool isEnabled(Widget w) => _isEnabled(w);

  /// Only the widget passed in a slot counts as entering it.
  List<Widget?> slots(Widget w) => _slots(w);

  @override
  String toString() => 'ControlSpec($name)';
}

bool _pressable({VoidCallback? onPressed, VoidCallback? onLongPress}) =>
    onPressed != null || onLongPress != null;

// Only the public ButtonStyleButton subclasses are rows. A private subclass
// (Material 3's IconButton builds one) is a framework internal; reporting
// it would displace the public widget the developer actually wrote.
final elevatedButtonRow = ControlSpec.of<ElevatedButton>(
  name: 'ElevatedButton',
  isEnabled: (w) =>
      _pressable(onPressed: w.onPressed, onLongPress: w.onLongPress),
  slots: (w) => [w.child],
);

final textButtonRow = ControlSpec.of<TextButton>(
  name: 'TextButton',
  isEnabled: (w) =>
      _pressable(onPressed: w.onPressed, onLongPress: w.onLongPress),
  slots: (w) => [w.child],
);

final outlinedButtonRow = ControlSpec.of<OutlinedButton>(
  name: 'OutlinedButton',
  isEnabled: (w) =>
      _pressable(onPressed: w.onPressed, onLongPress: w.onLongPress),
  slots: (w) => [w.child],
);

final filledButtonRow = ControlSpec.of<FilledButton>(
  name: 'FilledButton',
  isEnabled: (w) =>
      _pressable(onPressed: w.onPressed, onLongPress: w.onLongPress),
  slots: (w) => [w.child],
);

final materialButtonRow = ControlSpec.of<MaterialButton>(
  name: 'MaterialButton',
  isEnabled: (w) =>
      _pressable(onPressed: w.onPressed, onLongPress: w.onLongPress),
  slots: (w) => [w.child],
);

final iconButtonRow = ControlSpec.of<IconButton>(
  name: 'IconButton',
  isEnabled: (w) => w.onPressed != null,
);

final floatingActionButtonRow = ControlSpec.of<FloatingActionButton>(
  name: 'FloatingActionButton',
  isEnabled: (w) => w.onPressed != null,
  slots: (w) => [w.child],
);

final cupertinoButtonRow = ControlSpec.of<CupertinoButton>(
  name: 'CupertinoButton',
  isEnabled: (w) => w.onPressed != null,
  slots: (w) => [w.child],
);

final checkboxRow = ControlSpec.of<Checkbox>(
  name: 'Checkbox',
  isEnabled: (w) => w.onChanged != null,
);

final switchRow = ControlSpec.of<Switch>(
  name: 'Switch',
  isEnabled: (w) => w.onChanged != null,
);

final dropdownButtonRow = ControlSpec.of<DropdownButton>(
  name: 'DropdownButton',
  isEnabled: (w) {
    // `w is DropdownButton` matches any DropdownButton<T>; reading the
    // typed getters through the static type throws a cast error for every
    // real (typed) dropdown, so read them dynamically.
    final dynamic dropdown = w;
    return dropdown.onChanged != null &&
        ((dropdown.items as List?)?.isNotEmpty ?? false);
  },
);

final listTileRow = ControlSpec.of<ListTile>(
  name: 'ListTile',
  isActive: (w) => w.onTap != null || w.onLongPress != null,
  isEnabled: (w) => w.enabled,
  slots: (w) => [w.leading, w.title, w.subtitle, w.trailing],
);

final checkboxListTileRow = ControlSpec.of<CheckboxListTile>(
  name: 'CheckboxListTile',
  isEnabled: (w) => w.onChanged != null,
  slots: (w) => [w.secondary, w.title, w.subtitle],
  builds: [listTileRow, checkboxRow],
);

final switchListTileRow = ControlSpec.of<SwitchListTile>(
  name: 'SwitchListTile',
  isEnabled: (w) => w.onChanged != null,
  slots: (w) => [w.secondary, w.title, w.subtitle],
  builds: [listTileRow, switchRow],
);

// Without a child it builds an IconButton, which is its own. The child slot
// keeps a developer's IconButton passed as the child a target of its own.
final popupMenuButtonRow = ControlSpec.of<PopupMenuButton>(
  name: 'PopupMenuButton',
  isEnabled: (w) => w.enabled,
  slots: (w) => [w.child, w.icon],
  builds: [iconButtonRow],
);

final textFieldRow = ControlSpec.of<TextField>(
  name: 'TextField',
  isActive: (w) => w.enabled ?? true,
);

// Includes InkWell.
final inkResponseRow = ControlSpec.of<InkResponse>(
  name: 'InkResponse',
  isActive: (w) =>
      w.onTap != null || w.onLongPress != null || w.onDoubleTap != null,
  slots: (w) => [w.child],
  generic: true,
);

final gestureDetectorRow = ControlSpec.of<GestureDetector>(
  name: 'GestureDetector',
  isActive: (w) =>
      w.onTap != null ||
      w.onTapUp != null ||
      w.onTapDown != null ||
      w.onLongPress != null ||
      w.onDoubleTap != null,
  slots: (w) => [w.child],
  generic: true,
);

/// Every control the resolver recognizes. No widget matches two rows.
final List<ControlSpec> controlCatalog = [
  elevatedButtonRow,
  textButtonRow,
  outlinedButtonRow,
  filledButtonRow,
  materialButtonRow,
  iconButtonRow,
  floatingActionButtonRow,
  cupertinoButtonRow,
  checkboxRow,
  switchRow,
  dropdownButtonRow,
  listTileRow,
  checkboxListTileRow,
  switchListTileRow,
  popupMenuButtonRow,
  textFieldRow,
  inkResponseRow,
  gestureDetectorRow,
];

final _rowByType = <Type, ControlSpec?>{};

/// The row whose type [w] has, whether or not [w] is active, or null.
///
/// The resolver checks whether a widget is internal to its owner before
/// asking [ControlSpec.isActive], so this lookup is kept separate.
ControlSpec? controlRowOfType(Widget w) =>
    _rowByType.putIfAbsent(w.runtimeType, () {
      for (final row in controlCatalog) {
        if (row.isType(w)) return row;
      }
      return null;
    });

/// The active row for [w], or null when [w] is not a control.
ControlSpec? controlSpecOf(Widget w) {
  final row = controlRowOfType(w);
  return row != null && row.isActive(w) ? row : null;
}
