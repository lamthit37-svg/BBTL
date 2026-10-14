// Thư viện hiệu ứng (script hệ hạt, script effect, bảng material) và các hệ đang chạy. Particle thành
// Field. Beam, NewRibbonTrail và Projector thành dải quad trong strips().
// Thứ module hoặc pipeline cộng sáng của client chưa vẽ đúng được thì KHÔNG dựng mà đếm theo lý do
// (Skip, Tally): hạt vẽ sai trông như lỗi dữ liệu, hạt thiếu thì dòng log nói rõ thiếu gì.
// Bảng material là effect/materials.tsv do TOOLS/content/collect_fx.py ghi từ script của kho gốc.
#pragma once

#include "fx/billboard.hpp"
#include "fx/field.hpp"
#include "fx/script.hpp"
#include "fx/strip.hpp"
#include "fx/system.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::fx {

// Cách một material hạt trộn vào khung, theo hai hệ số của scene_blend. "one one" (kAdd) và
// "src_alpha one" (kAlphaAdd) đi pipeline cộng sáng. "src_alpha one_minus_src_alpha" (kAlpha) đi
// pipeline trộn alpha. Mọi cặp hệ số khác là kOther.
// kDarken là "zero one_minus_src_colour" (khói, bóng): đích nhân (1 - màu ảnh). Vẽ thành trộn alpha thẳng của màu
// đen với alpha là độ sáng ảnh, đúng với ảnh xám (khói) và gần đúng với ảnh có màu.
enum class Blend : std::uint8_t { kAdd, kAlphaAdd, kAlpha, kDarken, kOther };

// Một dòng của bảng material: material hạt sau kế thừa.
struct Paint {
    // Ảnh nền, đường dẫn tính từ gốc dữ liệu client; rỗng khi kho gốc không có ảnh.
    std::string image;
    Blend blend = Blend::kOther;
    // Hệ số nhân màu ảnh của shader ColorX2 và ColorX4.
    float gain = 1.0F;
    // Ảnh thứ hai (mặt nạ) và tốc độ cuộn UV. Billboad thường bỏ qua khi có hai ảnh;
    // hạt mesh vẫn vẽ, mặt nạ nhân lên ảnh nền.
    std::string second;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    // scale của texture_unit. 1 là không đổi. Cuộn UV nhân thời gian cảnh rồi cộng vào.
    float scale_u = 1.0F;
    float scale_v = 1.0F;
    // Shader fixed hoặc particle: màu là ảnh nhân màu đỉnh. Shader khác không vẽ ở billboard.
    bool is_common = false;
    // Một ảnh, không cuộn, không scale, shader thường. Hai ảnh vẫn không phải thường.
    bool is_plain = false;
};

// Bảng material của thư viện: tên material thành Paint.
class Palette {
public:
    Palette() = default;
    // table là nội dung materials.tsv. Cột tra theo tên ở dòng tiêu đề; dòng thiếu tên hay hệ số màu
    // không phải số dương thì bỏ.
    explicit Palette(std::string_view table);

    // nullptr khi bảng không có tên đó.
    [[nodiscard]] const Paint* find(std::string_view material) const;
    [[nodiscard]] std::size_t size() const noexcept { return paints_.size(); }

private:
    std::map<std::string, Paint, std::less<>> paints_;
};

// Vì sao một hệ hạt hoặc một element không được dựng.
enum class Skip : std::uint8_t {
    kUnknownName,
    kUnknownElement,
    kUnknownAffector,
    kMeshRenderer,
    kNoMaterial,
    kShading,
    kBlend,
};

// Mọi lý do, theo thứ tự enumerator; Tally::skipped xếp theo đúng thứ tự này.
inline constexpr std::array kSkips{
    Skip::kUnknownName,
    Skip::kUnknownElement,
    Skip::kUnknownAffector,
    Skip::kMeshRenderer,
    Skip::kNoMaterial,
    Skip::kShading,
    Skip::kBlend,
};

