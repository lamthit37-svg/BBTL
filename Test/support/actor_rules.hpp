// Luật thân thể THẬT cho test: nạp bảng từ GAME_SERVER_TABLES (dev/server/tables) một lần cho cả tiến trình test.
// Dùng chung cho actor_tests và combat_tests để hai nơi đọc đúng một bộ bảng.
#pragma once

#include "actor/rules.hpp"
#include "actor/sheet.hpp"
#include "support/keep_forever.hpp"
#include "test.hpp"

#include <array>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <optional>
#include <string>
#include <utility>

#ifndef GAME_SERVER_TABLES
#error "GAME_SERVER_TABLES phải trỏ tới dev/server/tables"
#endif

namespace game::test {

// Đọc nguyên một bảng theo đường dẫn tương đối từ GAME_SERVER_TABLES; nullopt khi không mở được.
[[nodiscard]] inline std::optional<std::string> slurp_table(const std::string& relative) {
    std::ifstream file(std::string(GAME_SERVER_TABLES) + "/" + relative, std::ios::binary);
    if (!file) return std::nullopt;
    return std::string(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>());
}

// Chín bảng của actor::RulesText.
struct RuleTables {
    std::string base, growth, templates, rage, exp, gap, penalties, monsters, inner;

    [[nodiscard]] actor::RulesText text() const {
        return actor::RulesText{.sect_base_values = base, .sect_growth = growth, .sect_templates = templates,
            .sect_rage_rules = rage, .player_exp_levels = exp, .exp_level_gap = gap, .death_penalties = penalties,
            .monsters = monsters, .inner_arts = inner};
    }
};

[[nodiscard]] inline std::optional<RuleTables> load_rule_tables() {
    RuleTables loaded;
    const std::array<std::pair<std::string*, const char*>, 9> files{{
        {&loaded.base, "server/sect_base_values.tsv"},
        {&loaded.growth, "server/sect_attribute_growth.tsv"},
        {&loaded.templates, "server/sect_templates.tsv"},
        {&loaded.rage, "server/sect_rage_rules.tsv"},
        {&loaded.exp, "shared/player_exp_levels.tsv"},
        {&loaded.gap, "server/exp_level_gap_factors.tsv"},
        {&loaded.penalties, "server/death_penalties.tsv"},
        {&loaded.monsters, "shared/monsters.tsv"},
        {&loaded.inner, "shared/inner_arts.tsv"},
    }};
    for (const auto& [target, name] : files) {
        std::optional<std::string> text = slurp_table(name);
        if (!text) return std::nullopt;
        *target = std::move(*text);
    }
    return loaded;
}

// Chín bảng luật thật; nullptr khi không đọc được tệp.
[[nodiscard]] inline const RuleTables* rule_tables() {
    static const RuleTables* const kTables = keep_forever(load_rule_tables());
    return kTables;
}

[[nodiscard]] inline std::optional<actor::Rules> load_real_rules() {
    const RuleTables* loaded = rule_tables();
    if (loaded == nullptr) return std::nullopt;
    actor::Loaded<actor::Rules> result = actor::load_rules(loaded->text());
    if (!result) {
        static_cast<void>(std::fprintf(stderr, "lỗi nạp bảng: %s\n", result.error().what.c_str()));
        return std::nullopt;
    }
    return std::move(*result);
}

// Luật đã nạp từ bảng thật; ghi một kỳ vọng sai vào `context` khi không nạp được (rồi trả nullptr).
[[nodiscard]] inline const actor::Rules* real_rules(Context& context) {
    static const actor::Rules* const kRules = keep_forever(load_real_rules());
    context.expect(kRules != nullptr, "nạp được bảng luật thật từ GAME_SERVER_TABLES");
    return kRules;
}

} // namespace game::test
