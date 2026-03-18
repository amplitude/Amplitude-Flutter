#include "storage.h"

#include <windows.h>
#include <shlobj.h>

#include <fstream>
#include <sstream>

#include "string_utils.h"

namespace amplitude_flutter {

namespace {

std::string GetLocalAppDataPath() {
  wchar_t* path = nullptr;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &path))) {
    std::string result = WideToUtf8(std::wstring(path));
    CoTaskMemFree(path);
    return result;
  }
  // Fallback
  return "C:\\Users\\Public\\AppData\\Local";
}

}  // namespace

Storage::Storage(const std::string& instance_name) {
  base_path_ = GetLocalAppDataPath() + "\\amplitude\\" + instance_name;
  identity_path_ = base_path_ + "\\identity.json";
  events_path_ = base_path_ + "\\events.json";
  inflight_path_ = base_path_ + "\\events_inflight.json";
  EnsureDirectory();
}

void Storage::SaveIdentity(const nlohmann::json& identity) {
  WriteFile(identity_path_, identity.dump());
}

nlohmann::json Storage::LoadIdentity() {
  std::string content = ReadFile(identity_path_);
  if (content.empty()) return nlohmann::json::object();
  try {
    return nlohmann::json::parse(content);
  } catch (...) {
    return nlohmann::json::object();
  }
}

void Storage::SaveEvents(const std::vector<nlohmann::json>& events) {
  nlohmann::json arr = nlohmann::json::array();
  for (const auto& e : events) arr.push_back(e);
  WriteFile(events_path_, arr.dump());
}

std::vector<nlohmann::json> Storage::LoadEvents() {
  std::string content = ReadFile(events_path_);
  if (content.empty()) return {};
  try {
    auto arr = nlohmann::json::parse(content);
    if (!arr.is_array()) return {};
    std::vector<nlohmann::json> result;
    for (const auto& e : arr) result.push_back(e);
    return result;
  } catch (...) {
    return {};
  }
}

void Storage::ClearEvents() {
  DeleteFileW(Utf8ToWide(events_path_).c_str());
}

void Storage::SaveInflight(const std::vector<nlohmann::json>& events) {
  nlohmann::json arr = nlohmann::json::array();
  for (const auto& e : events) arr.push_back(e);
  WriteFile(inflight_path_, arr.dump());
}

std::vector<nlohmann::json> Storage::LoadInflight() {
  std::string content = ReadFile(inflight_path_);
  if (content.empty()) return {};
  try {
    auto arr = nlohmann::json::parse(content);
    if (!arr.is_array()) return {};
    std::vector<nlohmann::json> result;
    for (const auto& e : arr) result.push_back(e);
    return result;
  } catch (...) {
    return {};
  }
}

void Storage::ClearInflight() {
  DeleteFileW(Utf8ToWide(inflight_path_).c_str());
}

void Storage::EnsureDirectory() {
  std::wstring wide_path = Utf8ToWide(base_path_);
  // Create directory recursively
  size_t pos = 0;
  while ((pos = wide_path.find(L'\\', pos + 1)) != std::wstring::npos) {
    CreateDirectoryW(wide_path.substr(0, pos).c_str(), nullptr);
  }
  CreateDirectoryW(wide_path.c_str(), nullptr);
}

void Storage::WriteFile(const std::string& path, const std::string& content) {
  // Write to temp file then rename for atomicity
  std::string temp_path = path + ".tmp";
  std::wstring wide_temp = Utf8ToWide(temp_path);
  std::wstring wide_path = Utf8ToWide(path);

  std::ofstream file(wide_temp, std::ios::binary | std::ios::trunc);
  if (file.is_open()) {
    file << content;
    file.close();
    MoveFileExW(wide_temp.c_str(), wide_path.c_str(),
                MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
  }
}

std::string Storage::ReadFile(const std::string& path) {
  std::wstring wide_path = Utf8ToWide(path);
  std::ifstream file(wide_path, std::ios::binary);
  if (!file.is_open()) return "";
  std::ostringstream ss;
  ss << file.rdbuf();
  return ss.str();
}

}  // namespace amplitude_flutter
