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
  final testApiKey = 'test-api-key';
  final testUserId = 'test user id';
  final testDeviceId = 'test device id';
  final testProperty = 'property';
  final testValue = 'value';
  final testGroupType = 'group type';
  final testGroupName = 'group name';
  final testConfiguration = Configuration(apiKey: testApiKey);
  final testConfigurationMap = {
    'apiKey': testApiKey,
    'flushQueueSize': 30,
    'flushIntervalMillis': 30000,
    'instanceName': Constants.defaultInstanceName,
    'optOut': false,
    'logLevel': LogLevel.warn.name,
    'minIdLength': null,
    'partnerId': null,
    'flushMaxRetries': 5,
    'useBatch': false,
    'serverZone': ServerZone.us.name,
    'serverUrl': null,
    'minTimeBetweenSessionsMillis': 5 * 60 * 1000,
    'defaultTracking': {
      'sessions': true,
      'appLifecycles': false,
      'deepLinks': false,
      'attribution': true,
      'pageViews': true,
      'formInteractions': true,
      'fileDownloads': true,
    },
    'trackingOptions': {
      'ipAddress': true,
      'language': true,
      'platform': true,
      'region': true,
      'dma': true,
      'country': true,
      'city': true,
      'carrier': true,
      'deviceModel': true,
      'deviceManufacturer': true,
      'osVersion': true,
      'osName': true,
      'versionName': true,
      'adid': true,
      'appSetId': true,
      'deviceBrand': true,
      'latLag': true,
      'apiLevel': true,
      'idfv': true,
    },
    'enableCoppaControl': false,
    'flushEventsOnClose': true,
    'identifyBatchIntervalMillis': 30 * 1000,
    'migrateLegacyData': true,
    'locationListening': true,
    'useAdvertisingIdForDeviceId': false,
    'useAppSetIdForDeviceId': false,
    'appVersion': null,
    'deviceId': null,
    'cookieOptions': {
      'domain': '',
      'expiration': 365,
      'sameSite': 'Lax',
      'secure': false,
      'upgrade': true,
    },
    'identityStorage': 'cookie',
    'sessionTimeout': 30 * 60 * 1000,
    'userId': null,
    'transport': 'fetch',
    'fetchRemoteConfig': false,
    'autocapture': {
      'sessions': true,
      'attribution': {
        'initialEmptyValue': 'EMPTY',
        'resetSessionOnNewCampaign': false
      },
      'pageViews': {
        'trackHistoryChanges': 'all',
        'eventType': ''
      }
    },
    // This field doesn't belong to Configuration
    // Pass it for FlutterLibraryPlugin
    'library': '${Constants.packageName}/${Constants.packageVersion}'
  };
  final testEvent = BaseEvent('testEvent');
  final testEventMap = {
    'event_type': 'testEvent',
    'attempts': 0,
  };
  final testPrice = 3.99;
  final testQuantity = 3;
  final testProductId = 'com.company.productId';

  setUp(() async {
    mockChannel = MockMethodChannel();
    when(mockChannel.invokeListMethod('init', any))
        .thenAnswer((_) async => null);
    amplitude = Amplitude(testConfiguration, mockChannel);
    await amplitude.isBuilt;
  });

  test('Should init and track call MethodChannel', () async {
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);
    await amplitude.track(testEvent);

    verify(mockChannel.invokeMethod('init', testConfigurationMap)).called(1);
    verify(mockChannel.invokeMethod('track', testEventMap)).called(1);
  });

  test('Should track with event options calls MethodChannel', () async {
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);
    await amplitude.track(testEvent, EventOptions(userId: testUserId));

    final expectedEventMap = Map.from(testEventMap);
    expectedEventMap['user_id'] = testUserId;
    verify(mockChannel.invokeMethod('track', expectedEventMap)).called(1);
  });

  test('Should identify calls MethodChannel', () async {
    when(mockChannel.invokeMethod('identify', any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(testProperty, testValue);
    await amplitude.identify(identify);

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['event_type'] = Constants.identifyEvent;
    testIdentifyMap['user_properties'] = {
      '\$set': {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod('identify', testIdentifyMap)).called(1);
  });

  test('Should identify calls setUserId in MethodChannel', () async {
    when(mockChannel.invokeMethod('identify', any))
        .thenAnswer((_) async => null);
    when(mockChannel.invokeMethod('setUserId', any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(testProperty, testValue);
    await amplitude.identify(identify, EventOptions(userId: testUserId));

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['user_id'] = testUserId;
    testIdentifyMap['event_type'] = Constants.identifyEvent;
    testIdentifyMap['user_properties'] = {
      '\$set': {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod('setUserId', {'setUserId': testUserId}))
        .called(1);
    verify(mockChannel.invokeMethod('identify', testIdentifyMap)).called(1);
  });

  test('Should identify calls setDeviceId in MethodChannel', () async {
    when(mockChannel.invokeMethod('identify', any))
        .thenAnswer((_) async => null);
    when(mockChannel.invokeMethod('setDeviceId', any))
        .thenAnswer((_) async => null);

    final identify = Identify()..set(testProperty, testValue);
    await amplitude.identify(identify, EventOptions(deviceId: testDeviceId));

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['device_id'] = testDeviceId;
    testIdentifyMap['event_type'] = Constants.identifyEvent;
    testIdentifyMap['user_properties'] = {
      '\$set': {testProperty: testValue}
    };
    verify(mockChannel
        .invokeMethod('setDeviceId', {'setDeviceId': testDeviceId})).called(1);
    verify(mockChannel.invokeMethod('identify', testIdentifyMap)).called(1);
  });

  test('Should groupIdentify calls MethodChannel', () async {
    when(mockChannel.invokeMethod('groupIdentify', any))
        .thenAnswer((_) async => null);

    final groupIdentify = Identify()..set(testProperty, testValue);
    await amplitude.groupIdentify(testGroupType, testGroupName, groupIdentify);

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['event_type'] = Constants.groupIdentifyEvent;
    testIdentifyMap['groups'] = {testGroupType: testGroupName};
    testIdentifyMap['group_properties'] = {
      '\$set': {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod('groupIdentify', testIdentifyMap))
        .called(1);
  });

  test('Should groupIdentify with event options calls MethodChannel', () async {
    when(mockChannel.invokeMethod('groupIdentify', any))
        .thenAnswer((_) async => null);

    final groupIdentify = Identify()..set(testProperty, testValue);
    await amplitude.groupIdentify(testGroupType, testGroupName, groupIdentify,
        EventOptions(userId: testUserId));

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['event_type'] = Constants.groupIdentifyEvent;
    testIdentifyMap['user_id'] = testUserId;
    testIdentifyMap['groups'] = {testGroupType: testGroupName};
    testIdentifyMap['group_properties'] = {
      '\$set': {testProperty: testValue}
    };
    verify(mockChannel.invokeMethod('groupIdentify', (testIdentifyMap)))
        .called(1);
  });

  test('Should setGroup calls MethodChannel', () async {
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);

    await amplitude.setGroup(testGroupType, testGroupName);

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['event_type'] = Constants.identifyEvent;
    testIdentifyMap['groups'] = {testGroupType: testGroupName};
    testIdentifyMap['user_properties'] = {
      '\$set': {testGroupType: testGroupName}
    };

    verify(mockChannel.invokeMethod('setGroup', testIdentifyMap)).called(1);
  });

  test('Should setGroup with event options calls MethodChannel', () async {
    when(mockChannel.invokeMethod('track', any)).thenAnswer((_) async => null);

    await amplitude.setGroup(
        testGroupType, testGroupName, EventOptions(userId: testUserId));

    final testIdentifyMap = Map.from(testEventMap);
    testIdentifyMap['event_type'] = Constants.identifyEvent;
    testIdentifyMap['groups'] = {testGroupType: testGroupName};
    testIdentifyMap['user_properties'] = {
      '\$set': {testGroupType: testGroupName}
    };
    testIdentifyMap['user_id'] = testUserId;

    verify(mockChannel.invokeMethod('setGroup', testIdentifyMap)).called(1);
  });

  test('Should revenue calls MethodChannel', () async {
    when(mockChannel.invokeMethod('revenue', any))
        .thenAnswer((_) async => null);

    final revenue = Revenue()
      ..price = testPrice
      ..quantity = testQuantity
      ..productId = testProductId;
    await amplitude.revenue(revenue);

    final testRevenueMap = Map.from(testEventMap);
    testRevenueMap['event_type'] = Constants.revenueEvent;
    testRevenueMap['event_properties'] = {};
    testRevenueMap['event_properties'][RevenueConstants.revenuePrice] =
        testPrice;
    testRevenueMap['event_properties'][RevenueConstants.revenueQuantity] =
        testQuantity;
    testRevenueMap['event_properties'][RevenueConstants.revenueProductId] =
        testProductId;

    verify(mockChannel.invokeMethod('revenue', testRevenueMap)).called(1);
  });

  test('Should revenue calls MethodChannel with event options', () async {
    when(mockChannel.invokeMethod('revenue', any))
        .thenAnswer((_) async => null);

    final revenue = Revenue()
      ..price = testPrice
      ..quantity = testQuantity
      ..productId = testProductId;
    await amplitude.revenue(revenue, EventOptions(userId: testUserId));

    final testRevenueMap = Map.from(testEventMap);
    testRevenueMap['user_id'] = testUserId;
    testRevenueMap['event_type'] = Constants.revenueEvent;
    testRevenueMap['event_properties'] = {};
    testRevenueMap['event_properties'][RevenueConstants.revenuePrice] =
        testPrice;
    testRevenueMap['event_properties'][RevenueConstants.revenueQuantity] =
        testQuantity;
    testRevenueMap['event_properties'][RevenueConstants.revenueProductId] =
        testProductId;

    verify(mockChannel.invokeMethod('revenue', testRevenueMap)).called(1);
  });

  test('Should getUserId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('getUserId')).thenAnswer((_) async => testUserId);

    final userId = await amplitude.getUserId();

    expect(userId, testUserId);
    verify(mockChannel.invokeMethod('getUserId')).called(1);
  });

  test('Should setUserId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('setUserId', any))
        .thenAnswer((_) async => null);

    amplitude.setUserId(testUserId);

    verify(mockChannel.invokeMethod('setUserId', {'setUserId': testUserId}))
        .called(1);
  });

  test('Should getDeviceId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('getDeviceId')).thenAnswer((_) async => testDeviceId);

    final deviceId = await amplitude.getDeviceId();

    expect(deviceId, testDeviceId);
    verify(mockChannel.invokeMethod('getDeviceId')).called(1);
  });

  test('Should setDeviceId calls MethodChannel', () async {
    when(mockChannel.invokeMethod('setDeviceId', any))
        .thenAnswer((_) async => null);

    amplitude.setDeviceId(testDeviceId);

    verify(mockChannel
        .invokeMethod('setDeviceId', {'setDeviceId': testDeviceId})).called(1);
  });

  test('Should reset calls MethodChannel', () async {
    when(mockChannel.invokeMethod('reset', any)).thenAnswer((_) async => null);

    amplitude.reset();

    verify(mockChannel.invokeMethod('reset')).called(1);
  });

  test('Should flush calls MethodChannel', () async {
    when(mockChannel.invokeMethod('flush', any)).thenAnswer((_) async => null);

    amplitude.flush();

    verify(mockChannel.invokeMethod('flush')).called(1);
  });

  // Reset the mock method call handler after each test
  tearDown(() {
    clearInteractions(mockChannel);
  });
}
