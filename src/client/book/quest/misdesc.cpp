/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/book/quest/misdesc.cpp
 *  PHÂN HỆ   : Client / Sổ sách / Nhiệm vụ
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vòng đọc dòng ở Game.exe 0x1402cdbc0 và hàm xử lý 0x1401d9330-0x1401dc6f0:
 *    tìm tên g_* bằng strstr, đọc giá trị bằng máy trạng thái từng ký tự, giữ
 *    mọi quirk của máy đó vì dữ liệu thật dựa vào chúng.
 *  - Khác gốc: tệp UTF-8 (gốc GBK); ký tự đa byte bị bỏ qua trọn chuỗi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "quest/misdesc.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::quest {
namespace {

using Status = std::expected<void, std::string>;
using Value = std::expected<std::string_view, std::string>;
using Strings = std::vector<std::string>;

constexpr std::string_view kBegin = "MisDescBegin";
constexpr std::string_view kEnd = "MisDescEnd";
constexpr std::string_view kDigits = "0123456789";
constexpr std::size_t kShownBytes = 60;
constexpr std::size_t kNone = std::string_view::npos;

[[nodiscard]] bool is_digit(char letter) noexcept {
    return letter >= '0' && letter <= '9';
}

[[nodiscard]] bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

[[nodiscard]] bool is_wide(char letter) noexcept {
    return static_cast<unsigned char>(letter) >= 0x80;
}

[[nodiscard]] bool is_continuation(char letter) noexcept {
    return (static_cast<unsigned char>(letter) & 0xC0) == 0x80;
}

[[nodiscard]] std::size_t sequence_length(char lead) noexcept {
    const auto byte = static_cast<unsigned char>(lead);
    if (byte >= 0xF0) return 4;
    if (byte >= 0xE0) return 3;
    if (byte >= 0xC0) return 2;
    return 1;
}

// atoi của C: bỏ khoảng trắng đầu, dấu tuỳ chọn, rồi chữ số; tràn thì kẹp như MSVCRT.
[[nodiscard]] std::int32_t c_atoi(std::string_view text) noexcept {
    std::size_t pos = 0;
    while (pos < text.size() && is_space(text[pos]))
        ++pos;
    const bool has_sign = pos < text.size() && (text[pos] == '-' || text[pos] == '+');
    const bool is_negative = has_sign && text[pos] == '-';
    if (has_sign) ++pos;
    std::int64_t value = 0;
    while (pos < text.size() && is_digit(text[pos])) {
        value = std::min<std::int64_t>((value * 10) + (text[pos] - '0'), 0x80000000LL);
        ++pos;
    }
    const std::int64_t signed_value = is_negative ? -value : value;
    const std::int64_t low = std::numeric_limits<std::int32_t>::min();
    const std::int64_t high = std::numeric_limits<std::int32_t>::max();
    return static_cast<std::int32_t>(std::clamp(signed_value, low, high));
}

// Cắt không quá limit byte, lùi về ranh giới ký tự UTF-8.
[[nodiscard]] std::string_view clip(std::string_view text, std::size_t limit) noexcept {
    std::size_t cut = std::min(text.size(), limit);
    while (cut > 0 && cut < text.size() && is_continuation(text[cut]))
        --cut;
    return text.substr(0, cut);
}

// Cắt dòng như strtok(text, "\r\n"): dòng rỗng không sinh ra.
class Lines {
public:
    explicit Lines(std::string_view text) noexcept : rest_(text) {}

    [[nodiscard]] std::optional<std::string_view> next() noexcept {
        const std::size_t start = rest_.find_first_not_of("\r\n");
        if (start == kNone) rest_ = {};
        if (start == kNone) return std::nullopt;
        rest_.remove_prefix(start);
        const std::string_view line = rest_.substr(0, rest_.find_first_of("\r\n"));
        rest_.remove_prefix(line.size());
        return line;
    }

private:
    std::string_view rest_;
};

// Con trỏ đọc giá trị sau dấu '=': mỗi lần một ký tự, ký tự đa byte nuốt trọn.
class Cursor {
public:
    explicit Cursor(std::string_view text) noexcept : text_(text) {}

