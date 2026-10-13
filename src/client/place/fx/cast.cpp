// Cửa xét trước khi dựng: tên có trong thư viện, bộ đọc hiểu hết affector và element, renderer và
// material là thứ pipeline cộng sáng vẽ đúng. Bảng material đọc theo tên cột của dòng tiêu đề, nên
// bộ gom thêm cột thì bản client cũ vẫn đọc được; dòng hỏng bị bỏ chứ không làm client dừng.
#include "fx/cast.hpp"

#include "fx/billboard.hpp"
#include "fx/field.hpp"
#include "fx/script.hpp"
#include "fx/strip.hpp"
#include "fx/system.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <numeric>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::fx {
namespace {

[[nodiscard]] Node placed(const Node& parent, const ElementDef& element) {
    Node node;
    const ogre::Vec3 scaled = ogre::mul_vec3(parent.scale, element.position);
    node.position = ogre::add_vec3(parent.position, ogre::quat_rotate(parent.orientation, scaled));
    node.orientation = ogre::quat_multiply(parent.orientation, element.orientation);
    node.scale = parent.scale;
    return node;
}

[[nodiscard]] ogre::Vec3 world_point(const Node& node, ogre::Vec3 local) {
    const ogre::Vec3 scaled = ogre::mul_vec3(node.scale, local);
    return ogre::add_vec3(node.position, ogre::quat_rotate(node.orientation, scaled));
}

[[nodiscard]] ogre::Vec3 local_point(const Node& node, ogre::Vec3 world) {
    const ogre::Vec3 shifted = ogre::sub_vec3(world, node.position);
    const ogre::Vec3 turned = ogre::quat_rotate(ogre::quat_inverse(node.orientation), shifted);
    return ogre::div_vec3(turned, node.scale);
}

void lift_point(ChainSample& sample, const Node& node) {
    sample.position = world_point(node, sample.position);
}

// Bảng material: tên cột của dòng tiêu đề và các giá trị client hiểu.
constexpr std::string_view kNameColumn = "name";
constexpr std::string_view kImageColumn = "image";
constexpr std::string_view kBlendColumn = "blend";
constexpr std::string_view kGainColumn = "gain";
constexpr std::string_view kSecondColumn = "second";
constexpr std::string_view kScrollUColumn = "scroll_u";
constexpr std::string_view kScrollVColumn = "scroll_v";
constexpr std::string_view kShaderColumn = "shader";
constexpr std::string_view kExtraColumn = "extra";
constexpr std::string_view kAddBlend = "one one";
constexpr std::string_view kAlphaAddBlend = "src_alpha one";
// Hai giá trị của cột shader mà màu ra chỉ là ảnh nhân hệ số nhân màu đỉnh.
constexpr std::array<std::string_view, 2> kPlainShaders{"fixed", "particle"};

using Cells = std::vector<std::string_view>;

[[nodiscard]] Cells split(std::string_view text, char mark) {
    Cells cells;
    std::size_t begin = 0;
    while (begin <= text.size()) {
        const std::size_t found = text.find(mark, begin);
        const std::size_t end = found == std::string_view::npos ? text.size() : found;
        cells.push_back(text.substr(begin, end - begin));
        begin = end + 1;
    }
    return cells;
}

[[nodiscard]] std::string_view without_return(std::string_view line) noexcept {
    return line.ends_with('\r') ? line.substr(0, line.size() - 1) : line;
}

// Các ô của một dòng, tra theo tên cột của dòng tiêu đề. Cột bảng không có, hoặc dòng ngắn hơn
// tiêu đề, thì ô ấy rỗng.
struct Row {
    const Cells* header = nullptr;
    const Cells* cells = nullptr;

