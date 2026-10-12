// Giải ngoại hình: tra từng khe theo luật mặc định ghi ở look.hpp, rồi xếp bộ phận theo thứ tự vẽ.
// Nguồn: TLBB Dev src/look/look.cpp@e0d89a6 và src/look/load.cpp@e0d89a6. Khác gốc: giới là Race;
// khoá faces, hairs là (id, race); bảng đọc qua table::Tsv; ReadFile trả chữ; thân của pick và
// resolve tách hàm để không có nhánh lồng (cổng của dự án).
#include "look/look.hpp"

#include "look/appearance.hpp"
#include "table/tsv.hpp"

#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

// Trang phục id của giới; id 0 hay không có thì bộ mặc định; nullptr khi mặc định cũng không có.
const OutfitRow* pick_outfit(const Tables& tables, Race race, std::uint16_t id, std::uint16_t fallback) {
    const OutfitRow* chosen = find_outfit(tables.outfits, id, race);
    if (id != 0 && chosen != nullptr) return chosen;
    return find_outfit(tables.outfits, fallback, race);
}

// Mặt id của giới nếu có, không thì mặt mặc định của thân; nullptr khi cả hai không có.
const FaceRow* pick_face(const Tables& tables, Race race, std::uint16_t id, std::uint16_t fallback) {
    const FaceRow* chosen = find_face(tables.faces, id, race);
    if (chosen != nullptr) return chosen;
    return find_face(tables.faces, fallback, race);
}

const HairRow* pick_hair(const Tables& tables, Race race, std::uint16_t id, std::uint16_t fallback) {
    const HairRow* chosen = find_hair(tables.hairs, id, race);
    if (chosen != nullptr) return chosen;
    return find_hair(tables.hairs, fallback, race);
}

Part outfit_part(Slot slot, const OutfitRow& row) {
    return Part{.slot = slot, .mesh = row.mesh, .materials = row.materials};
}

Part mesh_part(Slot slot, const std::string& mesh) {
    return Part{.slot = slot, .mesh = mesh, .materials = {}};
}

// Mũ chỉ vẽ khi id khác 0 và có trong bảng của giới.
void add_cap(std::vector<Part>& parts, const Tables& tables, Race race, std::uint16_t id) {
    const OutfitRow* cap = find_outfit(tables.outfits, id, race);
    if (id == 0 || cap == nullptr) return;
    parts.push_back(outfit_part(Slot::kCap, *cap));
}

// Tóc vẽ sau cùng vì material của nó trộn alpha; kiểu tóc không lưới thì không vẽ gì.
void add_hair(std::vector<Part>& parts, const HairRow& hair) {
    if (!hair.mesh.empty()) parts.push_back(mesh_part(Slot::kHair, hair.mesh));
    if (!hair.accessory.empty()) parts.push_back(mesh_part(Slot::kHairAccessory, hair.accessory));
}

// Clip của hành động action trong action set khi cầm loại vũ khí weapon; loại không có dòng cho
// hành động đó thì dùng dòng tay không.
std::optional<Clip> clip_of(const Tables& tables, std::uint32_t set, Action action, Weapon weapon) {
    const AnimRow* armed = find_anim(tables.anims, set, action, weapon);
    const AnimRow* row = armed != nullptr ? armed : find_anim(tables.anims, set, action, Weapon::kNone);
    if (row == nullptr) return std::nullopt;
    return Clip{.anim = row->anim, .name = row->clip};
}

// Ba trang phục của thân: áo, tay, giày; mỗi cái theo id của look hay mặc định của thân.
struct Dressing {
    const OutfitRow* clothes = nullptr;
    const OutfitRow* arm = nullptr;
    const OutfitRow* foot = nullptr;

    [[nodiscard]] bool is_complete() const noexcept { return clothes != nullptr && arm != nullptr && foot != nullptr; }
};

Dressing dress(const Tables& tables, const PlayerBody& body, const Look& look) {
    return Dressing{.clothes = pick_outfit(tables, body.race, look.body, body.body),
        .arm = pick_outfit(tables, body.race, look.arm, body.arm),
        .foot = pick_outfit(tables, body.race, look.foot, body.foot)};
}

// Mặt, tóc và trang phục của look; lỗi khi thiếu mặc định.
struct Chosen {
    const FaceRow* face = nullptr;
    const HairRow* hair = nullptr;
    Dressing dressing;
};

std::expected<Chosen, LookError> choose(const Tables& tables, const PlayerBody& body, const Look& look) {
    Chosen chosen;
    chosen.face = pick_face(tables, body.race, look.face, body.face);
    if (chosen.face == nullptr) return std::unexpected(LookError::kNoDefaultFace);
    chosen.hair = pick_hair(tables, body.race, look.hair, body.hair);
    if (chosen.hair == nullptr) return std::unexpected(LookError::kNoDefaultHair);
    chosen.dressing = dress(tables, body, look);
    if (!chosen.dressing.is_complete()) return std::unexpected(LookError::kNoDefaultOutfit);
    return chosen;
}

std::vector<Part> parts_of(const Tables& tables, const Chosen& chosen, const Look& look, Race race) {
    const Dressing& dressing = chosen.dressing;
    std::vector<Part> parts = {outfit_part(Slot::kBody, *dressing.clothes), outfit_part(Slot::kArm, *dressing.arm),
        outfit_part(Slot::kFoot, *dressing.foot), mesh_part(Slot::kFace, chosen.face->mesh)};
    add_cap(parts, tables, race, look.cap);
    add_hair(parts, *chosen.hair);
    return parts;
}

