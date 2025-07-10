package com.amplitude.amplitude_flutter

import android.app.Activity
import android.content.Context
import com.amplitude.android.Amplitude
import com.amplitude.android.Configuration
import com.amplitude.android.DefaultTrackingOptions
import com.amplitude.android.TrackingOptions
import com.amplitude.android.events.IngestionMetadata
import com.amplitude.android.events.Plan
import com.amplitude.common.Logger
import com.amplitude.core.events.BaseEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.pm.PackageManager
import com.amplitude.android.utilities.DefaultEventUtils
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.lang.ref.WeakReference

class AmplitudeFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var instances: Map<String, Amplitude> = mutableMapOf()
    private var activity: WeakReference<Activity?> = WeakReference(null)
    lateinit var ctxt: Context

    private lateinit var channel: MethodChannel

    companion object {
        private const val methodChannelName = "amplitude_flutter"
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = WeakReference(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activity = WeakReference(null)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ctxt = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "init") {
            val configuration = getConfiguration(call)
            val amplitude = Amplitude(configuration)
            instances += mapOf(configuration.instanceName to amplitude)

            // Set library
            amplitude.add(
                FlutterLibraryPlugin(
                    call.argument<String>("library") ?: "amplitude-flutter/unknown"
                )
            )

            call.argument<String>("logLevel")?.let {
                if (it == "log") {
                    amplitude.logger.logMode = Logger.LogMode.INFO
                } else {
                    amplitude.logger.logMode = Logger.LogMode.valueOf(it.uppercase())
                }
            }
            amplitude.logger.debug("Amplitude has been successfully initialized.")

            trackAppLifecycleAndDeepLinkEvents(
                amplitude,
                configuration.defaultTracking.appLifecycles,
                configuration.defaultTracking.deepLinks
            )

            result.success("init called..")
            return
        }

        val instanceName = call.argument<String>("instanceName") ?: "\$default_instance"
        val amplitude = instances[instanceName] ?: throw IllegalArgumentException("Amplitude instance $instanceName not found")

        when (call.method) {
            "track", "identify", "groupIdentify", "setGroup", "revenue" -> {
                val event = getEvent(call)
                amplitude.track(event)
                amplitude.logger.debug("Track ${call.method} event: ${call.arguments}")

                result.success("${call.method} called..")
            }

            "getUserId" -> {
                val userId = amplitude.getUserId()
                amplitude.logger.debug("Get userId: $userId")

                result.success(userId)
            }

            "setUserId" -> {
                val userId = call.argument<Map<String, String?>>("properties")!!["setUserId"]
                amplitude.setUserId(userId)
                amplitude.logger.debug("Set userId to ${call.arguments}")

                result.success("setUserId called..")
            }

            "getDeviceId" -> {
                val deviceId = amplitude.getDeviceId()
                amplitude.logger.debug("Get deviceId: $deviceId")

                result.success(deviceId)
            }

            "setDeviceId" -> {
                val deviceId = call.argument<Map<String, String>>("properties")!!["setDeviceId"]
                deviceId?.let { amplitude.setDeviceId(it) }
                amplitude.logger.debug("Set deviceId to ${call.arguments}")

                result.success("setDeviceId called..")
            }

            "getSessionId" -> {
                val sessionId = amplitude.sessionId
                amplitude.logger.debug("Get sessionId: $sessionId")

                result.success(sessionId)
            }

            "reset" -> {
                amplitude.reset()
                amplitude.logger.debug("Reset userId and deviceId.")

                result.success("reset called..")
            }

            "flush" -> {
                amplitude.flush()
                amplitude.logger.debug("Flush events.")

                result.success("flush called..")
            }

            else -> {
                amplitude.logger.debug("Method ${call.method} is not recognized.")

                result.notImplemented()
            }
        }
    }

    private fun trackAppLifecycleAndDeepLinkEvents(amplitude: Amplitude, appLifecycles: Boolean, deepLinks: Boolean) {
        amplitude.isBuilt.invokeOnCompletion { exception ->
            if (exception != null) {
                println("isBuilt computation failed with exception: $exception")
            } else {
                val utils = DefaultEventUtils(amplitude)

                if (deepLinks) {
                    activity.get()?.let { utils.trackDeepLinkOpenedEvent(it) }
                }
            }
        }
    }

    private fun getConfiguration(call: MethodCall): Configuration {
        val configuration = Configuration(call.argument<String>("apiKey")!!, context = ctxt)
        call.argument<Int>("flushQueueSize")?.let { configuration.flushQueueSize = it }
        call.argument<Int>("flushIntervalMillis")?.let { configuration.flushIntervalMillis = it }
        call.argument<String>("instanceName")?.let { configuration.instanceName = it }
        call.argument<Boolean>("optOut")?.let { configuration.optOut = it }
        call.argument<Int>("minIdLength")?.let { configuration.minIdLength = it }
        call.argument<String>("partnerId")?.let { configuration.partnerId = it }
        call.argument<Int>("flushMaxRetries")?.let { configuration.flushMaxRetries = it }
        call.argument<Boolean>("useBatch")?.let { configuration.useBatch = it }
        call.argument<String>("serverZone")
            ?.let { configuration.serverZone = com.amplitude.core.ServerZone.valueOf(it.uppercase()) }
        call.argument<String>("serverUrl")?.let { configuration.serverUrl = it }
        call.argument<Int>("minTimeBetweenSessionsMillis")
            ?.let { configuration.minTimeBetweenSessionsMillis = it.toLong() }
        call.argument<Map<String, Any>>("defaultTracking")?.let { map ->
            configuration.defaultTracking = DefaultTrackingOptions(
                sessions = (map["sessions"] as? Boolean) ?: true,
                appLifecycles = (map["appLifecycles"] as? Boolean) ?: false,
                deepLinks = (map["deepLinks"] as? Boolean) ?: false,
                // Set false to disable screenViews on Android
                // screenViews is implemented in Flutter
                screenViews = false
            )
        }
        call.argument<Map<String, Any>>("trackingOptions")?.let { map ->
            configuration.trackingOptions = convertMapToTrackingOptions(map)
        }
        call.argument<Boolean>("enableCoppaControl")?.let { configuration.enableCoppaControl = it }
        call.argument<Boolean>("flushEventsOnClose")?.let { configuration.flushEventsOnClose = it }
        call.argument<Int>("identifyBatchIntervalMillis")
            ?.let { configuration.identifyBatchIntervalMillis = it.toLong() }
        call.argument<Boolean>("migrateLegacyData")?.let { configuration.migrateLegacyData = it }
        call.argument<Boolean>("locationListening")?.let { configuration.locationListening = it }
        call.argument<Boolean>("useAdvertisingIdForDeviceId")
            ?.let { configuration.useAdvertisingIdForDeviceId = it }
        call.argument<Boolean>("useAppSetIdForDeviceId")?.let { configuration.useAppSetIdForDeviceId = it }

        return configuration
    }

    private fun convertMapToTrackingOptions(map: Map<String, Any>): TrackingOptions {
        val trackingOptions = TrackingOptions()

        (map["ipAddress"] as? Boolean)?.let { if (!it) trackingOptions.disableIpAddress() }
        (map["language"] as? Boolean)?.let { if (!it) trackingOptions.disableLanguage() }
        (map["platform"] as? Boolean)?.let { if (!it) trackingOptions.disablePlatform() }
        (map["region"] as? Boolean)?.let { if (!it) trackingOptions.disableRegion() }
        (map["dma"] as? Boolean)?.let { if (!it) trackingOptions.disableDma() }
        (map["country"] as? Boolean)?.let { if (!it) trackingOptions.disableCountry() }
        (map["city"] as? Boolean)?.let { if (!it) trackingOptions.disableCity() }
        (map["carrier"] as? Boolean)?.let { if (!it) trackingOptions.disableCarrier() }
        (map["deviceModel"] as? Boolean)?.let { if (!it) trackingOptions.disableDeviceModel() }
        (map["deviceManufacturer"] as? Boolean)?.let { if (!it) trackingOptions.disableDeviceManufacturer() }
        (map["osVersion"] as? Boolean)?.let { if (!it) trackingOptions.disableOsVersion() }
        (map["osName"] as? Boolean)?.let { if (!it) trackingOptions.disableOsName() }
        (map["versionName"] as? Boolean)?.let { if (!it) trackingOptions.disableVersionName() }
        (map["adid"] as? Boolean)?.let { if (!it) trackingOptions.disableAdid() }
        (map["appSetId"] as? Boolean)?.let { if (!it) trackingOptions.disableAppSetId() }
        (map["deviceBrand"] as? Boolean)?.let { if (!it) trackingOptions.disableDeviceBrand() }
        (map["latLng"] as? Boolean)?.let { if (!it) trackingOptions.disableLatLng() }
        (map["apiLevel"] as? Boolean)?.let { if (!it) trackingOptions.disableApiLevel() }

        return trackingOptions
    }

    /**
     * Converts a [MethodCall] to a [BaseEvent] assuming arguments is a Map.
     *
     * @param call The [MethodCall] containing the event's data as arguments.
     * @return A [BaseEvent] populated with properties extracted from the [MethodCall].
     * @throws IllegalArgumentException If mandatory field `event_type` is missing.
     *
     * Example usage:
     * val event = getEventFromMap(methodCall)
     *
     * Note:
     * - The function only sets the class property of the BaseEvent instance if it's explicitly set.
     *   Otherwise, it will take the default value of BaseEvent constructor
     */
    private fun getEvent(call: MethodCall): BaseEvent {
        val args = call.argument<Map<String, Any>>("event")!!
        val event = BaseEvent()
        event.eventType = args["event_type"] as String
        (args["event_properties"] as? Map<String, Any>)?.let {
            event.eventProperties = it.toMutableMap()
        }
        (args["user_properties"] as? Map<String, Any>)?.let {
            event.userProperties = it.toMutableMap()
        }
        (args["groups"] as? Map<String, Any>)?.let {
            event.groups = it.toMutableMap()
        }
        (args["group_properties"] as? Map<String, Any>)?.let {
            event.groupProperties = it.toMutableMap()
        }
        (args["user_id"] as? String)?.let { event.userId = it }
        (args["device_id"] as? String)?.let { event.deviceId = it }
        (args["timestamp"] as? Int)?.let { event.timestamp = it.toLong() }
        (args["event_id"] as? Int)?.let { event.eventId = it.toLong() }
        (args["session_id"] as? Int)?.let { event.sessionId = it.toLong() }
        (args["insert_id"] as? String)?.let { event.insertId = it }
        (args["location_lat"] as? Double)?.let { event.locationLat = it }
        (args["location_lng"] as? Double)?.let { event.locationLng = it }
        (args["app_version"] as? String)?.let { event.appVersion = it }
        (args["version_name"] as? String)?.let { event.versionName = it }
        (args["platform"] as? String)?.let { event.platform = it }
        (args["os_name"] as? String)?.let { event.osName = it }
        (args["os_version"] as? String)?.let { event.osVersion = it }
        (args["device_brand"] as? String)?.let { event.deviceBrand = it }
        (args["device_manufacturer"] as? String)?.let { event.deviceManufacturer = it }
        (args["device_model"] as? String)?.let { event.deviceModel = it }
        (args["carrier"] as? String)?.let { event.carrier = it }
        (args["country"] as? String)?.let { event.country = it }
        (args["region"] as? String)?.let { event.region = it }
        (args["city"] as? String)?.let { event.city = it }
        (args["dma"] as? String)?.let { event.dma = it }
        (args["idfa"] as? String)?.let { event.idfa = it }
        (args["idfv"] as? String)?.let { event.idfv = it }
        (args["adid"] as? String)?.let { event.adid = it }
        (args["app_set_id"] as? String)?.let { event.appSetId = it }
        (args["android_id"] as? String)?.let { event.androidId = it }
        (args["language"] as? String)?.let { event.language = it }
        (args["library"] as? String)?.let { event.library = it }
        (args["ip"] as? String)?.let { event.ip = it }
        (args["plan"] as? Map<String, Any>)?.let {
            event.plan = Plan(
                it["branch"] as? String,
                it["source"] as? String,
                it["version"] as? String,
                it["versionId"] as? String
            )
        }
        (args["ingestion_metadata"] as? Map<String, Any>)?.let {
            event.ingestionMetadata = IngestionMetadata(
                it["sourceName"] as? String,
                it["sourceVersion"] as? String
            )
        }
        (args["revenue"] as? Double)?.let { event.revenue = it }
        (args["price"] as? Double)?.let { event.price = it }
        (args["quantity"] as? Int)?.let { event.quantity = it }
        (args["product_id"] as? String)?.let { event.productId = it }
        (args["revenue_type"] as? String)?.let { event.revenueType = it }
        (args["extra"] as? Map<String, Any>)?.let {
            event.extra = it
        }
        (args["partner_id"] as? String)?.let { event.partnerId = it }

        return event
    }
}
