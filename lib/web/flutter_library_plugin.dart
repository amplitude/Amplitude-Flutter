import 'dart:js_interop';
import 'dart:js_interop_unsafe';

var libraryJSKey = 'library'.toJS;

@JSExport()
class FlutterLibraryPlugin {
  String library = 'amplitude-flutter/unknown';
  String name = 'FlutterLibraryPlugin';

  JSObject execute(JSObject event) {
    event.hasProperty('library'.toJS);
    if (!event.hasProperty(libraryJSKey).toDart) {
      event.setProperty(libraryJSKey, library.toJS);
    } else {
      event.setProperty(
          libraryJSKey, '${library}_${event.getProperty(libraryJSKey)}'.toJS);
    }
    return event;
  }

  FlutterLibraryPlugin(this.library);
}
