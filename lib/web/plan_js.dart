import 'dart:js_interop';

@JSExport()
extension type Plan(JSObject _) implements JSObject {
  external JSString? branch;
  external JSString? source;
  external JSString? version;
  external JSString? versionId;
}
