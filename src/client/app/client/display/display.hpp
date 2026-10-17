/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/display.hpp
 *  PHÂN HỆ   : Client / Display / Display
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần hiển thị của cửa sổ xem cảnh: một LUỒNG VẼ riêng giữ thiết bị đồ hoạ,
 *    màn hình vẽ và render::Forward, quay đều mỗi khung cho tới khi bị dừng —
 *    lõi của mọi engine mượt (o3de, Wicked): luồng thông điệp chỉ bơm thông
 *    điệp, không bao giờ chặn GPU, nên kéo hay đổi cỡ cửa sổ không bao giờ
 *    giật.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nội dung stage được luồng vẽ nạp một lần lúc khởi tạo: mỗi mesh một GLB (Model/<tên>.glb, ảnh ngoài giải trong thư
// mục dữ liệu), một upload, một Drawable; mỗi vật thể là một Instance với ma trận thế giới T * R * S từ phép đặt gốc.

// Cảnh có địa hình thì camera là camera cảnh của client 2026 (control/follow_camera), điều khiển bằng chuột, phím và
// chạm như CGamePro_Main (control/player_input); không có thì luồng vẽ xoay camera quanh hộp bao thế giới theo đồng
// hồ. Luồng vẽ vẽ đèn directional đầu tiên và ambient của cảnh, và ghi PNG khung đầu (--shot). Hai bản cài đặt, CMake
// chọn một: display/graphic chia luồng vẽ theo domain (khung, nạp, cảnh, chơi, giao diện, hiệu ứng) và dùng module
// gpu, render. display_none.cpp cho cấu hình không dựng chuỗi đồ hoạ — không vẽ gì. Nhờ vậy mã gọi không cần biết cấu
// hình nào đang dựng.

#pragma once

#include "client/cast/note.hpp"
#include "client/display/policy.hpp"
#include "client/display/script.hpp"
#include "client/map/ground.hpp"
#include "client/stage/stage.hpp"
#include "client/world/world.hpp"
#include "control/cursor_rules.hpp"
#include "control/input.hpp"
#include "core/error.hpp"
#include "core/ground_point.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/talk.hpp"

#include <cstdint>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

// Cỡ vùng vẽ của cửa sổ tính bằng điểm ảnh; bằng 0 khi cửa sổ đang thu nhỏ.
struct PixelSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Thủ tục client đang chạy, như CGameProcedure của client gốc: kLogin là thủ tục đăng nhập (giao
// diện chỉ có bảng nhập tài khoản, chưa có cảnh chơi), kPlay là màn chơi.
enum class Procedure : std::uint8_t { kPlay, kLogin };

// Trang web mà một nút của giao diện mở (GetWeblink của client gốc): nạp thẻ, đăng ký tài khoản,
// quên mật khẩu, thẻ bảo mật, trợ giúp, diễn đàn. Diễn đàn là WEB_TLLUNTAN; chưa có URL.
enum class WebLink : std::uint8_t { kTopUp, kRegister, kLostPassword, kSecurityCard, kHelp, kForum };

// Việc giao diện nhờ vòng cửa sổ làm: vào game (rời thủ tục đăng nhập), rời client, mở trang web.
enum class RequestKind : std::uint8_t { kEnterGame, kLeave, kOpenWeb };

// Chỗ vào game do máy chủ đặt: cảnh theo resid của client và chỗ đứng theo đơn vị game (mét; máy chủ nói centimet).
struct EntryPoint {
    std::int32_t scene = 0;
    float x = 0.0F;
    float z = 0.0F;
};

struct Request {
    RequestKind kind = RequestKind::kLeave;
    // Trang của kOpenWeb.
    WebLink link = WebLink::kHelp;
    // kEnterGame ở chế độ trực tuyến: máy chủ đã nhận nhân vật và đặt chỗ vào. Không có là vào cảnh khởi đầu cục bộ.
    std::optional<EntryPoint> entry = std::nullopt;
};

// Ngoại hình đã chọn lúc vào game. Vỏ giữ bản này qua lần huỷ phần hiển thị (tạm dừng) để lần
// dựng lại không về nhân vật mặc định. has là false khi chưa vào game hoặc chưa kịp áp.
struct KeptRole {
    bool has = false;
    std::uint8_t sex = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
};

class DisplayPreload;

struct DisplayDesc {
    // HWND của cửa sổ (window::Window::native_handle).
    void* window = nullptr;
    PixelSize size;
    Procedure procedure = Procedure::kPlay;
    // Bật lớp kiểm tra của API đồ hoạ; lỗi nó báo được đếm ở validation_errors.
    bool is_validated = true;
    // Nội dung sẽ vẽ; null hoặc không có vật thể thì khung chỉ là màu nền. Display mượn con trỏ:
    // stage phải sống lâu hơn Display.
    const Stage* stage = nullptr;
    // Địa hình của cảnh. Null khi cảnh không có .Terrain. Display mượn; ground sống lâu hơn
    // Display. Bị bỏ qua khi scene được đặt: phần vẽ theo cảnh đó và đổi khi show().
    const game::client::map::Ground* ground = nullptr;
    // Cảnh đang chơi. Có thì nạp cảnh này thay cho stage/ground phía trên.
    std::shared_ptr<const world::ShownScene> scene;
    // Cảnh tl3chuangjian của bảng chọn và bảng tạo. Rỗng thì hai bảng ở lại cảnh tài khoản.
    std::shared_ptr<const world::ShownScene> role_scene;
    // Thư mục gốc dữ liệu (chứa Model/ và Material/); rỗng thì không nạp mesh nào.
    std::filesystem::path data_root;
    // Nơi ghi Save/roles.tsv. Rỗng thì dùng data_root. iOS để data_root là bundle chỉ đọc và
    // đưa thư mục Documents vào đây; Android giải nén vào bộ nhớ trong nên để rỗng.
    std::filesystem::path save_root;
    // Màn điện thoại (nhỏ hơn 600 dp ở cạnh ngắn, hay iPhone): giao diện dùng layout Interface/phone. Máy tính bảng và PC
    // để false: dùng giao diện PC.
    bool uses_phone_layout = false;
    // Điểm ảnh của màn cho một điểm giao diện: 1 trên PC (bản gốc không co giao diện), dpi/160 trên Android,
    // contentScaleFactor trên iOS. Giao diện giữ cỡ vật lý trên màn mật độ cao (ui::layout_scale); bảng đăng nhập nằm trong
    // khung 1280x720 điểm giao diện giữa màn (placed_frame), cảnh nền vẫn vẽ trọn màn.
    float ui_density = 1.0F;
    // Chính sách đồ hoạ (policy.hpp): rỗng thì default_quality() của nền tảng. Đường vẽ chỉ đọc chính sách, không hỏi nền
    // tảng, nên PC chạy được chính sách của điện thoại để so ảnh.
    std::optional<QualityClass> quality;
    // Ghi ảnh chụp khung đầu tiên vẽ được ra tệp PNG này; rỗng thì không chụp.
    std::filesystem::path shot_path;
    // Không vẽ lớp giao diện (HUD, bảng đăng nhập, bảng đo): khung hình chỉ còn cảnh 3D và hiệu
    // ứng. Giao diện vẫn chạy và nhận chuột, phím như thường, chỉ không ra hình.
    bool is_bare = false;
    // Công cụ đo của dự án (--walk), client gốc không có: ở màn chơi nhân vật tự chạy tới như giữ W
    // và hướng nhìn xoay đều kWalkTurnPerSecond, để đo nhịp khung lúc di chuyển mà không cần chuột hay
    // phím thật. Lúc thoát in một dòng về bước đi mỗi khung.
    bool is_auto_walk = false;
    // Công cụ đo của dự án (--auto-strike), client gốc không có: ở màn chơi tự nhấn ô thao tác cuối ở khung màn chơi
    // thứ auto_strike_from rồi mỗi 180 khung, để chụp hay đo đòn đánh mà không cần phím thật. 0 là tắt.
    std::uint32_t auto_strike_from = 0;
    // Công cụ thử của dự án (--ui-event), client gốc không có: sự kiện giao diện "TÊN|arg0|...|arg3" phát cho các bảng ở
    // khung màn chơi đầu tiên, theo thứ tự, như PushEvent của game gốc.
    std::vector<std::string> ui_events;
    // Công cụ thử của dự án (--creature), client gốc không có: id mẫu quái hay NPC đứng thành lưới trước mặt nhân vật ở
    // khung màn chơi đầu tiên, như máy chủ vừa báo chúng vào vùng nhìn. Để nhìn hình mà không cần máy chủ.
    std::vector<std::uint32_t> creatures;
    // Công cụ thử (--pet): id mẫu trân thú đứng trước mặt, như máy chủ gửi EntityKind::kPet.
    std::vector<std::uint32_t> pets;
    // Công cụ thử (--impact): id hiệu ứng bật trên người chơi ở khung đầu. 0 là id thật.
    std::optional<std::uint32_t> impact_id;
    // Công cụ thử (--peer): số người chơi khác đứng trước mặt ở khung đầu, như máy chủ vừa cho thấy họ.
    std::uint32_t peer_count = 0;
    // Công cụ thử của dự án (--talk-demo), client gốc không có: NPC của --creature mang cờ bấm được, và việc người chơi nhờ
    // ở hộp thoại được đáp bằng kịch bản có sẵn (graphic/talk_demo.cpp) thay cho máy chủ. "click" chờ người chơi bấm NPC;
    // "menu", "offer", "turn" mở sẵn hộp tương ứng ở khung màn chơi đầu. "fight": quái của --creature đánh được và chiêu được
    // đáp bằng sát thương giả (graphic/fight_demo.cpp); "fall" như "fight" nhưng người chơi chết ở chiêu đầu. Rỗng là tắt.
    std::string talk_demo;
    // Công cụ thử của dự án (--weapon): vật phẩm khe 0 mà nhân vật ở màn chơi cầm; không có thì tay
    // không (hay ngoại hình đã chọn). Hành trang thật nối vào ngoại hình sau (docs/NGHI-NGO.md).
    std::optional<std::uint32_t> weapon_item;
    // Công cụ thử (--mount): id CharMount. 0 là hổ. Không có thì không cưỡi. Chưa có trường trên
    // dây.
    std::optional<std::uint32_t> ride_id;
    // Công cụ thử của dự án (--gem): đá quý gắn vào vũ khí, gieo vào hero.equipment như gói trang bị của máy chủ.
    std::optional<std::uint32_t> weapon_gem;
    // Công cụ thử của dự án (--skill): skill học thêm, gieo vào hero.skills như gói skill của máy chủ.
    std::optional<std::uint32_t> skill_id;
    // Rỗng: tự chọn backend. Có thì ép đúng tên đó.
    std::optional<std::string> backend;
    // Công cụ thử của dự án (--script), client gốc không có: kịch bản E2E chạy mỗi khung một bước
    // (display/script.hpp). Không có thì không chạy kịch bản. shot_dir là nơi bước shot ghi ảnh.
    std::optional<ScriptSteps> script;
    std::filesystem::path shot_dir;
    // Máy chủ trong danh sách đăng nhập có cổng thật (client/session): chọn chúng thì thủ tục đăng
    // nhập nối máy chủ.
    std::vector<ui::panel::ServerName> online_servers;
    // Công cụ thử: tài khoản đăng nhập tự động vào máy chủ đầu của online_servers (auto_login.hpp). Rỗng là không bật.
    std::optional<std::string> auto_account;
    // Có has thì màn chơi dùng ngoại hình này thay cho nhân vật mặc định.
    KeptRole restored;
    // Việc đã bắt đầu sớm (DisplayPreload); nullptr thì Display::create tự bắt đầu.
    std::shared_ptr<DisplayPreload> preload;
};

// Điều khiển bằng phím, cộng dồn giữa hai khung. Mũi tên lên xuống là lệnh phím zoom của client
// 2026 (hai bước 0,05 mỗi lần nhấn), V là ResetCamera (hướng quay dần về 3,1415). Mũi tên trái phải
// xoay 0,04 radian như bản 2008; bản 2026 không còn phím xoay. W A S D đi theo hướng camera, là của
// cửa sổ này chứ không có trong client gốc. Chuột và chạm đi qua Display::input.
struct Steering {
    // Số lần nhấn phím: dương là trái (xoay) hoặc lên (lại gần).
    int turn_keys = 0;
    int zoom_keys = 0;
    // Có nhấn V: hướng camera quay về hướng lúc vào cảnh.
    bool is_home = false;
    // Có nhấn phím nhảy (Space) từ khung trước; nhảy lặp do giữ phím không tính.
    bool wants_jump = false;
    // Ô thao tác vừa nhấn (0 là ô 1) từ khung trước; giữ phím lặp không tính.
    std::optional<std::uint32_t> strike_slot;
    // Hướng đi đang giữ so với hướng nhìn, trong [-1, 1]; ghi đè chứ không cộng dồn, và chỉ khi
    // has_walk (để phím mũi tên không xoá hướng đi đang giữ).
    bool has_walk = false;
    float walk_forward = 0.0F;
    float walk_right = 0.0F;
};

// Thao tác chơi trừu tượng (lệnh của CAI_MySelf). Phím trên PC và nút chạm trên mobile cùng gọi
// Display::act; màn chơi không đọc mã phím.
enum class PlayAct : std::uint8_t { kJump, kStrike };

// Hàm tra tên hiển thị của một cảnh theo ngôn ngữ của bản dựng (Table/scene_names.lang.tsv dưới
// data_root), cho nơi nằm dưới tầng giao diện như tiêu đề cửa sổ của viewer. Tên chưa có bản dịch
// thì trả nguyên; thiếu tệp thì mọi tên trả nguyên. Bảng đọc một lần lúc gọi scene_title_lookup;
// hàm trả về chỉ đọc bảng bất biến đó nên luồng nào gọi cũng được.
using SceneTitle = std::function<std::string(std::string_view)>;
[[nodiscard]] SceneTitle scene_title_lookup(const std::filesystem::path& data_root);

class Display;

// Việc không cần cửa sổ, bắt đầu ngay khi dựng (mỗi việc một luồng riêng) để trùng với việc đọc cảnh và mở cửa sổ thay
// vì nằm trước khung đầu: nạp driver đồ hoạ (lần liệt kê adapter đầu của tiến trình nạp loader và mọi ICD, 100 tới
// 150 ms) và đọc dữ liệu giao diện (bộ nạp, layout, bảng chuỗi, phông: 280 ms nối đuôi). Dựng ngay đầu tiến trình, giữ
// tới khi Display::create nhận qua DisplayDesc::preload; data_root và backend phải khớp DisplayDesc::data_root và
// DisplayDesc::backend, khác thì Display::create tự bắt đầu lại. Không chặn, không báo lỗi (lỗi thật hiện lại ở
// Display::create). Huỷ khi chưa dùng thì chờ các luồng ấy xong. Bản không có đồ hoạ không làm gì.
class DisplayPreload {
public:
    DisplayPreload(const std::filesystem::path& data_root, const std::optional<std::string>& backend);
    DisplayPreload(DisplayPreload&&) noexcept;
    DisplayPreload& operator=(DisplayPreload&&) noexcept;
    DisplayPreload(const DisplayPreload&) = delete;
    DisplayPreload& operator=(const DisplayPreload&) = delete;
    ~DisplayPreload();

private:
    struct Work;
    std::unique_ptr<Work> work_;
    friend class Display;
};

class Display {
public:
    // Dựng luồng vẽ; khởi tạo thiết bị, màn hình vẽ và renderer xảy ra trên luồng ấy nên lỗi trả
    // về từ đây. Mượn cửa sổ và stage: Display phải bị huỷ trước cả hai.
    [[nodiscard]] static core::Result<Display> create(const DisplayDesc& desc);

    Display(Display&&) noexcept;
    Display& operator=(Display&&) noexcept;
    Display(const Display&) = delete;
    Display& operator=(const Display&) = delete;
    // Dừng luồng vẽ (nếu chưa dừng), chờ GPU rỗi cho tới khi mọi lệnh đã nộp chạy xong.
    ~Display();

    // Vùng vẽ của cửa sổ đã đổi cỡ: luồng vẽ dựng lại màn hình vẽ ở khung kế. An toàn mọi luồng,
    // không chặn.
    void notify_resized(PixelSize size) noexcept;
    // Đổi cảnh đang vẽ. Luồng vẽ xóa mesh cũ và nạp cảnh mới ở khung kế. An toàn mọi luồng.
    void show(const std::shared_ptr<const world::ShownScene>& scene);
    // Rời thủ tục đăng nhập sang màn chơi ở cảnh scene: luồng vẽ nạp người chơi, đổi sang camera và
    // giao diện của màn chơi ở khung kế. Đang ở màn chơi thì chỉ đổi cảnh như show. entry (nếu có) là chỗ đứng đầu
    // tiên máy chủ đặt, thay điểm đến mặc định của cảnh. An toàn mọi luồng.
    void play(const std::shared_ptr<const world::ShownScene>& scene, std::optional<EntryPoint> entry = std::nullopt);
    // Việc chuỗi đăng nhập nhờ phần nối máy chủ từ lần gọi trước (đăng nhập, tạo, xoá, vào game, trả phiên), theo
    // thứ tự; lấy rồi thì hết. An toàn mọi luồng.
    [[nodiscard]] std::vector<ui::panel::OnlineAsk> take_online_asks();
    // Đưa trả lời của phần nối máy chủ cho chuỗi đăng nhập ở khung kế. Hàng chờ có trần; vượt trần thì bỏ trả lời
    // cũ nhất (phần nối chỉ gửi vài trả lời mỗi khung). An toàn mọi luồng.
    void post_online(const ui::panel::OnlineReply& reply);
    // Việc giao diện đã nhờ từ lần gọi trước (nút của bảng đăng nhập), theo thứ tự. An toàn mọi luồng.
    [[nodiscard]] std::vector<Request> take_requests();
    // Tin thế giới của phiên mạng (vào cảnh, thực thể hiện, đi, biến mất, sinh lực, bị kéo về) cho luồng vẽ áp ở khung
    // kế, theo thứ tự. Hàng chờ có trần: vượt trần thì bỏ tin vị trí và sinh lực mới tới (trạng thái tức thời, tin sau
    // thay nó) chứ không bỏ tin hiện hay biến mất. An toàn mọi luồng.
    void post_world(std::span<const cast::Note> notes);
    // Tin hội thoại NPC, sổ nhiệm vụ và chỉ số bản thân của phiên mạng cho luồng vẽ áp ở khung kế, theo thứ tự. Hàng chờ có trần:
    // vượt trần thì bỏ tin cũ nhất (sổ và hộp mới thay bản cũ). An toàn mọi luồng.
    void post_talk(std::span<const ui::panel::talk::Hear> heard);
    // Việc hộp thoại và sổ nhiệm vụ mà người chơi đã nhờ từ lần gọi trước (bấm NPC, chọn dòng, nhận, nộp, đóng), theo thứ tự; lấy
    // rồi thì hết. An toàn mọi luồng.
    [[nodiscard]] std::vector<ui::panel::talk::Say> take_says();
    // Chỗ đứng của nhân vật ở khung vừa mô phỏng, mét của game: cái phiên mạng báo cho máy chủ. Rỗng khi chưa ở màn chơi,
    // chưa vào cảnh nào của máy chủ, hoặc cảnh máy chủ vừa đổi mà cảnh mới chưa nạp xong (báo chỗ của cảnh cũ lúc ấy
    // là dịch chuyển giả). An toàn mọi luồng.
    [[nodiscard]] std::optional<core::GroundPoint> reported_spot() const;
    // Đưa điều khiển bằng phím cho luồng vẽ; nó dùng ở khung kế. An toàn mọi luồng, không chặn lâu.
    void steer(const Steering& input) noexcept;
    // Đưa một thao tác chơi cho luồng vẽ; nó dùng ở bước mô phỏng kế. An toàn mọi luồng.
    // slot chỉ dùng cho kStrike: ô thao tác (0 là ô 1).
    void act(PlayAct what, std::uint32_t slot = 0) noexcept;
    // Tai nghe của khung vừa vẽ, centimet thế giới, hướng nhìn của camera. Rỗng khi chưa có camera.
    struct HeardEar {
        float x = 0.0F;
        float y = 0.0F;
        float z = 0.0F;
        float forward_x = 0.0F;
        float forward_y = 0.0F;
        float forward_z = -1.0F;
        float up_x = 0.0F;
        float up_y = 1.0F;
        float up_z = 0.0F;
    };
    // Một tiếng của kịch bản đòn. is_spatial thì x, y, z là centimet thế giới của điểm gắn.
    struct HeardSound {
        std::string name;
        float x = 0.0F;
        float y = 0.0F;
        float z = 0.0F;
        bool is_spatial = false;
    };
    struct SoundBatch {
        std::optional<HeardEar> ear;
        std::vector<HeardSound> due;
    };
    // Khối Sound của kịch bản đòn vừa tới mốc, kèm tai nghe. Luồng cửa sổ phát ra loa; nơi vẽ không giữ loa.
    // An toàn mọi luồng.
    [[nodiscard]] SoundBatch take_sounds();
    // Đưa thao tác chuột hay chạm (nhấn, nhả, di, lăn, cần gạt) cho luồng vẽ; nó gom thành mẫu
    // chuột của khung kế, như CInputSystem::MouseTick. Vị trí chuẩn hoá về [0, 1] theo vùng vẽ.
    // An toàn mọi luồng, không chặn lâu.
    void input(std::span<const control::InputEvent> events);
    // Dừng luồng vẽ và chờ GPU rỗi; trả lỗi vẽ đầu tiên của luồng (nếu có) hoặc lỗi khi chờ. Gọi
    // một lần trước khi huỷ; huỷ cũng tự gọi.
    [[nodiscard]] core::Status finish();
    // Số lỗi lớp kiểm tra đã báo, bản lưu gần nhất của luồng vẽ; 0 khi không bật.
    [[nodiscard]] std::uint64_t validation_errors() const noexcept;
    // Số lệnh vẽ của khung gần nhất; 0 ở bản không có chuỗi đồ hoạ.
    [[nodiscard]] std::uint32_t draw_count() const noexcept;
    // Luồng vẽ còn quay hay không: dừng khi lỗi vẽ hoặc mất thiết bị, vòng cửa sổ nên kết thúc.
    [[nodiscard]] bool is_spinning() const noexcept;
    // Kịch bản --script đã chạy hết (hay gặp bước quit): vòng cửa sổ nên kết thúc. false khi không
    // có kịch bản.
    [[nodiscard]] bool script_ended() const noexcept;
    // Số bước hỏng của kịch bản; mã thoát khác 0 khi có.
    [[nodiscard]] std::uint32_t script_failures() const noexcept;
    // Số lượt của vòng vẽ từ lúc quay (khung đã vẽ cộng lượt nghỉ khi cửa sổ ẩn hay bề mặt đang
    // đổi cỡ); --frames đếm theo số này. An toàn mọi luồng.
    [[nodiscard]] std::uint64_t turns() const noexcept;
    // Tần số quét của màn đang chứa cửa sổ, Hz. Khi trình Fifo, khung không nhanh hơn được nhịp quét,
    // nên bảng đo lấy 1000 / hz làm ngân sách thay cho trần render_hz. Số không dương hay không hữu
    // hạn là "không biết": bảng giữ ngân sách của trần. An toàn mọi luồng, không chặn.
    void set_refresh(double rate_hz) noexcept;
    // Một dòng mô tả để in ra: tên API và tên card, hoặc lý do không vẽ.
    [[nodiscard]] std::string description() const;
    // Bản ngoại hình luồng vẽ đã áp. Luồng cửa sổ đọc được trong lúc luồng vẽ đang chạy.
    [[nodiscard]] KeptRole kept_role() const;
    // Con trỏ của khung vừa vẽ theo control::choose_cursor; nullopt nghĩa là đang ẩn.
    [[nodiscard]] std::optional<control::CursorKind> cursor_choice() const noexcept;

private:
    struct State;

    explicit Display(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::client
