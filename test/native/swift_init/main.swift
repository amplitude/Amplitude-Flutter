import Foundation
import FlutterMacOS
import AmplitudeSwift

var failureCount = 0

func checkInvalidInit(_ name: String, arguments: Any?) {
    let plugin = SwiftAmplitudeFlutterPlugin()
    var replies: [Any?] = []
    plugin.handle(FlutterMethodCall(methodName: "init", arguments: arguments)) { replies.append($0) }

    let errors = replies.compactMap { $0 as? FlutterError }
    let passed = replies.count == 1
        && errors.count == 1
        && errors.first?.code == "amplitude_init_failed"
        && plugin.instances.isEmpty
    if !passed {
        failureCount += 1
    }
    print("\(passed ? "PASS" : "FAIL") \(name): replies=\(replies.count), errors=\(errors.count), codes=\(errors.map { $0.code }), instances=\(plugin.instances.count)")
}

checkInvalidInit("malformed argument map", arguments: "not a map")
checkInvalidInit("nil arguments", arguments: nil)
checkInvalidInit("missing API key", arguments: ["instanceName": "readiness-missing-key"])
checkInvalidInit("non-string API key", arguments: ["apiKey": 123, "instanceName": "readiness-non-string-key"])

exit(failureCount == 0 ? 0 : 1)
