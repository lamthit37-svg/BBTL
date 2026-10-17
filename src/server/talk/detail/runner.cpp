// Bộ chạy khối hội thoại: duyệt các bước của khối bằng ngăn xếp tường minh (không đệ quy, độ sâu và số bước có trần) nên dữ
// liệu thù địch không làm tràn ngăn xếp hay chạy vô hạn. Điều kiện đọc trạng thái nhân vật TẠI LÚC bước chạy tới, nên nhánh
// sau một bước `effects` thấy kết quả của bước đó, giống script gốc.
#include "talk/detail/runner.hpp"

#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"
#include "talk/service.hpp"
#include "talk/view.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::talk::detail {
namespace {

constexpr std::size_t kMaxDepth = 32;

struct Frame {
    std::span<const Step> steps;
    std::size_t at = 0;
    bool call = false;  // `ret` dừng ở khung này
};

[[nodiscard]] std::unexpected<Failure> too_long() {
    Failure failure;
    failure.error = Error::kTooLong;
    return std::unexpected(std::move(failure));
}

[[nodiscard]] std::unexpected<Failure> refused(const mission::Failure& why) {
    Failure failure;
    failure.error = Error::kMission;
    failure.mission = why;
    return std::unexpected(std::move(failure));
}

[[nodiscard]] Mode mode_of(DispatchKind kind) noexcept {
    switch (kind) {
        case DispatchKind::kList: return Mode::kList;
        case DispatchKind::kBox: return Mode::kBox;
        case DispatchKind::kMissionInfo: return Mode::kMissionInfo;
        case DispatchKind::kContinue: return Mode::kContinue;
        case DispatchKind::kDemand: return Mode::kDemand;
        case DispatchKind::kTips: return Mode::kTips;
    }
    return Mode::kList;
}

[[nodiscard]] BonusKind bonus_of(BonusWord word) noexcept {
    switch (word) {
        case BonusWord::kMoney: return BonusKind::kMoney;
        case BonusWord::kItem: return BonusKind::kItem;
        case BonusWord::kRadio: return BonusKind::kRadio;
        case BonusWord::kRandom: return BonusKind::kRandom;
        case BonusWord::kDemand: return BonusKind::kDemand;
    }
    return BonusKind::kMoney;
}

class Runner {
public:
    Runner(const Env& env, std::uint32_t entry_script, Dialogue& dialogue, mission::Outcome& outcome)
        : env_(env), entry_script_(entry_script), dialogue_(dialogue), outcome_(outcome), facade_(env.hero, &env.engine.catalog()) {}

    [[nodiscard]] std::expected<void, Failure> run(std::uint32_t block) {
        stack_.push_back(Frame{.steps = env_.script.block(block), .at = 0, .call = true});
        while (!stack_.empty()) {
            Frame& top = stack_.back();
            if (top.at >= top.steps.size()) {
                stack_.pop_back();
                continue;
            }
            const Step& step = top.steps[top.at++];
            if (++budget_ > env_.max_steps) return too_long();
            if (auto done = execute(step); !done) return done;
        }
        return {};
    }

private:
    [[nodiscard]] bool holds(std::int32_t cond) const {
        ops::Context context;
        context.hero = &facade_;
        context.calendar = env_.calendar;
        context.target_name = env_.npc.name;
        return env_.engine.catalog().program().holds(cond, context);
    }

    // Mục dẫn tới nhiệm vụ không chạy được (ngoài danh bạ client 2026, hay bộ chạy chưa làm được)
    // không được mời: chọn nó chỉ ra kNoDialog. Script không phải nhiệm vụ thì luôn được mời.
    [[nodiscard]] bool offerable(std::uint32_t script) const {
        const mission::Quest* const quest = env_.engine.catalog().by_script(script);
        return quest == nullptr || quest->runnable();
    }

    // Vào một khối con. Khi khung hiện tại đã chạy hết (lời gọi/nhánh là bước cuối, như mọi chuỗi `if ... elseif` mà bộ trích dựng)
    // thì thay khung đó thay vì chồng thêm: khung hết bước chỉ còn chờ bị bỏ, giữ nó lại làm độ sâu tăng theo độ dài chuỗi nhánh
    // chứ không theo độ lồng thật. Khung mới thừa hưởng cờ `call` của khung bị thay để `ret` vẫn thoát đúng khối được gọi.
    [[nodiscard]] bool push(std::uint32_t block, bool call) {
        if (!stack_.empty() && stack_.back().at >= stack_.back().steps.size()) {
            Frame& done = stack_.back();
            done = Frame{.steps = env_.script.block(block), .at = 0, .call = done.call || call};
            return true;
        }
        if (stack_.size() >= kMaxDepth) return false;
        stack_.push_back(Frame{.steps = env_.script.block(block), .at = 0, .call = call});
        return true;
    }

    // `goto` là nhảy cuối (bộ trích luôn đặt nó ở cuối danh sách bước): thay khung hiện tại bằng khối đích thay vì chồng thêm khung,
    // vì một script có hàng chục câu if liên tiếp tạo hàng chục lần nhảy mà độ sâu thật không tăng. Khung đích thừa hưởng `call` để
    // `ret` trong khối đích vẫn thoát đúng khối được gọi.
    void jump(std::uint32_t block) {
        Frame& frame = stack_.back();
        frame = Frame{.steps = env_.script.block(block), .at = 0, .call = frame.call};
    }

