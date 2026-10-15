/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/fs/buny.cpp
 *  PHÂN HỆ   : Fs / Buny
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt fs/buny.hpp.
 *  - Dựng bảng giữ đúng thứ tự thử và cách đếm bộ nhớ khoá của
 *    bunyArHashTableConstruct, vì thứ tự đó quyết định seed và salt được chọn:
 *    seed bắt đầu từ 0, xô nhiều va chạm xử lý trước, xô cùng cỡ theo chỉ số ô,
 *    salt bắt đầu từ seed + 1, và seed bị bỏ khi tổng khoá đã chép vượt số ô.
 *    Gốc dùng một vùng nhớ khoá chép đi chép lại; ở đây mảng phẳng cấp một lần
 *    mỗi seed, nhanh hơn gốc (đo ở docs/modules/fs.md) mà ra cùng bảng.
 *  - Nguồn: Forge2 src/fs/buny.cpp@d7fcd76. Khác gốc (so với Forge2): các vòng
 *    lặp có câu if trong thân (has_twins, any_twins, salted_slots, displace,
 *    place_collisions, try_seed, is_safe_name, build) đưa điều kiện dừng lên
 *    điều kiện lặp hoặc tách thân thành hàm, thứ tự thử seed, salt và ô giữ
 *    nguyên (ghi tại chỗ); bỏ {} thừa của thành viên Draft, Draft khởi tạo bằng
 *    gán trường; Miss có kiểu nền.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fs/buny.hpp"

#include "core/error.hpp"
#include "fs/stream.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <limits>
#include <optional>
#include <ranges>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::fs::buny {

namespace {

constexpr std::uint64_t kSaltFlag = std::uint64_t{1} << 63U;
constexpr std::uint64_t kMurmurM = 0xc6a4a7935bd1e995ULL;
constexpr unsigned kMurmurR = 47;
// Ô trên số node: gốc chọn 2 ("Values less then 1.5 won't work").
constexpr std::uint64_t kSlotsPerNode = 2;
// Ba word đầu của bảng là HashHeader, các ô theo sau.
constexpr std::uint64_t kHeadWords = 3;
// Số salt hỏng liên tiếp của một xô trước khi soát tên trùng.
constexpr std::uint64_t kPatience = 256;

[[nodiscard]] std::uint64_t load64(std::span<const std::byte> bytes) noexcept {
    std::uint64_t value = 0;
    std::memcpy(&value, bytes.data(), sizeof(value));
    return value;
}

[[nodiscard]] std::uint64_t slot_of(std::uint64_t seed, std::uint64_t slots, std::string_view name) {
    return murmur64a(std::as_bytes(std::span(name)), seed) % slots;
}

// Bảng đang dựng cho một seed, toàn mảng phẳng cấp một lần: ô sơ cấp của từng node, số node mỗi ô,
// và các node xếp theo ô (dạng CSR, giữ thứ tự node như vùng nhớ khoá của gốc).
struct Draft {
    std::span<const std::string_view> names;
    std::uint64_t seed = 0;
    std::uint64_t slots = 0;
    std::vector<std::uint64_t> words;
    // Chỉ số node và ô vừa uint32_t (build chặn số node).
    std::vector<std::uint32_t> primary;
    std::vector<std::uint32_t> counts;
    // Sau group(): vị trí ngay sau node cuối của mỗi ô trong members.
    std::vector<std::uint32_t> ends;
    std::vector<std::uint32_t> members;
    std::uint32_t max_collisions = 0;
    // Ô thử cho một xô và bản sắp xếp của nó, cỡ max_collisions.
    std::vector<std::uint64_t> taken;
    std::vector<std::uint64_t> sorted;

