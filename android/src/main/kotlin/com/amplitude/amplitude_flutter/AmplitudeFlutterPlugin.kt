package com.amplitude.amplitude_flutter

import android.app.Application
import android.content.Context
import com.amplitude.api.Amplitude
import com.amplitude.api.AmplitudeServerZone
import com.amplitude.api.Identify
import com.amplitude.api.Revenue
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

class AmplitudeFlutterPlugin : FlutterPlugin, MethodCallHandler {
    companion object {

        private const val methodChannelName = "amplitude_flutter"

        var ctxt: Context? = null

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
        val instanceName = json["instanceName"].toString()

        when (call.method) {
            "init" -> {
                val client = Amplitude.getInstance(instanceName)
                client.initialize(
                    ctxt, json.getString("apiKey"),
                    json.optString("userId", null)
                )
                val application = ctxt?.applicationContext
                if (application is Application) {
                    client.enableForegroundTracking(application)
                }

                result.success("Init success..")
            }
            // Get userId
            "getUserId" -> {
                val client = Amplitude.getInstance(instanceName)
                result.success(client.userId)
            }
            // Get deviceId
            "getDeviceId" -> {
                val client = Amplitude.getInstance(instanceName)
                val deviceId = client.getDeviceId()

                result.success(deviceId)
            }
            // Get sessionId
            "getSessionId" -> {
                val client = Amplitude.getInstance(instanceName)
                val sessionId = client.getSessionId()

                result.success(sessionId)
            }
            // Settings
            "enableCoppaControl" -> {
                val client = Amplitude.getInstance(instanceName)
                client.enableCoppaControl()

                result.success("enableCoppaControl called..")
            }
            "disableCoppaControl" -> {
                val client = Amplitude.getInstance(instanceName)
                client.disableCoppaControl()

                result.success("disableCoppaControl called..")
            }
            "setOptOut" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setOptOut(json.getBoolean("optOut"))

                result.success("setOptOut called..")
            }
            "setLibraryName" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setLibraryName(json.getString("libraryName"))

                result.success("setLibraryName called..")
            }
            "setLibraryVersion" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setLibraryVersion(json.getString("libraryVersion"))

