#include "billing/code.hpp"

#include "secure/secure.hpp"

#include <array>
#include <cstddef>
#include <optional>
#include <span>
#include <string>

namespace game::billing {
namespace {

constexpr std::size_t kAlphabetSize = 31;
static_assert(kCodeAlphabet.size() == kAlphabetSize);
// 248 = 8 x 31 là bội lớn nhất của 31 không vượt 256: byte từ 248 trở lên bị loại để phép chia lấy
// dư không lệch về các chữ đầu bảng.
constexpr unsigned kByteLimit = 248;
constexpr int kRefillMost = 8;
constexpr std::string_view kHashPrefix = "TLBB-CODE-1:";

} // namespace

std::optional<std::string> mint_code(const RandomSource& source) {
    if (source.fill == nullptr) return std::nullopt;
    std::string code;
    code.reserve(kCodeChars);
    std::array<std::byte, 32> pool{};
    for (int round = 0; round < kRefillMost && code.size() < kCodeChars; ++round) {
        if (!source.fill(source.context, pool)) return std::nullopt;
        for (const std::byte byte : pool) {
            const auto value = std::to_integer<unsigned>(byte);
            if (value >= kByteLimit) continue;
            code.push_back(kCodeAlphabet[value % kAlphabetSize]);
            if (code.size() == kCodeChars) break;
        }
    }
    secure::wipe_bytes(pool);
    if (code.size() != kCodeChars) return std::nullopt;
    return code;
}

std::string format_code(std::string_view normalized) {
    std::string out;
    out.reserve(normalized.size() + (normalized.size() / 4));
    for (std::size_t index = 0; index < normalized.size(); ++index) {
        if (index != 0 && index % 4 == 0) out.push_back('-');
        out.push_back(normalized[index]);
    }
    return out;
}

std::optional<std::string> normalize_code(std::string_view typed) {
    // Trần đầu vào chặn chuỗi dài do kẻ gọi gửi: một mã gõ đủ chỗ cho dấu '-' và khoảng trắng thừa.
    constexpr std::size_t kTypedMost = 64;
    if (typed.size() > kTypedMost) return std::nullopt;
    std::string out;
    out.reserve(kCodeChars);
    for (const char raw : typed) {
        if (raw == '-' || raw == ' ') continue;
        const char upper = (raw >= 'a' && raw <= 'z') ? static_cast<char>(raw - 'a' + 'A') : raw;
        if (kCodeAlphabet.find(upper) == std::string_view::npos) return std::nullopt;
        if (out.size() == kCodeChars) return std::nullopt;
        out.push_back(upper);
    }
    if (out.size() != kCodeChars) return std::nullopt;
    return out;
}

std::string hash_code(std::string_view normalized) {
    std::string message{kHashPrefix};
    message.append(normalized);
    std::array<std::byte, 32> digest{};
    const bool hashed = secure::sha256(std::as_bytes(std::span{message.data(), message.size()}), digest);
    if (!hashed) return {};
    return secure::hex_encode(digest);
}

} // namespace game::billing
