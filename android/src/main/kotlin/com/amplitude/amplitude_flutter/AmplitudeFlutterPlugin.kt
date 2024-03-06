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
    lateinit var amplitude: Amplitude
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
        when (call.method) {
            "init" -> {
                val configuration = getConfiguration(call)
                amplitude = Amplitude(configuration)

                // Set library
                amplitude.add(
                    FlutterLibraryPlugin(
                        call.argument<String>("library") ?: "amplitude-flutter/unknown"
                    )
                )

                call.argument<String>("logLevel")?.let {
                    amplitude.logger.logMode = Logger.LogMode.valueOf(it.uppercase())
                }
                amplitude.logger.debug("Amplitude has been successfully initialized.")

                trackAppLifecycleAndDeepLinkEvents(
                    configuration.defaultTracking.appLifecycles,
                    configuration.defaultTracking.deepLinks
                )

                result.success("init called..")
            }

            "track", "identify", "groupIdentify", "setGroup", "revenue" -> {
                val event = getEvent(call)
                amplitude.track(event)
                amplitude.logger.debug("Track ${call.method} event: ${call.arguments}")

                result.success("${call.method} called..")
            }

            "setUserId" -> {
                val userId = call.argument<String?>("setUserId")
                amplitude.setUserId(userId)
                amplitude.logger.debug("Set user Id to ${call.arguments}")

                result.success("setUserId called..")
            }

            "setDeviceId" -> {
                val deviceId = call.argument<String>("setDeviceId")
                deviceId?.let { amplitude.setDeviceId(it) }
                amplitude.logger.debug("Set device Id to ${call.arguments}")

                result.success("setDeviceId called..")
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

    private fun trackAppLifecycleAndDeepLinkEvents(appLifecycles: Boolean, deepLinks: Boolean) {
        amplitude.isBuilt.invokeOnCompletion { exception ->
            if (exception != null) {
                println("isBuilt computation failed with exception: $exception")
            } else {
                val utils = DefaultEventUtils(amplitude)

                if (appLifecycles) {
                    val packageManager = ctxt.packageManager
                    val packageInfo = try {
                        packageManager.getPackageInfo(ctxt.packageName, 0)
                    } catch (ex: PackageManager.NameNotFoundException) {
                        println("Error occurred in getting package info. " + ex.message)
                        null
                    }
                    packageInfo?.let { utils.trackAppUpdatedInstalledEvent(it) }
                }

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
                screenViews = (map["screenViews"] as? Boolean) ?: false
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
        val event = BaseEvent()
        event.eventType = call.argument<String>("event_type")!!
        call.argument<Map<String, Any>>("event_properties")?.let {
            event.eventProperties = it.toMutableMap()
        }
        call.argument<Map<String, Any>>("user_properties")?.let {
            event.userProperties = it.toMutableMap()
        }
        call.argument<Map<String, Any>>("groups")?.let {
            event.groups = it.toMutableMap()
        }
        call.argument<Map<String, Any>>("group_properties")?.let {
            event.groupProperties = it.toMutableMap()
        }
        call.argument<String>("user_id")?.let { event.userId = it }
        call.argument<String>("device_id")?.let { event.deviceId = it }
        call.argument<Int>("timestamp")?.let { event.timestamp = it.toLong() }
        call.argument<Int>("event_id")?.let { event.eventId = it.toLong() }
        call.argument<Int>("session_id")?.let { event.sessionId = it.toLong() }
        call.argument<String>("insert_id")?.let { event.insertId = it }
        call.argument<Double>("location_lat")?.let { event.locationLat = it }
        call.argument<Double>("location_lng")?.let { event.locationLng = it }
        call.argument<String>("app_version")?.let { event.appVersion = it }
        call.argument<String>("version_name")?.let { event.versionName = it }
        call.argument<String>("platform")?.let { event.platform = it }
        call.argument<String>("os_name")?.let { event.osName = it }
        call.argument<String>("os_version")?.let { event.osVersion = it }
        call.argument<String>("device_brand")?.let { event.deviceBrand = it }
        call.argument<String>("device_manufacturer")?.let { event.deviceManufacturer = it }
        call.argument<String>("device_model")?.let { event.deviceModel = it }
        call.argument<String>("carrier")?.let { event.carrier = it }
        call.argument<String>("country")?.let { event.country = it }
        call.argument<String>("region")?.let { event.region = it }
        call.argument<String>("city")?.let { event.city = it }
        call.argument<String>("dma")?.let { event.dma = it }
        call.argument<String>("idfa")?.let { event.idfa = it }
        call.argument<String>("idfv")?.let { event.idfv = it }
        call.argument<String>("adid")?.let { event.adid = it }
        call.argument<String>("app_set_id")?.let { event.appSetId = it }
        call.argument<String>("android_id")?.let { event.androidId = it }
        call.argument<String>("language")?.let { event.language = it }
        call.argument<String>("library")?.let { event.library = it }
        call.argument<String>("ip")?.let { event.ip = it }
        call.argument<Map<String, Any>>("plan")?.let {
            event.plan = Plan(
                it["branch"] as? String,
                it["source"] as? String,
                it["version"] as? String,
                it["versionId"] as? String
            )
        }
        call.argument<Map<String, Any>>("ingestion_metadata")?.let {
            event.ingestionMetadata = IngestionMetadata(
                it["sourceName"] as? String,
                it["sourceVersion"] as? String
            )
        }
        call.argument<Double>("revenue")?.let { event.revenue = it }
        call.argument<Double>("price")?.let { event.price = it }
        call.argument<Int>("quantity")?.let { event.quantity = it }
        call.argument<String>("product_id")?.let { event.productId = it }
        call.argument<String>("revenue_type")?.let { event.revenueType = it }
        call.argument<Map<String, Any>>("extra")?.let {
            event.extra = it
        }
        call.argument<String>("partner_id")?.let { event.partnerId = it }

        return event
    }
}
