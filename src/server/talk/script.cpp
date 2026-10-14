// Nạp chương trình hội thoại từ talk_blocks / talk_entries / talk_npc_roles / talk_npc_events. Mọi ô là dữ liệu từ tệp nên bị
// coi là thù địch: từ khoá lạ, seq không liền, id khối ngoài miền, điều kiện hay bộ hiệu ứng không có trong ops::Program đều là
// lỗi nạp có số dòng. Khối trỏ tới id không có dòng nào là khối rỗng (script gốc có nhánh trống), không phải lỗi.
#include "talk/script.hpp"

#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::talk {

namespace {

constexpr std::int32_t kMaxInt = std::numeric_limits<std::int32_t>::max();
constexpr std::int32_t kMaxBlockId = 1 << 24;
constexpr std::size_t kMaxSteps = 4'000'000;
constexpr std::size_t kMaxBlockSteps = 4096;
constexpr std::size_t kMaxEntries = 1'000'000;
constexpr std::size_t kMaxNpcScripts = 200'000;
constexpr std::int32_t kMaxPick = 64;

template <typename Enum>
struct Word {
    std::string_view text;
    Enum value;
};

template <typename Enum, std::size_t Count>
[[nodiscard]] std::optional<Enum> lookup(const std::array<Word<Enum>, Count>& words, std::string_view text) noexcept {
    for (const Word<Enum>& word : words) {
        if (word.text == text) return word.value;
    }
    return std::nullopt;
}

constexpr std::array<Word<StepKind>, 11> kKindWords{{
    {.text = "begin", .value = StepKind::kBegin},
    {.text = "text", .value = StepKind::kText},
    {.text = "option", .value = StepKind::kOption},
    {.text = "branch", .value = StepKind::kBranch},
    {.text = "goto", .value = StepKind::kGoto},
    {.text = "call", .value = StepKind::kCall},
    {.text = "ret", .value = StepKind::kRet},
    {.text = "dispatch", .value = StepKind::kDispatch},
    {.text = "bonus", .value = StepKind::kBonus},
    {.text = "effects", .value = StepKind::kEffects},
    {.text = "pick", .value = StepKind::kPick},
}};
constexpr std::array<Word<DispatchKind>, 6> kDispatchWords{{
    {.text = "list", .value = DispatchKind::kList},
    {.text = "box", .value = DispatchKind::kBox},
    {.text = "mission_info", .value = DispatchKind::kMissionInfo},
    {.text = "continue", .value = DispatchKind::kContinue},
    {.text = "demand", .value = DispatchKind::kDemand},
    {.text = "tips", .value = DispatchKind::kTips},
}};
constexpr std::array<Word<BonusWord>, 5> kBonusWords{{
    {.text = "money", .value = BonusWord::kMoney},
    {.text = "item", .value = BonusWord::kItem},
    {.text = "radio", .value = BonusWord::kRadio},
    {.text = "random", .value = BonusWord::kRandom},
    {.text = "demand", .value = BonusWord::kDemand},
}};
constexpr std::array<Word<EntryStatus>, 3> kStatusWords{{
    {.text = "ok", .value = EntryStatus::kOk},
    {.text = "no_dialog", .value = EntryStatus::kNoDialog},
    {.text = "unsupported", .value = EntryStatus::kUnsupported},
}};

// Bỏ số riêng của từng script khỏi lý do để các lý do cùng loại gộp thành một dòng báo cáo.
[[nodiscard]] std::string reason_class(std::string_view reason) {
    std::string out;
    bool in_digits = false;
    for (const char character : reason) {
        const bool digit = character >= '0' && character <= '9';
        if (digit && !in_digits) out += 'N';
        if (!digit) out += character;
        in_digits = digit;
    }
    return out;
}

}  // namespace

