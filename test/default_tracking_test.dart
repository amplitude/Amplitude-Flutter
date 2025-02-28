import 'package:amplitude_flutter/default_tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultTrackingOptions', () {
    test('should enable all default tracking options', () {
      var defaultTrackingOptions = DefaultTrackingOptions.all();

      expect(defaultTrackingOptions.sessions, true);
      expect(defaultTrackingOptions.appLifecycles, true);
      // expect(defaultTrackingOptions.screenViews, true);
      expect(defaultTrackingOptions.deepLinks, true);
      expect(defaultTrackingOptions.attribution, true);
      expect(defaultTrackingOptions.pageViews, true);
      expect(defaultTrackingOptions.formInteractions, true);
      expect(defaultTrackingOptions.fileDownloads, true);
    });

    test('should disable all default tracking options', () {
      var defaultTrackingOptions = DefaultTrackingOptions.none();

      expect(defaultTrackingOptions.sessions, false);
      expect(defaultTrackingOptions.appLifecycles, false);
      // expect(defaultTrackingOptions.screenViews, false);
      expect(defaultTrackingOptions.deepLinks, false);
      expect(defaultTrackingOptions.attribution, false);
      expect(defaultTrackingOptions.pageViews, false);
      expect(defaultTrackingOptions.formInteractions, false);
      expect(defaultTrackingOptions.fileDownloads, false);
    });
  });
}
