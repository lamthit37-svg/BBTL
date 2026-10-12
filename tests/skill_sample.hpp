// Bảng mẫu nhỏ cho test của sách võ công (module skill và các trang ui/panel): đủ cột mà bộ đọc
// hỏi, vài dòng mỗi bảng đi qua từng nhánh (kỹ năng không cần học, kỹ năng của môn phái có tâm pháp,
// dòng số liệu thiếu, bảng lên cấp thiếu). Dữ liệu tự đặt, không phải bảng thật.
#pragma once

#include "core/check.hpp"
#include "skill/tables.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {

[[nodiscard]] inline table::Tsv sample_table(std::string_view text) {
    table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng mẫu phải đọc được");
    return std::move(*table);
}

// Kết quả của một bộ đọc trên bảng mẫu; bộ đọc báo lỗi là test viết sai, dừng ngay.
template <typename Rows>
[[nodiscard]] Rows must(std::expected<Rows, std::string> rows) {
    core::check(rows.has_value(), "bảng mẫu phải qua bộ đọc");
    return std::move(*rows);
}

// Dòng tên cột của skills.tsv: các cột bộ đọc hỏi, data_0..data_30 ở cuối.
[[nodiscard]] inline std::string skills_head() {
    std::string head = "id\tsect\tname\ticon\tinner_art_level\tinner_art\tlevel_offset\tuser_class\tpassivity\t"
                       "must_learn\texplain\tcolumn_101";
    for (std::size_t tier = 0; tier < skill::kDataTiers; ++tier) head += std::format("\tdata_{}", tier);
    return head + "\n";
}

// Một kỹ năng mẫu; data_0..data_2 là id dòng số liệu của ba bậc đầu (bậc sau để -1).
struct SampleSkill {
    std::int32_t id = 0;
    std::int32_t sect = 9;
    std::int32_t inner_art = skill::kNone;
    std::int32_t inner_art_level = 0;
    std::int32_t level_offset = 0;
    std::int32_t user_class = 0;
    std::int32_t passivity = 0;
    std::int32_t must_learn = 1;
    std::int32_t column_101 = 0;
    std::int32_t data_0 = skill::kNone;
    std::int32_t data_1 = skill::kNone;
    std::int32_t data_2 = skill::kNone;
};

[[nodiscard]] inline std::string skill_line(const SampleSkill& one) {
    std::string line = std::format("{}\t{}\tKỹ năng {}\tIcon_{}\t{}\t{}\t{}\t{}\t{}\t{}\tMô tả {}\t{}", one.id, one.sect,
        one.id, one.id, one.inner_art_level, one.inner_art, one.level_offset, one.user_class, one.passivity,
        one.must_learn, one.id, one.column_101);
    line += std::format("\t{}\t{}\t{}", one.data_0, one.data_1, one.data_2);
    for (std::size_t tier = 3; tier < skill::kDataTiers; ++tier) line += "\t-1";
    return line + "\n";
}

// Dòng tên cột của inner_art_learn_costs.tsv.
[[nodiscard]] inline std::string costs_head() {
    std::string head = "id\tlevel";
    for (std::size_t art = 0; art < skill::kCostArts; ++art) head += std::format("\tmoney_{}\texp_{}", art, art);
    return head + "\n";
}

// Một dòng giá: tâm pháp k tốn level x 100 + k tiền và level x 1000 + k kinh nghiệm.
[[nodiscard]] inline std::string cost_line(std::int32_t id, std::int32_t level) {
    std::string line = std::format("{}\t{}", id, level);
    for (std::int32_t art = 0; std::cmp_less(art, skill::kCostArts); ++art) {
        line += std::format("\t{}\t{}", (level * 100) + art, (level * 1000) + art);
    }
    return line + "\n";
}

inline constexpr std::string_view kSampleLevels =
    "id\tdescription\n100\tSố liệu bậc 0\n101\tSố liệu bậc 1\n102\tSố liệu bậc 2\n200\tSố liệu khác\n";
inline constexpr std::string_view kSampleArts = "id\tsect\tname\texplain\ticon\tneed_level\n"
                                                "1\t0\tTâm pháp 1\tMô tả một, trần %d cấp\tArt_1\t10\n"
                                                "2\t0\tTâm pháp 2\tMô tả hai, trần %d\tArt_2\t20\n"
                                                "5\t1\tTâm pháp 5\tMô tả năm %d\tArt_5\t10\n";