std::string_view describe(LoadError error) noexcept {
    switch (error) {
        case LoadError::kNone: return "không lỗi";
        case LoadError::kBadCell: return "ô sai kiểu hoặc ngoài miền";
        case LoadError::kUnknownWord: return "từ khoá không thuộc tập đóng";
        case LoadError::kBadOrder: return "seq không liền từ 0";
        case LoadError::kBadReference: return "tham chiếu tới điều kiện, bộ hiệu ứng hay khối không có";
        case LoadError::kDuplicateEntry: return "điểm vào trùng";
        case LoadError::kTooLarge: return "vượt trần kích thước";
    }
    return "lỗi không rõ";
}

class ScriptBuilder {
public:
    ScriptBuilder(Script& script, const ops::Program& program, const Tables& tables)
        : script_(script), program_(program), tables_(tables) {}

    [[nodiscard]] std::expected<void, LoadFailure> run() {
        if (auto step = read_blocks(); !step) return step;
        if (auto step = read_entries(); !step) return step;
        if (auto step = read_roles(); !step) return step;
        return read_events();
    }

private:
    using Result = std::expected<void, LoadFailure>;

    [[nodiscard]] static std::unexpected<LoadFailure> failure(LoadError error, std::string_view table, std::string detail) {
        return std::unexpected(LoadFailure{.error = error, .table = std::string(table), .detail = std::move(detail)});
    }

    [[nodiscard]] static std::unexpected<LoadFailure> bad_cell(std::string_view table, const table::RowReader& reader) {
        const std::optional<std::string>& cause = reader.error();
        return failure(LoadError::kBadCell, table, cause.value_or(std::string{}));
    }

    [[nodiscard]] static std::string where(const table::Tsv& table, std::size_t row, std::string_view what) {
        return "dòng " + std::to_string(table.lines.at(row)) + ": " + std::string(what);
    }

    // Đọc nội dung riêng của từng loại bước từ ô text/args; trả lỗi ngay nếu từ khoá lạ hoặc tham chiếu treo.
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ và tham số là hai ô khác vai, nơi gọi nêu tên (HP-07)
    [[nodiscard]] Result fill(Step& step, std::string_view text, std::string_view args, std::size_t row) const {
        const table::Tsv& table = tables_.blocks;
        switch (step.kind) {
            case StepKind::kText:
            case StepKind::kOption: {
                if (!text.empty()) step.text.id = ops::string_id(text);
                auto params = ops::parse_text_params(args);
                if (!params) return failure(LoadError::kUnknownWord, "talk_blocks", where(table, row, "args " + std::string(args)));
                step.text.params = std::move(*params);
                return {};
            }
            case StepKind::kDispatch: {
                const auto kind = lookup(kDispatchWords, text);
                if (!kind) return failure(LoadError::kUnknownWord, "talk_blocks", where(table, row, "dispatch " + std::string(text)));
                step.dispatch = *kind;
                return {};
            }
            case StepKind::kBonus: {
                const auto kind = lookup(kBonusWords, text);
                if (!kind) return failure(LoadError::kUnknownWord, "talk_blocks", where(table, row, "bonus " + std::string(text)));
                step.bonus = *kind;
                return {};
            }
            case StepKind::kBegin:
            case StepKind::kBranch:
            case StepKind::kGoto:
            case StepKind::kCall:
            case StepKind::kRet:
            case StepKind::kPick:
            case StepKind::kEffects: return {};
        }
        return {};
    }

    [[nodiscard]] bool blocks_ok(const Step& step) const noexcept {
        const auto in_range = [](std::int32_t id, std::int32_t low) { return id >= low && id <= kMaxBlockId; };
        switch (step.kind) {
            case StepKind::kBranch: return in_range(step.a, 1) && in_range(step.b, 0);
            case StepKind::kGoto:
            case StepKind::kCall: return in_range(step.a, 1);
            case StepKind::kEffects: return program_.has_effects(step.a);
            case StepKind::kPick: return step.a >= 1 && step.a <= kMaxPick;
            default: return true;
        }
    }

