import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/event_options.dart';
import 'package:amplitude_flutter/events/ingestion_metadata.dart';
import 'package:amplitude_flutter/events/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseEvent', () {
    test('Should init with default values', () {
      final testEventType = 'test-event-type';
      final event = BaseEvent(testEventType);

      expect(event.eventType, testEventType);
      expect(event.eventProperties, isNull);
      expect(event.userProperties, isNull);
      expect(event.groups, isNull);
      expect(event.groupProperties, isNull);
    });

    test('Should init with custom values', () {
      final testEventType = 'test-event-type';
      final testEventProperties = {
        'test-event-property-key': 'test-event-property-value'
      };
      final testUserProperties = {
        'test-user-property-key': 'test-user-property-value'
      };
      final testGroups = {'test-group-key': 'test-group-value'};
      final testGroupProperties = {
        'test-group-property-key': 'test-group-property-value'
      };
      final event = BaseEvent(
        testEventType,
        eventProperties: testEventProperties,
        userProperties: testUserProperties,
        groups: testGroups,
        groupProperties: testGroupProperties,
      );

      expect(event.eventType, testEventType);
      expect(event.eventProperties, testEventProperties);
      expect(event.userProperties, testUserProperties);
      expect(event.groups, testGroups);
      expect(event.groupProperties, testGroupProperties);
    });

    test('Should toMap() return a correct map with custom values', () {
      final eventType = 'test_event';
      final userId = 'test_user';
      final deviceId = 'test_device';
      final timestamp = 1234567890;
      final eventId = 1;
      final sessionId = 2;
      final insertId = 'insert_id';
      final locationLat = 37.7749;
      final locationLng = -122.4194;
      final appVersion = '1.0.0';
      final versionName = 'version_name';
      final platform = 'Flutter';
      final osName = 'iOS';
      final osVersion = '14.4';
      final deviceBrand = 'Apple';
      final deviceManufacturer = 'Apple';
      final deviceModel = 'iPhone12,1';
      final carrier = 'T-Mobile';
      final country = 'USA';
      final region = 'CA';
      final city = 'San Francisco';
      final dma = 'dma_code';
      final idfa = 'idfa_value';
      final idfv = 'idfv_value';
      final adid = 'adid_value';
      final appSetId = 'app_set_id';
      final androidId = 'android_id';
      final language = 'en';
      final library = 'amplitude-flutter';
      final ip = '192.168.1.1';
      final plan = Plan(branch: 'test_branch', source: 'test_source', version: 'test_version', versionId: 'test_user_id');
      final ingestionMetadata = IngestionMetadata(sourceName: 'source_name', sourceVersion: 'source_version');
      final revenue = 9.99;
      final price = 9.99;
      final quantity = 1;
      final productId = 'product_id';
      final revenueType = 'purchase';
      final extra = {'extra_key': 'extra_value'};
      final partnerId = 'partner_id';

      final event = BaseEvent(
        eventType,
        userId: userId,
        deviceId: deviceId,
        timestamp: timestamp,
        eventId: eventId,
        sessionId: sessionId,
        insertId: insertId,
        locationLat: locationLat,
        locationLng: locationLng,
        appVersion: appVersion,
        versionName: versionName,
        platform: platform,
        osName: osName,
        osVersion: osVersion,
        deviceBrand: deviceBrand,
        deviceManufacturer: deviceManufacturer,
        deviceModel: deviceModel,
        carrier: carrier,
        country: country,
        region: region,
        city: city,
        dma: dma,
        idfa: idfa,
        idfv: idfv,
        adid: adid,
        appSetId: appSetId,
        androidId: androidId,
        language: language,
        library: library,
        ip: ip,
        plan: plan,
        ingestionMetadata: ingestionMetadata,
        revenue: revenue,
        price: price,
        quantity: quantity,
        productId: productId,
        revenueType: revenueType,
        extra: extra,
        partnerId: partnerId,
      );

      final expectedMap = {
        'event_type': eventType,
        'user_id': userId,
        'device_id': deviceId,
        'timestamp': timestamp,
        'event_id': eventId,
        'session_id': sessionId,
        'insert_id': insertId,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'app_version': appVersion,
        'version_name': versionName,
        'platform': platform,
        'os_name': osName,
        'os_version': osVersion,
        'device_brand': deviceBrand,
        'device_manufacturer': deviceManufacturer,
        'device_model': deviceModel,
        'carrier': carrier,
        'country': country,
        'region': region,
        'city': city,
        'dma': dma,
        'idfa': idfa,
        'idfv': idfv,
        'adid': adid,
        'app_set_id': appSetId,
        'android_id': androidId,
        'language': language,
        'library': library,
        'ip': ip,
        'plan': plan.toMap(),
        'ingestion_metadata': ingestionMetadata.toMap(),
        'revenue': revenue,
        'price': price,
        'quantity': quantity,
        'product_id': productId,
        'revenue_type': revenueType,
        'extra': extra,
        'partner_id': partnerId,
        'attempts': 0,
      };

      expect(event.toMap(), equals(expectedMap));
    });

    test('Should mergeEventOptions() merge event options', () {
      final originalUserId = 'original_user';
      final newUserId = 'new_user';
      final deviceId = 'device_id';
      final eventType = 'event_type';

      final originalEvent = BaseEvent(eventType, userId: originalUserId, deviceId: deviceId);
      final newOptions = EventOptions(userId: newUserId);

      originalEvent.mergeEventOptions(newOptions);

      // User Id should be overwritten to the new one
      expect(originalEvent.userId, newUserId);
      // Device Id should remain unchanged
      expect(originalEvent.deviceId, deviceId);
    });
  });
}
