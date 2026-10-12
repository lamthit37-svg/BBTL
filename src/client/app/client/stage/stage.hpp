// Nội dung của một cảnh mà phần hiển thị cần để vẽ: các vật thể tĩnh (tên mesh và phép đặt), đèn
// directional, đèn điểm, màu ambient, sương của Enviroment và mặt TerrainLiquid. Trích từ
// scene::SceneFile; không biết gì về GPU hay tệp GLB, nên kiểm được bằng test và dùng được ở mọi
// cấu hình.
// Tên thuộc tính và mặc định của đèn theo LightObject của client 2026 (Render.dll, hàm dựng ở
// 0x108960): tầm 100000, cường độ 1, số mũ suy giảm 1. Bản 2026 chỉ còn "range", "intensity" và
// "attenuation"; "attenuation.linear", "attenuation.quadric" của tệp cảnh cũ không còn được đọc.
// Model của cảnh giữ tên tệp .model; world bung mesh. Đèn spot không có góc nón ở bản 2026
// nên đi cùng đèn điểm. Chưa lấy: Actor có xương, FakeLight, Projector. Địa hình ở client/map.
#pragma once

#include "scene/placement.hpp"
#include "scene/scene_file.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace game::client {

// Màu tuyến tính ba kênh, như số ghi trong tệp cảnh.
struct Rgb {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;

    [[nodiscard]] bool operator==(const Rgb&) const = default;
};

// Một vật thể tĩnh (StaticEntity) có mesh.
struct Prop {
    // Tên mesh như trong tệp cảnh, ví dụ "敦煌/敦煌山洞.mesh"; tệp GLB là Model/<tên>.glb.
    std::string mesh;
    scene::Placement placement;
};

// Một object Model. model là thuộc tính "model name", tương đối với thư mục Model.
struct Figure {
    std::string model;
    scene::Placement placement;
};

// Một đèn directional. direction là hướng tia sáng đi (từ đèn tới vật), theo quy ước của OGRE.
struct Sun {
    scene::Vector3 direction;
    Rgb colour;
    Rgb specular;
    // Thuộc tính "intensity": hệ số nhân màu diffuse (power scale của Ogre::Light).
    float power = 1.0F;
};

// Một đèn điểm. Độ sáng tại khoảng cách d là (1 - d / range) mũ falloff, kẹp trong 0..1.
struct Lamp {
    scene::Vector3 position;
    Rgb colour;
    float range = 100000.0F;
    float falloff = 1.0F;
    float power = 1.0F;
};

// Kiểu sương, đúng thứ tự Ogre::FogMode: shader gốc dùng số này chọn công thức.
enum class FogMode : std::uint8_t { kNone, kExp, kExp2, kLinear };

// Sương của Enviroment. Mặc định là bộ số Render.dll đặt lại khi cảnh không có Enviroment.
struct Fog {
    FogMode mode = FogMode::kNone;
    Rgb colour{.red = 1.0F, .green = 1.0F, .blue = 1.0F};
    float density = 0.001F;
    float start = 0.0F;
    float end = 1.0F;
};

// Hạt đứng một mình, hoặc effect (nhiều hệ hạt). Tên là tên trong script.
struct FxPlace {
    std::string name;
    scene::Placement placement;
    bool is_effect = false;
};

// Một dải vòm trời. pitch 0 là đỉnh, pi/2 là chân trời. repeats là số lần ảnh quấn quanh.
struct SkyBand {
    std::string texture;
    float pitch_start = 0.0F;
    float pitch_end = 0.0F;
    int repeats = 1;
    bool blends = false;
};

// Một mặt TerrainLiquid. Không có bán kính trong tệp: mặt lan theo độ cao địa hình.
struct Liquid {
    std::string material;
    scene::Vector3 position;
    float texture_scale = 1.0F;
};

// Một mốc EnvKey của .skysphere (client/stage/sky đọc): môi trường của cảnh tại thời điểm time,
// tính bằng phần của một ngày (0 là nửa đêm, 0,5 là giữa trưa). Mặc định là giá trị hàm dựng EnvKey
// của bản gốc (Render.dll 0xE6B80): màu đen, riêng ba màu của nhân vật xám 0,5, mọi cường độ 1.
struct DayKey {
    float time = 0.0F;
    Rgb ambient;
    Rgb fog;
    float fog_near = 0.0F;
    float fog_far = 0.0F;
    // Màu của lớp sương trên vòm trời.
    Rgb sky_fog;
    Rgb light_one;
    Rgb light_one_specular;
    Rgb light_two;
    Rgb light_two_specular;
    // Ánh sáng riêng của nhân vật (LogicModel); vật thể tĩnh và địa hình dùng light_one, light_two.
    Rgb actor_one{.red = 0.5F, .green = 0.5F, .blue = 0.5F};
    Rgb actor_two{.red = 0.5F, .green = 0.5F, .blue = 0.5F};
    Rgb actor_ambient{.red = 0.5F, .green = 0.5F, .blue = 0.5F};
    float light_one_power = 1.0F;
    float light_two_power = 1.0F;
    float actor_one_power = 1.0F;
    float actor_two_power = 1.0F;
};

struct Stage {
    // Theo đúng thứ tự StaticEntity trong tệp cảnh; vật thể không có "mesh name" bị bỏ.
    std::vector<Prop> props;
    // Object type Model, đúng thứ tự tệp. Mesh nằm trong XML .model, world mới bung ra props.
    std::vector<Figure> figures;
    // Đèn mang tên "#FairyMainLightOne" đứng đầu, "#FairyMainLightTwo" đứng thứ hai (thứ tự Ogre
    // trao cho shader); đèn directional khác theo thứ tự tệp.
    std::vector<Sun> suns;
    std::vector<Lamp> lamps;
    std::vector<Liquid> liquids;
    std::vector<FxPlace> effects;
    Rgb ambient;
    Fog fog;
    // Màu nền khi cảnh không có sương; có sương thì nền là màu sương (Render.dll 0xE1150).
    Rgb background;
    // Bảng môi trường theo giờ của bầu trời, xếp theo time. Khác rỗng thì ambient, sương và màu
    // đèn chính lấy từ bảng này (day_at) thay số ghi ở trên. stage_of để rỗng; nơi nạp cảnh điền.
    std::vector<DayKey> days;
    // Các dải có ảnh của thời tiết đang dùng. Rỗng khi cảnh không có bầu trời.
    std::vector<SkyBand> sky;
};

// Nội dung cần vẽ của một tệp cảnh đã đọc.
[[nodiscard]] Stage stage_of(const scene::SceneFile& file);

// Thuộc tính mesh của mọi phần tử entity trong XML .model. Chuỗi rỗng và XML hỏng bị bỏ.
// Đường dẫn còn tương đối với thư mục của chính tệp .model.
[[nodiscard]] std::vector<std::string> model_meshes(std::string_view text);

} // namespace game::client
