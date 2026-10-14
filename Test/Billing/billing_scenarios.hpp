// Kịch bản dùng chung cho mọi Book: cùng một dãy khẳng định chạy trên MemoryBook (billing_tests) và PgBook
// (billing_db_tests). Hai bản phải ra cùng kết quả vì chúng dùng chung bộ hàm luật; chỗ lệch là lỗi của một trong hai.
// Số vàng ở đây tính tay từ định nghĩa (ví dụ ceil(10 * 10 / 3) = 34), không lấy từ đầu ra của mã.
#pragma once

#include "billing/book.hpp"
#include "billing/code.hpp"
#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/types.hpp"
#include "ids/ids.hpp"

#include "billing_support.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <initializer_list>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing::scenario {

using test::Context;
using test::billing_support::kT0;

// Nơi kịch bản lấy sổ: `fresh` trả một sổ trống mới (PgBook thì trên schema mới), `corrupt` cố ý làm lệch bản nhớ đệm
// số dư để thử đường phát hiện và dựng lại.
struct Env {
    std::function<std::unique_ptr<Book>()> fresh;
    std::function<void(Book&, AccountId, Points)> corrupt;
};

constexpr AccountId kA{7};
constexpr AccountId kB{8};

[[nodiscard]] inline UnixTime at(std::int64_t offset) {
    return UnixTime{kT0 + offset};
}

[[nodiscard]] inline PaymentEvent paid(std::string_view trade, AccountId account, std::int64_t points,
    PaymentStatus status = PaymentStatus::kPaid) {
    return PaymentEvent{.provider = "alpha",
        .trade_no = std::string{trade},
        .account = account,
        .points = Points{points},
        .amount_minor = points * 1000,
        .currency = "VND",
        .status = status};
}

// Nguồn byte cố định cho mint_code: 0, 1, 2, ... lặp.
struct Counter {
    std::uint8_t next = 0;
};

inline bool fill_counter(void* context, std::span<std::byte> out) {
    auto* counter = static_cast<Counter*>(context);
    for (std::byte& byte : out)
        byte = static_cast<std::byte>(counter->next++);
    return true;
}

inline bool fill_ones(void*, std::span<std::byte> out) {
    for (std::byte& byte : out)
        byte = std::byte{0xFF};
    return true;
}

inline bool fill_fail(void*, std::span<std::byte>) {
    return false;
}

