#pragma once
// Điều kiện và hiệu ứng ĐÓNG của nội dung gameplay (nhiệm vụ, hội thoại, NPC): tập op cố định, đánh giá thuần trên
// một "góc nhìn" chỉ đọc của nhân vật, kết quả là Plan (danh sách hiệu ứng đã quyết định) để bên gọi áp dụng.
//
// Nguồn thiết kế: TLBB Dev docs/ADR (ADR-001 tập op đóng, ADR-002 sổ cái nguyên tử, ADR-005 phiên hội thoại do máy chủ
// giữ). Dữ liệu do TOOLS/server/lua_extract.py trích tĩnh từ 5.494 script Lua 4.0 của máy chủ 14 môn phái rồi ghi vào
// ops_conditions.tsv và ops_effects.tsv; không có Lua nào chạy ở đây.
//
// Khác gốc: ADR-001 chọn cây biểu thức; bản này dùng DẠNG TUYỂN CHUẨN (OR của các AND, có phủ định ở nguyên tử) vì
// script gốc dùng and/or/not tuỳ ý và lua_extract.py rút về dạng này lúc trích: đánh giá không đệ quy, không cấp phát,
// kích thước mỗi bộ điều kiện có trần (kMaxClauses, kMaxAtoms) nên thời gian đánh giá có chặn trên theo dữ liệu nạp.
//
// Tất định: đánh giá chỉ đọc HeroView, Calendar và Event do bên gọi đưa vào; lịch là ĐẦU VÀO (bên gọi lấy từ tick của
// mô phỏng), không có lời gọi đồng hồ thật nào trong module.

#include "table/tsv.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ops {

// ----- Số liệu cố định -----------------------------------------------------------------------------------------
inline constexpr std::size_t kMaxClauses = 24;       // trần của lua_extract.py (lua_bool.MAX_CLAUSES)
inline constexpr std::size_t kMaxAtoms = 16;         // số nguyên tử tối đa trong một mệnh đề
inline constexpr std::size_t kMaxSetEffects = 256;   // số hiệu ứng tối đa trong một bộ (lua_emit.MAX_SET_EFFECTS)
inline constexpr std::size_t kMaxProgramSets = 200000;  // số bộ điều kiện/hiệu ứng tối đa một chương trình

// ----- Chuỗi ---------------------------------------------------------------------------------------------------
// Mã chuỗi gửi qua dây: FNV-1a 32 bit của khoá (khoá StrDictionary của client hoặc `lua.<băm>` do công cụ trích đặt).
[[nodiscard]] constexpr std::uint32_t string_id(std::string_view key) noexcept {
    std::uint32_t value = 0x811C9DC5U;
    for (const char character : key) {
        value ^= static_cast<std::uint8_t>(character);
        value *= 0x01000193U;
    }
    return value;
}

// Mã tên (NPC, quái): băm tên đã chuẩn hoá (bỏ khoảng trắng kể cả U+3000/U+00A0 và thẻ màu `#X`), cắt về 31 bit.
// Phải trùng từng bit với lua_world.norm_name + fnv1a32 & 0x7FFFFFFF của công cụ trích; test đối chiếu với bảng thật.
[[nodiscard]] std::uint32_t name_id(std::string_view utf8) noexcept;

// ----- Điều kiện -----------------------------------------------------------------------------------------------
// Đại lượng đọc được từ góc nhìn nhân vật hoặc ngữ cảnh. Số đối số chọn (arity) ghi ở metric_arity.
enum class Metric : std::uint8_t {
    kLevel,         // cấp nhân vật
    kItemCount,     // (vật phẩm) số lượng trong các túi
    kBagSpace,      // số ô trống
    kMoney,         // (khoá 0/1) số tiền
    kObjective,     // (nhiệm vụ, chỉ số) tham số mục tiêu trong sổ
    kCounter,       // (chỉ số) bộ đếm dữ liệu nhiệm vụ
    kSect,          // môn phái
    kGender,        // giới tính
    kTeamSize,      // số người trong đội
    kQuestCount,    // số nhiệm vụ đang giữ
    kHour,          // giờ trong ngày (lịch)
    kWeekday,       // thứ trong tuần (lịch)
    kMinute,        // phút (lịch)
    kRadio,         // phần thưởng chọn trong lần nộp này
    kAbility,       // (kỹ năng sống) cấp
    kGuild,         // id bang (-1 là không có)
    kClock,         // (đồng hồ lịch 1..5) giá trị đồng hồ
    kMonster,       // mẫu quái của sự kiện
    kArea,          // vùng của sự kiện
    kEventItem,     // vật phẩm của sự kiện
    kSlotsFree,     // số ô nhiệm vụ trống
};

