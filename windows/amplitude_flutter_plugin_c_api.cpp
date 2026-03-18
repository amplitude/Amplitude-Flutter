#include "include/amplitude_flutter/amplitude_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "amplitude_flutter_plugin.h"

void AmplitudeFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  amplitude_flutter::AmplitudeFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
