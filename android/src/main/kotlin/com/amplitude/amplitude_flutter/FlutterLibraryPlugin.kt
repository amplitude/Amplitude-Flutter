package com.amplitude.amplitude_flutter

import com.amplitude.core.Amplitude
import com.amplitude.core.events.BaseEvent
import com.amplitude.core.platform.Plugin

class FlutterLibraryPlugin(val library: String): Plugin {
    override val type: Plugin.Type = Plugin.Type.Enrichment
    override lateinit var amplitude: Amplitude

    override fun execute(event: BaseEvent): BaseEvent? {
        if (event.library == null) {
            event.library = library
        } else {
            event.library = "${library}_${event.library}"
        }
        return super.execute(event)
    }
}
