// Ảnh nền của minimap. Client gốc (FalagardSceneMap::createBackground) cắt ảnh cảnh thành ô 256
// điểm ảnh, mỗi ô 64 đơn vị cảnh (4 điểm ảnh một đơn vị), tên jpg_<token>_<cột>_<hàng>, và chỉ
// nạp ô quanh người chơi. Ở đây vùng đang thấy nằm trong một atlas 2x2 ô (512x512): cửa sổ radar
// hẹp hơn một ô nên không bao giờ phủ quá hai ô mỗi chiều. Atlas chỉ ghép lại khi vùng thấy ra
// khỏi nó, nên bộ nhớ không phụ thuộc cỡ cảnh và mỗi lần đổi chỉ đẩy lại 1 MB.
// Khác bản port TLBB Dev (pc_hud.cpp ghép cả cảnh thành một ảnh): cảnh 1024 đơn vị ở đó tốn 64 MB
// và vượt cỡ texture của GPU điện thoại.
#pragma once

#include "gui/sheet.hpp"
#include "resource/image.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui {

// Cạnh một ô ảnh và số ô mỗi chiều của atlas minimap.
inline constexpr int kRadarTilePixels = 256;
inline constexpr int kRadarAtlasTiles = 2;
// Số ô đã giải mã giữ lại: đủ cho atlas đang dùng và atlas vừa rời.
inline constexpr std::size_t kRadarKeptTiles = 8;

// Hình dạng một atlas: số ô mỗi chiều, và độ thu nhỏ (1, 2 hay 4: mỗi ô còn 256/shrink điểm ảnh, vùng phủ
// không đổi). Atlas minimap là 2x2 ô nguyên; bản đồ lớn cần nhiều ô hơn và thu nhỏ khi xem cả cảnh.
struct AtlasShape {
    int across = kRadarAtlasTiles;
    int down = kRadarAtlasTiles;
    int shrink = 1;
    std::size_t kept = kRadarKeptTiles;

    friend constexpr bool operator==(const AtlasShape&, const AtlasShape&) = default;
};

// Vùng đang thấy của một cảnh: token szSceneMap, cỡ cảnh theo đơn vị cảnh, và phần ảnh cả cảnh
// (0..1) mà cửa sổ radar hiện.
struct RadarAim {
    std::string_view token;
    float scene_width = 0.0F;
    float scene_depth = 0.0F;
    gui::Radar view;
};

class RadarAtlas {
public:
    // data_root là thư mục dữ liệu client; ô ảnh nằm theo gui::radar_tile_path dưới đó.
    explicit RadarAtlas(std::filesystem::path data_root, AtlasShape shape = {});

    [[nodiscard]] const AtlasShape& shape() const noexcept { return shape_; }

    // Ngắm vùng thấy. true khi ảnh atlas đổi và phải đẩy lại lên GPU.
    [[nodiscard]] bool aim(const RadarAim& seen);

    // Có ít nhất một ô của atlas hiện tại nạp được.
    [[nodiscard]] bool has_image() const noexcept { return filled_ > 0; }
    [[nodiscard]] const resource::Image& image() const noexcept { return atlas_; }
    // Đổi toạ độ ảnh cả cảnh (0..1) sang toạ độ ảnh trong atlas.
    [[nodiscard]] gui::Radar to_atlas(const gui::Radar& whole) const noexcept;
    // Số lần đọc tệp ô ảnh từ lúc tạo, để đo bộ đệm.
    [[nodiscard]] std::size_t reads() const noexcept { return reads_; }

private:
    struct Tile {
        int column = 0;
        int row = 0;
        std::uint64_t used = 0;
        // Rỗng khi tệp thiếu hay hỏng: ô đó trong suốt.
        std::vector<std::uint8_t> rgba;
    };

    // Ô ở góc trái trên của atlas.
    struct Origin {
        int column = 0;
        int row = 0;
        friend bool operator==(const Origin&, const Origin&) = default;
    };

    void reset(const RadarAim& seen);
    [[nodiscard]] bool covers(const RadarAim& seen) const noexcept;
    [[nodiscard]] Origin origin_for(const RadarAim& seen) const noexcept;
    // Chỗ của một ô trong atlas: cột và hàng tính từ góc trái trên của atlas.
    struct Slot {
        int across = 0;
        int down = 0;
    };

    void stitch();
    void place(Origin origin, Slot slot);
    [[nodiscard]] const Tile& tile_at(int column, int row);
    [[nodiscard]] Tile load(int column, int row);

    std::filesystem::path root_;
    AtlasShape shape_;
    std::string token_;
    float scene_width_ = 0.0F;
    float scene_depth_ = 0.0F;
    int columns_ = 0;
    int rows_ = 0;
    std::optional<Origin> origin_;
    resource::Image atlas_;
    std::vector<Tile> tiles_;
    std::uint64_t clock_ = 0;
    std::size_t reads_ = 0;
    int filled_ = 0;
};

} // namespace game::ui