inline constexpr std::size_t kMetricCount = 21;

[[nodiscard]] std::size_t metric_arity(Metric metric) noexcept;

enum class Op : std::uint8_t {
    kNever,           // luôn sai
    kAtLeast,         // metric >= n
    kIs,              // metric == n
    kTeamLeader,      // là đội trưởng
    kSkillKnown,      // (kỹ năng) đã học
    kQuestActive,     // (nhiệm vụ) đang giữ
    kQuestDone,       // (nhiệm vụ) đã xong
    kFlagSet,         // (cờ) bật
    kCounterVsClock,  // (chỉ số, đồng hồ, quan hệ -1/0/1) bộ đếm so với đồng hồ lịch
    kTargetName,      // mã tên NPC đang nói chuyện
    kEventMonsterName,  // mã tên quái của sự kiện
    kQuestNamed,      // (nhiệm vụ, tên) đang giữ nhiệm vụ mà tên hiển thị của script đang giữ khớp (TGetMissionName)
    kImpactActive,    // (mã hiệu ứng) nhân vật đang chịu hiệu ứng (buff) có mã dữ liệu này
};

struct Atom {
    Op op = Op::kNever;
    Metric metric = Metric::kLevel;  // chỉ dùng với kAtLeast, kIs
    bool negated = false;
    std::array<std::int32_t, 3> arg{};  // selector rồi ngưỡng; kTargetName, kEventMonsterName, kQuestNamed dùng name
    std::uint32_t name = 0;
};

// Một điều kiện: OR của các mệnh đề, mỗi mệnh đề là AND của các nguyên tử. Không có mệnh đề nào là luôn sai.
struct CondSet {
    std::vector<std::vector<Atom>> clauses;
};

// ----- Góc nhìn nhân vật và ngữ cảnh ---------------------------------------------------------------------------
// Chỉ đọc, thuần ảo để lõi không biết túi, sổ hay đội cụ thể (bên gọi nối). Mọi hàm là truy vấn không đổi trạng thái.
class HeroView {
public:
    HeroView() = default;
    HeroView(const HeroView&) = delete;
    HeroView& operator=(const HeroView&) = delete;
    HeroView(HeroView&&) = delete;
    HeroView& operator=(HeroView&&) = delete;
    virtual ~HeroView() = default;

    [[nodiscard]] virtual std::int32_t level() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t sect() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t gender() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t team_size() const noexcept = 0;
    [[nodiscard]] virtual bool team_leader() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t guild() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t bag_space() const noexcept = 0;
    [[nodiscard]] virtual std::int64_t money(bool bound) const noexcept = 0;
    [[nodiscard]] virtual std::int64_t item_count(std::uint32_t item) const noexcept = 0;
    [[nodiscard]] virtual std::int32_t ability(std::int32_t skill) const noexcept = 0;
    [[nodiscard]] virtual bool skill_known(std::int32_t skill) const noexcept = 0;
    [[nodiscard]] virtual bool quest_active(std::uint32_t quest) const noexcept = 0;
    [[nodiscard]] virtual bool quest_done(std::uint32_t quest) const noexcept = 0;
    // Mã tên (name_id) của nhiệm vụ đang giữ theo script nó được nhận bằng; 0 khi không giữ hoặc script không có trong danh mục.
    [[nodiscard]] virtual std::uint32_t quest_name(std::uint32_t quest) const noexcept = 0;
    // Đang chịu hiệu ứng (buff) mã `impact`. Hệ hiệu ứng thuộc vai combat; mặc định không có hiệu ứng nào để lõi chạy được
    // trước khi nó nối vào.
    [[nodiscard]] virtual bool impact_active(std::int32_t impact) const noexcept {
        static_cast<void>(impact);
        return false;
    }
    [[nodiscard]] virtual std::int32_t quest_count() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t quest_slots_free() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t objective(std::uint32_t quest, std::int32_t index) const noexcept = 0;
    [[nodiscard]] virtual std::int64_t counter(std::int32_t index) const noexcept = 0;
    [[nodiscard]] virtual bool flag(std::int32_t index) const noexcept = 0;
};

