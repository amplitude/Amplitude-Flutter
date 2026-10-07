import 'dart:js_interop';
import 'dart:js_interop_unsafe';

var libraryJSKey = 'library'.toJS;

@JSExport()
class FlutterLibraryPlugin {
  String library = 'amplitude-flutter/unknown';
  String name = 'FlutterLibraryPlugin';
  final void Function(JSObject config)? onSetup;

  void setup(JSAny? config, JSAny? client) {
    if (config != null && config is JSObject) {
      onSetup?.call(config);
    }
  }

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

  FlutterLibraryPlugin(this.library, {this.onSetup});
}
