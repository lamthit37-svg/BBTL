/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/content.hpp
 *  PHÂN HỆ   : Server / Zone / Content
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Quái và NPC đặt sẵn của cảnh, lấy từ dữ liệu cảnh
 *    (dev/server/scenes/<tên>/spawns.tsv, do module scenedata nạp). Host tạo
 *    cảnh lười khi người chơi đầu tiên vào; lúc đó nó hỏi Seeder danh sách thực
 *    thể cần đặt.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Tách làm hai phần: seeds_of là phép đổi THUẦN từ Scene của scenedata sang danh sách đặt (test được không cần
// đĩa), DiskSeeder là chỗ duy nhất chạm đĩa (bảng scene_ids.tsv, thư mục cảnh) và chỉ được gọi từ serve.cpp.
//
// Chỉ bảng quái gốc (spawns.tsv) được đặt. Các bảng theo cấp người chơi (spawns.level_*.tsv, chọn qua
// spawn_operates) và luật AI/tuần tra thuộc bước sau: cảnh dựng xong thì quái đứng yên đúng chỗ đặt.

#pragma once

#include "scenedata/types.hpp"
#include "zone/gates.hpp"
#include "zone/scene.hpp"

#include <cstddef>
#include <memory>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::zone {

// Một thực thể đặt sẵn. respawn_ms âm là không hồi sinh (cảnh chưa có cái chết, nên chưa dùng).
struct Seed {
    Spawn what;
    std::int32_t respawn_ms = -1;
};

struct Seeding {
    std::vector<Seed> seeds;
    // Dòng bảng không có toạ độ (ô x hoặc z rỗng): mã 2008 đặt chúng ở góc (0, 0) ngoài mọi lưới đi.
    std::size_t unplaced = 0;
    // Dòng bị bỏ vì vượt trần `cap`.
    std::size_t over_cap = 0;
};

// Hai thuộc tính của mẫu quái/NPC mà bảng cảnh không ghi (tables/shared/monsters.tsv của client 2026: cột
// monster_id, level, can_interact). Bảng này là bảng sinh ra từ client (git bỏ qua), nên có thể vắng: khi đó mọi
// dòng không phải trân thú là quái và cấp lấy từ bảng cảnh.
struct TemplateInfo {
    std::uint16_t level = 0;
    // can_interact == 1: đứng đó để nói chuyện/mua bán, không phải để đánh.
    bool interactive = false;
    // base_ai: loại AI mặc định của mẫu (khoá của AiTypeTable); -1 khi bảng không có cột hay ô.
    std::int32_t base_ai = -1;
    // move_speed: nghìn mét mỗi giây (1800 là 1,8 m/s), nhân 1,5 khi chạy (Obj_Monster::GetMoveSpeed).
    std::int32_t move_speed = 0;
};

// NOLINTNEXTLINE(bugprone-exception-escape): ctor ngầm định của map chuẩn ném bad_alloc; không dùng ngoại lệ (LH-07)
class TemplateTable {
public:
    // Đọc bằng cách tách theo tab, không dựng bảng ô: bảng thật 29 nghìn dòng × 70 cột. Lỗi trả câu tiếng Việt kèm số dòng.
    [[nodiscard]] static std::expected<TemplateTable, std::string> parse(std::string_view text);

    [[nodiscard]] const TemplateInfo* find(std::uint32_t template_id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return by_id_.size(); }

private:
    std::unordered_map<std::uint32_t, TemplateInfo> by_id_;
};

// Một dòng của tables/server/monster_ai_types.tsv (MonsterAITable của máy chủ 2008). Giá trị thô: mili giây, hoặc nghìn
// mét (aiparam / 1000 là mét), âm là "tắt" (scan -1 là quái không chủ động).
struct AiType {
    std::int32_t scan_ms = -1;
    std::int32_t wander_ms = -1;
    std::int32_t return_mm = -1;
    std::int32_t scan_mm = -1;
};

// NOLINTNEXTLINE(bugprone-exception-escape): ctor ngầm định của map chuẩn ném bad_alloc; không dùng ngoại lệ (LH-07)
class AiTypeTable {
public:
    // Cột ai_id và aiparam0, aiparam1, aiparam3, aiparam4 (ý nghĩa: AIPARAM_* của GameDefine2.h). Lỗi trả câu tiếng Việt.
    [[nodiscard]] static std::expected<AiTypeTable, std::string> parse(std::string_view text);

    [[nodiscard]] const AiType* find(std::int32_t ai_id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return by_id_.size(); }

private:
    std::unordered_map<std::int32_t, AiType> by_id_;
};

// Hai bảng làm giàu cho seeds_of; con trỏ rỗng là bảng vắng (quái đứng yên như trước).
struct SeedTables {
    const TemplateTable* templates = nullptr;
    const AiTypeTable* ai_types = nullptr;
    // Script này có hội thoại chạy được không (play::World); rỗng thì không NPC nào có cờ nói chuyện.
    std::function<bool(std::uint32_t script)> talks{};
};

// Bán kính lang thang quanh chỗ sinh, cm: bằng default_position_range của config/rules/monster.toml (10 m); zone chưa có
// bộ đọc luật quái nên số này viết ở đây.
inline constexpr std::uint32_t kWanderRangeCm = 1000;

// Đơn vị toạ độ của bảng cảnh là đơn vị game (một đơn vị là một ô lưới); zone dùng centimet, 1 đơn vị = 100 cm
// (cùng phép đổi như điểm sinh của nhân vật, docs/SERVER-DI-CHUYEN.md).
// Hướng: bảng ghi độ (Spawn::heading_degrees); đổi sang 0..65535 ứng với 0..2π. Quy ước gốc của góc (từ trục nào,
// chiều nào) chưa đối chiếu với client 2026 (docs/NGHI-NGO.md), nên hướng NPC có thể lệch một góc cố định.
[[nodiscard]] Seeding seeds_of(const scenedata::Scene& scene, std::size_t cap,
    const SeedTables& tables, std::int64_t hz = kTickHz);

// Cầu từ id cảnh của client sang thư mục cảnh.
// NOLINTNEXTLINE(bugprone-exception-escape): ctor ngầm định của map chuẩn ném bad_alloc; không dùng ngoại lệ (LH-07)
class SceneDirectory {
public:
    // Đọc scene_ids.tsv (cột client_id_first, client_id_last, scene_dir). Lỗi trả câu tiếng Việt.
    [[nodiscard]] static std::expected<SceneDirectory, std::string> parse(std::string_view text);

    // Tên thư mục của id; rỗng khi id không thuộc cảnh nào.
    [[nodiscard]] std::string_view dir_of(std::uint16_t scene) const noexcept;
    [[nodiscard]] std::size_t range_count() const noexcept { return ranges_.size(); }

private:
    struct Range {
        std::uint16_t last = 0;
        std::string dir;
    };
    // Khoá là id đầu của khoảng; khoảng không chồng nhau (parse từ chối).
    std::map<std::uint16_t, Range> ranges_;
};

// Luật đi của một cảnh từ lưới đi của dữ liệu cảnh (scenedata::Walk). Client đi bằng cùng lưới nên đứng trong nó;
// độ lệch kWalkSlackCm chỉ để số thực làm tròn ở mép tam giác không đẩy người chơi ra ngoài (15,5 cm là một bước của
// 30 bước mỗi giây ở tốc độ tối đa). Một điểm đi được khi nó hoặc điểm lệch kWalkSlackCm theo bốn hướng đi được.
// Cảnh không có lưới đi (WalkSource::kNone) thì trả rỗng: đi đâu cũng được, thay vì chặn mọi bước.
inline constexpr float kWalkSlackCm = 20.0F;
[[nodiscard]] Walkable walkable_of(std::shared_ptr<const scenedata::Walk> walk);

// Mọi thứ zone lấy từ dữ liệu cảnh khi tạo cảnh: thực thể đặt sẵn và luật đi.
struct SceneContent {
    std::vector<Seed> seeds;
    Walkable walkable{};
    // Vùng sự kiện, cổng đi bộ đã buộc vào ScenePosDefineEx. Rỗng khi cảnh không có areas.
    std::vector<AreaRect> areas;
};

using Seeder = std::function<SceneContent(std::uint16_t scene)>;

struct DiskPaths {
    std::filesystem::path scenes;
    std::filesystem::path ids_table;
    // Có thể vắng: xem TemplateTable.
    std::filesystem::path templates;
    // tables/server/monster_ai_types.tsv; có thể vắng (quái đứng yên).
    std::filesystem::path ai_types;
    // tables/shared/scene_positions_extended.tsv; vắng thì không cổng đi bộ.
    std::filesystem::path gates;
    // tables/server/script_index.tsv; vắng thì không nhận ra script chuansong.
    std::filesystem::path scripts;
};

// Seeder đọc đĩa: thiếu bảng id hay thư mục cảnh thì cảnh để trống (không quái, không luật đi) và nói ra stderr. `cap` là số thực thể tối đa
// mỗi cảnh. Chỉ một luồng được gọi nó (luồng tick của zone); đọc một cảnh lớn tốn vài chục mili giây, lần đầu
// có người vào cảnh đó.
[[nodiscard]] Seeder disk_seeder(const DiskPaths& paths, std::size_t cap,
    std::function<bool(std::uint32_t script)> talks = {}, std::int64_t hz = kTickHz);

} // namespace game::zone
