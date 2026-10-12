// Khoá danh tính trên đĩa và các kiểu giữ bí mật. Tệp đúng 64 byte, không ghi đè, không ghi log.
#include "secure/secure.hpp"

#include "secure/detail/sodium.hpp"

#include <array>
#include <cstddef>
#include <cstring>
#include <expected>
#include <filesystem>
#include <fstream>
#include <ios>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::secure {
namespace {

constexpr std::string_view kHex = "0123456789abcdef";

void append_hex(std::string& text, std::byte value) {
    const auto byte = static_cast<unsigned>(value);
    const auto high = byte >> 4U;
    const auto low = byte & 0x0fU;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index): high đã kẹp trong 0..15
    text.push_back(kHex[high]);
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index): low đã kẹp trong 0..15
    text.push_back(kHex[low]);
}

[[nodiscard]] bool ensure_parent(const std::filesystem::path& path) {
    const std::filesystem::path parent = path.parent_path();
    if (parent.empty()) return true;
    std::error_code error;
    std::filesystem::create_directories(parent, error);
    return !error;
}

[[nodiscard]] Result<std::array<std::byte, kSecretBytes>> read_secret(const std::filesystem::path& path) {
    std::ifstream input{path, std::ios::binary};
    if (!input) return std::unexpected(Error::kNotFound);
    std::error_code error;
    const auto size = std::filesystem::file_size(path, error);
    if (error) return std::unexpected(Error::kIo);
    if (size != kSecretBytes) return std::unexpected(Error::kCorrupt);
    std::array<char, kSecretBytes> raw{};
    input.read(raw.data(), static_cast<std::streamsize>(raw.size()));
    if (!input) return std::unexpected(Error::kIo);
    std::array<std::byte, kSecretBytes> bytes{};
    std::memcpy(bytes.data(), raw.data(), bytes.size());
    return bytes;
}

[[nodiscard]] Result<void> write_secret(const std::filesystem::path& path, ByteView bytes) {
    if (bytes.size() != kSecretBytes) return std::unexpected(Error::kCorrupt);
    std::error_code error;
    if (std::filesystem::exists(path, error)) return std::unexpected(Error::kExists);
    if (error) return std::unexpected(Error::kIo);
    if (!ensure_parent(path)) return std::unexpected(Error::kIo);
    std::array<char, kSecretBytes> raw{};
    std::memcpy(raw.data(), bytes.data(), raw.size());
    std::ofstream output{path, std::ios::binary};
    output.write(raw.data(), static_cast<std::streamsize>(raw.size()));
    output.flush();
    if (output) return {};
    std::filesystem::remove(path, error);
    return std::unexpected(Error::kIo);
}

} // namespace

std::string_view describe(Error error) noexcept {
    switch (error) {
    case Error::kProtocol: return "bản ghi bắt tay không đúng giao thức";
    case Error::kAuthentication: return "không xác thực được máy chủ";
    case Error::kRecord: return "bản ghi mã hoá không hợp lệ";
    case Error::kExhausted: return "bộ đếm bản ghi đã cạn";
    case Error::kCapacity: return "vùng đệm không đủ chỗ";
    case Error::kState: return "luồng bảo mật không ở trạng thái này";
    case Error::kRandom: return "không lấy được số ngẫu nhiên";
    case Error::kNotFound: return "không thấy tệp khoá danh tính";
    case Error::kCorrupt: return "tệp khoá danh tính hỏng";
    case Error::kExists: return "tệp khoá danh tính đã có, không ghi đè";
    case Error::kIo: return "không đọc hay ghi được tệp khoá danh tính";
    }
    return "lỗi bảo mật không rõ";
}

SessionKeys::SessionKeys(SessionKeys&& other) noexcept {
    *this = std::move(other);
}

SessionKeys& SessionKeys::operator=(SessionKeys&& other) noexcept {
    if (this == &other) return *this;
    detail::wipe(send);
    detail::wipe(receive);
    send = other.send;
    receive = other.receive;
    detail::wipe(other.send);
    detail::wipe(other.receive);
    return *this;
}

SessionKeys::~SessionKeys() {
    detail::wipe(send);
    detail::wipe(receive);
}

void Identity::wipe() noexcept {
    detail::wipe(public_.bytes);
    detail::wipe(secret_);
}

Identity::~Identity() {
    wipe();
}

Identity::Identity(Identity&& other) noexcept {
    *this = std::move(other);
}

Identity& Identity::operator=(Identity&& other) noexcept {
    if (this == &other) return *this;
    wipe();
    public_ = other.public_;
    secret_ = other.secret_;
    other.wipe();
    return *this;
}

Result<Identity> Identity::generate() {
    Identity identity;
    const detail::KeyPairOut out{.public_key = identity.public_.bytes, .secret = identity.secret_};
    if (!detail::identity_keypair(out)) return std::unexpected(Error::kRandom);
    return identity;
}

Result<Identity> Identity::from_seed(ByteView seed) {
    if (seed.size() != detail::kSeed) return std::unexpected(Error::kProtocol);
    Identity identity;
    const detail::KeyPairOut out{.public_key = identity.public_.bytes, .secret = identity.secret_};
    if (!detail::identity_from_seed(seed, out)) return std::unexpected(Error::kRandom);
    return identity;
}

Result<Identity> Identity::load(const std::filesystem::path& path) {
    Result<std::array<std::byte, kSecretBytes>> read = read_secret(path);
    if (!read) return std::unexpected(read.error());
    Identity identity;
    const ByteView seed{read->data(), detail::kSeed};
    const detail::KeyPairOut out{.public_key = identity.public_.bytes, .secret = identity.secret_};
    const bool derived = detail::identity_from_seed(seed, out);
    const detail::SecretPair pair{.left = *read, .right = identity.secret_};
    const bool same = derived && detail::equal64(pair);
    detail::wipe(*read);
    if (!same) return std::unexpected(Error::kCorrupt);
    return identity;
}

Result<void> Identity::store_new(const std::filesystem::path& path) const {
    return write_secret(path, secret_);
}

std::string hex_encode(ByteView bytes) {
    std::string text;
    text.reserve(bytes.size() * 2);
    for (const std::byte value : bytes) {
        append_hex(text, value);
    }
    return text;
}

} // namespace game::secure
