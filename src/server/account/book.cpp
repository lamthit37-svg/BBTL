#include "account/book.hpp"

#include "account/starter.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <utility>

namespace game::account {
namespace {

using Clock = std::chrono::system_clock;

[[nodiscard]] TicketResult fail_ticket(protocol::ErrorCode code) {
    TicketResult result;
    result.code = code;
    return result;
}

[[nodiscard]] ListResult fail_list(protocol::ErrorCode code) {
    ListResult result;
    result.code = code;
    return result;
}

[[nodiscard]] protocol::CharacterSummary summary_of(std::string name, protocol::Gender gender, std::uint16_t face,
    std::uint16_t hair) {
    protocol::CharacterSummary summary;
    summary.name = std::move(name);
    summary.level = static_cast<std::uint16_t>(starter::kLevel);
    summary.gender = gender;
    summary.face = face;
    summary.hair = hair;
    summary.school = static_cast<std::uint8_t>(starter::kSchool);
    summary.scene = static_cast<std::uint16_t>(starter::kScene);
    return summary;
}

} // namespace

MemoryBook::MemoryBook(BookConfig config) : config_(std::move(config)) {}

MemoryBook::AccountRow* MemoryBook::find_fold(std::string_view fold) {
    const auto same = [&](const AccountRow& row) { return row.fold == fold; };
    const auto found = std::ranges::find_if(accounts_, same);
    if (found == accounts_.end()) return nullptr;
    return &*found;
}

int MemoryBook::recent_failures(const AccountRow& row, Clock::time_point now) const {
    int count = 0;
    for (const Clock::time_point at : row.failures) {
        if (now - at <= kFailWindow) ++count;
    }
    return count;
}

void MemoryBook::note_failure(AccountRow& row, Clock::time_point now) {
    std::erase_if(row.failures, [&](Clock::time_point at) { return now - at > kFailWindow; });
    row.failures.push_back(now);
}

TicketResult MemoryBook::issue(std::uint64_t account, Clock::time_point now) {
    if (config_.random.fill == nullptr) return fail_ticket(protocol::ErrorCode::kBusy);
    std::array<std::byte, kTicketRaw> raw{};
    if (!config_.random.fill(config_.random.ctx, raw)) return fail_ticket(protocol::ErrorCode::kBusy);
    TicketRow ticket;
    ticket.account = account;
    ticket.hex = secure::hex_encode(raw);
    ticket.expires = now + config_.ticket_ttl;
    secure::wipe_bytes(raw);
    TicketResult result;
    result.ok = true;
    result.hex = ticket.hex;
    tickets_.push_back(std::move(ticket));
    return result;
}

std::vector<protocol::CharacterSummary> MemoryBook::list_of(std::uint64_t account) const {
    std::vector<protocol::CharacterSummary> rows;
    for (const CharacterRow& row : characters_) {
        if (row.deleted || row.account != account) continue;
        rows.push_back(row.summary);
        if (rows.size() == protocol::kCharacterListCharactersCount) break;
    }
    return rows;
}

// Giống GameDb: tên sống của bất kỳ ai, hoặc tên tài khoản khác đã xoá mềm. Bản nhớ không giữ giờ xoá
// nên chỗ giữ tên kéo dài hết đời của sổ (dài hơn kNameReserve, không ngắn hơn).
bool MemoryBook::name_taken(std::string_view fold, std::uint64_t account) const {
    for (const CharacterRow& row : characters_) {
        if (fold_character_name(row.summary.name) != fold) continue;
        if (!row.deleted || row.account != account) return true;
    }
    return false;
}

int MemoryBook::live_count(std::uint64_t account) const {
    int count = 0;
    for (const CharacterRow& row : characters_) {
        if (!row.deleted && row.account == account) ++count;
    }
    return count;
}

TicketResult MemoryBook::create_account(std::string_view name, std::string_view password, Clock::time_point now) {
    const NameFault fault = account_fault(name, password);
    if (fault != NameFault::kOk) return fail_ticket(fault_code(fault));
    const std::string fold = fold_ascii(name);
    // Tên đã có trả cùng mã như đăng nhập sai, để không dò được tài khoản (giống AuthDb).
    if (find_fold(fold) != nullptr) return fail_ticket(protocol::ErrorCode::kBadCredentials);
    if (config_.hash.hash == nullptr) return fail_ticket(protocol::ErrorCode::kBusy);
    AccountRow row;
    row.id = next_account_++;
    row.name = std::string{name};
    row.fold = fold;
    row.gift_points = config_.gift_points;
    if (!config_.hash.hash(config_.hash.ctx, password, row.password_hash)) {
        return fail_ticket(protocol::ErrorCode::kBusy);
    }
    const std::uint64_t id = row.id;
    accounts_.push_back(std::move(row));
    return issue(id, now);
}

TicketResult MemoryBook::sign_in(std::string_view name, std::string_view password, Clock::time_point now) {
    if (!sign_in_shape_ok(name, password)) return fail_ticket(protocol::ErrorCode::kBadCredentials);
    const std::string fold = fold_ascii(name);
    AccountRow* row = find_fold(fold);
    const int failures = row == nullptr ? 0 : recent_failures(*row, now);
    const bool known = row != nullptr;
    const bool disabled = known && row->disabled;
    bool matched = false;
    if (known && !disabled && config_.hash.verify != nullptr) {
        matched = config_.hash.verify(config_.hash.ctx, row->password_hash, password);
    }
    const SignStep step = sign_step(known, disabled, matched, failures, config_.auto_register);
    if (step == SignStep::kRate) return fail_ticket(sign_code(step));
    if (step == SignStep::kCreate) {
        if (account_fault(name, password) != NameFault::kOk) return fail_ticket(protocol::ErrorCode::kBadCredentials);
        return create_account(name, password, now);
    }
    if (step != SignStep::kOk) {
        if (row != nullptr) note_failure(*row, now);
        return fail_ticket(sign_code(step));
    }
    return issue(row->id, now);
}

ListResult MemoryBook::login(std::string_view ticket_hex, Clock::time_point now) {
    std::array<std::byte, kTicketRaw> raw{};
    if (!token_bytes(ticket_hex, raw)) return fail_list(protocol::ErrorCode::kBadCredentials);
    const std::string hex = secure::hex_encode(raw);
    secure::wipe_bytes(raw);
    TicketRow* ticket = nullptr;
    for (TicketRow& row : tickets_) {
        if (row.hex == hex) ticket = &row;
    }
    if (ticket == nullptr) return fail_list(protocol::ErrorCode::kBadCredentials);
    if (ticket->used || ticket->expires <= now) return fail_list(protocol::ErrorCode::kSessionExpired);
    ticket->used = true;
    ListResult result;
    result.ok = true;
    result.account = ticket->account;
    result.characters = list_of(ticket->account);
    return result;
}

ListResult MemoryBook::create_character(std::uint64_t account, std::string_view name, protocol::Gender gender,
    std::uint16_t face, std::uint16_t hair) {
    const bool owned = std::ranges::any_of(accounts_, [&](const AccountRow& row) { return row.id == account; });
    if (!owned) return fail_list(protocol::ErrorCode::kNotAuthenticated);
    if (!look_ok(config_.look, gender, face, hair)) return fail_list(protocol::ErrorCode::kBadOption);
    const std::optional<std::string> canonical = canonical_character_name(name);
    if (!canonical) return fail_list(protocol::ErrorCode::kNameInvalid);
    const std::string fold = fold_character_name(*canonical);
    const CreateStep step = create_step(true, live_count(account), name_taken(fold, account));
    if (step != CreateStep::kOk) return fail_list(create_code(step));
    CharacterRow row;
    row.id = next_character_++;
    row.account = account;
    row.summary = summary_of(*canonical, gender, face, hair);
    row.summary.id = row.id;
    characters_.push_back(std::move(row));
    ListResult result;
    result.ok = true;
    result.account = account;
    result.characters = list_of(account);
    return result;
}

ListResult MemoryBook::remove_character(std::uint64_t account, std::uint64_t character) {
    CharacterRow* row = nullptr;
    for (CharacterRow& item : characters_) {
        if (item.id == character && item.account == account && !item.deleted) row = &item;
    }
    if (row == nullptr) return fail_list(protocol::ErrorCode::kNoSuchCharacter);
    row->deleted = true;
    ListResult result;
    result.ok = true;
    result.account = account;
    result.characters = list_of(account);
    return result;
}

EnterResult MemoryBook::enter(std::uint64_t account, std::uint64_t character) {
    EnterResult result;
    for (const CharacterRow& row : characters_) {
        if (row.id == character && row.account == account && !row.deleted) {
            // Sổ nhớ không lưu vị trí: nhân vật luôn ở điểm sinh của hồ sơ mới.
            result.ok = true;
            result.scene = row.summary.scene;
            result.x_cm = static_cast<std::int32_t>(starter::kPositionX * 100.0);
            result.z_cm = static_cast<std::int32_t>(starter::kPositionZ * 100.0);
            result.summary = row.summary;
            return result;
        }
    }
    return result;
}

} // namespace game::account
