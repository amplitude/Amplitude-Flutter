import Foundation
import AmplitudeSwift

// Plugin to deduplicate lifecycle events within a time window
class LifecycleDeduplicationPlugin: BeforePlugin {
    private var eventTimestamps: [String: Date] = [:]
    private let deduplicationWindowSeconds: TimeInterval = 1.0

    override func execute(event: BaseEvent) -> BaseEvent? {
        let eventType = event.eventType

        guard ["[Amplitude] Application Installed", "[Amplitude] Application Updated", "[Amplitude] Application Opened"].contains(eventType) else {
            return event
        }

        let now = Date()

        // Check if we've seen this event type recently
        if let lastTimestamp = eventTimestamps[eventType] {
            let timeSinceLastEvent = now.timeIntervalSince(lastTimestamp)

            if timeSinceLastEvent < deduplicationWindowSeconds {
                // Too soon since last event of this type, drop it
                return nil
            }
        }

        // Update timestamp for this event type
        eventTimestamps[eventType] = now

        // Clean up old timestamps (older than window)
        eventTimestamps = eventTimestamps.filter { _, timestamp in
            now.timeIntervalSince(timestamp) < deduplicationWindowSeconds
        }

        return event
    }
}
