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
    if (text == "one one_minus_src_colour") return Blend::kGlow;
    if (text == "src_colour one_minus_src_colour") return Blend::kColour;
    if (text == "one zero") return Blend::kReplace;
    return Blend::kOther;
}

[[nodiscard]] bool is_still(std::string_view scroll) {
    const std::optional<float> speed = parse_float(scroll);
    return scroll.empty() || (speed && *speed == 0.0F);
}

enum class UvKey : std::uint8_t { kScale, kScroll, kAnim, kOther };

[[nodiscard]] UvKey uv_key(std::string_view name) noexcept {
    if (name == "scale") return UvKey::kScale;
    if (name == "scroll") return UvKey::kScroll;
    if (name == "scroll_anim") return UvKey::kAnim;
    return UvKey::kOther;
}

[[nodiscard]] std::uint8_t uv_bit(UvKey key) noexcept {
    if (key == UvKey::kScale) return 1;
    if (key == UvKey::kScroll) return 2;
    return 4;
}

struct UvUnit {
    float scale_u = 1.0F;
    float scale_v = 1.0F;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    float anim_u = 0.0F;
    float anim_v = 0.0F;
};

void write_uv(UvUnit& unit, UvKey key, float across, float down) {
    if (key == UvKey::kScale) {
        unit.scale_u = across;
        unit.scale_v = down;
        return;
    }
    if (key == UvKey::kScroll) {
        unit.scroll_u = across;
        unit.scroll_v = down;
        return;
    }
    unit.anim_u = across;
    unit.anim_v = down;
}

// extra liệt kê lệnh unit theo thứ tự collect_fx: từ khoá lặp lại là sang unit sau.
// scroll_anim của unit đầu nằm ở cột, nên gặp nó lúc còn unit đầu là sang unit sau.
void take_uv_piece(std::array<UvUnit, 2>& units, int& slot, std::array<std::uint8_t, 2>& seen,
    std::string_view piece) {
    const std::size_t gap = piece.find(' ');
    if (gap == std::string_view::npos) return;
    const UvKey key = uv_key(piece.substr(0, gap));
    if (key == UvKey::kOther) return;
    const std::string_view rest = piece.substr(gap + 1);
    const std::size_t next = rest.find(' ');
    if (next == std::string_view::npos) return;
    const std::optional<float> across = parse_float(rest.substr(0, next));
    std::string_view tail = rest.substr(next + 1);
    const std::size_t end = tail.find_first_of(" ;");
    if (end != std::string_view::npos) tail = tail.substr(0, end);
    const std::optional<float> down = parse_float(tail);
    if (!across || !down) return;
    if (key == UvKey::kScale && (*across == 0.0F || *down == 0.0F)) return;
    const std::uint8_t bit = uv_bit(key);
    const bool repeats = (seen[static_cast<std::size_t>(slot)] & bit) != 0;
    const bool anim_starts_cover = key == UvKey::kAnim && slot == 0;
    if ((repeats || anim_starts_cover) && slot == 0) slot = 1;
    const std::size_t index = static_cast<std::size_t>(slot);
    if ((seen[index] & bit) != 0) return;
    seen[index] = static_cast<std::uint8_t>(seen[index] | bit);
    write_uv(units[index], key, *across, *down);
}

[[nodiscard]] std::size_t consume_piece(std::string_view extra, std::size_t cursor, std::array<UvUnit, 2>& units,
    int& slot, std::array<std::uint8_t, 2>& seen) {
    const std::size_t stop = extra.find(';', cursor);
    const std::size_t end = stop == std::string_view::npos ? extra.size() : stop;
    const std::string_view piece = extra.substr(cursor, end - cursor);
    const std::size_t from = piece.find_first_not_of(' ');
    if (from != std::string_view::npos) take_uv_piece(units, slot, seen, piece.substr(from));
    if (stop == std::string_view::npos) return extra.size();
    return stop + 1;
}

