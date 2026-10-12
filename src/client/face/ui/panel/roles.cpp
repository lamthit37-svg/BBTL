// Sổ nhân vật cục bộ (xem roles.hpp).
#include "ui/panel/roles.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::panel {
namespace {

constexpr std::size_t kColumns = 10;
constexpr std::string_view kVersion = "1";
constexpr char32_t kHash = U'#';
constexpr char32_t kDelete = 0x7F;
constexpr char32_t kLastBmp = 0xFFFF;
constexpr char32_t kSurrogateFirst = 0xD800;
constexpr char32_t kSurrogateLast = 0xDFFF;

struct Cells {
    std::array<std::string_view, kColumns> fields{};
    bool is_full = false;
};

struct Decoded {
    char32_t value = 0;
    bool is_ok = false;
};

[[nodiscard]] bool is_continuation(unsigned char byte) noexcept {
    return (byte & 0xC0U) == 0x80U;
}

[[nodiscard]] bool is_name_char(char32_t code) noexcept {
    if (code < 0x20 || code == kHash || code == kDelete) return false;
    if (code >= kSurrogateFirst && code <= kSurrogateLast) return false;
    return code <= kLastBmp;
}

[[nodiscard]] std::size_t sequence_length(unsigned char lead) noexcept {
    if (lead < 0x80U) return 1;
    if (lead >= 0xC2U && lead <= 0xDFU) return 2;
    if (lead >= 0xE0U && lead <= 0xEFU) return 3;
    return 0;
}

[[nodiscard]] bool continues_char(char byte) noexcept {
    return is_continuation(static_cast<unsigned char>(byte));
}

[[nodiscard]] bool tail_continues(std::string_view text, std::size_t length) noexcept {
    const std::string_view tail = text.substr(1, length - 1);
    return std::ranges::all_of(tail, continues_char);
}

[[nodiscard]] char32_t unpack(std::string_view text, std::size_t length) noexcept {
    const auto lead = static_cast<unsigned char>(text.front());
    if (length == 1) return lead;
    const auto second = static_cast<unsigned char>(text[1]);
    if (length == 2) return (static_cast<char32_t>(lead & 0x1FU) << 6) | (second & 0x3FU);
    const auto third = static_cast<unsigned char>(text[2]);
    const char32_t high = static_cast<char32_t>(lead & 0x0FU) << 12;
    const char32_t mid = static_cast<char32_t>(second & 0x3FU) << 6;
    return high | mid | (third & 0x3FU);
}

[[nodiscard]] bool is_overlong(unsigned char lead, std::string_view text, std::size_t length) noexcept {
    if (length != 3) return false;
    const auto second = static_cast<unsigned char>(text[1]);
    if (lead == 0xE0U && second < 0xA0U) return true;
    return lead == 0xEDU && second >= 0xA0U;
}

// Rút một mã Unicode ở đầu text và nuốt các byte của nó. Thất bại thì không nuốt.
[[nodiscard]] Decoded take_code(std::string_view& text) noexcept {
    if (text.empty()) return {};
    const auto lead = static_cast<unsigned char>(text.front());
    const std::size_t length = sequence_length(lead);
    if (length == 0 || text.size() < length || !tail_continues(text, length)) return {};
    if (is_overlong(lead, text, length)) return {};
    Decoded decoded;
    decoded.value = unpack(text, length);
    decoded.is_ok = true;
    text.remove_prefix(length);
    return decoded;
}

[[nodiscard]] NameFault fault_of(std::string_view& text) noexcept {
    const Decoded decoded = take_code(text);
    if (!decoded.is_ok || !is_name_char(decoded.value)) return NameFault::kBad;
    return NameFault::kOk;
}

[[nodiscard]] NameFault judge_name(std::string_view name) noexcept {
    if (name.empty()) return NameFault::kEmpty;
    NameFault fault = NameFault::kOk;
    std::size_t count = 0;
    std::string_view rest = name;
    while (!rest.empty() && fault == NameFault::kOk) {
        fault = fault_of(rest);
        count += fault == NameFault::kOk ? 1U : 0U;
    }
    if (fault != NameFault::kOk) return fault;
    if (count > kNameLimit) return NameFault::kLong;
    return NameFault::kOk;
}

[[nodiscard]] bool same_account(const StoredRole& row, std::string_view account) noexcept {
    return row.account == account;
}

// Lượt tìm ô của một tài khoản: đếm nhân vật của tài khoản đó cho tới đúng slot.
struct SlotWalk {
    std::string_view account;
    std::uint8_t slot = 0;
    std::size_t seen = 0;
    std::optional<std::size_t> found;
};

void note_slot(SlotWalk& walk, const StoredRole& row, std::size_t index) noexcept {
    if (!same_account(row, walk.account)) return;
    const bool is_slot = walk.seen == walk.slot;
    ++walk.seen;
    if (!is_slot) return;
    walk.found = index;
}

[[nodiscard]] std::optional<std::size_t> slot_index(const Book& book, std::string_view account, std::uint8_t slot) {
    SlotWalk walk;
    walk.account = account;
    walk.slot = slot;
    for (std::size_t index = 0; index < book.rows.size(); ++index) note_slot(walk, book.rows[index], index);
    return walk.found;
}

void keep_role(Roster& roster, const StoredRole& row, std::string_view account) {
    if (!same_account(row, account) || roster.count >= kRoleCap) return;
    const auto index = static_cast<std::ptrdiff_t>(roster.count);
    *std::next(roster.roles.begin(), index) = row.role;
    ++roster.count;
}

[[nodiscard]] bool taken_at(const Roster& roster, std::string_view name, std::uint8_t index) noexcept {
    if (index >= roster.count) return false;
    const Role& role = *std::next(roster.roles.begin(), static_cast<std::ptrdiff_t>(index));
    return role.name == name;
}

struct AccountName {
    std::string_view account;
    std::string_view name;
};

[[nodiscard]] bool is_taken(const Book& book, AccountName who) {
    const Roster roster = roster_of(book, who.account);
    bool taken = false;
    for (std::uint8_t index = 0; index < roster.count; ++index) taken = taken || taken_at(roster, who.name, index);
    return taken;
}

[[nodiscard]] int prior_slots(const Book& book, std::size_t index) {
    int count = 0;
    const std::string& account = book.rows[index].account;
    for (std::size_t earlier = 0; earlier < index; ++earlier) {
        count += same_account(book.rows[earlier], account) ? 1 : 0;
    }
    return count;
}

void add_number(std::string& out, int value) {
    std::format_to(std::back_inserter(out), "{}\t", value);
}

void add_text(std::string& out, std::string_view text, char mark) {
    out.append(text);
    out.push_back(mark);
}

void write_row(std::string& out, const StoredRole& row, int slot) {
    add_text(out, row.account, '\t');
    add_number(out, slot);
    add_text(out, row.role.name, '\t');
    add_number(out, static_cast<int>(row.role.sex));
    add_number(out, static_cast<int>(row.role.face));
    add_number(out, static_cast<int>(row.role.hair));
    add_number(out, row.role.level);
    add_number(out, static_cast<int>(row.role.sect));
    add_number(out, row.role.portrait);
    add_text(out, row.role.icon, '\n');
}

[[nodiscard]] std::size_t tab_count(std::string_view line) noexcept {
    return static_cast<std::size_t>(std::ranges::count(line, '\t'));
}

[[nodiscard]] std::string_view take_cell(std::string_view& line) noexcept {
    const std::size_t tab = line.find('\t');
    if (tab == std::string_view::npos) {
        const std::string_view cell = line;
        line = {};
        return cell;
    }
    const std::string_view cell = line.substr(0, tab);
    line.remove_prefix(tab + 1);
    return cell;
}

void store_cell(Cells& cells, std::size_t index, std::string_view& line) noexcept {
    const auto at = static_cast<std::ptrdiff_t>(index);
    *std::next(cells.fields.begin(), at) = take_cell(line);
}

[[nodiscard]] Cells split_row(std::string_view line) noexcept {
    Cells cells;
    if (tab_count(line) != kColumns - 1) return cells;
    for (std::size_t index = 0; index < kColumns - 1; ++index) store_cell(cells, index, line);
    cells.fields[kColumns - 1] = line;
    cells.is_full = true;
    return cells;
}

[[nodiscard]] bool fits_byte(int value, int top) noexcept {
    return value >= 0 && value <= top;
}

[[nodiscard]] std::optional<int> cell_int(std::string_view text) noexcept {
    return core::parse_whole_int(text);
}

[[nodiscard]] std::optional<StoredRole> role_of(const Cells& cells) {
    if (!cells.is_full || cells.fields[0].empty()) return std::nullopt;
    const std::optional<int> slot = cell_int(cells.fields[1]);
    const std::optional<int> sex = cell_int(cells.fields[3]);
    const std::optional<int> face = cell_int(cells.fields[4]);
    const std::optional<int> hair = cell_int(cells.fields[5]);
    const std::optional<int> level = cell_int(cells.fields[6]);
    const std::optional<int> sect = cell_int(cells.fields[7]);
    const std::optional<int> portrait = cell_int(cells.fields[8]);
    if (!slot || !sex || !face || !hair || !level || !sect || !portrait) return std::nullopt;
    if (!fits_byte(*sex, 1) || !fits_byte(*face, 65535) || !fits_byte(*hair, 65535)) return std::nullopt;
    if (*level < kNewLevel || !fits_byte(*sect, 15) || *portrait < 0) return std::nullopt;
    if (judge_name(cells.fields[2]) != NameFault::kOk) return std::nullopt;
    StoredRole stored;
    stored.account = std::string(cells.fields[0]);
    stored.role.name = std::string(cells.fields[2]);
    stored.role.sex = static_cast<std::uint8_t>(*sex);
    stored.role.face = static_cast<std::uint16_t>(*face);
    stored.role.hair = static_cast<std::uint16_t>(*hair);
    stored.role.level = *level;
    stored.role.sect = static_cast<std::uint8_t>(*sect);
    stored.role.portrait = *portrait;
    stored.role.icon = std::string(cells.fields[9]);
    return stored;
}

void take_role(Book& book, std::string_view line) {
    const Cells cells = split_row(line);
    std::optional<StoredRole> stored = role_of(cells);
    if (!stored) return;
    if (roster_of(book, stored->account).count >= kRoleCap) return;
    const AccountName who{.account = stored->account, .name = stored->role.name};
    if (is_taken(book, who)) return;
    book.rows.push_back(std::move(*stored));
}

struct VersionMark {
    bool seen = false;
    bool ok = false;
};

void take_line(Book& book, std::string_view line, VersionMark& mark) {
    if (line.empty()) return;
    if (!mark.seen) {
        mark.seen = true;
        mark.ok = line == kVersion;
        return;
    }
    if (!mark.ok) return;
    take_role(book, line);
}

void consume_line(Book& book, std::string_view& text, VersionMark& mark) {
    const std::size_t end = text.find('\n');
    std::string_view line = end == std::string_view::npos ? text : text.substr(0, end);
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    take_line(book, line, mark);
    text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
}

} // namespace