    // span chưa có at() ở C++23; subspan vẫn được STL kiểm biên ở bản debug.
    [[nodiscard]] std::string_view name(std::uint32_t node) const { return names.subspan(node, 1).front(); }
    [[nodiscard]] std::uint64_t& cell(std::uint64_t index) { return words.at(kHeadWords + index); }
    [[nodiscard]] std::span<const std::uint32_t> bucket(std::uint64_t slot) const {
        const std::uint32_t count = counts.at(slot);
        return std::span(members).subspan(ends.at(slot) - count, count);
    }
};

// Lượt một: mọi tên vào ô của seed.
void place_primary(Draft& draft) {
    for (std::uint32_t node = 0; const std::string_view name : draft.names) {
        const std::uint64_t index = slot_of(draft.seed, draft.slots, name);
        draft.cell(index) = std::uint64_t{node} + 1;
        draft.primary.at(node) = static_cast<std::uint32_t>(index);
        draft.max_collisions = std::max(draft.max_collisions, ++draft.counts.at(index));
        ++node;
    }
}

// Gốc chép lại cả xô mỗi lần thêm khoá và bỏ seed khi tổng khoá đã chép, cộng hai mảng tạm cỡ va
// chạm lớn nhất, vượt số ô (ép uint32). Tổng đó là Σ k(k+1)/2 theo cỡ cuối của từng xô, không phụ
// thuộc thứ tự chèn, nên tính một lần sau lượt một mà vẫn bỏ đúng seed như gốc.
[[nodiscard]] bool fits(const Draft& draft) {
    std::uint64_t copied = 0;
    for (const std::uint64_t count : draft.counts) {
        copied += count * (count + 1) / 2;
    }
    const auto capacity = static_cast<std::uint32_t>(draft.slots);
    return copied + (2 * std::uint64_t{draft.max_collisions}) <= capacity;
}

// Xếp node theo ô, giữ thứ tự node trong mỗi ô: ends bắt đầu là đầu mỗi ô, mỗi node ghi vào rồi
// tiến lên, nên khi xong ends là cuối mỗi ô.
void group(Draft& draft) {
    std::uint32_t start = 0;
    for (std::uint64_t slot = 0; slot < draft.slots; ++slot) {
        draft.ends.at(slot) = start;
        start += draft.counts.at(slot);
    }
    for (std::uint32_t node = 0; node < draft.primary.size(); ++node) {
        std::uint32_t& end = draft.ends.at(draft.primary.at(node));
        draft.members.at(end) = node;
        ++end;
    }
}

// Seed không dùng được thì thử seed sau; tên trùng thì không seed nào dùng được.
enum class Miss : std::uint8_t { kSeed, kTwins };
using Tried = std::expected<void, Miss>;

using Nodes = std::span<const std::uint32_t>;

// Khác gốc: thân vòng lặp của has_twins tách ra đây. Tên của node ở it có trùng một node đứng
// trước nó trong xô không.
[[nodiscard]] bool repeats_earlier(const Draft& draft, Nodes bucket, Nodes::iterator it) {
    const auto name_of = [&draft](std::uint32_t node) { return draft.name(node); };
    const std::span<const std::uint32_t> earlier(bucket.begin(), it);
    return std::ranges::find(earlier, draft.name(*it), name_of) != earlier.end();
}

// Hai tên trùng chung ô với mọi seed lẫn salt nên không bảng nào tách được chúng: gốc thử salt tới
// 2^63 (treo), hay bỏ mọi seed khi xô trùng quá lớn. Tên trùng luôn chung xô sơ cấp nên chỉ so
// trong từng xô, và chỉ so khi có dấu hiệu (kPatience, fits): bảng hợp lệ không trả giá nào.
[[nodiscard]] bool has_twins(const Draft& draft, std::span<const std::uint32_t> bucket) {
    bool is_found = false;
    for (auto it = bucket.begin(); it != bucket.end() && !is_found; ++it) {
        is_found = repeats_earlier(draft, bucket, it);
    }
    return is_found;
}

// Khác gốc: gốc viết hai câu if trong thân vòng lặp (xô dưới 2 node thì bỏ qua, thấy tên trùng thì
// trả true ngay).
[[nodiscard]] bool any_twins(const Draft& draft) {
    bool is_found = false;
    for (std::uint64_t slot = 0; slot < draft.slots && !is_found; ++slot) {
        is_found = draft.counts.at(slot) >= 2 && has_twins(draft, draft.bucket(slot));
    }
    return is_found;
}

// Ô của từng khoá trong xô theo salt; false khi có ô đã bị chiếm hay hai khoá chung ô.
[[nodiscard]] bool salted_slots(Draft& draft, std::span<const std::uint32_t> bucket, std::uint64_t salt) {
    // Khác gốc: gốc là range-for có câu if (ô đã bị chiếm) return false trong thân; ở đây vòng dừng
    // ở ô bị chiếm đầu tiên và ô ấy không được ghi vào taken, như gốc.
    const auto pairs = std::views::zip(bucket, draft.taken);
    bool is_free = true;
    for (auto it = pairs.begin(); it != pairs.end() && is_free; ++it) {
        const auto [node, taken] = *it;
        const std::uint64_t index = slot_of(salt, draft.slots, draft.name(node));
        is_free = draft.cell(index) == 0;
        taken = is_free ? index : taken;
    }
    if (!is_free) return false;
    const auto chosen = std::span(draft.taken).first(bucket.size());
    const auto order = std::span(draft.sorted).first(bucket.size());
    std::ranges::copy(chosen, order.begin());
    std::ranges::sort(order);
    return std::ranges::adjacent_find(order) == order.end();
}

void claim(Draft& draft, std::span<const std::uint32_t> bucket, std::uint64_t slot, std::uint64_t salt) {
    for (const auto [node, taken] : std::views::zip(bucket, draft.taken)) {
        draft.cell(taken) = std::uint64_t{node} + 1;
    }
    draft.cell(slot) = salt | kSaltFlag;
}

// Kết quả thử một salt cho một xô.
enum class Salted : std::uint8_t {
    kRetry,
    kTwins,
    kPlaced,
};

// Khác gốc: thân vòng lặp của displace tách ra đây; thứ tự soát tên trùng, thử ô, chiếm ô giữ
// nguyên.
[[nodiscard]] Salted try_salt(Draft& draft, Nodes bucket, std::uint64_t slot, std::uint64_t salt) {
    const std::uint64_t first = draft.seed + 1;
    const bool stuck = salt - first == kPatience && has_twins(draft, bucket);
    if (stuck) return Salted::kTwins;
    if (!salted_slots(draft, bucket, salt)) return Salted::kRetry;
    claim(draft, bucket, slot, salt);
    return Salted::kPlaced;
}

// Tìm salt cho xô ở ô slot rồi chiếm các ô. Xô thường xong trong vài salt; tới salt thứ kPatience
// mà chưa xong thì soát tên trùng một lần. Miss::kSeed khi hết salt 63 bit.
[[nodiscard]] Tried displace(Draft& draft, std::uint64_t slot) {
    const std::span<const std::uint32_t> bucket = draft.bucket(slot);
    const std::uint64_t first = draft.seed + 1;
    Salted state = Salted::kRetry;
    for (std::uint64_t salt = first; salt < kSaltFlag && state == Salted::kRetry; ++salt) {
        state = try_salt(draft, bucket, slot, salt);
    }
    if (state == Salted::kTwins) return std::unexpected(Miss::kTwins);
    if (state == Salted::kRetry) return std::unexpected(Miss::kSeed);
    return {};
}

// Lượt hai: xô nhiều va chạm trước, cùng cỡ thì theo chỉ số ô.
[[nodiscard]] Tried place_collisions(Draft& draft, std::uint64_t collisions) {
    // Khác gốc: gốc viết hai câu if trong thân vòng lặp (xô khác cỡ thì bỏ qua, displace hỏng thì
    // trả lỗi ngay).
    Tried placed{};
    for (std::uint64_t slot = 0; slot < draft.slots && placed; ++slot) {
        const bool is_sized = draft.counts.at(slot) == collisions;
        placed = is_sized ? displace(draft, slot) : Tried{};
    }
    return placed;
}

[[nodiscard]] std::expected<std::vector<std::uint64_t>, Miss> try_seed(std::span<const std::string_view> names,
    std::uint64_t seed) {
    const std::uint64_t slots = (names.size() * kSlotsPerNode) + 1;
    // Khác gốc: gốc khởi tạo Draft bằng designated initializer; thành viên vector không còn {} nên
    // GCC báo thiếu trường, vì thế gán từng trường.
    Draft draft;
    draft.names = names;
    draft.seed = seed;
    draft.slots = slots;
    draft.words.assign(kHeadWords + slots, 0);
    draft.words.at(1) = seed;
    draft.words.at(2) = slots;
    draft.primary.resize(names.size());
    draft.counts.assign(slots, 0);
    draft.ends.resize(slots);
    draft.members.resize(names.size());
    place_primary(draft);
    group(draft);
    // Seed bị bỏ vì xô quá lớn: nếu do tên trùng thì seed nào cũng bị bỏ, nên dừng hẳn.
    if (!fits(draft)) return std::unexpected(any_twins(draft) ? Miss::kTwins : Miss::kSeed);
    draft.taken.resize(draft.max_collisions);
    draft.sorted.resize(draft.max_collisions);
    // Khác gốc: câu if (!placed) return của gốc nằm trong thân vòng lặp.
    Tried placed{};
    for (std::uint64_t collisions = draft.max_collisions; collisions > 1 && placed; --collisions) {
        placed = place_collisions(draft, collisions);
    }
    if (!placed) return std::unexpected(placed.error());
    return std::move(draft.words);
}

// Khác gốc: thân vòng lặp của is_safe_name tách ra đây. Vị trí index không kết thúc đoạn nào thì
// true; kết thúc một đoạn thì kiểm đoạn ấy rồi dời begin sang đoạn kế.
[[nodiscard]] bool ends_safely(std::string_view name, std::size_t index, std::size_t& begin) {
    if (index != name.size() && name.at(index) != '/') return true;
    const std::string_view segment = name.substr(begin, index - begin);
    if (segment.empty() || segment == "." || segment == "..") return false;
    begin = index + 1;
    return true;
}

} // namespace

