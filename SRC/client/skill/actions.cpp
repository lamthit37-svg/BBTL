// Hệ action của sách võ công (xem actions.hpp).
#include "skill/actions.hpp"

#include "skill/book.hpp"
#include "skill/tables.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::skill {
namespace {

// Lấy một id mới từ bộ đếm chung (0x14002468e): bộ đếm âm thì quay về 1.
// Khác gốc: sau INT32_MAX bộ đếm về 1 thẳng; mã gốc cộng tràn thành số âm rồi mới về 1.
[[nodiscard]] std::int32_t take_id(Actions& actions) noexcept {
    const std::int32_t id = actions.next_id < 0 ? 1 : actions.next_id;
    actions.next_id = id == std::numeric_limits<std::int32_t>::max() ? 1 : id + 1;
    return id;
}

[[nodiscard]] bool has_action(const Actions& actions, ActionKind kind, std::int32_t define) noexcept {
    const auto is_it = [kind, define](const Action& one) noexcept { return one.kind == kind && one.define == define; };
    return std::ranges::any_of(actions.all, is_it);
}

// Thêm action cho một mục chưa có action; id mới lớn hơn mọi id đang có nên danh sách vẫn xếp tăng,
// trừ khi bộ đếm đã quay vòng: khi đó chèn đúng chỗ.
void add_action(Actions& actions, ActionKind kind, std::int32_t define) {
    if (has_action(actions, kind, define)) return;
    const Action made{.id = take_id(actions), .kind = kind, .define = define};
    actions.all.insert(std::ranges::upper_bound(actions.all, made.id, {}, &Action::id), made);
}

// PosIndex của mục mà action trỏ tới (vtbl+0x60 của từng lớp action): -1 khi mục không còn, và với
// kỹ năng không cần học; action trận pháp trả id kỹ năng. Action thú cưng: mã gốc chưa đọc, script
// không liệt kê loại này; coi là -1.
[[nodiscard]] std::int32_t pos_index(const Action& action, const Book& book, const Tables& tables) noexcept {
    if (action.kind == ActionKind::kSkill) {
        const std::optional<SkillView> skill = find_skill(book, tables, action.define);
        return skill ? skill->pos_index : kNone;
    }
    if (action.kind == ActionKind::kInnerArt) {
        const OwnedInnerArt* art = find_inner_art(book, action.define);
        return art == nullptr ? kNone : art->pos_index;
    }
    if (action.kind == ActionKind::kLifeSkill) {
        const OwnedLifeSkill* life = find_life_skill(book, action.define);
        return life == nullptr ? kNone : life->pos_index;
    }
    const bool is_formation = action.kind == ActionKind::kFormation && skill_row(tables, action.define) != nullptr;
    return is_formation ? action.define : kNone;
}

// Mục mà action trỏ tới còn dữ liệu không (GetImpl() khác NULL).
[[nodiscard]] bool is_backed(const Action& action, const Book& book, const Tables& tables) noexcept {
    if (action.kind == ActionKind::kSkill) return find_skill(book, tables, action.define).has_value();
    if (action.kind == ActionKind::kInnerArt) return find_inner_art(book, action.define) != nullptr;
    if (action.kind == ActionKind::kLifeSkill) return find_life_skill(book, action.define) != nullptr;
    if (action.kind == ActionKind::kFormation) return skill_row(tables, action.define) != nullptr;
    return true;
}

} // namespace

void sync_skill_actions(Actions& actions, const Book& book, const Tables& tables) {
    const auto is_gone = [&book, &tables](const Action& one) noexcept {
        return one.kind == ActionKind::kSkill && !is_backed(one, book, tables);
    };
    std::erase_if(actions.all, is_gone);
    for (const OwnedSkill& skill : book.skills) add_action(actions, ActionKind::kSkill, skill.id);
}