    [[nodiscard]] bool done() const noexcept { return at_ >= text_.size(); }
    [[nodiscard]] char current() const noexcept { return text_[at_]; }
    [[nodiscard]] char before() const noexcept { return at_ == 0 ? '\0' : text_[at_ - 1]; }
    [[nodiscard]] bool wide() const noexcept { return is_wide(text_[at_]); }
    [[nodiscard]] std::string_view rest() const noexcept { return text_.substr(at_); }
    void advance(std::size_t count) noexcept { at_ = std::min(at_ + count, text_.size()); }
    void next() noexcept {
        if (!done()) advance(sequence_length(text_[at_]));
    }

private:
    std::string_view text_;
    std::size_t at_ = 0;
};

struct Call {
    std::string_view line;
    Lines* lines;
    MissionDef* def;
};

[[nodiscard]] std::unexpected<std::string> fail(std::string_view why, const Call& call) {
    const std::string_view shown = clip(call.line, kShownBytes);
    std::string text = std::format("{}: {}", why, shown);
    return std::unexpected(std::move(text));
}

using Run = Status (*)(const Call&);

[[nodiscard]] std::optional<std::string_view> value_of(std::string_view line) noexcept {
    const std::size_t pos = line.find('=');
    if (pos == kNone) return std::nullopt;
    return line.substr(pos + 1);
}

[[nodiscard]] Value value_after_equals(const Call& call) {
    const std::optional<std::string_view> value = value_of(call.line);
    if (!value) return fail("thiếu dấu =", call);
    return *value;
}

// Chuỗi trong cặp nháy đầu tiên trở ra, tới dấu nháy cuối của dòng (strchr rồi strrchr của gốc).
// Rỗng thì gốc không gán gì.
// Khác gốc: gốc nối vào bộ đệm 260 byte nên giá trị dài hơn bị tràn; ở đây không cắt.
[[nodiscard]] Status read_text(std::string MissionDef::* field, const Call& call) {
    const std::size_t open = call.line.find('"');
    if (open == kNone) return fail("thiếu dấu nháy", call);
    const std::size_t close = call.line.rfind('"');
    if (close <= open + 1) return {};
    const std::string_view inner = call.line.substr(open + 1, close - open - 1);
    call.def->*field = std::string(inner);
    return {};
}

struct IntVar {
    std::string_view name;
    std::int32_t MissionDef::* field;
};

// Quét tới chữ số đầu tiên rồi atoi: dấu '-' đứng trước bị bỏ qua.
constexpr std::array<IntVar, 2> kScanned = {{
    {.name = "g_MissionLevel", .field = &MissionDef::level},
    {.name = "g_IfMissionElite", .field = &MissionDef::elite},
}};

// atoi ngay sau dấu '='.
constexpr std::array<IntVar, 9> kParsed = {{
    {.name = "g_MissionKind", .field = &MissionDef::kind},
    {.name = "g_MissionRound", .field = &MissionDef::round},
    {.name = "g_StrForePart", .field = &MissionDef::fore_part},
    {.name = "g_DoubleExp", .field = &MissionDef::double_exp},
    {.name = "g_StopWatch_Pause_Flag", .field = &MissionDef::stopwatch_pause},
    {.name = "g_Position_X", .field = &MissionDef::pos_x},
    {.name = "g_Position_Z", .field = &MissionDef::pos_z},
    {.name = "g_SceneID", .field = &MissionDef::scene},
    {.name = "g_ShimenTypeIndex", .field = &MissionDef::shimen_index},
}};

// Chỉ cần có dấu '=': đặt 1. (g_Bill và g_IsMissionOkFail còn gọi atoi nhưng bỏ kết quả. Tên
// "g_Bill" nằm trong "g_BillName" nên dòng g_BillName cũng đặt bill = 1, như strstr của gốc.)
constexpr std::array<IntVar, 3> kFlags = {{
    {.name = "g_IsMissionOkFail", .field = &MissionDef::ok_fail},
    {.name = "g_AccomplishCircumstance", .field = &MissionDef::circumstance},
    {.name = "g_Bill", .field = &MissionDef::bill},
}};

struct TextVar {
    std::string_view name;
    std::string MissionDef::* field;
};

constexpr std::array<TextVar, 5> kTexts = {{
    {.name = "g_MissionName", .field = &MissionDef::name},
    {.name = "g_MissionTarget", .field = &MissionDef::target},
    {.name = "g_MissionState", .field = &MissionDef::state},
    {.name = "g_BillName", .field = &MissionDef::bill_name},
    {.name = "g_AccomplishNPC_Name", .field = &MissionDef::npc_name},
}};

// Khác gốc: quét chữ số không thấy chữ số nào thì giữ trường; gốc đọc lố ra ngoài dòng.
[[nodiscard]] std::int32_t scanned_int(std::string_view value, std::int32_t keep) noexcept {
    const std::size_t pos = value.find_first_of(kDigits);
    if (pos == kNone) return keep;
    return c_atoi(value.substr(pos));
}

[[nodiscard]] Status run_scanned(const Call& call) {
    for (const IntVar& var : kScanned) {
        if (!call.line.contains(var.name)) continue;
        const Value value = value_after_equals(call);
        if (!value) return std::unexpected(value.error());
        std::int32_t& slot = call.def->*var.field;
        slot = scanned_int(*value, slot);
    }
    return {};
}

[[nodiscard]] Status run_parsed(const Call& call) {
    for (const IntVar& var : kParsed) {
        if (!call.line.contains(var.name)) continue;
        const Value value = value_after_equals(call);
        if (!value) return std::unexpected(value.error());
        call.def->*var.field = c_atoi(*value);
    }
    return {};
}

[[nodiscard]] Status run_flags(const Call& call) {
    for (const IntVar& var : kFlags) {
        if (!call.line.contains(var.name)) continue;
        const Value value = value_after_equals(call);
        if (!value) return std::unexpected(value.error());
        call.def->*var.field = 1;
    }
    return {};
}

[[nodiscard]] Status run_texts(const Call& call) {
    for (const TextVar& var : kTexts) {
        if (!call.line.contains(var.name)) continue;
        const Status status = read_text(var.field, call);
        if (!status) return status;
    }
    return {};
}

struct Pair {
    std::int32_t first = 0;
    std::int32_t second = 0;
};

// Máy "{{a,b},{a,b}}" của DemandItem, ItemBonus, DemandKill, NpcIdIndicator...: trạng thái 1 chờ
// số thứ nhất, 2 đã có, 3 chờ số thứ hai, 4 đã có; dấu ',' đưa về 3. Chữ số của khoá (tên trường)
// làm lệch máy, dữ liệu thật tránh bằng cách đặt tên không chữ số. reset_on_close: '}' trong khối
// đưa về trạng thái 1 (DemandItem, RadioItemBonus, DemandKill, NpcIdIndicator) hay giữ nguyên
// (ItemBonus, RandomItemBonus).
class PairScan {
public:
    explicit PairScan(bool reset_on_close) noexcept : reset_(reset_on_close) {}

