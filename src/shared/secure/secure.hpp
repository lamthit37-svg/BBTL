#pragma once
// Bắt tay và luồng bản ghi nằm dưới khung protocol. Thiết kế và chỗ khác bản Dev:
// docs/SERVER-BAO-MAT.md. Mọi phép mật mã là libsodium. Khoá tự xoá khi huỷ.
// Không hàm nào ghi log, và không bản rõ nào thoát ra trước khi chữ ký khớp.

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::secure {

enum class [[nodiscard]] Error : std::uint8_t {
    kProtocol = 1,
    kAuthentication,
    kRecord,
    kExhausted,
    kCapacity,
    kState,
    kRandom,
    kNotFound,
    kCorrupt,
    kExists,
    kIo,
    // Tệp khoá danh tính mà tài khoản khác đọc được (secure/private_file.hpp).
    kExposed,
};

// Câu tiếng Việt cho log của gate. Không chứa vật liệu khoá.
[[nodiscard]] std::string_view describe(Error error) noexcept;

using ByteView = std::span<const std::byte>;

template <typename T>
using Result = std::expected<T, Error>;

inline constexpr std::size_t kPublicBytes = 32;
inline constexpr std::size_t kSecretBytes = 64;
inline constexpr std::size_t kSignatureBytes = 64;
inline constexpr std::size_t kEphemeralBytes = 32;
inline constexpr std::size_t kSessionBytes = 32;
inline constexpr std::size_t kTagBytes = 16;
inline constexpr std::size_t kLabelBytes = 8;
inline constexpr std::uint16_t kSecureVersion = 1;
inline constexpr std::size_t kClientHelloBytes = kLabelBytes + 2 + kEphemeralBytes;
inline constexpr std::size_t kServerHelloBytes = kEphemeralBytes + kSignatureBytes;
inline constexpr std::size_t kTranscriptBytes = (kEphemeralBytes * 2) + kLabelBytes + 2;
inline constexpr std::size_t kMaxPlainBytes = 8 + 4096;
inline constexpr std::size_t kMaxBodyBytes = kMaxPlainBytes + kTagBytes;
inline constexpr std::size_t kRecordHeaderBytes = 2;
inline constexpr std::size_t kMaxRecordBytes = kRecordHeaderBytes + kMaxBodyBytes;
inline constexpr std::uint64_t kCounterLast = ~std::uint64_t{0};

inline constexpr std::array<std::byte, kLabelBytes> kLabel{std::byte{'T'}, std::byte{'L'}, std::byte{'B'},
    std::byte{'B'}, std::byte{'S'}, std::byte{'E'}, std::byte{'C'}, std::byte{'1'}};

static_assert(kClientHelloBytes == 42);
static_assert(kServerHelloBytes == 96);
static_assert(kTranscriptBytes == 74);
static_assert(kMaxRecordBytes == 4122);

struct PublicKey {
    std::array<std::byte, kPublicBytes> bytes{};
};

// Hai khoá một chiều. Chỉ chuyển được: bản bị chuyển đi bị xoá ngay, không chờ huỷ.
struct SessionKeys {
    std::array<std::byte, kSessionBytes> send{};
    std::array<std::byte, kSessionBytes> receive{};

    SessionKeys() = default;
    SessionKeys(const SessionKeys&) = delete;
    SessionKeys& operator=(const SessionKeys&) = delete;
    SessionKeys(SessionKeys&& other) noexcept;
    SessionKeys& operator=(SessionKeys&& other) noexcept;
    ~SessionKeys();
};

// Khoá danh tính Ed25519. Tệp là đúng 64 byte bí mật của libsodium. store_new tạo tệp riêng và không ghi đè;
// load từ chối tệp không riêng (kExposed) trước khi đọc nội dung.
class Identity {
public:
    [[nodiscard]] static Result<Identity> generate();
    // Hạt giống 32 byte. Dùng cho test và fuzz có hạt cố định; cổng chạy thật không gọi.
    [[nodiscard]] static Result<Identity> from_seed(ByteView seed);
    [[nodiscard]] static Result<Identity> load(const std::filesystem::path& path);
    [[nodiscard]] Result<void> store_new(const std::filesystem::path& path) const;

    [[nodiscard]] PublicKey public_key() const noexcept { return public_; }

    ~Identity();
    Identity(const Identity&) = delete;
    Identity& operator=(const Identity&) = delete;
    Identity(Identity&& other) noexcept;
    Identity& operator=(Identity&& other) noexcept;

private:
    friend class ServerHandshake;
    Identity() = default;
    void wipe() noexcept;
    [[nodiscard]] ByteView secret_view() const noexcept { return secret_; }

    PublicKey public_{};
    std::array<std::byte, kSecretBytes> secret_{};
};

struct Absorb {
    std::size_t consumed = 0;
};

using AbsorbResult = Result<Absorb>;

// Máy chủ, chờ đúng một lời chào 42 byte. identity phải sống lâu hơn đối tượng này.
class ServerHandshake {
public:
    explicit ServerHandshake(const Identity& identity) noexcept;
    ~ServerHandshake();
    ServerHandshake(const ServerHandshake&) = delete;
    ServerHandshake& operator=(const ServerHandshake&) = delete;
    ServerHandshake(ServerHandshake&& other) noexcept;
    ServerHandshake& operator=(ServerHandshake&& other) noexcept;

    // Rút byte của lời chào. Chưa đủ thì consumed nhỏ hơn input và chưa xong.
    [[nodiscard]] AbsorbResult absorb(ByteView input) noexcept;
    [[nodiscard]] bool is_done() const noexcept { return stage_ == Stage::kDone; }
    [[nodiscard]] bool is_broken() const noexcept { return stage_ == Stage::kBroken; }
    [[nodiscard]] Error error() const noexcept { return error_; }
    // Rỗng khi chưa xong hoặc đã hỏng: lời chào sai không có câu trả lời.
    [[nodiscard]] ByteView reply() const noexcept;
    // Chỉ gọi khi is_done. Gọi lần hai là lỗi lập trình.
    [[nodiscard]] SessionKeys take_keys() noexcept;

private:
    enum class Stage : std::uint8_t { kCollect, kDone, kBroken, kMoved };

    [[nodiscard]] std::size_t take(ByteView input) noexcept;
    [[nodiscard]] bool hello_ok() const noexcept;
    [[nodiscard]] bool derive() noexcept;
    void wipe_ephemeral() noexcept;
    void break_with(Error error) noexcept;

    const Identity* identity_ = nullptr;
    std::array<std::byte, kClientHelloBytes> hello_{};
    std::size_t filled_ = 0;
    std::array<std::byte, kEphemeralBytes> server_public_{};
    std::array<std::byte, kEphemeralBytes> server_secret_{};
    std::array<std::byte, kServerHelloBytes> reply_{};
    SessionKeys keys_;
    bool keys_taken_ = false;
    Stage stage_ = Stage::kCollect;
    Error error_ = Error::kProtocol;
};

// Máy khách. Khoá tạm bí mật bị xoá khi finish trả về, đúng hay sai.
class ClientHandshake {
public:
    [[nodiscard]] static Result<ClientHandshake> begin();
    ~ClientHandshake();
    ClientHandshake(const ClientHandshake&) = delete;
    ClientHandshake& operator=(const ClientHandshake&) = delete;
    ClientHandshake(ClientHandshake&& other) noexcept;
    ClientHandshake& operator=(ClientHandshake&& other) noexcept;

    [[nodiscard]] ByteView hello() const noexcept;
    // reply đúng 96 byte. Sai chữ ký thì không có SessionKeys nào được tạo ra.
    [[nodiscard]] Result<SessionKeys> finish(ByteView reply, PublicKey pinned) noexcept;

private:
    enum class Stage : std::uint8_t { kEmpty, kWait, kFinished, kMoved };

    ClientHandshake() = default;
    void wipe_secret() noexcept;

    std::array<std::byte, kEphemeralBytes> public_{};
    std::array<std::byte, kEphemeralBytes> secret_{};
    std::array<std::byte, kClientHelloBytes> hello_{};
    Stage stage_ = Stage::kEmpty;
};

struct CounterMarks {
    std::uint64_t send = 0;
    std::uint64_t receive = 0;
};

struct Opened {
    std::size_t consumed = 0;
    std::size_t written = 0;
};

using OpenResult = Result<Opened>;
using SealResult = Result<std::size_t>;

// Một chiều niêm, một chiều mở. Vùng đệm dở đúng một bản ghi, không cấp phát thêm.
// plain của open_bytes phải chứa được kMaxPlainBytes; thiếu là lỗi lập trình.
class RecordPipe {
public:
    explicit RecordPipe(SessionKeys keys) noexcept;
    ~RecordPipe();
    RecordPipe(const RecordPipe&) = delete;
    RecordPipe& operator=(const RecordPipe&) = delete;
    RecordPipe(RecordPipe&& other) noexcept;
    RecordPipe& operator=(RecordPipe&& other) noexcept;

    [[nodiscard]] OpenResult open_bytes(ByteView input, std::span<std::byte> plain) noexcept;
    [[nodiscard]] SealResult seal(ByteView plain, std::span<std::byte> out) noexcept;
    // Đẩy bộ đếm tới, không lùi. Chỉ test gọi, để thử trần mà không niêm 2^64 bản ghi.
    void advance_counters(CounterMarks marks) noexcept;
    [[nodiscard]] bool has_partial() const noexcept { return pending_ > 0; }
    [[nodiscard]] bool is_broken() const noexcept { return broken_; }
    [[nodiscard]] Error error() const noexcept { return error_; }

private:
    [[nodiscard]] bool pull(ByteView& input, Opened& opened, std::size_t need) noexcept;
    [[nodiscard]] bool length_ok() const noexcept;
    [[nodiscard]] std::uint16_t body_length() const noexcept;
    [[nodiscard]] bool decrypt(std::span<std::byte> plain, Opened& opened) noexcept;
    void wipe_pending() noexcept;
    void break_with(Error error) noexcept;

    SessionKeys keys_;
    std::uint64_t send_counter_ = 0;
    std::uint64_t receive_counter_ = 0;
    std::array<std::byte, kMaxRecordBytes> pending_bytes_{};
    std::size_t pending_ = 0;
    bool broken_ = false;
    Error error_ = Error::kRecord;
};

// Hex thường, hai chữ số một byte. Lệnh sinh khoá in khoá công khai; không dùng cho nửa bí mật.
[[nodiscard]] std::string hex_encode(ByteView bytes);

// Entropy của libsodium. false khi thư viện không khởi động được.
[[nodiscard]] bool fill_random(std::span<std::byte> out) noexcept;

// SHA-256, out đúng 32 byte. Dùng để lưu vết vé, không phải để băm mật khẩu.
[[nodiscard]] bool sha256(ByteView data, std::span<std::byte> out) noexcept;

// Argon2id. ops và mem_bytes là tham số libsodium; mem_bytes tính bằng byte.
// auth.toml ghi mem_limit_kib, bên gọi nhân 1024 trước khi đưa vào đây.
struct PasswordPolicy {
    std::uint64_t ops = 2;
    std::size_t mem_bytes = 67108864;
};

// out nhận chuỗi băm có dấu kết thúc, khoảng dưới 128 byte. Không ghi mật khẩu ra log.
[[nodiscard]] bool hash_password(std::string_view password, PasswordPolicy policy, std::string& out);

[[nodiscard]] bool verify_password(std::string_view hash, std::string_view password) noexcept;

// Xoá byte nhạy cảm. Vùng rỗng thì không làm gì.
void wipe_bytes(std::span<std::byte> region) noexcept;

// Khung ipc: nonce 24 byte rồi bản mã XChaCha20-Poly1305 (thân cộng 16 byte tag). Khoá 32 byte.
[[nodiscard]] std::optional<std::vector<std::byte>> ipc_seal(ByteView key, ByteView plain);
[[nodiscard]] std::optional<std::vector<std::byte>> ipc_open(ByteView key, ByteView boxed);

// HMAC-SHA512-256, tag 32 byte. Dùng cho vé năng lực giữa auth và store.
[[nodiscard]] bool mac32(ByteView key, ByteView message, std::span<std::byte> tag);
[[nodiscard]] bool mac32_verify(ByteView key, ByteView message, ByteView tag) noexcept;

} // namespace game::secure
