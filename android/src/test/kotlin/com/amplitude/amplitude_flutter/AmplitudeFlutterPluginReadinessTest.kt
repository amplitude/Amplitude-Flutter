package com.amplitude.amplitude_flutter

import android.os.Looper
import com.amplitude.android.Amplitude
import com.amplitude.common.Logger
import com.amplitude.core.events.BaseEvent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode
import kotlin.concurrent.thread

@Config(manifest = Config.NONE, sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
@RunWith(RobolectricTestRunner::class)
class AmplitudeFlutterPluginReadinessTest {
    private val instanceName = "readiness-test"
    private lateinit var plugin: AmplitudeFlutterPlugin
    private lateinit var amplitude: Amplitude
    private lateinit var nativeBuild: CompletableDeferred<Boolean>

    @Before
    fun setup() {
        plugin = AmplitudeFlutterPlugin()
        amplitude = mockk(relaxed = true)
        nativeBuild = CompletableDeferred()
        every { amplitude.isBuilt } returns nativeBuild
        every { amplitude.logger } returns mockk<Logger>(relaxed = true)
        // Exercise the real method handler while controlling only SDK completion.
        // Avoid configuration, persistence, and network work unrelated to the barrier.
        AmplitudeFlutterPlugin::class.java.getDeclaredField("instances").apply {
            isAccessible = true
            set(plugin, mapOf(instanceName to amplitude))
        }
    }

    @Test
    fun `awaitBuild remains pending while track submits directly`() {
        val readiness = awaitBuild()
        idleMain()
        assertTrue(readiness.replies.isEmpty())

        val track = RecordingResult()
        plugin.onMethodCall(MethodCall("track", mapOf(
            "instanceName" to instanceName,
            "event" to mapOf("event_type" to "early-event"),
        )), track)
        assertEquals("track called..", track.replies.single().value)
        verify(exactly = 1) { amplitude.track(match<BaseEvent> { it.eventType == "early-event" }) }
        idleMain()
        assertTrue(readiness.replies.isEmpty())
        assertFalse(nativeBuild.isCompleted)
    }

    @Test
    fun `successful worker completion replies once on main`() {
        val result = awaitBuild()
        onWorker { nativeBuild.complete(true) }
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertSuccess(result)
        onWorker { nativeBuild.complete(true) }
        idleMain()
        assertSuccess(result)
    }

    @Test
    fun `exceptional worker completion replies once on main`() {
        val result = awaitBuild()
        onWorker { nativeBuild.completeExceptionally(IllegalStateException("native build failed")) }
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertError(result, "native build failed")
        idleMain()
        assertError(result, "native build failed")
    }

    @Test
    fun `cancelled worker completion replies once on main`() {
        val result = awaitBuild()
        onWorker { nativeBuild.cancel(CancellationException("native build cancelled")) }
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertError(result, "native build cancelled")
        idleMain()
        assertError(result, "native build cancelled")
    }

    @Test
    fun `already successful build still posts one main reply`() {
        nativeBuild.complete(true)
        val result = awaitBuild()
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertSuccess(result)
        idleMain()
        assertSuccess(result)
    }

    @Test
    fun `already failed build still posts one main error`() {
        nativeBuild.completeExceptionally(IllegalStateException("already failed"))
        val result = awaitBuild()
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertError(result, "already failed")
        idleMain()
        assertError(result, "already failed")
    }

    @Test
    fun `already cancelled build still posts one main error`() {
        nativeBuild.cancel(CancellationException("already cancelled"))
        val result = awaitBuild()
        assertTrue(result.replies.isEmpty())
        idleMain()
        assertError(result, "already cancelled")
        idleMain()
        assertError(result, "already cancelled")
    }

    @Test
    fun `two readiness requests each receive one reply`() {
        val first = awaitBuild()
        val second = awaitBuild()
        onWorker { nativeBuild.complete(true) }
        idleMain()
        assertSuccess(first)
        assertSuccess(second)
        idleMain()
        assertSuccess(first)
        assertSuccess(second)
    }

    @Test
    fun `failed readiness does not unregister the native instance`() {
        val readiness = awaitBuild()
        nativeBuild.completeExceptionally(IllegalStateException("native build failed"))
        idleMain()
        assertError(readiness, "native build failed")
        val track = RecordingResult()
        plugin.onMethodCall(MethodCall("track", mapOf(
            "instanceName" to instanceName,
            "event" to mapOf("event_type" to "after-failure"),
        )), track)
        assertEquals("track called..", track.replies.single().value)
        verify(exactly = 1) { amplitude.track(match<BaseEvent> { it.eventType == "after-failure" }) }
    }

    private fun awaitBuild(): RecordingResult = RecordingResult().also {
        plugin.onMethodCall(MethodCall("awaitBuild", mapOf("instanceName" to instanceName)), it)
    }

    private fun idleMain() = shadowOf(Looper.getMainLooper()).idle()

    private fun onWorker(action: () -> Unit) {
        val worker = thread(name = "native-build-completion", block = action)
        worker.join(5000)
        assertFalse("Completion worker must finish", worker.isAlive)
    }

    private fun assertSuccess(result: RecordingResult) {
        assertEquals(1, result.replies.size)
        val reply = result.replies.single()
        assertEquals("success", reply.kind)
        assertEquals(true, reply.value)
        assertTrue("Reply must be on Android's main looper", reply.onMain)
    }

    private fun assertError(result: RecordingResult, cause: String) {
        assertEquals(1, result.replies.size)
        val reply = result.replies.single()
        assertEquals("error", reply.kind)
        assertEquals("amplitude_init_failed", reply.code)
        assertEquals("Amplitude initialization failed.", reply.message)
        assertTrue(reply.value.toString().contains(cause))
        assertTrue("Reply must be on Android's main looper", reply.onMain)
    }

    private data class Reply(val kind: String, val value: Any?, val code: String? = null,
        val message: String? = null, val onMain: Boolean = Looper.myLooper() == Looper.getMainLooper())

    private class RecordingResult : MethodChannel.Result {
        val replies = mutableListOf<Reply>()
        override fun success(result: Any?) { replies.add(Reply("success", result)) }
        override fun error(code: String, message: String?, details: Any?) {
            replies.add(Reply("error", details, code, message))
        }
        override fun notImplemented() { replies.add(Reply("notImplemented", null)) }
    }
}
