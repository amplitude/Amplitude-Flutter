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
    cv_.notify_one();  // Wake background thread instead of blocking caller
  }
}

void EventQueue::Flush() {
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
  FlushInternal();
}

void EventQueue::FlushTimerLoop() {
  while (true) {
    {
      std::unique_lock<std::mutex> lock(mutex_);
      cv_.wait_for(lock, std::chrono::milliseconds(flush_interval_millis_),
                   [this] { return stop_; });
      if (stop_) break;
    }
    FlushInternal();
  }
}

void EventQueue::FlushInternal() {
  std::vector<nlohmann::json> batch;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (events_.empty()) return;
    batch = std::move(events_);
    events_.clear();
    Persist();  // Write cleared state so concurrent Push+Persist won't lose in-flight events
  }

  // Send outside the lock so Push() is never blocked by network I/O
  bool success = transport_->Send(batch);
  std::lock_guard<std::mutex> lock(mutex_);
  if (success) {
    Persist();
  } else {
    events_.insert(events_.begin(), batch.begin(), batch.end());
    Persist();
  }
}

void EventQueue::Persist() {
  storage_->SaveEvents(events_);
}

}  // namespace amplitude_flutter
