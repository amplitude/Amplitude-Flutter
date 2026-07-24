import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/attribution.dart';
import 'package:amplitude_flutter/autocapture/element_interactions.dart';
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
      expect(Autocapture.toMapOrBool(autocaptureEnabled),
          isA<Map<String, dynamic>>());
    });

    test('returns a map for AutocaptureOptions()', () {
      var autocaptureOptions = AutocaptureOptions();
      expect(Autocapture.toMapOrBool(autocaptureOptions),
          isA<Map<String, dynamic>>());
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
      expect(options.formInteractions, true);
      expect(options.fileDownloads, true);
      expect(options.elementInteractions, isA<ElementInteractionsDisabled>());
      expect(options.pageUrlEnrichment, true);
    });

    test('appLifecycles, deepLinks, and screenViews default to false', () {
      const options = AutocaptureOptions();

      expect(options.appLifecycles, false);
      expect(options.deepLinks, false);
      expect(options.screenViews, false);
    });

    test('toMap converts options to a map', () {
      const options = AutocaptureOptions();
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], isA<Map<String, dynamic>>());
      expect(map['pageViews'], isA<Map<String, dynamic>>());
      expect(map['appLifecycles'], false);
      expect(map['deepLinks'], false);
      expect(map['screenViews'], false);
      expect(map['formInteractions'], true);
      expect(map['fileDownloads'], true);
      expect(map['elementInteractions'], false);
      expect(map['pageUrlEnrichment'], true);
    });

    test('toMap handles custom values', () {
      const options = AutocaptureOptions(
        sessions: false,
        attribution: AttributionDisabled(),
        pageViews: PageViewsDisabled(),
        appLifecycles: true,
        deepLinks: true,
        screenViews: true,
        formInteractions: false,
        fileDownloads: false,
        elementInteractions: ElementInteractionsOptions(
          cssSelectorAllowlist: ['a', 'button'],
        ),
        pageUrlEnrichment: false,
      );
      final map = options.toMap();

      expect(map['sessions'], false);
      expect(map['attribution'], false);
      expect(map['pageViews'], false);
      expect(map['appLifecycles'], true);
      expect(map['deepLinks'], true);
      expect(map['screenViews'], true);
      expect(map['formInteractions'], false);
      expect(map['fileDownloads'], false);
      expect(map['elementInteractions'], {
        'cssSelectorAllowlist': ['a', 'button'],
      });
      expect(map['pageUrlEnrichment'], false);
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
      expect(options.appLifecycles, true);
      expect(options.deepLinks, true);
      expect(options.screenViews, true);
      expect(options.formInteractions, true);
      expect(options.fileDownloads, true);
      expect(options.elementInteractions, true);
      expect(options.pageUrlEnrichment, true);
    });

    test('toMap includes all enabled values', () {
      const options = AutocaptureEnabled();
      final map = options.toMap();

      expect(map['sessions'], true);
      expect(map['attribution'], true);
      expect(map['pageViews'], true);
      expect(map['appLifecycles'], true);
      expect(map['deepLinks'], true);
      expect(map['screenViews'], true);
      expect(map['formInteractions'], true);
      expect(map['fileDownloads'], true);
      expect(map['elementInteractions'], true);
      expect(map['pageUrlEnrichment'], true);
    });
  });
}
