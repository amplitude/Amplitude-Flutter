import Flutter
import UIKit
import XCTest

import AmplitudeSwift
@testable import amplitude_flutter

class RunnerTests: XCTestCase {

  /// Sends an `init` method call through the plugin and returns the resulting
  /// Amplitude instance created for the given `instanceName`.
  private func initPlugin(arguments: [String: Any], instanceName: String) -> Amplitude? {
    let plugin = SwiftAmplitudeFlutterPlugin()
    let call = FlutterMethodCall(methodName: "init", arguments: arguments)
    plugin.handle(call) { _ in }
    return plugin.instances[instanceName]
  }

  /// A configured `deviceId` (passed from Dart `Configuration.deviceId`) must be
  /// applied to the native Amplitude instance, matching Android semantics.
  func testInitAppliesConfiguredDeviceId() {
    let instanceName = "test_device_id_\(UUID().uuidString)"
    let expectedDeviceId = "configured-device-id-\(UUID().uuidString)"

    let amplitude = initPlugin(
      arguments: [
        "apiKey": "test-api-key",
        "instanceName": instanceName,
        "deviceId": expectedDeviceId,
      ],
      instanceName: instanceName
    )

    XCTAssertNotNil(amplitude, "init should create an Amplitude instance")
    XCTAssertEqual(amplitude?.getDeviceId(), expectedDeviceId)
  }

  /// When no `deviceId` is configured, init still succeeds and the SDK falls back
  /// to its own generated device id rather than the configured value.
  func testInitWithoutDeviceIdFallsBackToGeneratedId() {
    let instanceName = "test_no_device_id_\(UUID().uuidString)"

    let amplitude = initPlugin(
      arguments: [
        "apiKey": "test-api-key",
        "instanceName": instanceName,
      ],
      instanceName: instanceName
    )

    XCTAssertNotNil(amplitude, "init should create an Amplitude instance")
    XCTAssertNotNil(amplitude?.getDeviceId(), "SDK should generate a device id when none is configured")
  }

  /// A failed init (e.g. missing apiKey) must be reported back to Dart as a
  /// FlutterError so `isBuilt` resolves to false, rather than silently reporting
  /// success with no instance created.
  func testInitWithMissingApiKeyReportsFlutterError() {
    let instanceName = "test_missing_api_key_\(UUID().uuidString)"
    let plugin = SwiftAmplitudeFlutterPlugin()
    let call = FlutterMethodCall(methodName: "init", arguments: ["instanceName": instanceName])

    var captured: Any?
    plugin.handle(call) { captured = $0 }

    XCTAssertTrue(captured is FlutterError, "init without apiKey should report a FlutterError")
    XCTAssertNil(plugin.instances[instanceName], "no instance should be created when init fails")
  }

}
