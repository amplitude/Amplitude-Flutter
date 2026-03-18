#include "event_queue.h"

namespace amplitude_flutter {

EventQueue::EventQueue(std::shared_ptr<Storage> storage,
                       std::shared_ptr<HttpTransport> transport,
                       int flush_queue_size, int flush_interval_millis)
    : storage_(std::move(storage)),
      transport_(std::move(transport)),
      flush_queue_size_(flush_queue_size),
      flush_interval_millis_(flush_interval_millis) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto inflight = storage_->LoadInflight();
    if (!inflight.empty()) {
      events_.insert(events_.end(), inflight.begin(), inflight.end());
      storage_->ClearInflight();
    }
    auto recovered = storage_->LoadEvents();
    if (!recovered.empty()) {
      events_.insert(events_.end(), recovered.begin(), recovered.end());
    }
    if (!events_.empty()) {
      Persist();
    }
  }

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
    std::lock_guard<std::mutex> lock(mutex_);
    flush_requested_ = true;
    cv_.notify_one();
  }
}

void EventQueue::Flush() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    flush_requested_ = true;
  }
  cv_.notify_one();
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
  FlushInternal();
}

void EventQueue::FlushTimerLoop() {
  while (true) {
    {
      std::unique_lock<std::mutex> lock(mutex_);
      cv_.wait_for(lock, std::chrono::milliseconds(flush_interval_millis_),
                   [this] { return stop_ || flush_requested_; });
      if (stop_) break;
      flush_requested_ = false;
    }
    FlushInternal();
  }
}

void EventQueue::FlushInternal() {
  if (flushing_.exchange(true)) return;

  std::vector<nlohmann::json> batch;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (events_.empty()) {
      flushing_ = false;
      return;
    }
    batch = std::move(events_);
    events_.clear();
    storage_->SaveInflight(batch);
    Persist();
  }

  bool success = transport_->Send(batch);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (success) {
      storage_->ClearInflight();
      Persist();
    } else {
      storage_->ClearInflight();
      events_.insert(events_.begin(), batch.begin(), batch.end());
      Persist();
    }
  }

  flushing_ = false;
}

void EventQueue::Persist() {
  storage_->SaveEvents(events_);
}

}  // namespace amplitude_flutter
