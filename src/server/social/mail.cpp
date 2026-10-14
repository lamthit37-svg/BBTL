#include "social/mail.hpp"

#include "core/text.hpp"
#include "ids/ids.hpp"
#include "protocol/wire.hpp"
#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/limits.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/text.hpp"
#include "social/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint16_t kMailVersion = 1;
constexpr std::size_t kMaxMails = 64;        // trần giải mã, rộng hơn mail_inbox_cap
constexpr std::size_t kMaxItems = 8;         // trần giải mã, rộng hơn mail_max_items
constexpr std::size_t kMaxNameBytes = 63;
constexpr std::size_t kMaxTitleBytes = 255;
constexpr std::size_t kMaxTextBytes = 1023;

[[nodiscard]] MailResult reject(MailError error) {
    MailResult result;
    result.error = error;
    return result;
}

[[nodiscard]] bool valid_kind(std::uint8_t raw) noexcept { return raw <= static_cast<std::uint8_t>(MailKind::kSystemReturned); }

// Nội dung thư nhiều dòng: UTF-8 chặt, chỉ cho '\n' trong các ký tự điều khiển.
[[nodiscard]] bool is_body_text(std::string_view text, std::size_t max_bytes) noexcept {
    if (text.size() > max_bytes || !core::is_valid_utf8(text)) return false;
    return std::ranges::none_of(text, [](char c) {
        const auto byte = static_cast<unsigned char>(c);
        return (byte < 0x20U && byte != '\n') || byte == 0x7FU;
    });
}

[[nodiscard]] Mail* find_mail(Mailbox& box, MailId id) noexcept {
    const auto found = std::ranges::find(box.mails, id, &Mail::id);
    return found == box.mails.end() ? nullptr : &*found;
}

[[nodiscard]] bool is_friend_of(const RelationSheet& sheet, CharacterId other) noexcept {
    const auto found = std::ranges::find(sheet.entries, other, &RelationEntry::id);
    if (found == sheet.entries.end()) return false;
    return found->kind == RelationKind::kFriend || found->kind == RelationKind::kSpouse || found->kind == RelationKind::kMaster ||
           found->kind == RelationKind::kPrentice;
}

[[nodiscard]] bool has_blacklisted(const RelationSheet& sheet, CharacterId other) noexcept {
    const auto found = std::ranges::find(sheet.entries, other, &RelationEntry::id);
    return found != sheet.entries.end() && found->kind == RelationKind::kBlack;
}

[[nodiscard]] std::string_view mail_problem(const Mail& mail, const Limits& limits) {
    if (mail.id.value() == 0) return "id thư 0";
    if (!valid_kind(static_cast<std::uint8_t>(mail.kind))) return "loại thư lạ";
    if (!is_plain_text(mail.sender_name, kMaxNameBytes)) return "tên người gửi sai";
    if (!is_plain_text(mail.title, static_cast<std::size_t>(limits.mail_title_max_bytes))) return "tiêu đề sai";
    if (!is_body_text(mail.text, static_cast<std::size_t>(limits.mail_text_max_bytes))) return "nội dung sai";
    if (std::cmp_greater(mail.payload.items.size(), limits.mail_max_items)) return "quá số vật phẩm";
    std::set<std::uint64_t> serials;
    for (const MailItem& item : mail.payload.items) {
        if (item.serial.value() == 0 || item.item.value() == 0 || item.count == 0) return "vật phẩm đính kèm sai";
        if (!serials.insert(item.serial.value()).second) return "vật phẩm trùng số sê-ri";
    }
    if (mail.payload.money < 0 || mail.payload.money > kCopperCeiling || mail.payload.cod < 0 || mail.payload.cod > kCopperCeiling) {
        return "tiền ngoài miền";
    }
    if (mail.payload.cod > 0 && (!mail.payload.has_goods() || mail.payload.money != 0)) return "thu tiền khi không có đồ";
    return {};
}

} // namespace