Roster roster_of(const Book& book, std::string_view account) {
    Roster roster;
    for (const StoredRole& row : book.rows) keep_role(roster, row, account);
    return roster;
}

NameFault admit_name(const Book& book, std::string_view account, std::string_view name) {
    const NameFault fault = judge_name(name);
    if (fault != NameFault::kOk) return fault;
    if (roster_of(book, account).count >= kRoleCap) return NameFault::kFull;
    const AccountName who{.account = account, .name = name};
    if (is_taken(book, who)) return NameFault::kTaken;
    return NameFault::kOk;
}

std::string_view name_fault_text(NameFault fault) noexcept {
    if (fault == NameFault::kEmpty) return "#{Login_Create_Role_Info_Name_Is_Empty}";
    if (fault == NameFault::kLong) return "#{Login_Create_Role_Info_Name_Too_Len}";
    if (fault == NameFault::kBad) return "#{INVALID_CHARACTER_IN_NAME}";
    if (fault == NameFault::kTaken) return "#{Login_Create_Role_Name_Exist}";
    if (fault == NameFault::kFull) return "#{ROLE_LIST_FULL}";
    return {};
}

NameFault add_role(Book& book, std::string_view account, const Role& role) {
    const NameFault fault = admit_name(book, account, role.name);
    if (fault != NameFault::kOk) return fault;
    StoredRole stored;
    stored.account = std::string(account);
    stored.role = role;
    book.rows.push_back(std::move(stored));
    return NameFault::kOk;
}

bool erase_role(Book& book, std::string_view account, std::uint8_t index) {
    const std::optional<std::size_t> found = slot_index(book, account, index);
    if (!found) return false;
    const auto at = book.rows.begin() + static_cast<std::ptrdiff_t>(*found);
    book.rows.erase(at);
    return true;
}

std::string encode_book(const Book& book) {
    std::string out;
    out.append(kVersion);
    out.push_back('\n');
    for (std::size_t index = 0; index < book.rows.size(); ++index) {
        write_row(out, book.rows[index], prior_slots(book, index));
    }
    return out;
}

std::optional<Book> decode_book(std::string_view text) {
    Book book;
    VersionMark mark;
    while (!text.empty()) consume_line(book, text, mark);
    if (!mark.seen || !mark.ok) return std::nullopt;
    return book;
}

} // namespace game::ui::panel
