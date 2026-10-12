// Định dạng archive Buny v0 — thay phần "Buny Archive format definitions" của IFileSystem.h và các
// hàm bunyAr* trong FileSystem.c (_Ref). Tương thích từng byte với archive do công cụ buny của The
// Forge ghi: header 80 B, node 40 B, mục LZ4/ZSTD chia khối với bảng con trỏ 64 bit (1 bit nén, 40
// bit offset, 23 bit cỡ trừ 1), bảng băm hoàn hảo MurmurHash64A hai tầng. Hash, mã hoá con trỏ và
// dựng bảng port nguyên toán tử: cùng danh sách tên ra cùng bảng như gốc. Khác gốc: đọc khoá qua
// memcpy (gốc ép const uint64_t* lên byte không căn lề, UB), bảng băm đọc từ tệp được kiểm cỡ khớp
// số ô trước khi tra (gốc chỉ kiểm khi bật validation, không thì tra ngoài mảng).
// Nguồn: Forge2 src/fs/buny.hpp@d7fcd76. Khác gốc (so với Forge2): thêm NOLINT cho kiểu nền 64 bit
// của Format.
#pragma once

#include "fs/stream.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::fs::buny {

// Chuỗi ASCII thành mảng byte, bỏ số 0 cuối.
template <std::size_t N>
// NOLINTNEXTLINE(*-avoid-c-arrays): tham chiếu mảng để suy N từ chuỗi hằng.
[[nodiscard]] consteval std::array<std::byte, N - 1> magic_of(const char (&text)[N]) {
    std::array<std::byte, N - 1> out{};
    for (std::size_t i = 0; i < out.size(); ++i) {
        out.at(i) = static_cast<std::byte>(text[i]);
    }
    return out;
}

inline constexpr std::array<std::byte, 16> kMagic = magic_of("BunyArchTheForge");
// Tên dài nhất, không tính số 0 cuối (BUNYAR_FILE_NAME_LENGTH_MAX).
inline constexpr std::size_t kNameMax = 511;
// Khối lớn nhất: trường cỡ của con trỏ khối có 23 bit, lưu cỡ trừ 1.
inline constexpr std::uint64_t kBlockMax = std::uint64_t{1} << 23U;
inline constexpr std::uint64_t kOffsetMax = (std::uint64_t{1} << 40U) - 1;

// Kiểu nền 64 bit là độ rộng của trường Node::format trên đĩa, không thu nhỏ được (lệch KG-06).
// NOLINTNEXTLINE(performance-enum-size)
enum class Format : std::uint64_t {
    kRaw = 0,
    kLz4Blocks = 3,
    kZstdBlocks = 5,
};

// "raw", "LZ4", "zstd"; giá trị lạ đọc từ tệp là "unknown" (bunyArFormatName).
[[nodiscard]] std::string_view name(Format format) noexcept;

struct Pointer64 {
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
};

struct Pointer32 {
    std::uint32_t offset = 0;
    std::uint32_t size = 0;
};

// Bộ đọc dùng được archive khi compatible <= phiên bản bộ đọc (0) <= actual.
struct Version {
    std::uint32_t compatible = 0;
    std::uint32_t actual = 0;
};

struct Header {
    std::array<std::byte, 16> magic{};
    Version version{};
    std::uint64_t flags = 0;
    Pointer64 nodes{};
    Pointer64 names{};
    // Có bảng băm khi size >= sizeof(HashHeader).
    Pointer64 hash_table{};
};

struct Node {
    std::uint64_t format = 0;
    // Cỡ gốc, cũng là cỡ đọc ra.
    std::uint64_t size = 0;
    // Tính từ Header::names.offset; size không tính số 0 cuối.
    Pointer32 name{};
    // Vùng lưu của mục, tuyệt đối trong archive.
    Pointer64 data{};
};

// Đầu vùng lưu của mục chia khối, theo sau là count con trỏ khối u64 rồi các khối.
struct BlockHeader {
    std::uint64_t block_size = 0;
    // Cỡ khối cuối, 1..block_size.
    std::uint64_t last_size = 0;
    std::uint64_t count = 0;
};

// Theo sau là slots ô u64.
struct HashHeader {
    std::uint64_t reserved = 0;
    std::uint64_t seed = 0;
    std::uint64_t slots = 0;
};

static_assert(sizeof(Header) == 80 && sizeof(Node) == 40, "bố cục trên đĩa của Buny v0");
static_assert(sizeof(BlockHeader) == 24 && sizeof(HashHeader) == 24, "bố cục trên đĩa của Buny v0");

