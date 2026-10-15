/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/talk_demo.cpp
 *  PHÂN HỆ   : Display / Graphic / TalkDemo
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Công cụ thử --talk-demo: NPC của --creature bấm được, và việc người chơi
 *    nhờ ở hộp thoại được đáp bằng kịch bản có sẵn thay cho máy chủ, để nhìn và
 *    thử cả vòng hộp thoại, nhận và nộp nhiệm vụ khi chưa có máy chủ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Công cụ thử của dự án, client gốc không có. Kịch bản đi đúng hình tin của giao thức v5 (DialogOpen, DialogClosed, QuestNotice,
// SelfStats) nên đường đi sau nó là đường thật; chỉ phần máy chủ là giả. Một NPC chỉ có một kịch bản: Talk mở danh sách lựa
// chọn, lựa chọn 1 mở bảng nhận nhiệm vụ, lựa chọn 2 mở bảng nộp, còn lại đóng hộp.
//
// Cách hỏng đã tính trước (CL-03): việc nhờ mang phiên không phải phiên đang mở (hộp đã đóng, phiên cũ) -> không đáp, như máy
// chủ trả Reject(StaleSession) mà client bỏ qua; kịch bản không giữ trạng thái nào ngoài số phiên.

#include "client/display/graphic/state.hpp"

#include "client/display/display.hpp"
#include "ui/panel/talk.hpp"

#include <cstdint>
#include <mutex>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace game::client {
namespace {

namespace tk = ui::panel::talk;

constexpr std::uint16_t kDemoQuest = 1201;
// Vật phẩm thật trong Table/items.tsv (白英, 蒲黄): bảng thưởng hiện tên, không hiện số mẫu.
constexpr std::int32_t kFirstReward = 20101001;
constexpr std::int32_t kSecondReward = 20101002;
constexpr std::int32_t kDemoMoney = 500;
constexpr std::uint64_t kDemoExp = 300;
constexpr std::uint16_t kAskOffer = 1;
constexpr std::uint16_t kAskTurnIn = 2;
constexpr std::uint16_t kSayGoodbye = 3;

// Hộp đang mở: phiên và NPC mà mọi tin đáp phải mang.
struct Seat {
    std::uint64_t session = 0;
    std::uint32_t npc = 0;
};

tk::Dialog greeting(Seat seat) {
    tk::Dialog dialog;
    dialog.session = seat.session;
    dialog.npc = seat.npc;
    dialog.mode = tk::Mode::kList;
    dialog.lines = {"#Y你好，旅行者。#W", "我这里有些事情需要人帮忙。"};
    dialog.choices = {tk::Choice{.index = kAskOffer, .icon = 8, .text = "我想接任务"},
        tk::Choice{.index = kAskTurnIn, .icon = 8, .text = "我来交任务"}, tk::Choice{.index = kSayGoodbye, .icon = 0, .text = "再见"}};
    return dialog;
}

tk::Dialog offer(Seat seat) {
    tk::Dialog dialog;
    dialog.session = seat.session;
    dialog.npc = seat.npc;
    dialog.mode = tk::Mode::kMissionInfo;
    dialog.panel_quest = kDemoQuest;
    dialog.lines = {"#R【新手任务】#W", "帮我杀三只野狼，回来给你奖励。"};
    dialog.bonuses = {tk::Bonus{.kind = tk::BonusKind::kMoney, .a = kDemoMoney, .b = 0, .c = 0},
        tk::Bonus{.kind = tk::BonusKind::kRadio, .a = kFirstReward, .b = 1, .c = 0},
        tk::Bonus{.kind = tk::BonusKind::kRadio, .a = kSecondReward, .b = 2, .c = 0}};
    return dialog;
}

tk::Dialog turn_in(Seat seat) {
    tk::Dialog dialog = offer(seat);
    dialog.mode = tk::Mode::kDemand;
    dialog.lines = {"#R【新手任务】#W", "做得不错！这是答应你的奖励。"};
    dialog.bonuses.push_back(tk::Bonus{.kind = tk::BonusKind::kDemand, .a = kFirstReward, .b = 3, .c = 0});
    return dialog;
}

tk::Notice notice(tk::NoticeKind kind, std::string text) {
    tk::Notice made;
    made.kind = kind;
    made.quest = kDemoQuest;
    made.text = std::move(text);
    return made;
}

// Kịch bản một tin việc người chơi nhờ; session và npc là của hộp đang mở.
struct Script {
    Seat seat;
    std::vector<tk::Hear>* out = nullptr;

    void close_done() const { out->emplace_back(tk::Closed{.session = seat.session, .reason = tk::Reason::kDone}); }

    void operator()(const tk::Talk& /*said*/) const { out->emplace_back(greeting(seat)); }
    void operator()(const tk::Choose& said) const {
        if (said.session != seat.session) return;
        if (said.index == kAskOffer) out->emplace_back(offer(seat));
        if (said.index == kAskTurnIn) out->emplace_back(turn_in(seat));
        if (said.index != kAskOffer && said.index != kAskTurnIn) close_done();
    }
    void operator()(const tk::Accept& said) const {
        if (said.session != seat.session) return;
        out->emplace_back(notice(tk::NoticeKind::kAdded, "你接受了任务：新手任务"));
        close_done();
    }
    void operator()(const tk::TurnIn& said) const {
        if (said.session != seat.session) return;
        tk::Notice exp = notice(tk::NoticeKind::kRewardExp, "");
        exp.value = static_cast<std::int64_t>(kDemoExp);
        tk::Notice money = notice(tk::NoticeKind::kRewardMoney, "");
        money.value = kDemoMoney;
        tk::Notice item = notice(tk::NoticeKind::kRewardItem, "");
        item.value = 1;
        item.ref = said.reward;
        out->emplace_back(std::move(exp));
        out->emplace_back(std::move(money));
        if (said.reward >= 0) out->emplace_back(std::move(item));
        out->emplace_back(tk::Stats{.level = 1, .exp = kDemoExp, .money = kDemoMoney, .bound_money = 0});
        out->emplace_back(notice(tk::NoticeKind::kDone, "#Y任务完成：新手任务#W"));
        close_done();
    }
    void operator()(const tk::Abandon& /*said*/) const {}
    void operator()(const tk::Close& /*said*/) const {}
    // Kịch bản hội thoại không có chiêu thức, hồi sinh hay nhặt đồ.
    void operator()(const tk::Cast& /*said*/) const {}
    void operator()(const tk::Revive& /*said*/) const {}
    void operator()(const tk::PickUp& /*said*/) const {}
};

} // namespace

void Display::State::answer_demo(const ui::panel::talk::Say& said) {
    if (const auto* talk = std::get_if<tk::Talk>(&said)) {
        ++demo_session;
        demo_npc = talk->npc;
    }
    std::vector<tk::Hear> replies;
    std::visit(Script{.seat = {.session = demo_session, .npc = demo_npc}, .out = &replies}, said);
    const std::scoped_lock<std::mutex> locked(talk_guard);
    for (tk::Hear& reply : replies) talk_heard.push_back(std::move(reply));
}

void Display::State::open_demo(std::uint32_t npc) {
    if (talk_demo == "click") return;
    answer_demo(tk::Talk{.npc = npc});
    if (talk_demo == "offer") answer_demo(tk::Choose{.session = demo_session, .index = kAskOffer});
    if (talk_demo == "turn") answer_demo(tk::Choose{.session = demo_session, .index = kAskTurnIn});
}

} // namespace game::client