inline void topup_exchange(Context& context, const Env& env) {
    const std::unique_ptr<Book> owned = env.fresh();
    Book& book = *owned;
    const Result<Balance> start = book.ensure_account(kA, at(0));
    context.expect(start && start->available.value() == 100, "quà đăng ký 10 điểm");
    context.expect(book.ensure_account(kA, at(1))->available.value() == 100, "quà đăng ký chỉ một lần");

    const Result<PaymentOutcome> topped = book.apply_payment(paid("T1", kA, 500), at(2));
    context.expect(topped && topped->result == PaymentResult::kApplied && topped->balance.value() == 600, "nạp 500");
    const Result<PaymentOutcome> dup = book.apply_payment(paid("T1", kA, 500), at(3));
    context.expect(dup && dup->result == PaymentResult::kDuplicate && dup->balance.value() == 600, "webhook gọi lại");
    const Result<PaymentOutcome> clash = book.apply_payment(paid("T1", kA, 400), at(3));
    context.expect(!clash && clash.error() == Error::kConflict, "cùng mã khác số điểm");
    const Result<PaymentOutcome> other_account = book.apply_payment(paid("T1", kB, 500), at(3));
    context.expect(!other_account && other_account.error() == Error::kConflict, "cùng mã khác tài khoản");

    ExchangeRequest request{.account = kA, .character = CharacterId{70}, .request = RequestId{1}, .ingot = Ingot{10}};
    const Result<ExchangeOutcome> begun = book.exchange_begin(request, at(10));
    // ceil(10 * 10 / 3) = 34.
    context.expect(begun && !begun->replayed && begun->order.points.value() == 34 && begun->balance.value() == 566,
        "giữ 34 phần mười điểm");
    context.expect(book.balance(kA)->held.value() == 34, "điểm giữ hiện trong số dư");
    const Result<ExchangeOutcome> replay = book.exchange_begin(request, at(11));
    context.expect(replay && replay->replayed && replay->order.id == begun->order.id && replay->balance.value() == 566,
        "gọi lại cùng request không trừ thêm");
    ExchangeRequest changed = request;
    changed.ingot = Ingot{11};
    context.expect(book.exchange_begin(changed, at(11)).error() == Error::kConflict, "cùng request khác nội dung");
    changed = request;
    changed.character = CharacterId{71};
    context.expect(book.exchange_begin(changed, at(11)).error() == Error::kConflict, "cùng request khác nhân vật");
    ExchangeRequest big{.account = kA, .character = CharacterId{70}, .request = RequestId{2}, .ingot = Ingot{500000}};
    context.expect(book.exchange_begin(big, at(12)).error() == Error::kInsufficient, "không đủ điểm");
    big.ingot = Ingot{0};
    context.expect(book.exchange_begin(big, at(12)).error() == Error::kBadAmount, "0 ingot");
    big.ingot = Ingot{500001};
    context.expect(book.exchange_begin(big, at(12)).error() == Error::kBadAmount, "quá trần mỗi đơn");
    big.request = RequestId{0};
    big.ingot = Ingot{1};
    context.expect(book.exchange_begin(big, at(12)).error() == Error::kMalformed, "request 0");

    const Result<ExchangeOutcome> confirmed = book.exchange_finish(begun->order.id, Verdict::kDone, at(20));
    context.expect(confirmed && confirmed->order.status == ExchangeStatus::kConfirmed && confirmed->balance.value() == 566,
        "xác nhận không đổi số dư");
    context.expect(book.exchange_finish(begun->order.id, Verdict::kDone, at(21))->replayed, "xác nhận lặp");
    context.expect(book.exchange_finish(begun->order.id, Verdict::kCancelled, at(22)).error() == Error::kBadState,
        "đã xác nhận mà báo huỷ: không hoàn điểm");
    context.expect(book.balance(kA)->available.value() == 566, "số dư giữ nguyên sau báo ngược");
    context.expect(book.exchange_finish(ExchangeId{999}, Verdict::kDone, at(22)).error() == Error::kNotFound, "đơn lạ");

    // Huỷ một đơn: điểm quay về, đúng một lần.
    request.request = RequestId{3};
    request.ingot = Ingot{30};
    const Result<ExchangeOutcome> second = book.exchange_begin(request, at(30));
    context.expect(second && second->balance.value() == 566 - 100, "ceil(300/3) = 100");
    const Result<ExchangeOutcome> cancelled = book.exchange_finish(second->order.id, Verdict::kCancelled, at(31));
    context.expect(cancelled && cancelled->balance.value() == 566, "huỷ hoàn đủ");
    context.expect(book.exchange_finish(second->order.id, Verdict::kCancelled, at(32))->balance.value() == 566, "huỷ lặp");
    context.expect(book.exchange_finish(second->order.id, Verdict::kDone, at(33)).error() == Error::kBadState,
        "đã huỷ mà báo xong: cần xử tay, không tự cộng");

    // Quá hạn: sang kStale, điểm vẫn giữ, vẫn chốt được.
    request.request = RequestId{4};
    request.ingot = Ingot{3};
    const Result<ExchangeOutcome> slow = book.exchange_begin(request, at(100));
    context.expect(slow.has_value(), "đơn chờ");
    context.expect(book.exchange_sweep(at(699)).value() == 0, "chưa tới hạn");
    context.expect(book.exchange_sweep(at(700)).value() == 1, "đúng hạn 600 giây");
    context.expect(book.exchange_sweep(at(701)).value() == 0, "không quét lại đơn đã stale");
    const Result<ExchangeOrder> found = book.find_exchange(slow->order.id);
    context.expect(found && found->status == ExchangeStatus::kStale, "trạng thái stale");
    const Result<std::vector<ExchangeOrder>> open = book.exchange_open(10);
    context.expect(open && open->size() == 1 && open->front().id == slow->order.id, "danh sách đối soát");
    const Balance after_stale = *book.balance(kA);
    context.expect(after_stale.held.value() == 10 && after_stale.available.value() == 556, "stale vẫn giữ điểm");
    context.expect(book.exchange_finish(slow->order.id, Verdict::kDone, at(800))->order.status == ExchangeStatus::kConfirmed,
        "chốt đơn stale");
    context.expect(book.exchange_open(10)->empty(), "hết đơn mở");

    // Đóng băng chặn đổi nhưng không chặn nạp.
    context.expect(book.set_frozen(kA, true, {.reason = "nghi gian lận", .actor = "gm_a"}, at(900)).has_value(), "đóng băng");
    request.request = RequestId{5};
    context.expect(book.exchange_begin(request, at(901)).error() == Error::kFrozen, "đóng băng chặn đổi");
    context.expect(book.apply_payment(paid("T2", kA, 50), at(902)).has_value(), "đóng băng không chặn nạp");
    context.expect(book.set_frozen(kA, false, {.reason = "đã rõ", .actor = "gm_a"}, at(903)).has_value(), "mở băng");
    context.expect(book.set_frozen(kA, true, {.reason = "", .actor = "gm_a"}, at(903)).error() == Error::kReasonRequired, "đóng băng cần lý do");
    context.expect(book.exchange_begin(request, at(904)).has_value(), "đổi lại được");

    // Hoàn tiền: bị chặn khi điểm đã tiêu, qua khi đã trả lại.
    const std::unique_ptr<Book> refund_owned = env.fresh();
    Book& refund_book = *refund_owned;
    context.expect(refund_book.apply_payment(paid("R1", kB, 500), at(0)).has_value(), "bước chuẩn bị");
    const ExchangeRequest spend{.account = kB, .character = CharacterId{80}, .request = RequestId{1}, .ingot = Ingot{100}};
    const Result<ExchangeOutcome> held = refund_book.exchange_begin(spend, at(1));
    context.expect(held && held->balance.value() == 500 - 334, "ceil(1000/3) = 334");
    const Result<PaymentOutcome> blocked = refund_book.refund_payment({.provider = "alpha", .trade_no = "R1"}, {.reason = "khách đòi", .actor = "gm"}, at(2));
    context.expect(!blocked && blocked.error() == Error::kInsufficient, "đã tiêu thì không hoàn được");
    context.expect(refund_book.find_payment({.provider = "alpha", .trade_no = "R1"})->event.status == PaymentStatus::kPaid, "đơn vẫn là paid");
    context.expect(refund_book.exchange_finish(held->order.id, Verdict::kCancelled, at(3)).has_value(), "bước chuẩn bị");
    const Result<PaymentOutcome> refunded = refund_book.refund_payment({.provider = "alpha", .trade_no = "R1"}, {.reason = "khách đòi", .actor = "gm"}, at(4));
    context.expect(refunded && refunded->balance.value() == 0 && refunded->record.event.status == PaymentStatus::kRefunded,
        "hoàn là dòng sổ âm");
    context.expect(refund_book.refund_payment({.provider = "alpha", .trade_no = "R1"}, {.reason = "lần nữa", .actor = "gm"}, at(5))->result == PaymentResult::kDuplicate,
        "hoàn lặp");
    context.expect(refund_book.refund_payment({.provider = "alpha", .trade_no = "nope"}, {.reason = "x", .actor = "gm"}, at(5)).error() == Error::kNotFound, "đơn lạ");
    context.expect(refund_book.refund_payment({.provider = "alpha", .trade_no = "R1"}, {.reason = "", .actor = "gm"}, at(5)).error() == Error::kReasonRequired, "thiếu lý do");
    const Result<std::vector<LedgerEntry>> tail = refund_book.ledger_tail(kB, 10);
    context.expect(tail && tail->size() == 4 && tail->front().kind == LedgerKind::kRefund && tail->front().delta.value() == -500,
        "sổ chỉ thêm, không xoá dòng cũ");
    context.expect(refund_book.ledger_check()->balanced, "sổ cân sau hoàn");
    context.expect(book.ledger_check()->balanced, "sổ cân");
}