// Đường dẫn của tệp name trong folder; thư mục rỗng hay đã có dấu phân cách ở cuối thì không thêm
// "/".
std::string join(std::string_view folder, std::string_view name) {
    const bool has_end = folder.empty() || folder.ends_with('/') || folder.ends_with('\\');
    return std::format("{}{}{}", folder, has_end ? "" : "/", name);
}

// Đọc và phân tích một bảng; câu lỗi có đường dẫn tệp.
template <typename Row>
using Reader = Rows<Row> (*)(const table::Tsv&);

template <typename Row>
std::expected<std::vector<Row>, std::string> load_one(const std::string& path, const ReadFile& read,
    Reader<Row> read_rows) {
    const auto text = read(path);
    if (!text) return std::unexpected(std::format("không đọc được bảng {}: {}", path, text.error()));
    const table::TsvResult tsv = table::parse_tsv(*text);
    if (!tsv) return std::unexpected(std::format("bảng {} sai, {}", path, tsv.error()));
    auto rows = read_rows(*tsv);
    if (!rows) return std::unexpected(std::format("bảng {} sai, {}", path, rows.error()));
    return rows;
}

} // namespace

std::string_view describe(LookError error) {
    switch (error) {
    case LookError::kNoBody: return "bảng ngoại hình không có thân của giới này";
    case LookError::kNoDefaultFace: return "bảng ngoại hình không có mặt mặc định của giới này";
    case LookError::kNoDefaultHair: return "bảng ngoại hình không có tóc mặc định của giới này";
    case LookError::kNoDefaultOutfit: return "bảng ngoại hình không có áo, tay hay giày mặc định của giới này";
    case LookError::kNoIdle: return "bảng animation không có clip đứng tay không";
    case LookError::kNoRun: return "bảng animation không có clip chạy tay không";
    }
    return "lỗi ngoại hình không rõ";
}

// Clip đứng tay không của nam (空手站立01 trong 4_男空手非战斗.skeleton) để xương đầu ngửa 10,8 đến
// 15,1 độ so với tư thế bind, nên mặt nam hếch lên; nữ lệch bind 0 đến 3 độ. Cùng clip trong bộ _iv
// (bản 2026 không dùng) chỉ lệch 0,8 đến 4,7 độ. Chủ dự án yêu cầu hạ mặt mẫu nam cơ bản xuống
// (2026-10-09): cúi thêm 10,8 độ, là phần chênh trung bình của hai bộ. Số đo ở mục 8.6 của
// docs/TAO-NHAN-VAT-2026.md. Khác gốc: bản 2026 phát nguyên clip.
constexpr std::string_view kMaleHeadBone = "m_Bip01_Head";
constexpr float kMaleIdleHeadLower = 0.188F;

std::expected<Figure, LookError> resolve(const Tables& tables, Race race, const Look& look) {
    const PlayerBody* body = find_body(tables.bodies, race);
    if (body == nullptr) return std::unexpected(LookError::kNoBody);
    const auto chosen = choose(tables, *body, look);
    if (!chosen) return std::unexpected(chosen.error());
    std::optional<Clip> idle = clip_of(tables, body->anim_set, Action::kIdle, look.weapon);
    if (!idle) return std::unexpected(LookError::kNoIdle);
    std::optional<Clip> run = clip_of(tables, body->anim_set, Action::kRun, look.weapon);
    if (!run) return std::unexpected(LookError::kNoRun);
    Figure figure;
    figure.skeleton = body->skeleton;
    figure.template_name = body->template_name;
    figure.height = body->height;
    figure.parts = parts_of(tables, *chosen, look, race);
    figure.idle = std::move(*idle);
    figure.idle_alt = clip_of(tables, body->anim_set, Action::kIdleAlt, look.weapon);
    figure.idle_alt2 = clip_of(tables, body->anim_set, Action::kIdleAlt2, look.weapon);
    figure.run = std::move(*run);
    if (race == Race::kMale && look.weapon == Weapon::kNone) {
        figure.idle_trim = BoneTrim{.bone = std::string(kMaleHeadBone), .turn = kMaleIdleHeadLower};
    }
    return figure;
}

std::expected<Tables, std::string> load_tables(std::string_view folder, const ReadFile& read) {
    Tables loaded;
    auto bodies = load_one<PlayerBody>(join(folder, "player_bodies.tsv"), read, read_player_bodies);
    if (!bodies) return std::unexpected(bodies.error());
    loaded.bodies = std::move(*bodies);
    auto faces = load_one<FaceRow>(join(folder, "faces.tsv"), read, read_faces);
    if (!faces) return std::unexpected(faces.error());
    loaded.faces = std::move(*faces);
    auto hairs = load_one<HairRow>(join(folder, "hairs.tsv"), read, read_hairs);
    if (!hairs) return std::unexpected(hairs.error());
    loaded.hairs = std::move(*hairs);
    auto outfits = load_one<OutfitRow>(join(folder, "outfits.tsv"), read, read_outfits);
    if (!outfits) return std::unexpected(outfits.error());
    loaded.outfits = std::move(*outfits);
    auto anims = load_one<AnimRow>(join(folder, "anim_sets.tsv"), read, read_anim_sets);
    if (!anims) return std::unexpected(anims.error());
    loaded.anims = std::move(*anims);
    return loaded;
}

} // namespace game::look