// Lịch là đầu vào của máy chủ (tính từ tick mô phỏng + múi giờ cấu hình), không đọc đồng hồ máy.
// clock: 1 ngày, 2 giờ (từ gốc), 3 khắc (15 phút), 4 tuần, 5 giây kể từ gốc Unix.
struct Calendar {
    std::int64_t day = 0;
    std::int64_t hour_time = 0;
    std::int64_t quarter_time = 0;
    std::int64_t week_time = 0;
    std::int64_t unix_seconds = 0;
    std::int32_t hour = 0;
    std::int32_t minute = 0;
    std::int32_t weekday = 0;

    [[nodiscard]] std::int64_t clock(std::int32_t which) const noexcept;
    friend bool operator==(const Calendar&, const Calendar&) noexcept = default;
};

// Sự kiện đang xử lý (giết quái, vào vùng, đổi vật phẩm); các trường không dùng là 0.
struct Event {
    std::uint32_t monster = 0;
    std::uint32_t monster_name = 0;
    std::int32_t area = 0;
    std::uint32_t item = 0;
};

struct Context {
    const HeroView* hero = nullptr;  // bắt buộc
    Calendar calendar{};
    Event event{};
    std::int32_t radio = -1;         // phần thưởng chọn (id vật phẩm), -1 là chưa chọn
    std::uint32_t target_name = 0;   // mã tên NPC đang đối thoại, 0 là không có
};

[[nodiscard]] bool holds(const CondSet& set, const Context& context) noexcept;
[[nodiscard]] bool holds(const Atom& atom, const Context& context) noexcept;

// ----- Hiệu ứng ------------------------------------------------------------------------------------------------
enum class EffectOp : std::uint8_t {
    kGiveItem,        // (vật phẩm, số lượng)
    kTakeItem,        // (vật phẩm, số lượng)
    kGiveMoney,       // (số tiền, khoá 0/1)
    kTakeMoney,       // (số tiền, khoá 0/1)
    kGiveExp,         // (kinh nghiệm)
    kQuestAccept,     // (nhiệm vụ, script)
    kQuestRemove,     // (nhiệm vụ)
    kQuestMarkDone,   // (nhiệm vụ)
    kObjectiveSet,    // (nhiệm vụ, chỉ số, giá trị)
    kObjectiveAdd,    // (nhiệm vụ, chỉ số, bước)
    kSetCounter,      // (chỉ số, giá trị)
    kCounterAdd,      // (chỉ số, bước)
    kSetCounterClock, // (chỉ số, đồng hồ): lưu giá trị đồng hồ lịch hiện tại
    kSetFlag,         // (cờ)
    kClearFlag,       // (cờ)
    kNotify,          // thông báo cho người chơi (chuỗi)
    kAnnounce,        // thông báo toàn máy chủ (chuỗi)
    kTeleport,        // (cảnh, x, z)
    kOpenShop,        // (cửa hàng)
    kSignpost,        // (cảnh, x, z, chuỗi): dấu chỉ đường tới NPC
    kSignpostPos,     // (cảnh, x, z, chuỗi): dấu chỉ đường tới toạ độ
    kOfferNext,       // (nhiệm vụ): mở tiếp nhiệm vụ kế
    kUiCommand,       // (lệnh, số 1, số 2): lệnh giao diện cho client (DispatchUICommand của script gốc)
};

