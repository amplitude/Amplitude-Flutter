import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart' as js;
import 'web/amplitude_js.dart';
import 'dart:async';

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
      case "setOptOut":
        {
          bool optOut = args['optOut'];
          return amplitude.setOptOut(optOut);
        }
      case "trackingSessionEvents":
      case "setUserId":
        {
          String userId = args['userId'] ?? null;
          return amplitude.setUserId(userId);
          //TODO: support startNewSession
        }
      case "setServerUrl":
      case "setEventUploadThreshold":
      case "regenerateDeviceId":
        {
          return amplitude.regenerateDeviceId();
        }
      case "setUseDynamicConfig":
      case "logEvent":
        {
          String eventType = args['eventType'];
          var eventProperties = (args['eventProperties'] != null)
              ? mapToJSObj(args['eventProperties'])
              : null;
          return amplitude.logEvent(eventType, eventProperties);
          //TODO: support outOfSession
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
      case "setGroup":
        {
          String groupType = args['groupType'];
          String groupName = args['groupName'];
          return amplitude.setGroup(groupType, groupName);
        }
      case "groupIdentify":
      case "setUserProperties":
        {
          Map<String, dynamic> userProperties = new Map();
          if (args['setUserProperties'] != null) {
            userProperties = jsonDecode(args['setUserProperties'].toString())
                as Map<String, dynamic>;
          }
          return amplitude.setUserProperties(userProperties);
        }
      case "clearUserProperties":
        {
          return amplitude.clearUserProperties();
        }
      case "uploadEvents":
      case "setLibraryName":
      case "setLibraryVersion":
      case "getUserId":
      case "getDeviceId":
      case "getSessionId":
        {
          return amplitude.getSessionId();
        }
      case "useAppSetIdForDeviceId":
      case "setMinTimeBetweenSessionsMillis":
      case "setServerZone":
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
      var value = v;
      js.setProperty(object, key, value);
    });
    return object;
  }
}
