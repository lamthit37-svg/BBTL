// Cầu nối từ dàn trang (gui::Hub) sang đỉnh và lô của lượt vẽ 2D (render::UiPass). Mỗi khung gom
// ba danh sách của Hub theo lớp (cửa sổ gốc): ảnh tĩnh, ảnh động rồi chữ của một gốc vẽ xong mới
// tới gốc kế, nên bảng mở sau đè trọn lên bảng dưới nó. Ô nguồn theo điểm ảnh đổi sang toạ độ ảnh
// 0..1; quad liền nhau cùng texture gom thành một lô; texture gốc tải lên GPU khi gặp lần đầu.
// Texture của asset là tên Imagefile gốc ("Common/Button.dds"), mở đúng tệp đó dưới Interface.
// Quad ảnh cảnh (kSceneMap) vẽ bằng atlas minimap của PaintKit; quad tròn (LookLikeRound) thành
// quạt 16 tam giác, ghép đôi thành 8 quad có chung đỉnh tâm.
// Nguồn: bản mới của dự án, tương ứng pc_hud.cpp của TLBB Dev (bgfx) ở phần đưa quad lên thiết bị.
#pragma once

#include "gui/asset.hpp"
#include "gui/sheet.hpp"
#include "render/ui.hpp"
#include "ui/text.hpp"
#include "ui/view.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <vector>

namespace game::ui {

// Ba danh sách của một khung của Hub; mỗi danh sách đã xếp theo lớp tăng dần.
struct FrameParts {
    std::span<const gui::Quad> still;
    std::span<const gui::Quad> live;
    std::span<const gui::TextRun> texts;
};

// Ảnh minimap của khung: texture trong UiPass và phép đổi toạ độ ảnh cả cảnh sang toạ độ atlas.
struct MapPaint {
    std::uint32_t texture = render::kUiWhite;
    // Toạ độ atlas của góc (0, 0) của ảnh cả cảnh, và độ dài atlas ứng với cả ảnh trên mỗi trục.
    float origin_u = 0.0F;
    float origin_v = 0.0F;
    float scale_u = 1.0F;
    float scale_v = 1.0F;
};

// Những thứ ngoài GuiAsset mà một khung cần: bộ viết chữ cùng texture phông, ảnh minimap và ảnh
// của các fake object. Thiếu thứ nào thì phần đó không vẽ.
struct PaintKit {
    TextWriter* writer = nullptr;
    std::uint32_t font_texture = render::kUiWhite;
    // Phông thứ hai (Việt, có dấu): run có chữ tiếng Việt có dấu mà phông này vẽ trọn được thì vẽ bằng nó.
    TextWriter* alt_writer = nullptr;
    std::uint32_t alt_font_texture = render::kUiWhite;
    std::optional<MapPaint> map;
    // Ảnh bản đồ lớn (quad kSceneBoard): atlas riêng, cùng cách đổi toạ độ như map.
    std::optional<MapPaint> board;
    // Ảnh nền bản đồ thế giới (quad kWorldBoard): texture riêng, uv là phần của ảnh nguyên.
    std::optional<MapPaint> world;
    std::span<const ViewPaint> views;
};

class Painter {
public:
    // pass và thư mục root (CLIENT/data/Interface) phải sống lâu hơn Painter.
    Painter(render::UiPass& pass, std::filesystem::path root);

    // Dựng lại đỉnh và lô của khung. Gọi ngoài begin_rendering vì có thể tải texture. Texture không
    // tải được thì quad của nó bị bỏ và đếm vào missing().
    void build(const gui::GuiAsset& asset, const FrameParts& parts, const PaintKit& kit);

    [[nodiscard]] std::span<const render::UiVertex> vertices() const noexcept { return vertices_; }
    [[nodiscard]] std::span<const render::UiBatch> batches() const noexcept { return batches_; }
    // Số quad đã bỏ vì texture thiếu hay hỏng, cộng dồn từ lúc tạo.
    [[nodiscard]] std::size_t missing() const noexcept { return missing_; }

private:
    // Texture đã tải: chỉ số trong UiPass và cỡ điểm ảnh; id kUiWhite khi tải hỏng (đã đếm).
    struct Loaded {
        std::uint32_t id = render::kUiWhite;
        float width = 1.0F;
        float height = 1.0F;
        bool is_ok = false;
    };

    // Vị trí đang đọc trong ba danh sách của khung.
    struct Cursor {
        std::size_t still = 0;
        std::size_t live = 0;
        std::size_t text = 0;
    };

    // Đầu vào của một lượt build.
    struct Job {
        const gui::GuiAsset* asset = nullptr;
        const FrameParts* parts = nullptr;
        const PaintKit* kit = nullptr;
    };

    // Một lô đang mở: texture của nó, đỉnh đầu tiên và mặt nạ (kUiWhite là không có).
    struct Open {
        std::uint32_t texture = render::kUiWhite;
        std::size_t first_vertex = 0;
        std::uint32_t mask = render::kUiWhite;
        render::UiRect mask_box{};
    };

    [[nodiscard]] const Loaded& texture_of(const gui::GuiAsset& asset, std::int32_t index);
    [[nodiscard]] Loaded load(const std::string& name);
    void add_layer(const Job& job, Cursor& cursor);
    void add_quad(const Job& job, const gui::Quad& quad);
    void add_image(const gui::GuiAsset& asset, const gui::Quad& quad);
    void add_map(const gui::Quad& quad, const MapPaint& map);
    void add_view(const Job& job, const gui::Quad& quad);
    [[nodiscard]] std::optional<Open> open_for(const gui::GuiAsset& asset, const gui::Quad& quad);
    void add_text(const Job& job, const gui::TextRun& run);
    void close_batch(Open open);

    render::UiPass* pass_;
    std::filesystem::path root_;
    std::map<std::string, Loaded, std::less<>> cache_;
    std::vector<render::UiVertex> vertices_;
    std::vector<render::UiBatch> batches_;
    std::size_t missing_ = 0;
};

} // namespace game::ui
