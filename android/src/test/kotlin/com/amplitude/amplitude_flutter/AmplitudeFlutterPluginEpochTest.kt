package com.amplitude.amplitude_flutter

import com.amplitude.core.events.BaseEvent
import com.amplitude.android.Amplitude
import com.amplitude.android.Configuration
import com.amplitude.core.platform.Plugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/** SDK-439: exercise the real channel codec and plugin parser without uploading events. */
@Config(manifest = Config.NONE, sdk = [28])
@RunWith(RobolectricTestRunner::class)
class AmplitudeFlutterPluginEpochTest {
    @Test
    fun `small integer overrides survive the channel and parser`() {
        assertOverridesPreserved(1234)
    }

    @Test
    fun `epoch timestamp survives the channel and parser`() {
        val event = parseEvent(1793041045610L)
        assertEquals("Explicit epoch timestamp was dropped", 1793041045610L, event.timestamp)
    }

    @Test
    fun `epoch session ID survives the channel and parser`() {
        val event = parseEvent(1793041045610L)
        assertEquals("Explicit epoch session ID was dropped", 1793041045610L, event.sessionId)
    }

    @Test
    fun `large event ID survives the channel and parser`() {
        val event = parseEvent(1793041045610L)
        assertEquals(1793041045610L, event.eventId)
    }

    @Test
    fun `integer boundaries and out of session sentinel are preserved`() {
        listOf(-1, 0, Int.MAX_VALUE, Int.MAX_VALUE.toLong() + 1, Long.MAX_VALUE).forEach {
            assertOverridesPreserved(it)
        }
    }

    @Test
    fun `omitted and null overrides keep native defaults`() {
        listOf(emptyMap<String, Any?>(), mapOf("timestamp" to null, "session_id" to null, "event_id" to null)).forEach {
            val event = parse(decodedCall(it))
            assertNull(event.timestamp)
            assertNull(event.sessionId)
            assertNull(event.eventId)
        }
    }

    @Test
    fun `session timeout preserves small integers and values above the 32 bit limit`() {
        assertConfigurationDurationPreserved("minTimeBetweenSessionsMillis") { it.minTimeBetweenSessionsMillis }
    }

    @Test
    fun `identify batch interval preserves small integers and values above the 32 bit limit`() {
        assertConfigurationDurationPreserved("identifyBatchIntervalMillis") { it.identifyBatchIntervalMillis }
    }

    private fun assertConfigurationDurationPreserved(key: String, readValue: (Configuration) -> Long) {
        val plugin = AmplitudeFlutterPlugin().apply { ctxt = RuntimeEnvironment.getApplication() }
        val parser = AmplitudeFlutterPlugin::class.java.getDeclaredMethod("getConfiguration", MethodCall::class.java).apply {
            isAccessible = true
        }
        listOf(1234, Int.MAX_VALUE, Int.MAX_VALUE.toLong() + 1, 30L * 24 * 60 * 60 * 1000).forEach { value ->
            val call = roundTrip(MethodCall("init", mapOf(
                "apiKey" to "test-api-key",
                key to value,
            )))
            val configuration = parser.invoke(plugin, call) as Configuration
            assertEquals(value.toLong(), readValue(configuration))
        }
    }

    @Test
    fun `omitted and null configuration durations keep native defaults`() {
        val plugin = AmplitudeFlutterPlugin().apply { ctxt = RuntimeEnvironment.getApplication() }
        val parser = AmplitudeFlutterPlugin::class.java.getDeclaredMethod("getConfiguration", MethodCall::class.java).apply {
            isAccessible = true
        }
        val defaults = Configuration(apiKey = "test-api-key", context = RuntimeEnvironment.getApplication(), autocapture = emptySet())
        listOf(emptyMap<String, Any?>(), mapOf("minTimeBetweenSessionsMillis" to null, "identifyBatchIntervalMillis" to null)).forEach { values ->
            val call = roundTrip(MethodCall("init", mapOf("apiKey" to "test-api-key") + values))
            val configuration = parser.invoke(plugin, call) as Configuration
            assertEquals(defaults.minTimeBetweenSessionsMillis, configuration.minTimeBetweenSessionsMillis)
            assertEquals(defaults.identifyBatchIntervalMillis, configuration.identifyBatchIntervalMillis)
        }
    }

