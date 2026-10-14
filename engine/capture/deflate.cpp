// Nén deflate theo RFC 1951 cho dòng zlib của PNG.
// Chuỗi lặp ngắn nhất bộ dò nhận là 4 byte, dù định dạng cho phép chuỗi 3 byte.
#include "capture/deflate.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <utility>
#include <vector>

namespace game::capture {

namespace {

// Cửa sổ lùi tối đa và độ dài chuỗi lặp của deflate (RFC 1951 mục 3.2.5).
constexpr std::size_t kWindow = 32768;
constexpr std::size_t kMaxMatch = 258;
// Chuỗi lặp ngắn nhất bộ dò nhận. Định dạng cho phép 3, nhưng băm 4 byte nhanh hơn và chuỗi 3 byte
// ở khoảng cách xa tốn bit hơn ba ký tự thường.
constexpr std::size_t kMinMatch = 4;
constexpr unsigned kHashBits = 15;
// Số ký hiệu của một khối: đủ lớn để bảng Huffman không chiếm phần đáng kể, đủ nhỏ để bảng bám
// theo thống kê từng vùng ảnh.
constexpr std::size_t kBlockSymbols = 32768;
constexpr std::size_t kLiteralCodes = 288;
constexpr std::size_t kDistanceCodes = 32;
constexpr std::size_t kLengthCodes = 19;
constexpr unsigned kCodeBits = 15;
constexpr unsigned kLengthCodeBits = 7;
constexpr std::size_t kEndOfBlock = 256;
constexpr std::uint32_t kMatchFlag = 0x80000000U;
constexpr std::size_t kStoredMax = 65535;

using Index = std::size_t;
using Lengths = std::span<const std::uint8_t>;
using LengthOut = std::span<std::uint8_t>;
using Counts = std::span<const std::uint32_t>;
using ByteSpan = std::span<const std::byte>;
using CodeSpan = std::span<std::uint16_t>;

[[nodiscard]] std::uint32_t load32(std::span<const std::byte> data, std::size_t offset) noexcept {
    std::uint32_t value = 0;
    std::memcpy(&value, data.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

[[nodiscard]] std::uint64_t load64(std::span<const std::byte> data, std::size_t offset) noexcept {
    std::uint64_t value = 0;
    std::memcpy(&value, data.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

// Ghi bit theo thứ tự của deflate: bit thấp trước. Mỗi lần put tối đa 32 bit.
class BitSink {
public:
    explicit BitSink(std::vector<std::byte>& out) noexcept : out_(&out) {}

    // Giá trị rồi số bit, thứ tự của mọi bộ ghi bit (lệch API-03).
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
    void put(std::uint64_t value, unsigned width) {
        bits_ |= value << count_;
        count_ += width;
        if (count_ >= 32) drain();
    }

    // Đệm bit 0 tới biên byte rồi đẩy hết byte đang chờ ra.
    void align() {
        count_ = (count_ + 7U) & ~7U;
        while (count_ != 0) {
            out_->push_back(static_cast<std::byte>(bits_ & 0xFFU));
            bits_ >>= 8U;
            count_ -= 8;
        }
    }

    // Chép thẳng byte; chỉ gọi ngay sau align().
    void bytes(std::span<const std::byte> data) { out_->insert(out_->end(), data.begin(), data.end()); }

private:
    void drain() {
        const auto low = static_cast<std::uint32_t>(bits_);
        const std::size_t offset = out_->size();
        out_->resize(offset + sizeof(low));
        std::memcpy(std::span(*out_).subspan(offset).data(), &low, sizeof(low));
        bits_ >>= 32U;
        count_ -= 32;
    }

    std::vector<std::byte>* out_;
    std::uint64_t bits_ = 0;
    unsigned count_ = 0;
};

// Mã của một độ dài hay một khoảng cách: số mã, số bit phụ và giá trị bit phụ.
struct Coded {
    std::uint32_t code = 0;
    std::uint32_t extra_bits = 0;
    std::uint32_t extra = 0;
};

// Độ dài 3..258 thành mã 257..285. Từ độ dài 11, mỗi nhóm bốn mã thêm một bit phụ.
[[nodiscard]] constexpr Coded length_code(std::uint32_t length) noexcept {
    const std::uint32_t value = length - 3;
    if (value < 8) return {.code = 257 + value};
    if (length == kMaxMatch) return {.code = 285};
    const auto top = static_cast<std::uint32_t>(std::bit_width(value)) - 1;
    const std::uint32_t bits = top - 2;
    const std::uint32_t code = 261 + (4 * bits) + ((value >> bits) & 3U);
    return {.code = code, .extra_bits = bits, .extra = value & ((1U << bits) - 1)};
}

// Khoảng cách 1..32768 thành mã 0..29. Từ khoảng cách 5, mỗi cặp mã thêm một bit phụ.
[[nodiscard]] constexpr Coded distance_code(std::uint32_t distance) noexcept {
    const std::uint32_t value = distance - 1;
    if (value < 4) return {.code = value};
    const auto top = static_cast<std::uint32_t>(std::bit_width(value)) - 1;
    const std::uint32_t bits = top - 1;
    const std::uint32_t code = (2 * top) + ((value >> bits) & 1U);
    return {.code = code, .extra_bits = bits, .extra = value & ((1U << bits) - 1)};
}

// Đối chiếu với bảng của RFC 1951 mục 3.2.5.
static_assert(length_code(3).code == 257 && length_code(10).code == 264);
static_assert(length_code(11).code == 265 && length_code(12).extra == 1);
static_assert(length_code(257).code == 284 && length_code(257).extra == 30);
static_assert(length_code(258).code == 285 && length_code(258).extra_bits == 0);
static_assert(distance_code(1).code == 0 && distance_code(4).code == 3);
static_assert(distance_code(6).code == 4 && distance_code(6).extra == 1);
static_assert(distance_code(24577).code == 29 && distance_code(24577).extra == 0);
static_assert(distance_code(32768).code == 29 && distance_code(32768).extra == 8191);

// Ký hiệu trong bộ đệm của một khối: ký tự thường là chính byte ấy; chuỗi lặp mang cờ, độ dài trừ 3
// ở bit 15..22 và khoảng cách trừ 1 ở 15 bit thấp.
// Độ dài rồi khoảng cách, thứ tự cặp của RFC 1951 (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] constexpr std::uint32_t pack_match(Index length, Index distance) noexcept {
    const auto packed_length = static_cast<std::uint32_t>(length - 3) << 15U;
    return kMatchFlag | packed_length | static_cast<std::uint32_t>(distance - 1);
}

[[nodiscard]] constexpr std::uint32_t match_length_of(std::uint32_t symbol) noexcept {
    return ((symbol >> 15U) & 0xFFU) + 3;
}

[[nodiscard]] constexpr std::uint32_t match_distance_of(std::uint32_t symbol) noexcept {
    return (symbol & 0x7FFFU) + 1;
}

// Lá của cây Huffman: một ký hiệu có dùng.
struct Leaf {
    std::uint32_t count = 0;
    std::uint16_t symbol = 0;
};

// Chỗ làm việc khi dựng cây: lá đã sắp ở 0..n-1, nút trong ở n..2n-2.
struct Tree {
    std::array<std::uint64_t, 2 * kLiteralCodes> weight{};
    std::array<std::uint16_t, 2 * kLiteralCodes> parent{};
    std::array<std::uint16_t, 2 * kLiteralCodes> depth{};
};

// Lấy nút nhẹ hơn ở đầu hai hàng: hàng lá (từ leaf tới hết count) và hàng nút trong (từ node tới
// made). Cả hai hàng đều tăng dần nên đây là thuật toán Huffman hai hàng, không cần heap.
// made rồi count là hai mốc cuối của hai hàng, cùng kiểu chỉ số (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] Index take(const Tree& tree, Index& leaf, Index& node, Index made, Index count) {
    const bool has_leaf = leaf < count;
    const bool has_node = node < made;
    const bool pick_leaf = has_leaf && (!has_node || tree.weight.at(leaf) <= tree.weight.at(node));
    return pick_leaf ? leaf++ : node++;
}

// Độ sâu của từng lá trong cây Huffman dựng từ leaves (đã sắp tăng theo count, ít nhất hai lá).
void leaf_depths(std::span<const Leaf> leaves, Tree& tree) {
    const std::size_t count = leaves.size();
    for (std::size_t index = 0; index < count; ++index) {
        tree.weight.at(index) = leaves.subspan(index, 1).front().count;
    }
    std::size_t leaf = 0;
    std::size_t node = count;
    for (std::size_t made = count; made < (2 * count) - 1; ++made) {
        const std::size_t first = take(tree, leaf, node, made, count);
        const std::size_t second = take(tree, leaf, node, made, count);
        tree.weight.at(made) = tree.weight.at(first) + tree.weight.at(second);
        tree.parent.at(first) = static_cast<std::uint16_t>(made);
        tree.parent.at(second) = static_cast<std::uint16_t>(made);
    }
    // Nút cha luôn có chỉ số lớn hơn nút con, nên đi lùi từ gốc là đủ.
    tree.depth.at((2 * count) - 2) = 0;
    for (std::size_t index = (2 * count) - 2; index-- > 0;) {
        tree.depth.at(index) = static_cast<std::uint16_t>(tree.depth.at(tree.parent.at(index)) + 1);
    }
}

// Ép bộ đếm "số mã ở mỗi độ dài" về tổng Kraft đúng bằng 1 sau khi các mã dài quá limit bị dồn về
// limit: mỗi bước bỏ một mã ở limit và tách một mã ngắn hơn thành hai mã dài hơn một bit.
// Độ dài lớn nhất dưới limit còn có mã. Luôn có khi tổng Kraft vượt 1: số ký hiệu ít hơn 2^limit.
[[nodiscard]] unsigned longest_below(std::span<const std::uint32_t> per_length, unsigned limit) {
    unsigned bits = limit - 1;
    while (bits > 1 && per_length.subspan(bits, 1).front() == 0) {
        --bits;
    }
    return bits;
}

void enforce_limit(std::span<std::uint32_t> per_length, unsigned limit) {
    std::uint64_t total = 0;
    for (unsigned bits = 1; bits <= limit; ++bits) {
        total += std::uint64_t{per_length.subspan(bits, 1).front()} << (limit - bits);
    }
    const std::uint64_t full = std::uint64_t{1} << limit;
    while (total > full) {
        const unsigned bits = longest_below(per_length, limit);
        --per_length.subspan(limit, 1).front();
        --per_length.subspan(bits, 1).front();
        per_length.subspan(bits + 1, 1).front() += 2;
        --total;
    }
}

// Gán độ dài bits cho các lá leaves.
void assign_length(std::span<const Leaf> leaves, unsigned bits, std::span<std::uint8_t> lengths) {
    for (const Leaf& leaf : leaves) {
        lengths.subspan(leaf.symbol, 1).front() = static_cast<std::uint8_t>(bits);
    }
}

// Khác gốc: thân vòng gom lá của build_lengths tách thành hàm. Ký hiệu không gặp thì không thành lá.
void add_leaf(std::array<Leaf, kLiteralCodes>& storage, std::size_t& used, Leaf leaf) {
    if (leaf.count == 0) return;
    storage.at(used++) = leaf;
}

// Độ dài mã Huffman của từng ký hiệu, không quá limit bit. counts phải có ít nhất hai ký hiệu khác
// 0 (force_two). Ký hiệu hay gặp nhất nhận mã ngắn nhất.
void build_lengths(Counts counts, unsigned limit, LengthOut lengths) {
    std::array<Leaf, kLiteralCodes> storage{};
    std::size_t used = 0;
    for (std::size_t symbol = 0; symbol < counts.size(); ++symbol) {
        const std::uint32_t count = counts.subspan(symbol, 1).front();
        const Leaf leaf{.count = count, .symbol = static_cast<std::uint16_t>(symbol)};
        add_leaf(storage, used, leaf);
    }
    const std::span<Leaf> leaves = std::span(storage).first(used);
    const auto by_count = [](const Leaf& leaf) { return std::pair(leaf.count, leaf.symbol); };
    std::ranges::sort(leaves, {}, by_count);
    Tree tree;
    leaf_depths(leaves, tree);
    std::array<std::uint32_t, 2 * kLiteralCodes> per_length{};
    for (std::size_t index = 0; index < used; ++index) {
        ++per_length.at(std::min<std::size_t>(tree.depth.at(index), limit));
    }
    enforce_limit(per_length, limit);
    std::ranges::fill(lengths, std::uint8_t{0});
    // Lá sắp tăng theo số lần gặp: đi từ cuối để ký hiệu hay gặp nhận độ dài ngắn trước.
    std::size_t next = used;
    for (unsigned bits = 1; bits <= limit; ++bits) {
        const std::size_t end = next - per_length.at(bits);
        assign_length(leaves.subspan(end, next - end), bits, lengths);
        next = end;
    }
}

// Mã rồi số bit của mã (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] constexpr std::uint16_t reverse_bits(std::uint32_t code, unsigned width) noexcept {
    std::uint32_t reversed = 0;
    for (unsigned bit = 0; bit < width; ++bit) {
        reversed = (reversed << 1U) | ((code >> bit) & 1U);
    }
    return static_cast<std::uint16_t>(reversed);
}

// Mã kế tiếp sẽ cấp cho mỗi độ dài.
using NextCodes = std::array<std::uint32_t, kCodeBits + 2>;

// Khác gốc: thân vòng gán mã của assign_codes tách thành hàm. Độ dài 0 là ký hiệu không dùng.
void assign_code(Lengths lengths, Index symbol, NextCodes& next, CodeSpan codes) {
    const std::uint8_t length = lengths.subspan(symbol, 1).front();
    if (length == 0) return;
    codes.subspan(symbol, 1).front() = reverse_bits(next.at(length)++, length);
}

// Mã chuẩn tắc từ độ dài (RFC 1951 mục 3.2.2), đảo bit sẵn vì deflate ghi mã Huffman từ bit cao.
void assign_codes(std::span<const std::uint8_t> lengths, std::span<std::uint16_t> codes) {
    std::array<std::uint32_t, kCodeBits + 2> per_length{};
    for (const std::uint8_t length : lengths) {
        ++per_length.at(length);
    }
    per_length.front() = 0;
    NextCodes next{};
    std::uint32_t code = 0;
    for (unsigned bits = 1; bits <= kCodeBits; ++bits) {
        code = (code + per_length.at(bits - 1)) << 1U;
        next.at(bits) = code;
    }
    for (std::size_t symbol = 0; symbol < lengths.size(); ++symbol) {
        assign_code(lengths, symbol, next, codes);
    }
}

// Mã và độ dài của hai bảng chữ: ký tự/độ dài và khoảng cách.
struct Codes {
    std::array<std::uint8_t, kLiteralCodes> literal_lengths{};
    std::array<std::uint16_t, kLiteralCodes> literal_codes{};
    std::array<std::uint8_t, kDistanceCodes> distance_lengths{};
    std::array<std::uint16_t, kDistanceCodes> distance_codes{};
};

// Bảng Huffman cố định của định dạng (RFC 1951 mục 3.2.6).
[[nodiscard]] Codes make_fixed() {
    Codes codes;
    std::ranges::fill(codes.literal_lengths, std::uint8_t{8});
    std::ranges::fill(std::span(codes.literal_lengths).subspan(144, 112), std::uint8_t{9});
    std::ranges::fill(std::span(codes.literal_lengths).subspan(256, 24), std::uint8_t{7});
    std::ranges::fill(codes.distance_lengths, std::uint8_t{5});
    assign_codes(codes.literal_lengths, codes.literal_codes);
    assign_codes(codes.distance_lengths, codes.distance_codes);
    return codes;
}

[[nodiscard]] const Codes& fixed_codes() {
    static const Codes kCodes = make_fixed();
    return kCodes;
}

struct Histogram {
    std::array<std::uint32_t, kLiteralCodes> literals{};
    std::array<std::uint32_t, kDistanceCodes> distances{};
    // Tổng bit phụ của mọi chuỗi lặp: như nhau với mọi bảng mã.
    std::uint64_t extra_bits = 0;
};

void tally(Histogram& histogram, std::uint32_t symbol) {
    if ((symbol & kMatchFlag) == 0) {
        ++histogram.literals.at(symbol);
        return;
    }
    const Coded length = length_code(match_length_of(symbol));
    const Coded distance = distance_code(match_distance_of(symbol));
    ++histogram.literals.at(length.code);
    ++histogram.distances.at(distance.code);
    histogram.extra_bits += length.extra_bits + distance.extra_bits;
}

[[nodiscard]] Histogram count_symbols(std::span<const std::uint32_t> symbols) {
    Histogram histogram;
    for (const std::uint32_t symbol : symbols) {
        tally(histogram, symbol);
    }
    histogram.literals.at(kEndOfBlock) = 1;
    return histogram;
}

// Bộ giải nén của zlib từ chối bảng chỉ có một mã, nên bảng nào cũng phải có ít nhất hai ký hiệu.
void force_two(std::span<std::uint32_t> counts) {
    const auto is_used = [](std::uint32_t count) { return count != 0; };
    std::uint32_t& first = counts.front();
    std::uint32_t& second = counts.subspan(1, 1).front();
    if (std::ranges::count_if(counts, is_used) < 2 && first == 0) first = 1;
    if (std::ranges::count_if(counts, is_used) < 2 && second == 0) second = 1;
}

// Tổng số bit của các ký hiệu đã đếm khi mã bằng bảng độ dài cho trước.
[[nodiscard]] std::uint64_t body_bits(const Histogram& histogram, const Codes& codes) {
    std::uint64_t bits = histogram.extra_bits;
    for (std::size_t symbol = 0; symbol < kLiteralCodes; ++symbol) {
        bits += std::uint64_t{histogram.literals.at(symbol)} * codes.literal_lengths.at(symbol);
    }
    for (std::size_t symbol = 0; symbol < kDistanceCodes; ++symbol) {
        bits += std::uint64_t{histogram.distances.at(symbol)} * codes.distance_lengths.at(symbol);
    }
    return bits;
}

// Một mục của dãy độ dài mã đã nén chạy trong header khối động: ký hiệu 0..15 là chính độ dài; 16
// lặp độ dài trước 3..6 lần; 17 và 18 lặp số 0 lần lượt 3..10 và 11..138 lần.
struct Run {
    std::uint8_t symbol = 0;
    std::uint8_t extra = 0;
};

constexpr std::array<std::uint8_t, kLengthCodes> kRunExtraBits{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7};

// Thứ tự ghi độ dài của bảng mã độ dài (RFC 1951 mục 3.2.7).
constexpr std::array<std::uint8_t, kLengthCodes> kRunOrder{
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};

struct Runs {
    std::array<Run, kLiteralCodes + kDistanceCodes> items{};
    std::size_t size = 0;

    void add(std::size_t symbol, std::size_t extra) {
        const auto narrow_symbol = static_cast<std::uint8_t>(symbol);
        items.at(size++) = {.symbol = narrow_symbol, .extra = static_cast<std::uint8_t>(extra)};
    }
};

void add_zero_runs(Runs& runs, std::size_t count) {
    while (count >= 11) {
        const std::size_t taken = std::min<std::size_t>(count, 138);
        runs.add(18, taken - 11);
        count -= taken;
    }
    if (count >= 3) runs.add(17, count - 3);
    if (count >= 3) count = 0;
    for (; count != 0; --count) {
        runs.add(0, 0);
    }
}

// Độ dài mã rồi số lần lặp liền nhau (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void add_value_runs(Runs& runs, std::uint8_t value, std::size_t count) {
    runs.add(value, 0);
    --count;
    while (count >= 3) {
        const std::size_t taken = std::min<std::size_t>(count, 6);
        runs.add(16, taken - 3);
        count -= taken;
    }
    for (; count != 0; --count) {
        runs.add(value, 0);
    }
}

// Số phần tử liên tiếp bằng nhau kể từ start.
[[nodiscard]] Index run_at(Lengths lengths, Index start) noexcept {
    const std::span<const std::uint8_t> rest = lengths.subspan(start);
    const auto differs = [&](std::uint8_t length) { return length != rest.front(); };
    return static_cast<std::size_t>(std::ranges::find_if(rest, differs) - rest.begin());
}

// Khác gốc: thân vòng của add_runs tách thành hàm. Ghi một lượt độ dài bằng nhau kể từ cursor, trả
// số phần tử của lượt.
[[nodiscard]] Index add_run(Runs& runs, Lengths lengths, Index cursor) {
    const std::uint8_t value = lengths.subspan(cursor, 1).front();
    const std::size_t count = run_at(lengths, cursor);
    if (value == 0) add_zero_runs(runs, count);
    if (value != 0) add_value_runs(runs, value, count);
    return count;
}

void add_runs(Runs& runs, std::span<const std::uint8_t> lengths) {
    std::size_t cursor = 0;
    while (cursor < lengths.size()) {
        cursor += add_run(runs, lengths, cursor);
    }
}

// Một khối Huffman động đã tính xong: bảng mã, header và số bit.
struct Plan {
    Codes codes{};
    std::size_t literal_count = 0;
    std::size_t distance_count = 0;
    Runs runs{};
    std::array<std::uint8_t, kLengthCodes> run_lengths{};
    std::array<std::uint16_t, kLengthCodes> run_codes{};
    // Số độ dài của bảng mã độ dài được ghi, theo thứ tự kRunOrder.
    std::size_t run_count = 0;
    std::uint64_t bits = 0;
};

// Chỉ số cuối cùng khác 0, cộng 1; không dưới least.
[[nodiscard]] std::size_t used_count(std::span<const std::uint8_t> lengths, std::size_t least) {
    std::size_t count = lengths.size();
    while (count > least && lengths.subspan(count - 1, 1).front() == 0) {
        --count;
    }
    return count;
}

void plan_header(Plan& plan) {
    const std::span<const std::uint8_t> literals(plan.codes.literal_lengths);
    const std::span<const std::uint8_t> distances(plan.codes.distance_lengths);
    plan.literal_count = used_count(literals, 257);
    plan.distance_count = used_count(distances, 1);
    add_runs(plan.runs, literals.first(plan.literal_count));
    add_runs(plan.runs, distances.first(plan.distance_count));
    std::array<std::uint32_t, kLengthCodes> counts{};
    for (const Run& run : std::span(plan.runs.items).first(plan.runs.size)) {
        ++counts.at(run.symbol);
    }
    force_two(counts);
    build_lengths(counts, kLengthCodeBits, plan.run_lengths);
    assign_codes(plan.run_lengths, plan.run_codes);
    plan.run_count = kLengthCodes;
    while (plan.run_count > 4 && plan.run_lengths.at(kRunOrder.at(plan.run_count - 1)) == 0) {
        --plan.run_count;
    }
    // 3 bit đầu khối, 5 + 5 + 4 bit số lượng, 3 bit cho mỗi độ dài của bảng mã độ dài.
    plan.bits += 17 + (3 * plan.run_count);
    for (std::size_t symbol = 0; symbol < kLengthCodes; ++symbol) {
        const std::uint64_t each = plan.run_lengths.at(symbol) + kRunExtraBits.at(symbol);
        plan.bits += each * counts.at(symbol);
    }
}

[[nodiscard]] Plan plan_dynamic(Histogram histogram) {
    Plan plan;
    force_two(histogram.literals);
    force_two(histogram.distances);
    // Bảng khoảng cách của khối động chỉ có 30 mã.
    const std::span<std::uint32_t> distances = std::span(histogram.distances).first(30);
    build_lengths(histogram.literals, kCodeBits, plan.codes.literal_lengths);
    build_lengths(distances, kCodeBits, std::span(plan.codes.distance_lengths).first(30));
    assign_codes(plan.codes.literal_lengths, plan.codes.literal_codes);
    assign_codes(plan.codes.distance_lengths, plan.codes.distance_codes);
    plan.bits = body_bits(histogram, plan.codes);
    plan_header(plan);
    return plan;
}

void write_header(BitSink& sink, const Plan& plan) {
    sink.put(plan.literal_count - 257, 5);
    sink.put(plan.distance_count - 1, 5);
    sink.put(plan.run_count - 4, 4);
    for (const std::uint8_t symbol : std::span(kRunOrder).first(plan.run_count)) {
        sink.put(plan.run_lengths.at(symbol), 3);
    }
    for (const Run& run : std::span(plan.runs.items).first(plan.runs.size)) {
        sink.put(plan.run_codes.at(run.symbol), plan.run_lengths.at(run.symbol));
        sink.put(run.extra, kRunExtraBits.at(run.symbol));
    }
}

void write_symbol(BitSink& sink, std::uint32_t symbol, const Codes& codes) {
    if ((symbol & kMatchFlag) == 0) {
        sink.put(codes.literal_codes.at(symbol), codes.literal_lengths.at(symbol));
        return;
    }
    const Coded length = length_code(match_length_of(symbol));
    const Coded distance = distance_code(match_distance_of(symbol));
    sink.put(codes.literal_codes.at(length.code), codes.literal_lengths.at(length.code));
    sink.put(length.extra, length.extra_bits);
    sink.put(codes.distance_codes.at(distance.code), codes.distance_lengths.at(distance.code));
    sink.put(distance.extra, distance.extra_bits);
}

void write_symbols(BitSink& sink, std::span<const std::uint32_t> symbols, const Codes& codes) {
    for (const std::uint32_t symbol : symbols) {
        write_symbol(sink, symbol, codes);
    }
    sink.put(codes.literal_codes.at(kEndOfBlock), codes.literal_lengths.at(kEndOfBlock));
}

// Một khối stored: 3 bit đầu, đệm tới biên byte, độ dài 16 bit và phần bù của nó, rồi byte thô.
// chunk dài tối đa kStoredMax byte.
void write_chunk(BitSink& sink, std::span<const std::byte> chunk, bool last) {
    sink.put(last ? 1 : 0, 1);
    sink.put(0, 2);
    sink.align();
    sink.put(chunk.size(), 16);
    sink.put(chunk.size() ^ 0xFFFFU, 16);
    sink.align();
    sink.bytes(chunk);
}

// raw thành các khối stored liền nhau; raw rỗng vẫn ra một khối rỗng (dùng làm mốc nối đoạn). Cờ
// kết thúc dòng chỉ đặt ở khối cuối cùng.
void write_stored(BitSink& sink, std::span<const std::byte> raw, bool last) {
    if (raw.empty()) {
        write_chunk(sink, raw, last);
        return;
    }
    while (!raw.empty()) {
        const std::span<const std::byte> chunk = raw.first(std::min(kStoredMax, raw.size()));
        raw = raw.subspan(chunk.size());
        write_chunk(sink, chunk, last && raw.empty());
    }
}

[[nodiscard]] std::uint64_t stored_bits(std::size_t size) noexcept {
    const std::size_t chunks = std::max<std::size_t>((size + kStoredMax - 1) / kStoredMax, 1);
    // Mỗi khối: 3 bit đầu, tối đa 7 bit đệm, 32 bit độ dài.
    return (std::uint64_t{chunks} * 42) + (std::uint64_t{size} * 8);
}

// Ghi một khối bằng cách rẻ nhất: Huffman động, Huffman cố định, hoặc để thô.
void emit_block(BitSink& sink, Counts symbols, ByteSpan raw, bool last) {
    const Histogram histogram = count_symbols(symbols);
    const Plan plan = plan_dynamic(histogram);
    const std::uint64_t fixed = 3 + body_bits(histogram, fixed_codes());
    const std::uint64_t stored = stored_bits(raw.size());
    const std::uint64_t best = std::min({plan.bits, fixed, stored});
    if (best == stored) {
        write_stored(sink, raw, last);
        return;
    }
    sink.put(last ? 1 : 0, 1);
    sink.put(best == fixed ? 1 : 2, 2);
    if (best == fixed) {
        write_symbols(sink, symbols, fixed_codes());
        return;
    }
    write_header(sink, plan);
    write_symbols(sink, symbols, plan.codes);
}

struct Match {
    std::size_t length = 0;
    std::size_t distance = 0;
};

struct Search {
    // Số ứng viên thử ở mỗi vị trí và độ dài "đủ tốt" để ngừng thử.
    unsigned probes = 0;
    std::size_t nice = 0;
};

[[nodiscard]] constexpr Search search_of(Effort effort) noexcept {
    switch (effort) {
    case Effort::kFast: return {.probes = 2, .nice = 32};
    case Effort::kBalanced: return {.probes = 12, .nice = 96};
    case Effort::kBest: return {.probes = 96, .nice = kMaxMatch};
    }
    return {};
}

// Dò chuỗi lặp bằng bảng băm 4 byte có xích: head_ giữ vị trí mới nhất của mỗi giá trị băm (cộng 1,
// 0 là chưa có), prev_ giữ vị trí trước đó cùng băm cho từng vị trí trong cửa sổ.
class Matcher {
public:
    Matcher(std::span<const std::byte> data, Effort effort)
        : data_(data), search_(search_of(effort)), head_(std::size_t{1} << kHashBits), prev_(kWindow) {}

