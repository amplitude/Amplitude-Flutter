@JS()

import 'package:js/js.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:async';

@JS('amplitude')
class Amplitude {
  external Amplitude(String instanceName);
  external static Amplitude getInstance(String instanceName);
  external void init(String api, String? userId, Object? option);
  external void logEvent(String eventType);
}

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
      // Init
      case "init":
        {
          var apiKey = args['apiKey'];
          amplitude.init(apiKey, null, {});
          return true;
        }
      case "logEvent":
        {
          var eventType = args['eventType'];
          amplitude.logEvent(eventType);
          return true;
        }
      default:
      //(FlutterMethodNotImplemented)
    }
  }
}
