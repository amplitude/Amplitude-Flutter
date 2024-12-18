import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';
// import 'configuration.dart'

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
          // JSObject configuration = getConfiguration(call);
          // JSObject configuration = mapToJSObj(call.arguments);
          Configuration configuration = Configuration(JSObject());
          configuration.autocapture = false.toJS;
          // configuration.autocapture = false;

          // amplitude.init(apiKey, configuration);
        }
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
      {
        // TODO: 2024-12-16 chungdanile make getEvent method
        JSObject event = mapToJSObj(call.arguments);
        amplitude.track(event);
        // amplitude.logger.debug("Track ")
      }
      case "setUserId":
      {
        String userId = call.arguments['setUserId'];
        amplitude.setUserId(userId);
      }
      case "setDeviceId":
      {
        String deviceId = call.arguments['setDeviceId'];
        amplitude.setDevideId(deviceId);
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

  // TODO: 2024-12-05 chungdaniel use safer/static js_interop if possible
  // https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  JSObject getConfiguration(MethodCall call) {
    JSObject configuration = JSObject();
    var arguments = call.arguments;
    if (arguments.containsKey('instanceName')) {
      configuration.setProperty('instanceName'.toJS, arguments['instanceName']);
    }
    if (arguments.containsKey('flushIntervalMillis')) {
      configuration.setProperty('flushIntervalMillis'.toJS, arguments['flushIntervalMillis']);
    }
    if (arguments.containsKey('flushQueueSize')) {
      configuration.setProperty('flushQueueSize'.toJS, arguments['flushQueueSize']);
    }
    if (arguments.containsKey('flushMaxRetries')) {
      configuration.setProperty('flushMaxRetries'.toJS, arguments['flushMaxRetries']);
    }
    if (arguments.containsKey('logLevel')) {
      configuration.setProperty('logLevel'.toJS, arguments['logLevel']);
    }
    if (arguments.containsKey('loggerProvider')) {
      configuration.setProperty('loggerProvider'.toJS, arguments['loggerProvider']);
    }
    if (arguments.containsKey('minIdLength')) {
      configuration.setProperty('minIdLength'.toJS, arguments['minIdLength']);
    }
    if (arguments.containsKey('optOut')) {
      configuration.setProperty('optOut'.toJS, arguments['optOut']);
    }
    if (arguments.containsKey('serverUrl')) {
      configuration.setProperty('serverUrl'.toJS, arguments['serverUrl']);
    }
    if (arguments.containsKey('serverZone')) {
      configuration.setProperty('serverZone'.toJS, arguments['serverZone']);
    }
    if (arguments.containsKey('useBatch')) {
      configuration.setProperty('useBatch'.toJS, arguments['useBatch']);
    }
    if (arguments.containsKey('appVersion')) {
      configuration.setProperty('appVersion'.toJS, arguments['appVersion']);
    }
    // TODO: chungdaniel 20241216 look into this to see if I should bake this into configuration
    // vaguely remember hearing that it shouldn't be?
    // if (arguments.containsKey('autocapture')) {
      // configuration.setProperty('autocapture'.toJS, arguments['autocapture']);
    // }
    configuration.setProperty('autocapture'.toJS, false.toJS);
    if (arguments.containsKey('defaultTracking')) {
      configuration.setProperty('defaultTracking'.toJS, arguments['defaultTracking']);
    }
    if (arguments.containsKey('deviceId')) {
      configuration.setProperty('deviceId'.toJS, arguments['deviceId']);
    }
    if (arguments.containsKey('cookieOptions.domain')) {
      configuration.setProperty('cookieOptions.domain'.toJS, arguments['cookieOptions.domain']);
    }
    if (arguments.containsKey('cookieOptions.expiration')) {
      configuration.setProperty('cookieOptions.expiration'.toJS, arguments['cookieOptions.expiration']);
    }
    if (arguments.containsKey('cookieOptions.sameSite')) {
      configuration.setProperty('cookieOptions.sameSite'.toJS, arguments['cookieOptions.sameSite']);
    }
    if (arguments.containsKey('cookieOptions.secure')) {
      configuration.setProperty('cookieOptions.secure'.toJS, arguments['cookieOptions.secure']);
    }
    if (arguments.containsKey('cookieOptions.upgrade')) {
      configuration.setProperty('cookieOptions.upgrade'.toJS, arguments['cookieOptions.upgrade']);
    }
    if (arguments.containsKey('identityStorage')) {
      configuration.setProperty('identityStorage'.toJS, arguments['identityStorage']);
    }
    if (arguments.containsKey('partnerId')) {
      configuration.setProperty('partnerId'.toJS, arguments['partnerId']);
    }
    if (arguments.containsKey('sessionTimeout')) {
      configuration.setProperty('sessionTimeout'.toJS, arguments['sessionTimeout']);
    }
    if (arguments.containsKey('storageProvider')) {
      configuration.setProperty('storageProvider'.toJS, arguments['storageProvider']);
    }
    if (arguments.containsKey('userId')) {
      configuration.setProperty('userId'.toJS, arguments['userId']);
    }
    if (arguments.containsKey('trackingOptions')) {
      configuration.setProperty('trackingOptions'.toJS, arguments['trackingOptions']);
    }
    if (arguments.containsKey('transport')) {
      configuration.setProperty('transport'.toJS, arguments['transport']);
    }
    if (arguments.containsKey('offline')) {
      configuration.setProperty('offline'.toJS, arguments['offline']);
    }
    if (arguments.containsKey('fetchRemoteConfig')) {
      configuration.setProperty('fetchRemoteConfig'.toJS, arguments['fetchRemoteConfig']);
    }
    return configuration;
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
