#pragma once
// Bảng luật AI quái có kiểu (monster_ai_rules.tsv, monster_ai_rule_files.tsv), sinh bởi TOOLS/server/ai_convert.py
// từ 307 tệp scriptN.ai của XJL7457. Bộ nạp chỉ NẠP và SẮP luật; chạy luật thuộc về zone.
//
// Ngữ nghĩa lấy từ AIScript.cpp, AIScriptFunction.cpp, AIScriptDef.h và State.h của máy chủ 2008:
//   * một kịch bản có năm đoạn [common] [skill] [beskill] [damage] [dead]; mỗi lần xử lý một đoạn, chỉ luật
//     ĐẦU TIÊN (theo thứ tự ưu tiên) có mọi điều kiện đúng và còn lượt thì chạy, rồi dừng;
//   * `times` là số lần luật được chạy: -1 vô hạn, 0 là không bao giờ (đây cũng là giá trị khi tệp vắng
//     AIS_SetTimes); luật có `times` hữu hạn phải được đếm theo `rule_index` trên từng quái;
//   * `priority` vắng thì -1; luật xếp ưu tiên giảm dần, bằng nhau giữ thứ tự tệp (sắp ổn định) — bộ nạp đã
//     sắp sẵn trong AiScript::sections;
//   * điều kiện nối bằng VÀ; trong [common], luật có điều kiện get_ai_state chỉ chạy ở trạng thái đó.
// Khác gốc: mã 2008 phân tích chữ khi nạp và gọi hàm qua bảng con trỏ; ở đây luật đã là dữ liệu có kiểu, hàm là
// enum. 3 luật của dữ liệu thật không biểu diễn được (dấu "(" thay "{") bị ai_convert.py bỏ và báo ở đó.

#include "scenedata/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scenedata {

inline constexpr std::size_t kMaxAiRows = 400'000;
inline constexpr std::size_t kMaxAiScripts = 20'000;
inline constexpr std::size_t kMaxAiRulesPerScript = 4096;
inline constexpr std::size_t kMaxAiAtomsPerRule = 64;

enum class AiSection : std::uint8_t { kCommon, kSkill, kBeSkill, kDamage, kDead };
inline constexpr std::size_t kAiSectionCount = 5;

enum class AiCompare : std::uint8_t { kEq, kNe, kLt, kLe, kGt, kGe };

// Hàm điều kiện (kConst..kIsCanSkill) rồi hàm hành động (kBeSkill..kStartPatrol). AIS_SetTimes và AIS_SetPRI
// không có ở đây: chúng là đầu luật (times, priority), không phải nguyên tử.
enum class AiFunction : std::uint8_t {
    kConst,
    kGetBuffState,
    kGetAiState,
    kGetHp,
    kGetMp,
    kRand,
    kGetEnemyBuffState,
    kGetEnemyMp,
    kGetEnemyHp,
    kGetEnemySect,
    kGetEnemyLevel,
    kIsCanSpeak,
    kIsHasEnemy,
    kGetEnemySex,
    kGetCamp,
    kGetPk,
    kGetEnemyTeamNum,
    kIsEnemyHasSpecialItem,
    kGetSingleDamage,
    kGetEnemyNum,
    kIsBoss,
    kIsCanSkill,
    kBeSkill,
    kToFlee,
    kToSkill,
    kToSummon,
    kToLongAttack,
    kToFollow,
    kToSpeak,
    kToAssistTeammate,
    // Năm hàm bản private thêm, mã 2008 không có; tên suy ra từ chữ, ngữ nghĩa chưa có mã để đối chiếu.
    kCallOtherMonsterByGroup,
    kCallOtherMonsterByTeam,
    kSetBaseAiType,
    kSetPatrolId,
    kStartPatrol,
};

// Hàm này đứng được ở vế điều kiện (if) hay hành động (do).
[[nodiscard]] constexpr bool is_condition(AiFunction function) noexcept {
    return function <= AiFunction::kIsCanSkill;
}

