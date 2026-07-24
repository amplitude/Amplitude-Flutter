import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';
import 'web/configuration_transform.dart';
import 'web/flutter_library_plugin.dart';
import 'constants.dart';

@JS()
external Amplitude get amplitude;

class AmplitudeFlutterPlugin {
  Map<String, Amplitude> instances = {};

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
    if (call.method == 'init') {
      var args = call.arguments;
      String apiKey = args['apiKey'];
      JSObject configuration = getConfiguration(call);

      // Set library
      Amplitude instance = amplitude.createInstance();
      instance.add(createJSInteropWrapper(FlutterLibraryPlugin(
          args['library'] ?? 'amplitude_flutter/unknown')));
      instance.init(apiKey, configuration);

      instances[args['instanceName'] ?? Constants.defaultInstanceName] =
          instance;

      return null;
    }

    Amplitude? instance = instances[
        call.arguments['instanceName'] ?? Constants.defaultInstanceName];

    if (instance == null) {
      throw Exception(
          'instance not found: ${call.arguments['instanceName'] ?? Constants.defaultInstanceName}');
    }

    switch (call.method) {
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
        {
          JSObject event = getEvent(call);
          instance.track(event);
        }
      case "getUserId":
        {
          JSString? userId = instance.getUserId();
          if (userId == null) {
            return null;
          }
          return userId.toDart;
        }
      case "setUserId":
        {
          Map args = call.arguments['properties'];
          String? userId = args['setUserId'];
          instance.setUserId(userId?.toJS);
        }
      case "getDeviceId":
        {
          return instance.getDeviceId()?.toDart;
        }
      case "setDeviceId":
        {
          Map args = call.arguments['properties'];
          String? deviceId = args['setDeviceId'];
          instance.setDeviceId(deviceId?.toJS);
        }
      case "getSessionId":
        {
          return instance.getSessionId()?.toDartInt;
        }
      case "reset":
        {
          instance.reset();
        }
      case "flush":
        {
          instance.flush();
        }
      case "setOptOut":
        {
          Map args = call.arguments['properties'];
          bool enabled = args['setOptOut'];
          instance.setOptOut(enabled.toJS);
        }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  /// Extracts an event from call.arguments and converts it to a JSObject representing an Event object.
  ///
  /// This method extracts event properties from the provided MethodCall argument
  /// and converts them into a JavaScript object representing an Event using the mapToJSObj method.
  ///
  /// Returns:
  /// - `JSObject`: A JavaScript object representing the event.
  JSObject getEvent(MethodCall call) {
    var eventMap = call.arguments['event'] as Map;
    return eventMap.jsify() as JSObject;
  }

  /// Maps the configuration settings for the Amplitude SDK to a JavaScript object.
  ///
  /// For more details on configuring the SDK, refer to the official documentation:
  /// https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  ///
  /// The pure-Dart shaping (autocapture, logLevel, serverZone, defaultTracking)
  /// lives in [transformWebConfiguration] so it can be unit tested without the
  /// `chrome` platform; this method only handles the `jsify()` conversion.
  ///
  /// Returns a JavaScript object containing the configuration settings.
  JSObject getConfiguration(MethodCall call) {
    final configuration = Map<String, dynamic>.from(call.arguments as Map);
    return transformWebConfiguration(configuration).jsify() as JSObject;
  }
}
