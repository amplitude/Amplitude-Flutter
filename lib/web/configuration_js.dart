import 'dart:js_interop';

@JSExport()
extension type TrackingOptions(JSObject _) implements JSObject {
  external final JSBoolean ipAddress;
  external final JSBoolean language;
  external final JSBoolean platform;
}

extension type Configuration(JSObject _) implements JSObject {
  external JSBoolean autocapture;
  external JSNumber flushQueueSize;
  external JSNumber flushIntervalMillis;
  external JSString instanceName;
  external JSBoolean optOut;
  external JSString logLevel;
  external JSNumber minIdLength;
  external JSString? partnerId;
  external JSNumber flushMaxRetries;
  external JSBoolean useBatch;
  external JSString serverZone;
  external JSString serverUrl;
  external TrackingOptions trackingOptions;
  external JSString? appVersion;
}
