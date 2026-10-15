// Thư viện chuỗi (lstrlib.c của Lua 5.0.1) với bộ tên của LuaPlus.dll trong client 2026: len, sub, lower, upper, char, rep,
// byte, format, dump, find, gfind, gsub, lualex.
//
// Port từ lstrlib.c. Khác gốc:
// - Chuỗi mẫu là chuỗi C như gốc (dừng ở byte 0 đầu tiên); chữ ở nguồn ngoài đoạn đọc được coi là byte 0 như ký tự kết
//   thúc của chuỗi Lua. Phân loại ký tự là của locale "C" (ASCII), byte >= 0x80 không thuộc lớp nào; `char` mang dấu như
//   MSVC (so `%<byte cao>` với ký tự nguồn không bao giờ khớp, y như gốc).
// - Lỗi qua cờ của State thay longjmp; trình khớp dừng ngay khi cờ bật.
// - Trình khớp trừ một đơn vị ngân sách vòng lặp mỗi lần vào match và mỗi bước mở rộng, và dừng ở độ sâu đệ quy
//   kMaxMatchDepth với lỗi "pattern too complex" (gốc chỉ bị giới hạn bởi ngăn xếp C): mẫu kiểu "a*a*a*a*b" trên chuỗi dài
//   hết ngân sách thay vì treo client.
// - string.format dùng cformat.hpp (sprintf của MSVCR110, đã đo); `%` đứng cuối chuỗi định dạng báo "invalid option to
//   `format'" (gốc đọc quá cuối chuỗi, kết quả phụ thuộc bộ nhớ kế bên).
// - string.dump và string.lualex không có mã (cần trình biên dịch Lua): báo lỗi.
#include "lua/cformat.hpp"
#include "lua/element.hpp"
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <string>
#include <string_view>
#include <utility>

