#include "amplitude_flutter_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

namespace amplitude_flutter {

namespace {

nlohmann::json EncodableValueToJson(const flutter::EncodableValue& v);

nlohmann::json EncodableMapToJson(const flutter::EncodableMap& map) {
  nlohmann::json obj = nlohmann::json::object();
  for (const auto& [k, v] : map) {
    if (!std::holds_alternative<std::string>(k)) continue;
    obj[std::get<std::string>(k)] = EncodableValueToJson(v);
  }
  return obj;
}

nlohmann::json EncodableValueToJson(const flutter::EncodableValue& v) {
  if (std::holds_alternative<std::monostate>(v)) return nullptr;
  if (std::holds_alternative<bool>(v)) return std::get<bool>(v);
  if (std::holds_alternative<int32_t>(v)) return std::get<int32_t>(v);
  if (std::holds_alternative<int64_t>(v)) return std::get<int64_t>(v);
  if (std::holds_alternative<double>(v)) return std::get<double>(v);
  if (std::holds_alternative<std::string>(v)) return std::get<std::string>(v);
  if (std::holds_alternative<flutter::EncodableList>(v)) {
    nlohmann::json arr = nlohmann::json::array();
    for (const auto& item : std::get<flutter::EncodableList>(v)) {
      arr.push_back(EncodableValueToJson(item));
    }
    return arr;
  }
  if (std::holds_alternative<flutter::EncodableMap>(v)) {
    return EncodableMapToJson(std::get<flutter::EncodableMap>(v));
  }
  return nullptr;
}

}  // namespace

// static
void AmplitudeFlutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "amplitude_flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AmplitudeFlutterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_ptr = plugin.get()](const auto& call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  // Register window message handler for lifecycle detection
  auto* windows_registrar =
      static_cast<flutter::PluginRegistrarWindows*>(registrar);
  plugin->window_proc_id_ =
      windows_registrar->RegisterTopLevelWindowProcDelegate(
          [plugin_ptr = plugin.get()](HWND hwnd, UINT message, WPARAM wparam,
                                      LPARAM lparam) {
            return plugin_ptr->HandleWindowMessage(hwnd, message, wparam,
                                                    lparam);
          });

  registrar->AddPlugin(std::move(plugin));
}

AmplitudeFlutterPlugin::AmplitudeFlutterPlugin() = default;
AmplitudeFlutterPlugin::~AmplitudeFlutterPlugin() = default;

std::optional<LRESULT> AmplitudeFlutterPlugin::HandleWindowMessage(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_ACTIVATEAPP) {
    bool activated = (wparam != 0);
    for (auto& [name, instance] : instances_) {
      if (activated) {
        instance->OnAppLifecycleResumed();
      } else {
        instance->OnAppLifecyclePaused();
      }
    }
  }
  return std::nullopt;  // Don't consume the message
}

void AmplitudeFlutterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  // --- init ---
  if (method == "init") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "init requires a map argument");
      return;
    }

    auto config_json = EncodableMapToJson(*args);
    auto config = AmplitudeInstance::ParseConfiguration(config_json);
    if (config.api_key.empty()) {
      result->Error("MISSING_API_KEY", "apiKey is required");
      return;
    }

    auto instance = std::make_shared<AmplitudeInstance>(config);
    instances_[config.instance_name] = instance;

    result->Success(flutter::EncodableValue("init called.."));
    return;
  }

  // For all other methods, look up the instance
  const auto* args =
      std::get_if<flutter::EncodableMap>(method_call.arguments());
  std::string instance_name = "$default_instance";
  if (args) {
    auto it = args->find(flutter::EncodableValue("instanceName"));
    if (it != args->end() &&
        std::holds_alternative<std::string>(it->second)) {
      instance_name = std::get<std::string>(it->second);
    }
  }

  auto inst_it = instances_.find(instance_name);
  if (inst_it == instances_.end()) {
    result->Error("NOT_INITIALIZED",
                  "Amplitude instance not found: " + instance_name);
    return;
  }
  auto& instance = inst_it->second;

  // --- track, identify, groupIdentify, setGroup, revenue ---
  if (method == "track" || method == "identify" ||
      method == "groupIdentify" || method == "setGroup" ||
      method == "revenue") {
    if (!args) {
      result->Error("INVALID_ARGS", method + " requires a map argument");
      return;
    }
    auto event_it = args->find(flutter::EncodableValue("event"));
    if (event_it == args->end() ||
        !std::holds_alternative<flutter::EncodableMap>(event_it->second)) {
      result->Error("INVALID_ARGS", method + " requires an 'event' map");
      return;
    }
    nlohmann::json event =
        EncodableMapToJson(std::get<flutter::EncodableMap>(event_it->second));
    instance->Track(event);
    result->Success(flutter::EncodableValue(method + " called.."));
    return;
  }

  // --- getUserId ---
  if (method == "getUserId") {
    auto uid = instance->GetUserId();
    if (uid.empty()) {
      result->Success(flutter::EncodableValue(std::monostate{}));
    } else {
      result->Success(flutter::EncodableValue(uid));
    }
    return;
  }

  // --- setUserId ---
  if (method == "setUserId") {
    if (args) {
      auto props_it = args->find(flutter::EncodableValue("properties"));
      if (props_it != args->end() &&
          std::holds_alternative<flutter::EncodableMap>(props_it->second)) {
        const auto& props =
            std::get<flutter::EncodableMap>(props_it->second);
        auto uid_it = props.find(flutter::EncodableValue("setUserId"));
        if (uid_it != props.end()) {
          if (std::holds_alternative<std::monostate>(uid_it->second)) {
            instance->SetUserId(nullptr);
          } else if (std::holds_alternative<std::string>(uid_it->second)) {
            std::string uid = std::get<std::string>(uid_it->second);
            instance->SetUserId(&uid);
          }
        }
      }
    }
    result->Success(flutter::EncodableValue("setUserId called.."));
    return;
  }

  // --- getDeviceId ---
  if (method == "getDeviceId") {
    auto did = instance->GetDeviceId();
    if (did.empty()) {
      result->Success(flutter::EncodableValue(std::monostate{}));
    } else {
      result->Success(flutter::EncodableValue(did));
    }
    return;
  }

  // --- setDeviceId ---
  if (method == "setDeviceId") {
    if (args) {
      auto props_it = args->find(flutter::EncodableValue("properties"));
      if (props_it != args->end() &&
          std::holds_alternative<flutter::EncodableMap>(props_it->second)) {
        const auto& props =
            std::get<flutter::EncodableMap>(props_it->second);
        auto did_it = props.find(flutter::EncodableValue("setDeviceId"));
        if (did_it != props.end()) {
          if (std::holds_alternative<std::monostate>(did_it->second)) {
            instance->SetDeviceId(nullptr);
          } else if (std::holds_alternative<std::string>(did_it->second)) {
            std::string did = std::get<std::string>(did_it->second);
            instance->SetDeviceId(&did);
          }
        }
      }
    }
    result->Success(flutter::EncodableValue("setDeviceId called.."));
    return;
  }

  // --- getSessionId ---
  if (method == "getSessionId") {
    result->Success(flutter::EncodableValue(instance->GetSessionId()));
    return;
  }

  // --- reset ---
  if (method == "reset") {
    instance->Reset();
    result->Success(flutter::EncodableValue("reset called.."));
    return;
  }

  // --- flush ---
  if (method == "flush") {
    instance->Flush();
    result->Success(flutter::EncodableValue("flush called.."));
    return;
  }

  // --- setOptOut ---
  if (method == "setOptOut") {
    if (args) {
      auto props_it = args->find(flutter::EncodableValue("properties"));
      if (props_it != args->end() &&
          std::holds_alternative<flutter::EncodableMap>(props_it->second)) {
        const auto& props =
            std::get<flutter::EncodableMap>(props_it->second);
        auto opt_it = props.find(flutter::EncodableValue("setOptOut"));
        if (opt_it != props.end() &&
            std::holds_alternative<bool>(opt_it->second)) {
          instance->SetOptOut(std::get<bool>(opt_it->second));
        }
      }
    }
    result->Success(flutter::EncodableValue("setOptOut called.."));
    return;
  }

  result->NotImplemented();
}

}  // namespace amplitude_flutter