[[nodiscard]] inline std::vector<std::string> mint_hashes(Counter& counter, int count) {
    std::vector<std::string> hashes;
    for (int index = 0; index < count; ++index) {
        const std::optional<std::string> code = mint_code({.fill = &fill_counter, .context = &counter});
        if (code) hashes.push_back(hash_code(*code));
    }
    return hashes;
}

inline void redeem_and_grants(Context& context, const Env& env) {
    const std::unique_ptr<Book> owned = env.fresh();
    Book& book = *owned;
    BatchSpec spec;
    spec.name = "Tặng tân thủ";
    spec.starts = at(100);
    spec.ends = at(1000);
    spec.per_account_limit = 1;
    spec.actor = "gm_a";
    spec.rewards = {Reward{.kind = 0, .ref_id = 0, .quantity = 50}, Reward{.kind = 5, .ref_id = 0, .quantity = 1000}, Reward{.kind = 100, .ref_id = 12345, .quantity = 2}};
    const Result<BatchRecord> batch = book.create_batch(spec, at(0));
    context.expect(batch.has_value(), "tạo đợt");
    if (!batch) return;
    context.expect(book.create_batch(spec, at(0)).error() == Error::kConflict, "tên đợt trùng");
    BatchSpec bad = spec;
    bad.name = "x";
    bad.rewards = {Reward{.kind = 0, .ref_id = 0, .quantity = 0}};
    context.expect(book.create_batch(bad, at(0)).error() == Error::kBadAmount, "phần thưởng 0");
    bad.rewards = {Reward{.kind = 7, .ref_id = 0, .quantity = 1}};
    context.expect(book.create_batch(bad, at(0)).error() == Error::kBadAmount, "loại quà lạ");
    bad.rewards = {Reward{.kind = 100, .ref_id = 0, .quantity = 1}};
    context.expect(book.create_batch(bad, at(0)).error() == Error::kBadAmount, "vật phẩm thiếu id mẫu");
    bad.rewards = {Reward{.kind = 5, .ref_id = 9, .quantity = 1}};
    context.expect(book.create_batch(bad, at(0)).error() == Error::kBadAmount, "tiền không có id mẫu");
    bad.rewards.clear();
    context.expect(book.create_batch(bad, at(0)).error() == Error::kTooMany, "không có phần thưởng");
    bad.rewards = {Reward{.kind = 0, .ref_id = 0, .quantity = 5}};
    bad.starts = at(500);
    bad.ends = at(100);
    context.expect(book.create_batch(bad, at(0)).error() == Error::kBadAmount, "đóng trước khi mở");
    bad.starts.reset();
    bad.ends.reset();
    bad.actor = "";
    context.expect(book.create_batch(bad, at(0)).error() == Error::kReasonRequired, "thiếu người tạo");

    Counter counter;
    const std::vector<std::string> hashes = mint_hashes(counter, 4);
    context.expect(book.add_codes(batch->id, hashes, at(0)).value() == 4, "thêm bốn mã");
    context.expect(book.add_codes(batch->id, hashes, at(0)).error() == Error::kConflict, "mã trùng băm");
    context.expect(book.add_codes(BatchId{99}, hashes, at(0)).error() == Error::kNotFound, "đợt lạ");
    const std::vector<std::string> junk{"xyz"};
    context.expect(book.add_codes(batch->id, junk, at(0)).error() == Error::kMalformed, "băm sai hình dạng");
    context.expect(book.add_codes(batch->id, std::vector<std::string>{}, at(0)).error() == Error::kTooMany, "không mã nào");

    const std::string ip = "10.1.2.3";
    context.expect(book.redeem(kA, hashes[0], ip, at(50)).error() == Error::kCodeNotYet, "chưa mở");
    const Result<RedeemOutcome> good = book.redeem(kA, hashes[0], ip, at(500));
    context.expect(good && good->points.value() == 50 && good->balance.value() == 50 && good->grants.size() == 2, "đổi mã");
    context.expect(book.redeem(kA, hashes[0], ip, at(501)).error() == Error::kCodeUsed, "mã đã dùng");
    context.expect(book.redeem(kA, hashes[1], ip, at(502)).error() == Error::kLimitReached, "đủ một mã mỗi đợt");
    context.expect(book.redeem(kB, hashes[0], ip, at(503)).error() == Error::kCodeUsed, "tài khoản khác cũng không dùng lại");
    context.expect(book.redeem(kB, hashes[1], ip, at(504)).has_value(), "tài khoản khác dùng mã khác");
    context.expect(book.redeem(kB, std::string(64, 'a'), ip, at(505)).error() == Error::kBadCode, "mã không tồn tại");
    context.expect(book.redeem(kB, "short", ip, at(505)).error() == Error::kMalformed, "băm sai độ dài");
    context.expect(book.redeem(kB, hashes[2], "999.1.1.1", at(505)).error() == Error::kMalformed, "ip sai");
    context.expect(book.set_batch_enabled(batch->id, false, "gm_a", at(600)).has_value(), "bước chuẩn bị");
    context.expect(book.redeem(AccountId{9}, hashes[2], ip, at(600)).error() == Error::kCodeDisabled, "đợt đã tắt");
    context.expect(book.set_batch_enabled(batch->id, true, "gm_a", at(601)).has_value(), "bước chuẩn bị");
    context.expect(book.set_frozen(AccountId{9}, true, {.reason = "x", .actor = "gm"}, at(602)).has_value(), "bước chuẩn bị");
    context.expect(book.redeem(AccountId{9}, hashes[2], ip, at(603)).error() == Error::kFrozen, "tài khoản đóng băng");
    context.expect(book.set_frozen(AccountId{9}, false, {.reason = "x", .actor = "gm"}, at(604)).has_value(), "bước chuẩn bị");
    context.expect(book.redeem(AccountId{9}, hashes[2], ip, at(1001)).error() == Error::kCodeExpired, "hết hạn");
    context.expect(book.redeem(AccountId{9}, hashes[2], ip, at(1000)).has_value(), "đúng mốc đóng");

    // Quà: claim hai pha.
    const Result<std::vector<GrantRecord>> listed = book.grant_list(kA, 10);
    context.expect(listed && listed->size() == 2, "hai quà chờ");
    const GrantRecord ingot_grant = listed->front().kind == GrantKind::kIngot ? listed->front() : listed->back();
    context.expect(ingot_grant.kind == GrantKind::kIngot && ingot_grant.quantity == 1000 && ingot_grant.source == "redeem",
        "quà ingot");
    const Result<GrantClaimed> claimed = book.grant_claim(ingot_grant.id, kA, CharacterId{70}, at(1100));
    context.expect(claimed && !claimed->replayed && claimed->grant.status == GrantStatus::kDelivering, "nhận quà");
    context.expect(book.grant_claim(ingot_grant.id, kA, CharacterId{70}, at(1101))->replayed, "nhận lặp cùng nhân vật");
    context.expect(book.grant_claim(ingot_grant.id, kA, CharacterId{71}, at(1101)).error() == Error::kBadState,
        "nhân vật khác không nhận khi đang giao");
    context.expect(book.grant_claim(ingot_grant.id, kB, CharacterId{80}, at(1101)).error() == Error::kNotFound,
        "quà của người khác không lộ");
    context.expect(book.grant_list(kA, 10)->size() == 1, "quà đang giao không còn trong danh sách chờ");
    context.expect(book.grant_open(10)->size() == 1, "đơn giao mở");
    const Result<GrantFinished> cancelled = book.grant_finish(claimed->order.id, Verdict::kCancelled, at(1200));
    context.expect(cancelled && cancelled->grant.status == GrantStatus::kPending, "giao hỏng thì quà quay lại hàng chờ");
    const Result<GrantClaimed> again = book.grant_claim(ingot_grant.id, kA, CharacterId{71}, at(1300));
    context.expect(again && !again->replayed && again->order.id != claimed->order.id, "nhận lại bằng đơn mới");
    const Result<GrantFinished> done = book.grant_finish(again->order.id, Verdict::kDone, at(1400));
    context.expect(done && done->grant.status == GrantStatus::kDelivered, "giao xong");
    context.expect(book.grant_finish(again->order.id, Verdict::kDone, at(1401))->replayed, "báo xong lặp");
    context.expect(book.grant_finish(again->order.id, Verdict::kCancelled, at(1402)).error() == Error::kBadState,
        "đã giao mà báo huỷ");
    context.expect(book.grant_finish(claimed->order.id, Verdict::kDone, at(1403)).error() == Error::kBadState,
        "đơn cũ đã huỷ mà báo xong");
    context.expect(book.grant_list(kA, 10)->size() == 1 && book.grant_open(10)->empty(), "còn một quà vật phẩm");

    GrantSpec manual{.account = kA, .kind = GrantKind::kBonusPoint, .ref_id = 0, .quantity = 300, .source = "prize",
        .reason = "giải đua top", .actor = "gm_b"};
    context.expect(book.grant_add(manual, at(1500)).has_value(), "thêm quà tay");
    manual.ref_id = 5;
    context.expect(book.grant_add(manual, at(1500)).error() == Error::kMalformed, "điểm tặng không có id mẫu");
    manual.ref_id = 0;
    manual.quantity = 0;
    context.expect(book.grant_add(manual, at(1500)).error() == Error::kBadAmount, "số lượng 0");
    manual.quantity = 1;
    manual.reason = "";
    context.expect(book.grant_add(manual, at(1500)).error() == Error::kReasonRequired, "thiếu lý do");
    context.expect(book.ledger_check()->balanced, "sổ cân sau mã đổi");
}

