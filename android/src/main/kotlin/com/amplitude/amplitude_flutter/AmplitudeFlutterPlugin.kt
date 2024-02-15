package com.amplitude.amplitude_flutter

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
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject

class AmplitudeFlutterPlugin : FlutterPlugin, MethodCallHandler {
    lateinit var amplitude: Amplitude

    companion object {

        private const val methodChannelName = "amplitude_flutter"

        var ctxt: Context? = null

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            ctxt = registrar.context()
            val channel = MethodChannel(registrar.messenger(), methodChannelName)
            channel.setMethodCallHandler(AmplitudeFlutterPlugin())
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ctxt = binding.applicationContext
        val channel = MethodChannel(binding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(AmplitudeFlutterPlugin())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val json = JSONObject(call.arguments.toString())

        when (call.method) {
            "init" -> {
                val trackingOptions = json.getJSONObject("trackingOptions")
                val defaultTracking = json.getJSONObject("defaultTracking")
                amplitude = Amplitude(
                    Configuration(
                        apiKey = json.getString("apiKey"),
                        context = ctxt!!,
                        flushQueueSize = json.getInt("flushQueueSize"),
                        flushIntervalMillis = json.getInt("flushIntervalMillis"),
                        instanceName = json.getString("instanceName"),
                        optOut = json.getBoolean("optOut"),
                        minIdLength = json.getInt("minIdLength"),
                        partnerId = json.getString("partnerId"),
                        flushMaxRetries = json.getInt("flushMaxRetries"),
                        useBatch = json.getBoolean("useBatch"),
                        serverZone = com.amplitude.core.ServerZone.valueOf(
                            json.getString("serverZone").uppercase()
                        ),
                        serverUrl = json.getString("serverUrl"),
                        minTimeBetweenSessionsMillis = json.getLong("minTimeBetweenSessionsMillis"),
                        defaultTracking = DefaultTrackingOptions(
                            sessions = defaultTracking.getBoolean("sessions"),
                            appLifecycles = defaultTracking.getBoolean("appLifecycles"),
                            deepLinks = defaultTracking.getBoolean("deepLinks"),
                            screenViews = defaultTracking.getBoolean("screenViews"),
                        ),
                        trackingOptions = getTrackingOptions(trackingOptions),
                        enableCoppaControl = json.getBoolean("enableCoppaControl"),
                        flushEventsOnClose = json.getBoolean("flushEventsOnClose"),
                        identifyBatchIntervalMillis = json.getLong("identifyBatchIntervalMillis"),
                        migrateLegacyData = json.getBoolean("migrateLegacyData"),
                        locationListening = json.getBoolean("locationListening"),
                        useAdvertisingIdForDeviceId = json.getBoolean("useAdvertisingIdForDeviceId"),
                        useAppSetIdForDeviceId = json.getBoolean("useAppSetIdForDeviceId"),
                    )
                )
                 amplitude.logger.logMode = Logger.LogMode.valueOf(
                     json.getString("logLevel").uppercase()
                 )

                result.success("init called..")
            }

            "track" -> {
                amplitude.track(getEvent(json))
                result.success("track called..")
            }

            "identify" -> {
                amplitude.track(getEvent(json))
                result.success("identify called..")
            }

            "groupIdentify" -> {
                amplitude.track(getEvent(json))
                result.success("groupIdentify called..")
            }

            "setGroup" -> {
                amplitude.track(getEvent(json))
                result.success("setGroup called..")
            }

            "revenue" -> {
                amplitude.track(getEvent(json))
                result.success("revenue called..")
            }

            "setUserId" -> {
                amplitude.setUserId(json.getString("setUserId"))
                result.success("setUserId called..")
            }

            "setDeviceId" -> {
                amplitude.setDeviceId(json.getString("setDeviceId"))
                result.success("setDeviceId called..")
            }

            "reset" -> {
                amplitude.reset()
            }

            "flush" -> {
                amplitude.flush()
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getTrackingOptions(jsonObject: JSONObject): TrackingOptions {
        val trackingOptions = TrackingOptions()
        if (!jsonObject.getBoolean("ipAddress")) {
            trackingOptions.disableIpAddress()
        }
        if (!jsonObject.getBoolean("language")) {
            trackingOptions.disableLanguage()
        }
        if (!jsonObject.getBoolean("platform")) {
            trackingOptions.disablePlatform()
        }
        if (!jsonObject.getBoolean("region")) {
            trackingOptions.disableRegion()
        }
        if (!jsonObject.getBoolean("dma")) {
            trackingOptions.disableDma()
        }
        if (!jsonObject.getBoolean("country")) {
            trackingOptions.disableCountry()
        }
        if (!jsonObject.getBoolean("city")) {
            trackingOptions.disableCity()
        }
        if (!jsonObject.getBoolean("carrier")) {
            trackingOptions.disableCarrier()
        }
        if (!jsonObject.getBoolean("deviceModel")) {
            trackingOptions.disableDeviceModel()
        }
        if (!jsonObject.getBoolean("deviceManufacturer")) {
            trackingOptions.disableDeviceManufacturer()
        }
        if (!jsonObject.getBoolean("osVersion")) {
            trackingOptions.disableOsVersion()
        }
        if (!jsonObject.getBoolean("osName")) {
            trackingOptions.disableOsName()
        }
        if (!jsonObject.getBoolean("adid")) {
            trackingOptions.disableAdid()
        }
        if (!jsonObject.getBoolean("appSetId")) {
            trackingOptions.disableAppSetId()
        }
        if (!jsonObject.getBoolean("deviceBrand")) {
            trackingOptions.disableDeviceBrand()
        }
        if (!jsonObject.getBoolean("latLag")) {
            trackingOptions.disableLatLng()
        }
        if (!jsonObject.getBoolean("apiLevel")) {
            trackingOptions.disableApiLevel()
        }

        return trackingOptions
    }

    private fun getEvent(json: JSONObject): BaseEvent {
        val plan = json.getJSONObject("plan")
        val ingestionMetadata = json.getJSONObject("ingestion_metadata")
        val event = BaseEvent()
        event.eventType = json.getString("event_type")
        event.eventProperties = json.getJSONObject("event_properties").toMutableMap()
        event.userProperties = json.getJSONObject("user_properties").toMutableMap()
        event.groups = json.getJSONObject("groups").toMutableMap()
        event.groupProperties = json.getJSONObject("group_properties").toMutableMap()
        event.userId = json.getString("user_id")
        event.deviceId = json.getString("device_id")
        event.timestamp = json.getLong("timestamp")
        event.eventId = json.getLong("event_id")
        event.sessionId = json.getLong("session_id")
        event.insertId = json.getString("insert_id")
        event.locationLat = json.getDouble("location_lat")
        event.locationLng = json.getDouble("location_lng")
        event.appVersion = json.getString("app_version")
        event.versionName = json.getString("version_name")
        event.platform = json.getString("platform")
        event.osName = json.getString("osName")
        event.osVersion = json.getString("os_version")
        event.deviceBrand = json.getString("device_brand")
        event.deviceManufacturer = json.getString("device_manufacturer")
        event.deviceModel = json.getString("device_model")
        event.carrier = json.getString("carrier")
        event.country = json.getString("country")
        event.region = json.getString("region")
        event.city = json.getString("city")
        event.dma = json.getString("dma")
        event.idfa = json.getString("idfa")
        event.idfv = json.getString("idfv")
        event.adid = json.getString("adid")
        event.appSetId = json.getString("app_set_id")
        event.androidId = json.getString("android_id")
        event.language = json.getString("language")
        event.library = json.getString("library")
        event.ip = json.getString("ip")
        event.plan = Plan(
            plan.getString("branch"),
            plan.getString("source"),
            plan.getString("version"),
            plan.getString("versionId")
        )
        event.ingestionMetadata = IngestionMetadata(
            ingestionMetadata.getString("sourceName"),
            ingestionMetadata.getString("sourceVersion")
        )
        event.revenue = json.getDouble("revenue")
        event.price = json.getDouble("price")
        event.quantity = json.getInt("quantity")
        event.productId = json.getString("product_id")
        event.revenueType = json.getString("revenue_type")
        event.extra = json.optJSONObject("extra").toMap()
        event.partnerId = json.getString("partner_id")

        return event
    }

    private fun JSONObject.toMutableMap(): MutableMap<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = get(key)
            if (value is JSONObject) {
                value = value.toMap()
            }
            map[key] = value
        }
        return map
    }

    private fun JSONObject.toMap(): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        val keys = keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = get(key)
            if (value is JSONObject) {
                value = value.toMap()
            }
            map[key] = value
        }
        return map
    }
}
