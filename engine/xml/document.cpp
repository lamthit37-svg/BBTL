#include "xml/document.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::xml {
namespace {

// .Scene lồng sâu nhất 4 cấp (Scene, Group, Object, Property); trần rộng hơn nhiều so với nhu cầu.
constexpr std::size_t kMaxDepth = 256;
constexpr std::uint32_t kMaxCodePoint = 0x10FFFF;
constexpr std::string_view kSpaces = " \t\r\n";
constexpr std::string_view kNameEnd = " \t\r\n=/><";

using Step = std::expected<void, Fault>;
using TextStep = std::expected<std::string, Fault>;

[[nodiscard]] std::string_view trimmed(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(kSpaces);
    if (first == std::string_view::npos) return {};
    const std::size_t last = text.find_last_not_of(kSpaces);
    return text.substr(first, last - first + 1);
}

// Một byte nối tiếp của UTF-8 mang 6 bit của điểm mã, lấy từ vị trí shift.
[[nodiscard]] char continuation(std::uint32_t point, std::uint32_t shift) noexcept {
    return static_cast<char>(0x80U | ((point >> shift) & 0x3FU));
}

// Nối mã UTF-8 của một điểm mã không vượt kMaxCodePoint.
void append_utf8(std::string& output, std::uint32_t point) {
    if (point < 0x80U) {
        output.push_back(static_cast<char>(point));
        return;
    }
    if (point < 0x800U) {
        output.push_back(static_cast<char>(0xC0U | (point >> 6U)));
        output.push_back(continuation(point, 0));
        return;
    }
    if (point < 0x10000U) {
        output.push_back(static_cast<char>(0xE0U | (point >> 12U)));
        output.push_back(continuation(point, 6));
        output.push_back(continuation(point, 0));
        return;
    }
    output.push_back(static_cast<char>(0xF0U | (point >> 18U)));
    output.push_back(continuation(point, 12));
    output.push_back(continuation(point, 6));
    output.push_back(continuation(point, 0));
}

// Mã hoá của văn bản theo BOM đầu tệp; không có BOM là UTF-8. 29 layout giao diện của client 2026
// lưu UTF-16 LE có BOM (EquipRepair, Anniversary_*...); CEGUI gốc đọc được, nên bộ đọc phải đọc được.
enum class Encoding : std::uint8_t { kUtf8, kUtf16Little, kUtf16Big };

struct Detected {
    Encoding encoding = Encoding::kUtf8;
    // Số byte BOM đứng đầu tệp.
    std::size_t bom = 0;
};

[[nodiscard]] Detected detect_encoding(std::string_view source) noexcept {
    constexpr std::string_view kUtf8Bom = "\xEF\xBB\xBF";
    constexpr std::string_view kLittleBom = "\xFF\xFE";
    constexpr std::string_view kBigBom = "\xFE\xFF";
    if (source.starts_with(kUtf8Bom)) return {.encoding = Encoding::kUtf8, .bom = kUtf8Bom.size()};
    if (source.starts_with(kLittleBom)) return {.encoding = Encoding::kUtf16Little, .bom = kLittleBom.size()};
    if (source.starts_with(kBigBom)) return {.encoding = Encoding::kUtf16Big, .bom = kBigBom.size()};
    return {};
}

// Đơn vị UTF-16 ở offset (cần offset + 2 <= bytes.size()); is_big chọn thứ tự byte.
[[nodiscard]] std::uint32_t unit_at(std::string_view bytes, std::size_t offset, bool is_big) noexcept {
    const auto first = static_cast<std::uint32_t>(static_cast<unsigned char>(bytes[offset]));
    const auto second = static_cast<std::uint32_t>(static_cast<unsigned char>(bytes[offset + 1]));
    return is_big ? (first << 8U) | second : (second << 8U) | first;
}

[[nodiscard]] bool is_high_surrogate(std::uint32_t unit) noexcept {
    return unit >= 0xD800U && unit <= 0xDBFFU;
}

[[nodiscard]] bool is_low_surrogate(std::uint32_t unit) noexcept {
    return unit >= 0xDC00U && unit <= 0xDFFFU;
}

// Một điểm mã UTF-16 và số byte nó dùng (2, hoặc 4 với cặp thay thế); used bằng 0 khi dữ liệu hỏng.
struct Utf16Step {
    std::uint32_t point = 0;
    std::size_t used = 0;
};

[[nodiscard]] Utf16Step utf16_step(std::string_view bytes, std::size_t offset, bool is_big) noexcept {
    const std::uint32_t head = unit_at(bytes, offset, is_big);
    if (is_low_surrogate(head)) return {};
    if (!is_high_surrogate(head)) return {.point = head, .used = 2};
    if (offset + 4 > bytes.size()) return {};
    const std::uint32_t low = unit_at(bytes, offset + 2, is_big);
    if (!is_low_surrogate(low)) return {};
    return {.point = 0x10000U + ((head - 0xD800U) << 10U) + (low - 0xDC00U), .used = 4};
}

// UTF-16 (không kể BOM) sang UTF-8. Số byte lẻ, nửa cặp thay thế lạc chỗ hay bị cụt là dữ liệu hỏng:
// nullopt. Đầu ra không quá 1,5 lần đầu vào.
[[nodiscard]] std::optional<std::string> utf8_of_utf16(std::string_view bytes, bool is_big) {
    if (bytes.size() % 2 != 0) return std::nullopt;
    std::string output;
    output.reserve(bytes.size() + (bytes.size() / 2));
    std::size_t offset = 0;
    while (offset < bytes.size()) {
        const Utf16Step step = utf16_step(bytes, offset, is_big);
        if (step.used == 0) return std::nullopt;
        append_utf8(output, step.point);
        offset += step.used;
    }
    return output;
}

// Thực thể số "#N" hoặc "#xH" (đã bỏ & và ;). Trả false khi không phải số hợp lệ.
[[nodiscard]] bool append_numeric_entity(std::string& output, std::string_view body) {
    const bool is_hex = body.starts_with("#x") || body.starts_with("#X");
    const std::string_view digits = body.substr(is_hex ? 2 : 1);
    const auto number = core::parse_unsigned(digits, is_hex ? 16 : 10);
    const bool is_whole = number && number->length == digits.size();
    if (!is_whole || number->value == 0 || number->value > kMaxCodePoint) return false;
    append_utf8(output, number->value);
    return true;
}

// Một thực thể (phần giữa & và ;). Trả false khi tên lạ.
[[nodiscard]] bool append_entity(std::string& output, std::string_view body) {
    if (body.starts_with('#')) return append_numeric_entity(output, body);
    if (body == "lt") output.push_back('<');
    if (body == "gt") output.push_back('>');
    if (body == "amp") output.push_back('&');
    if (body == "quot") output.push_back('"');
    if (body == "apos") output.push_back('\'');
    return body == "lt" || body == "gt" || body == "amp" || body == "quot" || body == "apos";
}

// Trạng thái giải thực thể của một đoạn chữ thô.
struct Decoding {
    std::string_view raw;
    // Vị trí của raw trong văn bản nguồn, để lỗi chỉ đúng chỗ.
    std::size_t offset = 0;
    std::size_t cursor = 0;
    std::string output;
};

// Chép phần chữ tới thực thể kế tiếp rồi giải thực thể đó; cursor tiến qua cả hai.
[[nodiscard]] Step decode_piece(Decoding& state) {
    const std::size_t mark = state.raw.find('&', state.cursor);
    state.output.append(state.raw.substr(state.cursor, mark - state.cursor));
    state.cursor = state.raw.size();
    if (mark == std::string_view::npos) return {};
    const std::size_t end = state.raw.find(';', mark);
    const Fault fault{.error = XmlError::kBadEntity, .offset = state.offset + mark};
    if (end == std::string_view::npos) return std::unexpected(fault);
    const std::string_view body = state.raw.substr(mark + 1, end - mark - 1);
    if (!append_entity(state.output, body)) return std::unexpected(fault);
    state.cursor = end + 1;
    return {};
}

[[nodiscard]] TextStep decode(std::string_view raw, std::size_t offset) {
    Decoding state;
    state.raw = raw;
    state.offset = offset;
    state.output.reserve(raw.size());
    Step status{};
    while (status && state.cursor < raw.size()) {
        status = decode_piece(state);
    }
    if (!status) return std::unexpected(status.error());
    return std::move(state.output);
}

class Parser {
public:
    explicit Parser(std::string_view source) noexcept : source_(source) {}

