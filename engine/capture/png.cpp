// Ghi PNG: lọc từng hàng rồi nén deflate thành các chunk IDAT.
// Mẫu 16 bit trên máy được đổi sang big-endian trước khi lọc, đúng thứ tự byte của PNG.
// Nguồn: Forge2 src/capture/png.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ {} thừa của
// Band::stream; return hàm_void() tách thành lời gọi rồi return; biến at thành offset; plain của
// compress_band thành const và effort đặt tên trước; filter_row giữ bảy tham số kèm NOLINT; bỏ
// include <limits> không dùng.
#include "capture/png.hpp"

#include "capture/deflate.hpp"
#include "capture/frame.hpp"
#include "core/bits.hpp"
#include "jobs/jobs.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <initializer_list>
#include <ranges>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::capture {

namespace {

constexpr std::string_view kSignature = "\x89PNG\r\n\x1A\n";
// Kiểu màu của IHDR: 2 là RGB, 6 là RGB kèm alpha.
constexpr std::uint8_t kColorRgb = 2;
constexpr std::uint8_t kColorRgba = 6;
// Chiều lớn nhất PNG cho phép.
constexpr std::uint32_t kMaxSide = 0x7FFFFFFFU;
// Một dải không vượt quá mức này dù band_bytes đặt lớn: chunk IDAT giới hạn 2^31 - 1 byte.
constexpr std::size_t kMaxBand = std::size_t{64} << 20U;
constexpr std::size_t kFilters = 5;

// Filter của PNG, đúng số ghi ở đầu mỗi hàng.
enum class Filter : std::uint8_t {
    kNone,
    kSub,
    kUp,
    kAverage,
    kPaeth,
};

// Kích thước theo byte của ảnh trong PNG.
struct Layout {
    std::size_t channels = 0;
    // Byte mỗi mẫu: 1 hoặc 2.
    std::size_t sample = 0;
    std::size_t pixel = 0;
    // Byte mỗi hàng, chưa tính byte filter đứng đầu.
    std::size_t row = 0;
};

// Một lượt mã hoá: mọi dải dùng chung, chỉ đọc. frame là view mượn của người gọi encode_png.
struct Task {
    FrameView frame{};
    Layout layout{};
    PngOptions options{};
    std::uint32_t band_rows = 0;
};

// Kết quả của một dải: dòng deflate của nó, Adler-32 và cỡ của phần thô đã lọc.
struct Band {
    std::vector<std::byte> stream;
    std::uint32_t adler = 1;
    std::size_t raw_size = 0;
};

[[nodiscard]] constexpr std::byte minus(std::byte left, std::byte right) noexcept {
    return static_cast<std::byte>(std::to_integer<unsigned>(left) - std::to_integer<unsigned>(right));
}

[[nodiscard]] constexpr std::byte half_sum(std::byte left, std::byte above) noexcept {
    return static_cast<std::byte>((std::to_integer<unsigned>(left) + std::to_integer<unsigned>(above)) >> 1U);
}

// Bộ đoán Paeth: trong ba láng giềng (trái, trên, chéo trên trái) chọn cái gần trái + trên - chéo
// nhất; hoà thì ưu tiên trái, rồi trên.
[[nodiscard]] constexpr std::byte paeth(std::byte left, std::byte above, std::byte corner) noexcept {
    const int beside = std::to_integer<int>(left);
    const int over = std::to_integer<int>(above);
    const int diagonal = std::to_integer<int>(corner);
    const int estimate = beside + over - diagonal;
    const int from_left = std::abs(estimate - beside);
    const int from_up = std::abs(estimate - over);
    const int from_corner = std::abs(estimate - diagonal);
    if (from_left <= from_up && from_left <= from_corner) return left;
    return from_up <= from_corner ? above : corner;
}

void filter_sub(std::span<const std::byte> current, std::size_t pixel, std::span<std::byte> out) {
    std::ranges::copy(current.first(pixel), out.begin());
    std::ranges::transform(current.subspan(pixel), current, out.subspan(pixel).begin(), minus);
}

void filter_up(std::span<const std::byte> current, std::span<const std::byte> previous, std::span<std::byte> out) {
    std::ranges::transform(current, previous, out.begin(), minus);
}

// pixel byte đầu không có láng giềng trái: trái coi là 0.
void filter_average(std::span<const std::byte> current, std::span<const std::byte> previous, std::size_t pixel,
    std::span<std::byte> out) {
    const auto head = [](std::byte value, std::byte above) { return minus(value, half_sum({}, above)); };
    std::ranges::transform(current.first(pixel), previous, out.begin(), head);
    const auto rest = std::views::zip(current.subspan(pixel), current, previous.subspan(pixel), out.subspan(pixel));
    for (auto&& [value, left, above, target] : rest) {
        target = minus(value, half_sum(left, above));
    }
}

// pixel byte đầu: trái và chéo là 0 nên Paeth chọn láng giềng trên.
void filter_paeth(std::span<const std::byte> current, std::span<const std::byte> previous, std::size_t pixel,
    std::span<std::byte> out) {
    std::ranges::transform(current.first(pixel), previous, out.begin(), minus);
    const auto rest =
        std::views::zip(current.subspan(pixel), current, previous.subspan(pixel), previous, out.subspan(pixel));
    for (auto&& [value, left, above, corner, target] : rest) {
        target = minus(value, paeth(left, above, corner));
    }
}

void apply(Filter filter, std::span<const std::byte> current, std::span<const std::byte> previous, std::size_t pixel,
    std::span<std::byte> out) {
    switch (filter) {
    case Filter::kNone: std::ranges::copy(current, out.begin()); return;
    case Filter::kSub: filter_sub(current, pixel, out); return;
    case Filter::kUp: filter_up(current, previous, out); return;
    case Filter::kAverage: filter_average(current, previous, pixel, out); return;
    case Filter::kPaeth: filter_paeth(current, previous, pixel, out); return;
    }
}

// Tổng trị tuyệt đối khi coi mỗi byte là số có dấu: hàng đã lọc càng gần 0 thì nén càng tốt (cách
// chọn filter của libpng).
[[nodiscard]] std::size_t cost(std::span<const std::byte> filtered) noexcept {
    std::size_t total = 0;
    for (const std::byte value : filtered) {
        const auto magnitude = std::to_integer<std::size_t>(value);
        total += magnitude < 128 ? magnitude : 256 - magnitude;
    }
    return total;
}

// Thử cả năm filter vào scratch (năm hàng liền nhau) rồi trả filter có tổng nhỏ nhất.
[[nodiscard]] Filter best_filter(std::span<const std::byte> current, std::span<const std::byte> previous,
    std::size_t pixel, std::span<std::byte> scratch) {
    std::array<std::size_t, kFilters> costs{};
    for (std::size_t index = 0; index < kFilters; ++index) {
        const std::span<std::byte> out = scratch.subspan(index * current.size(), current.size());
        apply(static_cast<Filter>(index), current, previous, pixel, out);
        costs.at(index) = cost(out);
    }
    const auto least = std::ranges::min_element(costs);
    return static_cast<Filter>(least - costs.begin());
}

// Cách lọc của một dải.
enum class Filtering : std::uint8_t {
    // Up cho mọi hàng, trừ hàng đầu ảnh (hàng trên toàn 0) dùng Sub. Một lượt, không thử.
    kPlain,
    // Thử cả năm filter cho từng hàng, giữ filter có tổng trị tuyệt đối nhỏ nhất.
    kAdaptive,
};

// Lọc một hàng vào target: byte filter rồi các byte đã lọc. scratch chỉ dùng khi Adaptive.
// Bảy tham số như gốc: gom struct là đổi hình dạng mã chép (lệch API-03).
// NOLINTNEXTLINE(readability-function-size)
void filter_row(std::size_t pixel, Filtering filtering, bool top, std::span<const std::byte> current,
    std::span<const std::byte> previous, std::span<std::byte> scratch, std::span<std::byte> target) {
    const std::span<std::byte> body = target.subspan(1);
    if (filtering == Filtering::kPlain) {
        const Filter filter = top ? Filter::kSub : Filter::kUp;
        target.front() = static_cast<std::byte>(filter);
        apply(filter, current, previous, pixel, body);
        return;
    }
    const Filter filter = best_filter(current, previous, pixel, scratch);
    target.front() = static_cast<std::byte>(filter);
    const std::size_t offset = std::to_underlying(filter) * current.size();
    std::ranges::copy(scratch.subspan(offset, current.size()), body.begin());
}

void copy_bgr(std::span<const std::byte> source, std::span<std::byte> target) noexcept {
    target.front() = source.subspan(2, 1).front();
    target.subspan(1, 1).front() = source.subspan(1, 1).front();
    target.subspan(2, 1).front() = source.front();
    if (target.size() == 4) target.back() = source.back();
}

// Mẫu 16 bit của máy (little-endian) sang big-endian của PNG.
void copy_swapped(std::span<const std::byte> source, std::span<std::byte> target) noexcept {
    for (std::size_t offset = 0; offset + 1 < target.size(); offset += 2) {
        target.subspan(offset, 1).front() = source.subspan(offset + 1, 1).front();
        target.subspan(offset + 1, 1).front() = source.subspan(offset, 1).front();
    }
}

// Một điểm ảnh của khung hình sang thứ tự byte của PNG; target ngắn hơn from khi bỏ alpha.
void convert_pixel(PixelFormat format, std::span<const std::byte> from, std::span<std::byte> target) noexcept {
    switch (format) {
    case PixelFormat::kRgba8: std::ranges::copy(from.first(target.size()), target.begin()); return;
    case PixelFormat::kBgra8: copy_bgr(from, target); return;
    case PixelFormat::kRgba16: copy_swapped(from, target); return;
    case PixelFormat::kRgba32F: return;
    }
}

// Hàng line của khung hình theo thứ tự byte của PNG: R, G, B rồi A nếu giữ alpha.
void load_row(const Task& task, std::uint32_t line, std::span<std::byte> out) {
    const std::span<const std::byte> source = task.frame.row(line);
    const std::size_t pixel = task.layout.pixel;
    const std::size_t source_pixel = pixel_size(task.frame.format);
    const bool direct = task.frame.format == PixelFormat::kRgba8 && pixel == source_pixel;
    if (direct) std::ranges::copy(source, out.begin());
    if (direct) return;
    for (std::size_t column = 0; column < task.frame.width; ++column) {
        const std::span<const std::byte> from = source.subspan(column * source_pixel, source_pixel);
        convert_pixel(task.frame.format, from, out.subspan(column * pixel, pixel));
    }
}

// Lọc theo filtering rồi nén count hàng kể từ hàng first thành một dải độc lập.
[[nodiscard]] Band pack_band(const Task& task, Filtering filtering, std::uint32_t first, std::uint32_t count) {
    const std::size_t row = task.layout.row;
    std::vector<std::byte> filtered(count * (row + 1));
    std::vector<std::byte> rows(2 * row);
    std::vector<std::byte> scratch(filtering == Filtering::kPlain ? 0 : kFilters * row);
    std::span<std::byte> previous = std::span(rows).first(row);
    std::span<std::byte> current = std::span(rows).subspan(row);
    // Hàng đầu của dải vẫn lọc theo hàng ngay trên nó trong ảnh; hàng đầu ảnh thì hàng trên là 0.
    if (first != 0) load_row(task, first - 1, previous);
    for (std::uint32_t index = 0; index < count; ++index) {
        const std::uint32_t line = first + index;
        load_row(task, line, current);
        const std::span<std::byte> target = std::span(filtered).subspan(index * (row + 1), row + 1);
        filter_row(task.layout.pixel, filtering, line == 0, current, previous, scratch, target);
        std::swap(previous, current);
    }
    Band band;
    band.raw_size = filtered.size();
    band.adler = adler32(filtered);
    const bool last = first + count == task.frame.height;
    deflate(filtered, task.options.effort, last, band.stream);
    return band;
}

// Fast lọc Plain, Balanced lọc Adaptive. Best nén dải theo cả hai cách và giữ bản nhỏ hơn: tổng trị
// tuyệt đối chỉ là ước lượng, và trên vùng dốc màu mượt nó thua Up thuần (đo ở bench/capture).
// Khác gốc: effort đặt tên trước để câu bảo vệ nằm gọn một dòng sau khi enumerator thêm tiền tố k.
[[nodiscard]] Band compress_band(const Task& task, std::uint32_t first, std::uint32_t count) {
    const Effort effort = task.options.effort;
    if (effort == Effort::kFast) return pack_band(task, Filtering::kPlain, first, count);
    Band adaptive = pack_band(task, Filtering::kAdaptive, first, count);
    if (effort == Effort::kBalanced) return adaptive;
    const Band plain = pack_band(task, Filtering::kPlain, first, count);
    return plain.stream.size() < adaptive.stream.size() ? plain : adaptive;
}

void compress_bands(const Task& task, std::span<Band> bands, std::size_t begin) {
    for (std::size_t index = 0; index < bands.size(); ++index) {
        const auto first = static_cast<std::uint32_t>((begin + index) * task.band_rows);
        const std::uint32_t count = std::min(task.band_rows, task.frame.height - first);
        bands.subspan(index, 1).front() = compress_band(task, first, count);
    }
}

void append(std::vector<std::byte>& out, std::span<const std::byte> data) {
    out.insert(out.end(), data.begin(), data.end());
}

void append_be32(std::vector<std::byte>& out, std::uint32_t value) {
    const std::uint32_t big = core::to_big_endian(value);
    append(out, std::as_bytes(std::span(&big, 1)));
}

// Một chunk: độ dài (big-endian), bốn chữ tên, dữ liệu, CRC-32 của tên và dữ liệu.
void append_chunk(std::vector<std::byte>& out, std::string_view type,
    std::initializer_list<std::span<const std::byte>> parts) {
    std::size_t size = 0;
    for (const std::span<const std::byte> part : parts) {
        size += part.size();
    }
    append_be32(out, static_cast<std::uint32_t>(size));
    const std::size_t start = out.size();
    append(out, std::as_bytes(std::span(type)));
    for (const std::span<const std::byte> part : parts) {
        append(out, part);
    }
    append_be32(out, crc32(std::span(out).subspan(start)));
}

[[nodiscard]] Layout layout_of(const FrameView& frame, const PngOptions& options) noexcept {
    Layout layout;
    layout.channels = options.alpha ? 4 : 3;
    layout.sample = frame.format == PixelFormat::kRgba16 ? 2 : 1;
    layout.pixel = layout.channels * layout.sample;
    layout.row = layout.pixel * frame.width;
    return layout;
}

// Hai byte đầu của dòng zlib: phương pháp deflate cửa sổ 32 KiB, mức nén, và phần bù để cả hai chia
// hết cho 31.
[[nodiscard]] std::array<std::byte, 2> zlib_header(Effort effort) noexcept {
    switch (effort) {
    case Effort::kFast: return {std::byte{0x78}, std::byte{0x01}};
    case Effort::kBalanced: return {std::byte{0x78}, std::byte{0x9C}};
    case Effort::kBest: return {std::byte{0x78}, std::byte{0xDA}};
    }
    return {};
}

void append_header(std::vector<std::byte>& out, const Task& task) {
    std::vector<std::byte> header;
    append_be32(header, task.frame.width);
    append_be32(header, task.frame.height);
    const std::uint8_t depth = task.layout.sample == 2 ? 16 : 8;
    const std::uint8_t color = task.options.alpha ? kColorRgba : kColorRgb;
    // Độ sâu bit, kiểu màu, rồi nén 0, filter 0, không xen kẽ.
    const std::array<std::byte, 5> tail{std::byte{depth}, std::byte{color}};
    append(out, std::as_bytes(std::span(kSignature)));
    append_chunk(out, "IHDR", {header, tail});
    // Ý định hiển thị 0 (perceptual).
    const std::array<std::byte, 1> intent{};
    if (task.options.srgb) append_chunk(out, "sRGB", {intent});
}

// Ghép các dải thành một dòng zlib: hai byte đầu, các dòng deflate nối nhau, rồi Adler-32 của toàn
// bộ phần thô. Mỗi dải là một chunk IDAT.
[[nodiscard]] std::vector<std::byte> assemble(const Task& task, std::span<const Band> bands) {
    std::size_t size = 128;
    std::uint32_t adler = 1;
    for (const Band& band : bands) {
        size += band.stream.size() + 12;
        adler = adler32_combine(adler, band.adler, band.raw_size);
    }
    std::vector<std::byte> out;
    out.reserve(size);
    append_header(out, task);
    const std::array<std::byte, 2> head = zlib_header(task.options.effort);
    const std::uint32_t big = core::to_big_endian(adler);
    const std::span<const std::byte> tail = std::as_bytes(std::span(&big, 1));
    for (std::size_t index = 0; index < bands.size(); ++index) {
        const std::span<const std::byte> before = index == 0 ? head : std::span<const std::byte>();
        const bool final_band = index + 1 == bands.size();
        const std::span<const std::byte> after = final_band ? tail : std::span<const std::byte>();
        append_chunk(out, "IDAT", {before, bands.subspan(index, 1).front().stream, after});
    }
    append_chunk(out, "IEND", {});
    return out;
}

} // namespace

