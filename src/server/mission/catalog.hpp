/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/mission/catalog.hpp
 *  PHÂN HỆ   : Server / Mission / Catalog
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Danh mục nhiệm vụ nạp từ các bảng mission_*.tsv.
 *  - Khoá là script. Nhiệm vụ chạy được khi ok, có trong danh bạ và không vòng
 *    tiền đề.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Danh mục nhiệm vụ của máy chủ, nạp từ các bảng mission_*.tsv do TOOLS/server/lua_extract.py trích tĩnh từ script Lua 4.0
// của máy chủ 14 môn phái và bảng nhiệm vụ của client 2026 (client là thẩm quyền cao nhất: tên, cấp, NPC giao/trả, loại).
// Không có Lua nào chạy ở đây: điều kiện và hiệu ứng nằm trong ops::Program, bộ chạy chung của nhiệm vụ bảng là module engine.
//
// Khóa chính của danh mục là `script` (id duy nhất; với nhiệm vụ bảng là chỉ số dòng của bảng gốc). Nhiều dòng có thể cùng
// một `quest` (id nhiệm vụ client hiển thị, 0..4095): đó là các biến thể (ví dụ nhiệm vụ vòng "虚竹任务" có 502 dòng, chia theo
// cấp); lúc nhận, engine chọn một biến thể (xem engine.hpp).
//
// Một nhiệm vụ chạy được (Support::kRunnable) khi: bảng trích đánh dấu `ok`, có trong danh bạ client (trừ khi Options cho phép),
// mọi loại mục tiêu đều có bộ chạy, và chuỗi tiền đề không vòng. Phần còn lại KHÔNG bị bỏ im: mỗi nhiệm vụ mang Support và
// lý do, và Catalog::report() đếm theo từng lý do.

#pragma once

#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::mission {

enum class Source : std::uint8_t { kTable, kScript };
enum class Repeat : std::uint8_t { kOnce, kLoop };

enum class Support : std::uint8_t {
    kRunnable,
    kUnsupported,  // cần xử lý tay hoặc mục tiêu chưa có bộ chạy; xem Quest::reason
    kNotInClient,  // không có trong danh bạ client: client không hiện được nên từ chối nhận
    kBlocked,      // chuỗi tiền đề có vòng: không bao giờ hoàn thành được tiền đề
};

enum class ObjectiveKind : std::uint8_t {
    kTalk, // nói chuyện với NPC: target = guid (0 nếu chưa đặt), name = mã tên
    kKill, // giết quái: target = mã nhóm tên, count
    kLoot, // giết quái và nhặt vật phẩm nhiệm vụ: target = mã nhóm tên, item, rate (phần trăm),
           // count
    kDeliver, // giao vật phẩm: item, count; flag = 1 nếu nhiệm vụ cấp đồ lúc nhận
    kArea, // vào vùng: target = vùng, scene
    kEscort, // hộ tống (chưa có bộ chạy)
    kProgress, // script: tham số `index` của ô đạt count
    kCollect, // script: có đủ count vật phẩm `item`
    kSkill, // học kỹ năng: item = mã skills.tsv, name = thầy; ô ghi 0/1 khi đã biết
    kLevel, // đạt cấp: count = cấp cần; ô ghi 0/1 khi level() >= count
};

struct Objective {
    ObjectiveKind kind = ObjectiveKind::kTalk;
    std::int32_t index = 0;
    std::int32_t target = 0;
    std::int32_t count = 0;
    std::int32_t item = 0;
    std::int32_t rate = 0;
    std::int32_t scene = 0;
    std::int32_t flag = 0;
    std::uint32_t name = 0; // mã băm để so với script
    std::string label; // tên chữ trong bảng, để nút dấu nêu mục tiêu
};

enum class RewardGroup : std::uint8_t { kFixed, kChoice, kHidden };
enum class RewardKind : std::uint8_t {
    kMoney,       // count = tiền thường
    kBoundMoney,  // count = tiền khoá
    kExp,         // count = kinh nghiệm
    kItem,        // ref = mẫu vật phẩm, count
    kRelation,    // ref = chỉ số bộ đếm quan hệ, count = điểm cộng
};

struct Reward {
    RewardGroup group = RewardGroup::kFixed;
    RewardKind kind = RewardKind::kExp;
    std::int32_t ref = 0;
    std::int64_t count = 0;
    std::int32_t cond = -1;
};

enum class HookEvent : std::uint8_t { kKill, kEnterArea, kItemChanged };

struct Hook {
    HookEvent event = HookEvent::kKill;
    std::int32_t effects = -1;
};

struct Quest {
    std::uint32_t script = 0;
    std::int32_t quest = 0;
    Source source = Source::kTable;
    Support support = Support::kRunnable;
    std::string reason;           // vì sao không chạy được (rỗng khi chạy được)
    bool in_client = true;
    std::int32_t kind = 0;        // loại nhiệm vụ của client (màu, nhóm trong sổ)
    std::int32_t level = 0;
    Repeat repeat = Repeat::kOnce;
    std::string name;
    std::uint32_t name_id = 0;    // ops::name_id(name): so với tên mà script so (TGetMissionName)
    std::int32_t accept_scene = -1;
    std::int32_t accept_guid = 0;
    std::int32_t turn_scene = -1;
    std::int32_t turn_guid = 0;
    std::int32_t accept_cond = -1;
    std::int32_t ready_cond = -1;
    std::int32_t accept_fx = -1;
    std::int32_t submit_fx = -1;
    std::int32_t abandon_fx = -1;
    std::int32_t next_quest = -1;
    std::uint32_t next_script = 0;
    std::int32_t penalty = 0;
    std::int32_t ban_slot = -1;
    std::int32_t ban_seconds = 0;
    std::uint8_t watch = 0;       // bit kWatch* của book.hpp
    std::vector<std::int32_t> prereqs;
    std::vector<Objective> objectives;
    std::vector<Reward> rewards;
    std::vector<Hook> hooks;

