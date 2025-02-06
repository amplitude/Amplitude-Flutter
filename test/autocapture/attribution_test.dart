import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/attribution.dart';

void main() {
  group('Attribution.toMapOrBool', () {
    test('returns false for AttributionDisabled()', () {
      var attributionDisabled = AttributionDisabled();
      expect(Attribution.toMapOrBool(attributionDisabled), false);
    });

    test('returns true for AttributionEnabled()', () {
      var attributionEnabled = AttributionEnabled();
      expect(Attribution.toMapOrBool(attributionEnabled), true);
    });

    test('returns a map for AttributionOptions()', () {
      var attributionOptions = AttributionOptions();
      expect(Attribution.toMapOrBool(attributionOptions), isA<Map<String, dynamic>>());
    });
  });

  group('AttributionOptions', () {
    test('default values should be correctly set', () {
      final options = AttributionOptions();
      expect(options.excludeReferrers, isNull);
      expect(options.initialEmptyValue, 'EMPTY');
      expect(options.resetSessionOnNewCampaign, false);
    });

    test('custom values should be correctly set', () {
      final options = AttributionOptions(
        excludeReferrers: ['example.com'],
        initialEmptyValue: 'NONE',
        resetSessionOnNewCampaign: true,
      );
      expect(options.excludeReferrers, ['example.com']);
      expect(options.initialEmptyValue, 'NONE');
      expect(options.resetSessionOnNewCampaign, true);
    });

    test('toMap should return correct map with default values', () {
      final options = AttributionOptions();
      final map = options.toMap();
      expect(map['initialEmptyValue'], 'EMPTY');
      expect(map['resetSessionOnNewCampaign'], false);
      expect(map.containsKey('excludeReferrers'), false);
    });

    test('toMap should return correct map with custom values', () {
      final options = AttributionOptions(
        excludeReferrers: ['example.com'],
        initialEmptyValue: 'NONE',
        resetSessionOnNewCampaign: true,
      );
      final map = options.toMap();
      expect(map['initialEmptyValue'], 'NONE');
      expect(map['resetSessionOnNewCampaign'], true);
      expect(map['excludeReferrers'], ['example.com']);
    });
  });

  group('AttributionDisabled', () {
    test('is a subclass of Attribution', () {
      expect(AttributionDisabled(), isA<Attribution>());
    });
  });

  group('AttributionEnabled', () {
    test('is a subclass of Attribution', () {
      expect(AttributionEnabled(), isA<Attribution>());
    });
  });
}