void sync_inner_art_actions(Actions& actions, const Book& book) {
    const auto is_gone = [&book](const Action& one) noexcept {
        return one.kind == ActionKind::kInnerArt && find_inner_art(book, one.define) == nullptr;
    };
    std::erase_if(actions.all, is_gone);
    for (const OwnedInnerArt& art : book.inner_arts) add_action(actions, ActionKind::kInnerArt, art.id);
}

void sync_life_actions(Actions& actions, const Book& book) {
    const auto is_gone = [&book](const Action& one) noexcept {
        return one.kind == ActionKind::kLifeSkill && find_life_skill(book, one.define) == nullptr;
    };
    std::erase_if(actions.all, is_gone);
    for (const OwnedLifeSkill& life : book.life_skills) add_action(actions, ActionKind::kLifeSkill, life.id);
}

std::size_t action_count(const Actions& actions, ActionKind kind) noexcept {
    return static_cast<std::size_t>(std::ranges::count(actions.all, kind, &Action::kind));
}

const Action* enum_action(const Actions& actions, const Book& book, const Tables& tables, const ActionAsk& ask) noexcept {
    const auto is_it = [&book, &tables, &ask](const Action& one) noexcept {
        return one.kind == ask.kind && pos_index(one, book, tables) == ask.index;
    };
    const auto found = std::ranges::find_if(actions.all, is_it);
    return found == actions.all.end() ? nullptr : &*found;
}

const Action* action_by_id(const Actions& actions, std::int32_t id) noexcept {
    const auto found = std::ranges::find(actions.all, id, &Action::id);
    return found == actions.all.end() ? nullptr : &*found;
}

const Action* pet_action(const Actions& actions, PetAction which) noexcept {
    const auto is_it = [which](const Action& one) noexcept {
        return one.kind == ActionKind::kPet && std::cmp_equal(one.define, std::to_underlying(which));
    };
    const auto found = std::ranges::find_if(actions.all, is_it);
    return found == actions.all.end() ? nullptr : &*found;
}

std::int32_t define_id(const Action& action, const Book& book, const Tables& tables) noexcept {
    if (action.kind == ActionKind::kPet) return kNone;
    return is_backed(action, book, tables) ? action.define : kNone;
}

std::optional<std::int32_t> defined_by(const Actions& actions, const Book& book, const Tables& tables, std::int32_t action_id) noexcept {
    const Action* action = action_by_id(actions, action_id);
    if (action == nullptr) return std::nullopt;
    const std::int32_t define = define_id(*action, book, tables);
    if (define == kNone) return std::nullopt;
    return define;
}

std::int32_t owner_inner_art(const Actions& actions, const Book& book, const Tables& tables, const Action& action) noexcept {
    if (action.kind != ActionKind::kSkill) return kNotOwned;
    const std::optional<SkillView> skill = find_skill(book, tables, action.define);
    if (!skill || skill->row->user_class != 0) return kNotOwned;
    const std::int32_t art = skill->row->inner_art;
    const auto is_it = [art](const Action& one) noexcept { return one.kind == ActionKind::kInnerArt && one.define == art; };
    const auto found = std::ranges::find_if(actions.all, is_it);
    return found == actions.all.end() ? kNoOwnerArt : found->id;
}

std::string_view action_icon(const Action& action, const Tables& tables) noexcept {
    if (action.kind == ActionKind::kSkill || action.kind == ActionKind::kFormation) {
        const SkillRow* row = skill_row(tables, action.define);
        return row == nullptr ? std::string_view() : std::string_view(row->icon);
    }
    if (action.kind == ActionKind::kInnerArt) {
        const InnerArtRow* row = inner_art_row(tables, action.define);
        return row == nullptr ? std::string_view() : std::string_view(row->icon);
    }
    if (action.kind == ActionKind::kLifeSkill) {
        const LifeSkillRow* row = life_skill_row(tables, action.define);
        return row == nullptr ? std::string_view() : std::string_view(row->icon);
    }
    const bool is_listed = action.define >= 0 && std::cmp_less(action.define, kPetActions);
    return is_listed ? kPetFaces.at(static_cast<std::size_t>(action.define)).icon : std::string_view();
}

} // namespace game::skill
