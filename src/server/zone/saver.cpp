#include "zone/saver.hpp"

#include <cstdio>
#include <optional>
#include <print>
#include <thread>
#include <utility>

namespace game::zone {
namespace {

using Clock = std::chrono::steady_clock;

constexpr std::chrono::milliseconds kStopNap{50};

}

Saver::Saver(Send send) : Saver(std::move(send), Waits{}) {}

Saver::Saver(Send send, Waits waits)
    : send_(std::move(send)), waits_(waits),
      thread_([this](const std::stop_token& stop) { run(stop); }) {}

Saver::~Saver() {
    thread_.request_stop();
    // request_stop đánh thức wait_for/wait đang ngủ qua condition_variable_any; join ở huỷ jthread.
}

void Saver::push(const Save& spot) {
    {
        const std::scoped_lock guard{lock_};
        waiting_.insert_or_assign(spot.character, spot);
    }
    wake_.notify_one();
}

std::size_t Saver::pending() const {
    const std::scoped_lock guard{lock_};
    return waiting_.size();
}

std::uint64_t Saver::failures() const {
    const std::scoped_lock guard{lock_};
    return failures_;
}

std::uint64_t Saver::saved() const {
    const std::scoped_lock guard{lock_};
    return saved_;
}

void Saver::run(const std::stop_token& stop) {
    std::optional<Clock::time_point> give_up;
    for (;;) {
        Save job;
        {
            std::unique_lock guard{lock_};
            wake_.wait(guard, stop, [this] { return !waiting_.empty(); });
            if (waiting_.empty()) return;
            if (stop.stop_requested() && !give_up) give_up = Clock::now() + waits_.flush;
            const auto first = waiting_.begin();
            job = first->second;
            waiting_.erase(first);
        }
        const bool ok = send_(job);
        std::unique_lock guard{lock_};
        if (ok) {
            ++saved_;
            continue;
        }
        ++failures_;
        // Một lần ghi mới hơn đã tới trong lúc gửi thì giữ bản mới; không thì đặt lại bản này.
        waiting_.try_emplace(job.character, job);
        if (stop.stop_requested()) {
            if (!give_up) give_up = Clock::now() + waits_.flush;
            if (Clock::now() >= *give_up) {
                std::println(stderr, "zone: bỏ {} lần ghi điểm đứng chưa gửi được lúc dừng", waiting_.size());
                return;
            }
        }
        if (stop.stop_requested()) {
            // wait_for với stop đã bật trả ngay, nên lúc dừng phải ngủ thật để không quay rỗng.
            guard.unlock();
            std::this_thread::sleep_for(kStopNap);
            continue;
        }
        wake_.wait_for(guard, stop, waits_.retry, [] { return false; });
    }
}

} // namespace game::zone