    // true khi '}' đóng khối ngoài cùng.
    [[nodiscard]] bool feed(std::string_view rest);
    [[nodiscard]] std::vector<Pair> take() noexcept { return std::move(pairs_); }

private:
    [[nodiscard]] bool open() noexcept;
    [[nodiscard]] bool close() noexcept;
    void at_first(std::string_view rest) noexcept;
    void at_second(std::string_view rest);
    void after_pair(char letter) noexcept;

    bool reset_;
    int state_ = 1;
    int depth_ = 0;
    std::int32_t first_ = 0;
    std::vector<Pair> pairs_;
};

bool PairScan::open() noexcept {
    state_ = 1;
    ++depth_;
    return false;
}

bool PairScan::close() noexcept {
    --depth_;
    if (depth_ == 0) return true;
    if (reset_) state_ = 1;
    return false;
}

void PairScan::at_first(std::string_view rest) noexcept {
    const char letter = rest.front();
    if (letter == ',') state_ = 3;
    if (!is_digit(letter)) return;
    state_ = 2;
    first_ = c_atoi(rest);
}

void PairScan::at_second(std::string_view rest) {
    if (!is_digit(rest.front())) return;
    state_ = 4;
    const Pair pair{.first = first_, .second = c_atoi(rest)};
    pairs_.push_back(pair);
}

void PairScan::after_pair(char letter) noexcept {
    if (letter == ',') state_ = 3;
}

bool PairScan::feed(std::string_view rest) {
    const char letter = rest.front();
    if (letter == '{') return open();
    if (letter == '}') return close();
    switch (state_) {
    case 1: at_first(rest); break;
    case 3: at_second(rest); break;
    default: after_pair(letter); break;
    }
    return false;
}

[[nodiscard]] std::vector<Pair> scan_pairs(std::string_view value, bool reset_on_close) {
    PairScan scan(reset_on_close);
    for (Cursor cur(value); !cur.done(); cur.next()) {
        if (cur.wide()) continue;
        if (scan.feed(cur.rest())) break;
    }
    return scan.take();
}

// Mục tiêu tuỳ biến g_Custom (0x1401dac00): trạng thái 1 chờ chuỗi trong nháy (hoặc ','), 2 đã có
// tên, 3 chờ số, 4 đã có số. Tên được lấy ngay khi gặp nháy mở mà con trỏ không nhảy qua nháy
// đóng, nên dấu ',' hay chữ số nằm trong tên vẫn làm máy chạy tiếp.
class CustomScan {
public:
    // true khi khối ngoài cùng đóng hoặc gặp lỗi (bad()).
    [[nodiscard]] bool feed(std::string_view rest);
    [[nodiscard]] bool bad() const noexcept { return bad_; }
    [[nodiscard]] std::vector<Counted> take() noexcept { return std::move(entries_); }

private:
    [[nodiscard]] bool open() noexcept;
    [[nodiscard]] bool close() noexcept;
    void at_first(std::string_view rest);
    void at_second(std::string_view rest);
    void after_number(char letter) noexcept;

