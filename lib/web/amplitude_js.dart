@JS()

import 'package:js/js.dart';

@JS('amplitude')
class Amplitude {
  external Amplitude(String instanceName);
  external static Amplitude getInstance(String instanceName);
  external void init(String api, String? userId);
  external void setOptOut(bool optOut);
  external void setUserId(String? userId);
  //TODO: support startNewSession
  external void regenerateDeviceId();
  external void logEvent(String eventType, Object? eventProperties);
  //TODO: support outOfSession
  external void logRevenue(
      double price, int quantity, String? productIdentifier);
  external void setGroup(String groupType, dynamic groupName);
  external void setUserProperties(Map<String, dynamic> userProperties);
  external void clearUserProperties();
  external void getSessionId();
}