    [[nodiscard]] Match find(std::size_t at) const noexcept {
        Match best;
        const std::size_t limit = std::min(kMaxMatch, data_.size() - at);
        if (limit < kMinMatch) return best;
        std::uint32_t candidate = head_.at(hash(at));
        for (unsigned probe = 0; probe < search_.probes && candidate != 0; ++probe) {
            const std::size_t position = candidate - 1;
            if (at - position > kWindow) break;
            const std::size_t length = common(position, at, limit);
            if (length > best.length) best = {.length = length, .distance = at - position};
            if (length >= search_.nice) break;
            candidate = prev_.at(position & (kWindow - 1));
        }
        if (best.length < kMinMatch) return {};
        return best;
    }

    // Ghi nhận count vị trí kể từ at vào bảng băm; vị trí không còn đủ 4 byte phía sau thì bỏ.
    void insert(std::size_t at, std::size_t count) noexcept {
        const std::size_t hashable = data_.size() < kMinMatch ? 0 : data_.size() - kMinMatch + 1;
        const std::size_t end = std::min(at + count, hashable);
        for (std::size_t position = at; position < end; ++position) {
            std::uint32_t& head = head_.at(hash(position));
            prev_.at(position & (kWindow - 1)) = head;
            head = static_cast<std::uint32_t>(position + 1);
        }
    }

private:
    [[nodiscard]] std::size_t hash(std::size_t at) const noexcept {
        return (load32(data_, at) * 0x9E3779B1U) >> (32U - kHashBits);
    }

