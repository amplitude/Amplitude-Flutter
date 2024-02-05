import 'package:test/test.dart';
import 'package:amplitude_flutter/tracking_options.dart';
import 'package:amplitude_flutter/constants.dart';

void main() {
  group('TrackingOptions', () {
    test('should have all tracking enabled by default', () {
      final trackingOptions = TrackingOptions();
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], isEmpty);
    });

    test('should disable IP Address tracking when specified', () {
      final trackingOptions = TrackingOptions(ipAddress: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionIpAddress));
    });

    test('should disable Language tracking when specified', () {
      final trackingOptions = TrackingOptions(language: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionLanguage));
    });

    test('should disable Platform tracking when specified', () {
      final trackingOptions = TrackingOptions(platform: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionPlatform));
    });

    test('should disable Region tracking when specified', () {
      final trackingOptions = TrackingOptions(region: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionRegion));
    });

    test('should disable ADID tracking when specified', () {
      final trackingOptions = TrackingOptions(adid: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionAdid));
    });

    test('should disable IDFV tracking when specified', () {
      final trackingOptions = TrackingOptions(idfv: false);
      final map = trackingOptions.toMap();

      expect(map['disabledFields'], contains(Constants.ampTrackingOptionIdfv));
    });
  });
}
