/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/scene.hpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dữ liệu và bộ đọc tệp .EnScene: vùng (EnRegion), vòm trời, lớp mây, lớp mây
 *    vòng, sao, trăng, mặt trời, hiệu ứng và bảng môi trường theo giờ (EnvKey).
 *  - Tệp là XML UTF-8 hoặc GBK (tên ảnh tiếng Hán); đọc hỏng UTF-8 thì giải GBK.
 *    Phần tử vắng nhận giá trị mặc định của hàm dựng trong Render.dll (0 hoặc
 *    tắt), không phải lỗi: 6 lớp mây thật không khai turnoverMesh.
 *  - Nguồn: Render.dll 2026 (EnSky, EnDome, EnCloud, EnRingCloud, EnMoon, EnSun),
 *    xem docs/TAILIEU/EN-SCENE-RENDER-DLL.md.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ogre/vec3.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::ensky {

struct Colour {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;
};

// Vòm trời. height cộng vào y của đỉnh (trước khi chiếu), power là số mũ tán xạ tới.
struct Dome {
    std::string texture;
    // Rỗng: dùng lại texture (mọi tệp thật chỉ khai texture).
    std::string texture_ex;
    float height = 0.0F;
    float mie_amount = 0.0F;
    float vertex_height_effect = 0.0F;
    float sun_height_effect = 0.0F;
    float power = 1.0F;
};

// Sáng cạnh mây: sáng tán xạ theo hướng mặt trời và viền sáng ở mép dày.
struct Rim {
    float scatter_strength = 0.0F;
    float scatter_power = 0.0F;
    float strength = 0.0F;
    float power = 0.0F;
    float detect_power = 0.0F;
    float detect_width = 0.0F;
};

struct CloudKey {
    float time = 0.0F;
    float fog = 0.0F;
    float alpha = 0.0F;
    float speed = 0.0F;
    float ambient_blend = 0.0F;
};

// Lớp mây trên đỉnh (SkyCloudsLayer, EnCloud). tile.z do mã ghi đè mỗi khung (height * 15).
struct CloudLayer {
    std::string name;
    int layer = 0;
    bool is_flipped = false;
    float height = 0.0F;
    std::string mesh;
    std::string texture;
    float yaw = 0.0F;
    std::array<float, 4> tile{};
    Rim rim;
    std::vector<CloudKey> keys;
};

struct RingKey {
    float time = 0.0F;
    float fog_blend = 0.0F;
    float ambient_blend = 0.0F;
    float alpha = 0.0F;
    float roll_speed = 0.0F;
    float vertical_speed = 0.0F;
    float fade_range = 0.0F;
};

// Lớp mây vòng quanh chân trời (RingCloudsLayer, EnRingCloud).
struct RingLayer {
    std::string name;
    int layer = 0;
    bool is_flipped = false;
    float height = 0.0F;
    float scale = 1.0F;
    float repeat = 1.0F;
    float offset = 0.0F;
    float parallax = 0.0F;
    std::string mesh;
    std::string texture;
    Rim rim;
    std::vector<RingKey> keys;
};

struct Star {
    bool is_enabled = false;
    int count = 0;
    float radius = 0.0F;
    float intensity = 0.0F;
    float size = 0.0F;
    float flicker_speed = 0.0F;
    std::array<float, 4> start_colour{};
    std::array<float, 4> end_colour{};
    bool is_fixed = false;
};

struct Moon {
    bool is_enabled = false;
    std::string texture;
    float scale = 1.0F;
    float orient = 0.0F;
    float angle = 0.0F;
    float up_time = 0.0F;
    float down_time = 0.0F;
    bool is_fixed = false;
    int layer = 0;
};

struct Sun {
    bool is_enabled = false;
    std::string texture;
    bool uses_flare = false;
    std::string flare_texture;
    float scale = 1.0F;
    float orient = 0.0F;
    float angle = 0.0F;
    float up_time = 0.0F;
    float down_time = 0.0F;
    float intensity_step = 0.0F;
    bool is_fixed = false;
    std::string lens_flare;
    bool uses_lens_flare = false;
    int layer = 0;
};

// Một mốc môi trường (LightAndFog/EnvKey). Hướng (0 0 0) nghĩa là giữ hướng của tệp .Scene.
struct EnvKey {
    float time = 0.0F;
    Colour ambient;
    Colour fog;
    float fog_near = 0.0F;
    float fog_far = 0.0F;
    Colour light_one;
    Colour light_one_specular;
    ogre::Vec3 light_one_direction;
    float light_one_intensity = 1.0F;
    Colour light_two;
    Colour light_two_specular;
    ogre::Vec3 light_two_direction;
    float light_two_intensity = 1.0F;
    Colour actor_one;
    float actor_one_intensity = 1.0F;
    Colour actor_two;
    float actor_two_intensity = 1.0F;
    Colour actor_ambient;
    Colour dome_ambient{.red = 1.0F, .green = 1.0F, .blue = 1.0F};
    float dome_strength = 1.0F;
    // Sương chiều cao (height_fog_enabled, height_fog_param). Mười sáu số theo thứ tự chuỗi: màu (4),
    // màu tán xạ (4), mật độ, độ cao, độ giảm theo cao, mũ, mật độ theo sâu, độ giảm theo sâu, điểm
    // bắt đầu theo sâu, mũ tán xạ. Render.dll 0x1801e8130 chỉ bật bộ hậu kỳ HeightFog khi cờ bật.
    bool has_height_fog = false;
    std::array<float, 16> height_fog{};
};

// Một khối EnSky: trọn bầu trời của một vùng.
struct Sky {
    Dome dome;
    std::vector<CloudLayer> clouds;
    std::vector<RingLayer> rings;
    Star star;
    Moon moon;
    Sun sun;
    std::vector<std::string> effects;
    std::vector<EnvKey> env;
};

struct Point {
    float x = 0.0F;
    float z = 0.0F;
};

// EnRegion. Tệp không có EnRegionComposite thì có đúng một vùng tên "backgroud", không đa giác.
struct Region {
    std::string name;
    float max_distance = 0.0F;
    std::vector<std::vector<Point>> polygons;
    Sky sky;
};

struct Scene {
    std::vector<Region> regions;
};

enum class Fault : std::uint8_t { kBadText, kBadXml, kNotScene, kNoSky };

// Đọc cả tệp .EnScene (byte thô, UTF-8 hoặc GBK).
[[nodiscard]] std::expected<Scene, Fault> read_scene(std::string_view bytes);

// Mọi ảnh và mesh mà cảnh nêu, không trùng, theo thứ tự gặp: dùng cho bộ gom tài nguyên và nạp
// trước.
[[nodiscard]] std::vector<std::string> textures_of(const Scene& scene);
[[nodiscard]] std::vector<std::string> meshes_of(const Scene& scene);

} // namespace game::ensky
