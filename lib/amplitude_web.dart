@JS('amplitude')
library amplitude;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as util;

class AmplitudeWeb {
  final _Amplitude _amplitude = getInstance();

  void init(
    String apiKey, {
    String? optUserId,
    Map<String, dynamic>? optConfig,
    Function? optCallback,
  }) =>
      _amplitude.init(
        apiKey,
        optUserId,
        _mapToJsObject(optConfig),
        optCallback,
      );

  void logEvent(
    String name, {
    Map<String, String>? params,
    Function? optCallback,
  }) =>
      _amplitude.logEvent(
        name,
        _mapToJsObject(params),
        optCallback,
      );

  void setOptOut(bool enable) => _amplitude.setOptOut(enable);

  void setUserProperties(Map<String, String> properties) =>
      _amplitude.setUserProperties(_mapToJsObject(properties));
}

external _Amplitude getInstance();

@JS('Amplitude')
class _Amplitude {
  external void init(String apiKey, String? optUserId, Object? optConfig,
      Function? optCallback);

  external void logEvent(String name, Object? params, Function? optCallback);

  external void setOptOut(bool enable);

  external void setUserProperties(Object properties);
}

dynamic _mapToJsObject(Object? dartObject) {
  if (_isPrimitive(dartObject)) {
    return dartObject;
  }
  if (dartObject is Map) {
    final jsMap = util.newObject();
    dartObject.forEach((key, value) {
      util.setProperty(jsMap, key, _mapToJsObject(value));
    });
    return jsMap;
  }
  throw Exception('Unknpown type of object: $dartObject');
}

bool _isPrimitive(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return true;
  }
  return false;
}
