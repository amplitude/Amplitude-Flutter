import 'package:amplitude_flutter/src/interaction/control_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