    int state_ = 1;
    int depth_ = 0;
    bool bad_ = false;
    std::string name_;
    std::vector<Counted> entries_;
};

bool CustomScan::open() noexcept {
    state_ = 1;
    ++depth_;
    return false;
}

bool CustomScan::close() noexcept {
    state_ = 1;
    --depth_;
    return depth_ == 0;
}

void CustomScan::at_first(std::string_view rest) {
    const char letter = rest.front();
    if (letter == ',') state_ = 3;
    if (letter != '"') return;
    const std::size_t end = rest.substr(1).find('"');
    bad_ = end == kNone;
    if (bad_) return;
    state_ = 2;
    name_ = std::string(rest.substr(1, end));
}

void CustomScan::at_second(std::string_view rest) {
    if (!is_digit(rest.front())) return;
    state_ = 4;
    Counted entry{.text = name_, .count = c_atoi(rest)};
    entries_.push_back(std::move(entry));
}

void CustomScan::after_number(char letter) noexcept {
    if (letter == ',') state_ = 3;
}

bool CustomScan::feed(std::string_view rest) {
    const char letter = rest.front();
    if (letter == '{') return open();
    if (letter == '}') return close();
    switch (state_) {
    case 1: at_first(rest); break;
    case 3: at_second(rest); break;
    default: after_number(letter); break;
    }
    return bad_;
}

[[nodiscard]] Status scan_customs(std::string_view value, const Call& call) {
    CustomScan scan;
    for (Cursor cur(value); !cur.done(); cur.next()) {
        if (cur.wide()) continue;
        if (scan.feed(cur.rest())) break;
    }
    if (scan.bad()) return fail("g_Custom thiếu nháy đóng", call);
    std::vector<Counted> entries = scan.take();
    std::ranges::move(entries, std::back_inserter(call.def->customs));
    return {};
}

// g_RandomCustom (0x1401dc6f0): tên trong nháy, rồi hai số; dấu ',' nối bước. Khác g_Custom ở chỗ
// dấu ',' khi chờ tên không có nghĩa.
class RandomScan {
public:
    // true khi khối ngoài cùng đóng hoặc gặp lỗi (bad()).
    [[nodiscard]] bool feed(std::string_view rest);
    [[nodiscard]] bool bad() const noexcept { return bad_; }
    [[nodiscard]] std::vector<RandomCounted> take() noexcept { return std::move(entries_); }

private:
    [[nodiscard]] bool open() noexcept;
    [[nodiscard]] bool close() noexcept;
    void at_name(std::string_view rest);
    void at_first_number(std::string_view rest);
    void at_second_number(std::string_view rest);
    void after_part(char letter) noexcept;

