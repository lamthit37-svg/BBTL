#pragma once
// Luật tên, mật khẩu và bước đăng nhập. Không đụng database và không đọc đồng hồ.
// Trần tên tài khoản ngắn hơn trần byte của tin (64) để chặn chuỗi rác; tên nhân vật giữ trần 48
// byte của protocol vì client 2026 có tên Hán và tên Việt.

#include "protocol/messages.hpp"

#include <chrono>
#include <cstddef>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::account {

inline constexpr std::size_t kAccountMin = 4;
inline constexpr std::size_t kAccountMax = 32;
inline constexpr std::size_t kPasswordMin = 6;
inline constexpr std::size_t kPasswordMax = protocol::kCreateAccountPasswordBytes;
inline constexpr std::size_t kCharacterNameMax = protocol::kCreateCharacterNameBytes;
inline constexpr int kCharacterCap = 3;
inline constexpr int kFailLimit = 8;
inline constexpr int kIpFailLimit = 30;
inline constexpr std::chrono::seconds kFailWindow{15 * 60};
inline constexpr std::size_t kTicketRaw = 32;
inline constexpr std::size_t kTicketHex = kTicketRaw * 2;

enum class NameFault : std::uint8_t { kOk, kAccount, kPassword, kCharacter };

enum class SignStep : std::uint8_t { kRate, kCreate, kMissing, kDisabled, kMismatch, kOk };

enum class CreateStep : std::uint8_t { kBadName, kFull, kTaken, kOk };

// Chỉ hạ chữ ASCII. Dùng cho tên tài khoản (chỉ có ASCII) và mật khẩu.
[[nodiscard]] std::string fold_ascii(std::string_view text);

// Khoá duy nhất của tên nhân vật đã qua canonical_character_name: hạ hoa thường cả chữ có dấu
// ("Á" và "á", "Đ" và "đ", "Ầ" và "ầ" là một tên). Tên ngoài tập chữ không tới được đây.
[[nodiscard]] std::string fold_character_name(std::string_view canonical);

// Tên nhân vật đã xoá mềm giữ chỗ cho chủ cũ chừng này; tài khoản khác không lấy được tên đó
// trong hạn (chống chiếm tên vừa xoá để giả danh). Mặc định; store.toml name_reserve_days đè lên.
inline constexpr std::chrono::hours kNameReserve{24 * 30};

// Mặt và tóc nhân vật mới: chỉ id có creatable = 1 trong faces.tsv/hairs.tsv của client (race 0 = nữ,
// race 1 = nam). Client tự gửi id nên máy chủ đối chiếu danh sách đóng; ngoài danh sách là từ chối.
// Danh sách đọc từ store.toml [security] female_faces/male_faces/female_hairs/male_hairs; thiếu khoá
// thì dùng default_look_policy() (khớp bảng client hiện tại).
struct LookPolicy {
    std::vector<std::uint16_t> female_faces;
    std::vector<std::uint16_t> male_faces;
    std::vector<std::uint16_t> female_hairs;
    std::vector<std::uint16_t> male_hairs;
};

[[nodiscard]] LookPolicy default_look_policy();
[[nodiscard]] bool look_ok(const LookPolicy& policy, protocol::Gender gender, std::uint16_t face,
    std::uint16_t hair) noexcept;
// Theo default_look_policy().
[[nodiscard]] bool look_ok(protocol::Gender gender, std::uint16_t face, std::uint16_t hair) noexcept;

// Nút cấu hình của sổ nhân vật (store.toml [security]).
struct CharacterPolicy {
    LookPolicy look = default_look_policy();
    std::chrono::seconds name_reserve = kNameReserve;
};

[[nodiscard]] NameFault account_fault(std::string_view name, std::string_view password);

// Đăng nhập không tiết lộ luật mật khẩu: hình dạng sai cũng là mật khẩu sai.
[[nodiscard]] bool sign_in_shape_ok(std::string_view name, std::string_view password);

[[nodiscard]] bool character_name_ok(std::string_view name);

// Tên đã NFC cho Latin và tiếng Việt. nullopt khi có NUL, điều khiển hướng, ký tự rộng zero,
// dấu tổ hợp không ghép được, chữ ngoài tập (Cyrillic, Hy Lạp, toàn khổ...), hoặc vượt 48 byte.
[[nodiscard]] std::optional<std::string> canonical_character_name(std::string_view name);

// Bốn octet 0–255, không số 0 thừa ở đầu. "127.0.0.1" đúng, "127.00.0.1" sai.
[[nodiscard]] bool ipv4_ok(std::string_view text);

// 64 chữ hex, hoa hoặc thường. Sai thì false và không ghi gì vào out.
[[nodiscard]] bool token_bytes(std::string_view hex, std::span<std::byte, kTicketRaw> out);

[[nodiscard]] SignStep sign_step(bool known, bool disabled, bool matched, int failures, bool auto_register) noexcept;

[[nodiscard]] CreateStep create_step(bool name_ok, int live_count, bool taken) noexcept;

[[nodiscard]] protocol::ErrorCode fault_code(NameFault fault) noexcept;
[[nodiscard]] protocol::ErrorCode sign_code(SignStep step) noexcept;
[[nodiscard]] protocol::ErrorCode create_code(CreateStep step) noexcept;

} // namespace game::account
