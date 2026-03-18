#ifndef AMPLITUDE_FLUTTER_UUID_H_
#define AMPLITUDE_FLUTTER_UUID_H_

#include <windows.h>
#include <bcrypt.h>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <string>

namespace amplitude_flutter {

inline std::string GenerateUUID() {
  uint8_t bytes[16];
  BCryptGenRandom(nullptr, bytes, sizeof(bytes), BCRYPT_USE_SYSTEM_PREFERRED_RNG);

  // Set version 4 and variant bits
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  std::ostringstream ss;
  ss << std::hex << std::setfill('0');
  for (int i = 0; i < 16; i++) {
    if (i == 4 || i == 6 || i == 8 || i == 10) ss << '-';
    ss << std::setw(2) << static_cast<int>(bytes[i]);
  }
  return ss.str();
}

inline std::string GenerateInsertId() {
  uint8_t bytes[8];
  BCryptGenRandom(nullptr, bytes, sizeof(bytes), BCRYPT_USE_SYSTEM_PREFERRED_RNG);

  auto now = std::chrono::system_clock::now();
  auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                now.time_since_epoch())
                .count();

  std::ostringstream ss;
  ss << ms << '-' << std::hex << std::setfill('0');
  for (int i = 0; i < 8; i++) {
    ss << std::setw(2) << static_cast<int>(bytes[i]);
  }
  return ss.str();
}

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_UUID_H_