    @Test
    fun `custom session start sets active session and following event inherits it`() {
        val instanceName = "sdk-439-session-flow"
        val amplitude = Amplitude(Configuration(
            apiKey = "test-api-key",
            context = RuntimeEnvironment.getApplication(),
            instanceName = instanceName,
            autocapture = emptySet(),
            serverUrl = "http://127.0.0.1:1",
        ))
        try {
            runBlocking { withTimeout(15_000) { amplitude.isBuilt.await() } }
            val captured = LinkedBlockingQueue<BaseEvent>()
            amplitude.add(object : Plugin {
                override val type = Plugin.Type.Before
                override lateinit var amplitude: com.amplitude.core.Amplitude
                override fun execute(event: BaseEvent): BaseEvent? {
                    captured.add(event)
                    // Session processing has finished; stop before persistence/upload.
                    return null
                }
            })
            val plugin = AmplitudeFlutterPlugin()
            AmplitudeFlutterPlugin::class.java.getDeclaredField("instances").apply {
                isAccessible = true
                set(plugin, mapOf(instanceName to amplitude))
            }
            val result = object : MethodChannel.Result {
                override fun success(result: Any?) = Unit
                override fun error(code: String, message: String?, details: Any?) {
                    throw AssertionError("$code: $message")
                }
                override fun notImplemented() { throw AssertionError("Method not implemented") }
            }
            val sessionId = 1793041045610L
            // Distinct values ensure the session ID isn't merely derived from the timestamp.
            val timestamp = System.currentTimeMillis() - 1000
            plugin.onMethodCall(decodedCall(mapOf("timestamp" to timestamp, "session_id" to sessionId), instanceName), result)
            val start = captured.poll(5, TimeUnit.SECONDS)
            assertNotNull("Session start must reach the native pipeline", start)
            assertEquals(timestamp, start!!.timestamp)
            assertEquals(sessionId, start.sessionId)
            assertEquals(sessionId, amplitude.sessionId)

            plugin.onMethodCall(decodedCall(mapOf("event_type" to "following_event"), instanceName), result)
            val following = captured.poll(5, TimeUnit.SECONDS)
            assertNotNull("Following event must reach the native pipeline", following)
            assertEquals("following_event", following!!.eventType)
            assertNotNull("Native SDK supplies a timestamp when omitted", following.timestamp)
            assertEquals(sessionId, following.sessionId)
            assertEquals(sessionId, amplitude.sessionId)
        } finally {
            amplitude.amplitudeScope.cancel()
        }
    }

    private fun assertOverridesPreserved(value: Number) {
        val event = parseEvent(value)
        assertEquals(value.toLong(), event.timestamp)
        assertEquals(value.toLong(), event.sessionId)
        assertEquals(value.toLong(), event.eventId)
    }

    private fun parseEvent(value: Number): BaseEvent {
        return parse(decodedCall(mapOf("timestamp" to value, "session_id" to value, "event_id" to value)))
    }

    private fun decodedCall(event: Map<String, Any?>, instanceName: String = "sdk-439-repro"): MethodCall {
        return roundTrip(MethodCall("track", mapOf(
            "instanceName" to instanceName,
            "event" to (mapOf("event_type" to "session_start") + event),
        )))
    }

    private fun roundTrip(call: MethodCall): MethodCall {
        val codec = StandardMethodCodec.INSTANCE
        val encoded = codec.encodeMethodCall(call)
        encoded.flip()
        return codec.decodeMethodCall(encoded)
    }

    private fun parse(call: MethodCall): BaseEvent {
        val parser = AmplitudeFlutterPlugin::class.java.getDeclaredMethod("getEvent", MethodCall::class.java)
        parser.isAccessible = true
        return parser.invoke(AmplitudeFlutterPlugin(), call) as BaseEvent
    }
}
