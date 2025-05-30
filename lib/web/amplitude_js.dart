import 'dart:js_interop';

@JS('amplitude')
extension type Amplitude(JSObject _) implements JSObject {
  external Amplitude createInstance();
  external JSPromise init(String apiKey, JSObject? configuration);
  external void add(JSObject plugin);
  external void track(JSObject event);
  external JSString? getUserId();
  external void setUserId(JSString? userId);
  external JSString? getDeviceId();
  external void setDeviceId(JSString? devideId);
  external JSNumber? getSessionId();
  external void setOptOut(JSBoolean enabled);
  external void reset();
  external void flush();
}
