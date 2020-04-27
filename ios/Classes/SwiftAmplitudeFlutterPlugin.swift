import Flutter
import UIKit
import Amplitude

@objc public class SwiftAmplitudeFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "amplitude_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftAmplitudeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func getPropertiesFromArguments(_ callArguments: Any?) throws -> [String:Any]? {
      if let arguments = callArguments, let data = (arguments as! String).data(using: .utf8) {

        let properties = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
        return properties;
      }
      return nil;
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)  {
        do {
            if let args = try getPropertiesFromArguments(call.arguments) {
                let instanceName = args["instanceName"] as! String
            
                switch (call.method) {
                case "init":
                    let apiKey = args["apiKey"] as! String
                    
                    if (apiKey.isEmpty) {
                        result(FlutterError.init(code: "EMPTY_APP_KEY",
                                                 message: "Please initialize the Amplitude with a valid API Key.", details: nil))
                        return
                    }
                    
                    let userId = args["userId"] is NSNull ? nil : (args["userId"] as! String)
                    Amplitude.instance(withName: instanceName)?.initializeApiKey(apiKey, userId: userId)
                    result(true)
                case "logEvent":
                    let eventType = args["eventType"] as! String
                    Amplitude.instance(withName: instanceName)?.logEvent(eventType)
                    result(true)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        } catch {
            result(FlutterError.init(code: "EXCEPTION_IN_HANDLE",
            message: "Exception happened in handle.", details: nil))
        }
    }
}
