#pragma once
// Kiểu dữ liệu của một cảnh máy chủ (thư mục dev/server/scenes/<tên>): quái và NPC đặt sẵn, vùng sự kiện,
// tuyến tuần, điểm thu thập, bàn chế tác, trân thú hoang, cổng dịch chuyển, xe buýt, và lưới đi.
// Mọi struct ở đây là túi dữ liệu do bộ nạp (scene.hpp) điền; hợp đồng của từng trường nói ở comment
// của trường. Ô rỗng của bảng nghĩa là khoá vắng (hoặc chỉ có chú thích) trong tệp ini gốc; mỗi trường
// ghi rõ máy chủ 2008 đọc ô rỗng ra sao (atoi("") = 0, hay lấy mặc định của mẫu quái).
//
// Nguồn: dạng bảng do TOOLS/server/export_scene.py và import_scene_xjl.py sinh; ngữ nghĩa đọc từ
// Server/GameServer/Server/Obj/MonsterManager.cpp, Item/GrowPointManager.cpp, Scene/PathFinder.cpp của
// máy chủ 2008. Khác gốc: ghi ở scene.hpp và walk.hpp.

#include "core/ground_point.hpp"
#include "ids/ids.hpp"
#include "nav/mesh.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace game::scenedata {

struct LoadError {
    // Câu tiếng Việt: "<tệp>:<dòng>: cột <tên>: <lý do>".
    std::string what;
};

template <typename T>
using Loaded = std::expected<T, LoadError>;

// Quái hoặc NPC đặt sẵn (một bản ghi [monsterN] của tệp quái).
struct Spawn {
    // GUID trong tệp. KHÔNG duy nhất: nhiều NPC của bản private dùng chung một GUID (vd. 3898432 ở
    // fengmingzhen), nên không dùng làm khoá.
    std::uint32_t guid = 0;
    ids::MonsterTemplateId type;
    // UTF-8, rỗng thì lấy tên của mẫu quái.
    std::string name;
    std::string title;
    // Vị trí theo toạ độ game (đơn vị ô, x sang phải, z xuống dưới). position_given là false khi ô x hoặc z
    // rỗng: mã 2008 đọc atof("") = 0 nên quái nằm ở góc (0, 0), ngoài lưới đi của mọi cảnh; bên dùng quyết
    // định có sinh hay không.
    core::GroundPoint position;
    bool position_given = false;
    // Hướng tính bằng bước 10 độ (DIR_STEP = pi/18); heading_degrees() đổi ra độ như mã gốc.
    std::int32_t direction = 0;
    // Mã script của quái; -1 là không có. Ô rỗng đọc thành 0 (atoi("")).
    std::int32_t script_id = -1;
    // Mili giây giữa hai lần hồi sinh; âm là không hồi sinh. 60000 là mặc định của mã 2008 cho quái tạo
    // bằng code, không phải cho tệp: tệp luôn có khoá này.
    std::int32_t respawn_ms = 0;
    std::int32_t group_id = -1;
    std::int32_t team_id = -1;
    // Vắng thì lấy BaseAI / ExtAI của mẫu quái (MonsterAttrExTable); -1 ở ai_file là không có kịch bản.
    std::optional<std::int32_t> base_ai;
    std::optional<std::int32_t> ai_file;
    // Tuyến tuần (patrols.tsv, patrol_index); -1 là không tuần.
    std::int32_t patrol_id = -1;
    // Bốn ô cửa hàng; -1 là không có.
    std::array<std::int32_t, 4> shop{-1, -1, -1, -1};
    // Cấp ghi đè; vắng thì 0, 0 hoặc âm nghĩa là dùng cấp của mẫu quái.
    std::int32_t level = 0;
    bool is_pet = false;
    // Mili giây của bộ đếm script; vắng thì 0.
    std::int32_t script_timer_ms = 0;
    // Mã 2008 không đọc khoá này; giữ nguyên để không mất dữ liệu.
    std::optional<std::int32_t> reputation_id;
    // Chuỗi shop riêng (cshop), mã 2008 không đọc; giữ nguyên.
    std::string custom_shop;
    // Vắng thì -1 (leaderid), không là NPC (npc), phe mặc định của mã 2008 (camp, CAMP1_PLAYER).
    std::int32_t leader_id = -1;
    bool is_npc = false;
    std::optional<std::int32_t> camp;

    // Hướng đổi ra độ nguyên: bước * 10 + 90, trừ 360 một lần khi vượt 360, đúng phép của
    // MonsterManager.cpp (dir * DIR_STEP + pi/2 rồi trừ 2*pi một lần). Không dùng số thực: cùng đầu vào luôn
    // ra cùng đáp số trên mọi nền tảng.
    [[nodiscard]] std::int32_t heading_degrees() const noexcept {
        const std::int64_t degrees = static_cast<std::int64_t>(direction) * 10 + 90;
        return static_cast<std::int32_t>(degrees > 360 ? degrees - 360 : degrees);
    }
};

