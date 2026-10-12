// Dữ liệu của màn tạo nhân vật (xem role_cast.hpp).
#include "ui/panel/role_cast.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::int32_t kLowest = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t kHighest = std::numeric_limits<std::int32_t>::max();
constexpr std::uint32_t kMaxShort = 65535;

// Dòng chọn được lúc tạo: mã máy viết ((choice - 1) & ~2) == 0, tức choice là 1 hay 3.
[[nodiscard]] constexpr bool is_creatable(std::int32_t choice) noexcept {
    return choice == 1 || choice == 3;
}

// Số phần tử của một dãy dưới dạng số mà script nhận; dãy dài quá miền thì chặn ở trần.
[[nodiscard]] std::int32_t count_of(std::size_t size) noexcept {
    return static_cast<std::int32_t>(std::min(size, static_cast<std::size_t>(kHighest)));
}

// id + kHighPolyStep khi ids (đã xếp tăng) có số đó; không thì chính id.
[[nodiscard]] std::int32_t high_poly_of(const std::vector<std::int32_t>* ids, std::int32_t id) noexcept {
    if (ids == nullptr || id < 0 || id > kHighest - kHighPolyStep) return id;
    const std::int32_t wanted = id + kHighPolyStep;
    return std::ranges::binary_search(*ids, wanted) ? wanted : id;
}

// Giới ghi ở cột race của một dòng (ô hỏng thì reader giữ lỗi).
[[nodiscard]] std::int32_t sex_of(table::RowReader& reader) {
    return reader.integer("race", kLowest, kHighest);
}

} // namespace

void RoleCast::take_portraits(const table::Tsv& table) {
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        table::RowReader reader(table, row);
        std::vector<Portrait>* own = portraits_.of(sex_of(reader));
        Portrait item;
        item.id = reader.integer("id", 0, kHighest);
        item.image = reader.text("image");
        item.choice = reader.integer("choice", kLowest, kHighest);
        item.order = reader.integer("order", kLowest, kHighest);
        if (reader.error()) ++skipped_;
        if (reader.error() || own == nullptr) continue;
        own->push_back(std::move(item));
    }
    // std::stable_sort của bộ quản gốc (0x14063f480), phép so là order của dòng trước nhỏ hơn.
    const auto settle = [](std::vector<Portrait>& own, std::int32_t& count) {
        std::ranges::stable_sort(own, std::less<>{}, &Portrait::order);
        const auto creatable = std::ranges::count_if(own, is_creatable, &Portrait::choice);
        count = count_of(static_cast<std::size_t>(creatable));
    };
    settle(portraits_.female, portrait_counts_.female);
    settle(portraits_.male, portrait_counts_.male);
}

void RoleCast::take_faces(const table::Tsv& table) {
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        table::RowReader reader(table, row);
        const std::int32_t sex = sex_of(reader);
        Model item;
        item.id = static_cast<std::int32_t>(reader.number("id", 0, kMaxShort));
        item.name = reader.text("name");
        item.choice = reader.integer("choice", kLowest, kHighest);
        if (reader.error()) ++skipped_;
        if (reader.error() || faces_.of(sex) == nullptr) continue;
        face_ids_.of(sex)->push_back(item.id);
        faces_.of(sex)->push_back(std::move(item));
    }
    std::ranges::sort(face_ids_.female);
    std::ranges::sort(face_ids_.male);
}

void RoleCast::take_hairs(const table::Tsv& table) {
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        table::RowReader reader(table, row);
        const std::int32_t sex = sex_of(reader);
        Model item;
        item.id = static_cast<std::int32_t>(reader.number("id", 0, kMaxShort));
        item.name = reader.text("name");
        item.choice = reader.integer("choice", kLowest, kHighest);
        if (reader.error()) ++skipped_;
        if (reader.error() || hairs_.of(sex) == nullptr) continue;
        hair_ids_.of(sex)->push_back(item.id);
        if (is_creatable(item.choice)) hairs_.of(sex)->push_back(std::move(item));
    }
    std::ranges::sort(hair_ids_.female);
    std::ranges::sort(hair_ids_.male);
}

