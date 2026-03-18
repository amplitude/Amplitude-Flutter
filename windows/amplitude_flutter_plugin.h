#ifndef FLUTTER_PLUGIN_AMPLITUDE_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_AMPLITUDE_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>

#include "amplitude_instance.h"

namespace amplitude_flutter {

class AmplitudeFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

  AmplitudeFlutterPlugin();
  virtual ~AmplitudeFlutterPlugin();

  AmplitudeFlutterPlugin(const AmplitudeFlutterPlugin&) = delete;
  AmplitudeFlutterPlugin& operator=(const AmplitudeFlutterPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Window procedure delegate for lifecycle detection
  std::optional<LRESULT> HandleWindowMessage(HWND hwnd, UINT message,
                                              WPARAM wparam, LPARAM lparam);

  std::unordered_map<std::string, std::shared_ptr<AmplitudeInstance>>
      instances_;

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  int window_proc_id_ = -1;
};

}  // namespace amplitude_flutter

#endif  // FLUTTER_PLUGIN_AMPLITUDE_FLUTTER_PLUGIN_H_