std::string_view describe(MailError error) noexcept {
    switch (error) {
    case MailError::kUnknownPlayer: return "không thấy người chơi";
    case MailError::kSelf: return "không thể gửi thư cho chính mình";
    case MailError::kNotLoaded: return "hộp thư chưa được nạp";
    case MailError::kLevelTooLow: return "cấp chưa đủ để gửi thư";
    case MailError::kNotFriend: return "chỉ gửi thư được cho bạn bè";
    case MailError::kRefused: return "người nhận từ chối nhận thư";
    case MailError::kBadText: return "tiêu đề hoặc nội dung không hợp lệ";
    case MailError::kTooManyItems: return "quá nhiều vật phẩm đính kèm";
    case MailError::kBadItem: return "vật phẩm đính kèm không hợp lệ";
    case MailError::kBadMoney: return "số tiền không hợp lệ";
    case MailError::kBadCod: return "tiền thu khi nhận không hợp lệ";
    case MailError::kInboxFull: return "hộp thư của người nhận đã đầy";
    case MailError::kNoSuchMail: return "không có thư này";
    case MailError::kHasAttachments: return "thư còn đồ đính kèm, hãy lấy đồ hoặc trả thư";
    case MailError::kNoAttachments: return "thư không có đồ đính kèm";
    case MailError::kAttachmentRejected: return "hành trang từ chối chuyển đồ";
    case MailError::kSenderUnavailable: return "chưa thể giao cho người gửi";
    case MailError::kNotReturnable: return "thư này không trả được";
    }
    return "lỗi thư lạ";
}

MailBook::MailBook(const Limits& limits, const TextPolicy& policy)
    : limits_(limits), policy_(&policy), expire_after_(seconds_to_ticks(limits.mail_expire_seconds)) {}

Mailbox* MailBook::mutable_box(CharacterId owner) {
    const auto found = boxes_.find(owner);
    return found == boxes_.end() ? nullptr : &found->second;
}

const Mailbox* MailBook::mailbox(CharacterId owner) const {
    const auto found = boxes_.find(owner);
    return found == boxes_.end() ? nullptr : &found->second;
}

std::expected<void, std::string> MailBook::load(CharacterId owner, Mailbox box) {
    if (owner.value() == 0) return std::unexpected("chủ hộp id 0");
    if (std::cmp_greater(box.mails.size(), limits_.mail_inbox_cap)) return std::unexpected("hộp thư quá trần");
    std::set<MailId> seen;
    for (const Mail& mail : box.mails) {
        if (const std::string_view problem = mail_problem(mail, limits_); !problem.empty()) return std::unexpected(std::string(problem));
        if (!seen.insert(mail.id).second) return std::unexpected("trùng id thư trong hộp");
        for (const auto& [other_owner, other_box] : boxes_) {
            if (other_owner != owner && std::ranges::any_of(other_box.mails, [&mail](const Mail& m) { return m.id == mail.id; })) {
                return std::unexpected("id thư đã nằm ở hộp khác");
            }
        }
    }
    for (const Mail& mail : box.mails) next_mail_ = std::max(next_mail_, mail.id.value() + 1U);
    boxes_.insert_or_assign(owner, std::move(box));
    return {};
}

std::optional<Mailbox> MailBook::unload(CharacterId owner) {
    const auto found = boxes_.find(owner);
    if (found == boxes_.end()) return std::nullopt;
    Mailbox out = std::move(found->second);
    boxes_.erase(found);
    return out;
}

void MailBook::set_next_mail_id(MailId id) { next_mail_ = std::max(next_mail_, id.value()); }

bool MailBook::text_ok(std::string_view title, std::string_view text) const {
    if (!is_plain_text(title, static_cast<std::size_t>(limits_.mail_title_max_bytes))) return false;
    if (!is_body_text(text, static_cast<std::size_t>(limits_.mail_text_max_bytes))) return false;
    return (title.empty() || policy_->allowed(title)) && (text.empty() || policy_->allowed(text));
}

std::optional<MailError> MailBook::check_payload(const MailPayload& payload) const {
    if (std::cmp_greater(payload.items.size(), limits_.mail_max_items)) return MailError::kTooManyItems;
    std::set<std::uint64_t> serials;
    for (const MailItem& item : payload.items) {
        if (item.serial.value() == 0 || item.item.value() == 0 || item.count == 0) return MailError::kBadItem;
        if (!serials.insert(item.serial.value()).second) return MailError::kBadItem;
    }
    if (payload.money < 0 || payload.money > kCopperCeiling) return MailError::kBadMoney;
    if (payload.cod < 0 || payload.cod > kCopperCeiling) return MailError::kBadCod;
    if (payload.cod > 0 && (!payload.has_goods() || payload.money != 0)) return MailError::kBadCod;
    return std::nullopt;
}