    [[nodiscard]] std::string_view cell(std::string_view column) const {
        const auto found = std::ranges::find(*header, column);
        const auto index = static_cast<std::size_t>(found - header->begin());
        const bool is_present = found != header->end() && index < cells->size();
        return is_present ? (*cells)[index] : std::string_view{};
    }
};

[[nodiscard]] Blend blend_of(std::string_view text) noexcept {
    if (text == kAddBlend) return Blend::kAdd;
    if (text == kAlphaAddBlend) return Blend::kAlphaAdd;
    if (text == "src_alpha one_minus_src_alpha") return Blend::kAlpha;
    if (text == "zero one_minus_src_colour") return Blend::kDarken;
    return Blend::kOther;
}

[[nodiscard]] bool is_still(std::string_view scroll) {
    const std::optional<float> speed = parse_float(scroll);
    return scroll.empty() || (speed && *speed == 0.0F);
}

// "scale 1.1 1.1" hoặc "scale 0.8 0.5; ..." trong cột extra. Thiếu số thì giữ 1.
void take_scale(Paint& paint, std::string_view extra) {
    constexpr std::string_view kMark = "scale ";
    const std::size_t at = extra.find(kMark);
    if (at == std::string_view::npos) return;
    std::string_view rest = extra.substr(at + kMark.size());
    const std::size_t gap = rest.find(' ');
    if (gap == std::string_view::npos) return;
    const std::optional<float> across = parse_float(rest.substr(0, gap));
    std::string_view down = rest.substr(gap + 1);
    const std::size_t end = down.find_first_of(" ;");
    if (end != std::string_view::npos) down = down.substr(0, end);
    const std::optional<float> along = parse_float(down);
    if (!across || !along) return;
    if (*across == 0.0F || *along == 0.0F) return;
    paint.scale_u = *across;
    paint.scale_v = *along;
}

[[nodiscard]] bool is_plain(const Row& row) {
    const bool is_single = row.cell(kSecondColumn).empty() && row.cell(kExtraColumn).empty();
    const bool is_fixed = is_still(row.cell(kScrollUColumn)) && is_still(row.cell(kScrollVColumn));
    const bool is_common = std::ranges::find(kPlainShaders, row.cell(kShaderColumn)) != kPlainShaders.end();
    return is_single && is_fixed && is_common;
}

using Paints = std::map<std::string, Paint, std::less<>>;

// Dòng thiếu tên hay hệ số màu không phải số dương thì bỏ: material ấy thành "không có trong bảng".
void take_paint(Paints& paints, const Row& row) {
    const std::string_view name = row.cell(kNameColumn);
    const std::optional<float> gain = parse_float(row.cell(kGainColumn));
    const bool is_usable = !name.empty() && gain && *gain > 0.0F;
    if (!is_usable) return;
    Paint paint;
    paint.image = std::string(row.cell(kImageColumn));
    paint.blend = blend_of(row.cell(kBlendColumn));
    paint.gain = *gain;
    paint.second = std::string(row.cell(kSecondColumn));
    if (const std::optional<float> along_u = parse_float(row.cell(kScrollUColumn))) paint.scroll_u = *along_u;
    if (const std::optional<float> along_v = parse_float(row.cell(kScrollVColumn))) paint.scroll_v = *along_v;
    take_scale(paint, row.cell(kExtraColumn));
    const std::string_view shader = row.cell(kShaderColumn);
    paint.is_common = std::ranges::find(kPlainShaders, shader) != kPlainShaders.end();
    paint.is_plain = is_plain(row);
    paints.try_emplace(std::string(name), std::move(paint));
}

void take_line(Paints& paints, const Cells& header, std::string_view line) {
    const Cells cells = split(without_return(line), '\t');
    const Row row{.header = &header, .cells = &cells};
    take_paint(paints, row);
}

// read_system và read_effect bỏ lặng khối con chúng không biết loại (system.cpp). Probe hỏi lại
// chúng từng khối con một của một khối cấp cao: khối nào không ra thứ gì là loại chưa hỗ trợ. Không
// chép danh sách loại ở đây, nên hai nơi không lệch nhau được.
struct Probe {
    const ScriptBlock* block = nullptr;

    // Bộ đọc nhận hay bỏ một khối con chỉ theo dòng tiêu đề của nó ("affector Rotator"), nên khối
    // thử chỉ mang dòng ấy, không chép thuộc tính.
    [[nodiscard]] ScriptBlock alone(const ScriptBlock& child) const {
        ScriptBlock lone;
        lone.head = block->head;
        lone.children.emplace_back();
        lone.children.back().head = child.head;
        return lone;
    }

