@JS('amplitude')

import 'dart:js_interop';


extension type Configuration(JSObject _) implements JSObject {
  // String apiKey;
  external set flushQueueSize(int flushQueueSize);

  // int flushIntervalMillis;
  // late String instanceName;
  // bool optOut;
  // LogLevel logLevel;
  // int? minIdLength;
  // String? partnerId;
  // int flushMaxRetries;
  // bool useBatch;
  // ServerZone serverZone;
  // String? serverUrl;
  // int minTimeBetweenSessionsMillis;
  // DefaultTrackingOptions defaultTracking;
  // TrackingOptions trackingOptions;
  /// Web specific
  external set appVersion(String appVersion);
}

extension type Amplitude(JSObject _) implements JSObject {
  external void init(String apiKey, JSObject? configuration);
  external void track(JSObject event);
}

// @JS('@amplitude/analytics-types')

// @JS('amplitude.options')
// class Options {
//   external set eventUploadPeriodMillis(int value);
// }

// @JS('amplitude')
// class Amplitude {
//   external Amplitude(String instanceName);
//   external static Amplitude getInstance(String instanceName);
//   external void init(String api, Configuration? configuration);
//   external void setOptOut(bool optOut);
//   external void setUserId(String? userId, bool startNewSession);
//   external void setDeviceId(String deviceId);
//   external void setServerUrl(String serverUrl);
//   external void setEventUploadThreshold(int);
//   external void regenerateDeviceId();
//   external void setUseDynamicConfig(bool useDynamicConfig);
//   external void setGroup(String groupType, dynamic groupName);
//   external void setUserProperties(Object userProperties);
//   external void clearUserProperties();
//   external void sendEvents();
//   external void setLibrary(String? libraryName, String? libraryVersion);
//   external String getUserId();
//   external String getDeviceId();
//   external void getSessionId();
//   external void setMinTimeBetweenSessionsMillis(int timeInMillis);
//   external void setServerZone(String serverZone, bool updateServerUrl);
//   external void identify(Identify identify);
//   external void groupIdentify(
//       String groupType,
//       String groupName,
//       Identify groupIdentify,
//       // ignore: non_constant_identifier_names
//       Function? opt_callback,
//       // ignore: non_constant_identifier_names
//       Function? opt_error_callback,
//       bool? outOfSession);
//   external bool setOffline(bool enabled);
//   external Options options;
// }

// @JS('amplitude.Identify')
// class Identify {
//   external Identify();
//   external void add(String key, dynamic value);
//   external void append(String key, dynamic value);
//   external void prepend(String key, dynamic value);
//   external void set(String key, dynamic value);
//   external void setOnce(String key, dynamic value);
//   external void unset(String key);
//   external void preInsert(String key, dynamic value);
//   external void postInsert(String key, dynamic value);
//   external void remove(String key, dynamic value);
//   external void clearAll();
// }
