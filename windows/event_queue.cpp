#include "event_queue.h"

namespace amplitude_flutter {

EventQueue::EventQueue(std::shared_ptr<Storage> storage,
                       std::shared_ptr<HttpTransport> transport,
                       int flush_queue_size, int flush_interval_millis)
    : storage_(std::move(storage)),
      transport_(std::move(transport)),
      flush_queue_size_(flush_queue_size),
      flush_interval_millis_(flush_interval_millis) {
  // Recover any persisted events from a previous crash
  auto recovered = storage_->LoadEvents();
  if (!recovered.empty()) {
    std::lock_guard<std::mutex> lock(mutex_);
    events_.insert(events_.end(), recovered.begin(), recovered.end());
  }

  // Start background flush timer
  flush_thread_ = std::thread(&EventQueue::FlushTimerLoop, this);
}

EventQueue::~EventQueue() {
  Stop();
}

void EventQueue::Push(const nlohmann::json& event) {
  bool should_flush = false;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    events_.push_back(event);
    Persist();
    should_flush =
        (static_cast<int>(events_.size()) >= flush_queue_size_);
  }

  if (should_flush) {
    Flush();
  }
}

void EventQueue::Flush() {
  std::lock_guard<std::mutex> lock(mutex_);
  FlushInternal();
}

void EventQueue::Stop() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (stop_) return;
    stop_ = true;
  }
  cv_.notify_all();
  if (flush_thread_.joinable()) {
    flush_thread_.join();
  }
  // Final flush
  std::lock_guard<std::mutex> lock(mutex_);
  FlushInternal();
}

void EventQueue::FlushTimerLoop() {
  while (true) {
    std::unique_lock<std::mutex> lock(mutex_);
    cv_.wait_for(lock, std::chrono::milliseconds(flush_interval_millis_),
                 [this] { return stop_; });
    if (stop_) break;
    FlushInternal();
  }
}

void EventQueue::FlushInternal() {
  if (events_.empty()) return;

  // Move events out for sending
  std::vector<nlohmann::json> batch = std::move(events_);
  events_.clear();

  bool success = transport_->Send(batch);
  if (success) {
    storage_->ClearEvents();
  } else {
    // Put events back on failure
    events_.insert(events_.begin(), batch.begin(), batch.end());
    Persist();
  }
}

void EventQueue::Persist() {
  storage_->SaveEvents(events_);
}

}  // namespace amplitude_flutter
