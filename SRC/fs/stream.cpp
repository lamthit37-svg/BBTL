// find và rfind quét theo khúc 64 KiB bằng std::ranges::search và find_end, chồng m-1 byte giữa hai
// khúc để không lọt chỗ khớp nằm vắt qua biên. Gốc đọc từng byte qua con trỏ hàm, bản lùi
// seek-đọc-seek mỗi byte (mỗi fseek bỏ bộ đệm CRT), và giới hạn mẫu dưới 1024 byte bằng ASSERT —
// Release tràn stack.
// Nguồn: Forge2 src/fs/stream.cpp@d7fcd76. Khác gốc (so với Forge2): vòng for (;;) của scan_forward
// và scan_backward thành hàm bước gọi lặp, hai câu if trong vòng của read_full lên điều kiện lặp
// (ghi tại chỗ); bỏ phép ép uint64 sang size_t mà GCC báo thừa.
#include "fs/stream.hpp"

#include "core/error.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <utility>

namespace game::fs {

using core::ErrorCode;
using core::fail;

namespace {

// Khác gốc: gốc ép high - low sang std::size_t khi gọi load ở scan_backward. Trên nền 64 bit hai
// kiểu cùng độ rộng (GCC báo -Wuseless-cast), nên bỏ phép ép và chặn nền 32 bit ngay tại đây.
static_assert(sizeof(std::size_t) == sizeof(std::uint64_t), "quét luồng cần nền 64 bit");

constexpr std::size_t kScanChunk = std::size_t{64} * 1024;

// Vùng [low, high) mà chỗ khớp phải nằm trọn trong đó.
struct Window {
    std::uint64_t low = 0;
    std::uint64_t high = 0;
};

[[nodiscard]] std::uint64_t origin(Seek base, std::uint64_t position, std::uint64_t size) noexcept {
    switch (base) {
    case Seek::kBegin: return 0;
    case Seek::kCurrent: return position;
    case Seek::kEnd: return size;
    }
    std::unreachable();
}

[[nodiscard]] std::uint64_t saturating_add(std::uint64_t base, std::uint64_t extra) noexcept {
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    return extra > kMax - base ? kMax : base + extra;
}

[[nodiscard]] Status seek_to(Stream& stream, std::uint64_t position) {
    constexpr auto kMax = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    if (position > kMax) return fail(ErrorCode::kOverflow, "vị trí vượt int64");
    return stream.seek(Seek::kBegin, static_cast<std::int64_t>(position));
}

// Đọc [offset, offset + count) vào đầu buffer; phần trả về ngắn hơn count khi chạm EOF.
// Vị trí rồi số byte là thứ tự quen của mọi hàm đọc theo vùng (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] Result<std::span<const std::byte>> load(Stream& stream, Bytes& buffer, std::uint64_t offset,
    std::size_t count) {
    const std::span<std::byte> target = buffer.span().first(count);
    const auto read = [&] { return read_full(stream, target); };
    const auto view = [&](std::size_t got) { return std::span<const std::byte>(target.first(got)); };
    return seek_to(stream, offset).and_then(read).transform(view);
}
// NOLINTEND(bugprone-easily-swappable-parameters)

using Found = Result<std::optional<std::uint64_t>>;

// Khác gốc: gốc viết scan_forward và scan_backward là vòng for (;;) có ba câu if trong thân. Ở đây
// mỗi khúc là một lời gọi hàm bước, mép đang quét nằm trong Scan; thứ tự đọc, tìm, dời mép và các
// công thức giữ nguyên. capacity của gốc là buffer.size().
struct Scan {
    std::span<const std::byte> pattern;
    Window window;
    // Đầu khúc kế khi quét xuôi, cuối khúc kế khi quét lùi.
    std::uint64_t edge = 0;
};

// is_done sai thì quét khúc kế; đúng thì found là kết quả của cả lượt tìm.
struct Step {
    bool is_done = false;
    Found found;
};

[[nodiscard]] Step done(Found found) {
    return {.is_done = true, .found = std::move(found)};
}

[[nodiscard]] Step forward_step(Stream& stream, Bytes& buffer, Scan& scan) {
    const std::uint64_t low = scan.edge;
    const std::uint64_t high = scan.window.high;
    const auto count = static_cast<std::size_t>(std::min<std::uint64_t>(buffer.size(), high - low));
    const auto chunk = load(stream, buffer, low, count);
    if (!chunk) return done(std::unexpected(chunk.error()));
    const std::span<const std::byte> haystack = *chunk;
    const auto hit = std::ranges::search(haystack, scan.pattern);
    if (!hit.empty()) return done(low + static_cast<std::uint64_t>(hit.begin() - haystack.begin()));
    if (chunk->size() < count || count >= high - low) return done(std::nullopt);
    scan.edge += count - (scan.pattern.size() - 1);
    return {.is_done = false, .found = std::nullopt};
}

[[nodiscard]] Result<std::optional<std::uint64_t>> scan_forward(Stream& stream, std::span<const std::byte> pattern,
    Window window) {
    const std::size_t capacity = std::max(kScanChunk, pattern.size() * 2);
    Bytes buffer(capacity);
    Scan scan{.pattern = pattern, .window = window, .edge = window.low};
    Step step = forward_step(stream, buffer, scan);
    while (!step.is_done) {
        step = forward_step(stream, buffer, scan);
    }
    return std::move(step.found);
}

[[nodiscard]] Step backward_step(Stream& stream, Bytes& buffer, Scan& scan) {
    const std::uint64_t high = scan.edge;
    const std::uint64_t reach = std::min<std::uint64_t>(buffer.size(), high - scan.window.low);
    const std::uint64_t low = high - reach;
    const auto chunk = load(stream, buffer, low, high - low);
    if (!chunk) return done(std::unexpected(chunk.error()));
    const std::span<const std::byte> haystack = *chunk;
    const auto hit = std::ranges::find_end(haystack, scan.pattern);
    if (!hit.empty()) return done(low + static_cast<std::uint64_t>(hit.begin() - haystack.begin()));
    if (low == scan.window.low) return done(std::nullopt);
    scan.edge = low + (scan.pattern.size() - 1);
    return {.is_done = false, .found = std::nullopt};
}

[[nodiscard]] Result<std::optional<std::uint64_t>> scan_backward(Stream& stream, std::span<const std::byte> pattern,
    Window window) {
    const std::size_t capacity = std::max(kScanChunk, pattern.size() * 2);
    Bytes buffer(capacity);
    Scan scan{.pattern = pattern, .window = window, .edge = window.high};
    Step step = backward_step(stream, buffer, scan);
    while (!step.is_done) {
        step = backward_step(stream, buffer, scan);
    }
    return std::move(step.found);
}

// Đặt luồng ở chỗ khớp, hoặc về vị trí cũ khi không thấy hay lỗi. Seek hỏng thì trả lỗi ấy:
// trả lỗi quét trong khi vị trí không về chỗ cũ là nuốt mất hợp đồng của find.
[[nodiscard]] Result<std::optional<std::uint64_t>> settle(Stream& stream, Result<std::optional<std::uint64_t>> found,
    std::uint64_t start) {
    const std::uint64_t target = found && *found ? **found : start;
    Status sought = seek_to(stream, target);
    if (!sought) return std::unexpected(std::move(sought).error());
    return found;
}

// Byte từ vị trí hiện tại tới hết luồng, phải vừa size_t.
[[nodiscard]] Result<std::size_t> remaining(const Stream& stream) {
    const auto total = stream.size();
    if (!total) return std::unexpected(total.error());
    const std::uint64_t start = stream.position();
    const std::uint64_t left = *total > start ? *total - start : 0;
    constexpr std::uint64_t kLimit = std::numeric_limits<std::size_t>::max();
    if (left > kLimit) return fail(ErrorCode::kOverflow, "luồng lớn hơn bộ nhớ");
    return static_cast<std::size_t>(left);
}

} // namespace