    // Mỗi kPick(n) phải có n bước kText liền sau nó trong cùng khối: bộ chạy bỏ qua n bước đó nên không được lẫn bước khác vào.
    [[nodiscard]] bool picks_ok(std::size_t begin, std::size_t end) const noexcept {
        for (std::size_t at = begin; at < end; ++at) {
            const Step& step = script_.steps_[at];
            if (step.kind != StepKind::kPick) continue;
            const auto count = static_cast<std::size_t>(step.a);
            if (end - at <= count) return false;
            for (std::size_t offset = 1; offset <= count; ++offset) {
                if (script_.steps_[at + offset].kind != StepKind::kText) return false;
            }
        }
        return true;
    }

    Result read_blocks() {
        const table::Tsv& table = tables_.blocks;
        if (table.rows.size() > kMaxSteps) return failure(LoadError::kTooLarge, "talk_blocks", "quá nhiều dòng");
        script_.steps_.reserve(table.rows.size());
        std::int64_t current = -1;
        std::int32_t next_seq = 0;
        std::size_t begin = 0;
        const auto close_block = [&]() -> Result {
            if (current < 0) return {};
            if (!picks_ok(begin, script_.steps_.size())) {
                return failure(LoadError::kBadReference, "talk_blocks", "khối " + std::to_string(current) + ": pick không có đủ chữ liền sau");
            }
            script_.blocks_[static_cast<std::uint32_t>(current)] = Script::Span{.begin = begin, .end = script_.steps_.size()};
            return {};
        };
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::int32_t block = reader.integer("block", 1, kMaxBlockId);
            const std::int32_t seq = reader.integer("seq", 0, static_cast<std::int32_t>(kMaxBlockSteps) - 1);
            const std::string_view kind = reader.text("kind");
            Step step;
            step.cond = reader.integer("cond", -1, kMaxInt);
            step.a = reader.integer("a", std::numeric_limits<std::int32_t>::min(), kMaxInt);
            step.b = reader.integer("b", std::numeric_limits<std::int32_t>::min(), kMaxInt);
            step.c = reader.integer("c", std::numeric_limits<std::int32_t>::min(), kMaxInt);
            const std::string_view text = reader.text("text");
            const std::string_view args = reader.text("args");
            if (reader.error()) return bad_cell("talk_blocks", reader);
            const std::optional<StepKind> parsed = lookup(kKindWords, kind);
            if (!parsed) return failure(LoadError::kUnknownWord, "talk_blocks", where(table, row, kind));
            step.kind = *parsed;
            if (block != current) {
                if (block < current) return failure(LoadError::kBadOrder, "talk_blocks", where(table, row, "block lùi"));
                if (auto closed = close_block(); !closed) return closed;
                current = block;
                next_seq = 0;
                begin = script_.steps_.size();
            }
            if (seq != next_seq++) return failure(LoadError::kBadOrder, "talk_blocks", where(table, row, "seq"));
            if (step.cond != -1 && program_.condition(step.cond) == nullptr) {
                return failure(LoadError::kBadReference, "talk_blocks", where(table, row, "cond"));
            }
            if (!blocks_ok(step)) return failure(LoadError::kBadReference, "talk_blocks", where(table, row, "khối hoặc bộ hiệu ứng"));
            if (auto filled = fill(step, text, args, row); !filled) return filled;
            script_.steps_.push_back(std::move(step));
        }
        if (auto closed = close_block(); !closed) return closed;
        script_.report_.blocks = script_.blocks_.size();
        script_.report_.steps = script_.steps_.size();
        return {};
    }

    Result read_entries() {
        const table::Tsv& table = tables_.entries;
        if (table.rows.size() > kMaxEntries) return failure(LoadError::kTooLarge, "talk_entries", "quá nhiều dòng");
        ScriptReport& report = script_.report_;
        std::map<std::string, std::size_t> reasons;
        std::set<std::pair<std::uint32_t, std::int32_t>> seen;
        script_.entries_.reserve(table.rows.size());
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            Entry entry;
            entry.script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            entry.num = reader.integer("num", std::numeric_limits<std::int32_t>::min(), kMaxInt);  // GetNumText có thể âm (bảng thật có -9..-2)
            const std::int32_t block = reader.integer("block", 0, kMaxBlockId);
            const std::string_view status = reader.text("status");
            entry.reason = std::string(reader.text("reason"));
            if (reader.error()) return bad_cell("talk_entries", reader);
            const auto parsed = lookup(kStatusWords, status);
            if (!parsed) return failure(LoadError::kUnknownWord, "talk_entries", where(table, row, status));
            entry.status = *parsed;
            entry.block = static_cast<std::uint32_t>(block);
            if (entry.status == EntryStatus::kOk && block == 0) {
                return failure(LoadError::kBadReference, "talk_entries", where(table, row, "điểm vào ok không có khối"));
            }
            if (entry.status == EntryStatus::kUnsupported && entry.reason.empty()) entry.reason = "không rõ (bảng trích không ghi)";
            ++report.entries;
            switch (entry.status) {
                case EntryStatus::kOk: ++report.ok; break;
                case EntryStatus::kNoDialog: ++report.no_dialog; break;
                case EntryStatus::kUnsupported:
                    ++report.unsupported;
                    ++reasons[reason_class(entry.reason)];
                    break;
            }
            const auto key = std::make_pair(entry.script, entry.num);
            if (!seen.insert(key).second) {
                return failure(LoadError::kDuplicateEntry, "talk_entries", where(table, row, std::to_string(key.first)));
            }
            script_.entries_.push_back(std::move(entry));
        }
        std::ranges::sort(script_.entries_, {}, [](const Entry& entry) { return std::pair{entry.script, entry.num}; });
        report.reasons.assign(reasons.begin(), reasons.end());
        return {};
    }

    Result read_roles() {
        const table::Tsv& table = tables_.roles;
        if (table.rows.size() > kMaxNpcScripts) return failure(LoadError::kTooLarge, "talk_npc_roles", "quá nhiều dòng");
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::string_view path = reader.text("path");
            const std::uint32_t events = reader.number("events", 0, 1'000'000);
            if (reader.error()) return bad_cell("talk_npc_roles", reader);
            if (path.empty() || !script_.npc_scripts_.emplace(script, events).second) {
                return failure(LoadError::kBadReference, "talk_npc_roles", where(table, row, std::to_string(script)));
            }
        }
        script_.report_.npc_scripts = script_.npc_scripts_.size();
        return {};
    }

    Result read_events() {
        const table::Tsv& table = tables_.events;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            static_cast<void>(reader.integer("seq", 0, kMaxInt));
            static_cast<void>(reader.integer("event", 0, kMaxInt));
            if (reader.error()) return bad_cell("talk_npc_events", reader);
            if (!script_.npc_scripts_.contains(script)) {
                return failure(LoadError::kBadReference, "talk_npc_events", where(table, row, std::to_string(script)));
            }
        }
        return {};
    }

    // NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): Script đang dựng, chương trình và bảng do nơi gọi sở hữu, sống lâu hơn người dựng, không sở hữu, không giữ qua tick (SH-04)
    Script& script_;
    const ops::Program& program_;
    const Tables& tables_;
    // NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)
};

std::expected<Script, LoadFailure> Script::load(const ops::Program& program, const Tables& tables) {
    Script script;
    ScriptBuilder builder(script, program, tables);
    if (auto done = builder.run(); !done) return std::unexpected(std::move(done.error()));
    return script;
}

std::span<const Step> Script::block(std::uint32_t id) const noexcept {
    const auto found = blocks_.find(id);
    if (found == blocks_.end()) return {};
    return std::span<const Step>(steps_).subspan(found->second.begin, found->second.end - found->second.begin);
}

const Entry* Script::entry(std::uint32_t script, std::int32_t num) const noexcept {
    const auto key = std::pair{script, num};
    const auto found = std::ranges::lower_bound(entries_, key, {}, [](const Entry& entry) { return std::pair{entry.script, entry.num}; });
    return found != entries_.end() && found->script == script && found->num == num ? &*found : nullptr;
}

}  // namespace game::talk