void read_uv(Paint& paint, std::string_view extra) {
    std::array<UvUnit, 2> units;
    std::array<std::uint8_t, 2> seen{};
    int slot = 0;
    std::size_t cursor = 0;
    while (cursor < extra.size())
        cursor = consume_piece(extra, cursor, units, slot, seen);
    paint.scale_u = units[0].scale_u;
    paint.scale_v = units[0].scale_v;
    paint.shift_u = units[0].scroll_u;
    paint.shift_v = units[0].scroll_v;
    paint.cover_scale_u = units[1].scale_u;
    paint.cover_scale_v = units[1].scale_v;
    paint.cover_shift_u = units[1].scroll_u;
    paint.cover_shift_v = units[1].scroll_v;
    paint.cover_scroll_u = units[1].anim_u;
    paint.cover_scroll_v = units[1].anim_v;
}

// Cột sinh từ script gốc thắng extra: extra không ghi unit nào sở hữu lệnh khi chỉ có một lệnh.
void take_axis(float& across, float& down, const Row& row, std::string_view across_name,
    std::string_view down_name) {
    const std::optional<float> left = parse_float(row.cell(across_name));
    const std::optional<float> right = parse_float(row.cell(down_name));
    if (!left || !right) return;
    across = *left;
    down = *right;
}

void take_axes(Paint& paint, const Row& row) {
    take_axis(paint.scale_u, paint.scale_v, row, "scale_u", "scale_v");
    take_axis(paint.shift_u, paint.shift_v, row, "shift_u", "shift_v");
    take_axis(paint.cover_scale_u, paint.cover_scale_v, row, "cover_scale_u", "cover_scale_v");
    take_axis(paint.cover_shift_u, paint.cover_shift_v, row, "cover_shift_u", "cover_shift_v");
    take_axis(paint.cover_scroll_u, paint.cover_scroll_v, row, "cover_scroll_u", "cover_scroll_v");
}

