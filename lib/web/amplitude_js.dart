import 'dart:js_interop';
import 'flutter_library_plugin.dart';
import 'configuration_js.dart';
import 'event_js.dart';

@JS('amplitude')
extension type Amplitude(JSObject _) implements JSObject {
  external JSPromise init(String apiKey, Configuration? configuration);
  // TODO: chungdaniel 20241219 investigate why plugins are not triggering
  external void add(JSObject plugin);
  external void track(Event event);
  external void setUserId(JSString userId);
  external void setDeviceId(JSString devideId);
  external void reset();
  external void flush();
}