inline void admin_spend_audit(Context& context, const Env& env) {
    const std::unique_ptr<Book> owned = env.fresh();
    Book& book = *owned;
    context.expect(book.apply_payment(paid("T1", kA, 1000), at(0)).has_value(), "bước chuẩn bị");
    const Result<Points> adjusted = book.admin_adjust(kA, Points{300}, RequestId{1}, {.reason = "bù lỗi", .actor = "gm_a"}, at(1));
    context.expect(adjusted && adjusted->value() == 1300, "cộng tay");
    context.expect(book.admin_adjust(kA, Points{300}, RequestId{1}, {.reason = "bù lỗi", .actor = "gm_a"}, at(2))->value() == 1300,
        "gọi lại cùng request không cộng hai lần");
    context.expect(book.admin_adjust(kA, Points{301}, RequestId{1}, {.reason = "bù lỗi", .actor = "gm_a"}, at(2)).error() == Error::kConflict,
        "cùng request khác delta");
    context.expect(book.admin_adjust(kB, Points{300}, RequestId{1}, {.reason = "bù lỗi", .actor = "gm_a"}, at(2)).error() == Error::kConflict,
        "cùng request khác tài khoản");
    context.expect(book.admin_adjust(kA, Points{10}, RequestId{2}, {.reason = "", .actor = "gm_a"}, at(2)).error() == Error::kReasonRequired, "thiếu lý do");
    context.expect(book.admin_adjust(kA, Points{10}, RequestId{2}, {.reason = "ok", .actor = ""}, at(2)).error() == Error::kReasonRequired, "thiếu người làm");
    context.expect(book.admin_adjust(kA, Points{0}, RequestId{2}, {.reason = "ok", .actor = "gm"}, at(2)).error() == Error::kBadAmount, "delta 0");
    context.expect(book.admin_adjust(kA, Points{-1301}, RequestId{2}, {.reason = "ok", .actor = "gm"}, at(2)).error() == Error::kInsufficient,
        "trừ quá số dư");
    context.expect(book.admin_adjust(kA, Points{-1300}, RequestId{3}, {.reason = "thu hồi", .actor = "gm"}, at(3))->value() == 0, "trừ về 0");
    context.expect(book.admin_adjust(kA, Points{5}, RequestId{0}, {.reason = "ok", .actor = "gm"}, at(3)).error() == Error::kMalformed, "request 0");

    // Tiêu ingot: hạn mức 1000 mỗi nhân vật mỗi ngày UTC.
    const SpendEvent first{.event = 1, .account = kA, .character = CharacterId{70}, .amount = Ingot{300}};
    const SpendEvent second{.event = 2, .account = kA, .character = CharacterId{70}, .amount = Ingot{500}};
    const std::array<SpendEvent, 2> both{first, second};
    const Result<SpendSummary> recorded = book.record_spend(both, at(10));
    context.expect(recorded && recorded->recorded == 2 && recorded->duplicates == 0, "ghi hai lượt");
    context.expect(book.spend_headroom(CharacterId{70}, at(11))->value() == 200, "còn 200");
    const Result<SpendSummary> replay = book.record_spend(both, at(12));
    context.expect(replay && replay->recorded == 0 && replay->duplicates == 2, "báo lặp không ghi lại");
    SpendEvent altered = second;
    altered.amount = Ingot{501};
    const std::array<SpendEvent, 2> mixed{SpendEvent{.event = 3, .account = kA, .character = CharacterId{70}, .amount = Ingot{1}},
        altered};
    context.expect(book.record_spend(mixed, at(13)).error() == Error::kConflict, "cùng event khác nội dung");
    context.expect(book.spend_headroom(CharacterId{70}, at(14))->value() == 200, "lỗi không ghi nửa chừng");
    const std::array<SpendEvent, 1> over{SpendEvent{.event = 4, .account = kA, .character = CharacterId{70}, .amount = Ingot{900}}};
    context.expect(book.record_spend(over, at(15)).has_value(), "bước chuẩn bị");
    context.expect(book.spend_headroom(CharacterId{70}, at(16))->value() == 0, "vượt trần thì còn 0, không âm");
    context.expect(book.spend_headroom(CharacterId{70}, at(kSecondsPerDay + 5))->value() == 1000, "sang ngày UTC mới");
    context.expect(book.spend_headroom(CharacterId{71}, at(16))->value() == 1000, "nhân vật khác");
    const std::array<SpendEvent, 1> zero{SpendEvent{.event = 5, .account = kA, .character = CharacterId{70}, .amount = Ingot{0}}};
    context.expect(book.record_spend(zero, at(16)).error() == Error::kBadAmount, "tiêu 0");
    context.expect(book.record_spend(std::span<const SpendEvent>{}, at(16)).error() == Error::kTooMany, "không có sự kiện");

    // Bản nhớ đệm hỏng: phát hiện rồi dựng lại từ sổ.
    context.expect(book.ledger_check()->balanced, "sổ cân");
    env.corrupt(book, kA, Points{12345});
    const Result<Conservation> broken = book.ledger_check();
    context.expect(broken && !broken->balanced && broken->mismatched_accounts == 1, "phát hiện nhớ đệm lệch");
    context.expect(book.rebuild_balance(kA, "gm_a", at(20))->value() == 0, "dựng lại từ sổ");
    context.expect(book.ledger_check()->balanced, "sổ cân sau dựng lại");
    context.expect(book.rebuild_balance(kA, "", at(20)).error() == Error::kReasonRequired, "dựng lại cần người làm");

    const Result<DayReport> report = book.day_report(kT0 / kSecondsPerDay);
    context.expect(report && report->topped_up.value() == 1000 && report->ingot_spent.value() == 300 + 500 + 900 &&
            report->spend_events == 3,
        "báo cáo ngày");
    context.expect(book.day_report(-1).error() == Error::kBadAmount, "ngày âm");
}