    int state_ = 1;
    int depth_ = 0;
    bool bad_ = false;
    std::string name_;
    std::int32_t first_ = 0;
    std::vector<RandomCounted> entries_;
};

bool RandomScan::open() noexcept {
    state_ = 1;
    ++depth_;
    return false;
}

bool RandomScan::close() noexcept {
    state_ = 1;
    --depth_;
    return depth_ == 0;
}

void RandomScan::at_name(std::string_view rest) {
    if (rest.front() != '"') return;
    const std::size_t end = rest.substr(1).find('"');
    bad_ = end == kNone;
    if (bad_) return;
    state_ = 2;
    name_ = std::string(rest.substr(1, end));
}

void RandomScan::at_first_number(std::string_view rest) {
    if (!is_digit(rest.front())) return;
    state_ = 4;
    first_ = c_atoi(rest);
}

void RandomScan::at_second_number(std::string_view rest) {
    if (!is_digit(rest.front())) return;
    state_ = 6;
    RandomCounted entry{.text = name_, .first = first_, .second = c_atoi(rest)};
    entries_.push_back(std::move(entry));
}

void RandomScan::after_part(char letter) noexcept {
    if (letter != ',') return;
    if (state_ == 2) state_ = 3;
    if (state_ == 4) state_ = 5;
}

bool RandomScan::feed(std::string_view rest) {
    const char letter = rest.front();
    if (letter == '{') return open();
    if (letter == '}') return close();
    switch (state_) {
    case 1: at_name(rest); break;
    case 3: at_first_number(rest); break;
    case 5: at_second_number(rest); break;
    default: after_part(letter); break;
    }
    return bad_;
}

[[nodiscard]] Status scan_randoms(std::string_view value, const Call& call) {
    RandomScan scan;
    for (Cursor cur(value); !cur.done(); cur.next()) {
        if (cur.wide()) continue;
        if (scan.feed(cur.rest())) break;
    }
    if (scan.bad()) return fail("g_RandomCustom thiếu nháy đóng", call);
    std::vector<RandomCounted> entries = scan.take();
    std::ranges::move(entries, std::back_inserter(call.def->random_customs));
    return {};
}

// Nối các dòng của một khối nhiều dòng như 0x14032dad0: nối không ngăn cách tới dòng có '}' mà
// sau nó không còn dấu nháy.
[[nodiscard]] std::optional<std::string> join_block(const Call& call) {
    std::string text;
    std::string_view piece = call.line;
    while (true) {
        text += piece;
        const std::size_t brace = piece.find('}');
        const bool is_closed = brace != kNone && piece.find('"', brace) == kNone;
        if (is_closed) return text;
        const std::optional<std::string_view> more = call.lines->next();
        if (!more) return std::nullopt;
        piece = *more;
    }
}

enum class Quote : std::uint8_t {
    // Nháy đóng là nháy kế tiếp (g_StrList).
    kPlain,
    // Nháy đứng sau '\' không đóng chuỗi (g_FormatList).
    kEscaped,
};

struct QuoteRule {
    Quote mode;
    // Số byte tối đa của một chuỗi (gốc có bộ đệm 1024 byte cho g_FormatList).
    std::size_t limit;
};

constexpr QuoteRule kStrListRule = {.mode = Quote::kPlain, .limit = kNone};
constexpr QuoteRule kFormatRule = {.mode = Quote::kEscaped, .limit = 1023};

// Khác gốc: gốc còn nhận nháy sau '\' khi byte trước '\' có bit cao (cặp GBK mà byte sau là 0x5C);
// UTF-8 không có byte 0x5C trong ký tự đa byte nên không cần.
[[nodiscard]] std::size_t closing_quote(std::string_view after, Quote mode) noexcept {
    std::size_t pos = after.find('"');
    while (pos != kNone && mode == Quote::kEscaped && pos > 0) {
        if (after[pos - 1] != '\\') break;
        pos = after.find('"', pos + 1);
    }
    return pos;
}

// Con trỏ nhảy tới sau nháy đóng rồi vòng for của gốc lại tăng một ký tự: ký tự ngay sau nháy đóng
// không bao giờ được xét (0x1401daf90, 0x1401db1d0). Nên {"a"}"b" vẫn lấy "b": '}' bị bỏ qua.
[[nodiscard]] bool take_quote(Cursor& cur, const QuoteRule& rule, Strings& out) {
    const std::string_view after = cur.rest().substr(1);
    const std::size_t close = closing_quote(after, rule.mode);
    if (close == kNone) return false;
    const std::string_view inner = clip(after.substr(0, close), rule.limit);
    out.emplace_back(inner);
    cur.advance(close + 2);
    return true;
}

// Đếm ngoặc nhọn: '{' tăng, '}' giảm; true khi '}' đưa về 0.
class Braces {
public:
    [[nodiscard]] bool feed(char letter) noexcept {
        if (letter == '{') ++depth_;
        if (letter == '}') --depth_;
        return letter == '}' && depth_ == 0;
    }

private:
    int depth_ = 0;
};

[[nodiscard]] bool opens_string(const Cursor& cur, const QuoteRule& rule) noexcept {
    if (cur.current() != '"') return false;
    return rule.mode == Quote::kPlain || cur.before() != '\\';
}

// Máy của g_StrList (0x1401daf90) và g_FormatList (0x1401db1d0): đếm ngoặc nhọn, lấy từng chuỗi
// trong nháy rồi nhảy qua nháy đóng. false khi thiếu nháy đóng.
[[nodiscard]] bool scan_quoted(std::string_view value, const QuoteRule& rule, Strings& out) {
    Braces braces;
    for (Cursor cur(value); !cur.done(); cur.next()) {
        if (cur.wide()) continue;
        if (braces.feed(cur.current())) break;
        if (!opens_string(cur, rule)) continue;
        if (!take_quote(cur, rule, out)) return false;
    }
    return true;
}

using StringsField = Strings MissionDef::*;

[[nodiscard]] Status read_quoted(const Call& call, const QuoteRule& rule, StringsField field) {
    const std::optional<std::string> joined = join_block(call);
    if (!joined) return fail("khối chưa đóng ngoặc", call);
    const std::optional<std::string_view> value = value_of(*joined);
    if (!value) return fail("thiếu dấu =", call);
    if (!scan_quoted(*value, rule, call.def->*field)) return fail("thiếu nháy đóng", call);
    return {};
}

[[nodiscard]] Status read_str_list(const Call& call) {
    return read_quoted(call, kStrListRule, &MissionDef::str_list);
}

[[nodiscard]] Status read_format_list(const Call& call) {
    return read_quoted(call, kFormatRule, &MissionDef::format_list);
}

[[nodiscard]] Status read_custom(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    return scan_customs(*value, call);
}

[[nodiscard]] Status read_random_custom(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    return scan_randoms(*value, call);
}

[[nodiscard]] Status read_demand_item(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::vector<Pair> pairs = scan_pairs(*value, true);
    for (const Pair& pair : pairs) {
        const ItemCount entry{.item = pair.first, .count = pair.second};
        call.def->demand_items.push_back(entry);
    }
    return {};
}

[[nodiscard]] Status read_demand_kill(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::vector<Pair> pairs = scan_pairs(*value, true);
    for (const Pair& pair : pairs) {
        const KillCount entry{.creature = pair.first, .count = pair.second};
        call.def->demand_kills.push_back(entry);
    }
    return {};
}

[[nodiscard]] Status read_npc_indicator(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::vector<Pair> pairs = scan_pairs(*value, true);
    for (const Pair& pair : pairs) {
        const NpcIndicator entry{.key = pair.first, .index = pair.second};
        call.def->npc_indicators.push_back(entry);
    }
    return {};
}

[[nodiscard]] Status add_item_bonus(const Call& call, BonusKind kind, bool reset_on_close) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::vector<Pair> pairs = scan_pairs(*value, reset_on_close);
    for (const Pair& pair : pairs) {
        const Bonus entry{.kind = kind, .value = pair.second, .item = pair.first};
        call.def->bonuses.push_back(entry);
    }
    return {};
}