namespace game::lua {
namespace {

// ---- ký tự (locale "C") ----

[[nodiscard]] constexpr bool is_upper(int c) noexcept {
    return c >= 'A' && c <= 'Z';
}
[[nodiscard]] constexpr bool is_lower(int c) noexcept {
    return c >= 'a' && c <= 'z';
}
[[nodiscard]] constexpr bool is_alpha(int c) noexcept {
    return is_upper(c) || is_lower(c);
}
[[nodiscard]] constexpr bool is_digit(int c) noexcept {
    return c >= '0' && c <= '9';
}
[[nodiscard]] constexpr bool is_alnum(int c) noexcept {
    return is_alpha(c) || is_digit(c);
}
[[nodiscard]] constexpr bool is_xdigit(int c) noexcept {
    return is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}
[[nodiscard]] constexpr bool is_space(int c) noexcept {
    return c == ' ' || (c >= '\t' && c <= '\r');
}
[[nodiscard]] constexpr bool is_control(int c) noexcept {
    return (c >= 0 && c < ' ') || c == 0x7F;
}
[[nodiscard]] constexpr bool is_punct(int c) noexcept {
    return c > ' ' && c < 0x7F && !is_alnum(c);
}
[[nodiscard]] constexpr int to_lower(int c) noexcept {
    return is_upper(c) ? c + ('a' - 'A') : c;
}
[[nodiscard]] constexpr int to_upper(int c) noexcept {
    return is_lower(c) ? c - ('a' - 'A') : c;
}

// uchar(c) và ép char (mang dấu) sang int của gốc.
[[nodiscard]] constexpr int unsigned_byte(char letter) noexcept {
    return static_cast<unsigned char>(letter);
}
[[nodiscard]] constexpr int signed_byte(char letter) noexcept {
    return static_cast<signed char>(letter);
}

// Chuỗi C: tới byte 0 đầu tiên.
[[nodiscard]] std::string_view c_string(std::string_view text) noexcept {
    return text.substr(0, text.find('\0'));
}

// posrelat: vị trí tương đối, âm tính từ cuối.
[[nodiscard]] std::int32_t relative_position(std::int32_t position, std::size_t length) noexcept {
    return position >= 0 ? position : wrapping_add(wrapping_add(static_cast<std::int32_t>(length), position), 1);
}

// ---- hàm đơn giản ----

Results string_len(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    if (in.failed()) return {};
    return {Value::number(static_cast<double>(text.size()))};
}

Results string_sub(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    std::int32_t first = relative_position(in.integer(1), text.size());
    std::int32_t last = relative_position(in.opt_integer(2, -1), text.size());
    if (in.failed()) return {};
    first = std::max<std::int32_t>(first, 1);
    last = std::min(last, static_cast<std::int32_t>(text.size()));
    if (first > last) return {state.make_string("")};
    return {state.make_string(text.substr(static_cast<std::size_t>(first) - 1, static_cast<std::size_t>(last) - static_cast<std::size_t>(first) + 1))};
}

Results string_lower(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    if (in.failed()) return {};
    std::string lowered(text);
    for (char& letter : lowered)
        letter = static_cast<char>(to_lower(unsigned_byte(letter)));
    return {state.make_string(lowered)};
}

Results string_upper(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    if (in.failed()) return {};
    std::string raised(text);
    for (char& letter : raised)
        letter = static_cast<char>(to_upper(unsigned_byte(letter)));
    return {state.make_string(raised)};
}

Results string_rep(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    const std::int32_t count = in.integer(1);
    if (in.failed()) return {};
    Buffer out(state);
    // Chuỗi rỗng lặp n lần vẫn rỗng; không quay n lần (n tới 2^31).
    if (!text.empty() && count > 0) {
        for (std::int32_t i = 0; i < count && !state.failed(); ++i)
            out.add(text);
    }
    return {out.finish()};
}

Results string_byte(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view text = in.text(0);
    const std::int32_t position = relative_position(in.opt_integer(1, 1), text.size());
    if (in.failed()) return {};
    if (position <= 0 || static_cast<std::size_t>(position) > text.size()) return {};
    return {Value::number(static_cast<double>(unsigned_byte(text[static_cast<std::size_t>(position) - 1])))};
}

Results string_char(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    Buffer out(state);
    for (std::size_t i = 0; i < args.size(); ++i) {
        const std::int32_t code = in.integer(i);
        if (in.failed()) return {};
        if (code < 0 || code > 255) {
            in.argument_error(i, "invalid value");
            return {};
        }
        out.add(static_cast<char>(code));
    }
    return {out.finish()};
}

Results string_unsupported(State& state, const Function& self, Args) {
    state.native_error(std::string(self.proto().name) + ": not supported by this runtime");
    return {};
}

// ---- khớp mẫu ----

constexpr char kEscape = '%';
constexpr std::string_view kSpecials = "^$*+?.([%-";
constexpr std::size_t kMaxCaptures = 32;
constexpr int kMaxMatchDepth = 1000;
constexpr std::ptrdiff_t kCaptureUnfinished = -1;
constexpr std::ptrdiff_t kCapturePosition = -2;

class Matcher {
public:
    static constexpr std::size_t kNone = std::numeric_limits<std::size_t>::max();

    // args: đối số của lời gọi (đáy ngăn xếp hàm C); chỉ câu lỗi "ends with" dùng đến (xem malformed_end).
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): mọi nơi gọi đặt tên source và pattern ngay bên cạnh.
    Matcher(State& state, Args args, std::string_view source, std::string_view pattern) noexcept
        : state_(&state), args_(args), source_(source), pattern_(pattern) {}

    void reset() noexcept { level_ = 0; }

    // match(ms, s, p): vị trí cuối của chỗ khớp bắt đầu ở s với mẫu từ p, hoặc kNone (cũng khi đã lỗi).
    [[nodiscard]] std::size_t match(std::size_t s, std::size_t p);

    // push_captures(ms, s, e) với whole: không có capture tường minh thì trả cả chỗ khớp [s, e); không whole (find): chỉ
    // các capture.
    void push_captures(Results& out, bool whole, std::size_t s, std::size_t e);
    // push_onecapture rồi luaL_addvalue của add_s.
    [[nodiscard]] Value one_capture(std::size_t index);
    // check_capture của chữ số trong chuỗi thay thế; kNone khi lỗi.
    [[nodiscard]] std::size_t check_capture_digit(char digit);

private:
    struct Capture {
        std::size_t init = 0;
        std::ptrdiff_t length = 0;
    };