    [[nodiscard]] ParseResult run();

private:
    [[nodiscard]] std::unexpected<Fault> fail(XmlError error) const noexcept;
    [[nodiscard]] bool starts_with(std::string_view prefix) const noexcept;
    [[nodiscard]] bool is_at_tag_end() const noexcept;
    [[nodiscard]] Step step();
    [[nodiscard]] Step skip_past(std::string_view terminator);
    [[nodiscard]] Step read_text();
    [[nodiscard]] Step read_close();
    [[nodiscard]] Step read_open();
    [[nodiscard]] Step read_attribute(Element& element);
    [[nodiscard]] Step add_element(Element element, bool is_self_closing);
    [[nodiscard]] std::string_view read_name() noexcept;
    void skip_spaces() noexcept;

    std::string_view source_;
    std::size_t position_ = 0;
    Document document_;
    // Chỉ số các phần tử đang mở, ngoài cùng trước.
    std::vector<std::uint32_t> open_;
};

std::unexpected<Fault> Parser::fail(XmlError error) const noexcept {
    return std::unexpected(Fault{.error = error, .offset = position_});
}

bool Parser::starts_with(std::string_view prefix) const noexcept {
    return source_.substr(position_).starts_with(prefix);
}

// Hết thuộc tính của thẻ mở: gặp ">" hoặc "/>", hoặc văn bản bị cắt.
bool Parser::is_at_tag_end() const noexcept {
    return position_ >= source_.size() || starts_with(">") || starts_with("/>");
}

void Parser::skip_spaces() noexcept {
    position_ = std::min(source_.find_first_not_of(kSpaces, position_), source_.size());
}

// Tên phần tử hoặc thuộc tính: chạy tới khoảng trắng hoặc một trong các dấu = / > <.
std::string_view Parser::read_name() noexcept {
    const std::size_t start = position_;
    position_ = std::min(source_.find_first_of(kNameEnd, start), source_.size());
    return source_.substr(start, position_ - start);
}

Step Parser::skip_past(std::string_view terminator) {
    const std::size_t found = source_.find(terminator, position_);
    if (found == std::string_view::npos) return fail(XmlError::kTruncated);
    position_ = found + terminator.size();
    return {};
}

// Chữ giữa hai thẻ. Chữ ngoài phần tử gốc (thường là xuống dòng) bị bỏ qua.
Step Parser::read_text() {
    const std::size_t start = position_;
    position_ = std::min(source_.find('<', start), source_.size());
    const std::string_view raw = trimmed(source_.substr(start, position_ - start));
    if (raw.empty() || open_.empty()) return {};
    auto text = decode(raw, start);
    if (!text) return std::unexpected(text.error());
    document_.elements[open_.back()].text += *text;
    return {};
}

Step Parser::read_close() {
    position_ += 2;
    const std::string_view name = read_name();
    skip_spaces();
    if (position_ >= source_.size()) return fail(XmlError::kTruncated);
    if (!starts_with(">")) return fail(XmlError::kBadSyntax);
    const bool is_matching = !open_.empty() && document_.elements[open_.back()].name == name;
    if (!is_matching) return fail(XmlError::kMismatchedClose);
    ++position_;
    open_.pop_back();
    return {};
}

// Một thuộc tính tên="giá trị" (nháy kép hoặc nháy đơn), rồi bỏ khoảng trắng theo sau.
Step Parser::read_attribute(Element& element) {
    const std::string_view name = read_name();
    if (name.empty()) return fail(XmlError::kBadSyntax);
    skip_spaces();
    if (!starts_with("=")) return fail(XmlError::kBadSyntax);
    ++position_;
    skip_spaces();
    if (position_ >= source_.size()) return fail(XmlError::kTruncated);
    const bool is_quoted = starts_with("\"") || starts_with("'");
    if (!is_quoted) return fail(XmlError::kBadSyntax);
    const std::size_t start = position_ + 1;
    const std::size_t end = source_.find(source_.substr(position_, 1), start);
    if (end == std::string_view::npos) return fail(XmlError::kTruncated);
    auto value = decode(source_.substr(start, end - start), start);
    if (!value) return std::unexpected(value.error());
    element.attributes.push_back(Attribute{.name = std::string(name), .value = std::move(*value)});
    position_ = end + 1;
    skip_spaces();
    return {};
}

Step Parser::add_element(Element element, bool is_self_closing) {
    const bool is_second_root = open_.empty() && !document_.elements.empty();
    if (is_second_root) return fail(XmlError::kBadSyntax);
    if (open_.size() >= kMaxDepth) return fail(XmlError::kTooDeep);
    const auto index = static_cast<std::uint32_t>(document_.elements.size());
    document_.elements.push_back(std::move(element));
    if (!open_.empty()) document_.elements[open_.back()].children.push_back(index);
    if (!is_self_closing) open_.push_back(index);
    return {};
}

Step Parser::read_open() {
    ++position_;
    Element element;
    element.name = std::string(read_name());
    if (element.name.empty()) return fail(XmlError::kBadSyntax);
    skip_spaces();
    Step status{};
    while (status && !is_at_tag_end()) {
        status = read_attribute(element);
    }
    if (!status) return status;
    if (position_ >= source_.size()) return fail(XmlError::kTruncated);
    const bool is_self_closing = starts_with("/>");
    position_ += is_self_closing ? 2 : 1;
    return add_element(std::move(element), is_self_closing);
}

Step Parser::step() {
    if (!starts_with("<")) return read_text();
    if (starts_with("<?")) return skip_past("?>");
    if (starts_with("<!--")) return skip_past("-->");
    if (starts_with("<!")) return fail(XmlError::kUnsupported);
    if (starts_with("</")) return read_close();
    return read_open();
}

ParseResult Parser::run() {
    Step status{};
    while (status && position_ < source_.size()) {
        status = step();
    }
    if (!status) return std::unexpected(status.error());
    if (document_.elements.empty()) return fail(XmlError::kNoRoot);
    if (!open_.empty()) return fail(XmlError::kTruncated);
    return std::move(document_);
}

} // namespace

ParseResult parse(std::string_view source) {
    const Detected detected = detect_encoding(source);
    const std::string_view body = source.substr(detected.bom);
    if (detected.encoding == Encoding::kUtf8) {
        Parser parser(body);
        ParseResult result = parser.run();
        if (!result) result.error().offset += detected.bom;
        return result;
    }
    const bool is_big = detected.encoding == Encoding::kUtf16Big;
    const std::optional<std::string> utf8 = utf8_of_utf16(body, is_big);
    if (!utf8) return std::unexpected(Fault{.error = XmlError::kBadSyntax, .offset = 0});
    Parser parser(*utf8);
    return parser.run();
}

OptionalText attribute(const Element& element, std::string_view name) noexcept {
    const auto found = std::ranges::find(element.attributes, name, &Attribute::name);
    if (found == element.attributes.end()) return std::nullopt;
    return std::string_view(found->value);
}

} // namespace game::xml
