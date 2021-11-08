import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
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
          return amplitude.init(apiKey, args['userId'] ?? null);
        }
      case "logEvent":
        {
          String eventType = args['eventType'];
          return amplitude.logEvent(eventType, args['eventProperties'] ?? null);
          //TODO: support outOfSession
        }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }
}