inline constexpr std::size_t kSkipCount = kSkips.size();

// Lý do bằng tiếng Việt, để ghép vào dòng log.
[[nodiscard]] std::string_view describe(Skip skip) noexcept;

// Ba tệp của thư mục effect, nguyên văn: all.particle, all.effect, materials.tsv.
struct LibraryText {
    std::string particles;
    std::string effects;
    std::string materials;
};

class Library {
public:
    explicit Library(LibraryText text);

    [[nodiscard]] const SystemDef* system(std::string_view name);
    [[nodiscard]] const EffectDef* effect(std::string_view name);
    [[nodiscard]] const Palette& palette() const noexcept { return palette_; }

    // Lý do không dựng hệ hạt name; rỗng khi dựng được. Xét theo thứ tự: tên, affector, renderer,
    // rồi material.
    [[nodiscard]] std::optional<Skip> refuse_system(std::string_view name);
    // Lý do pipeline cộng sáng không vẽ đúng material; rỗng khi vẽ được.
    [[nodiscard]] std::optional<Skip> refuse_material(std::string_view material) const;
    // Hạt mesh: nhận khi có ảnh và trộn alpha. Cộng sáng vẫn bỏ, vì model không có PSO One+One.
    [[nodiscard]] std::optional<Skip> refuse_mesh(std::string_view material) const;
    // Loại affector của hệ name mà bộ đọc không dựng được, theo thứ tự trong script.
    [[nodiscard]] std::span<const std::string> lost_affectors(std::string_view name);
    // Số element của effect name mà bộ đọc không dựng được.
    [[nodiscard]] std::uint32_t lost_elements(std::string_view name);

private:
    struct KeptSystem {
        SystemDef definition;
        std::vector<std::string> lost;
    };

    struct KeptEffect {
        EffectDef definition;
        std::uint32_t lost = 0;
    };

    [[nodiscard]] const KeptSystem* kept_system(std::string_view name);
    [[nodiscard]] const KeptEffect* kept_effect(std::string_view name);

    ScriptIndex particles_;
    ScriptIndex effects_;
    // Con trỏ tới định nghĩa phải đứng yên khi map lớn lên: Field và Running giữ chúng.
    std::map<std::string, std::unique_ptr<KeptSystem>, std::less<>> systems_;
    std::map<std::string, std::unique_ptr<KeptEffect>, std::less<>> effect_defs_;
    Palette palette_;
};

struct Spawn {
    std::string name;
    bool is_effect = false;
    Node node{};
    // Đích thế giới của Beam. Thiếu thì beam không dựng, đúng sentinel (0, 1, 0).
    std::optional<ogre::Vec3> aim;
    // Hiệu ứng của skill hay của đồ (không phải của cảnh): Cast theo dõi nó, add trả handle để move và release. Emitter
    // theo duration và repeat_delay của hệ, effect hết LifeTime thì dừng, hệ hết hạt thì bị gỡ. Hiệu ứng của cảnh (mặc
    // định) phát mãi tới clear().
    bool is_tracked = false;
    // Hệ số nhân vào màu mọi hạt (Effect::setColour của gốc).
    Colour tint{1.0F, 1.0F, 1.0F, 1.0F};
};

// Số hệ được nhận dựng và số bị bỏ theo lý do, tính từ lần clear gần nhất.
struct Tally {
    // Hệ hạt và dải (Beam, NewRibbonTrail, Projector) được nhận; hệ của effect dựng khi tới StartTime.
    std::uint32_t systems = 0;
    std::uint32_t strips = 0;
    // Theo thứ tự enumerator của Skip.
    std::array<std::uint32_t, kSkipCount> skipped{};
    // Loại affector chưa hỗ trợ và số hệ bị bỏ có nó.
    std::map<std::string, std::uint32_t, std::less<>> affectors;

    [[nodiscard]] std::uint32_t count(Skip skip) const { return skipped.at(static_cast<std::size_t>(skip)); }
    [[nodiscard]] std::uint32_t total_skipped() const noexcept;
};

