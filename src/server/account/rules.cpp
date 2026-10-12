#include "account/rules.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::account {
namespace {

[[nodiscard]] bool is_account_char(unsigned char value) noexcept {
    const bool digit = value >= '0' && value <= '9';
    const bool upper = value >= 'A' && value <= 'Z';
    const bool lower = value >= 'a' && value <= 'z';
    return digit || upper || lower || value == '_';
}

[[nodiscard]] bool banned_in_name(unsigned char value) noexcept {
    if (value < 0x20 || value == 0x7f) return true;
    return value == '<' || value == '>' || value == '{' || value == '}' || value == '\\' || value == '|';
}

[[nodiscard]] int hex_value(unsigned char value) noexcept {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    return -1;
}

} // namespace

std::string fold_ascii(std::string_view text) {
    std::string out;
    out.reserve(text.size());
    for (const char value : text) {
        const auto byte = static_cast<unsigned char>(value);
        const bool upper = byte >= 'A' && byte <= 'Z';
        out.push_back(static_cast<char>(upper ? byte + 32 : byte));
    }
    return out;
}

NameFault account_fault(std::string_view name, std::string_view password) {
    const bool name_length = name.size() >= kAccountMin && name.size() <= kAccountMax;
    if (!name_length) return NameFault::kAccount;
    for (const char value : name) {
        if (!is_account_char(static_cast<unsigned char>(value))) return NameFault::kAccount;
    }
    const bool password_length = password.size() >= kPasswordMin && password.size() <= kPasswordMax;
    if (!password_length) return NameFault::kPassword;
    if (fold_ascii(password) == fold_ascii(name)) return NameFault::kPassword;
    return NameFault::kOk;
}

bool sign_in_shape_ok(std::string_view name, std::string_view password) {
    if (name.empty() || name.size() > protocol::kSignInAccountBytes) return false;
    if (password.empty() || password.size() > protocol::kSignInPasswordBytes) return false;
    return true;
}

bool character_name_ok(std::string_view name) {
    return canonical_character_name(name).has_value();
}

bool token_bytes(std::string_view hex, std::span<std::byte, kTicketRaw> out) {
    if (hex.size() != kTicketHex) return false;
    for (std::size_t index = 0; index < kTicketRaw; ++index) {
        const int high = hex_value(static_cast<unsigned char>(hex[index * 2]));
        const int low = hex_value(static_cast<unsigned char>(hex[index * 2 + 1]));
        if (high < 0 || low < 0) return false;
        out[index] = static_cast<std::byte>((high << 4) | low);
    }
    return true;
}

SignStep sign_step(bool known, bool disabled, bool matched, int failures, bool auto_register) noexcept {
    if (failures >= kFailLimit) return SignStep::kRate;
    if (!known && auto_register) return SignStep::kCreate;
    if (!known) return SignStep::kMissing;
    if (disabled) return SignStep::kDisabled;
    if (!matched) return SignStep::kMismatch;
    return SignStep::kOk;
}

CreateStep create_step(bool name_ok, int live_count, bool taken) noexcept {
    if (!name_ok) return CreateStep::kBadName;
    if (live_count >= kCharacterCap) return CreateStep::kFull;
    if (taken) return CreateStep::kTaken;
    return CreateStep::kOk;
}

protocol::ErrorCode fault_code(NameFault fault) noexcept {
    if (fault == NameFault::kAccount) return protocol::ErrorCode::kNameInvalid;
    if (fault == NameFault::kPassword) return protocol::ErrorCode::kPasswordInvalid;
    return protocol::ErrorCode::kMalformed;
}

protocol::ErrorCode sign_code(SignStep step) noexcept {
    if (step == SignStep::kRate) return protocol::ErrorCode::kRateLimited;
    return protocol::ErrorCode::kBadCredentials;
}

protocol::ErrorCode create_code(CreateStep step) noexcept {
    if (step == CreateStep::kBadName) return protocol::ErrorCode::kNameInvalid;
    if (step == CreateStep::kFull) return protocol::ErrorCode::kCharacterLimit;
    if (step == CreateStep::kTaken) return protocol::ErrorCode::kNameTaken;
    return protocol::ErrorCode::kMalformed;
}