    [[nodiscard]] char pat(std::size_t index) const noexcept { return index < pattern_.size() ? pattern_[index] : '\0'; }
    [[nodiscard]] char src(std::size_t index) const noexcept { return index < source_.size() ? source_[index] : '\0'; }
    [[nodiscard]] bool failed() const noexcept { return state_->failed(); }

    [[nodiscard]] std::size_t match_inner(std::size_t s, std::size_t p);
    [[nodiscard]] std::size_t class_end(std::size_t p);
    [[nodiscard]] static bool match_class(int c, int class_letter) noexcept;
    [[nodiscard]] bool match_bracket_class(int c, std::size_t p, std::size_t end_class) const noexcept;
    [[nodiscard]] bool single_match(int c, std::size_t p, std::size_t ep) const noexcept;
    [[nodiscard]] std::size_t match_balance(std::size_t s, std::size_t p);
    [[nodiscard]] std::size_t max_expand(std::size_t s, std::size_t p, std::size_t ep);
    [[nodiscard]] std::size_t min_expand(std::size_t s, std::size_t p, std::size_t ep);
    [[nodiscard]] std::size_t start_capture(std::size_t s, std::size_t p, std::ptrdiff_t what);
    [[nodiscard]] std::size_t end_capture(std::size_t s, std::size_t p);
    [[nodiscard]] std::size_t match_capture(std::size_t s, char digit);
    [[nodiscard]] std::size_t capture_to_close();
    void malformed_end();

