// Bộ đệm khung của một kết nối: gom byte nhận được rồi cắt thành khung, gom khung đã mã hoá chờ đẩy
// ra socket. Không đụng socket và không biết danh mục tin: bên gọi chuyển byte giữa socket và kênh,
// rồi tự giải mã thân khung. Hai hộp đều có trần để bên kia chậm hay thù địch không làm phình bộ
// nhớ (UB-13, LH-03).
// Nguồn: TLBB Dev src/net/connection.hpp, connection.cpp.
// Khác gốc: không phải template theo cặp tin, nhận và trả khung thô; trần là tham số lúc tạo; hộp
// gửi từ chối khung làm vượt trần trước khi thêm (Dev kiểm trước khi thêm nên vượt được một khung);
// hộp nhận đầy cũng làm kênh hỏng hẳn; lỗi kênh là enum riêng bọc được WireError. Trần hộp nhận mặc
// định là một khung lớn nhất cộng một mẩu đọc kReadChunkBytes (Dev đặt cứng 64 KiB cho thân client
// 4 KiB và chỉ ghi bất biến bằng lời); có thêm inbox_room() để bên gọi biết được đọc bao nhiêu.
#pragma once

#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::protocol {

// Mười giá trị đầu trùng tên và số với WireError; hai giá trị sau là của riêng kênh.
enum class [[nodiscard]] ChannelError : std::uint8_t {
    kTruncated = 1,
    kTrailingBytes,
    kTooLong,
    kBadText,
    kNonFinite,
    kBadEnum,
    kBodyTooLarge,
    kBadFlags,
    kUnknownKind,
    kOutOfRange,
    // Byte nhận vượt trần hộp nhận: luồng byte đã mất một đoạn, kết nối phải đóng.
    kInboxFull,
    // Khung định gửi làm hộp gửi vượt trần: bên kia không đọc kịp; khung không được thêm.
    kOutboxFull,
};

[[nodiscard]] constexpr ChannelError wrap(WireError error) noexcept {
    return static_cast<ChannelError>(std::to_underlying(error));
}

// Khoá từng cặp theo tên: thêm, bớt hay đổi chỗ một giá trị của một bên là lỗi dịch.
static_assert(wrap(WireError::kTruncated) == ChannelError::kTruncated);
static_assert(wrap(WireError::kTrailingBytes) == ChannelError::kTrailingBytes);
static_assert(wrap(WireError::kTooLong) == ChannelError::kTooLong);
static_assert(wrap(WireError::kBadText) == ChannelError::kBadText);
static_assert(wrap(WireError::kNonFinite) == ChannelError::kNonFinite);
static_assert(wrap(WireError::kBadEnum) == ChannelError::kBadEnum);
static_assert(wrap(WireError::kBodyTooLarge) == ChannelError::kBodyTooLarge);
static_assert(wrap(WireError::kBadFlags) == ChannelError::kBadFlags);
static_assert(wrap(WireError::kUnknownKind) == ChannelError::kUnknownKind);
static_assert(wrap(WireError::kOutOfRange) == ChannelError::kOutOfRange);

// Lỗi dây được bọc; lỗi riêng của kênh thì không có.
[[nodiscard]] std::optional<WireError> unwrap(ChannelError error) noexcept;

// Câu tiếng Việt cho log.
[[nodiscard]] std::string_view describe(ChannelError error) noexcept;

// Mẩu đọc socket mà trần hộp nhận mặc định luôn chừa chỗ.
inline constexpr std::size_t kReadChunkBytes = std::size_t{16} * 1024;
inline constexpr std::size_t kInboxBytes = kHeaderBytes + kMaxBodyBytes + kReadChunkBytes;
inline constexpr std::size_t kOutboxBytes = std::size_t{1024} * 1024;

// Trần của một kênh. Kết nối của client dùng max_body = kClientBodyBytes. Trần là trần số byte
// kênh giữ (§3.4), không phải dung lượng vector đã cấp: vector không reserve trước và không trả lại
// bộ nhớ sau đợt cao điểm.
struct ChannelLimits {
    std::size_t inbox_bytes = kInboxBytes;
    std::size_t outbox_bytes = kOutboxBytes;
    std::size_t max_body = kMaxBodyBytes;
};

// Một khung đã đến đủ. body chỉ còn hiệu lực tới lời gọi kế tiếp vào Channel.
struct InFrame {
    std::uint16_t kind = 0;
    ByteView body;
};

using ChannelStatus = std::expected<void, ChannelError>;
using NextFrame = std::expected<std::optional<InFrame>, ChannelError>;

// Sau một lỗi nhận (khung hỏng, hộp nhận đầy) kênh hỏng hẳn: mọi lời gọi receive, next, queue sau
// đó trả đúng lỗi ấy, và bên gọi phải đóng kết nối.
//
// Bất biến cho bên gọi: sau mỗi receive thì rút hết khung bằng next() tới khi hết khung, và mỗi lần
// đưa vào receive không quá inbox_room() byte. Khi đó hộp nhận chỉ còn phần dở của một khung (ít
// hơn kHeaderBytes + max_body byte), nên inbox_room() luôn lớn hơn 0 và luồng hợp lệ không bao giờ
// ra kInboxFull. Với trần mặc định, inbox_room() lúc ấy không dưới kReadChunkBytes nên đọc socket
// theo mẩu cố định kReadChunkBytes cũng đủ.
class Channel {
public:
    // Hộp nhận phải chứa được một khung lớn nhất; max_body không quá kMaxBodyBytes.
    explicit Channel(ChannelLimits limits) noexcept;

    // Nhận byte vừa đọc từ socket. Khung đã trả bởi next được bỏ trước khi so trần. Quá
    // inbox_room() byte là kInboxFull và không giữ byte nào của lần này.
    [[nodiscard]] ChannelStatus receive(ByteView bytes);

    // Khung kế tiếp; không có khi còn thiếu byte. Thân khai quá max_body báo ngay khi đủ 8 byte
    // đầu.
    [[nodiscard]] NextFrame next() noexcept;

    // Xếp một khung đã mã hoá trọn vẹn (đầu Writer ra) vào cuối hộp gửi. Vượt trần là kOutboxFull,
    // hộp gửi giữ nguyên.
    [[nodiscard]] ChannelStatus queue(ByteView frame);

    // Byte đang chờ gửi, đúng thứ tự.
    [[nodiscard]] ByteView outgoing() const noexcept;

    // Socket đã đẩy được count byte đầu của outgoing().
    void mark_sent(std::size_t count) noexcept;

    // Số byte hộp nhận đang giữ, kể cả khung vừa trả bởi next.
    [[nodiscard]] std::size_t inbox_held() const noexcept;

    // Số byte đưa được vào lần receive kế tiếp mà không ra kInboxFull: trần trừ số byte còn giữ
    // sau khi bỏ khung vừa trả bởi next. Bằng 0 khi kênh đã hỏng.
    [[nodiscard]] std::size_t inbox_room() const noexcept;

private:
    // Bỏ khung đã trả ở lời gọi next trước: vùng nhìn của nó hết hiệu lực từ đây.
    void release_frame() noexcept;

    ChannelLimits limits_;
    // Byte trước inbox_start_ và outbox_start_ đã dùng xong, được dồn đi ở lần thêm kế tiếp.
    std::vector<std::byte> inbox_;
    std::size_t inbox_start_ = 0;
    std::size_t returned_bytes_ = 0;
    std::vector<std::byte> outbox_;
    std::size_t outbox_start_ = 0;
    std::optional<ChannelError> broken_;
};

} // namespace game::protocol