// Dãy byte cụ thể (không qua literal để `\xC3b` không bị đọc thành một escape dài).
[[nodiscard]] inline std::string raw_bytes(std::initializer_list<unsigned char> bytes) {
    return std::string{bytes.begin(), bytes.end()};
}

// Chữ do người ngoài gửi (lý do, người làm): sổ lưu bản đã cắt khoảng trắng đầu cuối, và chỉ nhận UTF-8 đúng RFC 3629.
// Dãy hỏng phải bị từ chối ở cửa bằng kReasonRequired; để lọt thì PostgreSQL từ chối nó (lỗi 22021), bên gọi thấy kBusy
// và gọi lại mãi. Lý do dài đúng trần mà đệm khoảng trắng phải lưu bản đã cắt, vì cột reason giới hạn 200 byte.
inline void text_fields(Context& context, const Env& env) {
    const std::unique_ptr<Book> owned = env.fresh();
    Book& book = *owned;
    context.expect(book.apply_payment(paid("T1", kA, 1000), at(0)).has_value(), "bước chuẩn bị");
    context.expect(book.apply_payment(paid("T2", kB, 500), at(0)).has_value(), "bước chuẩn bị");

    const std::string longest(kReasonMost, 'a');
    const std::string padded_reason = "   " + longest + "     ";
    const std::string padded_actor = "  gm_a ";
    const Result<Points> adjusted =
        book.admin_adjust(kA, Points{5}, RequestId{1}, {.reason = padded_reason, .actor = padded_actor}, at(1));
    context.expect(adjusted && adjusted->value() == 1005, "lý do dài đúng trần cộng khoảng trắng đệm vẫn hợp lệ");
    const Result<std::vector<LedgerEntry>> tail = book.ledger_tail(kA, 1);
    context.expect(tail && tail->size() == 1 && tail->front().reason == longest && tail->front().actor == "gm_a",
        "sổ lưu lý do và người làm đã cắt khoảng trắng");
    const std::string too_long(kReasonMost + 1, 'a');
    context.expect(book.admin_adjust(kA, Points{5}, RequestId{2}, {.reason = too_long, .actor = "gm_a"}, at(2)).error() ==
            Error::kReasonRequired,
        "lý do dài hơn trần sau khi cắt");

    const Result<PaymentOutcome> refunded =
        book.refund_payment({.provider = "alpha", .trade_no = "T2"}, {.reason = "  khách đòi \t", .actor = " gm "}, at(3));
    context.expect(refunded.has_value(), "hoàn đơn với lý do có khoảng trắng đệm");
    const Result<std::vector<LedgerEntry>> refund_tail = book.ledger_tail(kB, 1);
    context.expect(refund_tail && refund_tail->size() == 1 && refund_tail->front().kind == LedgerKind::kRefund &&
            refund_tail->front().reason == "khách đòi" && refund_tail->front().actor == "gm",
        "dòng hoàn lưu bản đã cắt");

    // Tiếng Việt đủ dấu và ký tự ngoài mặt phẳng cơ bản đi qua nguyên vẹn.
    const std::string vietnamese = "Thiên Long Bát Bộ — thưởng đợt đầu \xF0\x9F\x8E\x81";
    context.expect(book.admin_adjust(kA, Points{1}, RequestId{3}, {.reason = vietnamese, .actor = "người làm"}, at(4)).has_value(),
        "UTF-8 đúng được nhận");
    const Result<std::vector<LedgerEntry>> kept = book.ledger_tail(kA, 1);
    context.expect(kept && kept->size() == 1 && kept->front().reason == vietnamese && kept->front().actor == "người làm",
        "UTF-8 đúng lưu nguyên vẹn");

    // Mỗi dãy dưới đây bị cấm vì một lý do khác nhau (tính tay theo RFC 3629): byte đầu bị cụt, byte không bao giờ xuất
    // hiện, dạng dài thừa của U+0000, nửa cặp thay thế U+D800, điểm mã U+110000, byte tiếp nối lạc chỗ, NUL.
    const std::array<std::string, 7> broken{raw_bytes({0xC3}), raw_bytes({0xFF}), raw_bytes({0xC0, 0x80}),
        raw_bytes({0xED, 0xA0, 0x80}), raw_bytes({0xF4, 0x90, 0x80, 0x80}), raw_bytes({0x80}),
        raw_bytes({'a', 0x00, 'b'})};
    for (const std::string& bad : broken) {
        context.expect(book.admin_adjust(kA, Points{1}, RequestId{9}, {.reason = bad, .actor = "gm"}, at(5)).error() ==
                Error::kReasonRequired,
            "lý do không phải UTF-8 đúng (chỉnh tay)");
        context.expect(book.admin_adjust(kA, Points{1}, RequestId{9}, {.reason = "ok", .actor = bad}, at(5)).error() ==
                Error::kReasonRequired,
            "người làm không phải UTF-8 đúng (chỉnh tay)");
        context.expect(book.set_frozen(kA, true, {.reason = bad, .actor = "gm"}, at(5)).error() == Error::kReasonRequired,
            "lý do hỏng (đóng băng)");
        context.expect(book.refund_payment({.provider = "alpha", .trade_no = "T1"}, {.reason = bad, .actor = "gm"}, at(5)).error() ==
                Error::kReasonRequired,
            "lý do hỏng (hoàn)");
        const GrantSpec spec{.account = kA, .kind = GrantKind::kBonusPoint, .ref_id = 0, .quantity = 3, .source = "prize",
            .reason = bad, .actor = "gm"};
        context.expect(book.grant_add(spec, at(5)).error() == Error::kReasonRequired, "lý do hỏng (quà tay)");
        context.expect(book.rebuild_balance(kA, bad, at(5)).error() == Error::kReasonRequired, "người làm hỏng (dựng lại)");
        context.expect(book.set_batch_enabled(BatchId{1}, false, bad, at(5)).error() == Error::kReasonRequired,
            "người làm hỏng (tắt đợt)");
    }
    context.expect(book.balance(kA)->available.value() == 1006 && !book.balance(kA)->frozen, "đầu vào hỏng không đổi sổ");
    context.expect(book.ledger_check()->balanced, "sổ cân");
}

} // namespace game::billing::scenario
