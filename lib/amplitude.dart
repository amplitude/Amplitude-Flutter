import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

abstract class _Amplitude {
  final MethodChannel _channel = const MethodChannel('amplitude_flutter');
}

class Amplitude extends _Amplitude {
  static Map<String, Amplitude> _instances;

  String _instanceName;

  static Amplitude getInstance({String instanceName = '\$default_instance'}) {
    if (_instances == null) {
      _instances = <String, Amplitude>{};
    }

    return _instances.putIfAbsent(instanceName, () => new Amplitude(instanceName));
  }

  Amplitude(String instanceName) {
    this._instanceName = instanceName;
  }

  Future<void> init(String apiKey, {String userId}) async {
    Map<String, dynamic> properties = <String, dynamic>{
      'instanceName':_instanceName,
      'apiKey': apiKey,
      'userId': userId
    };

    return await _channel.invokeMethod('init', jsonEncode(properties));
  }

  Future<void> logEvent(String eventType) async {
    Map<String, dynamic> properties = <String, dynamic>{
      'instanceName':_instanceName,
      'eventType': eventType
    };

    return await _channel.invokeMethod('logEvent', jsonEncode(properties));
  }

  Future<void> flushEvents() async {

  }
}
