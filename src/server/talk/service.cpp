/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/talk/service.cpp
 *  PHÂN HỆ   : Server / Talk / Service
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dịch vụ hội thoại: phiên do máy chủ giữ, tính lại hộp thoại trước khi chạy
 *    lựa chọn, dấu nhiệm vụ của NPC. Xem service.hpp cho hợp đồng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "talk/service.hpp"

#include "ids/ids.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "talk/detail/runner.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"
#include "talk/view.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::talk {
namespace {

[[nodiscard]] std::unexpected<Failure> fail(Error error, bool closed = false) {
    Failure failure;
    failure.error = error;
    failure.closed = closed;
    return std::unexpected(std::move(failure));
}

[[nodiscard]] std::unexpected<Failure> refused(const mission::Failure& why) {
    Failure failure;
    failure.error = Error::kMission;
    failure.mission = why;
    return std::unexpected(std::move(failure));
}

[[nodiscard]] bool panel_mode(Mode mode) noexcept {
    return mode == Mode::kMissionInfo || mode == Mode::kContinue || mode == Mode::kDemand || mode == Mode::kTips;
}

// Dấu nhiệm vụ của bảng tại NPC: nhận được ngay (!), đang làm (?), đủ điều kiện nộp (?). Mỗi id nhiệm vụ một dấu; nhiệm vụ nhiều
// biến thể (nhiệm vụ vòng) chỉ hiện một lần. Tăng theo id nhiệm vụ nên kết quả tất định.
void collect_marks(const mission::Engine& engine, mission::Character& hero, const NpcRef& npc, const ops::Calendar& calendar,
    Dialogue& dialogue) {
    const mission::Catalog& catalog = engine.catalog();
    std::map<std::int32_t, Stage> found;
    for (const mission::Offer& offer : catalog.offers_at(npc.guid, npc.scene, npc.name)) {
        const mission::Quest* const quest = catalog.by_script(offer.script);
        if (quest == nullptr || !quest->runnable()) continue;
        const mission::Slot* const slot = hero.book().find(quest->quest);
        if (offer.role == mission::NpcRole::kTurn) {
            if (slot == nullptr || std::cmp_not_equal(slot->script, quest->script)) continue;
            found[quest->quest] = engine.ready(hero, *quest, calendar) ? Stage::kReady : Stage::kInProgress;
        } else if (slot == nullptr && !found.contains(quest->quest) && !engine.can_accept(hero, quest->quest, calendar)) {
            found.emplace(quest->quest, Stage::kAvailable);
        }
    }
    for (const auto& [quest, stage] : found) {
        if (!dialogue.mark(Mark{.quest = quest, .stage = stage})) break;
    }
}

}  // namespace

std::string_view describe(Error error) noexcept {
    switch (error) {
        case Error::kNoNpc: return "NPC hoặc nhân vật không còn";
        case Error::kFar: return "quá xa NPC";
        case Error::kSceneChanged: return "đã sang cảnh khác";
        case Error::kNoSession: return "không có phiên hội thoại";
        case Error::kStale: return "mã phiên đã cũ";
        case Error::kExpired: return "phiên quá hạn";
        case Error::kBadOption: return "lựa chọn ngoài hộp thoại";
        case Error::kOptionGone: return "lựa chọn đã đổi";
        case Error::kNoDialog: return "không có hội thoại";
        case Error::kNotOffered: return "nhiệm vụ không được mời trong hộp thoại này";
        case Error::kMission: return "nhiệm vụ hay sổ cái từ chối";
        case Error::kTooLong: return "hội thoại vượt trần bước";
        case Error::kTooMany: return "quá nhiều phiên";
    }
    return "lỗi không rõ";
}

Service::Service(const Script& script, mission::Engine& engine, std::span<const HandlerSpec> handlers, const Options& options)
    : script_(script), engine_(engine), options_(options) {
    for (const HandlerSpec& spec : handlers) {
        if (spec.run != nullptr) handlers_.emplace(std::make_pair(spec.script, spec.num), &spec);
    }
}

std::optional<SessionId> Service::session_of(ids::CharacterId hero) const noexcept {
    const auto found = sessions_.find(hero);
    if (found == sessions_.end()) return std::nullopt;
    return found->second.id;
}

void Service::erase(ids::CharacterId hero) noexcept { sessions_.erase(hero); }

void Service::close(ids::CharacterId hero) noexcept { erase(hero); }

std::size_t Service::sweep(ids::Tick now) {
    return std::erase_if(sessions_, [now](const auto& entry) { return now >= entry.second.expires; });
}

