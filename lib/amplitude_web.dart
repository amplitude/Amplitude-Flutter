import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';
import 'web/flutter_library_plugin.dart';
import 'constants.dart';

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

          // Set library
          amplitude.add(createJSInteropWrapper(
            FlutterLibraryPlugin(args['library'] ?? 'amplitude_flutter/unknown')
          ));
          amplitude.init(apiKey, configuration);
        }
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
      {
        JSObject event = getEvent(call);
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
      case "setOptOut":
      {
        bool enabled = call.arguments['setOptOut'];
        amplitude.setOptOut(enabled);
      }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  /// Converts a Dart Map to a JavaScript object using `js_interop_unsafe`.
  ///
  /// This method takes a Dart Map and recursively converts it into a JavaScript
  /// object. Each key-value pair in the Dart Map is set as a property on the
  /// JavaScript object. If a value in the Dart Map is another Map, this method
  /// will recursively convert that Map as well.
  ///
  /// - Parameter map: The Dart Map to convert.
  /// - Returns: A JavaScript object with the same properties as the Dart Map.
  JSObject mapToJSObj(Map<dynamic, dynamic> map) {
    var object = JSObject();
    map.forEach((k, v) {
      var key = k;
      var value = (v is Map) ? mapToJSObj(v) : v;
      object[key] = value;
    });
    return object;
  }

  /// Extracts an event from call.arguments and converts it to a JSObject representing an Event object.
  ///
  /// This method extracts event properties from the provided MethodCall argument
  /// and converts them into a JavaScript object representing an Event using the mapToJSObj method.
  ///
  /// Returns:
  /// - `JSObject`: A JavaScript object representing the event.
  JSObject getEvent(MethodCall call) {
    var eventMap = call.arguments;
    return mapToJSObj(eventMap);
  }


  /// Maps the configuration settings for the Amplitude SDK to a JavaScript object.
  ///
  /// For more details on configuring the SDK, refer to the official documentation:
  /// https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  ///
  /// Returns a map containing the configuration settings.
  JSObject getConfiguration(MethodCall call) {
    var configuration = call.arguments;
    if (configuration['autocapture'] is Map) {
      // formInteractions, fileDownloads, elementInteractions are not supported in flutter web
      configuration['autocapture']['formInteractions'] = false;
      configuration['autocapture']['fileDownloads'] = false;
      configuration['autocapture']['elementInteractions'] = false;
    }
    JSObject configurationJS = mapToJSObj(configuration);

    // defaultTracking is not supported in flutter web
    if (call.arguments.containsKey('defaultTracking')) {
      configurationJS.delete('defaultTracking'.toJS);
    }

    if (call.arguments.containsKey('logLevel')) {
      var logLevelString = call.arguments['logLevel'] as String;
      configurationJS['logLevel'] = LogLevel.values.byName(logLevelString).index.toJS;
    }

    if (call.arguments.containsKey('serverZone')) {
      var serverZoneString = call.arguments['serverZone'] as String;
      serverZoneString.toUpperCase();
      configurationJS['serverZone'] = serverZoneString.toUpperCase().toJS;
    }

    return configurationJS;
  }
}
