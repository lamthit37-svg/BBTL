// Tầng byte của protocol: thân khung little-endian ghép từng byte, đầu khung 8 byte, UTF-8 kiểm
// chặt, trần đọc trước mọi lần cấp phát (MMO-05, MMO-06, UB-04).
// Phần công khai trùng từng chữ ký với docs/giao-viec/P2-DOT-2/hop-dong/wire.hpp: mã sinh của danh
// mục tin chỉ gọi các hàm ấy.
// Nguồn: TLBB Dev src/protocol/wire.hpp, wire.cpp.
// Khác gốc: namespace game::protocol, lỗi kCamelCase; mỗi kiểu một hàm đọc trả giá trị thay cho
// field(T&); có số có dấu (đi qua kiểu không dấu cùng cỡ); không có require, mã sinh gọi
// fail(kOutOfRange); count thay begin_list và còn từ chối số phần tử vượt số byte còn lại; Writer
// sau lỗi không ghi thêm byte nào và báo kBodyTooLarge ngay khi thân vượt trần.
#pragma once

#include <concepts>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::protocol {

inline constexpr std::size_t kHeaderBytes = 8;
inline constexpr std::size_t kMaxBodyBytes = std::size_t{64} * 1024;
inline constexpr std::size_t kClientBodyBytes = std::size_t{4} * 1024;

enum class [[nodiscard]] WireError : std::uint8_t {
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
};

[[nodiscard]] std::string_view describe(WireError error) noexcept;

using WireStatus = std::expected<void, WireError>;
using ByteView = std::span<const std::byte>;

// Ghi một khung vào cuối out. Lỗi đầu tiên được nhớ, các lời gọi sau không làm gì.
class Writer {
public:
    explicit Writer(std::vector<std::byte>& out);
    void u8(std::uint8_t value);
    void u16(std::uint16_t value);
    void u32(std::uint32_t value);
    void u64(std::uint64_t value);
    void i8(std::int8_t value);
    void i16(std::int16_t value);
    void i32(std::int32_t value);
    void i64(std::int64_t value);
    void f32(float value);
    void boolean(bool value);
    void text(std::string_view value, std::size_t max_bytes);
    void bytes(ByteView value);
    void count(std::size_t value, std::size_t max_count);
    void fail(WireError error) noexcept;
    [[nodiscard]] bool is_ok() const noexcept;
    // Điền đầu khung. Có lỗi thì cắt out về cỡ lúc tạo Writer và trả lỗi đầu tiên.
    [[nodiscard]] WireStatus finish(std::uint16_t kind);

private:
    // Ghi mọi byte của value, byte thấp trước.
    template <std::unsigned_integral Value>
    void put(Value value);
    // Nối byte vào thân; thân vượt kMaxBodyBytes là kBodyTooLarge và không nối gì.
    void append(ByteView value);
    [[nodiscard]] std::size_t body_bytes() const noexcept;

    std::vector<std::byte>* out_;
    std::size_t start_;
    std::optional<WireError> error_;
};

// Đọc thân một khung. Lỗi đầu tiên được nhớ, các lời gọi sau trả giá trị không.
class Reader {
public:
    explicit Reader(ByteView body) noexcept;
    [[nodiscard]] std::uint8_t u8() noexcept;
    [[nodiscard]] std::uint16_t u16() noexcept;
    [[nodiscard]] std::uint32_t u32() noexcept;
    [[nodiscard]] std::uint64_t u64() noexcept;
    [[nodiscard]] std::int8_t i8() noexcept;
    [[nodiscard]] std::int16_t i16() noexcept;
    [[nodiscard]] std::int32_t i32() noexcept;
    [[nodiscard]] std::int64_t i64() noexcept;
    [[nodiscard]] float f32() noexcept;
    [[nodiscard]] bool boolean() noexcept;
    [[nodiscard]] std::string text(std::size_t max_bytes);
    void bytes(std::span<std::byte> out) noexcept;
    // Số vượt số byte còn lại là kTruncated: mỗi phần tử ít nhất 1 byte, theo G6.
    [[nodiscard]] std::size_t count(std::size_t max_count) noexcept;
    void fail(WireError error) noexcept;
    [[nodiscard]] bool is_ok() const noexcept;
    // Còn byte chưa đọc là kTrailingBytes.
    [[nodiscard]] WireStatus finish() const noexcept;

private:
    // count byte kế tiếp; thiếu byte là kTruncated và trả vùng rỗng. Kiểm trước khi đọc.
    [[nodiscard]] ByteView take(std::size_t count) noexcept;

    ByteView body_;
    std::size_t position_ = 0;
    std::optional<WireError> error_;
};

struct Frame {
    std::uint16_t kind = 0;
    std::size_t body_bytes = 0;
};

using FrameResult = std::expected<std::optional<Frame>, WireError>;

// Khung ở đầu buffer. Chưa đủ byte thì không có khung; đầu khung sai hoặc thân khai quá max_body
// là lỗi, báo ngay khi đủ 8 byte đầu, trước khi thân tới.
[[nodiscard]] FrameResult peek_frame(ByteView buffer, std::size_t max_body) noexcept;

} // namespace game::protocol
