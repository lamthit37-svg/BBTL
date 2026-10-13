// HUD của game: gom bộ nạp giao diện gốc (gui::GuiLoader), dàn trang (gui::Hub), bảng chuỗi, bảng
// tên cảnh, bảng chân dung, phông chữ, ảnh minimap và bộ vẽ (Painter) cho các cửa sổ HUD của client
// gốc, và cho bảng nhập tài khoản của thủ tục đăng nhập (HudView::phase). Dữ liệu là cây Interface
// do TOOLS/content/collect_ui.py gom vào CLIENT/data (XML gốc của client 2026, chưa nấu, không
// Lua). Mỗi khung: prepare ghi chỉ thị của các bảng (ui/panel) vào Deck, dàn trang theo cỡ màn hình
// và dựng đỉnh (ngoài begin_rendering, vì có thể tải texture); draw ghi lệnh vẽ vào danh sách đang
// ghi. Client gốc để script Lua hiện, giấu và điền từng cửa sổ; ở đây việc đó là của ui/panel.
// Nguồn: bản mới của dự án, tương ứng pc_hud.cpp của TLBB Dev (Deck hud_) ở phần dựng và vẽ.
#pragma once

#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "render/ui.hpp"
#include "ui/panel/login_flow.hpp"
#include "ui/view.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::ui {

struct HudDesc {
    // Thư mục dữ liệu client (CLIENT/data); giao diện nằm ở Interface và Table dưới đó.
    std::filesystem::path data_root;
};

// Cảnh đang đứng, cho minimap. radar là token szSceneMap của bảng cảnh (rỗng thì minimap chỉ còn
// khung); cỡ cảnh và vị trí người chơi theo đơn vị cảnh.
struct HudScene {
    std::string_view radar;
    // Tên cảnh nguyên văn của bảng cảnh; HUD hiện bản dịch, chưa dịch thì hiện nguyên văn.
    std::string_view name;
    float width = 0.0F;
    float depth = 0.0F;
    float player_x = 0.0F;
    float player_z = 0.0F;
    // Hướng mặt của người chơi theo radian, 0 là +z và tăng về +x (atan2(dx, dz)).
    float facing = 0.0F;
    // Canh giờ trong game, 0 (Tý) tới 11 (Hợi). Giờ trong game là của máy chủ.
    std::uint8_t watch = 0;
    // Id cảnh client (cột 0 của bảng cảnh). -1 khi chưa vào cảnh.
    int id = -1;
};

// Thủ tục đang chạy, như CGameProcedure của client gốc: kLogin là thủ tục đăng nhập (tài khoản, chọn
// nhân vật, tạo nhân vật), kPlay là màn chơi (HUD và các bảng mở từ thanh menu).
enum class Phase : std::uint8_t { kPlay, kLogin };

// Việc nạp cảnh mà bảng chuyển cảnh báo. name là tên cảnh; percent từ 0 tới 100.
struct SceneLoad {
    std::string name;
    std::int32_t percent = 0;
};

// Đầu vào của một khung: cỡ màn hình theo điểm ảnh, chuột (có thì nút dưới chuột đổi trạng thái),
// cảnh, nhân vật và đồng hồ. Con trỏ và các chuỗi mượn phải sống tới hết lời gọi prepare.
struct HudView {
    Phase phase = Phase::kPlay;
    float width = 0.0F;
    float height = 0.0F;
    std::optional<gui::Pointer> pointer;
    HudScene scene;
    // Nhân vật của người chơi; nullptr thì khung nhân vật giữ chữ của layout.
    const hero::Hero* hero = nullptr;
    // Thời điểm của khung trên một đồng hồ đơn điệu: thanh máu trượt theo nó.
    std::chrono::milliseconds clock{0};
    // Ảnh của các fake object đã dựng (đầu 3D của người chơi). Rỗng thì ô chân dung dùng ảnh phẳng.
    std::span<const ViewPaint> views;
    // Ký tự gõ từ bàn phím kể từ khung trước, theo thứ tự (kể cả xoá lùi, Tab, Enter); thủ tục đăng
    // nhập đưa chúng cho ô đang nhận phím.
    std::span<const char32_t> typed;
    // Nấc lăn chuột dồn từ khung trước. Ô mô tả môn phái đang trỏ thì nhận số này.
    std::int32_t wheel = 0;
    // Có khi màn chơi đang nạp một cảnh. Hết nạp thì rỗng để bảng chuyển cảnh được giấu.
    std::optional<SceneLoad> loading;
};

// Việc một nút của giao diện nhờ client làm ngoài giao diện (vào game, mở trang web, rời bảng).
using Action = panel::LogonAction;

// Nhấp trái lên bản đồ lớn: đi tự động tới điểm đó của cảnh người chơi đang đứng (AutoRunToTarget của
// SceneMap_GotoDirectly), đơn vị cảnh.
struct RunTo {
    float x = 0.0F;
    float z = 0.0F;
};

// Bảng tên cảnh của ngôn ngữ đang dựng. Thiếu tệp thì bảng rỗng và tên trả nguyên.
[[nodiscard]] gui::StringBook scene_names(const std::filesystem::path& data_root);

