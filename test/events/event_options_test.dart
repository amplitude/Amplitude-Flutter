import 'package:amplitude_flutter/events/ingestion_metadata.dart';
import 'package:amplitude_flutter/events/plan.dart';
import 'package:test/test.dart';
import 'package:amplitude_flutter/events/event_options.dart'; // Update this import based on your project structure.

void main() {
  group('EventOptions', () {
    test('Should init with default values', () {
      final eventOptions = EventOptions();

      expect(eventOptions.userId, isNull);
      expect(eventOptions.deviceId, isNull);
      expect(eventOptions.timestamp, isNull);
      expect(eventOptions.eventId, isNull);
      expect(eventOptions.sessionId, isNull);
      expect(eventOptions.insertId, isNull);
      expect(eventOptions.locationLat, isNull);
      expect(eventOptions.locationLng, isNull);
      expect(eventOptions.appVersion, isNull);
      expect(eventOptions.versionName, isNull);
      expect(eventOptions.platform, isNull);
      expect(eventOptions.osName, isNull);
      expect(eventOptions.osVersion, isNull);
      expect(eventOptions.deviceBrand, isNull);
      expect(eventOptions.deviceManufacturer, isNull);
      expect(eventOptions.deviceModel, isNull);
      expect(eventOptions.carrier, isNull);
      expect(eventOptions.country, isNull);
      expect(eventOptions.region, isNull);
      expect(eventOptions.city, isNull);
      expect(eventOptions.dma, isNull);
      expect(eventOptions.idfa, isNull);
      expect(eventOptions.idfv, isNull);
      expect(eventOptions.adid, isNull);
      expect(eventOptions.appSetId, isNull);
      expect(eventOptions.androidId, isNull);
      expect(eventOptions.language, isNull);
      expect(eventOptions.library, isNull);
      expect(eventOptions.ip, isNull);
      expect(eventOptions.plan, isNull);
      expect(eventOptions.ingestionMetadata, isNull);
      expect(eventOptions.revenue, isNull);
      expect(eventOptions.price, isNull);
      expect(eventOptions.quantity, isNull);
      expect(eventOptions.productId, isNull);
      expect(eventOptions.revenueType, isNull);
      expect(eventOptions.extra, isNull);
      expect(eventOptions.partnerId, isNull);
      expect(eventOptions.attempts, equals(0));
    });

    test('Should init with custom values', () {
      final testUserId = 'user123';
      final testDeviceId = 'device456';
      final testTimestamp = 1234567890;
      final testEventId = 987;
      final testSessionId = 654321;
      final testInsertId = 'insert789';
      final testLocationLat = 37.7749;
      final testLocationLng = -122.4194;
      final testAppVersion = '1.0.0';
      final testVersionName = 'Version 1';
      final testPlatform = 'iOS';
      final testOsName = 'iOS';
      final testOsVersion = '14.4';
      final testDeviceBrand = 'Apple';
      final testDeviceManufacturer = 'Apple Inc.';
      final testDeviceModel = 'iPhone12,1';
      final testCarrier = 'Verizon';
      final testCountry = 'US';
      final testRegion = 'CA';
      final testCity = 'San Francisco';
      final testDma = '807';
      final testIdfa = 'idfa-example';
      final testIdfv = 'idfv-example';
      final testAdid = 'adid-example';
      final testAppSetId = 'appsetid-example';
      final testAndroidId = 'androidid-example';
      final testLanguage = 'en';
      final testLibrary = 'flutter';
      final testIp = '192.168.1.1';
      final testPlan = Plan(
        branch: 'test-branch',
        source: 'test-source',
        version: 'test-version',
        versionId: 'test-version-id',
      );
      final testIngestionMetadata = IngestionMetadata(
        sourceName: 'test-source-name',
        sourceVersion: 'test-source-version',
      );
      final testRevenue = 9.99;
      final testPrice = 9.99;
      final testQuantity = 1;
      final testProductId = 'product123';
      final testRevenueType = 'purchase';
      final testExtra = {'key': 'value'};
      final testPartnerId = 'partner123';

      final eventOptions = EventOptions(
        userId: testUserId,
        deviceId: testDeviceId,
        timestamp: testTimestamp,
        eventId: testEventId,
        sessionId: testSessionId,
        insertId: testInsertId,
        locationLat: testLocationLat,
        locationLng: testLocationLng,
        appVersion: testAppVersion,
        versionName: testVersionName,
        platform: testPlatform,
        osName: testOsName,
        osVersion: testOsVersion,
        deviceBrand: testDeviceBrand,
        deviceManufacturer: testDeviceManufacturer,
        deviceModel: testDeviceModel,
        carrier: testCarrier,
        country: testCountry,
        region: testRegion,
        city: testCity,
        dma: testDma,
        idfa: testIdfa,
        idfv: testIdfv,
        adid: testAdid,
        appSetId: testAppSetId,
        androidId: testAndroidId,
        language: testLanguage,
        library: testLibrary,
        ip: testIp,
        plan: testPlan,
        ingestionMetadata: testIngestionMetadata,
        revenue: testRevenue,
        price: testPrice,
        quantity: testQuantity,
        productId: testProductId,
        revenueType: testRevenueType,
        extra: testExtra,
        partnerId: testPartnerId,
      );

      // Assertions to validate initialization
      expect(eventOptions.userId, equals(testUserId));
      expect(eventOptions.deviceId, equals(testDeviceId));
      expect(eventOptions.timestamp, equals(testTimestamp));
      expect(eventOptions.eventId, equals(testEventId));
      expect(eventOptions.sessionId, equals(testSessionId));
      expect(eventOptions.insertId, equals(testInsertId));
      expect(eventOptions.locationLat, equals(testLocationLat));
      expect(eventOptions.locationLng, equals(testLocationLng));
      expect(eventOptions.appVersion, equals(testAppVersion));
      expect(eventOptions.versionName, equals(testVersionName));
      expect(eventOptions.platform, equals(testPlatform));
      expect(eventOptions.osName, equals(testOsName));
      expect(eventOptions.osVersion, equals(testOsVersion));
      expect(eventOptions.deviceBrand, equals(testDeviceBrand));
      expect(eventOptions.deviceManufacturer, equals(testDeviceManufacturer));
      expect(eventOptions.deviceModel, equals(testDeviceModel));
      expect(eventOptions.carrier, equals(testCarrier));
      expect(eventOptions.country, equals(testCountry));
      expect(eventOptions.region, equals(testRegion));
      expect(eventOptions.city, equals(testCity));
      expect(eventOptions.dma, equals(testDma));
      expect(eventOptions.idfa, equals(testIdfa));
      expect(eventOptions.idfv, equals(testIdfv));
      expect(eventOptions.adid, equals(testAdid));
      expect(eventOptions.appSetId, equals(testAppSetId));
      expect(eventOptions.androidId, equals(testAndroidId));
      expect(eventOptions.language, equals(testLanguage));
      expect(eventOptions.library, equals(testLibrary));
      expect(eventOptions.ip, equals(testIp));
      expect(eventOptions.plan, equals(testPlan));
      expect(eventOptions.ingestionMetadata, equals(testIngestionMetadata));
      expect(eventOptions.revenue, equals(testRevenue));
      expect(eventOptions.price, equals(testPrice));
      expect(eventOptions.quantity, equals(testQuantity));
      expect(eventOptions.productId, equals(testProductId));
      expect(eventOptions.revenueType, equals(testRevenueType));
      expect(eventOptions.extra, equals(testExtra));
      expect(eventOptions.partnerId, equals(testPartnerId));
    });
  });
}