    [[nodiscard]] bool loses_affector(const ScriptBlock& child) const {
        if (child.word(0) != "affector") return false;
        const SystemDef read = read_system(alone(child));
        return read.affectors.empty();
    }

    [[nodiscard]] bool loses_element(const ScriptBlock& child) const {
        if (child.word(0) != "element") return false;
        const EffectDef read = read_effect(alone(child));
        return read.elements.empty();
    }

    void take_affector(std::vector<std::string>& lost, const ScriptBlock& child) const {
        if (loses_affector(child)) lost.emplace_back(child.word(1));
    }
};

[[nodiscard]] std::vector<std::string> lost_affectors_of(const ScriptBlock& block) {
    const Probe probe{.block = &block};
    std::vector<std::string> lost;
    for (const ScriptBlock& child : block.children) {
        probe.take_affector(lost, child);
    }
    return lost;
}

[[nodiscard]] std::uint32_t lost_elements_of(const ScriptBlock& block) {
    const Probe probe{.block = &block};
    const auto is_lost = [&probe](const ScriptBlock& child) { return probe.loses_element(child); };
    return static_cast<std::uint32_t>(std::ranges::count_if(block.children, is_lost));
}

void take_live(std::vector<const Field*>& live, const Field& field) {
    if (!field.order().empty()) live.push_back(&field);
}

} // namespace

std::string_view describe(Skip skip) noexcept {
    switch (skip) {
    case Skip::kUnknownName: return "tên không có trong thư viện";
    case Skip::kUnknownElement: return "element chưa hỗ trợ";
    case Skip::kUnknownAffector: return "affector chưa hỗ trợ";
    case Skip::kMeshRenderer: return "hạt mesh cần material hạt";
    case Skip::kNoMaterial: return "material không có trong bảng hoặc thiếu ảnh";
    case Skip::kShading: return "material cần ảnh thứ hai hoặc shader riêng";
    case Skip::kBlend: return "material không cộng sáng";
    }
    return "lý do không rõ";
}

std::uint32_t Tally::total_skipped() const noexcept {
    return std::accumulate(skipped.begin(), skipped.end(), std::uint32_t{0});
}

Palette::Palette(std::string_view table) {
    const Cells lines = split(table, '\n');
    const Cells header = split(without_return(lines.front()), '\t');
    for (const std::string_view line : std::span(lines).subspan(1)) {
        take_line(paints_, header, line);
    }
}

const Paint* Palette::find(std::string_view material) const {
    const auto found = paints_.find(material);
    return found == paints_.end() ? nullptr : &found->second;
}

Library::Library(LibraryText text)
    : particles_(std::move(text.particles), 0), effects_(std::move(text.effects), 1), palette_(text.materials) {}

const Library::KeptSystem* Library::kept_system(std::string_view name) {
    const auto found = systems_.find(name);
    if (found != systems_.end()) return found->second.get();
    const ScriptBlock* block = particles_.find(name);
    if (block == nullptr) return nullptr;
    auto kept = std::make_unique<KeptSystem>();
    kept->definition = read_system(*block);
    kept->lost = lost_affectors_of(*block);
    return systems_.emplace(std::string(name), std::move(kept)).first->second.get();
}

const Library::KeptEffect* Library::kept_effect(std::string_view name) {
    const auto found = effect_defs_.find(name);
    if (found != effect_defs_.end()) return found->second.get();
    const ScriptBlock* block = effects_.find(name);
    if (block == nullptr) return nullptr;
    auto kept = std::make_unique<KeptEffect>();
    kept->definition = read_effect(*block);
    kept->lost = lost_elements_of(*block);
    return effect_defs_.emplace(std::string(name), std::move(kept)).first->second.get();
}

const SystemDef* Library::system(std::string_view name) {
    const KeptSystem* kept = kept_system(name);
    return kept == nullptr ? nullptr : &kept->definition;
}

const EffectDef* Library::effect(std::string_view name) {
    const KeptEffect* kept = kept_effect(name);
    return kept == nullptr ? nullptr : &kept->definition;
}