// Phần mở rộng của Forge2, nằm ngay sau Header khi Header::flags có kExtension. Bộ đọc của The
// Forge không xét flags và đi theo các con trỏ trong Header, nên vẫn mở được archive có phần này.
// Mỗi mục chia thành đơn vị băm: mục thô một đơn vị (cả vùng lưu); mục chia khối một đơn vị cho
// BlockHeader cùng bảng con trỏ, rồi một đơn vị mỗi khối. Băm XXH3-64 trên byte lưu (khối đã nén),
// nên kiểm được trước khi đưa dữ liệu vào bộ giải nén.
inline constexpr std::uint64_t kExtension = 1;
inline constexpr std::array<std::byte, 8> kExtensionMagic = magic_of("Forge2X1");

struct Extension {
    std::array<std::byte, 8> magic{};
    // sizeof(Extension) lúc ghi; bản sau thêm trường thì bộ đọc cũ bỏ qua phần thừa.
    std::uint64_t size = 0;
    // u64 mỗi node theo thứ tự node: chỉ số đơn vị đầu tiên của mục trong sums.
    Pointer64 starts{};
    // u64 mỗi đơn vị.
    Pointer64 sums{};
    std::uint64_t nodes_sum = 0;
    std::uint64_t names_sum = 0;
    // 0 khi không có bảng băm.
    std::uint64_t hash_sum = 0;
};

static_assert(sizeof(Extension) == 72, "bố cục trên đĩa của phần mở rộng Forge2");

// Tên mục an toàn: không rỗng, tương đối, không dấu chéo ngược, ':', không đoạn rỗng, "." hay "..".
// Tên đã chuẩn hoá (fs/path.hpp) của tệp trong cây tài nguyên luôn qua được; giải nén ra đĩa không
// thoát được khỏi thư mục đích (gốc chỉ chặn tiền tố "../" nên "a/../../x" thoát ra ngoài).
[[nodiscard]] bool is_safe_name(std::string_view name) noexcept;

// Một khối: offset tính từ cuối bảng con trỏ; size là cỡ lưu, 1..kBlockMax.
struct Block {
    bool compressed = false;
    std::uint32_t size = 0;
    std::uint64_t offset = 0;
};

inline constexpr std::uint64_t kSizeMask = (std::uint64_t{1} << 23U) - 1;

// bunyArDecodeBlockPointer.
[[nodiscard]] constexpr Block decode(std::uint64_t pointer) noexcept {
    return Block{.compressed = (pointer & 1U) != 0,
        .size = static_cast<std::uint32_t>((pointer >> 41U) & kSizeMask) + 1,
        .offset = (pointer >> 1U) & kOffsetMax};
}

// bunyArEncodeBlockPointer; nullopt khi offset hay cỡ vượt trường của nó.
[[nodiscard]] constexpr std::optional<std::uint64_t> encode(Block block) noexcept {
    const std::uint64_t size = std::uint64_t{block.size} - 1;
    if (block.offset > kOffsetMax || size > kSizeMask) return std::nullopt;
    const std::uint64_t flag = block.compressed ? 1U : 0U;
    return flag | (block.offset << 1U) | (size << 41U);
}

// MurmurHash64A của Austin Appleby, như archiveHashMurmur2_64.
[[nodiscard]] std::uint64_t murmur64a(std::span<const std::byte> key, std::uint64_t seed) noexcept;

// Bảng băm hoàn hảo "hash and displace": ô chứa chỉ số node + 1, 0 là rỗng, hoặc salt | 1 << 63 bảo
// tra lại với salt làm seed. words() đúng bố cục trong tệp: HashHeader rồi các ô.
class HashTable {
public:
    // bunyArHashTableConstruct; names[i] là tên của node i. nullopt khi có hai tên trùng (gốc treo)
    // hay khi hết seed (gốc gọi là "joke code path").
    [[nodiscard]] static std::optional<HashTable> build(std::span<const std::string_view> names);

    // Bảng đọc từ tệp: phải đúng sizeof(HashHeader) + 8 * slots byte, slots > 0.
    [[nodiscard]] static Result<HashTable> parse(std::span<const std::byte> bytes);

    // Chỉ số node duy nhất có thể mang tên name; người gọi so tên thật (bunyArHashTableLookup).
    [[nodiscard]] std::optional<std::uint64_t> candidate(std::string_view name) const noexcept;

    [[nodiscard]] std::uint64_t seed() const noexcept { return words_.at(1); }
    [[nodiscard]] std::uint64_t slots() const noexcept { return words_.at(2); }
    [[nodiscard]] std::span<const std::uint64_t> words() const noexcept { return words_; }

private:
    explicit HashTable(std::vector<std::uint64_t> words) noexcept : words_(std::move(words)) {}

    std::vector<std::uint64_t> words_;
};

} // namespace game::fs::buny