    [[nodiscard]] bool runnable() const noexcept { return support == Support::kRunnable; }
};

enum class NpcRole : std::uint8_t { kGive, kTurn };

struct Offer {
    std::uint32_t script = 0;
    NpcRole role = NpcRole::kGive;
    friend bool operator==(const Offer&, const Offer&) noexcept = default;
    friend auto operator<=>(const Offer&, const Offer&) noexcept = default;
};

// Hàng của mission_auto.tsv: tự nhận khi LÊN ĐÚNG cấp `level`, tự đánh dấu hoàn thành ở cấp `full_level`.
struct AutoRule {
    std::int32_t level = -1;
    std::int32_t quest = 0;
    std::uint32_t script = 0;
    std::int32_t pre_quest = 0;
    std::int32_t event = 0;
    std::int32_t full_level = -1;
    std::int32_t complete_idx = -1;
    std::int32_t record_idx = -1;
    std::string message;  // khoá chuỗi `#{...}`
};

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): bảng TSV do nơi gọi sở hữu, chỉ đọc trong lúc nạp, không sở hữu, không giữ qua tick (SH-04)
struct Tables {
    const table::Tsv& quests;
    const table::Tsv& objectives;
    const table::Tsv& rewards;
    const table::Tsv& prereqs;
    const table::Tsv& hooks;
    const table::Tsv& npcs;
    const table::Tsv& autos;
    const table::Tsv& name_groups;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

struct Options {
    // Cho phép nhận nhiệm vụ không có trong danh bạ client (chỉ để thử; client không hiện được chúng).
    bool allow_not_in_client = false;
};

enum class [[nodiscard]] LoadError : std::uint8_t {
    kNone = 0,          // chỉ là giá trị mặc định của LoadFailure chưa gán
    kBadCell,           // ô sai kiểu hoặc ngoài miền
    kUnknownWord,       // từ khoá lạ (loại mục tiêu, nhóm thưởng...)
    kDuplicateScript,
    kUnknownScript,     // bảng phụ trỏ tới script không có trong mission_quests
    kBadReference,      // id điều kiện hay bộ hiệu ứng không có trong ops::Program
    kBadOrder,          // seq của một script không liền từ 0
    kTooLarge,
};

[[nodiscard]] std::string_view describe(LoadError error) noexcept;

struct LoadFailure {
    LoadError error{};
    std::string table;   // tên bảng
    std::string detail;  // câu lỗi có số dòng
};

struct Report {
    std::size_t quests = 0;
    std::size_t runnable = 0;
    std::size_t unsupported = 0;
    std::size_t not_in_client = 0;
    std::size_t blocked = 0;
    std::size_t missing_prereq_quests = 0;  // có tiền đề không nằm trong danh mục (chỉ làm được nếu sổ đã đánh dấu xong)
    std::vector<std::pair<std::string, std::size_t>> reasons;  // số nhiệm vụ không chạy được theo lý do, sắp tăng theo lý do
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của unordered_map trong STL MSVC (HP-07)
class Catalog {
public:
    [[nodiscard]] static std::expected<Catalog, LoadFailure> load(ops::Program program, const Tables& tables,
        const Options& options);

    [[nodiscard]] const ops::Program& program() const noexcept { return program_; }
    [[nodiscard]] std::span<const Quest> quests() const noexcept { return quests_; }
    [[nodiscard]] const Quest* by_script(std::uint32_t script) const noexcept;
    // Các biến thể của một id nhiệm vụ client, tăng theo script. Rỗng nếu id không có trong danh mục.
    [[nodiscard]] std::vector<const Quest*> variants(std::int32_t quest) const;
    [[nodiscard]] std::span<const AutoRule> autos() const noexcept { return autos_; }

    // Việc giao/trả của NPC: theo guid khi có, nếu không thì theo (cảnh, mã tên). Kết quả không trùng, tăng theo (script, vai).
    [[nodiscard]] std::vector<Offer> offers_at(std::uint32_t guid, std::int32_t scene, std::uint32_t name) const;

    // Nhóm tên (mã băm tên chuẩn hoá) của một mẫu quái; 0 nếu mẫu không thuộc nhóm nào.
    [[nodiscard]] std::uint32_t group_of_template(std::uint32_t monster_template) const noexcept;

    [[nodiscard]] const Report& report() const noexcept { return report_; }

private:
    ops::Program program_;
    std::vector<Quest> quests_;
    std::unordered_map<std::uint32_t, std::size_t> by_script_;
    std::unordered_map<std::int32_t, std::vector<std::size_t>> by_quest_;
    std::unordered_map<std::uint32_t, std::vector<Offer>> by_guid_;
    std::map<std::pair<std::int32_t, std::uint32_t>, std::vector<Offer>> by_name_;
    std::unordered_map<std::uint32_t, std::uint32_t> template_group_;
    std::vector<AutoRule> autos_;
    Report report_;

    friend class CatalogBuilder;
};

}  // namespace game::mission
