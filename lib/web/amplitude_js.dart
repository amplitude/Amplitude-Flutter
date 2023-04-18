@JS()

import 'package:js/js.dart';

@JS('amplitude.options')
class Options {
  external set eventUploadPeriodMillis(int value);
}

@JS('amplitude')
class Amplitude {
  external Amplitude(String instanceName);
  external static Amplitude getInstance(String instanceName);
  external void init(String api, String? userId);
  external void setOptOut(bool optOut);
  external void setUserId(String? userId, bool startNewSession);
  external void setDeviceId(String deviceId);
  external void setServerUrl(String serverUrl);
  external void setEventUploadThreshold(int);
  external void regenerateDeviceId();
  external void setUseDynamicConfig(bool useDynamicConfig);
  external void logEvent(String eventType, Object? eventProperties,
      Function? optCallback, Function? optErrorCallback, bool? outOfSession);
  external void logRevenue(
      double price, int quantity, String? productIdentifier);
  external void setGroup(String groupType, dynamic groupName);
  external void setUserProperties(Object userProperties);
  external void clearUserProperties();
  external void sendEvents();
  external void setLibrary(String? libraryName, String? libraryVersion);
  external String getUserId();
  external String getDeviceId();
  external void getSessionId();
  external void setMinTimeBetweenSessionsMillis(int timeInMillis);
  external void setServerZone(String serverZone, bool updateServerUrl);
  external void identify(Identify identify);
  external void groupIdentify(
      String groupType,
      String groupName,
      Identify groupIdentify,
      Function? opt_callback,
      Function? opt_error_callback,
      bool? outOfSession);
  external bool setOffline(bool enabled);
  external Options options;
}

@JS('amplitude.Identify')
class Identify {
  external Identify();
  external void add(String key, dynamic value);
  external void append(String key, dynamic value);
  external void prepend(String key, dynamic value);
  external void set(String key, dynamic value);
  external void setOnce(String key, dynamic value);
  external void unset(String key);
  external void preInsert(String key, dynamic value);
  external void postInsert(String key, dynamic value);
  external void remove(String key, dynamic value);
  external void clearAll();
}
