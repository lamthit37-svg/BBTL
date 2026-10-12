// Bộ đệm khung của một kết nối. Hai hộp là vector kèm vị trí bắt đầu: tiêu thụ ở đầu chỉ dời vị
// trí, phần đã dùng được dồn đi ở lần thêm kế tiếp, nên mỗi lần thêm dời byte tối đa một lần.
// Nguồn: TLBB Dev src/net/connection.cpp.
// Khác gốc: compact dồn luôn, không kiểm start == 0 như Dev; mark_sent quá số byte đang chờ dừng
// bằng core::check thay vì kẹp như Dev; receive so với inbox_room() (trần trừ phần còn giữ sau khi
// bỏ khung đã trả) và trần mặc định chừa một mẩu đọc, xem channel.hpp.
#include "protocol/channel.hpp"

#include "core/check.hpp"
#include "protocol/wire.hpp"

#include <cstddef>
#include <expected>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::protocol {
namespace {

// Bỏ phần đã dùng ở đầu buffer, đưa start về 0.
void compact(std::vector<std::byte>& buffer, std::size_t& start) {
    const auto used = static_cast<std::ptrdiff_t>(start);
    buffer.erase(buffer.begin(), buffer.begin() + used);
    start = 0;
}

} // namespace

std::optional<WireError> unwrap(ChannelError error) noexcept {
    if (error == ChannelError::kInboxFull || error == ChannelError::kOutboxFull) {
        return std::nullopt;
    }
    return static_cast<WireError>(std::to_underlying(error));
}

std::string_view describe(ChannelError error) noexcept {
    if (error == ChannelError::kInboxFull) return "hộp nhận đầy, luồng byte mất một đoạn";
    if (error == ChannelError::kOutboxFull) return "hộp gửi đầy, bên kia không đọc kịp";
    const std::optional<WireError> wire = unwrap(error);
    if (!wire) return "lỗi kênh không rõ";
    return describe(*wire);
}

Channel::Channel(ChannelLimits limits) noexcept : limits_(limits) {
    core::check(limits.max_body <= kMaxBodyBytes, "Channel: max_body vượt kMaxBodyBytes");
    core::check(limits.inbox_bytes >= kHeaderBytes + limits.max_body,
        "Channel: hộp nhận không chứa nổi một khung lớn nhất");
}

ChannelStatus Channel::receive(ByteView bytes) {
    if (broken_) return std::unexpected(*broken_);
    release_frame();
    if (bytes.size() > inbox_room()) broken_ = ChannelError::kInboxFull;
    if (broken_) return std::unexpected(*broken_);
    compact(inbox_, inbox_start_);
    inbox_.insert(inbox_.end(), bytes.begin(), bytes.end());
    return {};
}

NextFrame Channel::next() noexcept {
    if (broken_) return std::unexpected(*broken_);
    release_frame();
    const ByteView view = ByteView{inbox_}.subspan(inbox_start_);
    const FrameResult frame = peek_frame(view, limits_.max_body);
    if (!frame) broken_ = wrap(frame.error());
    if (broken_) return std::unexpected(*broken_);
    if (!frame->has_value()) return std::nullopt;
    const Frame& whole = **frame;
    returned_bytes_ = kHeaderBytes + whole.body_bytes;
    return InFrame{.kind = whole.kind, .body = view.subspan(kHeaderBytes, whole.body_bytes)};
}

ChannelStatus Channel::queue(ByteView frame) {
    if (broken_) return std::unexpected(*broken_);
    const FrameResult whole = peek_frame(frame, kMaxBodyBytes);
    const bool is_one_frame = whole && whole->has_value() && kHeaderBytes + (*whole)->body_bytes == frame.size();
    core::check(is_one_frame, "Channel::queue: đầu vào không phải đúng một khung đã mã hoá");
    if (frame.size() > limits_.outbox_bytes - outgoing().size()) {
        return std::unexpected(ChannelError::kOutboxFull);
    }
    compact(outbox_, outbox_start_);
    outbox_.insert(outbox_.end(), frame.begin(), frame.end());
    return {};
}

ByteView Channel::outgoing() const noexcept {
    return ByteView{outbox_}.subspan(outbox_start_);
}

void Channel::mark_sent(std::size_t count) noexcept {
    core::check(count <= outgoing().size(), "Channel::mark_sent: nhiều hơn số byte đang chờ");
    outbox_start_ += count;
    if (outbox_start_ < outbox_.size()) return;
    outbox_.clear();
    outbox_start_ = 0;
}

std::size_t Channel::inbox_held() const noexcept {
    return inbox_.size() - inbox_start_;
}

// Khung vừa trả nằm trọn trong phần đang giữ nên phép trừ không âm; phần còn lại là phần dở, không
// quá trần.
std::size_t Channel::inbox_room() const noexcept {
    if (broken_) return 0;
    return limits_.inbox_bytes - (inbox_held() - returned_bytes_);
}

void Channel::release_frame() noexcept {
    inbox_start_ += std::exchange(returned_bytes_, 0);
    if (inbox_start_ < inbox_.size()) return;
    inbox_.clear();
    inbox_start_ = 0;
}

} // namespace game::protocol
