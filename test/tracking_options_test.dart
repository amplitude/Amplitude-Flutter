import 'package:test/test.dart';
import 'package:amplitude_flutter/tracking_options.dart';
import 'package:amplitude_flutter/constants.dart';

void main() {
  group("TrackingOptions", () {
    test("Should have all tracking enabled by default", () {
      final trackingOptions = TrackingOptions();
      expect(trackingOptions.ipAddress, true);
      expect(trackingOptions.language, true);
      expect(trackingOptions.platform, true);
      expect(trackingOptions.region, true);
      expect(trackingOptions.dma, true);
      expect(trackingOptions.country, true);
      expect(trackingOptions.city, true);
      expect(trackingOptions.carrier, true);
      expect(trackingOptions.deviceModel, true);
      expect(trackingOptions.deviceManufacturer, true);
      expect(trackingOptions.osVersion, true);
      expect(trackingOptions.osName, true);
      expect(trackingOptions.versionName, true);
      expect(trackingOptions.adid, true);
      expect(trackingOptions.appSetId, true);
      expect(trackingOptions.deviceBrand, true);
      expect(trackingOptions.latLag, true);
      expect(trackingOptions.apiLevel, true);
      expect(trackingOptions.idfv, true);
    });

    test("Should init with custom options", () {
      final trackingOptions =
          TrackingOptions(ipAddress: false, country: false, city: true);
      expect(trackingOptions.ipAddress, false);
      expect(trackingOptions.language, true);
      expect(trackingOptions.platform, true);
      expect(trackingOptions.region, true);
      expect(trackingOptions.dma, true);
      expect(trackingOptions.country, false);
      expect(trackingOptions.city, true);
      expect(trackingOptions.carrier, true);
      expect(trackingOptions.deviceModel, true);
      expect(trackingOptions.deviceManufacturer, true);
      expect(trackingOptions.osVersion, true);
      expect(trackingOptions.osName, true);
      expect(trackingOptions.versionName, true);
      expect(trackingOptions.adid, true);
      expect(trackingOptions.appSetId, true);
      expect(trackingOptions.deviceBrand, true);
      expect(trackingOptions.latLag, true);
      expect(trackingOptions.apiLevel, true);
      expect(trackingOptions.idfv, true);
    });

    test("Should toMap correctly", () {
      final trackingOptions = TrackingOptions();
      expect(trackingOptions.toMap(), {
        "ipAddress": true,
        "language": true,
        "platform": true,
        "region": true,
        "dma": true,
        "country": true,
        "city": true,
        "carrier": true,
        "deviceModel": true,
        "deviceManufacturer": true,
        "osVersion": true,
        "osName": true,
        "versionName": true,
        "adid": true,
        "appSetId": true,
        "deviceBrand": true,
        "latLag": true,
        "apiLevel": true,
        "idfv": true,
      });
    });
  });
}
