#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif

import AmplitudeSwift

@objc public class SwiftAmplitudeFlutterPlugin: NSObject, FlutterPlugin {
    var amplitude: Amplitude?
    static let methodChannelName = "amplitude_flutter"

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
            let messenger = registrar.messenger()
        #else
            let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
        let instance = SwiftAmplitudeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard let args = call.arguments as? [String: Any] else {
                print("\(call.method) called but call.arguments type casting failed.")
                return
            }

            do {
                amplitude = Amplitude(configuration: try getConfiguration(args: args))
            } catch {
                print("Initialization failed.")
            }

            // Set library
            amplitude?.add(
                plugin: FlutterLibraryPlugin(
                    library: args["library"] as? String ?? "amplitude-flutter/unknown"
                )
            )

            amplitude?.logger?.debug(message: "Amplitude has been successfully initialized.")

            // Track DET app lifecycle: application installed and updated events
            let utils = DefaultEventUtils(amplitude: amplitude!)
            utils.trackAppUpdatedInstalledEvent()

            result("init called..")

        case "track", "identify", "groupIdentify", "setGroup", "revenue":
            guard let args = call.arguments as? [String: Any] else {
                print("\(call.method) called but call.arguments type casting failed.")
                return
            }

            do {
                let event = try getEvent(args: args)
                amplitude?.track(event: event)
                amplitude?.logger?.debug(message: "Track \(call.method) event: \(String(describing: call.arguments))")

                result("\(call.method) called..")
            } catch {
                amplitude?.logger?.warn(message: "\(call.method) called but failed.")
            }

        case "getUserId":
            let userId = amplitude?.getUserId()
            amplitude?.logger?.debug(message: "Get userId: \(String(describing: userId))")

            result(userId)

        case "setUserId":
            guard let args = call.arguments as? [String: Any] else {
                print("\(call.method) called but call.arguments type casting failed.")
                return
            }

            let userId = args["setUserId"] as? String
            amplitude?.setUserId(userId: userId)
            amplitude?.logger?.debug(message: "Set userId to \(String(describing: userId))")

            result("serUserId called..")

        case "getDeviceId":
            let deviceId = amplitude?.getDeviceId()
            amplitude?.logger?.debug(message: "Get deviceId: \(String(describing: deviceId))")

            result(deviceId)

        case "setDeviceId":
            guard let args = call.arguments as? [String: Any] else {
                print("\(call.method) called but call.arguments type casting failed.")
                return
            }
            let deviceId = args["setDeviceId"] as? String
            amplitude?.setDeviceId(deviceId: deviceId)
            amplitude?.logger?.debug(message: "Set deviceId to \(String(describing: deviceId))")

            result("setDeviceId called..")

        case "reset":
            amplitude?.reset()
            amplitude?.logger?.debug(message: "Reset userId and deviceId.")

            result("reset called..")

        case "flush":
            amplitude?.flush()
            amplitude?.logger?.debug(message: "Flush events.")

            result("flush called..")