inline constexpr std::string_view kSampleLifeSkills = "id\tname\tmax_level\tlevel_table\ticon\texplain\tpopup\tconsume\n"
                                                      "1\tNấu ăn\t10\tcook.txt\tLife_1\tMô tả nấu ăn\t1\t1\n"
                                                      "2\tChế thuốc\t10\tmissing.txt\tLife_2\tMô tả chế thuốc\t1\t1\n"
                                                      "3\tKhảm\t10\tcook.txt\tLife_3\tMô tả khảm\t2\t2\n"
                                                      "7\tĐào mỏ\t10\tcook.txt\tLife_7\tMô tả đào mỏ\t-1\t1\n"
                                                      "26\tĐang thao tác\t12\tcook.txt\tLife_26\tẩn\t-1\t1\n";
inline constexpr std::string_view kSampleLifeLevels = "table\tlevel\tname\tlimit_exp\n"
                                                      "cook.txt\t1\tcấp 1\t1500\n"
                                                      "cook.txt\t2\tcấp 2\t5850\n"
                                                      "cook.txt\t3\tcấp 3\t-150\n"
                                                      "other.txt\t1\tcấp 1\t99900\n";
inline constexpr std::string_view kSampleIcons =
    "icon\timageset\nArt_1\tArts\nArt_2\tArts\nArt_5\tArts\nLife_1\tLives\nLife_3\tLives\n"
    "PetSkill2_1\tPetSkill2\nPetSkill2_2\tPetSkill2\nFightSkillXinShou_11\tFightSkillXinShou\n"
    "FightSkillXinShou_12\tFightSkillXinShou\n";

// Các kỹ năng mẫu: 0 và 1 không tâm pháp, phải học; 2 không cần học (must_learn 0); 3 có column_101
// bằng 2; 10, 11, 12 thuộc tâm pháp 1 của môn phái 0 (12 là bị động); 20 thuộc tâm pháp 2 của môn
// phái 0, user_class 1; 30 thuộc tâm pháp 5 của môn phái 1.
[[nodiscard]] inline std::string sample_skills() {
    std::string text = skills_head();
    text += skill_line({.id = 0, .data_0 = 100});
    text += skill_line({.id = 1, .passivity = 1, .data_0 = 999});
    text += skill_line({.id = 2, .must_learn = 0});
    text += skill_line({.id = 3, .column_101 = 2});
    text += skill_line({.id = 10, .sect = 0, .inner_art = 1, .inner_art_level = 10, .data_0 = 100, .data_1 = 101,
        .data_2 = 102});
    text += skill_line({.id = 11, .sect = 0, .inner_art = 1, .inner_art_level = 30, .level_offset = -1, .data_0 = 100,
        .data_1 = 101, .data_2 = 102});
    text += skill_line({.id = 12, .sect = 0, .inner_art = 1, .passivity = 1, .data_0 = 200});
    text += skill_line({.id = 20, .sect = 0, .inner_art = 2, .user_class = 1, .data_0 = 200});
    text += skill_line({.id = 30, .sect = 1, .inner_art = 5, .data_0 = 200});
    return text;
}

// Bộ bảng mẫu. Tâm pháp: 1, 2 của môn phái 0; 5 của môn phái 1. Kỹ năng sống: 1 (nấu ăn, bảng
// cook.txt), 2 (chế thuốc, bảng lên cấp thiếu), 3 (khảm, popup 2), 7 (đào mỏ, không giao diện), 26
// (trang kỹ năng sống giấu). Dòng số liệu: 100, 101, 102 và 200; giá lên cấp có cấp 888, 1, 2, 21.
[[nodiscard]] inline skill::Tables sample_tables() {
    skill::Tables tables;
    tables.skills = must(skill::read_skills(sample_table(sample_skills())));
    tables.levels = must(skill::read_skill_levels(sample_table(kSampleLevels)));
    tables.inner_arts = must(skill::read_inner_arts(sample_table(kSampleArts)));
    const std::string costs = costs_head() + cost_line(1, 888) + cost_line(2, 1) + cost_line(3, 2) + cost_line(4, 21);
    tables.learn_costs = must(skill::read_learn_costs(sample_table(costs)));
    tables.life_skills = must(skill::read_life_skills(sample_table(kSampleLifeSkills)));
    tables.life_levels = must(skill::read_life_levels(sample_table(kSampleLifeLevels)));
    std::string icons(kSampleIcons);
    for (const std::int32_t id : {0, 1, 2, 3, 10, 11, 12, 20, 30}) icons += std::format("Icon_{}\tSkills\n", id);
    tables.icons = must(skill::read_icons(sample_table(icons)));
    return tables;
}

} // namespace game::test