Mail MailBook::make_mail(MailKind kind, CharacterId sender, std::string sender_name, const MailDraft& draft, Tick now) {
    Mail mail;
    mail.id = MailId{next_mail_++};
    mail.kind = kind;
    mail.sender = sender;
    mail.sender_name = std::move(sender_name);
    mail.title = std::string(draft.title);
    mail.text = std::string(draft.text);
    mail.payload = draft.payload;
    mail.sent = now;
    return mail;
}

void MailBook::deliver(Mailbox& box, Mail mail) { box.mails.push_back(std::move(mail)); }

MailResult MailBook::send(Tick now, const PlayerDirectory& directory, const RelationBook& relations, AttachmentPort& port,
    const MailRoute& route, const MailDraft& draft) {
    const auto sender = directory.find(route.sender);
    const auto recipient = directory.find(route.recipient);
    if (!sender || !recipient || !sender->online) return reject(MailError::kUnknownPlayer);
    if (route.sender == route.recipient) return reject(MailError::kSelf);
    if (std::cmp_less(sender->level, limits_.mail_send_min_level)) return reject(MailError::kLevelTooLow);
    const RelationSheet* mine = relations.sheet(route.sender);
    if (mine == nullptr) return reject(MailError::kNotLoaded);
    if (!is_friend_of(*mine, route.recipient)) return reject(MailError::kNotFriend);
    const RelationSheet* theirs = relations.sheet(route.recipient);
    if ((theirs != nullptr && has_blacklisted(*theirs, route.sender)) || recipient->has(setting::kCannotReceiveMail)) {
        return reject(MailError::kRefused);
    }
    if (!text_ok(draft.title, draft.text)) return reject(MailError::kBadText);
    if (const auto problem = check_payload(draft.payload)) return reject(*problem);
    Mailbox* box = mutable_box(route.recipient);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    if (std::cmp_greater_equal(box->mails.size(), limits_.mail_inbox_cap)) return reject(MailError::kInboxFull);
    const auto reservation = port.reserve(route.sender, draft.payload, limits_.mail_send_fee_copper);
    if (!reservation) return reject(MailError::kAttachmentRejected);
    Mail mail = make_mail(MailKind::kNormal, route.sender, sender->name, draft, now);
    const MailId id = mail.id;
    deliver(*box, std::move(mail));
    port.commit(*reservation);
    MailResult result;
    MailEvent event;
    event.kind = MailEventKind::kReceived;
    event.mail = id;
    event.subject = route.sender;
    event.value = limits_.mail_send_fee_copper;
    event.audience = {route.recipient};
    result.events.push_back(std::move(event));
    return result;
}

MailResult MailBook::send_system(Tick now, CharacterId recipient, const MailDraft& draft) {
    if (!is_plain_text(draft.title, static_cast<std::size_t>(limits_.mail_title_max_bytes)) ||
        !is_body_text(draft.text, static_cast<std::size_t>(limits_.mail_text_max_bytes))) {
        return reject(MailError::kBadText);
    }
    if (const auto problem = check_payload(draft.payload)) return reject(*problem);
    Mailbox* box = mutable_box(recipient);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    if (std::cmp_greater_equal(box->mails.size(), limits_.mail_inbox_cap)) return reject(MailError::kInboxFull);
    Mail mail = make_mail(MailKind::kSystem, CharacterId{}, std::string(), draft, now);
    const MailId id = mail.id;
    deliver(*box, std::move(mail));
    MailResult result;
    MailEvent event;
    event.kind = MailEventKind::kReceived;
    event.mail = id;
    event.audience = {recipient};
    result.events.push_back(std::move(event));
    return result;
}

MailResult MailBook::mark_read(CharacterId owner, MailId mail) {
    Mailbox* box = mutable_box(owner);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    Mail* found = find_mail(*box, mail);
    if (found == nullptr) return reject(MailError::kNoSuchMail);
    found->read = true;
    return {};
}

MailResult MailBook::remove(CharacterId owner, MailId mail) {
    Mailbox* box = mutable_box(owner);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    const Mail* found = find_mail(*box, mail);
    if (found == nullptr) return reject(MailError::kNoSuchMail);
    if (found->payload.has_any()) return reject(MailError::kHasAttachments);
    std::erase_if(box->mails, [mail](const Mail& m) { return m.id == mail; });
    MailResult result;
    MailEvent event;
    event.kind = MailEventKind::kDeleted;
    event.mail = mail;
    event.audience = {owner};
    result.events.push_back(std::move(event));
    return result;
}

