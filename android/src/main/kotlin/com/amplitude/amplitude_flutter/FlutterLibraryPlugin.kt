package com.amplitude.amplitude_flutter

import com.amplitude.core.Amplitude
import com.amplitude.core.events.BaseEvent
import com.amplitude.core.platform.Plugin

class FlutterLibraryPlugin(val library: String): Plugin {
    override val type: Plugin.Type = Plugin.Type.Before
    override lateinit var amplitude: Amplitude

    override fun execute(event: BaseEvent): BaseEvent? {
        event.library = library
        return super.execute(event)
    }
}