[[nodiscard]] Status read_item_bonus(const Call& call) {
    return add_item_bonus(call, BonusKind::kItem, false);
}

[[nodiscard]] Status read_random_item(const Call& call) {
    return add_item_bonus(call, BonusKind::kItemRandom, false);
}

[[nodiscard]] Status read_radio_item(const Call& call) {
    return add_item_bonus(call, BonusKind::kItemRadio, true);
}

// Khác gốc: không thấy chữ số nào thì bỏ dòng; gốc đọc lố ra ngoài dòng.
[[nodiscard]] Status add_amount(const Call& call, BonusKind kind) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::size_t pos = value->find_first_of(kDigits);
    if (pos == kNone) return {};
    const std::string_view digits = value->substr(pos);
    const std::int32_t amount = c_atoi(digits);
    const Bonus entry{.kind = kind, .value = amount, .item = 0};
    call.def->bonuses.push_back(entry);
    return {};
}

[[nodiscard]] Status read_money(const Call& call) {
    return add_amount(call, BonusKind::kMoney);
}

[[nodiscard]] Status read_money_jz(const Call& call) {
    return add_amount(call, BonusKind::kMoneyJz);
}

[[nodiscard]] Status read_exp(const Call& call) {
    return add_amount(call, BonusKind::kExp);
}