// BLEND_OP_1 của Particle_2Tex. 0 là shader không nhân ảnh thứ hai.
[[nodiscard]] float cover_gain_of(std::string_view shader) noexcept {
    if (!shader.starts_with("Particle_TwoTex")) return 0.0F;
    if (shader.find("Dissolve") != std::string_view::npos) return 0.0F;
    if (shader.find("Tex2_ColorX4") != std::string_view::npos) return 4.0F;
    if (shader.find("Tex2_ColorX2") != std::string_view::npos) return 2.0F;
    return 1.0F;
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
    read_uv(paint, row.cell(kExtraColumn));
    take_axes(paint, row);
    const std::string_view shader = row.cell(kShaderColumn);
    const float cover = cover_gain_of(shader);
    const bool plain = std::ranges::find(kPlainShaders, shader) != kPlainShaders.end();
    const bool layered = cover > 0.0F && !paint.second.empty();
    paint.cover_gain = layered ? cover : 0.0F;
    paint.is_common = (plain && paint.second.empty()) || layered;
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
    // Hai ảnh chỉ vẽ khi shader là Particle_TwoTex (nhân ảnh). Dissolve và shader lạ vẫn bỏ.
    if (!found->is_common) return Skip::kShading;
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

std::uint32_t Cast::add_effect(const Spawn& spawn) {
    const EffectDef* effect = library_->effect(spawn.name);
    if (effect == nullptr) {
        note(Skip::kUnknownName);
        return 0;
    }
    tally_.skipped.at(static_cast<std::size_t>(Skip::kUnknownElement)) += library_->lost_elements(spawn.name);
    Running running;
    running.node = spawn.node;
    running.aim = spawn.aim;
    if (spawn.is_tracked) {
        running.handle = ++last_handle_;
        running.lifetime = effect->lifetime;
        running.tint = spawn.tint;
    }
    for (const ElementDef& element : effect->elements) {
        take_element(running, element);
    }
    const std::uint32_t handle = running.handle;
    runnings_.push_back(std::move(running));
    return handle;
}

std::uint32_t Cast::add(const Spawn& spawn) {
    if (library_ == nullptr) return 0;
    if (spawn.is_effect) return add_effect(spawn);
    if (!accepts_system(spawn.name)) return 0;
    Owned owner;
    if (spawn.is_tracked) owner.handle = ++last_handle_;
    Field* const made = spawn_system(spawn.name, spawn.node, owner);
    if (made == nullptr) return 0;
    made->set_tint(spawn.tint);
    return owner.handle;
}

void Cast::move(std::uint32_t handle, const Node& node) {
    if (handle == 0) return;
    for (Running& running : runnings_) {
        if (running.handle == handle) running.node = node;
    }
    for (const Owned& owned : fields_) {
        if (owned.handle != handle) continue;
        const Node placed_node = owned.element != nullptr ? placed(node, *owned.element) : node;
        owned.field->update(0.0F, placed_node);
    }
    for (Strip& strip : strips_) {
        if (strip.handle != handle || strip.element == nullptr) continue;
        strip.node = placed(node, *strip.element);
    }
}

void Cast::release(std::uint32_t handle) {
    if (handle == 0) return;
    std::erase_if(runnings_, [handle](const Running& running) { return running.handle == handle; });
    for (const Owned& owned : fields_) {
        if (owned.handle == handle) owned.field->stop();
    }
    for (Strip& strip : strips_) {
        if (strip.handle == handle) strip.alive = false;
    }
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
Field* Cast::spawn_system(std::string_view name, const Node& node, const Owned& owner) {
    const SystemDef* definition = library_->system(name);
    if (definition == nullptr || definition->quota == 0) return nullptr;
    auto field = std::make_unique<Field>(*definition, static_cast<std::uint32_t>(fields_.size() + 1));
    field->set_timed(owner.handle != 0);
    field->update(0.0F, node);
    Field* const made = field.get();
    fields_.push_back(Owned{.field = std::move(field), .handle = owner.handle, .element = owner.element});
    return made;
}

void Cast::spawn_element(const ElementDef& element, const Running& running) {
    const Node node = placed(running.node, element);
    if (element.kind == ElementKind::kParticle) {
        Field* const made =
            spawn_system(element.system, node, Owned{.field = nullptr, .handle = running.handle, .element = &element});
        if (made != nullptr) made->set_tint(running.tint);
        return;
    }
    Strip strip;
    strip.handle = running.handle;
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
    // Hết LifeTime thì dừng (release gỡ running khỏi danh sách, nên gom handle trước).
    std::vector<std::uint32_t> ended;
    for (const Running& running : runnings_) {
        if (running.handle != 0 && running.lifetime > 0.0F && running.age >= running.lifetime) ended.push_back(running.handle);
    }
    for (const std::uint32_t handle : ended) release(handle);
    for (const Owned& owned : fields_) {
        owned.field->update(seconds, owned.field->node());
    }
    for (Strip& strip : strips_) {
        step_strip(strip, seconds);
    }
    sweep();
}

bool Cast::is_live(std::uint32_t handle) const {
    if (handle == 0) return false;
    const auto is_mine = [handle](const Running& running) { return running.handle == handle; };
    return std::ranges::any_of(runnings_, is_mine) || has_children(handle);
}

bool Cast::has_children(std::uint32_t handle) const {
    const auto is_mine = [handle](const Owned& owned) { return owned.handle == handle; };
    const auto is_strip = [handle](const Strip& strip) { return strip.handle == handle && strip.alive; };
    return std::ranges::any_of(fields_, is_mine) || std::ranges::any_of(strips_, is_strip);
}

void Cast::sweep() {
    std::erase_if(fields_, [](const Owned& owned) { return owned.handle != 0 && owned.field->is_spent(); });
    std::erase_if(strips_, [](const Strip& strip) { return !strip.alive; });
    // Effect theo dõi đã đưa hết element ra và hết con thì xong việc.
    std::erase_if(runnings_, [this](const Running& running) {
        if (running.handle == 0) return false;
        const bool is_all_due = std::ranges::all_of(running.elements, [&running](const ElementDef* element) {
            return element->start_time < running.age;
        });
        return is_all_due && !has_children(running.handle);
    });
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
    for (const Owned& owned : fields_) {
        take_live(fields, *owned.field);
    }
    return fields;
}

} // namespace game::fx
