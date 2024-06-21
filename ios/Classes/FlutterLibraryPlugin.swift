import Foundation
import AmplitudeSwift

class FlutterLibraryPlugin: BeforePlugin {
    let library: String

    init(library: String) {
        self.library = library
    }

    override func execute(event: BaseEvent) -> BaseEvent? {
        if let eventLibrary = event.library {
            event.library = "\(library)_\(eventLibrary)"
        } else {
            event.library = library
        }
        return event
    }
}