// Tham số có kiểu của một chuỗi: máy chủ gửi mã chuỗi + các tham số này, client tự dựng câu (ADR-003).
struct TextParam {
    enum class Kind : std::uint8_t { kPlayer, kNpc, kMetric };
    Kind kind = Kind::kPlayer;
    Metric metric = Metric::kLevel;
    std::array<std::int32_t, 2> arg{};  // selector của metric (tối đa hai)
};

struct TextRef {
    std::uint32_t id = 0;  // 0 là không có chuỗi
    std::vector<TextParam> params;
};

// Đọc cột `args` của bảng (các tham số cách nhau dấu phẩy: `player`, `npc`, hoặc `<đại lượng>[:<đối số>[:<đối số>]]`).
// Trả nullopt khi có đại lượng lạ, số hỏng hoặc quá 8 tham số; ô rỗng cho danh sách rỗng.
[[nodiscard]] std::optional<std::vector<TextParam>> parse_text_params(std::string_view cell);

struct Effect {
    EffectOp op = EffectOp::kNotify;
    std::array<std::int32_t, 3> arg{};
    TextRef text;
    std::int32_t cond = -1;  // id bộ điều kiện của hiệu ứng; -1 là luôn chạy
};

struct EffectList {
    std::vector<Effect> effects;
};

// Kế hoạch: hiệu ứng đã quyết định (điều kiện của từng hiệu ứng được đánh giá trên TRẠNG THÁI TRƯỚC khi áp dụng bất kỳ
// hiệu ứng nào, đúng nghĩa chuỗi if/elseif của script gốc). Con trỏ trỏ vào Program, sống tới khi Program bị huỷ.
struct Plan {
    std::vector<const Effect*> steps;
};

// ----- Chương trình --------------------------------------------------------------------------------------------
enum class [[nodiscard]] LoadError : std::uint8_t {
    kNone = 0,  // chỉ là giá trị mặc định của LoadFailure chưa gán
    kMissingColumn,
    kBadNumber,
    kUnknownOp,
    kOutOfRange,
    kSetIdGap,
    kTooLarge,
    kBadReference,
    kUnknownMetric,
};

[[nodiscard]] std::string_view describe(LoadError error) noexcept;

struct LoadFailure {
    LoadError error{};
    std::size_t line = 0;  // dòng của tệp bảng (từ 1); 0 khi không gắn dòng
    std::string detail;
};

class Program {
public:
    Program() = default;

    // Nạp từ hai bảng đã parse. Mọi id điều kiện của hiệu ứng phải trỏ vào bộ điều kiện có thật. Id bộ phải liền 1..N.
    [[nodiscard]] static std::expected<Program, LoadFailure> load(const table::Tsv& conditions,
        const table::Tsv& effects);

    [[nodiscard]] const CondSet* condition(std::int32_t id) const noexcept;
    [[nodiscard]] const EffectList* effect_list(std::int32_t id) const noexcept;

    // id -1 là luôn đúng; id không có trong chương trình là sai (dữ liệu hỏng không được cho qua).
    [[nodiscard]] bool holds(std::int32_t condition_id, const Context& context) const noexcept;

    // Plan của một bộ hiệu ứng (-1 là rỗng). Bộ không có thì plan rỗng và `found` = false.
    [[nodiscard]] Plan plan(std::int32_t effects_id, const Context& context) const;
    [[nodiscard]] bool has_effects(std::int32_t effects_id) const noexcept;

    [[nodiscard]] std::size_t condition_count() const noexcept { return conditions_.size(); }
    [[nodiscard]] std::size_t effect_list_count() const noexcept { return lists_.size(); }

private:
    std::vector<CondSet> conditions_;
    std::vector<EffectList> lists_;
};

// Giá trị số của tham số chuỗi (kMetric) tại thời điểm gửi; kPlayer, kNpc do bên gọi điền tên.
[[nodiscard]] std::int64_t param_value(const TextParam& param, const Context& context) noexcept;

}  // namespace game::ops
