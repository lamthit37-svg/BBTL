// Hạt và dải của cảnh, cộng mesh hiệu ứng đã nhận material hạt.
#include "client/display/graphic/state.hpp"
namespace game::client {

void Display::State::say_fx_fault() {
    if (fx_fault_noted || catalog == nullptr) return;
    const core::Error* fault = catalog->fault(render::Pso::kFx);
    if (fault == nullptr) return;
    fx_fault_noted = true;
    std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ: {}", *fault);
}

void Display::State::open_fx() {
    if (fx_view || catalog == nullptr || device == nullptr) return;
    const gpu::PipelineHandle pipeline = catalog->get(render::Pso::kFx);
    if (!pipeline) return say_fx_fault();
    const gpu::PipelineHandle blend = catalog->get(render::Pso::kFxBlend);
    fx_view = FxView::open(*device, pipeline, blend);
    if (!fx_view) return;
    fx_view->load(data_root);
    if (stage != nullptr) fx_view->adopt(*stage);
}

void Display::State::advance_fx(float elapsed) {
    if (!fx_view) return;
    const float raw = elapsed - fx_stamp;
    const float step = fx_stamp < 0.0F ? 0.016F : std::min(raw, kMaxStep);
    fx_stamp = elapsed;
    fx_view->advance(step);
}

namespace {

[[nodiscard]] math::Quat fx_quat(ogre::Quat value) {
    return {value.x, value.y, value.z, value.w};
}

[[nodiscard]] math::Vector3 fx_vec(ogre::Vec3 value) {
    return {value.x, value.y, value.z};
}

// [R | t] rồi nhân scale: T * R * S, đúng nút OGRE.
[[nodiscard]] math::Matrix4 fx_placed(ogre::Vec3 position, ogre::Quat orientation, ogre::Vec3 scale) {
    const math::Transform3 spin(fx_quat(orientation), fx_vec(position));
    return math::Matrix4(spin) * math::Matrix4::scale(fx_vec(scale));
}

} // namespace

std::size_t Display::State::fx_mesh_slot(const fx::Field& field) {
    if (field.definition().renderer != fx::RendererKind::kMesh) return kMissing;
    if (field.definition().mesh_name.empty() || fx_view == nullptr) return kMissing;
    const fx::Paint* paint = fx_view->paint(field.definition().material);
    if (paint == nullptr || paint->blend != fx::Blend::kAlpha) return kMissing;
    return load_painted_mesh(field.definition().mesh_name, field.definition().material, *paint);
}

void Display::State::push_fx_field(const fx::Field& field, std::size_t slot) {
    if (slot == kMissing) return;
    const fx::Node& node = field.node();
    const math::Matrix4 parent = fx_placed(node.position, node.orientation, node.scale);
    const render::Drawable& drawable = kept.at(slot).loaded.drawable;
    for (const fx::MeshPose& pose : fx::mesh_poses(field)) {
        render::Instance instance;
        instance.drawable = &drawable;
        instance.world = parent * fx_placed(pose.position, pose.orientation, pose.scale);
        frame_instances.push_back(instance);
    }
}

void Display::State::append_fx_meshes() {
    if (!fx_view) return;
    const std::vector<const fx::Field*> live = fx_view->fields();
    std::vector<std::size_t> slots;
    slots.reserve(live.size());
    for (const fx::Field* field : live) {
        slots.push_back(fx_mesh_slot(*field));
    }
    for (std::size_t index = 0; index < live.size(); ++index) {
        push_fx_field(*live[index], slots[index]);
    }
}

void Display::State::draw_fx(const FxAsk& ask) const {
    if (!fx_view) return;
    fx_view->draw(*ask.list, ask.slot, *ask.camera);
}
} // namespace game::client
