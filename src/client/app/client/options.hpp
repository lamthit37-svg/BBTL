/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/options.hpp
 *  PHÂN HỆ   : Client / Client / Options
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tuỳ chọn dòng lệnh của thienlong_client, tách khỏi main để kiểm được bằng
 *    test. Mỗi tuỳ chọn là một cặp "--khoá giá trị"; sai cách dùng thì không có
 *    kết quả, main in hướng dẫn và thoát mã 2.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "client/display/policy.hpp"
#include "client/viewer/client_size.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

inline constexpr std::string_view kUsage =
    "Cách dùng: thienlong_client [--scene-id <resid>] [--scene <tên map>] [--data <thư mục>]\n"
    "                         [--frames <số khung>] [--shot <tệp.png>] [--validate]\n"
    "                         [--backend <tên>] [--size <rộng>x<cao>] [--login] [--bare]\n"
    "                         [--walk] [--weapon <mã vật phẩm>] [--gem <mã đá quý>]\n"
    "                         [--skill <mã skill>] [--auto-strike <khung>]\n"
    "                         [--ui-event <TÊN|arg0|arg1|arg2|arg3>]...\n"
    "--scene-id là resid trong Config/SceneDefineEx.txt. --scene tìm tên file .Scene trong bảng "
    "đó.\n"
    "Không nêu --scene và --scene-id: mở đăng nhập, như bấm đúp exe. Nút vào game đọc "
    "Config/startup.id.\n"
    "--shot: ghi ảnh chụp khung đầu tiên vẽ được ra tệp PNG.\n"
    "--size: cỡ vùng chơi, như View_Resoution của client 2026 (1280x720 hoặc 1280,720), mỗi\n"
    "cạnh từ 800x600 tới 16384. Không nêu thì 1280x720. Cửa sổ cố định như bản gốc.\n"
    "--backend: vulkan, gles, d3d12 hoặc d3d11. Không nêu thì tự chọn.\n"
    "--validate: bật lớp kiểm tra của API đồ hoạ (bản debug bật sẵn, bản phát hành tắt cho nhanh).\n"
    "--login: mở thủ tục đăng nhập (bảng nhập tài khoản) thay vì vào thẳng một cảnh.\n"
    "--bare: không vẽ lớp giao diện, chỉ cảnh 3D và hiệu ứng; dùng với --shot để chụp cảnh nền.\n"
    "--frames: thoát sau chừng ấy lượt của vòng vẽ (khung đã vẽ cộng lượt nghỉ khi cửa sổ ẩn).\n"
    "Bảng đo nhịp khung luôn hiện ở màn chơi, không tắt được (chủ dự án chốt 2026-10-14); nó so\n"
    "với một nhịp quét của màn (trình Fifo), không biết nhịp quét thì với 120 Hz. --shot chờ đủ\n"
    "30 mẫu của bảng nên cần --frames từ 30 trở lên.\n"
    "--walk: ở màn chơi nhân vật tự chạy vòng (giữ W, hướng nhìn xoay đều) để đo nhịp lúc di\n"
    "chuyển; lúc thoát in bước chân mỗi khung. Công cụ đo, client gốc không có.\n"
    "--weapon: ở màn chơi nhân vật cầm vũ khí của vật phẩm khe 0 này (mã trong EquipBase, ví dụ\n"
    "10100000 là Thanh Đồng Đao): mẫu gắn vào tay theo locator của mẫu nhân vật, clip đứng và chạy\n"
    "theo loại vũ khí. Công cụ thử, tới khi có hành trang nối vào ngoại hình.\n"
    "--gem: đá quý gắn vào vũ khí của --weapon (mã trong GemInfo, ví dụ 20101001): vũ khí có hiệu ứng đồ theo màu và\n"
    "kiểu của đá. Công cụ thử, tới khi có hành trang nối vào ngoại hình.\n"
    "--skill: ở màn chơi nhân vật học thêm skill này (mã trong SkillTemplate_V1, ví dụ 1 hay 2); phím\n"
    "1 tới 9 dùng skill ở ô thứ n (ô 1 là đánh thường). Công cụ thử, tới khi có gói skill của máy chủ.\n"
    "--auto-strike: ở màn chơi tự nhấn ô thao tác cuối ở khung màn chơi thứ <khung> (từ 1) rồi mỗi 180\n"
    "khung, để chụp hay đo đòn đánh mà không cần phím thật. --shot chụp ở khung cố định sau khi bảng đo\n"
    "đủ 30 mẫu, không theo --frames: đổi <khung> để chụp đòn ở thời điểm khác. Công cụ đo, client gốc\n"
    "không có.\n"
    "--ui-event: ở khung màn chơi đầu tiên phát một sự kiện của game cho các bảng giao diện (như\n"
    "PushEvent(tên, arg0...) của game gốc), ví dụ \"PROGRESSBAR_SHOW|Đang luyện công\"; nêu nhiều\n"
    "lần thì phát theo thứ tự. Phần rỗng là nil. Công cụ thử, tới khi có gói tin của máy chủ.";

