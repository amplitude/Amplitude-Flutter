import 'dart:js_interop';
import 'event_js.dart';

extension type Plugin(JSObject _) implements JSObject {
  @JS()
  external set execute(JSFunction value);
}

@JS()
external set exportedExecute(JSFunction value);

void printString(JSString string) {
  print(string.toDart);
}

void main() {
  exportedExecute = printString.toJS;
}

@JSExport()
class FlutterLibraryPlugin {
  String library = 'amplitude-flutter/unknown';
  String name = 'FlutterLibraryPlugin';

  Event execute(Event event) {
    print('is this ever being hit?');
    if (event.library == null) {
      event.library = library.toJS;
    } else {
      event.library = '${library}_${event.library}'.toJS;
    }
    return event;
  }
  FlutterLibraryPlugin(this.library);
}