std::string_view name(Format format) noexcept {
    switch (format) {
    case Format::kRaw: return "raw";
    case Format::kLz4Blocks: return "LZ4";
    case Format::kZstdBlocks: return "zstd";
    }
    return "unknown";
}

bool is_safe_name(std::string_view name) noexcept {
    const bool banned = name.empty() || name.find_first_of("\\:") != std::string_view::npos;
    if (banned) return false;
    std::size_t begin = 0;
    bool is_safe = true;
    for (std::size_t i = 0; i <= name.size() && is_safe; ++i) {
        is_safe = ends_safely(name, i, begin);
    }
    return is_safe;
}

std::uint64_t murmur64a(std::span<const std::byte> key, std::uint64_t seed) noexcept {
    std::uint64_t hash = seed ^ (key.size() * kMurmurM);
    const std::size_t blocks = key.size() / 8;
    for (std::size_t i = 0; i < blocks; ++i) {
        std::uint64_t word = load64(key.subspan(i * 8, 8));
        word *= kMurmurM;
        word ^= word >> kMurmurR;
        word *= kMurmurM;
        hash ^= word;
        hash *= kMurmurM;
    }
    // Phần đuôi: gốc dùng switch rơi từ case 7 xuống case 1; XOR giao hoán nên thứ tự không đổi kết
    // quả.
    const std::span<const std::byte> tail = key.subspan(blocks * 8);
    for (unsigned shift = 0; const std::byte byte : tail) {
        hash ^= std::to_integer<std::uint64_t>(byte) << shift;
        shift += 8;
    }
    if (!tail.empty()) hash *= kMurmurM;
    hash ^= hash >> kMurmurR;
    hash *= kMurmurM;
    hash ^= hash >> kMurmurR;
    return hash;
}

