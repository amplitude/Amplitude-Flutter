@JS()

import 'package:js/js.dart';

@JS('amplitude')
class Amplitude {
  external Amplitude(String instanceName);
  external static Amplitude getInstance(String instanceName);
  external void init(String api, String? userId);
  external void logEvent(
      String eventType, Map<String, dynamic>? eventProperties);
  //TODO: support outOfSession
}