    State* state_;
    Args args_;
    std::string_view source_;
    std::string_view pattern_;
    std::size_t level_ = 0;
    int depth_ = 0;
    std::array<Capture, kMaxCaptures> captures_{};
};

std::size_t Matcher::check_capture_digit(char digit) {
    const int index = static_cast<int>(digit) - '1';
    if (index < 0 || std::cmp_greater_equal(index, level_) ||
        element(captures_, static_cast<std::size_t>(index)).length == kCaptureUnfinished) {
        state_->native_error("invalid capture index");
        return kNone;
    }
    return static_cast<std::size_t>(index);
}

// Khác gốc: không có (bắt chước đúng lỗi của DLL). LuaPlus.dll ghi câu "malformed pattern (ends with `%')" với MỘT dấu %
// nên luaO_pushvfstring nuốt cặp "%'" và nối thêm cả giá trị nằm dưới "<chunk>:<dòng>: " trên ngăn xếp vào kết quả: câu lỗi
// thật là <giá trị trên cùng của ngăn xếp hàm C> .. <vị trí> .. "malformed pattern (ends with `)" (đo trên DLL:
// pcall(string.find, "abc", "b%") ra "b%malformed pattern (ends with `)"). Giá trị ấy không nối được (nil, boolean, bảng,
// hàm) thì lỗi là "attempt to concatenate a <kiểu> value".
void Matcher::malformed_end() {
    std::string message;
    if (args_.empty()) {
        state_->raise_text("attempt to concatenate a function value");
        return;
    }
    const Value top = args_.back();
    if (top.type() == Type::kString) {
        message = std::string(top.as_string().view());
    } else if (top.type() == Type::kNumber) {
        message = number_to_string(top.as_number());
    } else {
        state_->raise_text(std::string("attempt to concatenate a ") + std::string(type_name(top.type())) + " value");
        return;
    }
    message += state_->where(1);
    message += "malformed pattern (ends with `)";
    state_->raise_text(message);
}

std::size_t Matcher::capture_to_close() {
    for (std::size_t level = level_; level > 0; --level) {
        if (element(captures_, level - 1).length == kCaptureUnfinished) return level - 1;
    }
    state_->native_error("invalid pattern capture");
    return kNone;
}

std::size_t Matcher::class_end(std::size_t p) {
    const char first = pat(p++);
    if (first == kEscape) {
        if (pat(p) == '\0') {
            malformed_end();
            return pattern_.size();
        }
        return p + 1;
    }
    if (first == '[') {
        if (pat(p) == '^') ++p;
        do {
            if (pat(p) == '\0') {
                state_->native_error("malformed pattern (missing `]')");
                return pattern_.size();
            }
            const char current = pat(p);
            ++p;
            if (current == kEscape && pat(p) != '\0') ++p;
        } while (pat(p) != ']');
        return p + 1;
    }
    return p;
}

bool Matcher::match_class(int c, int class_letter) noexcept {
    bool result = false;
    switch (to_lower(class_letter)) {
    case 'a': result = is_alpha(c); break;
    case 'c': result = is_control(c); break;
    case 'd': result = is_digit(c); break;
    case 'l': result = is_lower(c); break;
    case 'p': result = is_punct(c); break;
    case 's': result = is_space(c); break;
    case 'u': result = is_upper(c); break;
    case 'w': result = is_alnum(c); break;
    case 'x': result = is_xdigit(c); break;
    case 'z': result = c == 0; break;
    default: return class_letter == c;
    }
    return is_lower(class_letter) ? result : !result;
}

bool Matcher::match_bracket_class(int c, std::size_t p, std::size_t end_class) const noexcept {
    bool signal = true;
    if (pat(p + 1) == '^') {
        signal = false;
        ++p;
    }
    while (++p < end_class) {
        if (pat(p) == kEscape) {
            ++p;
            if (match_class(c, signed_byte(pat(p)))) return signal;
        } else if (pat(p + 1) == '-' && p + 2 < end_class) {
            p += 2;
            if (unsigned_byte(pat(p - 2)) <= c && c <= unsigned_byte(pat(p))) return signal;
        } else if (unsigned_byte(pat(p)) == c) {
            return signal;
        }
    }
    return !signal;
}

bool Matcher::single_match(int c, std::size_t p, std::size_t ep) const noexcept {
    switch (pat(p)) {
    case '.': return true;
    case kEscape: return match_class(c, signed_byte(pat(p + 1)));
    case '[': return match_bracket_class(c, p, ep - 1);
    default: return unsigned_byte(pat(p)) == c;
    }
}

std::size_t Matcher::match_balance(std::size_t s, std::size_t p) {
    if (pat(p) == '\0' || pat(p + 1) == '\0') {
        state_->native_error("unbalanced pattern");
        return kNone;
    }
    if (src(s) != pat(p)) return kNone;
    const char open = pat(p);
    const char close = pat(p + 1);
    int depth = 1;
    while (++s < source_.size()) {
        if (src(s) == close) {
            if (--depth == 0) return s + 1;
        } else if (src(s) == open) {
            ++depth;
        }
    }
    return kNone;
}

// match, match_inner và bốn hàm dưới gọi lẫn nhau theo cấu trúc của lstrlib.c; match đếm độ sâu và dừng ở kMaxMatchDepth
// nên ngăn xếp có trần.
// NOLINTBEGIN(misc-no-recursion)
std::size_t Matcher::max_expand(std::size_t s, std::size_t p, std::size_t ep) {
    std::size_t count = 0;
    while (s + count < source_.size() && single_match(unsigned_byte(src(s + count)), p, ep)) {
        if (!tick(*state_)) return kNone;
        ++count;
    }
    // Thử với số lần lặp tối đa rồi giảm dần.
    for (;;) {
        const std::size_t result = match(s + count, ep + 1);
        if (result != kNone || failed()) return result;
        if (count == 0) return kNone;
        --count;
    }
}

std::size_t Matcher::min_expand(std::size_t s, std::size_t p, std::size_t ep) {
    for (;;) {
        const std::size_t result = match(s, ep + 1);
        if (result != kNone || failed()) return result;
        if (s < source_.size() && single_match(unsigned_byte(src(s)), p, ep)) {
            if (!tick(*state_)) return kNone;
            ++s;
        } else {
            return kNone;
        }
    }
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): vị trí nguồn, vị trí mẫu, kiểu capture — thứ tự như start_capture của gốc.
std::size_t Matcher::start_capture(std::size_t s, std::size_t p, std::ptrdiff_t what) {
    const std::size_t level = level_;
    if (level >= kMaxCaptures) {
        state_->native_error("too many captures");
        return kNone;
    }
    element(captures_, level) = Capture{.init = s, .length = what};
    level_ = level + 1;
    const std::size_t result = match(s, p);
    if (result == kNone) --level_;
    return result;
}

std::size_t Matcher::end_capture(std::size_t s, std::size_t p) {
    const std::size_t index = capture_to_close();
    if (index == kNone) return kNone;
    Capture& capture = element(captures_, index);
    capture.length = static_cast<std::ptrdiff_t>(s - capture.init);
    const std::size_t result = match(s, p);
    if (result == kNone) capture.length = kCaptureUnfinished;
    return result;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): vị trí nguồn rồi chữ số, như match_capture của gốc.
std::size_t Matcher::match_capture(std::size_t s, char digit) {
    const std::size_t index = check_capture_digit(digit);
    if (index == kNone) return kNone;
    const Capture& capture = element(captures_, index);
    // Capture vị trí có độ dài -2: size_t của gốc thành số rất lớn nên không bao giờ khớp.
    if (capture.length < 0) return kNone;
    const auto length = static_cast<std::size_t>(capture.length);
    if (source_.size() - std::min(s, source_.size()) >= length && source_.compare(s, length, source_.substr(capture.init, length)) == 0)
        return s + length;
    return kNone;
}

std::size_t Matcher::match(std::size_t s, std::size_t p) {
    if (depth_ >= kMaxMatchDepth) {
        state_->native_error("pattern too complex");
        return kNone;
    }
    if (!tick(*state_)) return kNone;
    ++depth_;
    const std::size_t result = match_inner(s, p);
    --depth_;
    return result;
}

std::size_t Matcher::match_inner(std::size_t s, std::size_t p) {
    for (;;) {
        if (failed()) return kNone;
        const char first = pat(p);
        if (first == '(') {
            if (pat(p + 1) == ')') return start_capture(s, p + 2, kCapturePosition);
            return start_capture(s, p + 1, kCaptureUnfinished);
        }
        if (first == ')') return end_capture(s, p + 1);
        if (first == '\0') return s;
        if (first == kEscape) {
            const char next = pat(p + 1);
            if (next == 'b') {
                s = match_balance(s, p + 2);
                if (s == kNone) return kNone;
                p += 4;
                continue;
            }
            if (next == 'f') {
                p += 2;
                if (pat(p) != '[') {
                    state_->native_error("missing `[' after `%f' in pattern");
                    return kNone;
                }
                const std::size_t ep = class_end(p);
                if (failed()) return kNone;
                const int previous = s == 0 ? 0 : unsigned_byte(src(s - 1));
                if (match_bracket_class(previous, p, ep - 1) || !match_bracket_class(unsigned_byte(src(s)), p, ep - 1)) return kNone;
                p = ep;
                continue;
            }
            if (is_digit(unsigned_byte(next))) {
                s = match_capture(s, next);
                if (s == kNone) return kNone;
                p += 2;
                continue;
            }
        } else if (first == '$' && pat(p + 1) == '\0') {
            return s == source_.size() ? s : kNone;
        }
        // Một mục của mẫu.
        const std::size_t ep = class_end(p);
        if (failed()) return kNone;
        const bool matched = s < source_.size() && single_match(unsigned_byte(src(s)), p, ep);
        switch (pat(ep)) {
        case '?': {
            if (matched) {
                const std::size_t result = match(s + 1, ep + 1);
                if (result != kNone || failed()) return result;
            }
            p = ep + 1;
            continue;
        }
        case '*': return max_expand(s, p, ep);
        case '+': return matched ? max_expand(s + 1, p, ep) : kNone;
        case '-': return min_expand(s, p, ep);
        default:
            if (!matched) return kNone;
            ++s;
            p = ep;
            continue;
        }
    }
}
// NOLINTEND(misc-no-recursion)

Value Matcher::one_capture(std::size_t index) {
    const Capture& capture = element(captures_, index);
    if (capture.length == kCaptureUnfinished) {
        state_->native_error("unfinished capture");
        return {};
    }
    if (capture.length == kCapturePosition) return Value::number(static_cast<double>(capture.init + 1));
    return state_->make_string(source_.substr(capture.init, static_cast<std::size_t>(capture.length)));
}

void Matcher::push_captures(Results& out, bool whole, std::size_t s, std::size_t e) {
    if (level_ == 0 && whole) {
        out.push(state_->make_string(source_.substr(s, e - s)));
        return;
    }
    for (std::size_t i = 0; i < level_ && !failed(); ++i)
        out.push(one_capture(i));
}

// ---- find, gfind, gsub ----

Results string_find(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view source = in.text(0);
    const std::string_view pattern = in.text(1);
    std::int32_t init = wrapping_add(relative_position(in.opt_integer(2, 1), source.size()), -1);
    if (in.failed()) return {};
    if (init < 0) init = 0;
    else if (static_cast<std::size_t>(init) > source.size()) init = static_cast<std::int32_t>(source.size());
    const std::string_view c_pattern = c_string(pattern);
    if (in.at(3).truthy() || c_pattern.find_first_of(kSpecials) == std::string_view::npos) {
        const std::size_t found = source.find(pattern, static_cast<std::size_t>(init));
        if (found != std::string_view::npos)
            return {Value::number(static_cast<double>(found + 1)), Value::number(static_cast<double>(found + pattern.size()))};
        return {Value()};
    }
    const bool anchor = !c_pattern.empty() && c_pattern.front() == '^';
    Matcher matcher(state, args, source, anchor ? c_pattern.substr(1) : c_pattern);
    auto start = static_cast<std::size_t>(init);
    do {
        matcher.reset();
        const std::size_t end = matcher.match(start, 0);
        if (state.failed()) return {};
        if (end != Matcher::kNone) {
            Results out;
            out.push(Value::number(static_cast<double>(start + 1)));
            out.push(Value::number(static_cast<double>(end)));
            matcher.push_captures(out, false, 0, 0);
            return out;
        }
    } while (start++ < source.size() && !anchor);
    return {Value()};
}

// gfind_aux: ba upvalue là chuỗi nguồn, mẫu, và vị trí bắt đầu lần tìm kế tiếp.
Results gfind_step(State& state, const Function& self, Args args) {
    const std::string_view source = self.upvalue(0).value.as_string().view();
    const std::string_view pattern = c_string(self.upvalue(1).value.as_string().view());
    Matcher matcher(state, args, source, pattern);
    const auto first = static_cast<std::size_t>(self.upvalue(2).value.as_number());
    for (std::size_t start = first; start <= source.size(); ++start) {
        matcher.reset();
        const std::size_t end = matcher.match(start, 0);
        if (state.failed()) return {};
        if (end == Matcher::kNone) continue;
        // Chỗ khớp rỗng thì lần sau đi ít nhất một vị trí.
        self.upvalue(2).value = Value::number(static_cast<double>(end == start ? end + 1 : end));
        Results out;
        matcher.push_captures(out, true, start, end);
        return out;
    }
    return {};
}

constexpr Proto kGfindStep = {.body = &gfind_step, .name = "gfind_iterator", .upvalues = 3};

Results string_gfind(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view source = in.text(0);
    const std::string_view pattern = in.text(1);
    if (in.failed()) return {};
    const std::array<Value, 3> upvalues = {state.make_string(source), state.make_string(pattern), Value::number(0.0)};
    if (state.failed()) return {};
    return {state.make_native_closure(kGfindStep, upvalues)};
}

Results string_gsub(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view source = in.text(0);
    std::string_view pattern = in.text(1);
    const std::int32_t max_substitutions = in.opt_integer(3, static_cast<std::int32_t>(source.size() + 1));
    if (in.failed()) return {};
    pattern = c_string(pattern);
    const Value replacement = in.at(2);
    if (args.size() < 3 || (replacement.type() != Type::kString && replacement.type() != Type::kNumber &&
                               replacement.type() != Type::kFunction)) {
        in.argument_error(2, "string or function expected");
        return {};
    }
    const bool anchor = !pattern.empty() && pattern.front() == '^';
    if (anchor) pattern.remove_prefix(1);
    // lua_tostring của chuỗi thay thế: số thành chuỗi trước khi duyệt.
    const std::string_view template_text = replacement.type() == Type::kFunction ? std::string_view() : in.text(2);
    if (in.failed()) return {};
    Matcher matcher(state, args, source, pattern);
    Buffer out(state);
    std::size_t at = 0;
    std::int32_t count = 0;
    while (count < max_substitutions) {
        matcher.reset();
        const std::size_t end = matcher.match(at, 0);
        if (state.failed()) return {};
        if (end != Matcher::kNone) {
            ++count;
            if (replacement.type() == Type::kFunction) {
                Results captures;
                matcher.push_captures(captures, true, at, end);
                if (state.failed()) return {};
                const Value result = call(state, replacement, captures.values()).first();
                if (state.failed()) return {};
                if (result.type() == Type::kString) out.add(result.as_string().view());
                else if (result.type() == Type::kNumber) out.add(number_to_string(result.as_number()));
            } else {
                for (std::size_t i = 0; i < template_text.size(); ++i) {
                    if (template_text[i] != kEscape) {
                        out.add(template_text[i]);
                        continue;
                    }
                    // `%` cuối chuỗi: gốc đọc byte 0 kết thúc rồi thêm nó vào kết quả.
                    ++i;
                    const char next = i < template_text.size() ? template_text[i] : '\0';
                    if (!is_digit(unsigned_byte(next))) {
                        out.add(next);
                        continue;
                    }
                    const std::size_t index = matcher.check_capture_digit(next);
                    if (index == Matcher::kNone) return {};
                    const Value captured = matcher.one_capture(index);
                    if (state.failed()) return {};
                    if (captured.type() == Type::kString) out.add(captured.as_string().view());
                    else out.add(number_to_string(captured.as_number()));
                }
            }
        }
        if (end != Matcher::kNone && end > at) {
            at = end;
        } else if (at < source.size()) {
            out.add(source[at++]);
        } else {
            break;
        }
        if (anchor) break;
    }
    out.add(source.substr(at));
    const Value result = out.finish();
    if (state.failed()) return {};
    return {result, Value::number(static_cast<double>(count))};
}

// ---- format ----

// Đặc tả đã đọc xong: scanformat của gốc.
struct ParsedSpec {
    FormatSpec spec;
    char conversion = '\0';
};

constexpr std::size_t kMaxFormatLength = 20;

// strchr("-+ #0", c) với c khác byte 0.
[[nodiscard]] constexpr bool is_flag(char letter) noexcept {
    return letter == '-' || letter == '+' || letter == ' ' || letter == '#' || letter == '0';
}

// scanformat: từ vị trí at (sau '%'); trả false (đã ghi lỗi) khi đặc tả sai. Cập nhật at tới sau ký tự kiểu.
[[nodiscard]] bool scan_format(State& state, std::string_view format, std::size_t& at, ParsedSpec& parsed) {
    const std::size_t begin = at;
    const auto peek = [&](std::size_t index) { return index < format.size() ? format[index] : '\0'; };
    FormatSpec& spec = parsed.spec;
    while (is_flag(peek(at))) {
        switch (peek(at)) {
        case '-': spec.left = true; break;
        case '+': spec.sign = true; break;
        case ' ': spec.blank = true; break;
        case '#': spec.alternate = true; break;
        default: spec.zero = true; break;
        }
        ++at;
    }
    const auto read_number = [&]() {
        int value = 0;
        for (int i = 0; i < 2 && is_digit(unsigned_byte(peek(at))); ++i) value = value * 10 + (peek(at++) - '0');
        return value;
    };
    spec.width = read_number();
    if (peek(at) == '.') {
        ++at;
        spec.precision = read_number();
    }
    if (is_digit(unsigned_byte(peek(at)))) {
        state.native_error("invalid format (width or precision too long)");
        return false;
    }
    // +2: '%' và ký tự kiểu.
    if (at - begin + 2 > kMaxFormatLength) {
        state.native_error("invalid format (too long)");
        return false;
    }
    if (at >= format.size()) {
        state.native_error("invalid option to `format'");
        return false;
    }
    parsed.conversion = format[at++];
    return true;
}

// (unsigned int)double của MSVC x64: qua int64 (cvttsd2si), ngoài miền int64 hay NaN ra byte thấp của 0x8000000000000000.
[[nodiscard]] std::uint32_t to_unsigned(double value) noexcept {
    if (value >= -9223372036854775808.0 && value < 9223372036854775808.0)
        return static_cast<std::uint32_t>(static_cast<std::uint64_t>(static_cast<std::int64_t>(value)));
    return 0;
}

void add_quoted(Buffer& out, std::string_view text) {
    out.add('"');
    for (const char letter : text) {
        switch (letter) {
        case '"':
        case '\\':
        case '\n':
            out.add('\\');
            out.add(letter);
            break;
        case '\0': out.add("\\000"); break;
        default: out.add(letter); break;
        }
    }
    out.add('"');
}

Results string_format(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::string_view format = in.text(0);
    if (in.failed()) return {};
    Buffer out(state);
    std::size_t arg = 0;
    std::size_t at = 0;
    while (at < format.size() && !state.failed()) {
        if (format[at] != '%') {
            const std::size_t next = std::min(format.find('%', at), format.size());
            out.add(format.substr(at, next - at));
            at = next;
            continue;
        }
        ++at;
        if (at < format.size() && format[at] == '%') {
            out.add('%');
            ++at;
            continue;
        }
        if (at + 1 < format.size() && is_digit(unsigned_byte(format[at])) && format[at + 1] == '$') {
            state.native_error("obsolete option (d$) to `format'");
            return {};
        }
        ++arg;
        ParsedSpec parsed;
        if (!scan_format(state, format, at, parsed)) return {};
        switch (parsed.conversion) {
        case 'c':
        case 'd':
        case 'i': {
            const std::int32_t value = in.integer(arg);
            if (in.failed()) return {};
            out.add(parsed.conversion == 'c' ? format_char(parsed.spec, value) : format_signed(parsed.spec, value));
            break;
        }
        case 'o':
        case 'u':
        case 'x':
        case 'X': {
            const double value = in.number(arg);
            if (in.failed()) return {};
            out.add(format_unsigned(parsed.conversion, parsed.spec, to_unsigned(value)));
            break;
        }
        case 'e':
        case 'E':
        case 'f':
        case 'g':
        case 'G': {
            const double value = in.number(arg);
            if (in.failed()) return {};
            out.add(format_double(parsed.conversion, parsed.spec, value));
            break;
        }
        case 'q': {
            const std::string_view text = in.text(arg);
            if (in.failed()) return {};
            add_quoted(out, text);
            break;
        }
        case 's': {
            const std::string_view text = in.text(arg);
            if (in.failed()) return {};
            // Không có độ chính xác và chuỗi dài từ 100 byte: giữ nguyên chuỗi gốc (kể cả byte 0 bên trong).
            if (parsed.spec.precision < 0 && text.size() >= 100) out.add(text);
            else out.add(format_text(parsed.spec, text));
            break;
        }
        default: state.native_error("invalid option to `format'"); return {};
        }
    }
    const Value result = out.finish();
    if (state.failed()) return {};
    return {result};
}

// Thứ tự của mảng này là thứ tự luaL_openlib chèn vào bảng, nên quyết định thứ tự pairs(string).
constexpr std::array<Proto, 13> kStringFunctions = {{
    {.body = &string_len, .name = "len"},
    {.body = &string_sub, .name = "sub"},
    {.body = &string_lower, .name = "lower"},
    {.body = &string_upper, .name = "upper"},
    {.body = &string_char, .name = "char"},
    {.body = &string_rep, .name = "rep"},
    {.body = &string_byte, .name = "byte"},
    {.body = &string_format, .name = "format"},
    {.body = &string_unsupported, .name = "dump"},
    {.body = &string_find, .name = "find"},
    {.body = &string_gfind, .name = "gfind"},
    {.body = &string_gsub, .name = "gsub"},
    {.body = &string_unsupported, .name = "lualex"},
}};

} // namespace

void open_string(State& state) {
    // Bảng của kiểu chuỗi chính là bảng `string` (LuaPlus: getmetatable("") == string); State tạo sẵn nó.
    Table* const library = state.type_table(Type::kString);
    state.set_global("string", Value(library));
    register_functions(state, *library, kStringFunctions);
}

} // namespace game::lua
