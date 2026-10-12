// Bảng chuyển cảnh (SceneTrans/SceneTrans.layout.xml): tấm ảnh 256 x 256 nằm giữa màn hình ở 37%
// chiều cao, mang một dòng chữ vàng "前往<tên cảnh>" trong lúc client nạp cảnh sẽ tới, thêm
// "[<phần trăm>]" khi việc nạp báo tiến độ, và tự giấu khi cảnh mới đã sẵn.
// Nguồn: Interface/SceneTrans/SceneTrans.lua của client 2026 (giải bằng TOOLS/content/lua_plain.py);
// mỗi hàm dưới đây là một nhánh của SceneTrans_OnEvent. Chữ "前往" viết thẳng trong script; bản dịch
// lấy theo cả mẫu (hai dòng nguyên văn của bảng chuỗi, chỗ điền %s0 và %s1 như wording.hpp) để
// ngôn ngữ có dấu cách giữa các từ tự đặt dấu cách.
// Khác gốc: nhánh chờ vào biệt dã (UI_COMMAND 89187003: chữ #{JYGZ_160809_265}, khoá phím tắt, tự
// đóng sau 10 giây) chưa port vì chưa có máy chủ phát lệnh đó; SceneTransB (đếm ngược trước khi
// chuyển) cũng vậy.
#pragma once

#include "gui/strings.hpp"
#include "ui/panel/deck.hpp"

#include <cstdint>
#include <string>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kSceneTransLayout = "SceneTrans/SceneTrans.layout.xml";

// Trạng thái của bảng: this:IsVisible(), g_strTargetSceneName và chữ đang đặt cho dòng tên cảnh.
struct SceneTrans {
    bool is_shown = false;
    std::string target;
    std::string text;
};

// PLAYER_LEAVE_WORLD(arg0): nhớ tên cảnh đích, đặt chữ "前往<tên>" và hiện bảng. scene là tên đã
// dịch mà người chơi sẽ đọc.
void leave_world(SceneTrans& panel, std::string_view scene, const gui::StringBook& words);
// ON_SCENE_TRANSING(arg0): bảng đang hiện thì chữ thành "前往<tên>[<percent>]"; đang giấu thì bỏ qua.
void scene_transing(SceneTrans& panel, std::int32_t percent, const gui::StringBook& words);
// SCENE_TRANSED: giấu bảng.
void scene_transed(SceneTrans& panel) noexcept;
// Hiện gốc của bảng và đặt chữ khi bảng đang hiện; đang giấu thì không làm gì (layout nạp ở trạng
// thái ẩn).
void paint_scene_trans(Deck& deck, const SceneTrans& panel);

} // namespace game::ui::panel
