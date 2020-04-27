package com.amplitude.amplitude_flutter

import android.content.Context
import com.amplitude.api.Amplitude
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.json.JSONObject

class AmplitudeFlutterPlugin : MethodCallHandler {
    companion object {
        var ctxt: Context? = null

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            ctxt = registrar.context()
            val channel = MethodChannel(registrar.messenger(), "amplitude_flutter")
            channel.setMethodCallHandler(AmplitudeFlutterPlugin())
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val json = JSONObject(call.arguments.toString())

        if (call.method == "init") {
            val client = Amplitude.getInstance(json["instanceName"].toString())
            client.initialize(ctxt, json["apiKey"].toString(), json["userId"]?.toString())

            result.success("Init success..")
        } else if (call.method == "logEvent") {
            val client = Amplitude.getInstance(json["instanceName"].toString())
            client.logEvent(json["eventType"].toString())
            result.success("Identify success..")
        } else {
            // TODO
            result.success("No such method call..")
        }
    }
}
