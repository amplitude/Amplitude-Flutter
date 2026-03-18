#include "amplitude_instance.h"

#include <chrono>

#include "uuid.h"

namespace amplitude_flutter {

namespace {

std::string GetString(const nlohmann::json& obj, const std::string& key,
                      const std::string& def = "") {
  if (obj.contains(key) && obj[key].is_string()) {
    return obj[key].get<std::string>();
  }
  return def;
}

int GetInt(const nlohmann::json& obj, const std::string& key, int def = 0) {
  if (obj.contains(key) && obj[key].is_number()) {
    return obj[key].get<int>();
  }
  return def;
}

bool GetBool(const nlohmann::json& obj, const std::string& key,
             bool def = false) {
  if (obj.contains(key) && obj[key].is_boolean()) {
    return obj[key].get<bool>();
  }
  return def;
}

}  // namespace

AmplitudeInstance::AmplitudeInstance(const Configuration& config)
    : config_(config), device_info_(DeviceInfo::Collect()) {
  std::string url = config_.server_url;
  if (url.empty()) {
    url = HttpTransport::DefaultUrl(config_.server_zone, config_.use_batch);
  }

  storage_ = std::make_shared<Storage>(config_.instance_name);
  transport_ = std::make_shared<HttpTransport>(
      config_.api_key, url, config_.use_batch, config_.flush_max_retries,
      stopping_);

  LoadIdentity();

  if (device_id_.empty()) {
    device_id_ = GenerateUUID();
  }

  // Decide whether to resume the previous session or start a new one
  int64_t now = CurrentTimeMillis();
  bool need_new_session =
      (session_id_ <= 0) || (last_event_time_ <= 0) ||
      (now - last_event_time_) > config_.min_time_between_sessions_millis;

  if (need_new_session) {
    session_id_ = now;
  }
  last_event_time_ = now;
  PersistIdentity();

  event_queue_ = std::make_unique<EventQueue>(
      storage_, transport_, config_.flush_queue_size,
      config_.flush_interval_millis);

  if (!config_.opt_out) {
    if (config_.default_tracking_sessions && need_new_session) {
      TrackSessionStart();
    }

    if (config_.default_tracking_app_lifecycles) {
      nlohmann::json event;
      event["event_type"] = "[Amplitude] Application Opened";
      event["event_properties"] = nlohmann::json::object();
      event["event_properties"]["from_background"] = false;
      TrackInternal(event);
    }
  }
}

AmplitudeInstance::~AmplitudeInstance() {
  stopping_ = true;
  if (!config_.opt_out && config_.default_tracking_sessions) {
    TrackSessionEnd(CurrentTimeMillis());
  }
  if (event_queue_) {
    event_queue_->Stop();
  }
}

void AmplitudeInstance::Track(const nlohmann::json& event) {
  if (config_.opt_out) return;

  nlohmann::json enriched = event;
  int64_t now = CurrentTimeMillis();

  if (config_.default_tracking_sessions &&
      (now - last_event_time_) > config_.min_time_between_sessions_millis) {
    TrackSessionEnd(last_event_time_);
    session_id_ = now;
    TrackSessionStart();
    last_event_time_ = now;
    PersistIdentity();
  } else {
    last_event_time_ = now;
  }

  EnrichEvent(enriched);
  event_queue_->Push(enriched);
}

void AmplitudeInstance::TrackInternal(const nlohmann::json& event) {
  if (config_.opt_out) return;

  nlohmann::json enriched = event;
  EnrichEvent(enriched);
  event_queue_->Push(enriched);
}

void AmplitudeInstance::TrackSessionStart() {
  nlohmann::json event;
  event["event_type"] = "[Amplitude] Start Session";
  event["session_id"] = session_id_;
  event["time"] = session_id_;  // Session start time = session_id
  TrackInternal(event);
}

void AmplitudeInstance::TrackSessionEnd(int64_t timestamp) {
  nlohmann::json event;
  event["event_type"] = "[Amplitude] End Session";
  event["session_id"] = session_id_;
  event["time"] = timestamp;
  TrackInternal(event);
}

void AmplitudeInstance::Flush() {
  event_queue_->Flush();
}

std::string AmplitudeInstance::GetUserId() const { return user_id_; }

void AmplitudeInstance::SetUserId(const std::string* user_id) {
  user_id_ = user_id ? *user_id : "";
  PersistIdentity();
}

std::string AmplitudeInstance::GetDeviceId() const { return device_id_; }

void AmplitudeInstance::SetDeviceId(const std::string* device_id) {
  if (device_id && !device_id->empty()) {
    device_id_ = *device_id;
  } else {
    device_id_ = GenerateUUID();
  }
  PersistIdentity();
}

int64_t AmplitudeInstance::GetSessionId() const { return session_id_; }

void AmplitudeInstance::Reset() {
  user_id_.clear();
  device_id_ = GenerateUUID();
  PersistIdentity();
}

void AmplitudeInstance::SetOptOut(bool opt_out) { config_.opt_out = opt_out; }

void AmplitudeInstance::OnAppLifecycleResumed() {
  int64_t now = CurrentTimeMillis();

  if (config_.default_tracking_sessions &&
      (now - last_event_time_) > config_.min_time_between_sessions_millis) {
    TrackSessionEnd(last_event_time_);
    session_id_ = now;
    TrackSessionStart();
  }
  last_event_time_ = now;
  PersistIdentity();

  if (config_.default_tracking_app_lifecycles) {
    nlohmann::json event;
    event["event_type"] = "[Amplitude] Application Opened";
    event["event_properties"] = nlohmann::json::object();
    event["event_properties"]["from_background"] = true;
    TrackInternal(event);
  }
}

void AmplitudeInstance::OnAppLifecyclePaused() {
  if (config_.default_tracking_app_lifecycles) {
    nlohmann::json event;
    event["event_type"] = "[Amplitude] Application Backgrounded";
    TrackInternal(event);
  }

  if (config_.default_tracking_sessions) {
    last_event_time_ = CurrentTimeMillis();
    PersistIdentity();
  }

  if (config_.flush_events_on_close) {
    event_queue_->Flush();
  }
}

Configuration AmplitudeInstance::ParseConfiguration(
    const nlohmann::json& args) {
  Configuration config;
  config.api_key = GetString(args, "apiKey");
  config.instance_name = GetString(args, "instanceName", "$default_instance");
  config.flush_queue_size = GetInt(args, "flushQueueSize", 30);
  config.flush_interval_millis = GetInt(args, "flushIntervalMillis", 30000);
  config.flush_max_retries = GetInt(args, "flushMaxRetries", 5);
  config.opt_out = GetBool(args, "optOut", false);
  config.use_batch = GetBool(args, "useBatch", false);
  config.server_zone = GetString(args, "serverZone", "US");
  config.server_url = GetString(args, "serverUrl");
  config.min_time_between_sessions_millis =
      GetInt(args, "minTimeBetweenSessionsMillis", 300000);
  config.library = GetString(args, "library", "amplitude-flutter/unknown");
  config.min_id_length = GetInt(args, "minIdLength", 0);
  config.partner_id = GetString(args, "partnerId");
  config.flush_events_on_close = GetBool(args, "flushEventsOnClose", true);
  config.enable_coppa_control = GetBool(args, "enableCoppaControl", false);

  if (args.contains("defaultTracking") &&
      args["defaultTracking"].is_object()) {
    const auto& dt = args["defaultTracking"];
    config.default_tracking_sessions = GetBool(dt, "sessions", true);
    config.default_tracking_app_lifecycles =
        GetBool(dt, "appLifecycles", false);
  }

  if (args.contains("trackingOptions") &&
      args["trackingOptions"].is_object()) {
    const auto& to = args["trackingOptions"];
    config.track_ip_address = GetBool(to, "ipAddress", true);
    config.track_language = GetBool(to, "language", true);
    config.track_platform = GetBool(to, "platform", true);
    config.track_region = GetBool(to, "region", true);
    config.track_dma = GetBool(to, "dma", true);
    config.track_country = GetBool(to, "country", true);
    config.track_city = GetBool(to, "city", true);
    config.track_carrier = GetBool(to, "carrier", true);
    config.track_device_model = GetBool(to, "deviceModel", true);
    config.track_device_manufacturer =
        GetBool(to, "deviceManufacturer", true);
    config.track_os_version = GetBool(to, "osVersion", true);
    config.track_os_name = GetBool(to, "osName", true);
    config.track_version_name = GetBool(to, "versionName", true);
  }

  // COPPA: disable tracking of IP and location-related fields
  if (config.enable_coppa_control) {
    config.track_ip_address = false;
    config.track_city = false;
    config.track_dma = false;
    config.track_region = false;
    config.track_country = false;
  }

  return config;
}

void AmplitudeInstance::EnrichEvent(nlohmann::json& event) {
  if (!event.contains("device_id") || event["device_id"].is_null()) {
    event["device_id"] = device_id_;
  }
  if (!user_id_.empty() &&
      (!event.contains("user_id") || event["user_id"].is_null())) {
    event["user_id"] = user_id_;
  }

  if (!event.contains("time") || event["time"].is_null()) {
    if (event.contains("timestamp") && event["timestamp"].is_number()) {
      event["time"] = event["timestamp"];
    } else {
      event["time"] = CurrentTimeMillis();
    }
  }

  if (!event.contains("session_id") || event["session_id"].is_null()) {
    event["session_id"] = session_id_;
  }

  if (!event.contains("insert_id") || event["insert_id"].is_null()) {
    event["insert_id"] = GenerateInsertId();
  }

  // Device info (all 7 coupled fields must be set together)
  if (config_.track_platform) {
    if (!event.contains("platform") || event["platform"].is_null())
      event["platform"] = "Windows";
  }
  if (config_.track_os_name) {
    if (!event.contains("os_name") || event["os_name"].is_null())
      event["os_name"] = device_info_.os_name;
  }
  if (config_.track_os_version) {
    if (!event.contains("os_version") || event["os_version"].is_null())
      event["os_version"] = device_info_.os_version;
  }
  if (config_.track_device_manufacturer) {
    if (!event.contains("device_manufacturer") ||
        event["device_manufacturer"].is_null())
      event["device_manufacturer"] = device_info_.device_manufacturer;
  }
  if (config_.track_device_model) {
    if (!event.contains("device_model") || event["device_model"].is_null())
      event["device_model"] = device_info_.device_model;
  }
  if (config_.track_device_manufacturer) {
    if (!event.contains("device_brand") || event["device_brand"].is_null())
      event["device_brand"] = device_info_.device_brand;
  }
  if (config_.track_carrier) {
    if (!event.contains("carrier") || event["carrier"].is_null())
      event["carrier"] = device_info_.carrier;
  }
  if (config_.track_language) {
    if (!event.contains("language") || event["language"].is_null())
      event["language"] = device_info_.language;
  }

  // Library enrichment
  if (event.contains("library") && event["library"].is_string() &&
      !event["library"].get<std::string>().empty()) {
    event["library"] =
        config_.library + "_" + event["library"].get<std::string>();
  } else {
    event["library"] = config_.library;
  }

  if (!config_.partner_id.empty() &&
      (!event.contains("partner_id") || event["partner_id"].is_null())) {
    event["partner_id"] = config_.partner_id;
  }

  if (config_.enable_coppa_control) {
    event["ip"] = "$none";
  }
}

void AmplitudeInstance::PersistIdentity() {
  nlohmann::json identity;
  identity["device_id"] = device_id_;
  identity["user_id"] = user_id_;
  identity["session_id"] = session_id_;
  identity["last_event_time"] = last_event_time_;
  storage_->SaveIdentity(identity);
}

void AmplitudeInstance::LoadIdentity() {
  auto identity = storage_->LoadIdentity();
  if (identity.contains("device_id") && identity["device_id"].is_string()) {
    device_id_ = identity["device_id"].get<std::string>();
  }
  if (identity.contains("user_id") && identity["user_id"].is_string()) {
    user_id_ = identity["user_id"].get<std::string>();
  }
  if (identity.contains("session_id") && identity["session_id"].is_number()) {
    session_id_ = identity["session_id"].get<int64_t>();
  }
  if (identity.contains("last_event_time") &&
      identity["last_event_time"].is_number()) {
    last_event_time_ = identity["last_event_time"].get<int64_t>();
  }
}

int64_t AmplitudeInstance::CurrentTimeMillis() const {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

}  // namespace amplitude_flutter
