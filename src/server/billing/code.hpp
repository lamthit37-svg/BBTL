#pragma once
// Mã đổi: 16 ký tự lấy từ bảng 31 chữ (bỏ I, L, O, 0, 1 vì dễ đọc nhầm), in thành bốn nhóm bốn ký tự
// cách bằng '-'. Entropy 16 x log2(31) ≈ 79 bit nên đoán mò không khả thi dù bộ đếm tốc độ có hở.
// Database chỉ giữ SHA-256 của mã đã chuẩn hoá (hash_code): rò bảng redeem_code không lộ mã chưa dùng.
//
// Chuẩn hoá chữ thường thành hoa và bỏ '-' lẫn khoảng trắng, vì người chơi gõ mã từ ảnh chụp hay tin
// nhắn. Mọi ký tự khác, hay độ dài khác 16, là mã sai.

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::billing {

inline constexpr std::size_t kCodeChars = 16;
inline constexpr std::string_view kCodeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

// Nguồn byte ngẫu nhiên do bên gọi đưa (secure::fill_random khi chạy thật, bộ cố định khi test).
// Trả false khi hết entropy.
struct RandomSource {
    bool (*fill)(void* context, std::span<std::byte> out) = nullptr;
    void* context = nullptr;
};

// Sinh một mã chuẩn hoá (16 ký tự, chưa có '-'). Loại mẫu để mỗi chữ đều xác suất như nhau.
// Hết entropy hoặc nguồn trả toàn byte bị loại thì nullopt.
[[nodiscard]] std::optional<std::string> mint_code(const RandomSource& source);

// "ABCD-EFGH-JKMN-PQRS" từ 16 ký tự chuẩn hoá.
[[nodiscard]] std::string format_code(std::string_view normalized);

// Chuẩn hoá chữ người chơi nhập; nullopt khi không phải một mã hợp lệ về hình dạng.
[[nodiscard]] std::optional<std::string> normalize_code(std::string_view typed);

// Hex thường của SHA-256 trên "TLBB-CODE-1:" + mã chuẩn hoá (64 ký tự). Rỗng khi libsodium hỏng.
[[nodiscard]] std::string hash_code(std::string_view normalized);

} // namespace game::billing