std::optional<Skip> Library::refuse_material(std::string_view material) const {
    const Paint* found = palette_.find(material);
    if (found == nullptr || found->image.empty()) return Skip::kNoMaterial;
    if (found->blend == Blend::kOther) return Skip::kBlend;
    // Một ảnh, shader thường: cuộn UV và scale vẫn vẽ. Hai ảnh hoặc shader riêng thì bỏ,
    // vì thiếu mặt nạ biến sương thành tấm đặc.
    const bool draws = found->second.empty() && found->is_common;
    if (!draws) return Skip::kShading;
    return std::nullopt;
}

std::optional<Skip> Library::refuse_mesh(std::string_view material) const {
    const Paint* found = palette_.find(material);
    if (found == nullptr || found->image.empty()) return Skip::kNoMaterial;
    if (found->blend == Blend::kOther) return Skip::kBlend;
    // Model chỉ trộn src_alpha. Hạt mesh cộng sáng không có pipeline One+One.
    if (found->blend != Blend::kAlpha) return Skip::kMeshRenderer;
    return std::nullopt;
}

std::optional<Skip> Library::refuse_system(std::string_view name) {
    const KeptSystem* kept = kept_system(name);
    if (kept == nullptr) return Skip::kUnknownName;
    if (!kept->lost.empty()) return Skip::kUnknownAffector;
    if (kept->definition.renderer == RendererKind::kMesh) return refuse_mesh(kept->definition.material);
    return refuse_material(kept->definition.material);
}

std::span<const std::string> Library::lost_affectors(std::string_view name) {
    const KeptSystem* kept = kept_system(name);
    if (kept == nullptr) return {};
    return kept->lost;
}

std::uint32_t Library::lost_elements(std::string_view name) {
    const KeptEffect* kept = kept_effect(name);
    return kept == nullptr ? 0 : kept->lost;
}

Cast::Cast(Library* library) : library_(library) {}

void Cast::note(Skip skip) {
    ++tally_.skipped.at(static_cast<std::size_t>(skip));
}

void Cast::note_affector(const std::string& kind) {
    ++tally_.affectors[kind];
}

bool Cast::accepts_system(std::string_view name) {
    const std::optional<Skip> refused = library_->refuse_system(name);
    if (!refused) {
        ++tally_.systems;
        return true;
    }
    note(*refused);
    if (*refused != Skip::kUnknownAffector) return false;
    for (const std::string& kind : library_->lost_affectors(name)) {
        note_affector(kind);
    }
    return false;
}

bool Cast::accepts(const ElementDef& element) {
    if (element.kind == ElementKind::kParticle) return accepts_system(element.system);
    const std::optional<Skip> refused = library_->refuse_material(element.material);
    if (refused) {
        note(*refused);
        return false;
    }
    ++tally_.strips;
    return true;
}

void Cast::take_element(Running& running, const ElementDef& element) {
    if (accepts(element)) running.elements.push_back(&element);
}

void Cast::add_effect(const Spawn& spawn) {
    const EffectDef* effect = library_->effect(spawn.name);
    if (effect == nullptr) {
        note(Skip::kUnknownName);
        return;
    }
    tally_.skipped.at(static_cast<std::size_t>(Skip::kUnknownElement)) += library_->lost_elements(spawn.name);
    Running running;
    running.node = spawn.node;
    running.aim = spawn.aim;
    for (const ElementDef& element : effect->elements) {
        take_element(running, element);
    }
    runnings_.push_back(std::move(running));
}

void Cast::add(const Spawn& spawn) {
    if (library_ == nullptr) return;
    if (spawn.is_effect) {
        add_effect(spawn);
        return;
    }
    if (accepts_system(spawn.name)) spawn_system(spawn.name, spawn.node);
}

void Cast::clear() noexcept {
    fields_.clear();
    runnings_.clear();
    strips_.clear();
    tally_.systems = 0;
    tally_.strips = 0;
    tally_.skipped.fill(0);
    tally_.affectors.clear();
}

