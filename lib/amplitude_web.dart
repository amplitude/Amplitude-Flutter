@JS()

import 'package:js/js.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:async';

//import 'package:js/js.dart';
@JS('amplitude')
class Amplitude {
  external Amplitude(String instanceName);
  external static Amplitude getInstance(String instanceName);
  external void init(String api, String? userId, Object? option);
  external void logEvent(String eventType);
  //external void jump(Function(int height) func);
}

class AmplitudeFlutterPlugin {
  static void registerWith(Registrar registrar) {
    print("in amplitude_web.dart");
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
    print(call.method);
    print(call.arguments.toString());
    var args = jsonDecode(call.arguments.toString());
    var instanceName = args['instanceName'];
    Amplitude amplitude = Amplitude.getInstance(instanceName);

    switch (call.method) {
      // Init
      case "init":
        {
          print("in init");
          var apiKey = args['apiKey'];
          amplitude.init(apiKey, null, {});
          return true;
        }
      case "logEvent":
        {
          print('in logEvent');
          var eventType = args['eventType'];
          amplitude.logEvent(eventType);
          return true;
        }
      // Get userId
      case "getUserId":
      // Get deviceId
      case "getDeviceId":
      // Get sessionId
      case "getSessionId":
      // Setters
      case "enableCoppaControl":
      case "disableCoppaControl":
      case "setOptOut":
      case "setLibraryName":
      case "setLibraryVersion":
      case "setEventUploadThreshold":
      case "trackingSessionEvents":
      case "setUseDynamicConfig":
      default:
      //result(FlutterMethodNotImplemented)
    }
  }
}

// ignore: public_member_api_docs
/*void registerPlugins(Registrar registrar) {
  AmplitudeFlutterPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}

class AmplitudeFlutterPlugin {
  static void registerWith(Registrar registrar) {}
}
*/