Result<std::vector<std::byte>> encode_png(const FrameView& frame, const PngOptions& options, jobs::JobSystem* jobs) {
    const bool sized = frame.valid() && frame.width <= kMaxSide && frame.height <= kMaxSide;
    if (!sized) return fail(ErrorCode::kInvalidArgument, "khung hình không hợp lệ");
    if (frame.format == PixelFormat::kRgba32F) {
        return fail(ErrorCode::kUnsupported, "PNG không ghi được điểm ảnh float");
    }
    Task task{.frame = frame, .layout = layout_of(frame, options), .options = options};
    // Một hàng đã tới ~17 GB với ảnh rộng u32 max: pack_band cấp count * (row + 1) mà không chặn.
    // Từ chối trước khi chia dải để trả fail thay vì ném bad_alloc.
    if (task.layout.row > kMaxBand) return fail(ErrorCode::kOutOfMemory, "hàng PNG quá lớn");
    const std::size_t band_bytes = std::clamp<std::size_t>(options.band_bytes, 1, kMaxBand);
    const std::size_t rows = std::max<std::size_t>(band_bytes / (task.layout.row + 1), 1);
    task.band_rows = static_cast<std::uint32_t>(std::min<std::size_t>(rows, frame.height));
    std::vector<Band> bands((frame.height + task.band_rows - 1) / task.band_rows);
    const std::span<Band> all = bands;
    const auto run = [&](std::size_t begin, std::size_t end) {
        compress_bands(task, all.subspan(begin, end - begin), begin);
    };
    if (jobs == nullptr) run(0, all.size());
    if (jobs != nullptr) jobs->parallel_for(all.size(), 1, run);
    return assemble(task, bands);
}

} // namespace game::capture
