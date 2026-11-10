@TestOn('chrome')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:amplitude_flutter/web/configuration_transform.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the web glue (`transformWebConfiguration(...).jsify()`) that
/// `AmplitudeFlutterPlugin.getConfiguration` performs, on the real `chrome`
/// platform. Run with `flutter test --platform chrome`.
void main() {
  group('web configuration jsify', () {
    test('transformed config jsifies into a Browser-SDK-shaped JS object', () {
      final jsConfig = transformWebConfiguration({
        'apiKey': 'k',
        'logLevel': 'warn',
        'serverZone': 'us',
        'defaultTracking': {'sessions': true},
        'autocapture': {
          'sessions': true,
          'pageViews': {'trackHistoryChanges': 'all'},
          'appLifecycles': true,
          'deepLinks': true,
          'screenViews': true,
          'formInteractions': true,
          'fileDownloads': true,
          'elementInteractions': {
            'cssSelectorAllowlist': ['a', 'button'],
          },
          'pageUrlEnrichment': true,
        },
      }).jsify() as JSObject;

      // defaultTracking dropped; logLevel -> numeric index; serverZone -> upper.
      expect(jsConfig.has('defaultTracking'), isFalse);
      expect((jsConfig['logLevel'] as JSNumber).toDartInt, 2);
      expect((jsConfig['serverZone'] as JSString).toDart, 'US');

      final autocapture = jsConfig['autocapture'] as JSObject;
      // Mobile-only keys stripped.
      expect(autocapture.has('appLifecycles'), isFalse);
      expect(autocapture.has('deepLinks'), isFalse);
      expect(autocapture.has('screenViews'), isFalse);
      // Web keys preserved.
      expect((autocapture['formInteractions'] as JSBoolean).toDart, isTrue);
      expect((autocapture['fileDownloads'] as JSBoolean).toDart, isTrue);
      expect((autocapture['pageUrlEnrichment'] as JSBoolean).toDart, isTrue);

      // Nested object + list survive the jsify conversion.
      final pageViews = autocapture['pageViews'] as JSObject;
      expect((pageViews['trackHistoryChanges'] as JSString).toDart, 'all');
      final element = autocapture['elementInteractions'] as JSObject;
      final allowlist = (element['cssSelectorAllowlist'] as JSArray).toDart;
      expect(allowlist.length, 2);
    });

    test('AutocaptureDisabled serializes as the JS boolean false', () {
      final jsConfig =
          transformWebConfiguration({'autocapture': false}).jsify() as JSObject;
      expect((jsConfig['autocapture'] as JSBoolean).toDart, isFalse);
    });
  });
}
