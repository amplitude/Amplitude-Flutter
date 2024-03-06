import Foundation
import AmplitudeSwift

class FlutterLibraryPlugin: BeforePlugin {
    static let sdkLibrary = "amplitude-flutter"
    // Version is managed automatically by semantic-release in release.config.js, please don't change it manually
    static let sdkVersion = "4.0.0-beta.0"

    override func setup(amplitude: Amplitude) {
        super.setup(amplitude: amplitude)
    }

    override func execute(event: BaseEvent) -> BaseEvent? {
        event.library = "\(FlutterLibraryPlugin.sdkLibrary)/\(FlutterLibraryPlugin.sdkVersion)"

        return event
    }
}