// Phần của Hud::open không cần thiết bị GPU: đọc đĩa và phân tích (bộ nạp giao diện, 40 layout, bảng chuỗi,
// bảng cảnh, bảng chân dung, dữ liệu hai phông). Chạy ở luồng riêng ngay khi start gọi, để trùng với việc tạo thiết bị
// GPU và nạp cảnh thay vì nối đuôi chúng; Hud::open nhận kết quả (chờ nếu chưa xong) rồi chỉ còn đưa phông lên GPU.
// Huỷ HudPrep khi chưa dùng thì chờ luồng đọc xong.
class HudPrep {
public:
    [[nodiscard]] static HudPrep start(const HudDesc& desc);

    HudPrep(HudPrep&&) noexcept;
    HudPrep& operator=(HudPrep&&) noexcept;
    HudPrep(const HudPrep&) = delete;
    HudPrep& operator=(const HudPrep&) = delete;
    ~HudPrep();

private:
    struct Work;
    explicit HudPrep(std::unique_ptr<Work> work) noexcept;
    std::unique_ptr<Work> work_;
    friend class Hud;
};

class Hud {
public:
    // Lỗi khi thiếu scheme, looknfeel, imageset hay layout của HUD. pass phải sống lâu hơn Hud.
    [[nodiscard]] static core::Result<Hud> open(render::UiPass& pass, const HudDesc& desc);
    // Như trên, nhưng dùng phần đọc đĩa đã bắt đầu từ trước (HudPrep::start với cùng desc).
    [[nodiscard]] static core::Result<Hud> open(render::UiPass& pass, const HudDesc& desc, HudPrep prep);

    Hud(Hud&&) noexcept;
    Hud& operator=(Hud&&) noexcept;
    Hud(const Hud&) = delete;
    Hud& operator=(const Hud&) = delete;
    ~Hud();

    // Dàn trang lại khi cần và dựng đỉnh cho khung. Gọi ngoài begin_rendering.
    void prepare(const HudView& view);

    // Quad vẽ thêm cùng lượt HUD (bảng nhịp). Rỗng thì chỉ vẽ giao diện.
    struct HudExtra {
        std::span<const render::UiVertex> vertices;
        std::span<const render::UiBatch> batches;
    };

    // Ghi lệnh vẽ HUD vào list, giữa begin_rendering và end_rendering, sau các lượt vẽ 3D.
    [[nodiscard]] core::Status draw(gpu::CommandList& list, std::uint32_t slot, HudExtra extra);

    // Điểm ảnh có nằm trên một cửa sổ của HUD không (theo lần prepare gần nhất): có thì cú bấm
    // thuộc về giao diện, không xuống thế giới.
    [[nodiscard]] bool contains(float across, float down) const;
    // Điểm có nằm trên ô mô tả môn phái đang cuộn được không. Có thì lăn chuột thuộc về ô đó.
    [[nodiscard]] bool takes_wheel(float across, float down) const;
    // Việc lần nhấn hay phím gần nhất nhờ client làm (theo lần prepare gần nhất); lấy rồi thì hết.
    [[nodiscard]] std::optional<Action> take_action() noexcept;
    // Điểm mà lần nhấp gần nhất trên bản đồ lớn nhờ đi tới; lấy rồi thì hết.
    [[nodiscard]] std::optional<RunTo> take_run_to() noexcept;
    // Tốc độ xoay người mẫu của bảng nhân vật theo đối số RotateBeginEx của script (âm là sang trái, 0 là
    // không giữ nút xoay): client đổi ra góc cho ảnh toàn thân.
    [[nodiscard]] float equip_spin() const noexcept;
    // Nạp máy chủ của lần vào game trước từ chữ tệp đã đọc (chuỗi rỗng là chưa có); chữ sai dạng hay
    // máy chủ không còn trong danh sách thì bỏ. Gọi sau khi mở Hud.
    bool recall_last_server(std::string_view text);
    // Chữ tệp khi máy chủ lần vào game trước đổi; không có khi chưa cần ghi.
    [[nodiscard]] std::optional<std::string> last_server_text() const;
    // Ghi đĩa xong.
    void mark_last_server_saved() noexcept;
    // Nạp sổ nhân vật từ chữ TSV đã đọc. Chuỗi rỗng là sổ trống.
    [[nodiscard]] bool recall_roles(std::string_view text);
    // Chữ TSV khi sổ đổi; không có khi chưa cần ghi.
    [[nodiscard]] std::optional<std::string> roles_text() const;
    // Ghi sổ ra đĩa xong.
    void mark_roles_saved() noexcept;
    // Nhân vật sẽ vào game; không có khi chưa chọn.
    [[nodiscard]] const panel::Role* entering_role() const noexcept;
    // Người mẫu của bảng chọn hay màn tạo ở khung vừa prepare.
    [[nodiscard]] const panel::ShownModel& role_model() const noexcept;

    // Số quad của khung vừa prepare, và số quad bỏ vì texture thiếu từ lúc mở.
    [[nodiscard]] std::size_t quad_count() const noexcept;
    [[nodiscard]] std::size_t missing_count() const noexcept;

private:
    struct State;

    explicit Hud(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::ui
