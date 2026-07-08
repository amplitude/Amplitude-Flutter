import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/web/configuration_transform.dart';

void main() {
  group('transformWebConfiguration', () {
    test('removes defaultTracking', () {
      final result = transformWebConfiguration({
        'defaultTracking': {'sessions': true},
        'apiKey': 'k',
      });

      expect(result.containsKey('defaultTracking'), false);
      expect(result['apiKey'], 'k');
    });

    test('maps logLevel name to its numeric index', () {
      expect(transformWebConfiguration({'logLevel': 'off'})['logLevel'], 0);
      expect(transformWebConfiguration({'logLevel': 'warn'})['logLevel'], 2);
      expect(transformWebConfiguration({'logLevel': 'debug'})['logLevel'], 4);
    });

    test('uppercases serverZone', () {
      expect(transformWebConfiguration({'serverZone': 'us'})['serverZone'], 'US');
      expect(transformWebConfiguration({'serverZone': 'eu'})['serverZone'], 'EU');
    });

    test('strips mobile-only autocapture keys but keeps web keys', () {
      final result = transformWebConfiguration({
        'autocapture': {
          'sessions': true,
          'attribution': {'initialEmptyValue': 'EMPTY'},
          'pageViews': {'trackHistoryChanges': 'all'},
          'appLifecycles': true,
          'deepLinks': true,
          'screenViews': true,
          'formInteractions': true,
          'fileDownloads': true,
          'elementInteractions': false,
          'pageUrlEnrichment': true,
        },
      });

      final autocapture = result['autocapture'] as Map;
      expect(autocapture.containsKey('appLifecycles'), false);
      expect(autocapture.containsKey('deepLinks'), false);
      expect(autocapture.containsKey('screenViews'), false);
      expect(autocapture['sessions'], true);
      expect(autocapture['attribution'], {'initialEmptyValue': 'EMPTY'});
      expect(autocapture['pageViews'], {'trackHistoryChanges': 'all'});
      expect(autocapture['formInteractions'], true);
      expect(autocapture['fileDownloads'], true);
      expect(autocapture['elementInteractions'], false);
      expect(autocapture['pageUrlEnrichment'], true);
    });

    test('passes pageViews through unchanged even when screenViews is enabled '
        '(never auto-disables it)', () {
      final result = transformWebConfiguration({
        'autocapture': {
          'pageViews': {'trackHistoryChanges': 'all'},
          'screenViews': true,
        },
      });

      // pageViews must not be silently disabled: the observer is opt-in and may
      // not be attached, so disabling pageViews could drop navigation capture.
      final autocapture = result['autocapture'] as Map;
      expect(autocapture['pageViews'], {'trackHistoryChanges': 'all'});
    });

    test('leaves autocapture untouched when it is false (AutocaptureDisabled)',
        () {
      final result = transformWebConfiguration({'autocapture': false});
      expect(result['autocapture'], false);
    });

    test('does not mutate the input map', () {
      final input = {
        'defaultTracking': {'sessions': true},
        'autocapture': {'appLifecycles': true, 'formInteractions': true},
      };
      transformWebConfiguration(input);

      expect(input.containsKey('defaultTracking'), true);
      expect((input['autocapture'] as Map).containsKey('appLifecycles'), true);
    });

    test('round-trips a default Configuration into a web-shaped autocapture', () {
      final config = Configuration(
        apiKey: 'k',
        autocapture: const AutocaptureOptions(),
      );

      final result = transformWebConfiguration(config.toMap());
      final autocapture = result['autocapture'] as Map;

      expect(result.containsKey('defaultTracking'), false);
      expect(autocapture.containsKey('appLifecycles'), false);
      expect(autocapture.containsKey('deepLinks'), false);
      expect(autocapture.containsKey('screenViews'), false);
      expect(autocapture['formInteractions'], true);
      expect(autocapture['fileDownloads'], true);
      expect(autocapture['elementInteractions'], false);
      expect(autocapture['pageUrlEnrichment'], true);
    });
  });
}
