#ifndef AMPLITUDE_FLUTTER_STRING_UTILS_H_
#define AMPLITUDE_FLUTTER_STRING_UTILS_H_

#include <windows.h>
#include <string>

namespace amplitude_flutter {

inline std::string WideToUtf8(const std::wstring& wide) {
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

inline std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return L"";
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                  static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring result(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                       static_cast<int>(utf8.size()), &result[0], size);
  return result;
}

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_STRING_UTILS_H_
