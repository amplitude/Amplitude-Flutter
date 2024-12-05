import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';

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
          var args = call.arguments;
          var instanceName = args['instanceName'];
          // Configuration configuration = getConfiguration(call);
          JSObject configuration = mapToJSObj(call.arguments);

          amplitude.init(args['apiKey'], configuration);
          // String apiKey = args['apiKey'];
          // var userId = args['userId'] ?? null;
          // return amplitude.init(apiKey, userId);
          return;
        }
      case "track":
      {
        JSObject event = getEvent(call);
        amplitude.track(event);
        // amplitude.logger.debug("Track ")
        return;
      }
      // case "enableCoppaControl":
      //   {
      //     return false;
      //   }
      // case "disableCoppaControl":
      //   {
      //     return false;
      //   }
      // case "setOptOut":
      //   {
      //     bool optOut = args['optOut'];
      //     return amplitude.setOptOut(optOut);
      //   }
      // case "trackingSessionEvents":
      //   {
      //     return false;
      //   }
      // case "setUserId":
      //   {
      //     String? userId = args['userId'] ?? null;
      //     bool startNewSession = args['startNewSession'] ?? false;
      //     return amplitude.setUserId(userId, startNewSession);
      //   }
      // case "setDeviceId":
      //   {
      //     String deviceId = args['deviceId'];
      //     return amplitude.setDeviceId(deviceId);
      //   }
      // case "setServerUrl":
      //   {
      //     String serverUrl = args['serverUrl'];
      //     return amplitude.setServerUrl(serverUrl);
      //   }
      // case "setEventUploadThreshold":
      //   {
      //     int eventUploadThreshold = args['eventUploadThreshold'];
      //     return amplitude.setEventUploadThreshold(eventUploadThreshold);
      //   }
      // case "setEventUploadPeriodMillis":
      //   {
      //     int eventUploadPeriodMillis = args['eventUploadPeriodMillis'];
      //     return amplitude.options.eventUploadPeriodMillis = eventUploadPeriodMillis;
      //   }
      // case "regenerateDeviceId":
      //   {
      //     return amplitude.regenerateDeviceId();
      //   }
      // case "setUseDynamicConfig":
      //   {
      //     bool useDynamicConfig = args['useDynamicConfig'];
      //     return amplitude.setUseDynamicConfig(useDynamicConfig);
      //   }
      // case "identify":
      //   {
      //     var userProperties = args['userProperties'];
      //     Identify identify = createIdentify(userProperties);
      //     return amplitude.identify(identify);
      //   }
      // case "setGroup":
      //   {
      //     String groupType = args['groupType'];
      //     dynamic groupName = args['groupName'];
      //     return amplitude.setGroup(groupType, groupName);
      //   }
      // case "groupIdentify":
      //   {
      //     String groupType = args['groupType'];
      //     dynamic groupName = args['groupName'];
      //     var userProperties = args['userProperties'];
      //     Identify groupIdentify = createIdentify(userProperties);
      //     bool outOfSession = args['outOfSession'] ?? false;
      //     return amplitude.groupIdentify(
      //         groupType, groupName, groupIdentify, null, null, outOfSession);
      //   }
      // case "clearUserProperties":
      //   {
      //     return amplitude.clearUserProperties();
      //   }
      // case "uploadEvents":
      //   {
      //     return amplitude.sendEvents();
      //   }
      // case "setLibraryName":
      //   {
      //     String libraryName = args['libraryName'];
      //     return amplitude.setLibrary(libraryName, null);
      //   }
      // case "setLibraryVersion":
      //   {
      //     String libraryVersion = args['libraryVersion'];
      //     return amplitude.setLibrary(null, libraryVersion);
      //   }
      // case "getDeviceId":
      //   {
      //     return amplitude.getDeviceId();
      //   }
      // case "getUserId":
      //   {
      //     return amplitude.getUserId();
      //   }
      // case "getSessionId":
      //   {
      //     return amplitude.getSessionId();
      //   }
      // case "useAppSetIdForDeviceId":
      //   {
      //     return false;
      //   }
      // case "setMinTimeBetweenSessionsMillis":
      //   {
      //     int timeInMillis = args['timeInMillis'];
      //     return amplitude.setMinTimeBetweenSessionsMillis(timeInMillis);
      //   }
      // case "setServerZone":
      //   {
      //     String serverZone = args['serverZone'];
      //     bool updateServerUrl = args['updateServerUrl'];
      //     return amplitude.setServerZone(serverZone, updateServerUrl);
      //   }
      // case "setOffline":
      //   {
      //     return false;
      //   }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  JSObject getEvent(MethodCall call) {
    // TODO: chungdaniel 2024-12-04 use types, actually extract event args properly
    JSObject event = mapToJSObj(call.arguments);
    return event;
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

  // Configuration getConfiguration(MethodCall call) {
  //   Configuration configuration = new Configuration();
  //   final LinkedHashMap<String, dynamic> arguments = call.arguments;
  //   if (arguments.containsKey('flushQueueSize')) {
  //     configuration.flushQueueSize = arguments['flushQueueSize'];
  //   }

  //   return configuration;
  // }

//   Identify createIdentify(Map<String, dynamic> userProperties) {
//     Identify identify = new Identify();
//     userProperties.forEach((String operation, dynamic properties) {
//       properties.forEach((String key, dynamic value) {
//         switch (operation) {
//           case "\$add":
//             {
//               identify.add(key, value);
//               break;
//             }

//           case "\$append":
//             {
//               identify.append(key, value);
//               break;
//             }
//           case "\$prepend":
//             {
//               identify.prepend(key, value);
//               break;
//             }
//           case "\$set":
//             {
//               identify.set(key, value);
//               break;
//             }
//           case "\$setOnce":
//             {
//               identify.setOnce(key, value);
//               break;
//             }
//           case "\$unset":
//             {
//               identify.unset(key);
//               break;
//             }
//           case "\$preInsert":
//             {
//               identify.preInsert(key, value);
//               break;
//             }
//           case "\$postInsert":
//             {
//               identify.postInsert(key, value);
//               break;
//             }
//           case "\$remove":
//             {
//               identify.remove(key, value);
//               break;
//             }
//           case "\$clearAll":
//             {
//               identify.clearAll();
//               break;
//             }
//           default:
//             break;
//         }
//       });
//     });
//     return identify;
//   }
}
