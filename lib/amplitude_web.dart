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
          String apiKey = args['apiKey'];
          JSObject configuration = getConfiguration(call);

          return amplitude.init(apiKey, configuration);;
        }
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
      {
        JSObject event = getEvent(call);
        amplitude.track(event);
        // amplitude.logger.debug("Track ")
        return;
      }
      case "setUserId":
      {
        String userId = call.arguments[setUserId];
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

  // TODO: 2024-12-05 chungdaniel use safer/static js_interop if possible
  // https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  JSObject getConfiguration(MethodCall call) {
    JSObject configuration = JSObject();
    final LinkedHashMap<String, dynamic> arguments = call.arguments;
    if (arguments.containsKey('instanceName')) {
      configuration.setProperty('instanceName', arguments['instanceName']);
    }
    if (arguments.containsKey('flushIntervalMillis')) {
      configuration.setProperty('flushIntervalMillis', arguments['flushIntervalMillis']);
    }
    if (arguments.containsKey('flushQueueSize')) {
      configuration.setProperty('flushQueueSize', arguments['flushQueueSize']);
    }
    if (arguments.containsKey('flushMaxRetries')) {
      configuration.setProperty('flushMaxRetries', arguments['flushMaxRetries']);
    }
    if (arguments.containsKey('logLevel')) {
      configuration.setProperty('logLevel', arguments['logLevel']);
    }
    if (arguments.containsKey('loggerProvider')) {
      configuration.setProperty('loggerProvider', arguments['loggerProvider']);
    }
    if (arguments.containsKey('minIdLength')) {
      configuration.setProperty('minIdLength', arguments['minIdLength']);
    }
    if (arguments.containsKey('optOut')) {
      configuration.setProperty('optOut', arguments['optOut']);
    }
    if (arguments.containsKey('serverUrl')) {
      configuration.setProperty('serverUrl', arguments['serverUrl']);
    }
    if (arguments.containsKey('serverZone')) {
      configuration.setProperty('serverZone', arguments['serverZone']);
    }
    if (arguments.containsKey('useBatch')) {
      configuration.setProperty('useBatch', arguments['useBatch']);
    }
    if (arguments.containsKey('appVersion')) {
      configuration.setProperty('appVersion', arguments['appVersion']);
    }
    if (arguments.containsKey('autocapture')) {
      configuration.setProperty('autocapture', arguments['autocapture']);
    }
    if (arguments.containsKey('defaultTracking')) {
      configuration.setProperty('defaultTracking', arguments['defaultTracking']);
    }
    if (arguments.containsKey('deviceId')) {
      configuration.setProperty('deviceId', arguments['deviceId']);
    }
    if (arguments.containsKey('cookieOptions.domain')) {
      configuration.setProperty('cookieOptions.domain', arguments['cookieOptions.domain']);
    }
    if (arguments.containsKey('cookieOptions.expiration')) {
      configuration.setProperty('cookieOptions.expiration', arguments['cookieOptions.expiration']);
    }
    if (arguments.containsKey('cookieOptions.sameSite')) {
      configuration.setProperty('cookieOptions.sameSite', arguments['cookieOptions.sameSite']);
    }
    if (arguments.containsKey('cookieOptions.secure')) {
      configuration.setProperty('cookieOptions.secure', arguments['cookieOptions.secure']);
    }
    if (arguments.containsKey('cookieOptions.upgrade')) {
      configuration.setProperty('cookieOptions.upgrade', arguments['cookieOptions.upgrade']);
    }
    if (arguments.containsKey('identityStorage')) {
      configuration.setProperty('identityStorage', arguments['identityStorage']);
    }
    if (arguments.containsKey('partnerId')) {
      configuration.setProperty('partnerId', arguments['partnerId']);
    }
    if (arguments.containsKey('sessionTimeout')) {
      configuration.setProperty('sessionTimeout', arguments['sessionTimeout']);
    }
    if (arguments.containsKey('storageProvider')) {
      configuration.setProperty('storageProvider', arguments['storageProvider']);
    }
    if (arguments.containsKey('userId')) {
      configuration.setProperty('userId', arguments['userId']);
    }
    if (arguments.containsKey('trackingOptions')) {
      configuration.setProperty('trackingOptions', arguments['trackingOptions']);
    }
    if (arguments.containsKey('transport')) {
      configuration.setProperty('transport', arguments['transport']);
    }
    if (arguments.containsKey('offline')) {
      configuration.setProperty('offline', arguments['offline']);
    }
    if (arguments.containsKey('fetchRemoteConfig')) {
      configuration.setProperty('fetchRemoteConfig', arguments['fetchRemoteConfig']);
    }
    return configuration;
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
