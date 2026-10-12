// Cài đặt tầng byte. Số ghép và tách từng byte bằng phép dịch nên byte trên dây chỉ phụ thuộc giá
// trị, không phụ thuộc endianness hay padding; không memcpy struct, không reinterpret_cast vùng
// byte. Nguồn: TLBB Dev src/protocol/wire.cpp. Khác gốc: kiểm UTF-8 trên vùng byte và coi byte 0 là
// byte đầu sai ngay trong bảng phân loại; Writer kiểm trần thân ở từng lần nối thay vì chỉ ở
// finish.
#include "protocol/wire.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::protocol {
namespace {

static_assert(std::numeric_limits<float>::is_iec559, "f32 trên dây là IEEE 754 binary32");

// Độ dài chuỗi và số phần tử danh sách đều ghi bằng u16.
constexpr std::size_t kMaxCount = 0xFFFF;

// Ghi các byte của value vào dest, byte thấp trước; dest dài bao nhiêu thì ghi bấy nhiêu byte.
void store(std::span<std::byte> dest, std::uint64_t value) noexcept {
    unsigned shift = 0;
    for (std::byte& part : dest) {
        part = static_cast<std::byte>((value >> shift) & 0xFFU);
        shift += 8;
    }
}

// Ghép các byte của source thành số, byte thấp trước. Vùng rỗng (đọc hỏng) ra 0.
[[nodiscard]] std::uint64_t load(ByteView source) noexcept {
    std::uint64_t value = 0;
    unsigned shift = 0;
    for (const std::byte part : source) {
        value |= std::to_integer<std::uint64_t>(part) << shift;
        shift += 8;
    }
    return value;
}

// Byte đầu của một ký tự UTF-8: số byte của ký tự và khoảng hợp lệ của byte thứ hai. length 0 là
// byte đầu sai. Bảng theo Unicode 15 chương 3, bảng 3-7; byte 0 bị cấm trên dây nên cũng là sai.
struct Lead {
    std::size_t length = 0;
    unsigned low = 0;
    unsigned high = 0;
};

// Một dải byte đầu [first, last] cùng chung một Lead.
struct LeadRange {
    unsigned first = 0;
    unsigned last = 0;
    Lead lead;
};

// E0 cấm mã hoá dài thừa, ED cấm nửa cặp thay thế U+D800 tới U+DFFF, F0 cấm mã hoá dài thừa, F4
// cấm vượt U+10FFFF. Byte ngoài mọi dải (0, 80 tới C1, F5 tới FF) là byte đầu sai.
constexpr std::array kLeads{
    LeadRange{.first = 0x01, .last = 0x7F, .lead = {.length = 1, .low = 0, .high = 0}},
    LeadRange{.first = 0xC2, .last = 0xDF, .lead = {.length = 2, .low = 0x80, .high = 0xBF}},
    LeadRange{.first = 0xE0, .last = 0xE0, .lead = {.length = 3, .low = 0xA0, .high = 0xBF}},
    LeadRange{.first = 0xE1, .last = 0xEC, .lead = {.length = 3, .low = 0x80, .high = 0xBF}},
    LeadRange{.first = 0xED, .last = 0xED, .lead = {.length = 3, .low = 0x80, .high = 0x9F}},
    LeadRange{.first = 0xEE, .last = 0xEF, .lead = {.length = 3, .low = 0x80, .high = 0xBF}},
    LeadRange{.first = 0xF0, .last = 0xF0, .lead = {.length = 4, .low = 0x90, .high = 0xBF}},
    LeadRange{.first = 0xF1, .last = 0xF3, .lead = {.length = 4, .low = 0x80, .high = 0xBF}},
    LeadRange{.first = 0xF4, .last = 0xF4, .lead = {.length = 4, .low = 0x80, .high = 0x8F}},
};

[[nodiscard]] Lead classify(unsigned byte) noexcept {
    const auto found = std::ranges::find_if(kLeads,
        [byte](const LeadRange& range) { return byte >= range.first && byte <= range.last; });
    return found == kLeads.end() ? Lead{} : found->lead;
}

[[nodiscard]] bool is_continuation(std::byte byte) noexcept {
    return (std::to_integer<unsigned>(byte) & 0xC0U) == 0x80U;
}

// Số byte của ký tự ở đầu text, 0 khi ký tự hỏng hay bị cắt cụt. text không rỗng.
[[nodiscard]] std::size_t sequence_length(ByteView text) noexcept {
    const Lead lead = classify(std::to_integer<unsigned>(text.front()));
    if (lead.length == 0 || lead.length > text.size()) return 0;
    if (lead.length == 1) return 1;
    const auto second = std::to_integer<unsigned>(text[1]);
    if (second < lead.low || second > lead.high) return 0;
    const ByteView rest = text.subspan(2, lead.length - 2);
    if (!std::ranges::all_of(rest, is_continuation)) return 0;
    return lead.length;
}

// UTF-8 đúng RFC 3629 và không có byte 0, để không cắt ngang API kiểu C phía sau.
[[nodiscard]] bool is_text(ByteView text) noexcept {
    std::size_t length = 1;
    while (length != 0 && !text.empty()) {
        length = sequence_length(text);
        text = text.subspan(length);
    }
    return length != 0;
}

} // namespace

