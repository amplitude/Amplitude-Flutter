import 'package:amplitude_flutter/default_tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main(){
  group('DefaultTrackingOptions', () {
    test('should enable all default tracking options', () {
      var defaultTrackingOptions = DefaultTrackingOptions.all();

      expect(defaultTrackingOptions.sessions, true);
      expect(defaultTrackingOptions.mobileDefaultTrackingOptions.appLifecycles, true);
      expect(defaultTrackingOptions.mobileDefaultTrackingOptions.screenViews, true);
      expect(defaultTrackingOptions.androidDefaultTrackingOptions.deepLinks, true);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.attribution, true);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.pageViews, true);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.formInteractions, true);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.fileDownloads, true);
    });

    test('should disable all default tracking options', () {
      var defaultTrackingOptions = DefaultTrackingOptions.none();

      expect(defaultTrackingOptions.sessions, false);
      expect(defaultTrackingOptions.mobileDefaultTrackingOptions.appLifecycles, false);
      expect(defaultTrackingOptions.mobileDefaultTrackingOptions.screenViews, false);
      expect(defaultTrackingOptions.androidDefaultTrackingOptions.deepLinks, false);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.attribution, false);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.pageViews, false);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.formInteractions, false);
      expect(defaultTrackingOptions.webDefaultTrackingOptions.fileDownloads, false);
    });
  });
}