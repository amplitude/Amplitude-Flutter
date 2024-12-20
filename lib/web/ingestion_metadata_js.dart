import 'dart:js_interop';

@JSExport()
extension type IngestionMetadata(JSObject _) implements JSObject {
  external JSString? sourceName;
  external JSString? sourceVersion;
}
