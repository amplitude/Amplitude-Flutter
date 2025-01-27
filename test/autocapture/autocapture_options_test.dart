import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/autocapture_options.dart';
import 'package:amplitude_flutter/autocapture/attribution_options.dart';
import 'package:amplitude_flutter/autocapture/page_views_options.dart';

void main() {
  group('AutocaptureOptions', () {
    test('Default constructor sets default values', () {
      const options = AutocaptureOptions();

      expect(options.attribution, isA<AttributionOptions>());
      expect(options.sessions, true);
      expect(options.pageViews, isA<PageViewsOptions>());
    });

    test('Disabled factory sets all values to false', () {
      var options = AutocaptureOptions.disabled();

      expect(options.attribution, false);
      expect(options.sessions, false);
      expect(options.pageViews, false);
    });

    test('toMap converts options to a map', () {
      const options = AutocaptureOptions();
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], isA<Map<String, dynamic>>());
      expect(map['pageViews'], isA<Map<String, dynamic>>());
    });

    test('toMap handles boolean values for attribution and pageViews', () {
      const options = AutocaptureOptions(
        attribution: false,
        pageViews: false,
      );
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], false);
      expect(map['pageViews'], false);
    });

    test('toMap handles AttributionOptions and PageViewsOptions', () {
      const attributionOptions = AttributionOptions();
      const pageViewsOptions = PageViewsOptions();
      const options = AutocaptureOptions(
        attribution: attributionOptions,
        pageViews: pageViewsOptions,
      );
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], attributionOptions.toMap());
      expect(map['pageViews'], pageViewsOptions.toMap());
    });
  });
}
