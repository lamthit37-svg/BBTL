/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/viewer/viewer.hpp
 *  PHÂN HỆ   : Client / Viewer / Viewer
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cửa sổ xem cảnh của client. Mỗi nền tảng một tệp cài đặt, CMake chọn một:
 *    viewer_win32.cpp dùng module window, viewer_none.cpp cho nền tảng chưa có
 *    cửa sổ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "client/display/display.hpp"
#include "client/map/ground.hpp"
#include "client/stage/stage.hpp"
#include "client/viewer/client_size.hpp"
#include "client/world/world.hpp"

#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

// Tên trên thanh tiêu đề (chủ dự án chốt 2026-10-16: dùng tên Việt). Icon là icon gốc của Game.exe.
inline constexpr std::string_view kGameTitle = "Thiên Long Bát Bộ";

struct ViewerDesc {
    // Tiêu đề cửa sổ, UTF-8.
    std::string title;
    // Số lượt của vòng vẽ (Display::turns) rồi tự thoát; không có thì chạy tới khi người dùng đóng cửa sổ.
    std::optional<std::uint32_t> frames;
    // Nội dung sẽ vẽ; null thì khung chỉ là màu nền. Mượn: phải sống lâu hơn run_viewer.
    const Stage* stage = nullptr;
    // Cảnh đang chơi. Mũi tên trái/phải và Page Up/Page Down gọi enter(resid) trên con trỏ này.
    world::World* playing = nullptr;
    // Địa hình đã nạp; null khi cảnh không có. Mượn cùng đời với stage.
    const game::client::map::Ground* ground = nullptr;
    // Cảnh nền không qua bảng cảnh (màn đăng nhập): phần hiển thị nạp dần nó như một cảnh chơi, tới
    // khi rời thủ tục đăng nhập.
    std::shared_ptr<const world::ShownScene> backdrop;
    // tl3chuangjian. Phần hiển thị đổi sang cảnh này khi bảng chọn hoặc bảng tạo đang mở.
    std::shared_ptr<const world::ShownScene> role_scene;
    // Resid của cảnh vào khi rời màn đăng nhập (nút vào game); cần playing. Không có thì nút vào
    // game chỉ báo một dòng.
    std::optional<int> first_scene;
    // Thư mục gốc dữ liệu (chứa Model/ và Material/); rỗng thì không nạp mesh nào.
    std::filesystem::path data_folder;
    // Ảnh chụp khung đầu tiên vẽ được; rỗng thì không chụp.
    std::filesystem::path shot;
    // Không vẽ lớp giao diện: khung hình chỉ còn cảnh 3D và hiệu ứng (để chụp cảnh nền).
    bool is_bare = false;
    // --walk: nhân vật tự chạy vòng để đo nhịp lúc di chuyển (DisplayDesc::is_auto_walk).
    bool is_auto_walk = false;
    // --auto-strike: khung màn chơi đầu tiên tự dùng skill ở ô cuối, 0 là tắt (DisplayDesc::auto_strike_from).
    std::uint32_t auto_strike_from = 0;
    // --ui-event: sự kiện giao diện phát ở khung màn chơi đầu tiên (DisplayDesc::ui_events).
    std::vector<std::string> ui_events;
    // --script: kịch bản E2E đã đọc (DisplayDesc::script). Có kịch bản thì viewer không nâng tần số
    // quét, cửa sổ không giành tiêu điểm, và mã thoát là 3 khi có bước hỏng. shot_dir là
    // DisplayDesc::shot_dir (--shot-dir).
    std::optional<ScriptSteps> script;
    std::filesystem::path shot_dir;
    // --creature: id mẫu quái hay NPC đứng trước mặt nhân vật ở màn chơi (DisplayDesc::creatures).
    std::vector<std::uint32_t> creatures;
    // --pet: id mẫu trân thú (DisplayDesc::pets).
    std::vector<std::uint32_t> pets;
    // --impact: id hiệu ứng bật ở khung đầu (DisplayDesc::impact_id). 0 là id thật.
    std::optional<std::uint32_t> impact_id;
    // --peer: số người chơi khác đứng trước mặt (DisplayDesc::peer_count).
    std::uint32_t peer_count = 0;
    // --talk-demo: NPC của --creature bấm được, hộp thoại đáp bằng kịch bản có sẵn (DisplayDesc::talk_demo).
    std::string talk_demo;
    // --weapon: vật phẩm khe 0 mà nhân vật ở màn chơi cầm (DisplayDesc::weapon_item).
    std::optional<std::uint32_t> weapon_item;
    // --mount: id CharMount (DisplayDesc::ride_id). 0 là hổ.
    std::optional<std::uint32_t> ride_id;
    // --gem: đá quý gắn vào vũ khí (DisplayDesc::weapon_gem).
    std::optional<std::uint32_t> weapon_gem;
    // --skill: skill gieo thêm vào hero.skills (DisplayDesc::skill_id).
    std::optional<std::uint32_t> skill_id;
    // Bật lớp kiểm tra của API đồ hoạ: bản dựng phát hành tắt mặc định cho đỡ hao CPU mỗi khung.
    bool is_validated = true;
    // Rỗng: tự chọn. Có thì ép backend.
    std::optional<std::string> backend;
    // Chính sách đồ hoạ (DisplayDesc::quality); rỗng thì theo nền tảng.
    std::optional<QualityClass> quality;
    // Cỡ vùng chơi của cửa sổ PC; rỗng thì kDefaultClientSize (View_Resoution của client 2026).
    std::optional<ClientSize> client_size;
    // Việc đã bắt đầu sớm (DisplayPreload, cùng data_folder và backend); nullptr thì Display tự bắt đầu.
    std::shared_ptr<DisplayPreload> preload;
    // Thủ tục sẽ chạy lúc mở. kLogin vẽ backdrop và chưa vào cảnh nào của playing; nó sang màn chơi
    // khi giao diện nhờ vào game.
    Procedure procedure = Procedure::kPlay;
};

// Cỡ vùng chơi của cửa sổ sẽ mở: thủ tục đăng nhập luôn là kLoginClientSize, kể cả khi đã chọn cỡ
// khác; màn chơi lấy cỡ đã chọn, không chọn thì kDefaultClientSize.
[[nodiscard]] inline ClientSize client_size_of(const ViewerDesc& desc) noexcept {
    if (desc.procedure == Procedure::kLogin) return kLoginClientSize;
    return desc.client_size.value_or(kDefaultClientSize);
}

// Mở cửa sổ và chạy tới khi nó đóng hoặc đủ số vòng lặp; trả mã thoát của tiến trình (0 là xong).
[[nodiscard]] int run_viewer(const ViewerDesc& desc);

} // namespace game::client
