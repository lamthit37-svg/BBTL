// Thư: gửi cho bạn bè, phí, đính kèm hai pha, thu tiền khi nhận, trả thư, hết hạn, khối lưu bền. Sai thì
// đồ hoặc tiền biến mất hay nhân đôi, nên mỗi ca kiểm bảo toàn: một sê-ri vật phẩm ở đúng một nơi.
#include "ids/ids.hpp"
#include "social/codec.hpp"
#include "social/directory.hpp"
#include "social/mail.hpp"
#include "social/policy.hpp"
#include "social/relation.hpp"
#include "social/types.hpp"
#include "social_port.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using social::Copper;
using social::Mail;
using social::MailBook;
using social::MailDraft;
using social::MailError;
using social::MailEvent;
using social::MailEventKind;
using social::MailId;
using social::MailItem;
using social::MailKind;
using social::MailPayload;
using social::MailRoute;
using social::Mailbox;
using social::RelationBook;
using social::ReservationId;
using social::Tick;

constexpr Tick kNow{10'000};

class DenyBad final : public social::TextPolicy {
public:
    [[nodiscard]] bool allowed(std::string_view text) const override { return text.find("bad") == std::string_view::npos; }
};

struct World {
    FakeDirectory directory;
    DenyBad policy;
    RelationBook relations{sample_limits(), sample_relation_rules()};
    MailBook mail{sample_limits(), policy};
    FakePort port;

    explicit World(std::uint64_t players) {
        for (std::uint64_t id = 1; id <= players; ++id) {
            directory.add(id, "p" + std::to_string(id), 50);
            relations_ok = relations.load(cid(id), social::RelationSheet{}).has_value() && relations_ok;
            mail_ok = mail.load(cid(id), Mailbox{}).has_value() && mail_ok;
            port.inventory[cid(id)].money = 100'000;
        }
    }

    bool relations_ok = true;
    bool mail_ok = true;

    bool befriend(std::uint64_t left, std::uint64_t right) {
        if (!relations.request(kNow, directory, social::BondKind::kFriend, cid(left), cid(right)).ok()) return false;
        return relations.answer(kNow, directory, social::BondKind::kFriend, cid(right), cid(left), true).ok();
    }

    [[nodiscard]] social::MailResult send(std::uint64_t from, std::uint64_t to, std::string_view title, std::string_view text,
        MailPayload payload = {}) {
        return mail.send(kNow, directory, relations, port, MailRoute{.sender = cid(from), .recipient = cid(to)},
            MailDraft{.title = title, .text = text, .payload = std::move(payload)});
    }

    [[nodiscard]] std::size_t box_size(std::uint64_t owner) const {
        const Mailbox* box = mail.mailbox(cid(owner));
        return box == nullptr ? 0U : box->mails.size();
    }

    // Số nơi đang giữ sê-ri `serial`: hành trang + thư. Bảo toàn khi luôn bằng 1.
    [[nodiscard]] int places_of(std::uint64_t serial) const {
        int places = 0;
        for (const auto& [id, have] : port.inventory) places += have.items.contains(serial) ? 1 : 0;
        for (std::uint64_t owner = 1; owner <= 40; ++owner) {
            const Mailbox* box = mail.mailbox(cid(owner));
            if (box == nullptr) continue;
            for (const Mail& entry : box->mails) {
                for (const MailItem& item : entry.payload.items) places += item.serial.value() == serial ? 1 : 0;
            }
        }
        return places;
    }
};

[[nodiscard]] MailItem item(std::uint64_t serial) {
    return MailItem{.serial = ids::ItemSerial{serial}, .item = ids::ItemTemplateId{1000}, .count = 1};
}

void expect_valid(Context& context, const World& world) {
    context.expect(world.mail.validate().has_value(), "validate() đạt");
}

[[nodiscard]] const Mail* mail_at(const World& world, CharacterId owner, std::size_t index) {
    const Mailbox* box = world.mail.mailbox(owner);
    if (box == nullptr || index >= box->mails.size()) return nullptr;
    return &box->mails[index];
}

// Bản sao của thư ở vị trí `index` (Mail rỗng nếu không có) để đọc trường mà không dereference con trỏ rỗng.
[[nodiscard]] Mail copy_at(const World& world, CharacterId owner, std::size_t index) {
    const Mail* found = mail_at(world, owner, index);
    return found == nullptr ? Mail{} : *found;
}

void send_and_receive(Context& context) {
    World world(3);
    context.expect(world.relations_ok && world.mail_ok, "dựng sổ");
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501, 502};
    MailPayload payload;
    payload.items = {item(501)};
    payload.money = 300;
    const auto sent = world.send(1, 2, "chào", "nội dung\nhai dòng", payload);
    context.expect(sent.ok() && sent.events.size() == 1 && sent.events[0].audience == std::vector{cid(2)}, "gửi được");
    context.expect(sent.events[0].value == 2000, "phí 2000 đồng");
    const Mail* got = mail_at(world, cid(2), 0);
    context.expect(got != nullptr && got->kind == MailKind::kNormal && got->sender == cid(1) && got->sender_name == "p1" &&
                       got->title == "chào" && got->payload.money == 300 && got->payload.items.size() == 1,
        "thư nằm trong hộp người nhận");
    // Đồ rời hành trang người gửi sau pha 2, tiền trừ cả phí lẫn tiền kèm.
    context.expect(!world.port.inventory[cid(1)].items.contains(501) && world.port.inventory[cid(1)].items.contains(502), "chỉ đồ đính kèm rời người gửi");
    context.expect(world.port.inventory[cid(1)].money == 100'000 - 2000 - 300 && world.port.held.empty(), "trừ phí và tiền kèm, không còn giữ chỗ treo");
    context.expect(world.places_of(501) == 1 && world.places_of(502) == 1, "mỗi sê-ri ở đúng một nơi");
    expect_valid(context, world);
}

void send_rejections_change_nothing(Context& context) {
    World world(5);
    world.directory.at(3).level = 49;
    world.directory.at(4).settings = social::setting::kCannotReceiveMail;
    context.expect(world.befriend(1, 2) && world.befriend(1, 4) && world.befriend(3, 2), "bạn");
    world.port.inventory[cid(1)].items = {501, 502, 503, 504, 505, 506, 507};
    world.port.inventory[cid(1)].pets = {900};
    const MailId before = world.mail.next_mail_id();
    const auto fail = [&world](std::uint64_t from, std::uint64_t to, MailPayload payload, std::string_view title = "t", std::string_view text = "x") {
        return world.send(from, to, title, text, std::move(payload)).error;
    };
    context.expect(fail(1, 1, {}) == MailError::kSelf, "tự gửi");
    context.expect(fail(1, 99, {}) == MailError::kUnknownPlayer, "người nhận lạ");
    context.expect(fail(3, 2, {}) == MailError::kLevelTooLow, "cấp 49");
    context.expect(fail(1, 3, {}) == MailError::kNotFriend, "chưa là bạn");
    context.expect(fail(1, 4, {}) == MailError::kRefused, "người nhận tắt nhận thư");
    context.expect(world.relations.blacklist(world.directory, cid(2), cid(1)).ok(), "2 chặn 1");
    context.expect(fail(1, 2, {}) == MailError::kNotFriend, "bị chặn (không còn là bạn)");
    World second(4);
    context.expect(second.befriend(1, 2), "bạn");
    second.port.inventory[cid(1)].items = {501, 502, 503, 504, 505, 506, 507};
    second.port.inventory[cid(1)].pets = {900};
    const auto fail2 = [&second](MailPayload payload, std::string_view title = "t", std::string_view text = "x") {
        return second.send(1, 2, title, text, std::move(payload)).error;
    };
    MailPayload six;
    for (std::uint64_t serial = 501; serial <= 506; ++serial) six.items.push_back(item(serial));
    context.expect(fail2(six) == MailError::kTooManyItems, "6 vật phẩm");
    MailPayload dup;
    dup.items = {item(501), item(501)};
    context.expect(fail2(dup) == MailError::kBadItem, "trùng sê-ri");
    MailPayload zero;
    zero.items = {MailItem{.serial = ids::ItemSerial{501}, .item = ids::ItemTemplateId{1}, .count = 0}};
    context.expect(fail2(zero) == MailError::kBadItem, "số lượng 0");
    MailPayload negative;
    negative.money = -1;
    context.expect(fail2(negative) == MailError::kBadMoney, "tiền âm");
    MailPayload huge;
    huge.money = social::kCopperCeiling + 1;
    context.expect(fail2(huge) == MailError::kBadMoney, "tiền vượt trần");
    MailPayload cod_no_goods;
    cod_no_goods.cod = 10;
    context.expect(fail2(cod_no_goods) == MailError::kBadCod, "thu tiền mà không có đồ");
    MailPayload cod_with_money;
    cod_with_money.items = {item(501)};
    cod_with_money.cod = 10;
    cod_with_money.money = 5;
    context.expect(fail2(cod_with_money) == MailError::kBadCod, "thu tiền mà còn kèm tiền");
    context.expect(fail2({}, std::string(21, 'a')) == MailError::kBadText, "tiêu đề 21 byte");
    context.expect(fail2({}, "t", std::string(254, 'a')) == MailError::kBadText, "nội dung 254 byte");
    context.expect(fail2({}, "t", std::string_view("a\x01" "b", 3)) == MailError::kBadText, "ký tự điều khiển");
    context.expect(fail2({}, "t", "bad") == MailError::kBadText, "bộ lọc chữ cấm");
    context.expect(fail2({}, std::string_view("\xFF\xFE", 2)) == MailError::kBadText, "UTF-8 hỏng");
    // Đồ không thuộc người gửi: hành trang từ chối ở pha 1, nhưng thư không được vào hộp.
    MailPayload not_mine;
    not_mine.items = {item(777)};
    context.expect(fail2(not_mine) == MailError::kAttachmentRejected, "đồ không thuộc người gửi");
    MailPayload too_poor;
    too_poor.money = 99'999;
    context.expect(fail2(too_poor) == MailError::kAttachmentRejected, "tiền kèm cộng phí vượt số dư");
    context.expect(second.box_size(2) == 0 && second.port.held.empty() && second.port.fees_burned == 0, "mọi lỗi: hộp rỗng, không giữ chỗ, không thu phí");
    context.expect(second.port.inventory[cid(1)].money == 100'000 && second.port.inventory[cid(1)].items.size() == 7, "người gửi còn nguyên tiền và đồ");
    context.expect(second.mail.next_mail_id() == MailId{1}, "lỗi không tiêu thụ id thư");
    context.expect(world.mail.next_mail_id() == before, "lỗi không tiêu thụ id thư (sổ 1)");
    expect_valid(context, second);
}

void inbox_full_blocks_without_reserving(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    for (int index = 0; index < 15; ++index) {
        context.expect(world.send(1, 2, "t", "x").ok(), "thư vào hộp");
    }
    MailPayload payload;
    payload.items = {item(501)};
    const auto full = world.send(1, 2, "t", "x", payload);
    context.expect(full.error == MailError::kInboxFull, "hộp đầy 15/15");
    context.expect(world.port.held.empty() && world.port.inventory[cid(1)].items.contains(501), "đồ còn ở người gửi, không có giữ chỗ treo");
    // Người nhận chưa được nạp hộp.
    World other(3);
    context.expect(other.befriend(1, 2), "bạn");
    static_cast<void>(other.mail.unload(cid(2)));
    context.expect(other.send(1, 2, "t", "x").error == MailError::kNotLoaded, "hộp người nhận chưa nạp");
    expect_valid(context, world);
}

void read_and_remove(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    MailPayload payload;
    payload.items = {item(501)};
    context.expect(world.send(1, 2, "có đồ", "x", payload).ok() && world.send(1, 2, "trơn", "x").ok(), "gửi hai thư");
    const MailId with_items = copy_at(world, cid(2), 0).id;
    const MailId plain = copy_at(world, cid(2), 1).id;
    context.expect(world.mail.mark_read(cid(2), plain).ok() && copy_at(world, cid(2), 1).read, "đánh dấu đã đọc");
    context.expect(world.mail.mark_read(cid(2), MailId{999}).error == MailError::kNoSuchMail, "thư không có");
    context.expect(world.mail.mark_read(cid(9), plain).error == MailError::kNotLoaded, "hộp lạ");
    context.expect(world.mail.remove(cid(3), plain).error == MailError::kNoSuchMail, "xoá thư của người khác");
    context.expect(world.mail.remove(cid(2), with_items).error == MailError::kHasAttachments, "thư còn đồ không xoá được");
    context.expect(world.mail.remove(cid(2), plain).ok() && world.box_size(2) == 1, "xoá thư trơn");
    expect_valid(context, world);
}

void claim_free_attachments(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    world.port.inventory[cid(1)].pets = {900};
    MailPayload payload;
    payload.items = {item(501)};
    payload.pet = ids::PetId{900};
    payload.money = 700;
    context.expect(world.send(1, 2, "quà", "x", payload).ok(), "gửi");
    const MailId id = copy_at(world, cid(2), 0).id;
    const Copper before = world.port.total_money();
    world.port.refuse_claim = true;
    context.expect(world.mail.claim(kNow, world.port, cid(2), id).error == MailError::kAttachmentRejected, "hành trang từ chối");
    context.expect(copy_at(world, cid(2), 0).payload.has_any() && world.places_of(501) == 1, "đồ còn nguyên trong thư");
    world.port.refuse_claim = false;
    const auto claimed = world.mail.claim(kNow, world.port, cid(2), id);
    context.expect(claimed.ok() && claimed.events[0].kind == MailEventKind::kClaimed, "lấy đồ");
    context.expect(!copy_at(world, cid(2), 0).payload.has_any() && copy_at(world, cid(2), 0).read, "thư rỗng và đã đọc");
    context.expect(world.port.inventory[cid(2)].items.contains(501) && world.port.inventory[cid(2)].pets.contains(900), "đồ và thú về người nhận");
    context.expect(world.port.total_money() == before + 700, "tiền kèm về người nhận (tiền bảo toàn trừ phần đã nằm trong thư)");
    context.expect(world.places_of(501) == 1, "sê-ri ở đúng một nơi");
    context.expect(world.mail.claim(kNow, world.port, cid(2), id).error == MailError::kNoAttachments, "lấy hai lần");
    context.expect(world.mail.remove(cid(2), id).ok(), "xoá thư rỗng");
    expect_valid(context, world);
}

void cash_on_delivery(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    MailPayload payload;
    payload.items = {item(501)};
    payload.cod = 5000;
    context.expect(world.send(1, 2, "bán", "x", payload).ok(), "gửi thu tiền");
    const MailId id = copy_at(world, cid(2), 0).id;
    // Người nhận không đủ tiền: hành trang từ chối, mọi thứ nguyên.
    world.port.inventory[cid(2)].money = 4999;
    context.expect(world.mail.claim(kNow, world.port, cid(2), id).error == MailError::kAttachmentRejected, "thiếu 1 đồng");
    context.expect(world.box_size(1) == 0 && copy_at(world, cid(2), 0).payload.has_goods(), "chưa ai nhận gì");
    // Hộp người gửi đầy: không trừ tiền người nhận, báo người gửi chưa nhận được.
    for (int index = 0; index < 15; ++index) {
        context.expect(world.mail.send_system(kNow, cid(1), MailDraft{.title = "t", .text = "x", .payload = {}}).ok(), "lấp đầy hộp người gửi");
    }
    world.port.inventory[cid(2)].money = 10'000;
    context.expect(world.mail.claim(kNow, world.port, cid(2), id).error == MailError::kSenderUnavailable, "hộp người gửi đầy");
    context.expect(world.port.inventory[cid(2)].money == 10'000 && copy_at(world, cid(2), 0).payload.has_goods(), "tiền người nhận chưa bị trừ");
    // Dọn chỗ rồi nhận.
    const MailId first = copy_at(world, cid(1), 0).id;
    context.expect(world.mail.remove(cid(1), first).ok(), "dọn một chỗ");
    const Copper before = world.port.total_money();
    const auto paid = world.mail.claim(kNow, world.port, cid(2), id);
    context.expect(paid.ok() && paid.events.size() == 2 && paid.events[0].value == 5000, "nhận đồ, trả 5000");
    context.expect(world.port.inventory[cid(2)].money == 5000 && world.port.inventory[cid(2)].items.contains(501), "người nhận mất 5000 và được đồ");
    const Mail* payment = mail_at(world, cid(1), 14);
    context.expect(payment != nullptr && payment->kind == MailKind::kSystem && payment->payload.money == 5000 && payment->sender.value() == 0,
        "người gửi nhận thư hệ thống chứa đúng 5000");
    // Bảo toàn: tiền trong hành trang giảm 5000 (đã chuyển vào thư), cộng với tiền nằm trong thư thành bằng nhau.
    context.expect(world.port.total_money() + 5000 == before, "tổng tiền hành trang giảm đúng phần đã vào thư");
    expect_valid(context, world);
}

void return_to_sender(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    MailPayload payload;
    payload.items = {item(501)};
    payload.cod = 99;
    context.expect(world.send(1, 2, "trả", "x", payload).ok() && world.send(1, 2, "trơn", "x").ok(), "gửi");
    const MailId with_items = copy_at(world, cid(2), 0).id;
    const MailId plain = copy_at(world, cid(2), 1).id;
    context.expect(world.mail.return_to_sender(kNow, cid(2), plain).error == MailError::kNoAttachments, "thư trơn không cần trả");
    const auto back = world.mail.return_to_sender(kNow, cid(2), with_items);
    context.expect(back.ok() && back.events.size() == 2, "trả thư");
    context.expect(world.box_size(2) == 1 && world.box_size(1) == 1, "thư rời hộp người nhận, về hộp người gửi");
    const Mail* returned = mail_at(world, cid(1), 0);
    context.expect(returned != nullptr && returned->kind == MailKind::kReturned && returned->sender == cid(2) && returned->payload.cod == 0 &&
                       returned->payload.items.size() == 1,
        "thư trả: loại 1, đồ nguyên, COD bị bỏ");
    context.expect(world.places_of(501) == 1, "sê-ri ở đúng một nơi");
    context.expect(world.mail.return_to_sender(kNow, cid(1), returned->id).error == MailError::kNotReturnable, "thư trả không trả lần nữa");
    // Thư hệ thống không trả được; hộp người gửi chưa nạp thì giữ thư.
    World two(3);
    context.expect(two.befriend(1, 2), "bạn");
    two.port.inventory[cid(1)].items = {501};
    MailPayload pay2;
    pay2.items = {item(501)};
    context.expect(two.send(1, 2, "x", "y", pay2).ok(), "gửi");
    static_cast<void>(two.mail.unload(cid(1)));
    context.expect(two.mail.return_to_sender(kNow, cid(2), copy_at(two, cid(2), 0).id).error == MailError::kSenderUnavailable, "người gửi chưa nạp hộp");
    context.expect(two.box_size(2) == 1 && two.places_of(501) == 1, "thư và đồ vẫn còn");
    context.expect(two.mail.send_system(kNow, cid(2), MailDraft{.title = "s", .text = "", .payload = {}}).ok(), "thư hệ thống");
    context.expect(two.mail.return_to_sender(kNow, cid(2), copy_at(two, cid(2), 1).id).error == MailError::kNotReturnable, "thư hệ thống không trả");
    expect_valid(context, world);
}

void system_mail(Context& context) {
    World world(2);
    MailPayload gift;
    gift.items = {item(601)};
    gift.money = 50;
    const auto sent = world.mail.send_system(kNow, cid(1), MailDraft{.title = "quà", .text = "chào mừng", .payload = gift});
    context.expect(sent.ok(), "gửi thư hệ thống");
    context.expect(copy_at(world, cid(1), 0).kind == MailKind::kSystem && copy_at(world, cid(1), 0).sender.value() == 0, "loại 2, không người gửi");
    context.expect(world.mail.send_system(kNow, cid(9), MailDraft{.title = "t", .text = "", .payload = {}}).error == MailError::kNotLoaded, "hộp chưa nạp");
    context.expect(world.mail.send_system(kNow, cid(1), MailDraft{.title = std::string(21, 'a'), .text = "", .payload = {}}).error == MailError::kBadText, "tiêu đề dài");
    MailPayload cod;
    cod.cod = 5;
    context.expect(world.mail.send_system(kNow, cid(1), MailDraft{.title = "t", .text = "", .payload = cod}).error == MailError::kBadCod, "COD không đồ");
    // Đồ hệ thống đến tay người nhận khi lấy.
    const auto claimed = world.mail.claim(kNow, world.port, cid(1), copy_at(world, cid(1), 0).id);
    context.expect(claimed.ok() && world.port.inventory[cid(1)].items.contains(601), "lấy đồ từ thư hệ thống");
    expect_valid(context, world);
}

void expiry_rules(Context& context) {
    World world(3);
    context.expect(world.befriend(1, 2), "bạn");
    world.port.inventory[cid(1)].items = {501};
    MailPayload payload;
    payload.items = {item(501)};
    context.expect(world.send(1, 2, "trơn", "x").ok() && world.send(1, 2, "đồ", "x", payload).ok(), "gửi hai thư lúc kNow");
    const Tick day29 = ids::advance(kNow, ids::TickSpan{(2'592'000LL - 1) * 20});
    context.expect(world.mail.tick(day29).empty() && world.box_size(2) == 2, "chưa tới 30 ngày");
    const Tick day30 = ids::advance(kNow, ids::TickSpan{2'592'000LL * 20});
    const auto events = world.mail.tick(day30);
    std::size_t expired = 0;
    std::size_t returned = 0;
    for (const MailEvent& event : events) {
        expired += event.kind == MailEventKind::kExpired ? 1U : 0U;
        returned += event.kind == MailEventKind::kReturned ? 1U : 0U;
    }
    context.expect(expired == 1 && returned == 1, "thư trơn hết hạn bị xoá, thư có đồ được trả");
    context.expect(world.box_size(2) == 0 && world.box_size(1) == 1 && world.places_of(501) == 1, "đồ về người gửi, không biến mất");
    // Thư trả hết hạn nữa: còn đồ thì ở lại (người gửi phải tự lấy).
    const Tick far = ids::advance(day30, ids::TickSpan{2'592'000LL * 20});
    context.expect(world.mail.tick(far).empty() && world.box_size(1) == 1, "thư trả còn đồ không tự biến mất");
    // Người gửi chưa nạp hộp: thư có đồ ở lại.
    World second(3);
    context.expect(second.befriend(1, 2), "bạn");
    second.port.inventory[cid(1)].items = {501};
    context.expect(second.send(1, 2, "đồ", "x", payload).ok(), "gửi");
    static_cast<void>(second.mail.unload(cid(1)));
    context.expect(second.mail.tick(day30).empty() && second.box_size(2) == 1 && second.places_of(501) == 1, "chưa trả được thì giữ thư");
    expect_valid(context, world);
    expect_valid(context, second);
}

[[nodiscard]] std::vector<std::byte> from_hex(std::string_view hex) {
    std::vector<std::byte> bytes;
    for (std::size_t index = 0; index + 1 < hex.size(); index += 2) {
        const auto digit = [](char c) { return c <= '9' ? c - '0' : c - 'a' + 10; };
        bytes.push_back(static_cast<std::byte>((digit(hex[index]) * 16) + digit(hex[index + 1])));
    }
    return bytes;
}

[[nodiscard]] Mailbox sample_box() {
    Mailbox box;
    Mail mail;
    mail.id = MailId{5};
    mail.kind = MailKind::kNormal;
    mail.sender = cid(7);
    mail.sender_name = "x";
    mail.title = "t";
    mail.text = "b";
    mail.payload.items = {MailItem{.serial = ids::ItemSerial{9}, .item = ids::ItemTemplateId{3}, .count = 2}};
    mail.payload.money = 11;
    mail.sent = Tick{kNow.value() - 100};
    box.mails.push_back(mail);
    return box;
}

void codec_golden_and_round_trip(Context& context) {
    const Mailbox box = sample_box();
    social::Bytes bytes;
    context.expect(social::encode_mailbox(box, kNow, bytes).has_value(), "mã hoá");
    // Số vàng tính tay: đầu khung (thân 79 byte, kind 0x5104), phiên bản 1, một thư: id 5, loại 0, người gửi 7,
    // tên "x", tiêu đề "t", nội dung "b", chưa đọc, tuổi 100 tick, một vật phẩm (sê-ri 9, mẫu 3, số lượng 2),
    // không thú, tiền 11, không thu tiền.
    const auto golden = from_hex(
        "4f000000" "0451" "0000"
        "0100" "0100"
        "0500000000000000" "00" "0700000000000000" "0100" "78" "0100" "74" "0100" "62" "00" "6400000000000000"
        "0100" "0900000000000000" "03000000" "0200"
        "0000000000000000" "0b00000000000000" "0000000000000000");
    context.expect(bytes == golden, "khớp số vàng");
    const auto back = social::decode_mailbox(bytes, kNow, sample_limits());
    context.expect(back.has_value() && back->mails.size() == 1 && back->mails[0].id == MailId{5} && back->mails[0].sent == Tick{kNow.value() - 100} &&
                       back->mails[0].payload.money == 11 && back->mails[0].payload.items[0].count == 2,
        "giải mã đúng, tuổi thư tính lại");
    const Tick later{kNow.value() + 5000};
    const auto restarted = social::decode_mailbox(bytes, later, sample_limits());
    context.expect(restarted.has_value() && restarted->mails[0].sent == Tick{later.value() - 100}, "nạp ở mốc khác: tuổi giữ nguyên");
}

void codec_rejects_garbage(Context& context) {
    const Mailbox box = sample_box();
    social::Bytes bytes;
    context.expect(social::encode_mailbox(box, kNow, bytes).has_value(), "mã hoá");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        every_cut_rejected = every_cut_rejected && !social::decode_mailbox(std::span<const std::byte>(bytes.data(), cut), kNow, sample_limits()).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt bị từ chối");
    social::Bytes extra = bytes;
    extra.push_back(std::byte{0});
    context.expect(!social::decode_mailbox(extra, kNow, sample_limits()).has_value(), "byte thừa");
    for (std::size_t index = 0; index < bytes.size(); ++index) {
        for (const unsigned flip : {0x01U, 0x80U, 0xFFU}) {
            social::Bytes copy = bytes;
            copy.at(index) = static_cast<std::byte>(static_cast<unsigned>(copy.at(index)) ^ flip);
            const auto decoded = social::decode_mailbox(copy, kNow, sample_limits());
            if (decoded.has_value()) {
                // Bản nào lọt qua phải đủ điều kiện nạp vào sổ.
                const social::AllowAllText policy;
                MailBook book(sample_limits(), policy);
                context.expect(book.load(cid(1), *decoded).has_value(), "bản lật byte nào lọt giải mã đều nạp được");
            }
        }
    }
    social::Bytes wrong = bytes;
    wrong.at(4) = std::byte{0x05};
    context.expect(social::decode_mailbox(wrong, kNow, sample_limits()).error() == social::CodecError::kBadKind, "kind sai");
    social::Bytes future = bytes;
    future.at(8) = std::byte{7};
    context.expect(social::decode_mailbox(future, kNow, sample_limits()).error() == social::CodecError::kBadVersion, "phiên bản lạ");
    // Hình dạng sai: COD không đồ, kind lạ, trùng id, đủ 16 thư.
    const auto reject_box = [&context](const Mailbox& bad, std::string_view why) {
        social::Bytes out;
        context.expect(social::encode_mailbox(bad, kNow, out).has_value(), "mã hoá bản sai hình dạng");
        context.expect(!social::decode_mailbox(out, kNow, sample_limits()).has_value(), why);
    };
    Mailbox cod = box;
    cod.mails[0].payload.items.clear();
    cod.mails[0].payload.cod = 5;
    reject_box(cod, "COD không đồ");
    Mailbox kind = box;
    kind.mails[0].kind = static_cast<MailKind>(9);
    reject_box(kind, "loại thư lạ");
    Mailbox dup = box;
    dup.mails.push_back(box.mails[0]);
    reject_box(dup, "trùng id thư");
    Mailbox crowded;
    for (std::uint64_t id = 1; id <= 16; ++id) {
        Mail mail = box.mails[0];
        mail.id = MailId{id};
        crowded.mails.push_back(mail);
    }
    reject_box(crowded, "16 thư vượt trần 15");
    Mailbox many_items = box;
    for (std::uint64_t serial = 20; serial < 25; ++serial) {
        many_items.mails[0].payload.items.push_back(MailItem{.serial = ids::ItemSerial{serial}, .item = ids::ItemTemplateId{1}, .count = 1});
    }
    reject_box(many_items, "6 vật phẩm");
    Mailbox negative = box;
    negative.mails[0].payload.money = -3;
    reject_box(negative, "tiền âm");
}

void load_rejects_conflicts(Context& context) {
    const social::AllowAllText policy;
    MailBook book(sample_limits(), policy);
    context.expect(book.load(cid(1), sample_box()).has_value(), "nạp hộp");
    context.expect(book.next_mail_id() == MailId{6}, "bộ đếm id vượt id đã nạp");
    context.expect(!book.load(cid(2), sample_box()).has_value(), "id thư đã nằm ở hộp khác");
    context.expect(!book.load(cid(0), Mailbox{}).has_value(), "chủ hộp id 0");
    context.expect(book.validate().has_value(), "validate() đạt");
}

constexpr std::array kCases{
    Case{.name = "send_and_receive", .body = send_and_receive},
    Case{.name = "send_rejections_change_nothing", .body = send_rejections_change_nothing},
    Case{.name = "inbox_full_blocks_without_reserving", .body = inbox_full_blocks_without_reserving},
    Case{.name = "read_and_remove", .body = read_and_remove},
    Case{.name = "claim_free_attachments", .body = claim_free_attachments},
    Case{.name = "cash_on_delivery", .body = cash_on_delivery},
    Case{.name = "return_to_sender", .body = return_to_sender},
    Case{.name = "system_mail", .body = system_mail},
    Case{.name = "expiry_rules", .body = expiry_rules},
    Case{.name = "codec_golden_and_round_trip", .body = codec_golden_and_round_trip},
    Case{.name = "codec_rejects_garbage", .body = codec_rejects_garbage},
    Case{.name = "load_rejects_conflicts", .body = load_rejects_conflicts},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
