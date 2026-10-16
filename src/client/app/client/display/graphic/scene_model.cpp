/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/scene_model.cpp
 *  PHÂN HỆ   : Display / Graphic / SceneModel
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Object Model có xương của cảnh (quạ bay và quạ đậu ở màn đăng nhập): nạp lưới, frame và
 *    skeleton một lần khi cảnh đổi, dựng tư thế rồi thêm instance mỗi khung (xem
 *    avatar/ambient.hpp). Lưới hay xương hỏng thì vật thể đó bị bỏ, ghi log một lần.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"

#include "avatar/ambient.hpp"
#include "client/display/graphic/prelude.hpp"
#include "client/stage/stage.hpp"
#include "io/file.hpp"
#include "render/forward.hpp"
#include "scene/transform.hpp"

#include <chrono>
#include <filesystem>
#include <print>
#include <string>
#include <utility>

namespace game::client {
namespace {

// Tệp của vật thể: frame nằm cạnh tệp .model, skeleton ở gốc Model theo tên lưới.
[[nodiscard]] avatar::AmbientFiles files_of(const std::filesystem::path& data_root,
    const Ambient& item) {
    const std::filesystem::path model_root = data_root / "Model";
    const std::filesystem::path model_file = io::path_from_utf8(item.model);
    std::filesystem::path stem = io::path_from_utf8(item.mesh).filename();
    stem.replace_extension();
    avatar::AmbientFiles files;
    files.frame = model_root / model_file.parent_path() / io::path_from_utf8(item.frame + ".glb");
    files.skeleton = model_root / stem;
    files.skeleton += ".skeleton.glb";
    files.node = item.node;
    return files;
}

} // namespace

void Display::State::add_scene_model(const Ambient& item) {
    const render::Drawable* drawable = load_creature_mesh(item.mesh, nullptr);
    if (drawable == nullptr) return;
    auto motion = avatar::Ambient::load(files_of(data_root, item));
    if (!motion) {
        std::println(stderr, "Vật thể {}: {}", item.mesh, motion.error());
        return;
    }
    SceneModel made{.motion = std::move(*motion), .drawable = drawable, .placed = {}};
    made.placed = world_of(scene::world_transform(item.placement));
    scene_models.push_back(std::move(made));
}

void Display::State::ensure_scene_models() {
    if (scene_models_built || stage == nullptr || data_root.empty()) return;
    if (forward == nullptr || device == nullptr) return;
    scene_models_built = true;
    for (const Ambient& item : stage->ambients)
        add_scene_model(item);
}

void Display::State::append_scene_models() {
    const float seconds = std::chrono::duration<float>(frame_time - started).count();
    for (SceneModel& model : scene_models) {
        const core::Status posed = model.motion.update(seconds);
        if (!posed) continue;
        render::Instance instance;
        instance.drawable = model.drawable;
        instance.world = model.placed * model.motion.attach();
        instance.joints = model.motion.joints();
        frame_instances.push_back(instance);
    }
}

} // namespace game::client
