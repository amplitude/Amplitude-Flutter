#ifndef AMPLITUDE_FLUTTER_AMPLITUDE_INSTANCE_H_
#define AMPLITUDE_FLUTTER_AMPLITUDE_INSTANCE_H_

#include <memory>
#include <nlohmann/json.hpp>
#include <string>

#include "device_info.h"
#include "event_queue.h"
#include "http_transport.h"
#include "storage.h"

namespace amplitude_flutter {

struct Configuration {
  std::string api_key;
  std::string instance_name = "$default_instance";
  int flush_queue_size = 30;
  int flush_interval_millis = 30000;
  int flush_max_retries = 5;
  bool opt_out = false;
  bool use_batch = false;
  std::string server_zone = "US";
  std::string server_url;
  int min_time_between_sessions_millis = 300000;  // 5 minutes
  std::string library = "amplitude-flutter/unknown";
  int min_id_length = 0;
  std::string partner_id;
  bool default_tracking_sessions = true;
  bool default_tracking_app_lifecycles = false;
  bool flush_events_on_close = true;
  bool enable_coppa_control = false;

  // Tracking options (which fields to track). True = track.
  bool track_ip_address = true;
  bool track_language = true;
  bool track_platform = true;
  bool track_region = true;
  bool track_dma = true;
  bool track_country = true;
  bool track_city = true;
  bool track_carrier = true;
  bool track_device_model = true;
  bool track_device_manufacturer = true;
  bool track_os_version = true;
  bool track_os_name = true;
  bool track_version_name = true;
};

class AmplitudeInstance {
 public:
  explicit AmplitudeInstance(const Configuration& config);
  ~AmplitudeInstance();

  void Track(const nlohmann::json& event);
  void Flush();

  std::string GetUserId() const;
  void SetUserId(const std::string* user_id);  // nullptr to clear

  std::string GetDeviceId() const;
  void SetDeviceId(const std::string* device_id);  // nullptr to clear

  int64_t GetSessionId() const;

  void Reset();
  void SetOptOut(bool opt_out);

  // App lifecycle hooks (called from plugin when Flutter notifies)
  void OnAppLifecycleResumed();
  void OnAppLifecyclePaused();

  static Configuration ParseConfiguration(const nlohmann::json& args);

 private:
  Configuration config_;
  DeviceInfo device_info_;
  std::shared_ptr<Storage> storage_;
  std::shared_ptr<HttpTransport> transport_;
  std::unique_ptr<EventQueue> event_queue_;

  std::string user_id_;
  std::string device_id_;
  int64_t session_id_ = -1;
  int64_t last_event_time_ = 0;

  void EnrichEvent(nlohmann::json& event);
  void UpdateSession();
  void TrackSessionStart();
  void TrackSessionEnd(int64_t timestamp);
  void TrackInternal(const nlohmann::json& event);
  void PersistIdentity();
  void LoadIdentity();
  int64_t CurrentTimeMillis() const;
};

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_AMPLITUDE_INSTANCE_H_