std::string_view describe(WireError error) noexcept {
    switch (error) {
    case WireError::kTruncated: return "thiếu byte";
    case WireError::kTrailingBytes: return "thừa byte sau tin";
    case WireError::kTooLong: return "chuỗi hoặc danh sách vượt trần";
    case WireError::kBadText: return "chuỗi không phải UTF-8 hợp lệ hoặc có byte 0";
    case WireError::kNonFinite: return "số thực NaN hoặc vô cực";
    case WireError::kBadEnum: return "giá trị enum, bool hoặc optional lạ";
    case WireError::kBodyTooLarge: return "thân khung vượt trần";
    case WireError::kBadFlags: return "cờ khung chưa định nghĩa";
    case WireError::kUnknownKind: return "mã tin lạ hoặc sai cổng, sai chiều";
    case WireError::kOutOfRange: return "giá trị ngoài khoảng cho phép";
    }
    return "lỗi dây không rõ";
}

Writer::Writer(std::vector<std::byte>& out) : out_(&out), start_(out.size()) {
    out.resize(start_ + kHeaderBytes);
}

template <std::unsigned_integral Value>
void Writer::put(Value value) {
    std::array<std::byte, sizeof(Value)> raw{};
    store(raw, value);
    append(raw);
}

void Writer::u8(std::uint8_t value) {
    put(value);
}

void Writer::u16(std::uint16_t value) {
    put(value);
}

void Writer::u32(std::uint32_t value) {
    put(value);
}

void Writer::u64(std::uint64_t value) {
    put(value);
}

void Writer::i8(std::int8_t value) {
    u8(static_cast<std::uint8_t>(value));
}

void Writer::i16(std::int16_t value) {
    u16(static_cast<std::uint16_t>(value));
}

void Writer::i32(std::int32_t value) {
    u32(static_cast<std::uint32_t>(value));
}

void Writer::i64(std::int64_t value) {
    u64(static_cast<std::uint64_t>(value));
}

void Writer::f32(float value) {
    if (!std::isfinite(value)) {
        fail(WireError::kNonFinite);
        return;
    }
    u32(std::bit_cast<std::uint32_t>(value));
}

void Writer::boolean(bool value) {
    u8(static_cast<std::uint8_t>(value));
}

void Writer::text(std::string_view value, std::size_t max_bytes) {
    if (value.size() > max_bytes || value.size() > kMaxCount) {
        fail(WireError::kTooLong);
        return;
    }
    const ByteView raw = std::as_bytes(std::span{value});
    if (!is_text(raw)) {
        fail(WireError::kBadText);
        return;
    }
    u16(static_cast<std::uint16_t>(value.size()));
    append(raw);
}

void Writer::bytes(ByteView value) {
    append(value);
}

void Writer::count(std::size_t value, std::size_t max_count) {
    if (value > max_count || value > kMaxCount) {
        fail(WireError::kTooLong);
        return;
    }
    u16(static_cast<std::uint16_t>(value));
}

void Writer::fail(WireError error) noexcept {
    if (!error_) error_ = error;
}

bool Writer::is_ok() const noexcept {
    return !error_.has_value();
}

WireStatus Writer::finish(std::uint16_t kind) {
    if (error_) {
        out_->resize(start_);
        return std::unexpected(*error_);
    }
    const std::span<std::byte> header = std::span{*out_}.subspan(start_, kHeaderBytes);
    store(header.first(4), body_bytes());
    store(header.subspan(4, 2), kind);
    store(header.subspan(6, 2), 0);
    return {};
}

