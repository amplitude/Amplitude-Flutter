import 'dart:convert';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/event_options.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:amplitude_flutter/events/revenue.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

/// Generates mocked MethodChannel.
/// ```
/// class MockMethodChannel extends Mock implements MethodChannel
/// ```
/// Learn more [here](https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md).
@GenerateNiceMocks([MockSpec<MethodChannel>()])
import 'amplitude_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockMethodChannel mockChannel;
  late Amplitude amplitude;
  final testApiKey = "test-api-key";
  final testUserId = "test user id";
  final testDeviceId = "test device id";
  final testProperty = "property";
  final testValue = "value";
  final testGroupType = "group type";
  final testGroupName = "group name";
  final testConfiguration = Configuration(apiKey: testApiKey);
  final testConfigurationMap = {
    "apiKey": testApiKey,
    "flushQueueSize": 30,
    "flushIntervalMillis": 30000,
    "instanceName": Constants.defaultInstanceName,
    "optOut": false,
    "logLevel": LogLevel.warn.toString(),
    "minIdLength": null,
    "partnerId": null,
    "flushMaxRetries": 5,
    "useBatch": false,
    "serverZone": ServerZone.us.toString(),
    "serverUrl": null,
    "minTimeBetweenSessionsMillis": 5 * 60 * 1000,
    "defaultTracking": {
      "sessions": true,
      "appLifecycles": false,
      "screenViews": false,
      "deepLinks": false,
      "attribution": true,
      "pageViews": true,
      "formInteractions": true,
      "fileDownloads": true,
    },
    "trackingOptions": {
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
    },
    "enableCoppaControl": false,
    "flushEventsOnClose": true,
    "identifyBatchIntervalMillis": 30 * 1000,
    "migrateLegacyData": true,
    "locationListening": true,
    "useAdvertisingIdForDeviceId": false,
    "useAppSetIdForDeviceId": false,
    "appVersion": null,
  };
  final testEvent = BaseEvent(eventType: "testEvent");
  final testEventMap = {
    "event_type": "testEvent",
    "event_properties": null,
    "user_properties": null,
    "groups": null,
    "group_properties": null,
    "user_id": null,
    "device_id": null,
    "timestamp": null,
    "event_id": null,
    "session_id": null,
    "insert_id": null,
    "location_lat": null,
    "location_lng": null,
    "app_version": null,
    "version_name": null,
    "platform": null,
    "os_name": null,
    "os_version": null,
    "device_brand": null,
    "device_manufacturer": null,
    "device_model": null,
    "carrier": null,
    "country": null,
    "region": null,
    "city": null,
    "dma": null,
    "idfa": null,
    "idfv": null,
    "adid": null,
    "app_set_id": null,
    "android_id": null,
    "language": null,
    "library": null,
    "ip": null,
    "plan": null,
    "ingestion_metadata": null,
    "revenue": null,
    "price": null,
    "quantity": null,
    "product_id": null,
    "revenue_type": null,
    "extra": null,
    "partner_id": null,
    "attempts": 0,
  };
  final testPrice = 3.99;
  final testQuantity = 3;
  final testProductId = "com.company.productId";

  setUp(() async {
    mockChannel = MockMethodChannel();
    when(mockChannel.invokeListMethod("init", any))
        .thenAnswer((_) async => null);
    amplitude = Amplitude(testConfiguration);
    await amplitude.init(mockChannel);
  });

  test("Should init calls MethodChannel", () async {
    expect(amplitude, isA<Amplitude>());
    verify(mockChannel.invokeListMethod(
            "init", jsonEncode(testConfigurationMap)))
        .called(1);
  });

  test("Should track calls MethodChannel", () async {
    when(mockChannel.invokeMethod("track", any)).thenAnswer((_) async => null);
    await amplitude.track(event: testEvent);

    verify(mockChannel.invokeMethod("track", jsonEncode(testEventMap)))
        .called(1);
  });

  test("Should track with event options calls MethodChannel", () async {
    when(mockChannel.invokeMethod("track", any)).thenAnswer((_) async => null);
    await amplitude.track(
        event: testEvent, options: EventOptions(userId: testUserId));

    final expectedEventMap = new Map.from(testEventMap);
    expectedEventMap["user_id"] = testUserId;
    verify(mockChannel.invokeMethod("track", jsonEncode(expectedEventMap)))
        .called(1);
  });

  test("Should identify calls MethodChannel", () async {
    when(mockChannel.invokeMethod("identify", any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(property: testProperty, value: testValue);
    await amplitude.identify(identify: identify);

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["event_type"] = Constants.identify_event;
    testIdentifyMap["user_properties"] = {
      "\$set": {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod("identify", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should identify calls setUserId in MethodChannel", () async {
    when(mockChannel.invokeMethod("identify", any))
        .thenAnswer((_) async => null);
    when(mockChannel.invokeMethod("setUserId", any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(property: testProperty, value: testValue);
    await amplitude.identify(
        identify: identify, options: EventOptions(userId: testUserId));

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["user_id"] = testUserId;
    testIdentifyMap["event_type"] = Constants.identify_event;
    testIdentifyMap["user_properties"] = {
      "\$set": {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod("setUserId", jsonEncode({"setUserId": testUserId})))
        .called(1);
    verify(mockChannel.invokeMethod("identify", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should identify calls setDeviceId in MethodChannel", () async {
    when(mockChannel.invokeMethod("identify", any))
        .thenAnswer((_) async => null);
    when(mockChannel.invokeMethod("setDeviceId", any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(property: testProperty, value: testValue);
    await amplitude.identify(
        identify: identify, options: EventOptions(deviceId: testDeviceId));

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["device_id"] = testDeviceId;
    testIdentifyMap["event_type"] = Constants.identify_event;
    testIdentifyMap["user_properties"] = {
      "\$set": {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod("setDeviceId", jsonEncode({"setDeviceId": testDeviceId})))
        .called(1);
    verify(mockChannel.invokeMethod("identify", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should groupIdentify calls MethodChannel", () async {
    when(mockChannel.invokeMethod("groupIdentify", any))
        .thenAnswer((_) async => null);

    final groupIdentify = Identify()
      ..set(property: testProperty, value: testValue);
    await amplitude.groupIdentify(
        groupType: testGroupType,
        groupName: testGroupName,
        identify: groupIdentify);

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["event_type"] = Constants.group_identify_event;
    testIdentifyMap["groups"] = {testGroupType: testGroupName};
    testIdentifyMap["group_properties"] = {
      "\$set": {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod(
            "groupIdentify", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should groupIdentify with event options calls MethodChannel", () async {
    when(mockChannel.invokeMethod("groupIdentify", any))
        .thenAnswer((_) async => null);

    final groupIdentify = Identify()
      ..set(property: testProperty, value: testValue);
    await amplitude.groupIdentify(
        groupType: testGroupType,
        groupName: testGroupName,
        identify: groupIdentify,
        options: EventOptions(userId: testUserId));

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["event_type"] = Constants.group_identify_event;
    testIdentifyMap["user_id"] = testUserId;
    testIdentifyMap["groups"] = {testGroupType: testGroupName};
    testIdentifyMap["group_properties"] = {
      "\$set": {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod(
            "groupIdentify", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should setGroup calls MethodChannel", () async {
    when(mockChannel.invokeMethod("track", any)).thenAnswer((_) async => null);

    await amplitude.setGroup(
        groupType: testGroupType, groupName: testGroupName);

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["event_type"] = Constants.identify_event;
    testIdentifyMap["groups"] = {testGroupType: testGroupName};
    testIdentifyMap["user_properties"] = {
      "\$set": {testGroupType: testGroupName}
    };

    verify(mockChannel.invokeMethod("setGroup", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test("Should setGroup with event options calls MethodChannel", () async {
    when(mockChannel.invokeMethod("track", any)).thenAnswer((_) async => null);

    await amplitude.setGroup(
        groupType: testGroupType,
        groupName: testGroupName,
        options: EventOptions(userId: testUserId));

    final testIdentifyMap = new Map.from(testEventMap);
    testIdentifyMap["event_type"] = Constants.identify_event;
    testIdentifyMap["groups"] = {testGroupType: testGroupName};
    testIdentifyMap["user_properties"] = {
      "\$set": {testGroupType: testGroupName}
    };
    testIdentifyMap["user_id"] = testUserId;

    verify(mockChannel.invokeMethod("setGroup", jsonEncode(testIdentifyMap)))
        .called(1);
  });

  test('Should revenue calls MethodChannel', () async {
    when(mockChannel.invokeMethod('revenue', any))
        .thenAnswer((_) async => null);

    final revenue = Revenue()
      ..price = testPrice
      ..quantity = testQuantity
      ..productId = testProductId;
    await amplitude.revenue(revenue: revenue);
    
    final testRevenueMap = new Map.from(testEventMap);
    testRevenueMap["event_type"] = Constants.revenue_event;
    testRevenueMap["event_properties"] = {};
    testRevenueMap["event_properties"][RevenueConstants.revenuePrice] = testPrice;
    testRevenueMap["event_properties"][RevenueConstants.revenueQuantity] = testQuantity;
    testRevenueMap["event_properties"][RevenueConstants.revenueProductId] = testProductId;

    verify(mockChannel.invokeMethod('revenue', jsonEncode(testRevenueMap))).called(1);
  });

  test('Should revenue calls MethodChannel with event options', () async {
    when(mockChannel.invokeMethod('revenue', any))
        .thenAnswer((_) async => null);

    final revenue = Revenue()
      ..price = testPrice
      ..quantity = testQuantity
      ..productId = testProductId;
    await amplitude.revenue(revenue: revenue, options: EventOptions(userId: testUserId));

    final testRevenueMap = new Map.from(testEventMap);
    testRevenueMap["user_id"] = testUserId;
    testRevenueMap["event_type"] = Constants.revenue_event;
    testRevenueMap["event_properties"] = {};
    testRevenueMap["event_properties"][RevenueConstants.revenuePrice] = testPrice;
    testRevenueMap["event_properties"][RevenueConstants.revenueQuantity] = testQuantity;
    testRevenueMap["event_properties"][RevenueConstants.revenueProductId] = testProductId;

    verify(mockChannel.invokeMethod('revenue', jsonEncode(testRevenueMap))).called(1);
  });

  test('Should setUserId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('setUserId', any))
        .thenAnswer((_) async => null);

    amplitude.setUserId(testUserId);

    verify(mockChannel.invokeMethod('setUserId', jsonEncode({"setUserId": testUserId}))).called(1);
  });

  test('Should setDeviceId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('setDeviceId', any))
        .thenAnswer((_) async => null);

    amplitude.setDeviceId(testDeviceId);

    verify(mockChannel.invokeMethod('setDeviceId', jsonEncode({"setDeviceId": testDeviceId}))).called(1);
  });

  test('Should setDeviceId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('setDeviceId', any))
        .thenAnswer((_) async => null);

    amplitude.setDeviceId(testDeviceId);

    verify(mockChannel.invokeMethod('setDeviceId', jsonEncode({"setDeviceId": testDeviceId}))).called(1);
  });

  test('Should reset calls MethodChannel', () async {
    when(mockChannel.invokeMethod('reset', any))
        .thenAnswer((_) async => null);

    amplitude.reset();

    verify(mockChannel.invokeMethod('reset')).called(1);
  });

  test('Should flush calls MethodChannel', () async {
    when(mockChannel.invokeMethod('flush', any))
        .thenAnswer((_) async => null);

    amplitude.flush();

    verify(mockChannel.invokeMethod('flush')).called(1);
  });

  // Reset the mock method call handler after each test
  tearDown(() {
    clearInteractions(mockChannel);
  });
}
