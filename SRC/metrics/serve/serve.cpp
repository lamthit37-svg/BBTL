// Hàng bên đọc và luồng phục vụ của cổng đọc số đo (metrics/serve/serve.hpp).
#include "metrics/serve/serve.hpp"

#include "core/check.hpp"
#include "core/clock.hpp"
#include "core/thread.hpp"
#include "metrics/metrics.hpp"
#include "net/net.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <stop_token>
#include <thread>
#include <utility>

namespace game::metrics {
namespace {

constexpr std::uint64_t kListenerTag = 0;
constexpr std::uint64_t kReaderTag = 1;
// Gửi từng khúc. Windows nhận trọn một lần gửi không chặn dù nó lớn hơn vùng đệm của socket, miễn
// vùng đệm chưa đầy lúc gọi: gửi cả ảnh chụp một lần thì nhân giữ hộ trọn ảnh chụp cho một bên
// không đọc, và hạn kReaderTimeout không bao giờ có dịp chạy.
constexpr std::size_t kChunkBytes = std::size_t{16} * 1024;
// Số kết nối nhận trong một vòng: một tiến trình nối liên tục không giữ được luồng trong vòng nhận,
// phần còn lại nằm ở hàng chờ của hệ điều hành tới vòng sau.
constexpr std::size_t kAcceptBurst = 16;
// Nhịp chờ của luồng phục vụ, cũng là hạn nó thấy yêu cầu dừng.
constexpr net::Milliseconds kServeSlice{100};
constexpr net::Endpoint kAnyLoopbackPort{.address = {127, 0, 0, 1}, .port = 0};

} // namespace

Readers::Readers(net::TcpListener listener, Registry& tally, Fill fill)
    : listener_(std::move(listener)), tally_(&tally), fill_(std::move(fill)), text_(kSnapshotMaxBytes) {
    events_.reserve(2);
    const bool is_watched = poll_.add(listener_.handle(), kListenerTag);
    core::check(is_watched, "Readers: cổng nghe phải đang mở");
}

net::NetResult<void> Readers::step(net::Milliseconds limit, core::Clock::time_point now) {
    const net::NetResult<void> waited = poll_.wait(limit, events_);
    if (!waited) return waited;
    accept_pending();
    send_more(now);
    while (!current_ && begin_next(now)) {
        send_more(now);
    }
    return {};
}

void Readers::accept_pending() {
    for (std::size_t round = 0; round < kAcceptBurst; ++round) {
        net::NetResult<std::optional<net::Accepted>> got = listener_.accept();
        // Lỗi nhận (hết handle...) không làm hỏng hàng: kết nối đó hệ điều hành đã bỏ, vòng sau nhận tiếp.
        if (!got || !got->has_value()) return;
        net::TcpStream stream = std::move((*got)->stream);
        if (waiting_count_ == kMaxReaders) {
            stream.abort();
            tally_->add(Counter::kMetricsReaderDropped);
            continue;
        }
        std::span{waiting_}[(waiting_from_ + waiting_count_) % kMaxReaders] = std::move(stream);
        ++waiting_count_;
    }
}

bool Readers::begin_next(core::Clock::time_point now) {
    if (waiting_count_ == 0) return false;
    current_ = std::move(std::span{waiting_}[waiting_from_]);
    waiting_from_ = (waiting_from_ + 1) % kMaxReaders;
    --waiting_count_;
    size_ = 0;
    sent_ = 0;
    // Không theo dõi được socket thì không biết lúc nào gửi tiếp được: bỏ bên này, tới bên kế.
    if (!poll_.add(current_->handle(), kReaderTag)) {
        drop_current();
        return true;
    }
    poll_.want_write(kReaderTag, true);
    size_ = std::min(fill_(text_), text_.size());
    deadline_ = now + kReaderTimeout;
    return true;
}

void Readers::send_more(core::Clock::time_point now) {
    if (!current_) return;
    const std::span<const char> text = std::span<const char>{text_}.first(size_);
    while (sent_ < size_) {
        const std::span<const char> chunk = text.subspan(sent_, std::min(size_ - sent_, kChunkBytes));
        const net::NetResult<std::size_t> wrote = current_->send(std::as_bytes(chunk));
        // Bên đọc tự đứt: không phải tiến trình bỏ nó, nên không đếm vào metrics.reader.dropped.
        if (!wrote) {
            drop_current();
            return;
        }
        if (*wrote == 0) break;
        sent_ += *wrote;
    }
    if (sent_ == size_) {
        poll_.remove(kReaderTag);
        current_->shutdown_send();
        current_.reset();
        return;
    }
    if (now < deadline_) return;
    drop_current();
    tally_->add(Counter::kMetricsReaderDropped);
}

void Readers::drop_current() noexcept {
    if (!current_) return;
    poll_.remove(kReaderTag);
    current_->abort();
    current_.reset();
}

Server::Server(std::uint16_t port, std::jthread thread) noexcept : port_(port), thread_(std::move(thread)) {}

net::NetResult<Server> Server::start(Registry& registry) {
    net::NetResult<net::TcpListener> listener = net::TcpListener::open(kAnyLoopbackPort);
    if (!listener) return std::unexpected{listener.error()};
    const net::NetResult<net::Endpoint> local = listener->local();
    if (!local) return std::unexpected{local.error()};
    Readers::Fill fill{[&registry, snapshot = std::make_unique<Snapshot>()](std::span<char> out) {
        registry.snapshot(*snapshot);
        return write_snapshot(*snapshot, out);
    }};
    core::ThreadConfig config;
    config.name = "metrics";
    Readers readers{std::move(*listener), registry, std::move(fill)};
    std::jthread thread = core::start_thread(std::move(config), [line = std::move(readers)](std::stop_token stop) mutable {
        while (!stop.stop_requested()) {
            const net::NetResult<void> stepped = line.step(kServeSlice, core::Clock::now());
            if (stepped) continue;
            std::println(stderr, "metrics: cổng đọc số đo dừng: {}", net::describe(stepped.error()));
            return;
        }
    });
    return Server{local->port, std::move(thread)};
}

} // namespace game::metrics