        default:
            amplitude?.logger?.debug(message: "Method \(call.method) is not recognized.")
            result(FlutterMethodNotImplemented)
        }
    }

    private func getConfiguration(args: [String: Any]) throws -> Configuration {
        guard let apiKey = args["apiKey"] as? String else {
            print("apiKey type casting failed.")
            throw AmplitudeFlutterPluginError.apiKeyNotFound
        }

        let instanceName = args["instanceName"] as? String ?? Constants.Configuration.DEFAULT_INSTANCE
        let migrateLegacyData = args["migrateLegacyData"] as? Bool ?? true

        let configuration = Configuration(
            apiKey: apiKey,
            instanceName: instanceName,
            migrateLegacyData: migrateLegacyData)

        if let flushQueueSize = args["flushQueueSize"] as? Int {
            configuration.flushQueueSize = flushQueueSize
        }
        if let flushIntervalMillis = args["flushIntervalMillis"] as? Int {
            configuration.flushIntervalMillis = flushIntervalMillis
        }
        if let optOut = args["optOut"] as? Bool {
            configuration.optOut = optOut
        }
        if let logLevel = args["logLevel"] as? String {
            configuration.logLevel = logLevelFromString(logLevel)
        }
        if let minIdLength = args["minIdLength"] as? Int {
            configuration.minIdLength = minIdLength
        }
        if let partnerId = args["partnerId"] as? String {
            configuration.partnerId = partnerId
        }
        if let flushMaxRetries = args["flushMaxRetries"] as? Int {
            configuration.flushMaxRetries = flushMaxRetries
        }
        if let useBatch = args["useBatch"] as? Bool {
            configuration.useBatch = useBatch
        }
        if let serverZone = args["serverZone"] as? String, let serverZoneValue = ServerZone(
            rawValue: serverZone.uppercased()) {
            configuration.serverZone = serverZoneValue
        }
        if let serverUrl = args["serverUrl"] as? String {
            configuration.serverUrl = serverUrl
        }
        if let trackingOptionsDict = args["trackingOptions"] as? [String: Any] {
            configuration.trackingOptions = convertMapToTrackingOptions(map: trackingOptionsDict)
        }
        if let enableCoppaControl = args["enableCoppaControl"] as? Bool {
            configuration.enableCoppaControl = enableCoppaControl
        }
        if let flushEventsOnClose = args["flushEventsOnClose"] as? Bool {
            configuration.flushEventsOnClose = flushEventsOnClose
        }
        if let minTimeBetweenSessionsMillis = args["minTimeBetweenSessionsMillis"] as? Int {
            configuration.minTimeBetweenSessionsMillis = minTimeBetweenSessionsMillis
        }
        if let identifyBatchIntervalMillis = args["identifyBatchIntervalMillis"] as? Int {
            configuration.identifyBatchIntervalMillis = identifyBatchIntervalMillis
        }
        if let defaultTrackingDict = args["defaultTracking"] as? [String: Bool] {
            let sessions = defaultTrackingDict["sessions"] ?? true
            let appLifecycles = defaultTrackingDict["appLifecycles"] ?? false
            // Set false to disable screenViews on iOS
            // screenViews is implemented in Flutter
            let screenViews = false
            configuration.defaultTracking = DefaultTrackingOptions(
                sessions: sessions,
                appLifecycles: appLifecycles,
                screenViews: screenViews
            )
        }

        return configuration
    }

    private func logLevelFromString(_ logLevelString: String) -> LogLevelEnum {
        switch logLevelString.lowercased() {
        case "off":
            return .OFF
        case "error":
            return .ERROR
        case "warn":
            return .WARN
        case "log":
            return .LOG
        case "debug":
            return .DEBUG
        default:
            return .DEBUG
        }
    }

    private func convertMapToTrackingOptions(map: [String: Any]) -> TrackingOptions {
        let trackingOptions = TrackingOptions()

        if let ipAddress = map["ipAddress"] as? Bool, !ipAddress {
            trackingOptions.disableTrackIpAddress()
        }
        if let language = map["language"] as? Bool, !language {
            trackingOptions.disableTrackLanguage()
        }
        if let platform = map["platform"] as? Bool, !platform {
            trackingOptions.disableTrackPlatform()
        }
        if let region = map["region"] as? Bool, !region {
            trackingOptions.disableTrackRegion()
        }
        if let dma = map["dma"] as? Bool, !dma {
            trackingOptions.disableTrackDMA()
        }
        if let country = map["country"] as? Bool, !country {
            trackingOptions.disableTrackCountry()
        }
        if let city = map["city"] as? Bool, !city {
            trackingOptions.disableTrackCity()
        }
        if let carrier = map["carrier"] as? Bool, !carrier {
            trackingOptions.disableTrackCarrier()
        }
        if let deviceModel = map["deviceModel"] as? Bool, !deviceModel {
            trackingOptions.disableTrackDeviceModel()
        }
        if let deviceManufacturer = map["deviceManufacturer"] as? Bool, !deviceManufacturer {
            trackingOptions.disableTrackDeviceManufacturer()
        }
        if let osVersion = map["osVersion"] as? Bool, !osVersion {
            trackingOptions.disableTrackOsVersion()
        }
        if let osName = map["osName"] as? Bool, !osName {
            trackingOptions.disableTrackOsName()
        }
        if let versionName = map["versionName"] as? Bool, !versionName {
            trackingOptions.disableTrackVersionName()
        }
        if let idfv = map["idfv"] as? Bool, !idfv {
            trackingOptions.disableTrackIDFV()
        }

        return trackingOptions
    }

    private func getEvent(args: [String: Any]) throws -> BaseEvent {
        guard let eventType = args["event_type"] as? String else {
            amplitude?.logger?.warn(message: "eventType type casting failed.")
            throw AmplitudeFlutterPluginError.eventTypeNotFound
        }

        let event = BaseEvent(eventType: eventType)

        if let eventProperties = args["event_properties"] as? [String: Any] {
            event.eventProperties = eventProperties
        }
        if let userProperties = args["user_properties"] as? [String: Any] {
            event.userProperties = userProperties
        }
        if let groups = args["groups"] as? [String: Any] {
            event.groups = groups
        }
        if let groupProperties = args["group_properties"] as? [String: Any] {
            event.groupProperties = groupProperties
        }
        if let userId = args["user_id"] as? String {
            event.userId = userId
        }
        if let deviceId = args["device_id"] as? String {
            event.deviceId = deviceId
        }
        if let timestamp = args["timestamp"] as? Int {
            event.timestamp = Int64(timestamp)
        }
        if let eventId = args["event_id"] as? Int {
            event.eventId = Int64(eventId)
        }
        if let sessionId = args["session_id"] as? Int {
            event.sessionId = Int64(sessionId)
        }
        if let insertId = args["insert_id"] as? String {
            event.insertId = insertId
        }
        if let locationLat = args["location_lat"] as? Double {
            event.locationLat = locationLat
        }
        if let locationLng = args["location_lng"] as? Double {
            event.locationLng = locationLng
        }
        if let appVersion = args["app_version"] as? String {
            event.appVersion = appVersion
        }
        if let versionName = args["version_name"] as? String {
            event.versionName = versionName
        }
        if let platform = args["platform"] as? String {
            event.platform = platform
        }
        if let osName = args["os_name"] as? String {
            event.osName = osName
        }
        if let osVersion = args["os_version"] as? String {
            event.osVersion = osVersion
        }
        if let deviceBrand = args["device_brand"] as? String {
            event.deviceBrand = deviceBrand
        }
        if let deviceManufacturer = args["device_manufacturer"] as? String {
            event.deviceManufacturer = deviceManufacturer
        }
        if let deviceModel = args["device_model"] as? String {
            event.deviceModel = deviceModel
        }
        if let carrier = args["carrier"] as? String {
            event.carrier = carrier
        }
        if let country = args["country"] as? String {
            event.country = country
        }
        if let region = args["region"] as? String {
            event.region = region
        }
        if let city = args["city"] as? String {
            event.city = city
        }
        if let dma = args["dma"] as? String {
            event.dma = dma
        }
        if let idfa = args["idfa"] as? String {
            event.idfa = idfa
        }
        if let idfv = args["idfv"] as? String {
            event.idfv = idfv
        }
        if let adid = args["adid"] as? String {
            event.adid = adid
        }
        if let language = args["language"] as? String {
            event.language = language
        }
        if let library = args["library"] as? String {
            event.library = library
        }
        if let ip = args["ip"] as? String {
            event.ip = ip
        }
        if let planMap = args["plan"] as? [String: Any] {
            event.plan = Plan(
                branch: planMap["branch"] as? String,
                source: planMap["source"] as? String,
                version: planMap["version"] as? String,
                versionId: planMap["versionId"] as? String
            )
        }
        if let ingestionMetadataMap = args["ingestion_metadata"] as? [String: Any] {
            event.ingestionMetadata = IngestionMetadata(
                sourceName: ingestionMetadataMap["sourceName"] as? String,
                sourceVersion: ingestionMetadataMap["sourceVersion"] as? String
            )
        }
        if let revenue = args["revenue"] as? Double {
            event.revenue = revenue
        }
        if let price = args["price"] as? Double {
            event.price = price
        }
        if let quantity = args["quantity"] as? Int {
            event.quantity = quantity
        }
        if let productId = args["product_id"] as? String {
            event.productId = productId
        }
        if let revenueType = args["revenue_type"] as? String {
            event.revenueType = revenueType
        }
        if let extra = args["extra"] as? [String: Any] {
            event.extra = extra
        }
        if let partnerId = args["partner_id"] as? String {
            event.partnerId = partnerId
        }

        return event
    }

    enum AmplitudeFlutterPluginError: Error {
        case apiKeyNotFound
        case eventTypeNotFound
    }
}
