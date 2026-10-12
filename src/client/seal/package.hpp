#pragma once
// Niêm asset ngoài tiến trình game. Định dạng TLBBPAK1: XChaCha20-Poly1305, BLAKE2b có khoá,
// crypto_kdf (libsodium 1.0.22). Không tự viết mật mã.
// Client không liên kết module này: đường nạp, khung hình và byte đồ hoạ không đổi.
// Byte mở ra trùng byte đã đưa vào. Method trên đĩa luôn là Stored (0): không nén, không đổi mẫu.
// Tên không nằm ở dạng rõ. Bảng kê thienlong/manifest.txt cũng là một mục đã niêm.
// Khác gói TLBB có zstd: gặp method khác 0 thì từ chối, không trả byte nén như thể đó là asset.
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::seal {

inline constexpr std::size_t kKeyBytes = 32;
inline constexpr std::size_t kHeaderBytes = 64;
inline constexpr std::string_view kManifestName = "thienlong/manifest.txt";

enum class Error : std::uint8_t {
    kCrypto,
    kBadMagic,
    kBadVersion,
    kWrongKey,
    kCorrupt,
    kMissing,
    kDuplicate,
    kName,
    kIo,
    kTooLarge,
};

// 32 byte bí mật. Mọi bản tự xoá khi hết đời, kể cả bản chép tạm.
struct Key {
    std::array<std::byte, kKeyBytes> bytes{};

    Key() = default;
    Key(const Key& other);
    Key& operator=(const Key& other);
    Key(Key&& other) noexcept;
    Key& operator=(Key&& other) noexcept;
    ~Key();
};

struct Item {
    std::string name;
    std::vector<std::byte> bytes;
};

using Blob = std::vector<std::byte>;
using Bytes = std::span<const std::byte>;
using KeyResult = std::expected<Key, Error>;
using BlobResult = std::expected<Blob, Error>;
using ItemsResult = std::expected<std::vector<Item>, Error>;
using CountResult = std::expected<std::uint64_t, Error>;
using UnitResult = std::expected<void, Error>;

[[nodiscard]] KeyResult random_key();

// Niêm các mục. Tên tương đối, dấu /, không .., không trùng cả khi chỉ khác hoa thường.
[[nodiscard]] BlobResult seal(const Key& key, std::span<const Item> items);

// Mở một mục theo đúng tên đã niêm.
[[nodiscard]] BlobResult open_named(const Key& key, Bytes package, std::string_view name);

// Đọc bảng kê đã niêm rồi mở từng mục. Không trả lại chính bảng kê.
[[nodiscard]] ItemsResult open_all(const Key& key, Bytes package);

// Mở hết mục. Sai khoá hoặc sai dấu thì không có số lượng.
[[nodiscard]] CountResult verify_bytes(const Key& key, Bytes package);

[[nodiscard]] std::string_view describe(Error error) noexcept;

} // namespace game::seal