void Writer::append(ByteView value) {
    if (error_) return;
    if (value.size() > kMaxBodyBytes - body_bytes()) {
        fail(WireError::kBodyTooLarge);
        return;
    }
    out_->insert(out_->end(), value.begin(), value.end());
}

std::size_t Writer::body_bytes() const noexcept {
    return out_->size() - start_ - kHeaderBytes;
}

Reader::Reader(ByteView body) noexcept : body_(body) {}

std::uint8_t Reader::u8() noexcept {
    return static_cast<std::uint8_t>(load(take(sizeof(std::uint8_t))));
}

std::uint16_t Reader::u16() noexcept {
    return static_cast<std::uint16_t>(load(take(sizeof(std::uint16_t))));
}

std::uint32_t Reader::u32() noexcept {
    return static_cast<std::uint32_t>(load(take(sizeof(std::uint32_t))));
}

std::uint64_t Reader::u64() noexcept {
    return load(take(sizeof(std::uint64_t)));
}

std::int8_t Reader::i8() noexcept {
    return static_cast<std::int8_t>(u8());
}

std::int16_t Reader::i16() noexcept {
    return static_cast<std::int16_t>(u16());
}

std::int32_t Reader::i32() noexcept {
    return static_cast<std::int32_t>(u32());
}

std::int64_t Reader::i64() noexcept {
    return static_cast<std::int64_t>(u64());
}

float Reader::f32() noexcept {
    const auto value = std::bit_cast<float>(u32());
    if (std::isfinite(value)) return value;
    fail(WireError::kNonFinite);
    return 0.0F;
}

bool Reader::boolean() noexcept {
    const std::uint8_t raw = u8();
    if (raw > 1) fail(WireError::kBadEnum);
    return raw == 1;
}

std::string Reader::text(std::size_t max_bytes) {
    const std::size_t size = u16();
    if (size > max_bytes) fail(WireError::kTooLong);
    if (error_) return {};
    const ByteView raw = take(size);
    if (raw.size() != size) return {};
    if (!is_text(raw)) fail(WireError::kBadText);
    if (error_) return {};
    std::string value(size, '\0');
    std::ranges::transform(raw, value.begin(), [](std::byte part) { return static_cast<char>(part); });
    return value;
}

void Reader::bytes(std::span<std::byte> out) noexcept {
    const ByteView raw = take(out.size());
    if (raw.size() == out.size()) std::ranges::copy(raw, out.begin());
}

std::size_t Reader::count(std::size_t max_count) noexcept {
    const std::size_t size = u16();
    if (size > max_count) fail(WireError::kTooLong);
    // Dựa vào bất biến "mỗi phần tử chiếm ít nhất một byte trên dây", do luật G6 của
    // gen_protocol.py bảo đảm (phần tử list không được là record mã hoá ra 0 byte). Nhờ đó số
    // khai vượt số byte còn lại thì thân chắc chắn thiếu: báo luôn để bên gọi không cấp phát theo
    // số khai.
    if (size > body_.size() - position_) fail(WireError::kTruncated);
    if (error_) return 0;
    return size;
}

void Reader::fail(WireError error) noexcept {
    if (!error_) error_ = error;
}

bool Reader::is_ok() const noexcept {
    return !error_.has_value();
}

WireStatus Reader::finish() const noexcept {
    if (error_) return std::unexpected(*error_);
    if (position_ != body_.size()) return std::unexpected(WireError::kTrailingBytes);
    return {};
}

ByteView Reader::take(std::size_t count) noexcept {
    if (error_) return {};
    if (count > body_.size() - position_) {
        fail(WireError::kTruncated);
        return {};
    }
    const ByteView part = body_.subspan(position_, count);
    position_ += count;
    return part;
}

FrameResult peek_frame(ByteView buffer, std::size_t max_body) noexcept {
    if (buffer.size() < kHeaderBytes) return std::nullopt;
    const std::uint64_t body_bytes = load(buffer.first(4));
    const auto kind = static_cast<std::uint16_t>(load(buffer.subspan(4, 2)));
    if (load(buffer.subspan(6, 2)) != 0) return std::unexpected(WireError::kBadFlags);
    if (body_bytes > std::min(max_body, kMaxBodyBytes)) {
        return std::unexpected(WireError::kBodyTooLarge);
    }
    if (body_bytes > buffer.size() - kHeaderBytes) return std::nullopt;
    return Frame{.kind = kind, .body_bytes = static_cast<std::size_t>(body_bytes)};
}

} // namespace game::protocol