class Cast {
public:
    explicit Cast(Library* library);

    // Dựng một hệ hạt hoặc một effect tại spawn.node. Thứ chưa vẽ đúng được thì không dựng và được
    // ghi vào tally(). Trả handle (khác 0) khi spawn.is_tracked và dựng được, không thì 0.
    std::uint32_t add(const Spawn& spawn);
    // Dời hiệu ứng theo dõi tới node mới (hiệu ứng bám theo xương hay vũ khí): hệ và dải của nó đi theo, hạt đã phát
    // trong không gian thế giới ở lại. Handle không còn thì bỏ qua.
    void move(std::uint32_t handle, const Node& node);
    // Dừng hiệu ứng theo dõi: không phát thêm, hạt đang bay bay nốt rồi hệ bị gỡ.
    void release(std::uint32_t handle);
    // Hiệu ứng theo dõi còn việc (chưa dựng xong element, hay còn hệ hạt hoặc dải của nó). Handle 0 hay đã gỡ thì sai.
    [[nodiscard]] bool is_live(std::uint32_t handle) const;
    // Bỏ mọi hệ đang chạy và đặt lại tally: gọi khi đổi cảnh.
    void clear() noexcept;
    void update(float seconds);
    [[nodiscard]] std::vector<const Field*> live() const;
    [[nodiscard]] std::vector<BillboardBatch> strips(CameraAxes camera) const;
    [[nodiscard]] const Tally& tally() const noexcept { return tally_; }

private:
    struct Running {
        Node node{};
        float age = 0.0F;
        std::optional<ogre::Vec3> aim;
        // 0 là hiệu ứng của cảnh. LifeTime của effect (0 là mãi), màu nhân.
        std::uint32_t handle = 0;
        float lifetime = 0.0F;
        Colour tint{1.0F, 1.0F, 1.0F, 1.0F};
        // Các element đã qua cửa xét, chờ tới StartTime.
        std::vector<const ElementDef*> elements;
    };

    // Hệ hạt đang chạy và chủ của nó: handle (0 là của cảnh) và element đặt nó (nullptr khi hệ dựng thẳng).
    struct Owned {
        std::unique_ptr<Field> field;
        std::uint32_t handle = 0;
        const ElementDef* element = nullptr;
    };

    struct Strip {
        std::uint32_t handle = 0;
        const ElementDef* element = nullptr;
        Node node{};
        std::optional<ogre::Vec3> aim;
        float age = 0.0F;
        float since = 0.0F;
        float phase = 0.0F;
        std::uint32_t seed = 1;
        bool alive = true;
        std::vector<ChainSample> local;
        TrailRun trail;
    };

    std::uint32_t add_effect(const Spawn& spawn);
    void take_element(Running& running, const ElementDef& element);
    [[nodiscard]] bool accepts(const ElementDef& element);
    [[nodiscard]] bool accepts_system(std::string_view name);
    void note(Skip skip);
    void note_affector(const std::string& kind);
    void advance(Running& running, float seconds);
    void spawn_due(const Running& running, const ElementDef& element, float before);
    Field* spawn_system(std::string_view name, const Node& node, const Owned& owner);
    void spawn_element(const ElementDef& element, const Running& running);
    // Gỡ hệ hết hạt, dải đã tắt, và effect theo dõi đã xong việc.
    void sweep();
    [[nodiscard]] bool has_children(std::uint32_t handle) const;
    static void step_strip(Strip& strip, float dt);
    static void emit_beam(BillboardBatch& batch, const Strip& strip, CameraAxes camera);
    static void emit_one(std::vector<BillboardBatch>& batches, const Strip& strip, CameraAxes camera);

    Library* library_ = nullptr;
    std::vector<Owned> fields_;
    std::uint32_t last_handle_ = 0;
    std::vector<Running> runnings_;
    std::vector<Strip> strips_;
    Tally tally_;
};

} // namespace game::fx