                result.success("setLibraryVersion called..")
            }
            "setEventUploadThreshold" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setEventUploadThreshold(json.getInt("eventUploadThreshold"))

                result.success("setEventUploadThreshold called..")
            }
            "setEventUploadPeriodMillis" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setEventUploadPeriodMillis(json.getInt("eventUploadPeriodMillis"))

                result.success("setEventUploadPeriodMillis called..")
            }
            "trackingSessionEvents" -> {
                val client = Amplitude.getInstance(instanceName)
                client.trackSessionEvents(json.getBoolean("trackingSessionEvents"))

                result.success("trackingSessionEvents called..")
            }
            "setUseDynamicConfig" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setUseDynamicConfig(json.getBoolean("useDynamicConfig"))

                result.success("setUseDynamicConfig called..")
            }
            "setUserId" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setUserId(json.optString("userId", null), json.optBoolean("startNewSession", false))

                result.success("setUserId called..")
            }
            "setDeviceId" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setDeviceId(json.optString("deviceId", null))

                result.success("setDeviceId called..")
            }
            "setServerUrl" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setServerUrl(json.optString("serverUrl", null))

                result.success("setServerUrl called..")
            }

            // Regenerate new deviceId
            "regenerateDeviceId" -> {
                val client = Amplitude.getInstance(instanceName)
                client.regenerateDeviceId()
                result.success("regenerateDeviceId called..")
            }

            // Event logging
            "logEvent" -> {
                val client = Amplitude.getInstance(instanceName)
                client.logEvent(
                    json.getString("eventType"),
                    json.optJSONObject("eventProperties"),
                    json.optBoolean("outOfSession", false)
                )

                result.success("logEvent called..")
            }
            "logRevenue" -> {
                val client = Amplitude.getInstance(instanceName)
                val revenue = Revenue().setProductId(json.getString("productIdentifier"))
                    .setPrice(json.getDouble("price"))
                    .setQuantity(json.getInt("quantity"))
                client.logRevenueV2(revenue)

                result.success("logRevenue called..")
            }
            "logRevenueAmount" -> {
                val client = Amplitude.getInstance(instanceName)
                val revenue = Revenue().setPrice(json.getDouble("amount"))
                client.logRevenueV2(revenue)

                result.success("logRevenueAmount called..")
            }
            "identify" -> {
                val client = Amplitude.getInstance(instanceName)
                val identify = createIdentify(json.getJSONObject("userProperties"))
                client.identify(identify)

                result.success("identify called..")
            }
            "setGroup" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setGroup(json.getString("groupType"), json.get("groupName"))

                result.success("identify called..")
            }
            "groupIdentify" -> {
                val client = Amplitude.getInstance(instanceName)
                val identify = createIdentify(json.getJSONObject("userProperties"))
                client.groupIdentify(
                    json.getString("groupType"),
                    json.getString("groupName"),
                    identify,
                    json.optBoolean("outOfSession", false)
                )

                result.success("identify called..")
            }
            "setUserProperties" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setUserProperties(json.getJSONObject("userProperties"))

                result.success("setUserProperties called..")
            }
            "clearUserProperties" -> {
                val client = Amplitude.getInstance(instanceName)
                client.clearUserProperties()

                result.success("clearUserProperties called..")
            }
            "uploadEvents" -> {
                val client = Amplitude.getInstance(instanceName)
                client.uploadEvents()

                result.success("uploadEvents called..")
            }

            "useAppSetIdForDeviceId" -> {
                val client = Amplitude.getInstance(instanceName)
                client.useAppSetIdForDeviceId()

                result.success("useAppSetIdForDeviceId called..")
            }

            "setMinTimeBetweenSessionsMillis" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setMinTimeBetweenSessionsMillis(json.getLong("timeInMillis"))
                result.success("setMinTimeBetweenSessionsMillis called..")
            }

            "setServerZone" -> {
                val client = Amplitude.getInstance(instanceName)
                val serverZone = json.getString("serverZone")
                val amplitudeServerZone = if (serverZone == "EU") AmplitudeServerZone.EU else AmplitudeServerZone.US
                client.setServerZone(amplitudeServerZone, json.getBoolean("updateServerUrl"))

                result.success("setServerZone called..")
            }

            "setOffline" -> {
                val client = Amplitude.getInstance(instanceName)
                client.setOffline(json.getBoolean("offline"))

                result.success("setOffline called..")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun createIdentify(userProperties: JSONObject): Identify {
        var identify = Identify()

        for (operation in userProperties.keys()) {
            val properties = userProperties.getJSONObject(operation)
            for (key in properties.keys()) {
                when (operation) {
                    // ADD
                    "\$add" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.add(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.add(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.add(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.add(key, properties.getString(key))
                            }
                            is JSONObject -> {
                                identify.add(key, properties.getJSONObject(key))
                            }
                        }
                    }

                    // APPEND
                    "\$append" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.append(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.append(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.append(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.append(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.append(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.append(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.prepend(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // REMOVE
                    "\$remove" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.remove(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.remove(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.remove(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.remove(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.remove(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.remove(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.remove(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // PREPEND
                    "\$prepend" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.prepend(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.prepend(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.prepend(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.prepend(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.prepend(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.prepend(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.prepend(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // SET
                    "\$set" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.set(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.set(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.set(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.set(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.set(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.set(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.set(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // SETONCE
                    "\$setOnce" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.setOnce(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.setOnce(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.setOnce(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.setOnce(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.setOnce(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.setOnce(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.setOnce(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // PREINSERT
                    "\$preInsert" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.preInsert(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.preInsert(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.preInsert(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.preInsert(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.preInsert(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.preInsert(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.preInsert(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // POSTINSERT
                    "\$postInsert" -> {
                        when (properties.get(key)) {
                            is Int -> {
                                identify.postInsert(key, properties.getInt(key))
                            }
                            is Long -> {
                                identify.postInsert(key, properties.getLong(key))
                            }
                            is Double -> {
                                identify.postInsert(key, properties.getDouble(key))
                            }
                            is String -> {
                                identify.postInsert(key, properties.getString(key))
                            }
                            is Boolean -> {
                                identify.postInsert(key, properties.getBoolean(key))
                            }
                            is JSONObject -> {
                                identify.postInsert(key, properties.getJSONObject(key))
                            }
                            is JSONArray -> {
                                identify.postInsert(key, properties.getJSONArray(key))
                            }
                        }
                    }

                    // UNSET
                    "\$unset" -> {
                        identify.unset(key)
                    }

                    // CLEARALL
                    "\$clearAll" -> {
                        identify.clearAll()
                    }
                }
            }
        }

        return identify
    }
}
