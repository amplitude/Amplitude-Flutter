// This file exercises both the new `autocapture` API and the deprecated
// `defaultTracking` API to verify the backward-compatibility bridge in
// Configuration._resolveAutocapture.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:amplitude_flutter/autocapture/attribution.dart';
import 'package:amplitude_flutter/autocapture/autocapture.dart';
import 'package:amplitude_flutter/autocapture/page_views.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/tracking_options.dart';
import 'package:amplitude_flutter/default_tracking.dart';
import 'package:amplitude_flutter/cookie_options.dart';

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
      expect(config.serverZone, ServerZone.us);
      expect(config.serverUrl, isNull);
      expect(config.minTimeBetweenSessionsMillis,
          Constants.minTimeBetweenSessionsMillisUnset);
      expect(config.trackingOptions, isA<TrackingOptions>());
      expect(config.defaultTracking, isA<DefaultTrackingOptions>());
      expect(config.enableCoppaControl, false);
      expect(config.flushEventsOnClose, true);
      expect(config.identifyBatchIntervalMillis,
          Constants.identifyBatchIntervalMillis);
      expect(config.migrateLegacyData, true);
      expect(config.deviceId, isNull);
      expect(config.locationListening, true);
      expect(config.useAdvertisingIdForDeviceId, false);
      expect(config.useAppSetIdForDeviceId, false);
      expect(config.appVersion, isNull);
      expect(config.cookieOptions, isA<CookieOptions>());
      expect(config.identityStorage, 'cookie');
      expect(config.userId, isNull);
      expect(config.transport, 'fetch');
      expect(config.fetchRemoteConfig, false);
      expect(config.autocapture, isA<AutocaptureOptions>());

      var map = config.toMap();
      expect(map['apiKey'], 'test_api_key');
      expect(map['flushQueueSize'], Constants.flushQueueSize);
      expect(map['flushIntervalMillis'], Constants.flushIntervalMillis);
      expect(map['instanceName'], Constants.defaultInstanceName);
      expect(map['optOut'], false);
      expect(map['logLevel'], 'warn');
      expect(map['minIdLength'], isNull);
      expect(map['partnerId'], isNull);
      expect(map['flushMaxRetries'], Constants.flushMaxRetries);
      expect(map['useBatch'], false);
      expect(map['serverZone'], 'us');
      expect(map['serverUrl'], isNull);
      expect(map['minTimeBetweenSessionsMillis'],
          Constants.minTimeBetweenSessionsMillisForMobile);
      expect(
          map['sessionTimeout'], Constants.minTimeBetweenSessionsMillisForWeb);
      expect(map.containsKey('trackingOptions'), true);
      expect(map.containsKey('defaultTracking'), true);
      expect(map['enableCoppaControl'], false);
      expect(map['flushEventsOnClose'], true);
      expect(map['identifyBatchIntervalMillis'],
          Constants.identifyBatchIntervalMillis);
      expect(map['migrateLegacyData'], true);
      expect(map['deviceId'], isNull);
      expect(map['locationListening'], true);
      expect(map['useAdvertisingIdForDeviceId'], false);
      expect(map['useAppSetIdForDeviceId'], false);
      expect(map['appVersion'], isNull);
      expect(map.containsKey('cookieOptions'), true);
      expect(map['identityStorage'], 'cookie');
      expect(map['userId'], isNull);
      expect(map['transport'], 'fetch');
      expect(map['fetchRemoteConfig'], false);
      expect(map.containsKey('autocapture'), true);
    });

    test('serializes autocapture mobile options', () {
      final config = Configuration(
        apiKey: 'test_api_key',
        autocapture: const AutocaptureOptions(
          appLifecycles: true,
          deepLinks: true,
        ),
      );

      final autocapture = config.toMap()['autocapture'] as Map<String, dynamic>;

      expect(autocapture['sessions'], true);
      expect(autocapture['appLifecycles'], true);
      expect(autocapture['deepLinks'], true);
    });

    group('autocapture derivation from defaultTracking', () {
      test('explicit autocapture wins over defaultTracking', () {
        final config = Configuration(
          apiKey: 'k',
          autocapture: const AutocaptureOptions(appLifecycles: true),
          defaultTracking: const DefaultTrackingOptions(appLifecycles: false),
        );

        final ac = config.autocapture as AutocaptureOptions;
        expect(ac.appLifecycles, true);

        final serialized = config.toMap()['autocapture'] as Map<String, dynamic>;
        expect(serialized['appLifecycles'], true);
      });

      test('autocapture derived from defaultTracking when not passed (mobile fields)', () {
        final config = Configuration(
          apiKey: 'k',
          defaultTracking: const DefaultTrackingOptions(
            appLifecycles: true,
            deepLinks: true,
          ),
        );

        final ac = config.autocapture as AutocaptureOptions;
        expect(ac.sessions, true,
            reason: 'DefaultTrackingOptions.sessions default is true');
        expect(ac.appLifecycles, true);
        expect(ac.deepLinks, true);

        final serialized = config.toMap()['autocapture'] as Map<String, dynamic>;
        expect(serialized['appLifecycles'], true);
        expect(serialized['deepLinks'], true);
      });

      test('autocapture derived from defaultTracking when not passed (web fields)', () {
        final config = Configuration(
          apiKey: 'k',
          defaultTracking: const DefaultTrackingOptions(
            attribution: false,
            pageViews: false,
          ),
        );

        final ac = config.autocapture as AutocaptureOptions;
        expect(Attribution.toMapOrBool(ac.attribution), false,
            reason: 'attribution=false on DTO should disable on derived AutocaptureOptions');
        expect(PageViews.toMapOrBool(ac.pageViews), false,
            reason: 'pageViews=false on DTO should disable on derived AutocaptureOptions');
      });

      test('autocapture derived from defaultTracking honors formInteractions/fileDownloads', () {
        final config = Configuration(
          apiKey: 'k',
          defaultTracking: const DefaultTrackingOptions(
            formInteractions: false,
            fileDownloads: false,
          ),
        );

        final ac = config.autocapture as AutocaptureOptions;
        expect(ac.formInteractions, false);
        expect(ac.fileDownloads, false);

        final serialized = config.toMap()['autocapture'] as Map<String, dynamic>;
        expect(serialized['formInteractions'], false);
        expect(serialized['fileDownloads'], false);
      });

      test('defaults: no autocapture, no defaultTracking → minimal autocapture', () {
        final config = Configuration(apiKey: 'k');

        final ac = config.autocapture as AutocaptureOptions;
        expect(ac.sessions, true);
        expect(ac.appLifecycles, false);
        expect(ac.deepLinks, false);
        expect(ac.attribution, isA<AttributionOptions>());
        expect(ac.pageViews, isA<PageViewsOptions>());
      });

      test('AutocaptureDisabled is preserved (not overridden by defaultTracking)', () {
        final config = Configuration(
          apiKey: 'k',
          autocapture: const AutocaptureDisabled(),
          defaultTracking: const DefaultTrackingOptions(appLifecycles: true),
        );

        expect(config.autocapture, isA<AutocaptureDisabled>());
      });

      test('AutocaptureEnabled is preserved (not overridden by defaultTracking)', () {
        final config = Configuration(
          apiKey: 'k',
          autocapture: const AutocaptureEnabled(),
          defaultTracking: const DefaultTrackingOptions(appLifecycles: false),
        );

        expect(config.autocapture, isA<AutocaptureEnabled>());
      });
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
        serverZone: ServerZone.eu,
        serverUrl: 'https://custom.server.url',
        minTimeBetweenSessionsMillis: 2000,
        trackingOptions: TrackingOptions(language: false),
        defaultTracking: DefaultTrackingOptions(sessions: false),
        enableCoppaControl: true,
        flushEventsOnClose: true,
        identifyBatchIntervalMillis: 2000,
        migrateLegacyData: true,
        deviceId: 'custom_device_id',
        locationListening: true,
        useAdvertisingIdForDeviceId: true,
        useAppSetIdForDeviceId: true,
        appVersion: '1.0.0',
        cookieOptions: CookieOptions(domain: 'custom.domain.com'),
        identityStorage: 'localStorage',
        userId: 'custom_user_id',
        transport: 'xhr',
        fetchRemoteConfig: true,
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
      expect(customConfig.serverZone, ServerZone.eu);
      expect(customConfig.serverUrl, 'https://custom.server.url');
      expect(customConfig.minTimeBetweenSessionsMillis, 2000);
      expect(customConfig.trackingOptions.language, false);
      expect(customConfig.defaultTracking.sessions, false);
      expect(customConfig.enableCoppaControl, true);
      expect(customConfig.flushEventsOnClose, true);
      expect(customConfig.identifyBatchIntervalMillis, 2000);
      expect(customConfig.migrateLegacyData, true);
      expect(customConfig.deviceId, 'custom_device_id');
      expect(customConfig.locationListening, true);
      expect(customConfig.useAdvertisingIdForDeviceId, true);
      expect(customConfig.useAppSetIdForDeviceId, true);
      expect(customConfig.appVersion, '1.0.0');
      expect(customConfig.cookieOptions.domain, 'custom.domain.com');
      expect(customConfig.identityStorage, 'localStorage');
      expect(customConfig.userId, 'custom_user_id');
      expect(customConfig.transport, 'xhr');
      expect(customConfig.fetchRemoteConfig, true);
    });
  });
}
