import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'my_app.dart';

void main() {
  // On Flutter web with the default CanvasKit renderer, the Amplitude Browser
  // SDK's DOM-based autocapture (formInteractions / fileDownloads) can only
  // observe Flutter's accessibility semantics tree. That tree is off until
  // something enables it, so enable it here to demonstrate web form capture.
  // Enabling semantics app-wide has a runtime cost and known side effects, so
  // only do this if you actually want DOM-based web capture. Element
  // interactions do not need it: the AmplitudeElementTapDetector wrapping the
  // app captures widget taps on every platform with semantics off.
  if (kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const MyApp('API_KEY'));
}