Result<std::size_t> Stream::write(std::span<const std::byte> /*data*/) {
    return fail(ErrorCode::kUnsupported, "luồng không ghi được");
}

Status Stream::flush() {
    return core::ok();
}

Result<std::span<const std::byte>> Stream::map() {
    return fail(ErrorCode::kUnsupported, "luồng không ánh xạ được vào bộ nhớ");
}

bool Stream::at_end() const {
    const auto total = size();
    return !total || position() >= *total;
}

// Gốc và độ dời theo thứ tự của Stream::seek, rồi vị trí và cỡ của luồng (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
Result<std::uint64_t> seek_target(Seek base, std::int64_t offset, std::uint64_t position, std::uint64_t size) {
    const std::uint64_t from = origin(base, position, size);
    const bool backward = offset < 0;
    // 0 - x trên số không dấu lấy được độ lớn của cả INT64_MIN mà không tràn có dấu.
    const auto raw = static_cast<std::uint64_t>(offset);
    const std::uint64_t distance = backward ? 0 - raw : raw;
    if (backward && distance > from) return fail(ErrorCode::kInvalidArgument, "seek tới vị trí âm");
    const bool overflow = !backward && distance > std::numeric_limits<std::uint64_t>::max() - from;
    if (overflow) return fail(ErrorCode::kOverflow, "seek tràn vị trí");
    return backward ? from - distance : from + distance;
}
// NOLINTEND(bugprone-easily-swappable-parameters)

