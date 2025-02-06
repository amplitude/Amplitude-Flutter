import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/attribution.dart';
import 'package:amplitude_flutter/autocapture/page_views.dart';

void main() {
  // create tests for toMapOrBool
  // create tests for AutocaptureOptions
  // create tests for AutocaptureDisabled
  // create tests for AutocaptureEnabled
  group('Autocapture.toMapOrBool', () {
    test('returns false for AutocaptureDisabled()', () {
      var autocaptureDisabled = AutocaptureDisabled();
      expect(Autocapture.toMapOrBool(autocaptureDisabled), false);
    });

    test('returns a map for AutocaptureEnabled()', () {
      var autocaptureEnabled = AutocaptureEnabled();
      expect(Autocapture.toMapOrBool(autocaptureEnabled), isA<Map<String, dynamic>>());
    });

    test('returns a map for AutocaptureOptions()', () {
      var autocaptureOptions = AutocaptureOptions();
      expect(Autocapture.toMapOrBool(autocaptureOptions), isA<Map<String, dynamic>>());
    });
  });

  group('AutocaptureOptions', () {
    test('is a subclass of Autocapture', () {
      expect(AutocaptureDisabled(), isA<Autocapture>());
    });

    test('Default constructor sets default values', () {
      const options = AutocaptureOptions();

      expect(options.attribution, isA<AttributionOptions>());
      expect(options.sessions, true);
      expect(options.pageViews, isA<PageViewsOptions>());
    });

    test('toMap converts options to a map', () {
      const options = AutocaptureOptions();
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], isA<Map<String, dynamic>>());
      expect(map['pageViews'], isA<Map<String, dynamic>>());
    });

    test('toMap handles custom values', () {
      const options = AutocaptureOptions(
        sessions: false,
        attribution: AttributionDisabled(),
        pageViews: PageViewsDisabled(),
      );
      final map = options.toMap();

      expect(map['sessions'], false);
      expect(map['attribution'], false);
      expect(map['pageViews'], false);
    });
  });

  group('AutocaptureDisabled', () {
    test('is a subclass of Autocapture', () {
      expect(AutocaptureDisabled(), isA<Autocapture>());
    });
  });

  group('AutocaptureEnabled', () {
    test('is a subclass of Autocapture', () {
      expect(AutocaptureEnabled(), isA<Autocapture>());
    });

    test('Constructor sets values to true', () {
      const options = AutocaptureEnabled();

      expect(options.attribution, true);
      expect(options.sessions, true);
      expect(options.pageViews, true);
    });
  });
}
