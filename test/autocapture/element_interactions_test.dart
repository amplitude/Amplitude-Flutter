import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';

void main() {
  group('ElementInteractions.toMapOrBool', () {
    test('returns false for ElementInteractionsDisabled()', () {
      var disabled = ElementInteractionsDisabled();
      expect(ElementInteractions.toMapOrBool(disabled), false);
    });

    test('returns true for ElementInteractionsEnabled()', () {
      var enabled = ElementInteractionsEnabled();
      expect(ElementInteractions.toMapOrBool(enabled), true);
    });

    test('returns a map for ElementInteractionsOptions()', () {
      var options = ElementInteractionsOptions();
      expect(ElementInteractions.toMapOrBool(options),
          isA<Map<String, dynamic>>());
    });
  });

  group('ElementInteractionsOptions', () {
    test('default values should be correctly set', () {
      final options = ElementInteractionsOptions();
      expect(options.cssSelectorAllowlist, isNull);
      expect(options.actionClickAllowlist, isNull);
      expect(options.dataAttributePrefix, isNull);
      expect(options.pageUrlAllowlist, isNull);
    });

    test('custom values should be correctly set', () {
      final options = ElementInteractionsOptions(
        cssSelectorAllowlist: ['a', 'button'],
        actionClickAllowlist: ['div'],
        dataAttributePrefix: 'data-amp-track-',
        pageUrlAllowlist: ['https://example.com'],
      );
      expect(options.cssSelectorAllowlist, ['a', 'button']);
      expect(options.actionClickAllowlist, ['div']);
      expect(options.dataAttributePrefix, 'data-amp-track-');
      expect(options.pageUrlAllowlist, ['https://example.com']);
    });

    test('toMap omits null values', () {
      final options = ElementInteractionsOptions();
      final map = options.toMap();
      expect(map, isEmpty);
    });

    test('toMap includes only the set values', () {
      final options = ElementInteractionsOptions(
        cssSelectorAllowlist: ['a', 'button'],
      );
      final map = options.toMap();
      expect(map['cssSelectorAllowlist'], ['a', 'button']);
      expect(map.containsKey('actionClickAllowlist'), false);
      expect(map.containsKey('dataAttributePrefix'), false);
      expect(map.containsKey('pageUrlAllowlist'), false);
    });

    test('toMap should return correct map with custom values', () {
      final options = ElementInteractionsOptions(
        cssSelectorAllowlist: ['a', 'button'],
        actionClickAllowlist: ['div'],
        dataAttributePrefix: 'data-amp-track-',
        pageUrlAllowlist: ['https://example.com'],
      );
      final map = options.toMap();
      expect(map['cssSelectorAllowlist'], ['a', 'button']);
      expect(map['actionClickAllowlist'], ['div']);
      expect(map['dataAttributePrefix'], 'data-amp-track-');
      expect(map['pageUrlAllowlist'], ['https://example.com']);
    });
  });

  group('ElementInteractionsDisabled', () {
    test('is a subclass of ElementInteractions', () {
      expect(ElementInteractionsDisabled(), isA<ElementInteractions>());
    });
  });

  group('ElementInteractionsEnabled', () {
    test('is a subclass of ElementInteractions', () {
      expect(ElementInteractionsEnabled(), isA<ElementInteractions>());
    });
  });
}
