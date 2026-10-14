// Sinh thuộc tính ngẫu nhiên của trang bị: xem roll.hpp.
#include "item/roll.hpp"

#include "item/catalog.hpp"
#include "item/rows.hpp"
#include "item/instance.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::item {
namespace {

using tsv::Cells;
using tsv::Rows;
using Fail = std::unexpected<std::string>;

constexpr std::size_t kRuleEntries = 190;      // số cột dữ liệu của ItemSegQuality
constexpr std::size_t kForgeWholeColumn = 7;   // "rèn không nguyên liệu", cột gộp; cấp N dùng cột 8 + N
constexpr std::size_t kForgeSplitBase = 19;    // cột tách của "không nguyên liệu": 19 + điểm lắp
constexpr std::size_t kForgeLevelBase = 38;    // cột tách của nguyên liệu cấp 1: 38 + điểm lắp
constexpr std::size_t kForgeSplitSpan = 19;    // mỗi cấp nguyên liệu chiếm 19 cột (điểm lắp 0..18)
constexpr std::uint32_t kFamily = 1000;        // đoạn giá trị lùi trong cùng nghìn
constexpr std::int64_t kMaxValue = 1 << 28;    // trần giá trị thuộc tính trong bảng

// Cột ItemAptRate theo thứ tự id thuộc tính nền 58..63: tấn công vật lý, tấn công phép, phòng vật lý,
// phòng phép, trúng, né. Bảng khai: physical_attack, physical_defence, magic_attack, magic_defence, miss, hit.
constexpr std::array<std::size_t, kBaseAttrCount> kAptColumnOfBase{1, 3, 2, 4, 6, 5};

using SegmentMap = std::map<std::uint32_t, std::array<std::int32_t, 64>>;

// Một bảng đã đọc vào bộ nhớ: tên để báo lỗi và nội dung.
struct Source {
    std::string_view name;
    std::string_view text;
};

} // namespace

struct RollLoader {
    RollTables* out;

