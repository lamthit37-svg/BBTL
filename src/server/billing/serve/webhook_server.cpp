#include "billing/serve/webhook_server.hpp"

#include "billing/book.hpp"
#include "billing/http.hpp"
#include "billing/types.hpp"
#include "billing/webhook.hpp"
#include "net/net.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::billing {
namespace {

// Mỗi lần đọc tối đa chừng này byte: đủ nhỏ để bộ phân tích chạy lại sau mỗi mảnh vẫn rẻ (O(độ dài) mỗi lần,
// tổng O(trần^2 / mảnh) = vài chục nghìn thao tác cho yêu cầu to nhất).
constexpr std::size_t kChunk = 1024;
// Số kết nối nhận tối đa trong một vòng: kẻ mở kết nối dồn dập không chiếm hết vòng chờ.
constexpr std::size_t kAcceptPerPump = 32;

[[nodiscard]] UnixTime unix_now() {
    const auto since = std::chrono::system_clock::now().time_since_epoch();
    return UnixTime{std::chrono::duration_cast<std::chrono::seconds>(since).count()};
}

[[nodiscard]] std::uint64_t tag_of(std::size_t index) noexcept {
    return static_cast<std::uint64_t>(index) + 1;
}

} // namespace

WebhookServer::WebhookServer(net::TcpListener listener, const Webhooks& hooks, Book& book, WebhookServerOptions options)
    : listener_(std::move(listener)), hooks_(&hooks), book_(&book), options_(options),
      // Nhãn 0 là cổng nghe; nhãn kết nối là chỉ số + 1. poll_ và listener_ khai báo trước ready_ nên đã dựng xong.
      ready_(poll_.add(listener_.handle(), 0)) {
    conns_.resize(std::max<std::size_t>(options_.max_connections, 1));
}

bool WebhookServer::pump(std::chrono::milliseconds wait) {
    if (!ready_) return false;
    if (!poll_.wait(wait, events_)) return false;
    const Clock::time_point now = Clock::now();
    for (const net::PollEvent& event : events_)
        on_event(event, now);
    sweep(Clock::now());
    return true;
}

void WebhookServer::on_event(const net::PollEvent& event, Clock::time_point now) {
    if (event.tag == 0) {
        accept_all(now);
        return;
    }
    // Nhãn là uint64 (bằng size_t trên mọi nền đích 64 bit của máy chủ).
    const auto index = event.tag - 1;
    if (index >= conns_.size()) return;
    switch (conns_[index].phase) {
    case Phase::kFree: return;
    case Phase::kReading: read_request(index, now); return;
    case Phase::kSending:
        if (event.failed) {
            drop(index);
        } else {
            flush(index, now);
        }
        return;
    case Phase::kLinger: linger(index); return;
    }
}

void WebhookServer::accept_all(Clock::time_point now) {
    for (std::size_t round = 0; round < kAcceptPerPump; ++round) {
        net::NetResult<std::optional<net::Accepted>> accepted = listener_.accept();
        if (!accepted || !*accepted) return;
        if (open_ >= conns_.size()) continue;  // đầy: Accepted huỷ ở cuối vòng, kết nối bị đóng
        const auto slot = std::ranges::find(conns_, Phase::kFree, &Conn::phase);
        if (slot == conns_.end()) continue;
        const std::size_t index = static_cast<std::size_t>(slot - conns_.begin());
        Conn& conn = *slot;
        conn.stream = std::move((*accepted)->stream);
        conn.phase = Phase::kReading;
        conn.in.clear();
        conn.out.clear();
        conn.sent = 0;
        conn.deadline = now + options_.request_budget;
        ++open_;
        if (!poll_.add(conn.stream.handle(), tag_of(index))) drop(index);
    }
}

void WebhookServer::read_request(std::size_t index, Clock::time_point now) {
    Conn& conn = conns_[index];
    std::array<char, kChunk> chunk{};
    for (;;) {
        const std::size_t room = http::kRequestMost - conn.in.size();
        if (room == 0) {
            answer(index, http::Status::kTooLarge, "too_large", now);
            return;
        }
        const std::span<char> window = std::span{chunk}.first(std::min(room, chunk.size()));
        const net::NetResult<std::size_t> got = conn.stream.receive(std::as_writable_bytes(window));
        // Bên kia đóng hay đứt trước khi gửi đủ yêu cầu: không có ai để trả lời.
        if (!got) {
            drop(index);
            return;
        }
        if (*got == 0) return;
        conn.in.append(window.data(), *got);
        const http::Parsed parsed = http::parse(conn.in);
        if (parsed.state == http::Parsed::State::kNeedMore) continue;
        if (parsed.state == http::Parsed::State::kReject) {
            answer(index, parsed.reject, "rejected", now);
            return;
        }
        const WebhookAnswer reply = hooks_->handle(*book_, parsed.request, unix_now());
        answer(index, reply.status, reply.body, now);
        return;
    }
}

void WebhookServer::answer(std::size_t index, http::Status status, std::string_view body, Clock::time_point now) {
    Conn& conn = conns_[index];
    conn.in.clear();
    conn.out = http::respond(status, body);
    conn.sent = 0;
    conn.phase = Phase::kSending;
    // Gửi trả lời nhỏ cũng có hạn: bên kia không đọc thì không giữ chỗ mãi.
    conn.deadline = now + options_.request_budget;
    flush(index, now);
}

void WebhookServer::flush(std::size_t index, Clock::time_point now) {
    Conn& conn = conns_[index];
    while (conn.sent < conn.out.size()) {
        const std::string_view rest = std::string_view{conn.out}.substr(conn.sent);
        const net::NetResult<std::size_t> sent = conn.stream.send(std::as_bytes(std::span{rest}));
        if (!sent) {
            drop(index);
            return;
        }
        if (*sent == 0) {
            poll_.want_write(tag_of(index), true);
            return;
        }
        conn.sent += *sent;
    }
    poll_.want_write(tag_of(index), false);
    conn.stream.shutdown_send();
    conn.out.clear();
    conn.phase = Phase::kLinger;
    conn.deadline = now + options_.linger_budget;
}

void WebhookServer::linger(std::size_t index) {
    Conn& conn = conns_[index];
    std::array<std::byte, kChunk> sink{};
    for (;;) {
        const net::NetResult<std::size_t> got = conn.stream.receive(sink);
        if (!got) {
            drop(index);
            return;
        }
        if (*got == 0) return;
    }
}

void WebhookServer::drop(std::size_t index) {
    Conn& conn = conns_[index];
    if (conn.phase == Phase::kFree) return;
    // Bỏ nhãn trước khi đóng socket: hệ điều hành có thể cấp lại đúng handle đó cho socket mới.
    poll_.remove(tag_of(index));
    conn.stream = net::TcpStream{};
    conn.phase = Phase::kFree;
    conn.in.clear();
    conn.out.clear();
    conn.sent = 0;
    --open_;
}

void WebhookServer::sweep(Clock::time_point now) {
    for (std::size_t index = 0; index < conns_.size(); ++index) {
        const Conn& conn = conns_[index];
        if (conn.phase == Phase::kFree || conn.deadline > now) continue;
        if (conn.phase == Phase::kReading) {
            // Kẻ nói chậm nhận 408 một lần rồi bị đóng ở hạn kế (answer đổi pha nên không lặp lại).
            answer(index, http::Status::kTimeout, "timeout", now);
        } else {
            drop(index);
        }
    }
}

} // namespace game::billing