// Hệ khai quota 0 không bao giờ có hạt: không dựng Field cho nó.
void Cast::spawn_system(std::string_view name, const Node& node) {
    const SystemDef* definition = library_->system(name);
    if (definition == nullptr || definition->quota == 0) return;
    auto field = std::make_unique<Field>(*definition, static_cast<std::uint32_t>(fields_.size() + 1));
    field->update(0.0F, node);
    fields_.push_back(std::move(field));
}

void Cast::spawn_element(const ElementDef& element, const Running& running) {
    const Node node = placed(running.node, element);
    if (element.kind == ElementKind::kParticle) {
        spawn_system(element.system, node);
        return;
    }
    Strip strip;
    strip.element = &element;
    strip.node = node;
    strip.aim = running.aim;
    strip.seed = static_cast<std::uint32_t>(strips_.size() + 1);
    strips_.push_back(std::move(strip));
}

void Cast::spawn_due(const Running& running, const ElementDef& element, float before) {
    const bool is_due = element.start_time >= before && element.start_time < running.age;
    if (is_due) spawn_element(element, running);
}

void Cast::advance(Running& running, float seconds) {
    const float before = running.age;
    running.age += seconds;
    for (const ElementDef* element : running.elements) {
        spawn_due(running, *element, before);
    }
}

void Cast::step_strip(Strip& strip, float dt) {
    if (strip.element == nullptr) return;
    strip.age += dt;
    const bool expired = strip.element->lifetime > 0.0F && strip.age >= strip.element->lifetime;
    if (expired) strip.alive = false;
    if (!strip.alive) return;
    if (strip.element->kind == ElementKind::kTrail) trail_step(strip.trail, *strip.element, strip.node.position, dt);
    if (strip.element->kind != ElementKind::kBeam) return;
    strip.since += dt;
    const float period = strip.element->frequency > 0.0F ? 1.0F / strip.element->frequency : 0.0F;
    const bool due = strip.element->frequency == 0.0F || strip.since > period;
    if (!due) return;
    strip.since = 0.0F;
    ogre::Vec3 dest{.y = 1.0F};
    if (strip.aim) dest = local_point(strip.node, *strip.aim);
    strip.local = beam_points(*strip.element, dest, strip.seed, strip.phase);
}

void Cast::update(float seconds) {
    if (seconds < 0.0F) return;
    for (Running& running : runnings_) {
        advance(running, seconds);
    }
    for (const std::unique_ptr<Field>& field : fields_) {
        field->update(seconds, field->node());
    }
    for (Strip& strip : strips_) {
        step_strip(strip, seconds);
    }
    std::erase_if(strips_, [](const Strip& strip) { return !strip.alive; });
}

void Cast::emit_beam(BillboardBatch& batch, const Strip& strip, CameraAxes camera) {
    std::vector<ChainSample> world = strip.local;
    for (ChainSample& sample : world) {
        lift_point(sample, strip.node);
    }
    append_chain(batch, world, camera, true);
}

void Cast::emit_one(std::vector<BillboardBatch>& batches, const Strip& strip, CameraAxes camera) {
    if (!strip.alive || strip.element == nullptr || strip.element->material.empty()) return;
    if (!strip.element->visible) return;
    BillboardBatch batch;
    batch.material = strip.element->material;
    if (strip.element->kind == ElementKind::kBeam) emit_beam(batch, strip, camera);
    if (strip.element->kind == ElementKind::kTrail) {
        const std::vector<ChainSample> points = trail_points(strip.trail, *strip.element);
        append_chain(batch, points, camera, false);
    }
    if (strip.element->kind == ElementKind::kProjector) {
        append_deck(batch, strip.node, strip.element->projection, Colour{1.0F, 1.0F, 1.0F, 1.0F});
    }
    if (!batch.vertices.empty()) batches.push_back(std::move(batch));
}

std::vector<BillboardBatch> Cast::strips(CameraAxes camera) const {
    std::vector<BillboardBatch> batches;
    for (const Strip& strip : strips_) {
        emit_one(batches, strip, camera);
    }
    return batches;
}

std::vector<const Field*> Cast::live() const {
    std::vector<const Field*> fields;
    fields.reserve(fields_.size());
    for (const std::unique_ptr<Field>& field : fields_) {
        take_live(fields, *field);
    }
    return fields;
}

} // namespace game::fx
