#ifndef AMPLITUDE_FLUTTER_EVENT_QUEUE_H_
#define AMPLITUDE_FLUTTER_EVENT_QUEUE_H_

#include <atomic>
#include <condition_variable>
#include <functional>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <thread>
#include <vector>

#include "http_transport.h"
#include "storage.h"

namespace amplitude_flutter {

class EventQueue {
 public:
  EventQueue(std::shared_ptr<Storage> storage,
             std::shared_ptr<HttpTransport> transport, int flush_queue_size,
             int flush_interval_millis);
  ~EventQueue();

  void Push(const nlohmann::json& event);
  void Flush();
  void Stop();

 private:
  std::shared_ptr<Storage> storage_;
  std::shared_ptr<HttpTransport> transport_;
  int flush_queue_size_;
  int flush_interval_millis_;

  std::vector<nlohmann::json> events_;
  std::mutex mutex_;

  std::thread flush_thread_;
  std::condition_variable cv_;
  bool stop_ = false;
  bool flush_requested_ = false;
  std::atomic<bool> flushing_{false};

  void FlushTimerLoop();
  void FlushInternal();
  void Persist();  // Must be called with mutex_ held
};

}  // namespace amplitude_flutter

#endif  // AMPLITUDE_FLUTTER_EVENT_QUEUE_H_
