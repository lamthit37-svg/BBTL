// Sách kỹ năng của người chơi (xem book.hpp). Mỗi hàm ghi giữ đúng thứ tự các phép xét của hàm
// tương ứng trong Game.exe 2026.
#include "skill/book.hpp"

#include "skill/tables.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::skill {
namespace {

// column_101 bằng 2: nhân vật nào cũng coi như đã học (0x140193e6e).
constexpr std::int32_t kAlwaysKnown = 2;
// Mười cấp tâm pháp là một bậc số liệu.
constexpr std::int64_t kTierSpan = 10;
// Độ thuần thục trong gói tin là giá trị hiển thị nhân 100.
constexpr std::int32_t kExpScale = 100;
// Kỹ năng và kỹ năng sống của nhân vật mới (DefaultChar.ini của máy chủ gốc).
constexpr std::array<std::int32_t, 6> kNewcomerSkills = {0, 1, 21, 22, 34, 35};
constexpr std::array<std::int32_t, 5> kNewcomerLifeSkills = {1, 26, 38, 50, 51};

// Chỗ của id trong một danh sách xếp theo id: mục mang id, hay chỗ chèn nó.
template <typename Owned>
[[nodiscard]] auto slot_of(std::vector<Owned>& list, std::int32_t id) noexcept {
    return std::ranges::lower_bound(list, id, {}, &Owned::id);
}

template <typename Owned>
[[nodiscard]] const Owned* owned(const std::vector<Owned>& list, std::int32_t id) noexcept {
    const auto found = std::ranges::lower_bound(list, id, {}, &Owned::id);
    if (found == list.end() || found->id != id) return nullptr;
    return &*found;
}

// PosIndex của mục sắp chèn: số mục đang có. Danh sách không dài hơn bảng nên vừa int32.
template <typename Owned>
[[nodiscard]] std::int32_t next_pos(const std::vector<Owned>& list) noexcept {
    return static_cast<std::int32_t>(list.size());
}

} // namespace

void set_inner_art(Book& book, const Tables& tables, const AtLevel& art) {
    const auto slot = slot_of(book.inner_arts, art.id);
    const bool is_known = slot != book.inner_arts.end() && slot->id == art.id;
    if (is_known) {
        slot->level = art.level;
        slot->is_learned = art.level > 0;
        return;
    }
    if (inner_art_row(tables, art.id) == nullptr) return;
    OwnedInnerArt made;
    made.id = art.id;
    made.pos_index = next_pos(book.inner_arts);
    made.level = art.level;
    made.is_learned = art.level > 0;
    book.inner_arts.insert(slot, made);
}

void set_skill(Book& book, const Tables& tables, std::int32_t sect, const SkillMark& mark) {
    const auto slot = slot_of(book.skills, mark.id);
    const bool is_known = slot != book.skills.end() && slot->id == mark.id;
    if (is_known) {
        slot->is_learned = mark.is_learned;
        return;
    }
    const SkillRow* row = skill_row(tables, mark.id);
    if (row == nullptr) return;
    if (row->inner_art != kNone && row->sect != sect) return;
    book.skills.insert(slot,
        OwnedSkill{.id = mark.id, .pos_index = next_pos(book.skills), .is_learned = mark.is_learned});
}

void replace_skills(Book& book, const Tables& tables, std::int32_t sect, std::span<const std::int32_t> ids) {
    book.skills.clear();
    for (const std::int32_t id : ids)
        set_skill(book, tables, sect, SkillMark{.id = id, .is_learned = true});
}

void set_life_skill(Book& book, const Tables& tables, const LifeMark& mark) {
    const std::int32_t exp = mark.exp > 0 ? mark.exp / kExpScale : mark.exp;
    const auto slot = slot_of(book.life_skills, mark.id);
    const bool is_known = slot != book.life_skills.end() && slot->id == mark.id;
    if (is_known) {
        if (mark.level >= 0) slot->level = mark.level;
        if (exp >= 0) slot->exp = exp;
        if (mark.mastery >= 0) slot->mastery = mark.mastery;
        return;
    }
    if (life_skill_row(tables, mark.id) == nullptr) return;
    OwnedLifeSkill made;
    made.id = mark.id;
    made.pos_index = next_pos(book.life_skills);
    made.level = mark.level;
    made.exp = std::max(exp, 0);
    made.mastery = std::max(mark.mastery, 0);
    book.life_skills.insert(slot, made);
}

Book newcomer_book(const Tables& tables) {
    Book book;
    replace_skills(book, tables, kNoSect, kNewcomerSkills);
    for (const std::int32_t id : kNewcomerLifeSkills) {
        set_life_skill(book, tables, LifeMark{.id = id, .level = 1, .exp = 0, .mastery = 0});
    }
    return book;
}

std::optional<SkillView> find_skill(const Book& book, const Tables& tables, std::int32_t id) noexcept {
    const SkillRow* row = skill_row(tables, id);
    if (row == nullptr) return std::nullopt;
    const bool is_free = row->must_learn <= 0 || row->column_101 == kAlwaysKnown;
    if (is_free) return SkillView{.row = row, .pos_index = kNone, .is_learned = true};
    const OwnedSkill* own = owned(book.skills, id);
    if (own == nullptr) return std::nullopt;
    return SkillView{.row = row, .pos_index = own->pos_index, .is_learned = own->is_learned};
}

const OwnedInnerArt* find_inner_art(const Book& book, std::int32_t id) noexcept {
    return owned(book.inner_arts, id);
}

const OwnedLifeSkill* find_life_skill(const Book& book, std::int32_t id) noexcept {
    return owned(book.life_skills, id);
}

std::string_view skill_data_text(const Book& book, const Tables& tables, const SkillRow& row) noexcept {
    const OwnedInnerArt* art = find_inner_art(book, row.inner_art);
    std::int64_t tier = 0;
    if (art != nullptr) tier = ((std::int64_t{art->level} + row.level_offset) / kTierSpan) % std::int64_t{kDataTiers};
    if (tier < 0) return row.explain;
    const LevelRow* level = level_row(tables, row.data.at(static_cast<std::size_t>(tier)));
    return level == nullptr ? std::string_view(row.explain) : std::string_view(level->description);
}

bool meets_requirement(const Book& book, const SkillRow& row) noexcept {
    const OwnedInnerArt* art = find_inner_art(book, row.inner_art);
    return art != nullptr && art->level >= row.inner_art_level;
}

} // namespace game::skill
