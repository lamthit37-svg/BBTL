#pragma once
// Nội bộ talk: bộ chạy khối hội thoại. Module khác không include tệp này.

#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"
#include "talk/service.hpp"
#include "talk/view.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <utility>

namespace game::talk::detail {

using HandlerMap = std::map<std::pair<std::uint32_t, std::int32_t>, const HandlerSpec*>;

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): môi trường của một lần chạy hội thoại: mọi tham chiếu sống lâu hơn nó, không sở hữu, không giữ qua tick (SH-04)
struct Env {
    const Script& script;
    const HandlerMap& handlers;
    mission::Engine& engine;
    mission::Character& hero;
    const NpcRef& npc;
    const ops::Calendar& calendar;
    bool dry = false;           // chỉ tính lại hộp thoại: bỏ qua mọi bước đổi trạng thái
    std::size_t max_steps = 0;  // trần bước của một lần chạy
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

enum class Ran : std::uint8_t {
    kYes,
    kNoEntry,  // không có handler, không có điểm vào, hoặc điểm vào không có hội thoại / chưa trích được
};

// Chạy điểm vào (script, num) để dựng `dialogue`, gộp thông báo và chỉ thị vào `outcome`. Handler viết tay được ưu tiên hơn
// điểm vào trích tĩnh cùng khoá.
[[nodiscard]] std::expected<Ran, Failure> run_entry(const Env& env, std::uint32_t script, std::int32_t num,
    Dialogue& dialogue, mission::Outcome& outcome);

void merge(mission::Outcome& into, mission::Outcome from);

}  // namespace game::talk::detail