void RoleCast::take_outfits(const table::Tsv& table) {
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        table::RowReader reader(table, row);
        NewbieOutfit item;
        item.id = reader.integer("id", 0, kHighest);
        item.name = reader.text("name");
        item.body = static_cast<std::uint16_t>(reader.number("body", 0, kMaxShort));
        item.foot = static_cast<std::uint16_t>(reader.number("foot", 0, kMaxShort));
        item.arm = static_cast<std::uint16_t>(reader.number("arm", 0, kMaxShort));
        if (reader.error()) ++skipped_;
        if (reader.error()) continue;
        outfits_.push_back(std::move(item));
    }
}

RoleCast RoleCast::from_tables(const CastTables& tables) {
    RoleCast cast;
    if (tables.portraits != nullptr) cast.take_portraits(*tables.portraits);
    if (tables.faces != nullptr) cast.take_faces(*tables.faces);
    if (tables.hairs != nullptr) cast.take_hairs(*tables.hairs);
    if (tables.outfits != nullptr) cast.take_outfits(*tables.outfits);
    return cast;
}

std::int32_t RoleCast::portrait_count(std::int32_t sex) const noexcept {
    const std::int32_t* count = portrait_counts_.of(sex);
    return count == nullptr ? 0 : *count;
}

std::string_view RoleCast::portrait_image(CastRow row) const noexcept {
    const Portrait* item = row_at(portraits_, row);
    if (item == nullptr || !is_creatable(item->choice)) return {};
    return item->image;
}

std::optional<std::int32_t> RoleCast::portrait_id(CastRow row) const noexcept {
    const Portrait* item = row_at(portraits_, row);
    if (item == nullptr || !is_creatable(item->choice)) return std::nullopt;
    return item->id;
}

std::int32_t RoleCast::face_count(std::int32_t sex) const noexcept {
    const std::vector<Model>* own = faces_.of(sex);
    return own == nullptr ? 0 : count_of(own->size());
}

std::int32_t RoleCast::face_choice(CastRow row) const noexcept {
    const Model* item = row_at(faces_, row);
    return item == nullptr ? -1 : item->choice;
}

std::string_view RoleCast::face_name(CastRow row) const noexcept {
    const Model* item = row_at(faces_, row);
    return item == nullptr ? std::string_view{} : std::string_view(item->name);
}

std::int32_t RoleCast::face_id(CastRow row) const noexcept {
    const Model* item = row_at(faces_, row);
    return item == nullptr ? 0 : item->id;
}

std::int32_t RoleCast::hair_count(std::int32_t sex) const noexcept {
    const std::vector<Model>* own = hairs_.of(sex);
    return own == nullptr ? 0 : count_of(own->size());
}

std::string_view RoleCast::hair_name(CastRow row) const noexcept {
    const Model* item = row_at(hairs_, row);
    return item == nullptr ? std::string_view{} : std::string_view(item->name);
}

std::int32_t RoleCast::hair_id(CastRow row) const noexcept {
    const Model* item = row_at(hairs_, row);
    return item == nullptr ? 0 : item->id;
}

std::int32_t RoleCast::outfit_count() const noexcept {
    return count_of(outfits_.size());
}

const NewbieOutfit* RoleCast::outfit(std::int32_t index) const noexcept {
    if (index < 0) return nullptr;
    const auto place = static_cast<std::size_t>(index);
    return place < outfits_.size() ? &outfits_[place] : nullptr;
}

std::string_view RoleCast::outfit_name(std::int32_t index) const noexcept {
    const NewbieOutfit* item = outfit(index);
    return item == nullptr ? std::string_view{} : std::string_view(item->name);
}

ModelLook RoleCast::model_look(ModelLook worn) const noexcept {
    ModelLook shown = worn;
    shown.face = high_poly_of(face_ids_.of(worn.sex), worn.face);
    shown.hair = high_poly_of(hair_ids_.of(worn.sex), worn.hair);
    return shown;
}

} // namespace game::ui::panel
