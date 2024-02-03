import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/tracking_options.dart';
import 'package:amplitude_flutter/default_tracking.dart';

void main() {
  group('Configuration', () {
    test('defaults should be set correctly', () {
      var config = Configuration(apiKey: 'test_api_key');

      expect(config.apiKey, 'test_api_key');
      expect(config.flushQueueSize, Constants.flushQueueSize);
      expect(config.flushIntervalMillis, Constants.flushIntervalMillis);
      expect(config.instanceName, Constants.defaultInstanceName);
      expect(config.optOut, false);
      expect(config.logLevel, LogLevel.warn);
      expect(config.minIdLength, isNull);
      expect(config.partnerId, isNull);
      expect(config.flushMaxRetries, Constants.flushMaxRetries);
      expect(config.useBatch, false);
      expect(config.serverZone, ServerZone.US);
      expect(config.serverUrl, isNull);
      expect(config.minTimeBetweenSessionsMillis, Constants.minTimeBetweenSessionsMillis);
      expect(config.defaultTracking, isA<DefaultTrackingOptions>());
      expect(config.trackingOptions, isA<TrackingOptions>());
      expect(config.mobileConfiguration, isA<MobileConfiguration>());
      expect(config.androidConfiguration, isA<AndroidConfiguration>());
      expect(config.webConfiguration, isA<WebConfiguration>());

      var map = config.toMap();
      expect(map['apiKey'], 'test_api_key');
      expect(map['flushQueueSize'], Constants.flushQueueSize);
      expect(map['flushIntervalMillis'], Constants.flushIntervalMillis);
      expect(map['instanceName'], Constants.defaultInstanceName);
      expect(map['optOut'], false);
      expect(map['logLevel'], LogLevel.warn.toString());
      expect(map['minIdLength'], isNull);
      expect(map['partnerId'], isNull);
      expect(map['flushMaxRetries'], Constants.flushMaxRetries);
      expect(map['useBatch'], false);
      expect(map['serverZone'], ServerZone.US.toString());
      expect(map['serverUrl'], isNull);
      expect(map['minTimeBetweenSessionsMillis'], Constants.minTimeBetweenSessionsMillis);
      expect(map.containsKey('defaultTracking'), true);
      expect(map.containsKey('trackingOptions'), true);
    });

    test('custom values should be set correctly', () {
      var customConfig = Configuration(
        apiKey: 'custom_api_key',
        flushQueueSize: 10,
        flushIntervalMillis: 1000,
        instanceName: 'custom_instance',
        optOut: true,
        logLevel: LogLevel.debug,
        minIdLength: 15,
        partnerId: 'partner_123',
        flushMaxRetries: 5,
        useBatch: true,
        serverZone: ServerZone.EU,
        serverUrl: 'https://custom.server.url',
        minTimeBetweenSessionsMillis: 2000,
      );

      expect(customConfig.apiKey, 'custom_api_key');
      expect(customConfig.flushQueueSize, 10);
      expect(customConfig.flushIntervalMillis, 1000);
      expect(customConfig.instanceName, 'custom_instance');
      expect(customConfig.optOut, true);
      expect(customConfig.logLevel, LogLevel.debug);
      expect(customConfig.partnerId, 'partner_123');
      expect(customConfig.flushMaxRetries, 5);
      expect(customConfig.useBatch, true);
      expect(customConfig.serverZone, ServerZone.EU);
      expect(customConfig.serverUrl, 'https://custom.server.url');
      expect(customConfig.minTimeBetweenSessionsMillis, 2000);
    });
  });
}
