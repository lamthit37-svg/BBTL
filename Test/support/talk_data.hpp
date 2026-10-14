// Dựng chương trình hội thoại nhỏ cho test từ các dòng viết tay, dùng đúng bộ nạp và cột của talk_blocks / talk_entries. Kế thừa
// MissionData để dùng chung bảng điều kiện, hiệu ứng và nhiệm vụ.
#pragma once

#include "mission/catalog.hpp"
#include "support/mission_data.hpp"
#include "support/mission_fakes.hpp"
#include "talk/script.hpp"
#include "talk/service.hpp"

#include <cstdint>
#include <expected>
#include <map>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {

// NOLINTBEGIN(cppcoreguidelines-non-private-member-variables-in-classes): bộ dựng dữ liệu thử — các chuỗi TSV công khai để test thêm dòng hỏng thẳng vào bảng (HP-07)
class TalkData : public MissionData {
public:
    TalkData() {
        data_detail::row(entries_text_, "script", "num", "block", "status", "reason");
        data_detail::row(roles_text_, "script", "path", "events");
        data_detail::row(events_text_, "script", "seq", "event");
    }

    // Thêm một bước vào khối; seq tự tăng theo khối.
    TalkData& step(int block, std::string_view kind, int cond = -1, int a = 0, int b = 0, int c = 0, std::string_view text = "",
        std::string_view args = "") {
        std::string row;
        const int seq = counts_[block]++;
        data_detail::row(row, block, seq, kind, cond, a, b, c, text, args);
        rows_[block] += row;
        return *this;
    }

    TalkData& begin(int block) { return step(block, "begin"); }
    TalkData& text(int block, std::string_view key, std::string_view args = "") {
        return step(block, "text", -1, 0, 0, 0, key, args);
    }
    TalkData& option(int block, int script, int icon, int value, std::string_view key) {
        return step(block, "option", -1, script, icon, value, key);
    }
    TalkData& branch(int block, int cond, int then_block, int else_block = 0) { return step(block, "branch", cond, then_block, else_block); }
    TalkData& jump(int block, int target) { return step(block, "goto", -1, target); }
    TalkData& call(int block, int target) { return step(block, "call", -1, target); }
    TalkData& ret(int block) { return step(block, "ret"); }
    TalkData& dispatch(int block, std::string_view kind) { return step(block, "dispatch", -1, 0, 0, 0, kind); }
    TalkData& bonus(int block, std::string_view kind, int a, int b = 0, int c = 0) { return step(block, "bonus", -1, a, b, c, kind); }
    TalkData& effects(int block, int set) { return step(block, "effects", -1, set); }

    TalkData& entry(std::uint32_t script, int num, int block, std::string_view status = "ok", std::string_view reason = "") {
        data_detail::row(entries_text_, script, num, block, status, reason);
        return *this;
    }
    TalkData& npc_script(std::uint32_t script) {
        data_detail::row(roles_text_, script, "obj/test.lua", 0);
        return *this;
    }

    [[nodiscard]] std::string blocks_text() const {
        std::string out;
        data_detail::row(out, "block", "seq", "kind", "cond", "a", "b", "c", "text", "args");
        for (const auto& [block, rows] : rows_) out += rows;
        return out;
    }

    // Cả hai chương trình; catalog phải sống lâu hơn script vì Script không giữ ops::Program.
    [[nodiscard]] std::expected<talk::Script, talk::LoadFailure> build_script(const mission::Catalog& catalog) const {
        auto blocks = table::parse_tsv(blocks_text());
        auto entries = table::parse_tsv(entries_text_);
        auto roles = table::parse_tsv(roles_text_);
        auto events = table::parse_tsv(events_text_);
        if (!blocks || !entries || !roles || !events) {
            return std::unexpected(talk::LoadFailure{.error = talk::LoadError::kBadCell, .table = "parse", .detail = "bảng thử không đọc được"});
        }
        const talk::Tables tables{.blocks = *blocks, .entries = *entries, .roles = *roles, .events = *events};
        return talk::Script::load(catalog.program(), tables);
    }

    std::string entries_text_;
    std::string roles_text_;
    std::string events_text_;

private:
    std::map<int, std::string> rows_;
    std::map<int, int> counts_;
};
// NOLINTEND(cppcoreguidelines-non-private-member-variables-in-classes)

// Thế giới giả: một NPC đứng yên, nhân vật ở khoảng cách tuỳ ý.
class FakeTalkWorld final : public talk::World {
public:
    talk::Presence value{.hero_scene = 3, .npc_scene = 3, .distance = 2.0F};
    bool present = true;

    [[nodiscard]] std::optional<talk::Presence> presence(ids::CharacterId, const talk::NpcRef&) const override {
        if (!present) return std::nullopt;
        return value;
    }
};

}  // namespace game::test
