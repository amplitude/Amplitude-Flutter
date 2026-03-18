#include "device_info.h"

#include <windows.h>
#include <versionhelpers.h>

#include <string>

namespace amplitude_flutter {

namespace {

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                                  static_cast<int>(wide.size()), nullptr, 0,
                                  nullptr, nullptr);
  std::string result(size, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                       static_cast<int>(wide.size()), &result[0], size,
                       nullptr, nullptr);
  return result;
}

std::string ReadRegistryString(HKEY root, const std::wstring& path,
                                const std::wstring& name) {
  HKEY key;
  if (RegOpenKeyExW(root, path.c_str(), 0, KEY_READ, &key) != ERROR_SUCCESS) {
    return "unknown";
  }

  wchar_t buffer[256];
  DWORD size = sizeof(buffer);
  DWORD type = 0;
  LSTATUS status =
      RegQueryValueExW(key, name.c_str(), nullptr, &type,
                       reinterpret_cast<LPBYTE>(buffer), &size);
  RegCloseKey(key);

  if (status == ERROR_SUCCESS && type == REG_SZ) {
    return WideToUtf8(std::wstring(buffer));
  }
  return "unknown";
}

std::string GetOsVersion() {
  // Use RtlGetVersion via ntdll to get accurate version (not subject to
  // compatibility shims like GetVersionEx)
  using RtlGetVersionFunc = NTSTATUS(WINAPI*)(PRTL_OSVERSIONINFOW);
  HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
  if (!ntdll) return "unknown";

  auto RtlGetVersion =
      reinterpret_cast<RtlGetVersionFunc>(GetProcAddress(ntdll, "RtlGetVersion"));
  if (!RtlGetVersion) return "unknown";

  RTL_OSVERSIONINFOW info = {};
  info.dwOSVersionInfoSize = sizeof(info);
  if (RtlGetVersion(&info) != 0) return "unknown";

  return std::to_string(info.dwMajorVersion) + "." +
         std::to_string(info.dwMinorVersion) + "." +
         std::to_string(info.dwBuildNumber);
}

std::string GetLanguage() {
  wchar_t locale[LOCALE_NAME_MAX_LENGTH];
  if (GetUserDefaultLocaleName(locale, LOCALE_NAME_MAX_LENGTH) > 0) {
    return WideToUtf8(std::wstring(locale));
  }
  return "en-US";
}

}  // namespace

DeviceInfo DeviceInfo::Collect() {
  DeviceInfo info;
  info.os_name = "Windows";
  info.os_version = GetOsVersion();
  info.device_manufacturer = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\BIOS",
      L"SystemManufacturer");
  info.device_model = ReadRegistryString(
      HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\BIOS",
      L"SystemProductName");
  info.device_brand = info.device_manufacturer;
  info.language = GetLanguage();
  info.carrier = "unknown";
  return info;
}

}  // namespace amplitude_flutter
