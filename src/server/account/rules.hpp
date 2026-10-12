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

// Chỉ hạ chữ ASCII. Chữ có dấu giữ nguyên, nên "Á" và "á" là hai tên.
[[nodiscard]] std::string fold_ascii(std::string_view text);

[[nodiscard]] NameFault account_fault(std::string_view name, std::string_view password);

// Đăng nhập không tiết lộ luật mật khẩu: hình dạng sai cũng là mật khẩu sai.
[[nodiscard]] bool sign_in_shape_ok(std::string_view name, std::string_view password);

[[nodiscard]] bool character_name_ok(std::string_view name);

// Tên đã NFC cho Latin và tiếng Việt. nullopt khi có NUL, điều khiển hướng, ký tự rộng zero,
// dấu tổ hợp không ghép được, hoặc vượt 48 byte.
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