std::expected<Service::Session*, Failure> Service::validate(mission::Character& hero, SessionId session, const World& world,
    ids::Tick now) {
    const auto found = sessions_.find(hero.id());
    if (found == sessions_.end()) return fail(Error::kNoSession);
    Session& open = found->second;
    // Mã lạ không đóng phiên thật: kẻ gửi mã bậy không được phá hộp thoại đang mở của chính nhân vật đó (hay của ai khác).
    if (session.value() == 0 || open.id != session) return fail(Error::kStale);
    if (now >= open.expires) {
        erase(hero.id());
        return fail(Error::kExpired, true);
    }
    const std::optional<Presence> here = world.presence(hero.id(), open.npc);
    if (!here) {
        erase(hero.id());
        return fail(Error::kNoNpc, true);
    }
    if (here->hero_scene != here->npc_scene || here->npc_scene != open.npc.scene) {
        erase(hero.id());
        return fail(Error::kSceneChanged, true);
    }
    if (!(here->distance <= options_.range)) {  // dạng phủ định để NaN cũng bị coi là xa
        erase(hero.id());
        return fail(Error::kFar, true);
    }
    open.expires = ids::advance(now, options_.idle);  // mọi ý định hợp lệ của phiên đang sống đều gia hạn nó
    return &open;
}

std::expected<Service::Built, Failure> Service::run(mission::Character& hero, const NpcRef& npc, std::uint32_t script,
    std::int32_t num, bool root, bool dry, const ops::Calendar& calendar) {
    Dialogue dialogue;
    mission::Outcome outcome;
    const detail::HandlerMap& handlers = handlers_;
    const detail::Env env{.script = script_, .handlers = handlers, .engine = engine_, .hero = hero, .npc = npc,
        .calendar = calendar, .dry = dry, .max_steps = options_.max_steps};
    bool ran = false;
    if (script != 0 || num != -1) {
        const auto result = detail::run_entry(env, script, num, dialogue, outcome);
        if (!result) return std::unexpected(result.error());
        ran = *result == detail::Ran::kYes;
    }
    if (!ran && !root) return fail(Error::kNoDialog);
    if (root) collect_marks(engine_, hero, npc, calendar, dialogue);
    // Bảng nhiệm vụ của script nhiệm vụ: hộp thoại này nói về nhiệm vụ nào (để client biết nhận/nộp cái nào).
    if (ran && panel_mode(dialogue.view().mode)) {
        if (const mission::Quest* const quest = engine_.catalog().by_script(script)) {
            // Nhiệm vụ chưa chạy được (không có trong danh bạ client, chưa hỗ trợ): không mời, vì nút Nhận sẽ chỉ báo lỗi.
            if (!quest->runnable()) return fail(Error::kNoDialog);
            dialogue.set_panel(quest->quest);
        }
    }
    Built built;
    built.options = dialogue.options();
    built.view = dialogue.take_view();
    built.outcome = std::move(outcome);
    return built;
}

Result Service::commit_open(mission::Character& hero, Session session, Built built, ids::Tick now) {
    session.id = SessionId{next_id_++};
    session.expires = ids::advance(now, options_.idle);
    session.options = std::move(built.options);
    session.marks = built.view.marks;
    session.panel_quest = built.view.panel_quest;
    session.mode = built.view.mode;
    Reply reply;
    reply.session = session.id;
    reply.view = std::move(built.view);
    reply.outcome = std::move(built.outcome);
    sessions_.insert_or_assign(hero.id(), std::move(session));
    return reply;
}

Result Service::talk(mission::Character& hero, const NpcRef& npc, const World& world, ids::Tick now,
    const ops::Calendar& calendar) {
    const std::optional<Presence> here = world.presence(hero.id(), npc);
    if (!here) return fail(Error::kNoNpc);
    if (here->hero_scene != here->npc_scene || here->npc_scene != npc.scene) return fail(Error::kSceneChanged);
    if (!(here->distance <= options_.range)) return fail(Error::kFar);
    if (!sessions_.contains(hero.id()) && sessions_.size() >= options_.max_sessions) return fail(Error::kTooMany);
    auto built = run(hero, npc, npc.script, -1, true, false, calendar);
    if (!built) return std::unexpected(std::move(built.error()));
    if (built->view.empty()) return fail(Error::kNoDialog);
    Session session;
    session.npc = npc;
    session.script = npc.script;
    session.num = -1;
    session.root = true;
    return commit_open(hero, std::move(session), std::move(*built), now);
}

