#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

@objc public class AmplitudeFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftAmplitudeFlutterPlugin.register(with: registrar)
    }
}
