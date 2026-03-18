#ifndef AMPLITUDE_FLUTTER_DEVICE_INFO_H_
#define AMPLITUDE_FLUTTER_DEVICE_INFO_H_

#include <string>

namespace amplitude_flutter {

struct DeviceInfo {
  std::string os_name;
  std::string os_version;
  std::string device_manufacturer;
  std::string device_model;
  std::string device_brand;
  std::string language;
  std::string carrier;

  static DeviceInfo Collect();
};

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_DEVICE_INFO_H_
