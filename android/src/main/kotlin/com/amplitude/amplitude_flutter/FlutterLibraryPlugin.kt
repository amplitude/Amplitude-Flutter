package com.amplitude.amplitude_flutter

import com.amplitude.core.Amplitude
import com.amplitude.core.events.BaseEvent
import com.amplitude.core.platform.Plugin
import com.amplitude.amplitude_flutter.BuildConfig

class FlutterLibraryPlugin: Plugin {
    override val type: Plugin.Type = Plugin.Type.Before
    override lateinit var amplitude: Amplitude

    companion object {
        const val SDK_LIBRARY = "amplitude-flutter"
        const val SDK_VERSION = BuildConfig.SDK_VERSION
    }

    override fun execute(event: BaseEvent): BaseEvent? {
        event.library = "$SDK_LIBRARY/$SDK_VERSION"
        return super.execute(event)
    }
}
