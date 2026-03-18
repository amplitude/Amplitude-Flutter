#ifndef AMPLITUDE_FLUTTER_HTTP_TRANSPORT_H_
#define AMPLITUDE_FLUTTER_HTTP_TRANSPORT_H_

#include <nlohmann/json.hpp>
#include <string>

namespace amplitude_flutter {

class HttpTransport {
 public:
  HttpTransport(const std::string& api_key, const std::string& server_url,
                bool use_batch, int max_retries);

  // Send events to Amplitude. Returns true on success.
  bool Send(const std::vector<nlohmann::json>& events);

 private:
  std::string api_key_;
  std::string server_url_;
  int max_retries_;

  // Returns HTTP status code, or 0 on connection failure.
  int Post(const std::string& url, const std::string& body);
  static std::string DefaultUrl(const std::string& server_zone, bool use_batch);

  friend class AmplitudeInstance;
};

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_HTTP_TRANSPORT_H_