Result<std::size_t> read_full(Stream& stream, std::span<std::byte> out) {
    std::size_t total = 0;
    // Khác gốc: gốc là while (total < out.size()) có hai câu if trong thân (lỗi thì trả ngay, đọc
    // được 0 byte thì break). Hai điều kiện dừng ấy lên điều kiện lặp; got khởi đầu khác 0 để lượt
    // đầu chỉ phụ thuộc total < out.size() như gốc.
    Result<std::size_t> got = std::size_t{1};
    while (got && *got != 0 && total < out.size()) {
        got = stream.read(out.subspan(total));
        total += got.value_or(0);
    }
    if (!got) return std::unexpected(std::move(got).error());
    return total;
}

Result<Bytes> read_all(Stream& stream) {
    const auto left = remaining(stream);
    if (!left) return std::unexpected(left.error());
    Bytes bytes(*left);
    const auto got = read_full(stream, bytes.span());
    if (!got) return std::unexpected(got.error());
    bytes.shrink(*got);
    return bytes;
}

Result<std::string> read_text(Stream& stream, std::size_t max) {
    const auto left = remaining(stream);
    if (!left) return std::unexpected(left.error());
    Result<std::size_t> got = 0;
    const auto fill = [&](char* out, std::size_t room) {
        got = read_full(stream, std::as_writable_bytes(std::span(out, room)));
        return got.value_or(0);
    };
    std::string text;
    text.resize_and_overwrite(std::min(*left, max), fill);
    if (!got) return std::unexpected(std::move(got).error());
    return text;
}

Result<std::optional<std::uint64_t>> find(Stream& stream, std::span<const std::byte> pattern, std::uint64_t max_bytes) {
    const std::uint64_t start = stream.position();
    if (pattern.empty()) return start;
    if (pattern.size() > max_bytes) return std::nullopt;
    const Window window{.low = start, .high = saturating_add(start, max_bytes)};
    return settle(stream, scan_forward(stream, pattern, window), start);
}

Result<std::optional<std::uint64_t>> rfind(Stream& stream, std::span<const std::byte> pattern,
    std::uint64_t max_bytes) {
    const std::uint64_t start = stream.position();
    if (pattern.empty()) return start;
    const std::uint64_t reach = std::min(max_bytes, start);
    if (pattern.size() > reach) return std::nullopt;
    const Window window{.low = start - reach, .high = start};
    return settle(stream, scan_backward(stream, pattern, window), start);
}

} // namespace game::fs
