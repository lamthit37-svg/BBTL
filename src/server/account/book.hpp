#pragma once
// Sổ tài khoản và nhân vật trong bộ nhớ. Cùng thứ tự quyết định với bản PostgreSQL ở sql.cpp:
// hình dạng, rồi trần lần sai, rồi tạo hoặc đối mật khẩu, rồi vé một lần. Test khoá thứ tự này.
// Bản chạy thật không dùng lớp này.

#include "account/rules.hpp"
#include "protocol/messages.hpp"

#include <chrono>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::account {

struct HashOps {
    bool (*hash)(void* ctx, std::string_view password, std::string& out) = nullptr;
    bool (*verify)(void* ctx, std::string_view stored, std::string_view password) = nullptr;
    void* ctx = nullptr;
};

struct RandomOps {
    bool (*fill)(void* ctx, std::span<std::byte> out) = nullptr;
    void* ctx = nullptr;
};

struct BookConfig {
    bool auto_register = false;
    std::int64_t gift_points = 0;
    std::chrono::seconds ticket_ttl{300};
    HashOps hash{};
    RandomOps random{};
    LookPolicy look = default_look_policy();
};

struct TicketResult {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    std::string hex;
};

struct ListResult {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;
    std::uint64_t account = 0;
    std::vector<protocol::CharacterSummary> characters{};
};

// Trần toạ độ điểm vào game, centimet (100 km). Số nguyên tới đây vẫn đúng tuyệt đối trong float.
inline constexpr std::int32_t kSpotLimitCm = 10'000'000;

[[nodiscard]] constexpr bool spot_fits(std::int64_t cm) noexcept {
    return cm >= -kSpotLimitCm && cm <= kSpotLimitCm;
}

// Kết quả vào game. scene/x_cm/z_cm là điểm vào do store giữ (cột position_x/position_z, đơn vị mét,
// đổi sang centimet). Phiếu standing của auth cũng dùng struct này nhưng không mang toạ độ.
struct EnterResult {
    bool ok = false;
    protocol::ErrorCode code = protocol::ErrorCode::kNoSuchCharacter;
    std::uint16_t scene = 0;
    std::int32_t x_cm = 0;
    std::int32_t z_cm = 0;
};

class MemoryBook {
public:
    explicit MemoryBook(BookConfig config);

    [[nodiscard]] TicketResult create_account(std::string_view name, std::string_view password,
        std::chrono::system_clock::time_point now);
    [[nodiscard]] TicketResult sign_in(std::string_view name, std::string_view password,
        std::chrono::system_clock::time_point now);
    [[nodiscard]] ListResult login(std::string_view ticket_hex, std::chrono::system_clock::time_point now);
    [[nodiscard]] ListResult create_character(std::uint64_t account, std::string_view name, protocol::Gender gender,
        std::uint16_t face, std::uint16_t hair);
    [[nodiscard]] ListResult remove_character(std::uint64_t account, std::uint64_t character);
    [[nodiscard]] EnterResult enter(std::uint64_t account, std::uint64_t character);

private:
    struct AccountRow {
        std::uint64_t id = 0;
        std::string name;
        std::string fold;
        std::string password_hash;
        bool disabled = false;
        std::int64_t gift_points = 0;
        std::vector<std::chrono::system_clock::time_point> failures;
    };

    struct CharacterRow {
        std::uint64_t id = 0;
        std::uint64_t account = 0;
        protocol::CharacterSummary summary;
        bool deleted = false;
    };

    struct TicketRow {
        std::uint64_t account = 0;
        std::string hex;
        std::chrono::system_clock::time_point expires;
        bool used = false;
    };

    [[nodiscard]] AccountRow* find_fold(std::string_view fold);
    [[nodiscard]] int recent_failures(const AccountRow& row, std::chrono::system_clock::time_point now) const;
    void note_failure(AccountRow& row, std::chrono::system_clock::time_point now);
    [[nodiscard]] TicketResult issue(std::uint64_t account, std::chrono::system_clock::time_point now);
    [[nodiscard]] std::vector<protocol::CharacterSummary> list_of(std::uint64_t account) const;
    [[nodiscard]] bool name_taken(std::string_view fold, std::uint64_t account) const;
    [[nodiscard]] int live_count(std::uint64_t account) const;

    BookConfig config_;
    std::vector<AccountRow> accounts_;
    std::vector<CharacterRow> characters_;
    std::vector<TicketRow> tickets_;
    std::uint64_t next_account_ = 1;
    std::uint64_t next_character_ = 1;
};

} // namespace game::account