// Vùng sự kiện hình chữ nhật (eventfile). Người chơi bước vào thì chạy script.
struct Area {
    std::uint32_t guid = 0;
    // -1 là không script; ô rỗng đọc thành 0.
    std::int32_t script_id = -1;
    // Giữ nguyên số của tệp. left > right hay top > bottom không phải lỗi nạp: vùng đó rỗng, đúng như mã 2008
    // (một vùng thật ở taohuadao có left 274 > right 102).
    float left = 0.0F;
    float top = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;

    // AreaManager.h 2008: x >= left && x < right && y >= top && y < bottom — cạnh phải và cạnh dưới KHÔNG
    // thuộc vùng. NaN không thuộc vùng nào.
    [[nodiscard]] bool contains(core::GroundPoint point) const noexcept {
        return point.x >= left && point.x < right && point.z >= top && point.z < bottom;
    }
};

// Điểm của một tuyến tuần.
struct PatrolPoint {
    core::GroundPoint position;
    // false khi ô x hoặc z rỗng (xem Spawn::position_given).
    bool position_given = false;
    // Độ cao ghi trong tệp (position_y); phần lớn điểm không có.
    std::optional<float> height;
    // Thời gian dừng tại điểm, mili giây; vắng thì không dừng.
    std::optional<std::uint32_t> settle_ms;
    std::optional<std::int32_t> point_script_id;
    std::optional<std::int32_t> route_script_id;
    // Vắng thì false.
    bool turns_back = false;
    bool teleport_to_respawn = false;
    // Các câu quái nói tại điểm (speech_1..), UTF-8; bỏ ô rỗng.
    std::vector<std::string> speech;
};

// Tuyến tuần: các điểm xếp theo point_index tăng dần, không lặp chỉ số.
struct Patrol {
    std::int32_t index = 0;
    std::vector<PatrolPoint> points;
};

// Điểm thu thập trên mặt đất (growpointdata). Cột position_y của bảng là trục Z của cảnh: mã 2008
// (GrowPointManager.cpp) gán GrowPointY vào m_fZ.
struct GrowPoint {
    std::int32_t point_id = 0;
    std::int32_t grow_point_type = 0;
    core::GroundPoint position;
};

// Nhịp bổ sung điểm thu thập theo loại (growpointsetup). Tên cột gốc: 类型, 数量, 每次生成数量, 生成函数,
// 种子补充的间隔时间, 补充时间随机增量. Đơn vị thời gian là mili giây theo tên biến m_IntervalPerSeed của mã
// 2008 (số đo: 1000..7200000), chưa đối chiếu với bản private.
struct GrowRule {
    std::int32_t grow_point_type = 0;
    std::int32_t max_count = 0;
    std::int32_t per_batch = 0;
    // Tên hàm sinh; bảng hiện có luôn rỗng.
    std::string control_function;
    std::int32_t refill_interval_ms = 0;
    std::int32_t refill_jitter_ms = 0;
};

// Bàn chế tác (platformfile).
struct Platform {
    std::int32_t type_id = 0;
    std::int32_t class_id = 0;
    core::GroundPoint position;
    std::int32_t direction = 0;
    // Vắng hoặc -1 là không script.
    std::optional<std::int32_t> script_id;
    std::string tip;
};

// Trân thú hoang (petfile); mã 2008 không nạp tệp này, bản private có.
struct WildPet {
    std::uint32_t guid = 0;
    std::int32_t type = 0;
    std::string name;
    core::GroundPoint position;
    std::int32_t respawn_ms = 0;
    std::int32_t ai_file = 0;
};

// Cổng dịch chuyển (portalfile).
struct Portal {
    std::int32_t type = 0;
    std::int32_t scene_id = 0;
    core::GroundPoint position;
    std::int32_t target_scene_id = 0;
    core::GroundPoint target_position;
    std::int32_t target_direction = 0;
};

// Xe buýt chạy theo tuyến tuần (busfile).
struct Bus {
    std::uint32_t guid = 0;
    std::int32_t data_id = 0;
    std::int32_t patrol_id = 0;
    bool reverse = false;
};

// Cấp riêng của từng quái trong tệp quái (monster_level.ini): monster_index là chỉ số [monsterN].
struct SpawnLevel {
    std::int32_t monster_index = 0;
    std::int32_t level = 0;
};