    [[nodiscard]] static std::optional<std::string> load_values(const Source& source, SegmentMap& into,
        bool overwrite) {
        const std::string_view table = source.name;
        Rows rows(source.text);
        if (rows.error()) return std::string(table) + ": " + *rows.error();
        if (rows.column_count() != RollTables::kValueColumns + 1) {
            return std::string(table) + ": cần " + std::to_string(RollTables::kValueColumns + 1) + " cột";
        }
        Cells cells(rows, table);
        while (rows.next()) {
            const auto id = static_cast<std::uint32_t>(cells.integer(0, {1, 1 << 20}));
            std::array<std::int32_t, RollTables::kValueColumns> values{};
            for (std::size_t i = 0; i < values.size(); ++i) {
                if (i >= kRollableAttrs) {
                    // Sáu cột cuối là "bảo lưu" (保留1..6): mã gốc không đọc, và bảng 0859602 có dòng 1120 dính
                    // dòng 1121 thành "-11121". Chỉ kiểm là số, không giữ giá trị.
                    static_cast<void>(cells.integer(i + 1, {-(1 << 30), 1 << 30}));
                    values.at(i) = -1;
                    continue;
                }
                values.at(i) = static_cast<std::int32_t>(cells.integer(i + 1, {-1, kMaxValue}));
            }
            if (cells.error()) return cells.error();
            if (overwrite) {
                into[id] = values;
            } else {
                into.try_emplace(id, values);
            }
        }
        if (rows.error()) return std::string(table) + ": " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_affects(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "item_segment_distributions: " + *rows.error();
        if (rows.column_count() != RollTables::kBuckets + 2) return "item_segment_distributions: cần 11 cột";
        Cells cells(rows, "item_segment_distributions");
        while (rows.next()) {
            const auto id = static_cast<std::uint32_t>(cells.integer(0, {1, 1 << 20}));
            std::array<std::uint32_t, RollTables::kBuckets> weights{};
            std::uint64_t sum = 0;
            for (std::size_t i = 0; i < weights.size(); ++i) {
                weights.at(i) = static_cast<std::uint32_t>(cells.integer(i + 2, {0, 1 << 24}));
                sum += weights.at(i);
            }
            if (cells.error()) return cells.error();
            if (sum == 0) return "item_segment_distributions: dòng " + std::to_string(id) + " không có trọng số";
            if (!out->affect_ids_.empty() && id <= out->affect_ids_.back()) {
                return "item_segment_distributions: id " + std::to_string(id) + " không tăng dần";
            }
            out->affect_ids_.push_back(id);
            out->affect_weights_.push_back(weights);
        }
        if (rows.error()) return "item_segment_distributions: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_rules(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "item_segment_quality_rules: " + *rows.error();
        if (rows.column_count() != kRuleEntries + 1) return "item_segment_quality_rules: cần 191 cột";
        Cells cells(rows, "item_segment_quality_rules");
        while (rows.next()) {
            const auto id = static_cast<std::uint32_t>(cells.integer(0, {1, 255}));
            std::vector<std::int32_t> entries(kRuleEntries);
            for (std::size_t i = 0; i < kRuleEntries; ++i) {
                const auto affect = static_cast<std::int32_t>(cells.integer(i + 1, {-1, 1 << 20}));
                entries.at(i) = affect;
                if (affect >= 0 && !std::ranges::binary_search(out->affect_ids_, static_cast<std::uint32_t>(affect))) {
                    return "item_segment_quality_rules:" + std::to_string(rows.line()) + ": dòng ItemSegAffect "
                        + std::to_string(affect) + " không có";
                }
            }
            if (cells.error()) return cells.error();
            if (!out->rule_ids_.empty() && id <= out->rule_ids_.back()) {
                return "item_segment_quality_rules: id " + std::to_string(id) + " không tăng dần";
            }
            out->rule_ids_.push_back(id);
            out->rule_columns_.push_back(std::move(entries));
        }
        if (rows.error()) return "item_segment_quality_rules: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_apt(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "item_aptitude_rates: " + *rows.error();
        if (rows.column_count() != kBaseAttrCount + 1) return "item_aptitude_rates: cần 7 cột";
        Cells cells(rows, "item_aptitude_rates");
        while (rows.next()) {
            const std::int64_t point = cells.integer(0, {1, 255});
            if (cells.error()) return cells.error();
            if (static_cast<std::size_t>(point) != out->apt_.size() + 1) {
                return "item_aptitude_rates: điểm tư chất phải liên tục từ 1, gặp " + std::to_string(point);
            }
            std::array<std::uint16_t, kBaseAttrCount> rates{};
            for (std::size_t i = 0; i < kBaseAttrCount; ++i) {
                rates.at(i) = static_cast<std::uint16_t>(cells.integer(kAptColumnOfBase.at(i), {0, 1000}));
            }
            if (cells.error()) return cells.error();
            out->apt_.push_back(rates);
        }
        if (rows.error()) return "item_aptitude_rates: " + *rows.error();
        return std::nullopt;
    }
};

std::expected<RollTables, std::string> RollTables::load(const RollSources& sources) {
    RollTables tables;
    const RollLoader loader{&tables};
    SegmentMap merged;
    // Thứ bậc nguồn của đề bài: client 2026 > XJL7457 > 0859602. Nạp client với ghi đè, hai bản sau chỉ bổ sung
    // đoạn còn thiếu theo đúng thứ tự đó.
    if (!sources.values_shared.empty()) {
        if (auto bad = RollLoader::load_values({.name = "item_segment_values(client)", .text = sources.values_shared}, merged, true)) {
            return Fail(*bad);
        }
    }
    if (!sources.values_xjl.empty()) {
        if (auto bad = RollLoader::load_values({.name = "item_segment_values(xjl)", .text = sources.values_xjl}, merged, false)) {
            return Fail(*bad);
        }
    }
    if (!sources.values_server.empty()) {
        if (auto bad = RollLoader::load_values({.name = "item_segment_values(server)", .text = sources.values_server}, merged, false)) {
            return Fail(*bad);
        }
    }
    if (merged.empty()) return Fail("item_segment_values: không có đoạn nào");
    for (const auto& [id, values] : merged) {
        tables.segment_ids_.push_back(id);
        tables.segment_values_.push_back(values);
    }
    if (auto bad = loader.load_affects(sources.affects)) return Fail(*bad);
    if (auto bad = loader.load_rules(sources.quality_rules)) return Fail(*bad);
    if (!sources.apt_rates.empty()) {
        if (auto bad = loader.load_apt(sources.apt_rates)) return Fail(*bad);
    }
    return tables;
}

std::optional<std::int32_t> RollTables::segment_value(std::uint32_t segment, AttrId attr) const noexcept {
    if (attr.value() >= kValueColumns) return std::nullopt;
    // Đoạn lớn nhất không vượt `segment`.
    auto it = std::ranges::upper_bound(segment_ids_, segment);
    if (it == segment_ids_.begin()) return std::nullopt;
    --it;
    if (*it / kFamily != segment / kFamily) return std::nullopt;
    const std::int32_t value = segment_values_[static_cast<std::size_t>(it - segment_ids_.begin())].at(attr.value());
    if (value < 0) return std::nullopt;
    return value;
}

std::uint32_t RollTables::aptitude_percent(std::uint32_t apt, AttrId base_attr) const noexcept {
    if (apt == 0 || apt > apt_.size() || base_attr.value() < kAttrBasePhysicalAttack
        || base_attr.value() >= kAttrCount) {
        return 0;
    }
    return apt_.at(apt - 1).at(static_cast<std::size_t>(base_attr.value() - kAttrBasePhysicalAttack));
}

std::optional<std::uint32_t> RollTables::affect_for(std::uint32_t rule, const RollContext& context,
    std::uint8_t point) const noexcept {
    const auto rule_it = std::ranges::lower_bound(rule_ids_, rule);
    if (rule_it == rule_ids_.end() || *rule_it != rule) return std::nullopt;
    const auto& columns = rule_columns_[static_cast<std::size_t>(rule_it - rule_ids_.begin())];
    const auto cell = [&columns](std::size_t column) noexcept -> std::int32_t {
        return column < columns.size() ? columns[column] : -1;
    };
    std::int32_t affect = -1;
    if (context.origin != Origin::kForge) {
        affect = cell(static_cast<std::size_t>(context.origin));
    } else {
        const std::size_t level = std::min<std::size_t>(context.forge_level, kMaxForgeLevel);
        // Cột gộp: 7 (không nguyên liệu) hay 8 + cấp; cột tách: 19 + điểm lắp, hay 38 + 19 * (cấp - 1) + điểm lắp.
        const std::size_t whole = level == 0 ? kForgeWholeColumn : kForgeWholeColumn + 1 + level;
        if (point <= kMaxAssemblyPoint) {
            const std::size_t split = (level == 0 ? kForgeSplitBase : kForgeLevelBase + kForgeSplitSpan * (level - 1)) + point;
            affect = cell(split);
        }
        if (affect < 0) affect = cell(whole);
    }
    if (affect < 0) return std::nullopt;
    return static_cast<std::uint32_t>(affect);
}

std::optional<std::array<std::uint32_t, 9>> RollTables::tier_weights(std::uint32_t affect) const noexcept {
    const auto it = std::ranges::lower_bound(affect_ids_, affect);
    if (it == affect_ids_.end() || *it != affect) return std::nullopt;
    return affect_weights_[static_cast<std::size_t>(it - affect_ids_.begin())];
}

std::uint32_t RollTables::pick_offset(std::optional<std::uint32_t> affect, dice::Dice& dice) const noexcept {
    if (!affect) return 0;
    const auto weights = tier_weights(*affect);
    if (!weights) return 0;
    return static_cast<std::uint32_t>(dice.pick_weighted(*weights).value_or(0));
}

void RollTables::roll(const Template& tmpl, const Catalog& catalog, const RollContext& context, dice::Dice& dice,
    Instance& out) const {
    const EquipSpec& spec = tmpl.equip;
    out.attr_count = 0;
    out.aptitude = 0;
    const std::span<const Weighted> pool = catalog.weights(tmpl);
    if (spec.seg_rule != 0 && spec.attr_max != 0 && spec.band_start >= 0 && !pool.empty()) {
        const std::optional<std::uint32_t> affect = affect_for(spec.seg_rule, context, spec.point);
        // Bản chép trọng số để loại dần thuộc tính đã chọn (không đụng danh mục dùng chung).
        std::array<std::uint32_t, kRollableAttrs> weight{};
        for (const Weighted& w : pool) weight.at(w.attr.value()) = w.weight;
        const auto wanted = static_cast<std::size_t>(dice.between(spec.attr_min, spec.attr_max));
        const std::size_t count = std::min({wanted, pool.size(), kMaxRolledAttrs});
        for (std::size_t slot = 0; slot < count; ++slot) {
            const std::optional<std::size_t> pick = dice.pick_weighted(weight);
            if (!pick) break;
            weight.at(*pick) = 0;
            const std::uint32_t offset = pick_offset(affect, dice);
            const auto segment = static_cast<std::uint32_t>(spec.band_start) + offset;
            const AttrId attr{static_cast<std::uint16_t>(*pick)};
            const std::optional<std::int32_t> value = segment_value(segment, attr);
            if (!value || *value == 0) continue;
            out.attrs.at(out.attr_count) = AttrValue{.id = attr, .value = *value};
            ++out.attr_count;
        }
    }
    if (spec.apt_max != 0) {
        out.aptitude = static_cast<std::uint8_t>(dice.between(std::max<std::int64_t>(spec.apt_min, 1), spec.apt_max));
        for (std::size_t i = 0; i < kBaseAttrCount; ++i) {
            const auto id = static_cast<std::uint16_t>(kAttrBasePhysicalAttack + i);
            const std::int64_t base = spec.base.at(i);
            const std::int64_t delta = base * aptitude_percent(out.aptitude, AttrId{id}) / 100;
            if (delta <= 0 || out.attr_count >= kMaxAttrs) continue;
            out.attrs.at(out.attr_count) = AttrValue{.id = AttrId{id}, .value = static_cast<std::int32_t>(delta)};
            ++out.attr_count;
        }
    }
}

} // namespace game::item