    // `ret`: thoát khối `call` gần nhất; không có thì thoát cả điểm vào.
    void leave() {
        while (!stack_.empty()) {
            const bool call = stack_.back().call;
            stack_.pop_back();
            if (call) return;
        }
    }

    [[nodiscard]] std::expected<void, Failure> add_choice(const Step& step) {
        const auto script = static_cast<std::uint32_t>(std::max(step.a, 0));
        if (!offerable(script)) return {};
        const bool added = dialogue_.choice(script, step.b, step.c, step.text);
        if (!added) return too_long();
        return {};
    }

    [[nodiscard]] std::expected<void, Failure> execute(const Step& step) {
        switch (step.kind) {
            case StepKind::kBegin: dialogue_.begin(); return {};
            case StepKind::kText: return dialogue_.line(step.text) ? std::expected<void, Failure>{} : too_long();
            case StepKind::kOption: return add_choice(step);
            case StepKind::kBranch: {
                const bool taken = holds(step.cond);
                const std::int32_t chosen = taken ? step.a : step.b;
                if (chosen > 0 && !push(static_cast<std::uint32_t>(chosen), false)) return too_long();
                return {};
            }
            case StepKind::kGoto: jump(static_cast<std::uint32_t>(step.a)); return {};
            case StepKind::kCall: return push(static_cast<std::uint32_t>(step.a), true) ? std::expected<void, Failure>{} : too_long();
            case StepKind::kRet: leave(); return {};
            case StepKind::kDispatch: dialogue_.set_mode(mode_of(step.dispatch)); return {};
            case StepKind::kBonus:
                return dialogue_.bonus(Bonus{.kind = bonus_of(step.bonus), .a = step.a, .b = step.b, .c = step.c}) ? std::expected<void, Failure>{} : too_long();
            case StepKind::kEffects: return apply(step.a);
            case StepKind::kPick: return pick(step.a);
        }
        return {};
    }

    // kPick(n): n chữ liền sau; hiện đúng một chữ rồi nhảy qua cả n. Chạy khô lấy chữ đầu và không tốn ngẫu nhiên (chữ không phải
    // danh tính của lựa chọn), nên tính lại hộp thoại không làm lệch dòng ngẫu nhiên của cảnh.
    [[nodiscard]] std::expected<void, Failure> pick(std::int32_t count) {
        Frame& frame = stack_.back();
        const auto n = static_cast<std::size_t>(count);
        const std::size_t first = frame.at;
        const std::size_t chosen = env_.dry ? 0 : env_.engine.dice().below(n);
        frame.at = first + n;
        return dialogue_.line(frame.steps[first + chosen].text) ? std::expected<void, Failure>{} : too_long();
    }

    [[nodiscard]] std::expected<void, Failure> apply(std::int32_t effects) {
        if (env_.dry) return {};
        mission::Engine::EffectsRun run;
        run.target_name = env_.npc.name;
        run.source = entry_script_;
        auto result = env_.engine.run_effects(env_.hero, effects, run, env_.calendar);
        if (!result) return refused(result.error());
        merge(outcome_, std::move(*result));
        return {};
    }

    const Env& env_;
    std::uint32_t entry_script_;
    Dialogue& dialogue_;
    mission::Outcome& outcome_;
    mission::HeroFacade facade_;
    std::vector<Frame> stack_;
    std::size_t budget_ = 0;
};

}  // namespace

void merge(mission::Outcome& into, mission::Outcome from) {
    into.notices.insert(into.notices.end(), std::make_move_iterator(from.notices.begin()),
        std::make_move_iterator(from.notices.end()));
    into.directives.insert(into.directives.end(), std::make_move_iterator(from.directives.begin()),
        std::make_move_iterator(from.directives.end()));
    if (from.receipt.request != 0) into.receipt = from.receipt;
    if (from.quest >= 0) {
        into.quest = from.quest;
        into.script = from.script;
    }
}

std::expected<Ran, Failure> run_entry(const Env& env, std::uint32_t script, std::int32_t num, Dialogue& dialogue,
    mission::Outcome& outcome) {
    const auto handler = env.handlers.find({script, num});
    if (handler != env.handlers.end()) {
        HandlerContext context{.hero = env.hero, .npc = env.npc, .script = script, .num = num, .calendar = env.calendar,
            .engine = env.engine, .dialogue = dialogue, .outcome = outcome, .dry = env.dry};
        if (const std::optional<mission::Failure> why = handler->second->run(context)) return refused(*why);
        return Ran::kYes;
    }
    const Entry* const entry = env.script.entry(script, num);
    if (entry == nullptr || entry->status != EntryStatus::kOk) return Ran::kNoEntry;
    Runner runner(env, script, dialogue, outcome);
    if (auto done = runner.run(entry->block); !done) return std::unexpected(std::move(done.error()));
    return Ran::kYes;
}

}  // namespace game::talk::detail
