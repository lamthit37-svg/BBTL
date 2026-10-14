#pragma once
// Chương trình hội thoại: các khối bước (text, option, branch, call, effects, dispatch, bonus) do TOOLS/server/lua_extract.py
// trích tĩnh từ hàm OnDefaultEvent / OnEventRequest của script NPC và script nhiệm vụ trong Public/Data/Script của máy chủ
// 14 môn phái. Không có Lua nào chạy ở đây; điều kiện và hiệu ứng nằm trong ops::Program.
//
// Khoá của một điểm vào là (script, num): num = -1 là OnDefaultEvent (bấm vào NPC hoặc chọn mục không số), còn lại là
// OnEventRequest với GetNumText() == num (script thật có cả num âm, -9..-2). Điểm vào không trích được (status unsupported) mang lý do; điểm vào của script
// không có hội thoại (no_dialog) không có khối. Hai loại đó không bị bỏ im: Script::report() đếm theo lý do.
//
// Khối là danh sách bước liền theo seq. `goto` là nhảy cuối (phần còn lại của luồng đã nằm trong khối đích), `call` chạy khối
// rồi quay lại, `ret` thoát khối `call` gần nhất (hoặc cả điểm vào). Khối không có dòng nào là khối rỗng hợp lệ (nhánh trống).

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
#include <vector>

namespace game::talk {

enum class StepKind : std::uint8_t {
    kBegin, kText, kOption, kBranch, kGoto, kCall, kRet, kDispatch, kBonus, kEffects,
    kPick,  // a = n: n bước kText liền sau; chạy đúng một chữ chọn đều ngẫu nhiên, bỏ n - 1 chữ còn lại
};

enum class DispatchKind : std::uint8_t { kList, kBox, kMissionInfo, kContinue, kDemand, kTips };
enum class BonusWord : std::uint8_t { kMoney, kItem, kRadio, kRandom, kDemand };

struct Step {
    StepKind kind = StepKind::kBegin;
    DispatchKind dispatch = DispatchKind::kList;  // chỉ với kDispatch
    BonusWord bonus = BonusWord::kMoney;          // chỉ với kBonus
    std::int32_t cond = -1;                       // chỉ với kBranch: bộ điều kiện của ops::Program
    // kOption: a = script đích, b = biểu tượng, c = giá trị. kBranch: a = khối then, b = khối else (0 là không có).
    // kPick: a = số chữ (1..64). Một lựa chọn được tính lại ở chế độ khô thì kPick luôn lấy chữ đầu và không tốn ngẫu nhiên.
    // kGoto, kCall: a = khối. kEffects: a = bộ hiệu ứng. kBonus: a, b, c là các số của dòng thưởng.
    std::int32_t a = 0;
    std::int32_t b = 0;
    std::int32_t c = 0;
    ops::TextRef text;                            // kText, kOption
};

enum class EntryStatus : std::uint8_t { kOk, kNoDialog, kUnsupported };

struct Entry {
    std::uint32_t script = 0;
    std::int32_t num = -1;
    std::uint32_t block = 0;
    EntryStatus status = EntryStatus::kOk;
    std::string reason;  // chỉ với kUnsupported
};

enum class [[nodiscard]] LoadError : std::uint8_t {
    kNone = 0,       // chỉ là giá trị mặc định của LoadFailure chưa gán
    kBadCell,
    kUnknownWord,
    kBadOrder,       // seq của một khối không liền từ 0
    kBadReference,   // điều kiện hay bộ hiệu ứng không có trong ops::Program, hoặc khối ngoài miền
    kDuplicateEntry,
    kTooLarge,
};

[[nodiscard]] std::string_view describe(LoadError error) noexcept;

struct LoadFailure {
    LoadError error{};
    std::string table;
    std::string detail;
};

// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): bảng TSV do nơi gọi sở hữu, chỉ đọc trong lúc nạp, không sở hữu, không giữ qua tick (SH-04)
struct Tables {
    const table::Tsv& blocks;
    const table::Tsv& entries;
    const table::Tsv& roles;
    const table::Tsv& events;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

struct ScriptReport {
    std::size_t blocks = 0;
    std::size_t steps = 0;
    std::size_t entries = 0;
    std::size_t ok = 0;
    std::size_t no_dialog = 0;
    std::size_t unsupported = 0;
    std::size_t npc_scripts = 0;
    // Số điểm vào không chạy được theo lý do (đã bỏ số riêng của từng script), sắp tăng theo lý do.
    std::vector<std::pair<std::string, std::size_t>> reasons;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của unordered_map trong STL MSVC (HP-07)
class Script {
public:
    [[nodiscard]] static std::expected<Script, LoadFailure> load(const ops::Program& program, const Tables& tables);

    // Các bước của khối; khối không có dòng nào (hoặc id lạ) trả danh sách rỗng.
    [[nodiscard]] std::span<const Step> block(std::uint32_t id) const noexcept;
    [[nodiscard]] const Entry* entry(std::uint32_t script, std::int32_t num) const noexcept;
    // Script NPC (có trong talk_npc_roles) hay không.
    [[nodiscard]] bool is_npc_script(std::uint32_t script) const noexcept { return npc_scripts_.contains(script); }
    [[nodiscard]] const ScriptReport& report() const noexcept { return report_; }

private:
    struct Span {
        std::size_t begin = 0;
        std::size_t end = 0;
    };

    std::vector<Step> steps_;
    std::unordered_map<std::uint32_t, Span> blocks_;
    std::vector<Entry> entries_;  // sắp tăng theo (script, num)
    std::unordered_map<std::uint32_t, std::size_t> npc_scripts_;  // script NPC -> số sự kiện nó đăng ký
    ScriptReport report_;

    friend class ScriptBuilder;
};

}  // namespace game::talk