MailResult MailBook::claim(Tick now, AttachmentPort& port, CharacterId owner, MailId mail) {
    Mailbox* box = mutable_box(owner);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    Mail* found = find_mail(*box, mail);
    if (found == nullptr) return reject(MailError::kNoSuchMail);
    if (!found->payload.has_any()) return reject(MailError::kNoAttachments);
    const Copper cod = found->payload.cod;
    Mailbox* payee = nullptr;
    if (cod > 0) {
        // Tiền người nhận trả phải có chỗ đáp xuống trước khi trừ tiền người nhận.
        payee = found->sender.value() == 0 ? nullptr : mutable_box(found->sender);
        if (payee == nullptr || payee == box || std::cmp_greater_equal(payee->mails.size(), limits_.mail_inbox_cap)) {
            return reject(MailError::kSenderUnavailable);
        }
    }
    if (!port.claim(owner, found->payload, cod)) return reject(MailError::kAttachmentRejected);
    const CharacterId payer_target = found->sender;
    found->payload = MailPayload{};
    found->read = true;
    MailResult result;
    MailEvent claimed;
    claimed.kind = MailEventKind::kClaimed;
    claimed.mail = mail;
    claimed.value = cod;
    claimed.audience = {owner};
    result.events.push_back(std::move(claimed));
    if (cod > 0 && payee != nullptr) {
        MailDraft payment;
        payment.payload.money = cod;
        Mail pay = make_mail(MailKind::kSystem, CharacterId{}, std::string(), payment, now);
        const MailId pay_id = pay.id;
        deliver(*payee, std::move(pay));
        MailEvent received;
        received.kind = MailEventKind::kReceived;
        received.mail = pay_id;
        received.audience = {payer_target};
        result.events.push_back(std::move(received));
    }
    return result;
}

MailResult MailBook::return_to_sender(Tick now, CharacterId owner, MailId mail) {
    Mailbox* box = mutable_box(owner);
    if (box == nullptr) return reject(MailError::kNotLoaded);
    const Mail* found = find_mail(*box, mail);
    if (found == nullptr) return reject(MailError::kNoSuchMail);
    if (found->kind != MailKind::kNormal || found->sender.value() == 0) return reject(MailError::kNotReturnable);
    if (!found->payload.has_any()) return reject(MailError::kNoAttachments);
    Mailbox* origin = mutable_box(found->sender);
    if (origin == nullptr || origin == box || std::cmp_greater_equal(origin->mails.size(), limits_.mail_inbox_cap)) {
        return reject(MailError::kSenderUnavailable);
    }
    const CharacterId origin_id = found->sender;
    MailDraft draft;
    draft.title = found->title;
    draft.text = found->text;
    draft.payload = found->payload;
    draft.payload.cod = 0;  // đồ về lại người gửi thì không còn gì để thu
    Mail returned = make_mail(MailKind::kReturned, owner, std::string(), draft, now);
    const MailId returned_id = returned.id;
    std::erase_if(box->mails, [mail](const Mail& m) { return m.id == mail; });
    deliver(*origin, std::move(returned));
    MailResult result;
    MailEvent deleted;
    deleted.kind = MailEventKind::kDeleted;
    deleted.mail = mail;
    deleted.audience = {owner};
    result.events.push_back(std::move(deleted));
    MailEvent back;
    back.kind = MailEventKind::kReturned;
    back.mail = returned_id;
    back.subject = owner;
    back.audience = {origin_id};
    result.events.push_back(std::move(back));
    return result;
}

MailEvents MailBook::tick(Tick now) {
    MailEvents out;
    std::vector<std::pair<CharacterId, MailId>> to_return;
    for (auto& [owner, box] : boxes_) {
        const CharacterId owner_id = owner;
        std::erase_if(box.mails, [this, &out, &to_return, owner_id, now](const Mail& mail) {
            if (ids::advance(mail.sent, expire_after_) > now) return false;
            if (!mail.payload.has_any()) {
                MailEvent event;
                event.kind = MailEventKind::kExpired;
                event.mail = mail.id;
                event.audience = {owner_id};
                out.push_back(std::move(event));
                return true;
            }
            if (mail.kind == MailKind::kNormal && mail.sender.value() != 0) to_return.emplace_back(owner_id, mail.id);
            return false;
        });
    }
    // Thư còn đồ hết hạn: trả về người gửi khi được, không thì ở lại thử nhịp sau.
    for (const auto& [owner, id] : to_return) {
        MailResult returned = return_to_sender(now, owner, id);
        if (returned.ok()) out.insert(out.end(), std::make_move_iterator(returned.events.begin()), std::make_move_iterator(returned.events.end()));
    }
    return out;
}