std::optional<HashTable> HashTable::build(std::span<const std::string_view> names) {
    // Đếm số node mỗi ô bằng uint32_t như gốc.
    constexpr std::size_t kLimit = std::numeric_limits<std::uint32_t>::max() / kSlotsPerNode;
    if (names.size() > kLimit) return std::nullopt;
    constexpr std::uint64_t kLastSeed = std::numeric_limits<std::uint64_t>::max();
    // Khác gốc: gốc là for (;;) có hai câu if trong thân. Seed kế chỉ được thử khi seed trước hỏng
    // không vì tên trùng và chưa tới seed cuối, như gốc.
    std::uint64_t seed = 0;
    auto words = try_seed(names, seed);
    while (!words && words.error() != Miss::kTwins && seed != kLastSeed) {
        ++seed;
        words = try_seed(names, seed);
    }
    if (!words) return std::nullopt;
    return HashTable(std::move(*words));
}

Result<HashTable> HashTable::parse(std::span<const std::byte> bytes) {
    using core::ErrorCode;
    constexpr std::size_t kHead = sizeof(HashHeader);
    const bool aligned = bytes.size() >= kHead + 8 && bytes.size() % 8 == 0;
    if (!aligned) return core::fail(ErrorCode::kCorrupt, "bảng băm sai cỡ");
    std::vector<std::uint64_t> words(bytes.size() / 8);
    std::memcpy(words.data(), bytes.data(), bytes.size());
    const bool matches = words.at(2) == words.size() - kHeadWords;
    if (!matches) return core::fail(ErrorCode::kCorrupt, "số ô của bảng băm không khớp cỡ");
    return HashTable(std::move(words));
}

std::optional<std::uint64_t> HashTable::candidate(std::string_view name) const noexcept {
    // parse và build bảo đảm words_ có đúng kHeadWords + slots() phần tử.
    std::uint64_t value = words_.at(kHeadWords + slot_of(seed(), slots(), name));
    const std::uint64_t salt = value & ~kSaltFlag;
    if (value >= kSaltFlag) value = words_.at(kHeadWords + slot_of(salt, slots(), name));
    if (value == 0 || value >= kSaltFlag) return std::nullopt;
    return value - 1;
}

} // namespace game::fs::buny
