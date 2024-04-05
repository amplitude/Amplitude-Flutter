package com.amplitude.amplitude_flutter

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.every
import io.mockk.mockk
import io.mockk.spyk
import io.mockk.verify
import org.json.JSONObject
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner::class)
class AmplitudeFlutterPluginTest {
    private val plugin = AmplitudeFlutterPlugin()
    private val result = spyk<MethodChannel.Result>()
    private val binding = mockk<FlutterPlugin.FlutterPluginBinding>(relaxed = true)
    private val context = mockk<Context>()

    private lateinit var testConfigurationMap: MutableMap<String, Any?>
    private lateinit var testEventMap: MutableMap<String, Any?>

    @Before
    fun setup() {
        testConfigurationMap = mutableMapOf(
            "apiKey" to "test-api-key",
            "flushQueueSize" to 30,
            "flushIntervalMillis" to 30 * 1000, // 30 seconds
            "instanceName" to "\$default_instance",
            "optOut" to false,
            "logLevel" to "info",
            "minIdLength" to null,
            "partnerId" to null,
            "flushMaxRetries" to 5,
            "useBatch" to false,
            "serverZone" to "us",
            "serverUrl" to null,
            "minTimeBetweenSessionsMillis" to 5 * 60 * 1000, // 5 minutes
            "defaultTracking" to JSONObject(mapOf(
                "sessions" to true,
                "appLifecycles" to false,
                "deepLinks" to false,
                "attribution" to true,
                "pageViews" to true,
                "formInteractions" to true,
                "fileDownloads" to true
            )),
            "trackingOptions" to JSONObject(mapOf(
                "ipAddress" to true,
                "language" to true,
                "platform" to true,
                "region" to true,
                "dma" to true,
                "country" to true,
                "city" to true,
                "carrier" to true,
                "deviceModel" to true,
                "deviceManufacturer" to true,
                "osVersion" to true,
                "osName" to true,
                "versionName" to true,
                "adid" to true,
                "appSetId" to true,
                "deviceBrand" to true,
                "latLag" to true,
                "apiLevel" to true,
                "idfv" to true
            )),
            "enableCoppaControl" to false,
            "flushEventsOnClose" to true,
            "identifyBatchIntervalMillis" to 30 * 1000,
            "migrateLegacyData" to true,
            "locationListening" to true,
            "useAdvertisingIdForDeviceId" to false,
            "useAppSetIdForDeviceId" to false,
            "appVersion" to null
        )
        testEventMap = mutableMapOf(
            "event_type" to "testEvent",
            "event_properties" to null,
            "user_properties" to null,
            "groups" to null,
            "group_properties" to null,
            "user_id" to null,
            "device_id" to "test device id",
            "timestamp" to null,
            "event_id" to null,
            "session_id" to null,
            "insert_id" to null,
            "location_lat" to null,
            "location_lng" to null,
            "app_version" to null,
            "version_name" to null,
            "platform" to null,
            "os_name" to null,
            "os_version" to null,
            "device_brand" to null,
            "device_manufacturer" to null,
            "device_model" to null,
            "carrier" to null,
            "country" to null,
            "region" to null,
            "city" to null,
            "dma" to null,
            "idfa" to null,
            "idfv" to null,
            "adid" to null,
            "app_set_id" to null,
            "android_id" to null,
            "language" to null,
            "library" to null,
            "ip" to null,
            "plan" to JSONObject(mapOf(
                "branch" to null,
                "source" to null,
                "version" to null,
                "versionId" to null,
            )),
            "ingestion_metadata" to JSONObject(mapOf(
                "sourceName" to null,
                "sourceVersion" to null,
            )),
            "revenue" to null,
            "price" to null,
            "quantity" to null,
            "product_id" to null,
            "revenue_type" to null,
            "extra" to null,
            "partner_id" to null,
            "attempts" to 0
        )

        every { binding.applicationContext } returns context

        plugin.onAttachedToEngine(binding)
    }

    @Test
    fun shouldInit() {
        val methodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("init called..") }
    }

    @Test
    fun shouldTrack() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        val methodCall = MethodCall("track", JSONObject(testEventMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("track called..") }
    }

    @Test
    fun shouldIdentify() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        testEventMap["event_type"] = "\$identify"
        testEventMap["user_properties"] = mapOf(
            "\$set" to mapOf("testProperty" to "testValue")
        )
        val methodCall = MethodCall("identify", JSONObject(testEventMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("identify called..") }
    }

    @Test
    fun shouldGroupIdentify() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        testEventMap["event_type"] = "\$groupidentify"
        testEventMap["groups"] = mapOf(
            "testGroupType" to "testGroupName"
        )
        testEventMap["group_properties"] = mapOf(
            "\$set" to mapOf("testProperty" to "testValue")
        )
        val methodCall = MethodCall("groupIdentify", JSONObject(testEventMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("groupIdentify called..") }
    }

    @Test
    fun shouldSetGroup() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        testEventMap["event_type"] = "\$identify"
        testEventMap["groups"] = mapOf(
            "testGroupType" to "testGroupName"
        )
        testEventMap["user_properties"] = mapOf(
            "\$set" to mapOf("testProperty" to "testValue")
        )
        val methodCall = MethodCall("setGroup", JSONObject(testEventMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("setGroup called..") }
    }

    @Test
    fun shouldRevenue() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        testEventMap["event_type"] = "revenue_amount"
        testEventMap["groups"] = mapOf(
            "testGroupType" to "testGroupName"
        )
        testEventMap["event_properties"] = mapOf(
            "\$price" to "testPrice",
            "\$quantity" to "testQuantity",
            "\$productId" to "testProductId"
        )
        val methodCall = MethodCall("revenue", JSONObject(testEventMap))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("revenue called..") }
    }

    @Test
    fun shouldSetUserId() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        val methodCall = MethodCall("setUserId", JSONObject(mapOf(
            "setUserId" to "testUserId"
        )))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("setUserId called..") }
    }

    @Test
    fun shouldSetDeviceId() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        val methodCall = MethodCall("setDeviceId", JSONObject(mapOf(
            "setDeviceId" to "testDeviceId"
        )))
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("setDeviceId called..") }
    }

    @Test
    fun shouldReset() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        val methodCall = MethodCall("reset", null)
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("reset called..") }
    }

    @Test
    fun shouldFlush() {
        val initMethodCall = MethodCall("init", JSONObject(testConfigurationMap))
        plugin.onMethodCall(initMethodCall, result)

        val methodCall = MethodCall("flush", null)
        plugin.onMethodCall(methodCall, result)

        verify(exactly = 1) { result.success("flush called..") }
    }

}