std::expected<void, std::string> MailBook::validate() const {
    std::set<MailId> seen;
    for (const auto& [owner, box] : boxes_) {
        if (std::cmp_greater(box.mails.size(), limits_.mail_inbox_cap)) return std::unexpected(std::format("hộp {} quá trần", owner.value()));
        for (const Mail& mail : box.mails) {
            if (const std::string_view problem = mail_problem(mail, limits_); !problem.empty()) {
                return std::unexpected(std::format("thư {}: {}", mail.id.value(), problem));
            }
            if (!seen.insert(mail.id).second) return std::unexpected(std::format("trùng id thư {}", mail.id.value()));
            if (mail.id.value() >= next_mail_) return std::unexpected("id thư vượt bộ đếm");
        }
    }
    return {};
}

// ---------------------------------------------------------------------------------------------
// Mã hoá
// ---------------------------------------------------------------------------------------------

CodecResult encode_mailbox(const Mailbox& box, Tick now, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kMailVersion);
    writer.count(box.mails.size(), kMaxMails);
    for (const Mail& mail : box.mails) {
        writer.u64(mail.id.value());
        writer.u8(static_cast<std::uint8_t>(mail.kind));
        writer.u64(mail.sender.value());
        writer.text(mail.sender_name, kMaxNameBytes);
        writer.text(mail.title, kMaxTitleBytes);
        writer.text(mail.text, kMaxTextBytes);
        writer.boolean(mail.read);
        writer.i64(now > mail.sent ? (now - mail.sent).count : 0);
        writer.count(mail.payload.items.size(), kMaxItems);
        for (const MailItem& item : mail.payload.items) {
            writer.u64(item.serial.value());
            writer.u32(item.item.value());
            writer.u16(item.count);
        }
        writer.u64(mail.payload.pet.value());
        writer.i64(mail.payload.money);
        writer.i64(mail.payload.cod);
    }
    return finish_blob(writer, blob::kMailbox);
}

std::expected<Mailbox, CodecError> decode_mailbox(std::span<const std::byte> bytes, Tick now, const Limits& limits) {
    const auto body = open_blob(bytes, blob::kMailbox);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    const std::uint16_t version = reader.u16();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (version != kMailVersion) return std::unexpected(CodecError::kBadVersion);
    const std::size_t count = reader.count(kMaxMails);
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    Mailbox box;
    box.mails.reserve(count);
    std::set<MailId> seen;
    for (std::size_t index = 0; index < count && reader.is_ok(); ++index) {
        Mail mail;
        mail.id = MailId{reader.u64()};
        const std::uint8_t kind = reader.u8();
        if (!valid_kind(kind)) return std::unexpected(CodecError::kBadValue);
        mail.kind = static_cast<MailKind>(kind);
        mail.sender = CharacterId{reader.u64()};
        mail.sender_name = reader.text(kMaxNameBytes);
        mail.title = reader.text(kMaxTitleBytes);
        mail.text = reader.text(kMaxTextBytes);
        mail.read = reader.boolean();
        const std::int64_t age = reader.i64();
        if (age < 0) return std::unexpected(CodecError::kBadValue);
        mail.sent = ids::advance(now, TickSpan{-age});
        const std::size_t item_count = reader.count(kMaxItems);
        if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
        for (std::size_t slot = 0; slot < item_count && reader.is_ok(); ++slot) {
            MailItem item;
            item.serial = ids::ItemSerial{reader.u64()};
            item.item = ids::ItemTemplateId{reader.u32()};
            item.count = reader.u16();
            mail.payload.items.push_back(item);
        }
        mail.payload.pet = ids::PetId{reader.u64()};
        mail.payload.money = reader.i64();
        mail.payload.cod = reader.i64();
        if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
        if (!mail_problem(mail, limits).empty() || !seen.insert(mail.id).second) return std::unexpected(CodecError::kBadValue);
        box.mails.push_back(std::move(mail));
    }
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (std::cmp_greater(box.mails.size(), limits.mail_inbox_cap)) return std::unexpected(CodecError::kBadValue);
    return box;
}

} // namespace game::social