// Tích các số cách nhau bằng '*' ("15*60*1000"), nhân không dấu 32 bit như gốc (0x1401da970).
[[nodiscard]] std::int32_t product_of(std::string_view text) noexcept {
    std::uint32_t product = 1;
    std::size_t from = 0;
    while (from <= text.size()) {
        const std::size_t star = text.find('*', from);
        const std::string_view piece = text.substr(from, star - from);
        product *= static_cast<std::uint32_t>(c_atoi(piece));
        if (star == kNone) break;
        from = star + 1;
    }
    return static_cast<std::int32_t>(product);
}

// Khác gốc: không thấy chữ số nào thì giữ trường; gốc đọc lố ra ngoài dòng.
[[nodiscard]] Status read_limit_time(const Call& call) {
    const Value value = value_after_equals(call);
    if (!value) return std::unexpected(value.error());
    const std::size_t pos = value->find_first_of(kDigits);
    if (pos == kNone) return {};
    const std::string_view digits = value->substr(pos);
    call.def->limit_time = product_of(digits);
    return {};
}

struct Special {
    std::string_view name;
    Run run;
};

constexpr std::array<Special, 14> kSpecials = {{
    {.name = "g_DemandItem", .run = read_demand_item},
    {.name = "g_ItemBonus", .run = read_item_bonus},
    {.name = "g_RandomItemBonus", .run = read_random_item},
    {.name = "g_RadioItemBonus", .run = read_radio_item},
    {.name = "g_MoneyBonus", .run = read_money},
    {.name = "g_MoneyJZBonus", .run = read_money_jz},
    {.name = "g_ExpBonus", .run = read_exp},
    {.name = "g_DemandKill", .run = read_demand_kill},
    {.name = "g_MissionLimitTime", .run = read_limit_time},
    {.name = "g_Custom", .run = read_custom},
    {.name = "g_StrList", .run = read_str_list},
    {.name = "g_FormatList", .run = read_format_list},
    {.name = "g_RandomCustom", .run = read_random_custom},
    {.name = "g_NpcIdIndicator", .run = read_npc_indicator},
}};

[[nodiscard]] Status run_specials(const Call& call) {
    for (const Special& special : kSpecials) {
        if (!call.line.contains(special.name)) continue;
        const Status status = special.run(call);
        if (!status) return status;
    }
    return {};
}

// Một dòng của khối: mỗi tên có trong dòng (strstr) chạy hàm xử lý của nó.
[[nodiscard]] Status read_line(std::string_view line, Lines& lines, MissionDef& def) {
    const Call call{.line = line, .lines = &lines, .def = &def};
    const Status scanned = run_scanned(call);
    if (!scanned) return scanned;
    const Status parsed = run_parsed(call);
    if (!parsed) return parsed;
    const Status flags = run_flags(call);
    if (!flags) return flags;
    const Status texts = run_texts(call);
    if (!texts) return texts;
    return run_specials(call);
}

[[nodiscard]] bool skip_to_block(Lines& lines) {
    while (const std::optional<std::string_view> line = lines.next()) {
        if (line->contains(kBegin)) return true;
    }
    return false;
}

// Dòng ngắn hơn hai byte hay mở bằng "--" không được xét; dòng thụt lề rồi mới "--" vẫn được xét.
[[nodiscard]] bool is_skipped(std::string_view line) noexcept {
    return line.size() <= 1 || line.starts_with("--");
}

} // namespace

std::expected<MissionDef, std::string> parse_misdesc(std::string_view file_text) {
    Lines lines(file_text);
    MissionDef def;
    if (!skip_to_block(lines)) return def;
    while (const std::optional<std::string_view> line = lines.next()) {
        if (line->contains(kEnd)) break;
        if (is_skipped(*line)) continue;
        const Status status = read_line(*line, lines, def);
        if (!status) return std::unexpected(status.error());
    }
    return def;
}

} // namespace game::quest
