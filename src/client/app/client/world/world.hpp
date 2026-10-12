// Một cảnh đang chơi, theo client gốc: enter(resid) xoá cảnh cũ và nạp đúng một file .Scene
// trong SceneDefineEx. Phần vẽ giữ shared_ptr nên có thể đổi trong lúc cửa sổ còn mở.
#pragma once

#include "client/map/book.hpp"
#include "client/map/ground.hpp"
#include "client/stage/stage.hpp"
#include "collision/model.hpp"
#include "nav/mesh.hpp"
#include "nav/route.hpp"
#include "scene/scene_file.hpp"

#include <cstddef>
#include <expected>
#include <filesystem>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

namespace game::client::world {

enum class [[nodiscard]] EnterError : std::uint8_t {
    kUnknownScene,
    kMissingFile,
    kBadXml,
};

enum class [[nodiscard]] EnterCode : std::uint8_t {
    kLoaded,
    kSame,
};

// Số cảnh giữ trong bộ nhớ. Đổi lại một resid trong số này không đọc lại đĩa.
inline constexpr std::size_t kRemembered = 4;

// Cảnh vừa nạp. ground rỗng khi cảnh không có .Terrain hoặc tệp địa hình hỏng. walk là lưới đi của
// cảnh (tệp .path cạnh tệp cảnh) kèm cỡ cảnh: rỗng khi bảng không ghi tệp, tệp không có trong kho
// hay tệp hỏng (walk_error ghi lý do); khi đó nhân vật không bị vật cản nào chặn.
struct ShownScene {
    int id = 0;
    std::string name;
    std::string scene_file;
    // Token ảnh minimap (szSceneMap) và cỡ cảnh theo đơn vị cảnh, lấy từ bảng cảnh.
    std::string radar;
    int x_size = 0;
    int z_size = 0;
    // Mặt cắt xa và gần của camera cảnh, đơn vị thế giới (cột 16 và 17 của bảng cảnh).
    int far_clip = map::kDefaultFarClip;
    int near_clip = map::kDefaultNearClip;
    scene::SceneFile scene;
    Stage stage;
    // Mặt công trình của cảnh, đơn vị game. Rỗng khi không có tệp .WCollision hoặc tệp hỏng.
    std::optional<collision::Model> buildings;
    std::optional<map::Ground> ground;
    std::optional<map::MapError> terrain_error;
    std::optional<nav::Field> walk;
    std::optional<nav::MeshError> walk_error;
};

struct World {
    map::Book book;
    std::shared_ptr<const ShownScene> current;
    // Mới nhất ở cuối. enter và current_scene giữ guard khi đọc hoặc ghi hai trường này.
    std::vector<std::shared_ptr<const ShownScene>> remembered;
    // Con trỏ để World vẫn chuyển được: mutex không chuyển.
    std::unique_ptr<std::mutex> guard = std::make_unique<std::mutex>();
};

using EnterResult = std::expected<EnterCode, EnterError>;

// `text` là SceneDefineEx.txt. Thư mục cảnh là data/Scene.
[[nodiscard]] std::expected<World, map::BookError> open_world(std::string_view text);

// Đọc .skysphere cạnh tệp cảnh và ghi mốc đèn cùng các dải ảnh vào stage. Thiếu tệp thì bỏ qua.
void attach_sky_file(Stage& stage, const std::filesystem::path& scene_folder, std::string_view sky_file);

// Đọc từng tệp .model mà stage.figures nêu và thêm mesh entity vào props. data_root chứa Model/.
// Thiếu tệp thì bỏ qua figure đó. Mesh trỏ ra ngoài Model/ bị bỏ.
void attach_models(Stage& stage, const std::filesystem::path& data_root);

// Nạp Scene/<tệp cảnh đổi đuôi .WCollision> vào slot. Thiếu tệp thì slot rỗng, không in.
void attach_buildings(std::optional<collision::Model>& slot, const std::filesystem::path& scene_folder,
    std::string_view scene_file);

// Nạp resid. Cùng id với cảnh đang chạy thì không nạp lại. Cảnh vừa vào nằm trong remembered.
[[nodiscard]] EnterResult enter(World& world, int id, const std::filesystem::path& scene_folder);

// Bản sao của cảnh đang chạy. Luồng cửa sổ đọc trong lúc luồng khác đang enter.
[[nodiscard]] std::shared_ptr<const ShownScene> current_scene(const World& world);

// Số trong Config/startup.id, nếu tệp có một resid hợp lệ.
[[nodiscard]] std::optional<int> file_resid(const std::filesystem::path& data_root);

[[nodiscard]] std::string_view describe(EnterError error) noexcept;

// Một dòng tiếng Việt cho log về lưới đi của cảnh: số đỉnh, tam giác và cạnh vật cản, hoặc vì sao
// cảnh không có lưới đi.
[[nodiscard]] std::string describe_walk(const ShownScene& shown);

} // namespace game::client::world
