#pragma once
// Phiên mở đầu dùng chung cho PC, Android và iOS. Nạp nền đăng nhập (erengu_DL), nền chọn
// nhân vật (tl3chuangjian) và bảng cảnh, rồi vào đúng một resid khi giao diện nhờ. Không đụng
// GPU: vỏ mỗi nền gọi Display::play sau khi host_step báo đã vào.
// Thiếu tệp thì trường tương ứng rỗng và notes có một dòng; không ném vì thiếu dữ liệu.
// bad_alloc vẫn có thể ném khi cảnh lớn hơn bộ nhớ.

#include "client/display/display.hpp"
#include "client/world/world.hpp"

#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

// Cảnh nền không có dòng trong bảng. -1 là "không có cảnh" của phần hiển thị, -2 đã là phông
// tài khoản ở bản gốc nên nền chọn nhân vật dùng -3.
inline constexpr int kBackdropSceneId = -2;
inline constexpr int kRoleSceneId = -3;

// Một cảnh mở từ tệp, không qua bảng. error khác rỗng thì shown rỗng. terrain là lỗi địa hình
// khi cảnh vẫn mở được. summary là dòng địa hình đã nạp, để vỏ in ra stdout.
struct NamedScene {
    std::shared_ptr<const world::ShownScene> shown;
    std::string error;
    std::string terrain;
    std::string summary;
};

// name là tên không đuôi của Scene/<name>.Scene. Có '/' , '\\' , ':' , rỗng, "." hoặc ".." thì
// không đọc đĩa và error nói tên không hợp lệ. Dấu ':' trên Windows biến đường tương đối thành
// tên ổ (C:ten.Scene thoát khỏi thư mục Scene).
[[nodiscard]] NamedScene load_named_scene(const std::filesystem::path& data_root, std::string_view name, int scene_id);

struct BootLoad {
    std::filesystem::path data_root;
    std::optional<world::World> playing;
    std::shared_ptr<const world::ShownScene> backdrop;
    std::shared_ptr<const world::ShownScene> role_scene;
    // Resid của Config/startup.id khi bảng mở được và tệp là một số nguyên. Chưa vào cảnh đó.
    std::optional<int> first_scene;
    // Đúng thứ tự PC in: lỗi của một cảnh, rồi dòng địa hình của cảnh đó. is_problem thì vỏ ghi
    // kênh lỗi; không thì kênh thường.
    struct Line {
        bool is_problem = false;
        std::string text;
    };
    std::vector<Line> lines;
};

// Thủ tục đăng nhập. Không vào cảnh chơi: nút vào game mới gọi host_step.
[[nodiscard]] BootLoad load_login(const std::filesystem::path& data_root);

struct EnterNote {
    bool ok = false;
    // Rỗng khi ok. Là describe(EnterError), chưa có tiền tố "Vào game:".
    std::string detail;
};

// Vào resid trong data_root/Scene. Đã ở đúng cảnh thì ok và không đọc lại. Thất bại thì
// playing không đổi.
[[nodiscard]] EnterNote enter_startup(world::World& playing, int resid, const std::filesystem::path& data_root);

// Việc vỏ phải làm sau một lời nhờ của giao diện. kNone là không có việc cửa sổ (kể cả vào
// game thất bại: detail nói lý do và is_playing giữ nguyên).
enum class HostAsk : std::uint8_t { kNone, kLeave, kOpenWeb, kEntered };

struct HostStep {
    HostAsk ask = HostAsk::kNone;
    WebLink link = WebLink::kHelp;
    std::string detail;
};

// KEnterGame khi chưa chơi: enter_startup resid first_scene. Đang chơi thì bỏ lời vào game.
// kind lạ (không phải ba giá trị của RequestKind) là kNone, không đổi is_playing.
[[nodiscard]] HostStep host_step(BootLoad& boot, bool& is_playing, Request request);

// Tên tiếng Việt của một trang, cùng thứ tự với WebLink. Giá trị ngoài enum là "trang web".
[[nodiscard]] std::string_view web_link_name(WebLink link) noexcept;

} // namespace game::client
