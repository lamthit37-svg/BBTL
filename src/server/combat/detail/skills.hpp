/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/detail/skills.hpp
 *  PHÂN HỆ   : Combat / Detail / Skills
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Giao diện mã xử lý logic kỹ năng (tương đương SkillLogic_T của GameServer
 *    2008). Arena làm phần chung (nhắm mục tiêu, trúng/né, hội tâm, tiêu hao,
 *    hồi chiêu, gom/dẫn); handler chỉ quyết định hiệu ứng nào đi tới ai. Header
 *    nội bộ module combat: module khác không include.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "actor/body.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"

#include <cstdint>
#include <span>
#include <string_view>

namespace game::combat::detail {

// Ngữ cảnh một lượt phát kỹ năng. `tick` là true ở nhịp dẫn (ActivateEachTick), false ở lượt phát
// một lần. `delay_ticks` là trễ từ lúc phát tới lúc hiệu ứng tới đích, đã đổi từ mili giây
// sang bước của nhịp arena. Gói tham chiếu sống đúng một lời gọi handler, không rỗng và
// không sao chép.
// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): gói tham chiếu sống một lời gọi,
// không sao chép (HP-07)
struct SkillRun {
    Arena& arena;
    Fighter& me;
    const SkillTemplate& tmpl;
    const CastInfo& info;
    const Target& target;
    const LogicSpec& spec;
    bool tick = false;
    std::int64_t delay_ticks = 0;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

class SkillHandler {
public:
    SkillHandler() = default;
    SkillHandler(const SkillHandler&) = delete;
    SkillHandler& operator=(const SkillHandler&) = delete;
    SkillHandler(SkillHandler&&) = delete;
    SkillHandler& operator=(SkillHandler&&) = delete;
    virtual ~SkillHandler() = default;

    // Kỹ năng bị động không bao giờ ra chiêu được; nó đóng góp qua contribute_passive.
    [[nodiscard]] virtual bool passive() const noexcept { return false; }
    // SpecificOperationOnSkillStart: thao tác/điều kiện riêng lúc bắt đầu; khác kOk thì từ chối.
    [[nodiscard]] virtual CastOutcome on_start(SkillRun& run) const;
    virtual void on_interrupt(SkillRun& run) const;
    // Một lượt phát: `hits` là các mục tiêu bị trúng, theo thứ tự quét (gần trước).
    virtual void apply(SkillRun& run, std::span<const Hit> hits) const = 0;
    // Kỹ năng bị động cộng vào chỉ số (chỉ handler bị động ghi đè).
    virtual void contribute_passive(const Fighter& me, const SkillLevel& level, const LogicSpec& spec,
        actor::Modifiers& out) const;
};

// Tra mã xử lý theo tên trong bảng skill_logics.tsv; nullptr khi tên lạ.
[[nodiscard]] const SkillHandler* find_skill_handler(std::string_view name) noexcept;

} // namespace game::combat::detail