    // Số byte giống nhau của hai chuỗi bắt đầu ở first và second, tối đa limit.
    [[nodiscard]] Index common(Index first, Index second, Index limit) const noexcept {
        std::size_t length = 0;
        while (length + sizeof(std::uint64_t) <= limit) {
            const std::uint64_t differ = load64(data_, first + length) ^ load64(data_, second + length);
            const auto same_bytes = static_cast<std::size_t>(std::countr_zero(differ)) / 8;
            if (differ != 0) return length + same_bytes;
            length += sizeof(std::uint64_t);
        }
        const auto byte_at = [this](Index index) { return data_.subspan(index, 1).front(); };
        while (length < limit && byte_at(first + length) == byte_at(second + length)) {
            ++length;
        }
        return length;
    }

    std::span<const std::byte> data_;
    Search search_;
    std::vector<std::uint32_t> head_;
    std::vector<std::uint32_t> prev_;
};

// Cộng dồn một khúc ngắn vào hai tổng của Adler-32; khúc đủ ngắn để hai tổng 32 bit không tràn.
// Hai tổng chạy cùng kiểu: nơi gọi ghi tên low và high.
struct AdlerSums {
    std::uint32_t& low;
    std::uint32_t& high;
};

void accumulate(ByteSpan chunk, AdlerSums sums) noexcept {
    for (const std::byte value : chunk) {
        sums.low += std::to_integer<std::uint32_t>(value);
        sums.high += sums.low;
    }
}

constexpr std::uint32_t kAdlerBase = 65521;

using CrcRow = std::array<std::uint32_t, 256>;
using CrcTables = std::array<CrcRow, 8>;

// CRC-32 của một byte đứng riêng: tám bước chia cho đa thức đảo bit.
[[nodiscard]] constexpr std::uint32_t crc_of_byte(std::uint32_t value) noexcept {
    for (int bit = 0; bit < 8; ++bit) {
        value = (value & 1U) != 0 ? (value >> 1U) ^ 0xEDB88320U : value >> 1U;
    }
    return value;
}

// Bảng kế tiếp của slice-by-8: mỗi mục của bảng trước dịch thêm một byte.
constexpr void shift_table(const CrcRow& previous, const CrcRow& base, CrcRow& next) noexcept {
    for (std::size_t index = 0; index < next.size(); ++index) {
        const std::uint32_t value = previous.at(index);
        next.at(index) = (value >> 8U) ^ base.at(value & 0xFFU);
    }
}

// Bảng slice-by-8 của CRC-32: bảng 0 là bảng một byte chuẩn, bảng k dịch thêm k byte.
[[nodiscard]] constexpr CrcTables make_crc_tables() noexcept {
    CrcTables tables{};
    for (std::uint32_t index = 0; index < 256; ++index) {
        tables.front().at(index) = crc_of_byte(index);
    }
    for (std::size_t table = 1; table < tables.size(); ++table) {
        shift_table(tables.at(table - 1), tables.front(), tables.at(table));
    }
    return tables;
}

constexpr CrcTables kCrcTables = make_crc_tables();

[[nodiscard]] std::uint32_t crc_entry(std::size_t table, std::uint32_t index) noexcept {
    return kCrcTables.at(table).at(index & 0xFFU);
}

// Tám byte một lượt: bốn byte đầu trộn với CRC đang có.
[[nodiscard]] std::uint32_t crc_step(std::uint32_t crc, std::span<const std::byte> data) noexcept {
    const std::uint32_t one = load32(data, 0) ^ crc;
    const std::uint32_t two = load32(data, 4);
    const std::uint32_t low =
        crc_entry(7, one) ^ crc_entry(6, one >> 8U) ^ crc_entry(5, one >> 16U) ^ crc_entry(4, one >> 24U);
    const std::uint32_t high =
        crc_entry(3, two) ^ crc_entry(2, two >> 8U) ^ crc_entry(1, two >> 16U) ^ crc_entry(0, two >> 24U);
    return low ^ high;
}

} // namespace

void deflate(std::span<const std::byte> data, Effort effort, bool last, std::vector<std::byte>& out) {
    out.reserve(out.size() + (data.size() / 2) + 64);
    BitSink sink(out);
    Matcher matcher(data, effort);
    std::vector<std::uint32_t> symbols;
    symbols.reserve(kBlockSymbols);
    std::size_t at = 0;
    std::size_t block_start = 0;
    while (at < data.size()) {
        const Match match = matcher.find(at);
        const std::size_t step = std::max<std::size_t>(match.length, 1);
        const auto literal = std::to_integer<std::uint32_t>(data.subspan(at, 1).front());
        symbols.push_back(match.length == 0 ? literal : pack_match(match.length, match.distance));
        matcher.insert(at, step);
        at += step;
        if (symbols.size() < kBlockSymbols) continue;
        emit_block(sink, symbols, data.subspan(block_start, at - block_start), false);
        symbols.clear();
        block_start = at;
    }
    emit_block(sink, symbols, data.subspan(block_start), last);
    // Đoạn chưa phải cuối: khối stored rỗng đưa dòng về biên byte để đoạn sau nối vào.
    if (!last) write_stored(sink, {}, false);
    sink.align();
}

std::uint32_t adler32(std::span<const std::byte> data, std::uint32_t seed) noexcept {
    // 5552 là số byte nhiều nhất cộng được trước khi tổng cao tràn 32 bit (như zlib).
    constexpr std::size_t kChunk = 5552;
    std::uint32_t low = seed & 0xFFFFU;
    std::uint32_t high = seed >> 16U;
    while (!data.empty()) {
        const std::span<const std::byte> chunk = data.first(std::min(kChunk, data.size()));
        accumulate(chunk, {.low = low, .high = high});
        low %= kAdlerBase;
        high %= kAdlerBase;
        data = data.subspan(chunk.size());
    }
    return (high << 16U) | low;
}

std::uint32_t adler32_combine(std::uint32_t first, std::uint32_t second, std::size_t second_size) noexcept {
    // Tổng thấp của cả dòng là hai tổng thấp cộng lại trừ 1 (seed tính hai lần); tổng cao của khối
    // sau phải cộng thêm (tổng thấp của khối trước trừ 1) nhân độ dài khối sau.
    const std::uint64_t length = second_size % kAdlerBase;
    const std::uint64_t low_first = first & 0xFFFFU;
    const std::uint64_t low_second = second & 0xFFFFU;
    const std::uint64_t high_first = first >> 16U;
    const std::uint64_t high_second = second >> 16U;
    const std::uint64_t low = (low_first + low_second + kAdlerBase - 1) % kAdlerBase;
    const std::uint64_t carried = (length * (low_first + kAdlerBase - 1)) % kAdlerBase;
    const std::uint64_t high = (high_first + high_second + carried) % kAdlerBase;
    return static_cast<std::uint32_t>((high << 16U) | low);
}

std::uint32_t crc32(std::span<const std::byte> data, std::uint32_t seed) noexcept {
    std::uint32_t crc = ~seed;
    while (data.size() >= 8) {
        crc = crc_step(crc, data);
        data = data.subspan(8);
    }
    for (const std::byte value : data) {
        crc = crc_entry(0, crc ^ std::to_integer<std::uint32_t>(value)) ^ (crc >> 8U);
    }
    return ~crc;
}

} // namespace game::capture
