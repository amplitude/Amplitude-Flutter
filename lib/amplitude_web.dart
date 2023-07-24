import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart' as js;

import 'web/amplitude_js.dart';

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
    var args = jsonDecode(call.arguments.toString());
    var instanceName = args['instanceName'];
    Amplitude amplitude = Amplitude.getInstance(instanceName);
    switch (call.method) {
      case "init":
        {
          String apiKey = args['apiKey'];
          var userId = args['userId'] ?? null;
          return amplitude.init(apiKey, userId);
        }
      case "enableCoppaControl":
        {
          return false;
        }
      case "disableCoppaControl":
        {
          return false;
        }
      case "setOptOut":
        {
          bool optOut = args['optOut'];
          return amplitude.setOptOut(optOut);
        }
      case "trackingSessionEvents":
        {
          return false;
        }
      case "setUserId":
        {
          String? userId = args['userId'] ?? null;
          bool startNewSession = args['startNewSession'] ?? false;
          return amplitude.setUserId(userId, startNewSession);
        }
      case "setDeviceId":
        {
          String deviceId = args['deviceId'];
          return amplitude.setDeviceId(deviceId);
        }
      case "setServerUrl":
        {
          String serverUrl = args['serverUrl'];
          return amplitude.setServerUrl(serverUrl);
        }
      case "setEventUploadThreshold":
        {
          int eventUploadThreshold = args['eventUploadThreshold'];
          return amplitude.setEventUploadThreshold(eventUploadThreshold);
        }
      case "setEventUploadPeriodMillis":
        {
          int eventUploadPeriodMillis = args['eventUploadPeriodMillis'];
          return amplitude.options.eventUploadPeriodMillis = eventUploadPeriodMillis;
        }
      case "regenerateDeviceId":
        {
          return amplitude.regenerateDeviceId();
        }
      case "setUseDynamicConfig":
        {
          bool useDynamicConfig = args['useDynamicConfig'];
          return amplitude.setUseDynamicConfig(useDynamicConfig);
        }
      case "logEvent":
        {
          String eventType = args['eventType'];
          var eventProperties = (args['eventProperties'] != null)
              ? mapToJSObj(args['eventProperties'])
              : null;
          bool outOfSession = args['outOfSession'] ?? false;
          return amplitude.logEvent(
              eventType, eventProperties, null, null, outOfSession);
        }
      case "logRevenue":
        {
          double price = args['price'] ?? 0;
          int quantity = args['quantity'] ?? 1;
          var productIdentifier = args['productIdentifier'] ?? null;
          return amplitude.logRevenue(price, quantity, productIdentifier);
        }
      case "logRevenueAmount":
        {
          double amount = args['amount'] ?? 0;
          return amplitude.logRevenue(amount, 1, null);
        }
      case "identify":
        {
          var userProperties = args['userProperties'];
          Identify identify = createIdentify(userProperties);
          return amplitude.identify(identify);
        }
      case "setGroup":
        {
          String groupType = args['groupType'];
          dynamic groupName = args['groupName'];
          return amplitude.setGroup(groupType, groupName);
        }
      case "groupIdentify":
        {
          String groupType = args['groupType'];
          dynamic groupName = args['groupName'];
          var userProperties = args['userProperties'];
          Identify groupIdentify = createIdentify(userProperties);
          bool outOfSession = args['outOfSession'] ?? false;
          return amplitude.groupIdentify(
              groupType, groupName, groupIdentify, null, null, outOfSession);
        }
      case "setUserProperties":
        {
          var userProperties = mapToJSObj(args['userProperties']);
          return amplitude.setUserProperties(userProperties);
        }
      case "clearUserProperties":
        {
          return amplitude.clearUserProperties();
        }
      case "uploadEvents":
        {
          return amplitude.sendEvents();
        }
      case "setLibraryName":
        {
          String libraryName = args['libraryName'];
          return amplitude.setLibrary(libraryName, null);
        }
      case "setLibraryVersion":
        {
          String libraryVersion = args['libraryVersion'];
          return amplitude.setLibrary(null, libraryVersion);
        }
      case "getDeviceId":
        {
          return amplitude.getDeviceId();
        }
      case "getUserId":
        {
          return amplitude.getUserId();
        }
      case "getSessionId":
        {
          return amplitude.getSessionId();
        }
      case "useAppSetIdForDeviceId":
        {
          return false;
        }
      case "setMinTimeBetweenSessionsMillis":
        {
          int timeInMillis = args['timeInMillis'];
          return amplitude.setMinTimeBetweenSessionsMillis(timeInMillis);
        }
      case "setServerZone":
        {
          String serverZone = args['serverZone'];
          bool updateServerUrl = args['updateServerUrl'];
          return amplitude.setServerZone(serverZone, updateServerUrl);
        }
      case "setOffline":
        {
          return false;
        }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  Object mapToJSObj(Map<dynamic, dynamic> map) {
    var object = js.newObject();
    map.forEach((k, v) {
      var key = k;
      var value = (v is Map) ? mapToJSObj(v) : v;
      js.setProperty(object, key, value);
    });
    return object;
  }

  Identify createIdentify(Map<String, dynamic> userProperties) {
    Identify identify = new Identify();
    userProperties.forEach((String operation, dynamic properties) {
      properties.forEach((String key, dynamic value) {
        switch (operation) {
          case "\$add":
            {
              identify.add(key, value);
              break;
            }

          case "\$append":
            {
              identify.append(key, value);
              break;
            }
          case "\$prepend":
            {
              identify.prepend(key, value);
              break;
            }
          case "\$set":
            {
              identify.set(key, value);
              break;
            }
          case "\$setOnce":
            {
              identify.setOnce(key, value);
              break;
            }
          case "\$unset":
            {
              identify.unset(key);
              break;
            }
          case "\$preInsert":
            {
              identify.preInsert(key, value);
              break;
            }
          case "\$postInsert":
            {
              identify.postInsert(key, value);
              break;
            }
          case "\$remove":
            {
              identify.remove(key, value);
              break;
            }
          case "\$clearAll":
            {
              identify.clearAll();
              break;
            }
          default:
            break;
        }
      });
    });
    return identify;
  }
}