// Hàm mà tham số đầu là id kỹ năng (cột skill_id của bảng).
[[nodiscard]] constexpr bool takes_skill_id(AiFunction function) noexcept {
    return function == AiFunction::kIsCanSkill || function == AiFunction::kToSkill || function == AiFunction::kBeSkill;
}

// Tên trong bảng ("get_hp", "to_skill"...) sang enum; nullopt khi tên lạ.
[[nodiscard]] std::optional<AiFunction> ai_function_from_name(std::string_view name) noexcept;
[[nodiscard]] std::string_view ai_function_name(AiFunction function) noexcept;

// Một nguyên tử: điều kiện `hàm(args) <so sánh> value` hay hành động `hàm(args)`. Tham số vắng là -1. Hành
// động có compare = kEq và value = 0 (không dùng).
struct AiAtom {
    AiFunction function = AiFunction::kConst;
    AiCompare compare = AiCompare::kEq;
    std::int32_t value = 0;
    std::array<std::int32_t, 3> args{-1, -1, -1};
};

struct AiRule {
    // Số thứ tự dòng luật trong tệp .ai (tăng theo từng dòng có dấu `:`, kể cả dòng hỏng nên có thể có lỗ).
    // Mã 2008 dùng nó làm chỗ đếm số lần của luật trên từng quái.
    std::uint32_t rule_index = 0;
    std::int32_t priority = -1;
    std::int32_t times = 0;
    std::vector<AiAtom> conditions;
    std::vector<AiAtom> actions;
};

struct AiScript {
    std::int32_t ai_id = 0;
    // Theo AiSection; mỗi đoạn đã sắp ưu tiên giảm dần, bằng nhau giữ thứ tự tệp.
    std::array<std::vector<AiRule>, kAiSectionCount> sections;

    [[nodiscard]] std::span<const AiRule> rules(AiSection section) const noexcept {
        // Qua std::span để chỉ số lúc chạy được kiểm biên ở chế độ hardening; AiSection luôn < kAiSectionCount.
        return std::span<const std::vector<AiRule>, kAiSectionCount>{sections}[static_cast<std::size_t>(section)];
    }
    [[nodiscard]] std::size_t rule_count() const noexcept;
};

class AiRuleTable {
public:
    AiRuleTable() = default;
    explicit AiRuleTable(std::vector<AiScript> scripts) noexcept : scripts_(std::move(scripts)) {}

    // nullptr khi không có kịch bản ai_id. Kịch bản không có luật nào biểu diễn được vẫn có mặt (rỗng).
    [[nodiscard]] const AiScript* find(std::int32_t ai_id) const noexcept;
    [[nodiscard]] std::span<const AiScript> scripts() const noexcept { return scripts_; }
    [[nodiscard]] std::size_t rule_count() const noexcept;

private:
    std::vector<AiScript> scripts_; // sắp ai_id tăng dần, không lặp
};

// Văn bản hai bảng của một bộ luật AI. rules: monster_ai_rules.tsv (mỗi dòng một nguyên tử; các dòng của một
// luật liền nhau, vế `if` rồi vế `do`, seq tăng từ 0). files: monster_ai_rule_files.tsv, danh sách mọi kịch bản
// kể cả kịch bản không có luật nào; mỗi kịch bản có dòng luật phải có trong danh sách này và số luật phải khớp
// cột `rules`. Hai trường cùng kiểu nên đi cùng nhau trong một struct để không đảo nhầm chỗ.
struct AiRuleTexts {
    std::string_view rules;
    std::string_view files;
};

// Lỗi: tên hàm lạ, hàm sai vế, so sánh lạ, đầu luật lệch giữa các dòng của cùng luật, rule_index không tăng
// ngặt, skill_id lệch arg_0, vượt các trần kMaxAi*.
[[nodiscard]] Loaded<AiRuleTable> parse_ai_rules(const AiRuleTexts& texts);

} // namespace game::scenedata