Result Service::choose(mission::Character& hero, SessionId session, std::uint32_t index, const World& world, ids::Tick now,
    const ops::Calendar& calendar) {
    const auto checked = validate(hero, session, world, now);
    if (!checked) return std::unexpected(checked.error());
    Session& open = **checked;
    if (index >= open.options.size()) return fail(Error::kBadOption);
    const Option wanted = open.options[index];
    // Tính lại hộp thoại hiện tại ở trạng thái bây giờ (chạy khô); chỉ chạy lựa chọn nếu nó vẫn còn nguyên.
    auto fresh = run(hero, open.npc, open.script, open.num, open.root, true, calendar);
    if (!fresh) return std::unexpected(std::move(fresh.error()));
    if (index >= fresh->options.size() || fresh->options[index] != wanted) {
        open.options = fresh->options;
        open.marks = fresh->view.marks;
        open.panel_quest = fresh->view.panel_quest;
        open.mode = fresh->view.mode;
        Failure failure;
        failure.error = Error::kOptionGone;
        failure.view = std::move(fresh->view);
        return std::unexpected(std::move(failure));
    }
    auto built = run(hero, open.npc, wanted.script, wanted.value, false, false, calendar);
    if (!built) return std::unexpected(std::move(built.error()));
    open.script = wanted.script;
    open.num = wanted.value;
    open.root = false;
    open.options = std::move(built->options);
    open.marks = built->view.marks;
    open.panel_quest = built->view.panel_quest;
    open.mode = built->view.mode;
    Reply reply;
    reply.session = open.id;
    reply.view = std::move(built->view);
    reply.outcome = std::move(built->outcome);
    return reply;
}

Result Service::finish_intent(mission::Character& hero, Session& open, mission::Outcome outcome,
    const ops::Calendar& calendar) {
    Reply reply;
    // Nhiệm vụ nộp xong mở tiếp nhiệm vụ kế (offer_next): hộp thoại chuyển sang lời mời đó trong cùng phiên.
    const mission::Catalog& catalog = engine_.catalog();
    const mission::Quest* next = nullptr;
    for (const mission::Directive& directive : outcome.directives) {
        if (directive.op != ops::EffectOp::kOfferNext) continue;
        if (directive.arg[1] > 0) next = catalog.by_script(static_cast<std::uint32_t>(directive.arg[1]));
        if (next == nullptr && directive.arg[0] >= 0) {
            const std::vector<const mission::Quest*> variants = catalog.variants(directive.arg[0]);
            if (!variants.empty()) next = variants.front();
        }
        break;
    }
    if (next != nullptr && next->runnable() && !engine_.can_accept(hero, next->quest, calendar)) {
        open.script = 0;
        open.num = -1;
        open.root = false;
        open.options.clear();
        open.marks = {Mark{.quest = next->quest, .stage = Stage::kAvailable}};
        open.panel_quest = next->quest;
        open.mode = Mode::kMissionInfo;
        reply.session = open.id;
        reply.view.mode = Mode::kMissionInfo;
        reply.view.marks = open.marks;
        reply.view.panel_quest = next->quest;
    } else {
        reply.closed = true;
        erase(hero.id());
    }
    reply.outcome = std::move(outcome);
    return reply;
}

Result Service::accept(mission::Character& hero, SessionId session, std::int32_t quest, const World& world, ids::Tick now,
    const ops::Calendar& calendar) {
    const auto checked = validate(hero, session, world, now);
    if (!checked) return std::unexpected(checked.error());
    Session& open = **checked;
    const bool offered = std::ranges::any_of(open.marks, [quest](const Mark& one) {
        return one.quest == quest && one.stage == Stage::kAvailable;
    }) || (open.panel_quest == quest && open.mode == Mode::kMissionInfo);
    if (!offered) return fail(Error::kNotOffered);
    auto done = engine_.accept(hero, quest, calendar);
    if (!done) return refused(done.error());
    return finish_intent(hero, open, std::move(*done), calendar);
}

Result Service::turn_in(mission::Character& hero, SessionId session, std::int32_t quest, std::int32_t choice, const World& world,
    ids::Tick now, const ops::Calendar& calendar) {
    const auto checked = validate(hero, session, world, now);
    if (!checked) return std::unexpected(checked.error());
    Session& open = **checked;
    const bool offered = std::ranges::any_of(open.marks, [quest](const Mark& one) {
        return one.quest == quest && one.stage != Stage::kAvailable;
    }) || (open.panel_quest == quest && open.mode != Mode::kTips);
    if (!offered) return fail(Error::kNotOffered);
    auto done = engine_.turn_in(hero, quest, choice, calendar);
    if (!done) return refused(done.error());
    return finish_intent(hero, open, std::move(*done), calendar);
}

mission::Result Service::abandon(mission::Character& hero, std::int32_t quest, const ops::Calendar& calendar) {
    return engine_.abandon(hero, quest, calendar);
}

}  // namespace game::talk
