import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'web/amplitude_js.dart';
import 'web/configuration_transform.dart';
import 'web/flutter_library_plugin.dart';
import 'constants.dart';

@JS()
external Amplitude get amplitude;

@JS('Object.defineProperty')
external void _jsDefineProperty(
    JSObject o, JSString property, JSObject descriptor);

class AmplitudeFlutterPlugin {
  Map<String, Amplitude> instances = {};
  Map<String, JSObject> detachedConnectivityPlugins = {};
  Map<String, void Function(bool)> offlineControllers = {};

  static void registerWith(Registrar registrar) {
    final channel = MethodChannel(
      'amplitude_flutter',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = AmplitudeFlutterPlugin();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (call.method == 'init') {
      var args = call.arguments;
      String apiKey = args['apiKey'];
      JSObject configuration = getConfiguration(call);
      String instanceName =
          args['instanceName'] ?? Constants.defaultInstanceName;
      bool initialOffline = args['offline'] == true;

      // Track and control offline state across SDK lifecycle
      bool manualOffline = initialOffline;
      bool currentOffline = initialOffline;

      void setOfflineState(bool offline) {
        manualOffline = offline;
        currentOffline = offline;
      }

      offlineControllers[instanceName] = setOfflineState;

      // Set library and install offline guard during plugin setup to prevent
      // Browser SDK network checker from overwriting manual offline mode during init
      Amplitude instance = amplitude.createInstance();
      instance.add(createJSInteropWrapper(FlutterLibraryPlugin(
        args['library'] ?? 'amplitude_flutter/unknown',
        onSetup: (JSObject config) {
          final descriptor = JSObject();
          descriptor.setProperty('configurable'.toJS, true.toJS);
          descriptor.setProperty('enumerable'.toJS, true.toJS);
          descriptor.setProperty(
              'get'.toJS, (() => currentOffline.toJS).toJS);
          descriptor.setProperty('set'.toJS, ((JSAny? val) {
            if (manualOffline) return;
            if (val != null && val is JSBoolean) {
              currentOffline = val.toDart;
            }
          }).toJS);
          _jsDefineProperty(config, 'offline'.toJS, descriptor);
        },
      )));

      await instance.init(apiKey, configuration).toDart;

      instances[instanceName] = instance;

      if (initialOffline) {
        applyOfflineMode(instanceName, instance, true);
      }

      return null;
    }

    Amplitude? instance = instances[
        call.arguments['instanceName'] ?? Constants.defaultInstanceName];

    if (instance == null) {
      throw Exception(
          'instance not found: ${call.arguments['instanceName'] ?? Constants.defaultInstanceName}');
    }

    switch (call.method) {
      case "track":
      case "identify":
      case "groupIdentify":
      case "setGroup":
      case "revenue":
        {
          JSObject event = getEvent(call);
          instance.track(event);
        }
      case "getUserId":
        {
          JSString? userId = instance.getUserId();
          if (userId == null) {
            return null;
          }
          return userId.toDart;
        }
      case "setUserId":
        {
          Map args = call.arguments['properties'];
          String? userId = args['setUserId'];
          instance.setUserId(userId?.toJS);
        }
      case "getDeviceId":
        {
          return instance.getDeviceId()?.toDart;
        }
      case "setDeviceId":
        {
          Map args = call.arguments['properties'];
          String? deviceId = args['setDeviceId'];
          instance.setDeviceId(deviceId?.toJS);
        }
      case "getSessionId":
        {
          return instance.getSessionId()?.toDartInt;
        }
      case "reset":
        {
          instance.reset();
        }
      case "flush":
        {
          instance.flush();
        }
      case "setOptOut":
        {
          Map args = call.arguments['properties'];
          bool enabled = args['setOptOut'];
          instance.setOptOut(enabled.toJS);
        }
      case "setOffline":
        {
          Map args = call.arguments['properties'];
          bool? offline = args['offline'];
          if (offline != null) {
            String instanceName =
                call.arguments['instanceName'] ?? Constants.defaultInstanceName;
            applyOfflineMode(instanceName, instance, offline);
          }
          return;
        }
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              "The amplitude_flutter plugin for web doesn't implement the method '${call.method}'",
        );
    }
  }

  /// Extracts an event from call.arguments and converts it to a JSObject representing an Event object.
  ///
  /// This method extracts event properties from the provided MethodCall argument
  /// and converts them into a JavaScript object representing an Event using the mapToJSObj method.
  ///
  /// Returns:
  /// - `JSObject`: A JavaScript object representing the event.
  JSObject getEvent(MethodCall call) {
    var eventMap = call.arguments['event'] as Map;
    return eventMap.jsify() as JSObject;
  }

  /// Maps the configuration settings for the Amplitude SDK to a JavaScript object.
  ///
  /// For more details on configuring the SDK, refer to the official documentation:
  /// https://amplitude.com/docs/sdks/analytics/browser/browser-sdk-2#configure-the-sdk
  ///
  /// The pure-Dart shaping (autocapture, logLevel, serverZone, defaultTracking)
  /// lives in [transformWebConfiguration] so it can be unit tested without the
  /// `chrome` platform; this method only handles the `jsify()` conversion.
  ///
  /// Returns a JavaScript object containing the configuration settings.
  JSObject getConfiguration(MethodCall call) {
    final configuration = Map<String, dynamic>.from(call.arguments as Map);
    return transformWebConfiguration(configuration).jsify() as JSObject;
  }

  /// Applies manual offline mode to a web Amplitude instance, ensuring
  /// automatic network listeners do not overwrite the forced offline state,
  /// and restoring the connectivity checker when returning online.
  void applyOfflineMode(
      String instanceName, Amplitude instance, bool offline) {
    const pluginName = '@amplitude/plugin-network-checker-browser';
    offlineControllers[instanceName]?.call(offline);
    if (offline) {
      final existingPlugin = instance.plugin(pluginName.toJS);
      if (existingPlugin != null) {
        detachedConnectivityPlugins[instanceName] = existingPlugin;
        instance.remove(pluginName.toJS);
      }
      final config = instance.getProperty('config'.toJS);
      if (config != null && config is JSObject) {
        config.setProperty('offline'.toJS, true.toJS);
      }
    } else {
      final detached = detachedConnectivityPlugins.remove(instanceName);
      if (detached != null) {
        instance.add(detached);
      }
      final config = instance.getProperty('config'.toJS);
      if (config != null && config is JSObject) {
        config.setProperty('offline'.toJS, false.toJS);
      }
      instance.flush();
    }
  }
}
