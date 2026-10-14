#pragma once
// Cổng cho handler viết tay: những điểm vào hội thoại mà công cụ trích tĩnh KHÔNG chuyển được thành bước đóng (script gốc dùng
// API mà tập op đóng không có, hoặc logic rẽ nhánh theo dữ liệu động). Mỗi handler gắn với một khoá (script, num) CỐ ĐỊNH và
// có MỘT dòng lý do vì sao cần viết tay; module `handlers` giữ danh sách tĩnh, talk::Service chỉ nhận một span của nó.
//
// Hợp đồng của HandlerFn:
// - Dựng hộp thoại bằng ctx.dialogue (begin, line, choice, set_mode...); lựa chọn nó thêm quay lại Service như mọi lựa chọn khác
//   nên có thể trỏ tới điểm vào của script trích được hoặc tới chính handler khác.
// - ctx.dry = true là lần chạy chỉ để TÍNH LẠI hộp thoại kiểm lựa chọn: không được đổi sổ, túi, ví hay ghi nhận gì.
// - Thay đổi trạng thái đi qua ctx.engine.run_effects (một giao dịch nguyên tử) để có sổ cái, nhật ký kiểm toán và gửi lại an toàn.
// - Trả mission::Failure khi một giao dịch bị từ chối; Service dừng lần chạy và trả lỗi cho client.

#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "talk/view.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::talk {

// NPC đang đối thoại, do zone cấp. `script` là id script của NPC (0 nếu NPC không có script hội thoại).
struct NpcRef {
    std::uint32_t guid = 0;
    std::int32_t scene = -1;
    std::uint32_t name = 0;    // ops::name_id của tên NPC
    std::uint32_t script = 0;

    friend bool operator==(const NpcRef&, const NpcRef&) noexcept = default;
};

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): ngữ cảnh một lần gọi handler: mọi tham chiếu sống lâu hơn nó, không sở hữu, không giữ qua tick (SH-04)
struct HandlerContext {
    mission::Character& hero;
    const NpcRef& npc;
    std::uint32_t script = 0;
    std::int32_t num = -1;
    const ops::Calendar& calendar;
    mission::Engine& engine;
    Dialogue& dialogue;
    mission::Outcome& outcome;
    bool dry = false;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

using HandlerFn = std::optional<mission::Failure> (*)(HandlerContext&);

struct HandlerSpec {
    std::uint32_t script = 0;
    std::int32_t num = -1;
    HandlerFn run = nullptr;
    std::string_view reason;  // vì sao điểm vào này không trích tĩnh được
};

}  // namespace game::talk
