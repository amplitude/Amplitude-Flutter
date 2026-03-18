#ifndef AMPLITUDE_FLUTTER_STORAGE_H_
#define AMPLITUDE_FLUTTER_STORAGE_H_

#include <nlohmann/json.hpp>
#include <string>
#include <vector>

namespace amplitude_flutter {

class Storage {
 public:
  explicit Storage(const std::string& instance_name);

  // Identity persistence
  void SaveIdentity(const nlohmann::json& identity);
  nlohmann::json LoadIdentity();

  // Event queue persistence
  void SaveEvents(const std::vector<nlohmann::json>& events);
  std::vector<nlohmann::json> LoadEvents();
  void ClearEvents();

  // In-flight batch persistence (crash recovery during send)
  void SaveInflight(const std::vector<nlohmann::json>& events);
  std::vector<nlohmann::json> LoadInflight();
  void ClearInflight();

 private:
  std::string base_path_;
  std::string identity_path_;
  std::string events_path_;
  std::string inflight_path_;

  void EnsureDirectory();
  void WriteFile(const std::string& path, const std::string& content);
  std::string ReadFile(const std::string& path);
};

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_STORAGE_H_
