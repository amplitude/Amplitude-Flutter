#include "http_transport.h"

#include <windows.h>
#include <winhttp.h>

#include <thread>

#include "string_utils.h"

namespace amplitude_flutter {

namespace {

struct UrlParts {
  std::wstring host;
  std::wstring path;
  INTERNET_PORT port;
  bool use_ssl;
};

UrlParts ParseUrl(const std::string& url) {
  UrlParts parts;
  std::wstring wide_url = Utf8ToWide(url);

  URL_COMPONENTS components = {};
  components.dwStructSize = sizeof(components);
  wchar_t host[256] = {};
  wchar_t path[1024] = {};
  components.lpszHostName = host;
  components.dwHostNameLength = 256;
  components.lpszUrlPath = path;
  components.dwUrlPathLength = 1024;

  WinHttpCrackUrl(wide_url.c_str(), 0, 0, &components);

  parts.host = host;
  parts.path = path;
  parts.port = components.nPort;
  parts.use_ssl = (components.nScheme == INTERNET_SCHEME_HTTPS);
  return parts;
}

}  // namespace

HttpTransport::HttpTransport(const std::string& api_key,
                             const std::string& server_url, bool use_batch,
                             int max_retries)
    : api_key_(api_key),
      server_url_(server_url),
      max_retries_(max_retries) {}

std::string HttpTransport::DefaultUrl(const std::string& server_zone,
                                       bool use_batch) {
  if (server_zone == "EU" || server_zone == "eu") {
    return use_batch ? "https://api.eu.amplitude.com/batch"
                     : "https://api.eu.amplitude.com/2/httpapi";
  }
  return use_batch ? "https://api2.amplitude.com/batch"
                   : "https://api2.amplitude.com/2/httpapi";
}

bool HttpTransport::Send(const std::vector<nlohmann::json>& events) {
  if (events.empty()) return true;

  nlohmann::json payload;
  payload["api_key"] = api_key_;
  payload["events"] = events;
  std::string body = payload.dump();

  for (int attempt = 0; attempt <= max_retries_; attempt++) {
    if (attempt > 0) {
      int shift = (attempt - 1 < 20) ? (attempt - 1) : 20;
      int delay_ms = 1000 * (1 << shift);
      std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
    }

    int status = Post(server_url_, body);
    if (status == 200) return true;
    // Don't retry permanent failures
    if (status == 400 || status == 413) return false;
    // Retry on 429 (throttle), 5xx (server error), or 0 (connection failure)
  }
  return false;
}

int HttpTransport::Post(const std::string& url, const std::string& body) {
  auto parts = ParseUrl(url);

  HINTERNET session = WinHttpOpen(L"amplitude-flutter-windows/1.0",
                                   WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                                   WINHTTP_NO_PROXY_NAME,
                                   WINHTTP_NO_PROXY_BYPASS, 0);
  if (!session) return 0;

  HINTERNET connection =
      WinHttpConnect(session, parts.host.c_str(), parts.port, 0);
  if (!connection) {
    WinHttpCloseHandle(session);
    return 0;
  }

  DWORD flags = parts.use_ssl ? WINHTTP_FLAG_SECURE : 0;
  HINTERNET request = WinHttpOpenRequest(
      connection, L"POST", parts.path.c_str(), nullptr,
      WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, flags);
  if (!request) {
    WinHttpCloseHandle(connection);
    WinHttpCloseHandle(session);
    return 0;
  }

  const wchar_t* content_type = L"Content-Type: application/json";
  BOOL sent = WinHttpSendRequest(
      request, content_type, static_cast<DWORD>(-1),
      const_cast<char*>(body.c_str()), static_cast<DWORD>(body.size()),
      static_cast<DWORD>(body.size()), 0);

  int result = 0;
  if (sent && WinHttpReceiveResponse(request, nullptr)) {
    DWORD status_code = 0;
    DWORD size = sizeof(status_code);
    WinHttpQueryHeaders(request,
                         WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                         WINHTTP_HEADER_NAME_BY_INDEX, &status_code, &size,
                         WINHTTP_NO_HEADER_INDEX);
    result = static_cast<int>(status_code);
  }

  WinHttpCloseHandle(request);
  WinHttpCloseHandle(connection);
  WinHttpCloseHandle(session);
  return result;
}

}  // namespace amplitude_flutter