namespace {

struct Compose {
    char32_t base = 0;
    char32_t mark = 0;
    char32_t out = 0;
};

// Một bước ghép NFC cho Latin-1 và chữ Việt. Dấu không có trong bảng thì tên bị từ chối.
constexpr Compose kCompose[] = {
    {0x0041, 0x0300, 0x00C0}, {0x0041, 0x0301, 0x00C1}, {0x0041, 0x0302, 0x00C2}, {0x0041, 0x0303, 0x00C3},
    {0x0041, 0x0308, 0x00C4}, {0x0041, 0x030A, 0x00C5}, {0x0043, 0x0327, 0x00C7}, {0x0045, 0x0300, 0x00C8},
    {0x0045, 0x0301, 0x00C9}, {0x0045, 0x0302, 0x00CA}, {0x0045, 0x0308, 0x00CB}, {0x0049, 0x0300, 0x00CC},
    {0x0049, 0x0301, 0x00CD}, {0x0049, 0x0302, 0x00CE}, {0x0049, 0x0308, 0x00CF}, {0x004E, 0x0303, 0x00D1},
    {0x004F, 0x0300, 0x00D2}, {0x004F, 0x0301, 0x00D3}, {0x004F, 0x0302, 0x00D4}, {0x004F, 0x0303, 0x00D5},
    {0x004F, 0x0308, 0x00D6}, {0x0055, 0x0300, 0x00D9}, {0x0055, 0x0301, 0x00DA}, {0x0055, 0x0302, 0x00DB},
    {0x0055, 0x0308, 0x00DC}, {0x0059, 0x0301, 0x00DD}, {0x0061, 0x0300, 0x00E0}, {0x0061, 0x0301, 0x00E1},
    {0x0061, 0x0302, 0x00E2}, {0x0061, 0x0303, 0x00E3}, {0x0061, 0x0306, 0x0103}, {0x0061, 0x0308, 0x00E4},
    {0x0061, 0x030A, 0x00E5}, {0x0063, 0x0327, 0x00E7}, {0x0065, 0x0300, 0x00E8}, {0x0065, 0x0301, 0x00E9},
    {0x0065, 0x0302, 0x00EA}, {0x0065, 0x0308, 0x00EB}, {0x0069, 0x0300, 0x00EC}, {0x0069, 0x0301, 0x00ED},
    {0x0069, 0x0302, 0x00EE}, {0x0069, 0x0308, 0x00EF}, {0x006E, 0x0303, 0x00F1}, {0x006F, 0x0300, 0x00F2},
    {0x006F, 0x0301, 0x00F3}, {0x006F, 0x0302, 0x00F4}, {0x006F, 0x0303, 0x00F5}, {0x006F, 0x0308, 0x00F6},
    {0x006F, 0x031B, 0x01A1}, {0x0075, 0x0300, 0x00F9}, {0x0075, 0x0301, 0x00FA}, {0x0075, 0x0302, 0x00FB},
    {0x0075, 0x0308, 0x00FC}, {0x0075, 0x031B, 0x01B0}, {0x0079, 0x0301, 0x00FD}, {0x0079, 0x0308, 0x00FF},
    {0x0041, 0x0306, 0x0102}, {0x004F, 0x031B, 0x01A0}, {0x0055, 0x031B, 0x01AF}, {0x00C2, 0x0300, 0x1EA6},
    {0x00C2, 0x0301, 0x1EA4}, {0x00C2, 0x0303, 0x1EAA}, {0x00C2, 0x0309, 0x1EA8}, {0x00C2, 0x0323, 0x1EAC},
    {0x00CA, 0x0300, 0x1EC0}, {0x00CA, 0x0301, 0x1EBE}, {0x00CA, 0x0303, 0x1EC4}, {0x00CA, 0x0309, 0x1EC2},
    {0x00CA, 0x0323, 0x1EC6}, {0x00D4, 0x0300, 0x1ED2}, {0x00D4, 0x0301, 0x1ED0}, {0x00D4, 0x0303, 0x1ED6},
    {0x00D4, 0x0309, 0x1ED4}, {0x00D4, 0x0323, 0x1ED8}, {0x00E2, 0x0300, 0x1EA7}, {0x00E2, 0x0301, 0x1EA5},
    {0x00E2, 0x0303, 0x1EAB}, {0x00E2, 0x0309, 0x1EA9}, {0x00E2, 0x0323, 0x1EAD}, {0x00EA, 0x0300, 0x1EC1},
    {0x00EA, 0x0301, 0x1EBF}, {0x00EA, 0x0303, 0x1EC5}, {0x00EA, 0x0309, 0x1EC3}, {0x00EA, 0x0323, 0x1EC7},
    {0x00F4, 0x0300, 0x1ED3}, {0x00F4, 0x0301, 0x1ED1}, {0x00F4, 0x0303, 0x1ED7}, {0x00F4, 0x0309, 0x1ED5},
    {0x00F4, 0x0323, 0x1ED9}, {0x0102, 0x0300, 0x1EB0}, {0x0102, 0x0301, 0x1EAE}, {0x0102, 0x0303, 0x1EB4},
    {0x0102, 0x0309, 0x1EB2}, {0x0102, 0x0323, 0x1EB6}, {0x0103, 0x0300, 0x1EB1}, {0x0103, 0x0301, 0x1EAF},
    {0x0103, 0x0303, 0x1EB5}, {0x0103, 0x0309, 0x1EB3}, {0x0103, 0x0323, 0x1EB7}, {0x0041, 0x0323, 0x1EA0},
    {0x0061, 0x0323, 0x1EA1}, {0x0045, 0x0309, 0x1EBA}, {0x0045, 0x0303, 0x1EBC}, {0x0045, 0x0323, 0x1EB8},
    {0x0065, 0x0309, 0x1EBB}, {0x0065, 0x0303, 0x1EBD}, {0x0065, 0x0323, 0x1EB9}, {0x0049, 0x0309, 0x1EC8},
    {0x0049, 0x0323, 0x1ECA}, {0x0069, 0x0309, 0x1EC9}, {0x0069, 0x0323, 0x1ECB}, {0x004F, 0x0309, 0x1ECE},
    {0x004F, 0x0323, 0x1ECC}, {0x006F, 0x0309, 0x1ECF}, {0x006F, 0x0323, 0x1ECD}, {0x01A0, 0x0300, 0x1EDC},
    {0x01A0, 0x0301, 0x1EDA}, {0x01A0, 0x0303, 0x1EE0}, {0x01A0, 0x0309, 0x1EDE}, {0x01A0, 0x0323, 0x1EE2},
    {0x01A1, 0x0300, 0x1EDD}, {0x01A1, 0x0301, 0x1EDB}, {0x01A1, 0x0303, 0x1EE1}, {0x01A1, 0x0309, 0x1EDF},
    {0x01A1, 0x0323, 0x1EE3}, {0x0055, 0x0309, 0x1EE6}, {0x0055, 0x0323, 0x1EE4}, {0x0075, 0x0309, 0x1EE7},
    {0x0075, 0x0323, 0x1EE5}, {0x01AF, 0x0300, 0x1EEA}, {0x01AF, 0x0301, 0x1EE8}, {0x01AF, 0x0303, 0x1EEE},
    {0x01AF, 0x0309, 0x1EEC}, {0x01AF, 0x0323, 0x1EF0}, {0x01B0, 0x0300, 0x1EEB}, {0x01B0, 0x0301, 0x1EE9},
    {0x01B0, 0x0303, 0x1EEF}, {0x01B0, 0x0309, 0x1EED}, {0x01B0, 0x0323, 0x1EF1}, {0x0059, 0x0300, 0x1EF2},
    {0x0059, 0x0303, 0x1EF8}, {0x0059, 0x0309, 0x1EF6}, {0x0059, 0x0323, 0x1EF4}, {0x0079, 0x0300, 0x1EF3},
    {0x0079, 0x0303, 0x1EF9}, {0x0079, 0x0309, 0x1EF7}, {0x0079, 0x0323, 0x1EF5},
};

[[nodiscard]] bool is_mark(char32_t cp) noexcept {
    const bool combining = cp >= 0x0300 && cp <= 0x036F;
    const bool combining_ext = cp >= 0x1AB0 && cp <= 0x1AFF;
    const bool combining_sup = cp >= 0x1DC0 && cp <= 0x1DFF;
    const bool combining_symbol = cp >= 0x20D0 && cp <= 0x20FF;
    const bool combining_half = cp >= 0xFE20 && cp <= 0xFE2F;
    return combining || combining_ext || combining_sup || combining_symbol || combining_half;
}

[[nodiscard]] bool banned_codepoint(char32_t cp) noexcept {
    if (cp == 0 || cp < 0x20 || cp == 0x7F) return true;
    if (cp == '<' || cp == '>' || cp == '{' || cp == '}' || cp == '\\' || cp == '|') return true;
    if (cp == 0x00AD || cp == 0x061C || cp == 0x180E || cp == 0xFEFF) return true;
    if (cp >= 0x200B && cp <= 0x200F) return true;
    if (cp == 0x2028 || cp == 0x2029 || (cp >= 0x202A && cp <= 0x202E)) return true;
    if (cp >= 0x2060 && cp <= 0x2064) return true;
    if (cp >= 0x2066 && cp <= 0x206F) return true;
    if (cp >= 0xFDD0 && cp <= 0xFDEF) return true;
    return (cp & 0xFFFE) == 0xFFFE;
}

[[nodiscard]] std::optional<char32_t> compose(char32_t base, char32_t mark) noexcept {
    for (const Compose& row : kCompose) {
        if (row.base == base && row.mark == mark) return row.out;
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<std::vector<char32_t>> decode_utf8(std::string_view text) {
    std::vector<char32_t> out;
    std::size_t index = 0;
    while (index < text.size()) {
        const auto lead = static_cast<unsigned char>(text[index]);
        std::size_t need = 1;
        char32_t cp = lead;
        if (lead >= 0x80) {
            if ((lead & 0xE0) == 0xC0) {
                need = 2;
                cp = lead & 0x1F;
            } else if ((lead & 0xF0) == 0xE0) {
                need = 3;
                cp = lead & 0x0F;
            } else if ((lead & 0xF8) == 0xF0) {
                need = 4;
                cp = lead & 0x07;
            } else {
                return std::nullopt;
            }
        }
        if (index + need > text.size()) return std::nullopt;
        for (std::size_t extra = 1; extra < need; ++extra) {
            const auto cont = static_cast<unsigned char>(text[index + extra]);
            if ((cont & 0xC0) != 0x80) return std::nullopt;
            cp = (cp << 6) | (cont & 0x3F);
        }
        const bool overlong = (need == 2 && cp < 0x80) || (need == 3 && cp < 0x800) || (need == 4 && cp < 0x10000);
        if (overlong || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) return std::nullopt;
        out.push_back(cp);
        index += need;
    }
    return out;
}

void append_utf8(std::string& out, char32_t cp) {
    if (cp < 0x80) {
        out.push_back(static_cast<char>(cp));
        return;
    }
    if (cp < 0x800) {
        out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
        out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        return;
    }
    if (cp < 0x10000) {
        out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
        out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
        out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        return;
    }
    out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
    out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
}

// Tập chữ được phép trong tên nhân vật, kiểm sau khi ghép NFC: ASCII in được, chữ Latin có dấu
// nằm trong bảng ghép (Latin-1 có dấu và chữ Việt), Đ/đ, và chữ Hán thống nhất (khối chính + mở rộng A).
// Ngoài tập là từ chối: Cyrillic, Hy Lạp, chữ toàn khổ, ký hiệu chữ cái, chữ Latin không có trong
// tiếng Việt (Æ, Ð, Ø, Þ, ß...) đều nhìn giống chữ Latin hoặc chữ Việt và dùng để giả tên.
[[nodiscard]] bool name_repertoire(char32_t cp) noexcept {
    if (cp >= 0x20 && cp <= 0x7E) return true;
    if (cp == 0x0110 || cp == 0x0111) return true;
    if (cp >= 0x4E00 && cp <= 0x9FFF) return true;
    if (cp >= 0x3400 && cp <= 0x4DBF) return true;
    for (const Compose& row : kCompose) {
        if (row.out == cp) return true;
    }
    return false;
}

// Hạ hoa thường đầy đủ cho đúng tập chữ name_repertoire. Tập đóng nên không cần bảng Unicode.
[[nodiscard]] char32_t fold_codepoint(char32_t cp) noexcept {
    if (cp >= 'A' && cp <= 'Z') return cp + 0x20;
    if (cp >= 0x00C0 && cp <= 0x00DE && cp != 0x00D7) return cp + 0x20;
    if (cp == 0x0102 || cp == 0x0110 || cp == 0x01A0 || cp == 0x01AF) return cp + 1;
    if (cp >= 0x1EA0 && cp <= 0x1EF9 && (cp % 2U) == 0) return cp + 1;
    return cp;
}

} // namespace

const LookPolicy& default_look_policy() {
    static const LookPolicy kDefault{
        .female_faces = {1, 2, 3, 4, 5, 14},
        .male_faces = {100, 101, 102, 103, 104, 113},
        .female_hairs = {1, 17, 19},
        .male_hairs = {5, 12, 14},
    };
    return kDefault;
}

bool look_ok(const LookPolicy& policy, protocol::Gender gender, std::uint16_t face, std::uint16_t hair) noexcept {
    const auto has = [](std::span<const std::uint16_t> set, std::uint16_t id) {
        return std::ranges::find(set, id) != set.end();
    };
    if (gender == protocol::Gender::kFemale) return has(policy.female_faces, face) && has(policy.female_hairs, hair);
    if (gender == protocol::Gender::kMale) return has(policy.male_faces, face) && has(policy.male_hairs, hair);
    return false;
}

bool look_ok(protocol::Gender gender, std::uint16_t face, std::uint16_t hair) noexcept {
    return look_ok(default_look_policy(), gender, face, hair);
}

std::string fold_character_name(std::string_view canonical) {
    const std::optional<std::vector<char32_t>> decoded = decode_utf8(canonical);
    if (!decoded) return fold_ascii(canonical);
    std::string out;
    out.reserve(canonical.size());
    for (const char32_t cp : *decoded) append_utf8(out, fold_codepoint(cp));
    return out;
}

std::optional<std::string> canonical_character_name(std::string_view name) {
    const std::optional<std::vector<char32_t>> decoded = decode_utf8(name);
    if (!decoded || decoded->empty()) return std::nullopt;
    std::vector<char32_t> folded;
    folded.reserve(decoded->size());
    for (const char32_t cp : *decoded) {
        if (banned_codepoint(cp)) return std::nullopt;
        if (!is_mark(cp) || folded.empty()) {
            if (is_mark(cp)) return std::nullopt;
            folded.push_back(cp);
            continue;
        }
        const std::optional<char32_t> joined = compose(folded.back(), cp);
        if (!joined) return std::nullopt;
        folded.back() = *joined;
    }
    for (const char32_t cp : folded) {
        if (!name_repertoire(cp)) return std::nullopt;
    }
    std::string text;
    for (const char32_t cp : folded) append_utf8(text, cp);
    if (text.empty() || text.size() > kCharacterNameMax) return std::nullopt;
    if (text.front() == ' ' || text.back() == ' ') return std::nullopt;
    bool visible = false;
    for (const char value : text) {
        if (value != ' ') visible = true;
    }
    if (!visible) return std::nullopt;
    return text;
}

bool ipv4_ok(std::string_view text) {
    std::size_t index = 0;
    int dots = 0;
    for (int part = 0; part < 4; ++part) {
        if (index >= text.size() || text[index] < '0' || text[index] > '9') return false;
        const bool zero = text[index] == '0';
        int value = 0;
        int digits = 0;
        while (index < text.size() && text[index] >= '0' && text[index] <= '9') {
            value = value * 10 + (text[index] - '0');
            if (value > 255 || digits == 3) return false;
            ++index;
            ++digits;
        }
        if (digits == 0 || (zero && digits > 1)) return false;
        if (part == 3) continue;
        if (index >= text.size() || text[index] != '.') return false;
        ++index;
        ++dots;
    }
    return index == text.size() && dots == 3;
}

} // namespace game::account
