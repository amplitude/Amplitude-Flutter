import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';
import 'web/flutter_library_plugin.dart';
import 'web/configuration_js.dart';
import 'web/event_js.dart';
import 'web/ingestion_metadata_js.dart';
import 'web/plan_js.dart';

@JS()
external Amplitude get amplitude;
class AmplitudeFlutterPlugin {
  static void registerWith(Registrar registrar) {
    final channel = MethodChannel(
      'amplitude_flutter',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = AmplitudeFlutterPlugin();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "init":
        {
          // TODO: 2024-12-16 chungdaniel add FlutterLibraryPlugin
          // how do I do this? write in JS then interop it over or in dart?
          // potentially look into JSExportedDartFunction?
          var args = call.arguments;
          String apiKey = args['apiKey'];
          Configuration configuration = getConfiguration(call);
          // var wrapped = createJSInteropWrapper(FlutterLibraryPlugin(args['library'] ?? 'amplitude_flutter/unknown'));
          // amplitude.add(wrapped);

          amplitude.init(apiKey, configuration);
        }
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
      {
        // TODO: 2024-12-16 chungdanile make getEvent method
        Event event = getEvent(call);
        amplitude.track(event);
      }
      case "setUserId":
      {
        String userId = call.arguments['setUserId'];
        amplitude.setUserId(userId.toJS);
      }
      case "setDeviceId":
      {
        String deviceId = call.arguments['setDeviceId'];
        amplitude.setDeviceId(deviceId.toJS);
      }
      case "reset":
      {
        amplitude.reset();
      }
      case "flush":
      {
        amplitude.flush();
      }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  JSObject mapToJSObj(Map<dynamic, dynamic> map) {
    var object = JSObject();
    map.forEach((k, v) {
      var key = k;
      var value = (v is Map) ? mapToJSObj(v) : v;
      object.setProperty(key, value);
    });
    return object;
  }


  Event getEvent(MethodCall call) {
    Event event = Event(JSObject());
    var arguments = call.arguments;
    if (arguments.containsKey('event_type')) {
      event.event_type = (arguments['event_type'] as String).toJS;
    }
    if (arguments.containsKey('event_properties')) {
      event.event_properties = mapToJSObj(arguments['event_properties'] as Map);
    }
    if (arguments.containsKey('user_properties')) {
      event.user_properties = mapToJSObj(arguments['user_properties'] as Map);
    }
    if (arguments.containsKey('groups')) {
      event.groups = mapToJSObj(arguments['groups'] as Map);
    }
    if (arguments.containsKey('group_properties')) {
      event.group_properties = mapToJSObj(arguments['group_properties'] as Map);
    }
    if (arguments.containsKey('user_id')) {
      event.user_id = (arguments['user_id'] as String).toJS;
    }
    if (arguments.containsKey('device_id')) {
      event.device_id = (arguments['device_id'] as String).toJS;
    }
    if (arguments.containsKey('timestamp')) {
      event.timestamp = (arguments['timestamp'] as int).toJS;
    }
    if (arguments.containsKey('event_id')) {
      event.event_id = (arguments['event_id'] as int).toJS;
    }
    if (arguments.containsKey('session_id')) {
      event.session_id = (arguments['session_id'] as int).toJS;
    }
    if (arguments.containsKey('insert_id')) {
      event.insert_id = (arguments['insert_id'] as String).toJS;
    }
    if (arguments.containsKey('location_lat')) {
      event.location_lat = (arguments['location_lat'] as double).toJS;
    }
    if (arguments.containsKey('location_lng')) {
      event.location_lng = (arguments['location_lng'] as double).toJS;
    }
    if (arguments.containsKey('app_version')) {
      event.app_version = (arguments['app_version'] as String).toJS;
    }
    if (arguments.containsKey('version_name')) {
      event.version_name = (arguments['version_name'] as String).toJS;
    }
    if (arguments.containsKey('platform')) {
      event.platform = (arguments['platform'] as String).toJS;
    }
    if (arguments.containsKey('os_name')) {
      event.os_name = (arguments['os_name'] as String).toJS;
    }
    if (arguments.containsKey('os_version')) {
      event.os_version = (arguments['os_version'] as String).toJS;
    }
    if (arguments.containsKey('device_brand')) {
      event.device_brand = (arguments['device_brand'] as String).toJS;
    }
    if (arguments.containsKey('device_manufacturer')) {
      event.device_manufacturer = (arguments['device_manufacturer'] as String).toJS;
    }
    if (arguments.containsKey('device_model')) {
      event.device_model = (arguments['device_model'] as String).toJS;
    }
    if (arguments.containsKey('carrier')) {
      event.carrier = (arguments['carrier'] as String).toJS;
    }
    if (arguments.containsKey('country')) {
      event.country = (arguments['country'] as String).toJS;
    }
    if (arguments.containsKey('region')) {
      event.region = (arguments['region'] as String).toJS;
    }
    if (arguments.containsKey('city')) {
      event.city = (arguments['city'] as String).toJS;
    }
    if (arguments.containsKey('dma')) {
      event.dma = (arguments['dma'] as String).toJS;
    }
    if (arguments.containsKey('idfa')) {
      event.idfa = (arguments['idfa'] as String).toJS;
    }
    if (arguments.containsKey('idfv')) {
      event.idfv = (arguments['idfv'] as String).toJS;
    }
    if (arguments.containsKey('adid')) {
      event.adid = (arguments['adid'] as String).toJS;
    }
    if (arguments.containsKey('app_set_id')) {
      event.app_set_id = (arguments['app_set_id'] as String).toJS;
    }
    if (arguments.containsKey('android_id')) {
      event.android_id = (arguments['android_id'] as String).toJS;
    }
    if (arguments.containsKey('language')) {
      event.language = (arguments['language'] as String).toJS;
    }
    if (arguments.containsKey('library')) {
      event.library = (arguments['library'] as String).toJS;
    }
    if (arguments.containsKey('ip')) {
      event.ip = (arguments['ip'] as String).toJS;
    }
    if (arguments.containsKey('plan')) {
      event.plan = arguments['plan'] as Plan;
    }
    if (arguments.containsKey('ingestion_metadata')) {
      event.ingestion_metadata = arguments['ingestion_metadata'] as IngestionMetadata;
    }
    if (arguments.containsKey('revenue')) {
      event.revenue = (arguments['revenue'] as double).toJS;
    }
    if (arguments.containsKey('price')) {
      event.price = (arguments['price'] as double).toJS;
    }
    if (arguments.containsKey('quantity')) {
      event.quantity = (arguments['quantity'] as int).toJS;
    }
    if (arguments.containsKey('product_id')) {
      event.product_id = (arguments['product_id'] as String).toJS;
    }
    if (arguments.containsKey('revenue_type')) {
      event.revenue_type = (arguments['revenue_type'] as String).toJS;
    }
    if (arguments.containsKey('extra')) {
      event.extra = mapToJSObj(arguments['extra'] as Map);
    }
    if (arguments.containsKey('partner_id')) {
      event.partner_id = (arguments['partner_id'] as String).toJS;
    }
    if (arguments.containsKey('attempts')) {
      event.attempts = (arguments['attempts'] as int).toJS;
    }
    return event;
  }


  // TODO: 2024-12-05 chungdaniel use safer/static js_interop if possible
  // https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  Configuration getConfiguration(MethodCall call) {
    Configuration configuration = Configuration(JSObject());
    // autocapture is not supported in flutter web
    configuration.autocapture = false.toJS;
    var arguments = call.arguments;
    if (arguments.containsKey('instanceName')) {
      configuration.instanceName = (arguments['instanceName'] as String).toJS;
    }
    if (arguments.containsKey('flushIntervalMillis')) {
      configuration.flushIntervalMillis = (arguments['flushIntervalMillis'] as int).toJS;
    }
    if (arguments.containsKey('flushQueueSize')) {
      configuration.flushQueueSize = (arguments['flushQueueSize'] as int).toJS;
    }
    if (arguments.containsKey('flushMaxRetries')) {
      configuration.flushMaxRetries = (arguments['flushMaxRetries'] as int).toJS;
    }
    if (arguments.containsKey('logLevel')) {
      configuration.logLevel = (arguments['logLevel'] as String).toJS;
    }
    if (arguments.containsKey('loggerProvider')) {
      // configuration.loggerProvider = arguments['loggerProvider'].toJS;
    }
    if (arguments.containsKey('minIdLength') && arguments['minIdLength'] != null) {
      configuration.minIdLength = (arguments['minIdLength'] as int).toJS;
    }
    if (arguments.containsKey('optOut') && arguments['optOut'] != null) {
      configuration.optOut = (arguments['optOut'] as bool).toJS;
    }
    if (arguments.containsKey('serverUrl') && arguments['serverUrl'] != null) {
      configuration.serverUrl = (arguments['serverUrl'] as String).toJS;
    }
    if (arguments.containsKey('serverZone') && arguments['serverZone'] != null) {
      configuration.serverZone = (arguments['serverZone'] as String).toJS;
    }
    if (arguments.containsKey('useBatch') && arguments['useBatch'] != null) {
      configuration.useBatch = (arguments['useBatch'] as bool).toJS;
    }
    if (arguments.containsKey('appVersion') && arguments['appVersion'] != null) {
      configuration.appVersion = (arguments['appVersion'] as String).toJS;
    }
    if (arguments.containsKey('defaultTracking') && arguments['defaultTracking'] != null) {
      // configuration.defaultTracking = (arguments['defaultTracking'] as bool).toJS;
    }
    if (arguments.containsKey('deviceId') && arguments['deviceId'] != null) {
      // configuration.deviceId = (arguments['deviceId'] as String).toJS;
    }
    if (arguments.containsKey('cookieOptions.domain') && arguments['cookieOptions.domain'] != null) {
      // configuration.cookieOptions.domain = (arguments['cookieOptions.domain'] as String).toJS;
    }
    if (arguments.containsKey('cookieOptions.expiration') && arguments['cookieOptions.expiration'] != null) {
      // configuration.cookieOptions.expiration = (arguments['cookieOptions.expiration'] as int).toJS;
    }
    if (arguments.containsKey('cookieOptions.sameSite') && arguments['cookieOptions.sameSite'] != null) {
      // configuration.cookieOptions.sameSite = (arguments['cookieOptions.sameSite'] as String).toJS;
    }
    if (arguments.containsKey('cookieOptions.secure') && arguments['cookieOptions.secure'] != null) {
      // configuration.cookieOptions.secure = (arguments['cookieOptions.secure'] as bool).toJS;
    }
    if (arguments.containsKey('cookieOptions.upgrade') && arguments['cookieOptions.upgrade'] != null) {
      // configuration.cookieOptions.upgrade = (arguments['cookieOptions.upgrade'] as bool).toJS;
    }
    if (arguments.containsKey('identityStorage') && arguments['identityStorage'] != null) {
      // configuration.identityStorage = (arguments['identityStorage'] as String).toJS;
    }
    if (arguments.containsKey('partnerId') && arguments['partnerId'] != null) {
      configuration.partnerId = (arguments['partnerId'] as String).toJS;
    }
    if (arguments.containsKey('sessionTimeout') && arguments['sessionTimeout'] != null) {
      // configuration.sessionTimeout = (arguments['sessionTimeout'] as int).toJS;
    }
    if (arguments.containsKey('storageProvider') && arguments['storageProvider'] != null) {
      // configuration.storageProvider = (arguments['storageProvider'] as String).toJS;
    }
    if (arguments.containsKey('userId') && arguments['userId'] != null) {
      // configuration.userId = (arguments['userId'] as String).toJS;
    }
    if (arguments.containsKey('trackingOptions') && arguments['trackingOptions'] != null) {
      // configuration.trackingOptions = (arguments['trackingOptions'] as TrackingOptions);
    }
    if (arguments.containsKey('transport') && arguments['transport'] != null) {
      // configuration.transport = (arguments['transport'] as String).toJS;
    }
    if (arguments.containsKey('offline') && arguments['offline'] != null) {
      // configuration.offline = (arguments['offline'] as bool).toJS;
    }
    if (arguments.containsKey('fetchRemoteConfig') && arguments['fetchRemoteConfig'] != null) {
      // configuration.fetchRemoteConfig = (arguments['fetchRemoteConfig'] as bool).toJS;
    }
    return configuration;
  }
}