// Quy tắc chọn tệp quái theo cấp người chơi (tệp *_monster_level.ini): spawn_file là tên bảng quái
// (spawns.level_100.tsv). select_type / select_value / data_def / max_left giữ nguyên số của tệp; ngữ nghĩa
// của select_type thuộc zone, scenedata chỉ nạp.
struct SpawnOperate {
    std::string spawn_file;
    std::int32_t select_type = 0;
    // Ô chữ vì có giá trị dạng "1" lẫn dạng danh sách.
    std::string select_value;
    std::int32_t data_def = 0;
    std::int32_t max_left = 0;
};

struct OperateValue {
    std::string spawn_file;
    std::int32_t data_index = 0;
    std::int32_t data_type = 0;
    std::int32_t value_index = 0;
    std::string value;
    std::string value_extra;
};

// Bảng cùng loại nhưng tách theo nhãn: spawns.<nhãn>.tsv. Nhãn là phần giữa "<loại>." và ".tsv", ví dụ
// "level_100", "n1_level_40", "set__pingpan_1". Với spawns và areas bảng gốc nằm riêng trong Scene; với
// spawn_operates và spawn_operate_values bảng gốc (spawn_operates.tsv) cũng là một Variant, nhãn rỗng.
template <typename Row>
struct Variant {
    std::string label;
    std::vector<Row> rows;
};

// Nguồn lưới đi đang dùng (khoá walk_source của scene.toml).
enum class WalkSource : std::uint8_t {
    kNone,       // cảnh không có lưới đi nào
    kClientPath, // .path của client 2026 (tam giác của PathLib.dll), đọc bằng nav::read_mesh
    kLegacyNav,  // walk.nav của máy chủ 2008 (lưới ô 0,5 đơn vị)
};

// Lưới đi của máy chủ 2008 (PathFinder::ReadNavMap): đầu tệp hai số u16 (rộng, cao), rồi mỗi ô bốn byte;
// trạng thái của ô là bốn bit thấp của byte đầu. Ô vuông 0,5 đơn vị, gốc ở (0, 0).
struct LegacyGrid {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // width * height phần tử, hàng z trước, mỗi phần tử 0..15.
    std::vector<std::uint8_t> state;

    // Trạng thái của ô chứa điểm; nullopt khi điểm ngoài lưới (âm, quá cỡ, hay không phải số).
    [[nodiscard]] std::optional<std::uint8_t> state_at(core::GroundPoint point) const noexcept;
    // Đi được khi level >= state, đúng PathFinder::IsCanGo. Ngoài lưới thì không đi được.
    [[nodiscard]] bool can_go(core::GroundPoint point, std::int32_t level) const noexcept;
};

struct Walk {
    WalkSource source = WalkSource::kNone;
    // Giá trị walk_source ghi trong scene.toml ("client_2026_path", "legacy_nav_0859602",
    // "legacy_nav_xjl7457", "none"); rỗng khi cảnh chưa có khối "Nguồn lưới đi" và nguồn được suy ra từ
    // tệp có mặt.
    std::string declared;
    std::optional<nav::Mesh> mesh;
    std::optional<LegacyGrid> grid;

    // Điểm đứng được theo nguồn đang dùng. kClientPath: nằm trong một tam giác đi được của .path (level bị
    // bỏ qua, lưới tam giác không chia cấp). kLegacyNav: LegacyGrid::can_go(point, level). kNone: false.
    // level là "driver level" của mã 2008 (0 là đi bộ).
    [[nodiscard]] bool walkable(core::GroundPoint point, std::int32_t level = 0) const noexcept;
};

// Cả cảnh. Bảng gốc của từng loại nằm ở trường riêng; bảng tách theo nhãn nằm ở *_variants, sắp theo nhãn.
struct Scene {
    // Tên thư mục cảnh (thân tệp scn).
    std::string name;
    std::vector<Spawn> spawns;
    std::vector<Variant<Spawn>> spawn_variants;
    std::vector<Area> areas;
    std::vector<Variant<Area>> area_variants;
    std::vector<SpawnLevel> spawn_levels;
    std::vector<Variant<SpawnOperate>> spawn_operates;
    std::vector<Variant<OperateValue>> operate_values;
    std::vector<Patrol> patrols;
    std::vector<GrowPoint> grow_points;
    std::vector<GrowRule> grow_rules;
    std::vector<Platform> platforms;
    std::vector<WildPet> wild_pets;
    std::vector<Portal> portals;
    std::vector<Bus> buses;
    Walk walk;
    // Tên tệp có mặt trong thư mục mà bộ nạp không đọc (loại bảng lạ), sắp tăng dần. Rỗng là bình thường.
    std::vector<std::string> unread_files;

    [[nodiscard]] const Patrol* find_patrol(std::int32_t index) const noexcept;
};

} // namespace game::scenedata