struct Options {
    // Rỗng: không chọn theo tên file. resid được ưu tiên hơn tên này.
    std::string scene_name;
    // resid trong SceneDefineEx.txt. Không nêu thì không chọn theo số.
    std::optional<int> scene_id;
    // Rỗng: lấy <thư mục chứa exe>/../assets.
    std::filesystem::path data_folder;
    // Số lượt của vòng vẽ rồi tự thoát, cho chạy tự động; không có thì chạy tới khi đóng cửa sổ.
    std::optional<std::uint32_t> frames;
    // Ảnh chụp khung đầu tiên vẽ được; rỗng thì không chụp.
    std::filesystem::path shot_path;
    // Bật lớp kiểm tra của API đồ hoạ; không nêu thì theo loại bản dựng (debug bật, phát hành tắt).
    std::optional<bool> validate;
    // Rỗng: tự chọn. Có thì ép đúng backend đó, không đổi sang backend khác.
    std::optional<std::string> backend;
    // --quality desktop|mobile: chính sách đồ hoạ (display/policy.hpp). Rỗng thì theo nền tảng. mobile trên PC vẽ đúng như
    // điện thoại (LOD, trần tam giác, một mẫu, texture 512) để so ảnh mà không cần máy thật.
    std::optional<QualityClass> quality;
    // Cỡ vùng chơi của cửa sổ PC; không nêu thì kDefaultClientSize (View_Resoution của 2026).
    std::optional<ClientSize> client_size;
    // Ép mở đăng nhập kể cả khi đã nêu --scene hoặc --scene-id. Không nêu cảnh thì main cũng
    // mở đăng nhập, để bấm đúp exe vào được game.
    bool is_login = false;
    // Không vẽ lớp giao diện (khung, nút, chữ, bảng đo): khung hình chỉ còn cảnh 3D và hiệu ứng.
    bool is_bare = false;
    // --walk: ở màn chơi nhân vật tự chạy vòng (giữ W, hướng nhìn xoay đều), lúc thoát in bước chân
    // mỗi khung. Công cụ đo của dự án, client gốc không có.
    bool is_auto_walk = false;
    // --weapon: vật phẩm khe 0 mà nhân vật ở màn chơi cầm. Công cụ thử của dự án.
    std::optional<std::uint32_t> weapon_item;
    // --gem: đá quý gắn vào vũ khí. Công cụ thử của dự án.
    std::optional<std::uint32_t> weapon_gem;
    // --skill: skill học thêm. Công cụ thử của dự án.
    std::optional<std::uint32_t> skill_id;
    // --auto-strike: khung màn chơi đầu tiên tự dùng skill ở ô cuối, rồi lặp theo nhịp; 0 là tắt. Công cụ đo của dự án.
    std::uint32_t auto_strike_from = 0;
    // --ui-event: sự kiện giao diện phát ở khung màn chơi đầu tiên, theo thứ tự. Công cụ thử của dự án.
    std::vector<std::string> ui_events;
    // --creature: id mẫu quái hay NPC đứng thành lưới trước mặt nhân vật ở màn chơi, để nhìn hình mà không cần máy chủ.
    // Công cụ thử của dự án.
    std::vector<std::uint32_t> creatures;
    // --pet: id mẫu trân thú (cùng bảng creature) đứng trước mặt. Công cụ thử, client gốc không có.
    std::vector<std::uint32_t> pets;
    // --peer: số người chơi khác đứng trước mặt (1..4), nữ rồi nam, bộ mặc định. Công cụ thử, client gốc không có.
    std::uint32_t peer_count = 0;
    // --talk-demo <click|menu|offer|turn|fight|fall>: NPC của --creature bấm được và hộp thoại được đáp bằng kịch bản có sẵn thay cho
    // máy chủ. click chờ người chơi bấm NPC; menu, offer, turn mở sẵn hộp tương ứng ở khung đầu (để chụp). fight: quái của
    // --creature đánh được, chiêu của người chơi được đáp bằng sát thương giả như máy chủ v6 và tự đánh quái đầu; fall như fight
    // nhưng người chơi bị đánh chết ở chiêu đầu (để xem lời nhắc hồi sinh). Rỗng là tắt.
    // Công cụ thử của dự án.
    std::string talk_demo;
};

using Arguments = std::span<const std::string_view>;

// Tuỳ chọn đọc từ các đối số sau tên exe; không có khi sai cách dùng. Không đối số nào là hợp lệ.
[[nodiscard]] std::optional<Options> parse_options(Arguments arguments);

using SceneNames = std::span<const std::string>;
using SceneChoice = std::optional<std::string>;

// Cảnh sẽ mở: cảnh được nêu; không nêu thì cảnh duy nhất trong available; còn lại không có.
[[nodiscard]] SceneChoice choose_scene(std::string_view requested, SceneNames available);

} // namespace game::client
