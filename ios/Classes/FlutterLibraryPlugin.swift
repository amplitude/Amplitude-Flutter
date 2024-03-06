import Foundation
import AmplitudeSwift

class FlutterLibraryPlugin: BeforePlugin {
    let library: String

    init(library: String) {
        self.library = library
    }

    override func execute(event: BaseEvent) -> BaseEvent? {
        event.library = library

        return event
    }
}
