// Test của xml: cây phần tử, thuộc tính, thực thể, chữ trong phần tử, và các lỗi cú pháp phải được
// báo đúng loại thay vì đọc sai (KT-01, KT-02).
#include "core/check.hpp"
#include "test.hpp"
#include "xml/document.hpp"

#include <array>
#include <string>
#include <string_view>

namespace game::test {
namespace {

static_assert(__cplusplus >= 202302L, "dự án cần C++23");

constexpr std::string_view kSample = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"
                                     "<!-- chú thích -->\n"
                                     "<Scene formatVersion=\"0.1.1\" name='thử'>\n"
                                     "  <Author>Genva &amp; Xie</Author>\n"
                                     "  <Terrain filename=\"a.Terrain\"/>\n"
                                     "  <Object type=\"StaticEntity\">\n"
                                     "    <Property name=\"mesh name\" value=\"大理/大理城门.mesh\"/>\n"
                                     "    <Property name=\"note\" value=\"&lt;a&gt; &quot;b&quot; &#65;&#x4E2D;\" />\n"
                                     "  </Object>\n"
                                     "</Scene>\n";

void parse_builds_tree_in_file_order(Context& context) noexcept {
    const auto document = xml::parse(kSample);
    context.expect(document.has_value(), "tài liệu mẫu đọc được");
    if (!document) return;
    const xml::Element& root = document->elements.front();
    context.expect(root.name == "Scene", "gốc là Scene");
    context.expect(root.children.size() == 3, "gốc có ba phần tử con");
    context.expect(xml::attribute(root, "name") == "thử", "thuộc tính trong nháy đơn");
    context.expect(!xml::attribute(root, "missing").has_value(), "thuộc tính vắng là không có");
    const xml::Element& object = document->elements[root.children[2]];
    context.expect(object.name == "Object", "phần tử con thứ ba là Object");
    context.expect(object.children.size() == 2, "Object có hai Property");
    const xml::Element& mesh = document->elements[object.children[0]];
    context.expect(xml::attribute(mesh, "value") == "大理/大理城门.mesh", "UTF-8 giữ nguyên");
}

void parse_decodes_entities_and_text(Context& context) noexcept {
    const auto document = xml::parse(kSample);
    context.expect(document.has_value(), "tài liệu mẫu đọc được");
    if (!document) return;
    const xml::Element& root = document->elements.front();
    const xml::Element& author = document->elements[root.children[0]];
    context.expect(author.text == "Genva & Xie", "chữ trong phần tử, thực thể đã giải");
    const xml::Element& object = document->elements[root.children[2]];
    const xml::Element& note = document->elements[object.children[1]];
    context.expect(xml::attribute(note, "value") == "<a> \"b\" A中", "thực thể tên và số");
}

[[nodiscard]] bool fails_with(std::string_view source, xml::XmlError error) noexcept {
    const auto document = xml::parse(source);
    return !document && document.error().error == error;
}

void parse_reports_broken_input(Context& context) noexcept {
    context.expect(fails_with("", xml::XmlError::kNoRoot), "rỗng: không có gốc");
    context.expect(fails_with("<a><b></a>", xml::XmlError::kMismatchedClose), "thẻ đóng lệch");
    context.expect(fails_with("<a><b/>", xml::XmlError::kTruncated), "thiếu thẻ đóng");
    context.expect(fails_with("<a x=\"1/>", xml::XmlError::kTruncated), "thiếu dấu nháy đóng");
    context.expect(fails_with("<a x=1/>", xml::XmlError::kBadSyntax), "giá trị không có nháy");
    context.expect(fails_with("<a x=\"&nope;\"/>", xml::XmlError::kBadEntity), "thực thể lạ");
    context.expect(fails_with("<a/><b/>", xml::XmlError::kBadSyntax), "hai phần tử gốc");
    context.expect(fails_with("<a><![CDATA[x]]></a>", xml::XmlError::kUnsupported), "CDATA");
}

void parse_reports_offset_of_fault(Context& context) noexcept {
    const auto document = xml::parse("<a><b></c></a>");
    context.expect(!document.has_value(), "thẻ đóng lệch là lỗi");
    if (document) return;
    context.expect(document.error().offset == 9, "vị trí lỗi ở ngay sau tên thẻ đóng lệch");
}

// UTF-16 như tệp layout của client 2026 (BOM, mỗi đơn vị hai byte); big chọn thứ tự byte của đơn vị.
enum class Order : bool { kLittle, kBig };

[[nodiscard]] std::string utf16_file(std::u16string_view text, Order order, bool has_bom = true) {
    std::string bytes;
    const auto put = [&bytes, order](char16_t unit) {
        const auto low = static_cast<char>(unit & 0xFFU);
        const auto high = static_cast<char>((unit >> 8U) & 0xFFU);
        bytes.push_back(order == Order::kBig ? high : low);
        bytes.push_back(order == Order::kBig ? low : high);
    };
    if (has_bom) put(u'\uFEFF');
    for (const char16_t unit : text) put(unit);
    return bytes;
}

constexpr std::u16string_view kWide = u"<?xml version=\"1.0\" ?>\r\n<Layout name=\"大理\">\r\n"
                                      u"  <Window Text=\"帮助 𠀀\"/>\r\n</Layout>\r\n";

void parse_reads_utf16_with_bom(Context& context) noexcept {
    for (const Order order : {Order::kLittle, Order::kBig}) {
        const std::string file = utf16_file(kWide, order);
        const auto document = xml::parse(file);
        context.expect(document.has_value(), "UTF-16 có BOM đọc được");
        if (!document) return;
        const xml::Element& root = document->elements.front();
        context.expect(root.name == "Layout" && xml::attribute(root, "name") == "大理", "chữ Hán ra UTF-8");
        const xml::Element& window = document->elements[root.children.front()];
        context.expect(xml::attribute(window, "Text") == "帮助 \U00020000", "cặp thay thế thành một điểm mã");
    }
}

void parse_skips_utf8_bom(Context& context) noexcept {
    const std::string source = std::string("\xEF\xBB\xBF") + "<a/>";
    const auto document = xml::parse(source);
    context.expect(document.has_value() && document->elements.front().name == "a", "BOM UTF-8 bị bỏ");
    const auto broken = xml::parse(std::string("\xEF\xBB\xBF") + "<a><b></c></a>");
    context.expect(!broken && broken.error().offset == 12, "vị trí lỗi vẫn tính từ đầu tệp");
}

void parse_rejects_broken_utf16(Context& context) noexcept {
    const std::string odd = utf16_file(u"<a/>", Order::kLittle) + "x";
    context.expect(fails_with(odd, xml::XmlError::kBadSyntax), "số byte lẻ");
    const std::u16string lone_low = u"<a x=\"" + std::u16string(1, char16_t{0xDC00}) + u"\"/>";
    context.expect(fails_with(utf16_file(lone_low, Order::kLittle), xml::XmlError::kBadSyntax), "nửa sau đứng một mình");
    const std::u16string lone_high = u"<a x=\"" + std::u16string(1, char16_t{0xD800}) + u"\"/>";
    context.expect(fails_with(utf16_file(lone_high, Order::kBig), xml::XmlError::kBadSyntax), "nửa đầu không có nửa sau");
    const std::u16string cut = u"<a/>" + std::u16string(1, char16_t{0xD800});
    context.expect(fails_with(utf16_file(cut, Order::kLittle), xml::XmlError::kBadSyntax), "nửa đầu cụt ở cuối tệp");
    context.expect(fails_with(utf16_file(u"<a/>", Order::kLittle).substr(0, 2), xml::XmlError::kNoRoot), "chỉ có BOM");
}

void parse_rejects_surrogate_entities(Context& context) noexcept {
    context.expect(fails_with("<a>&#xD800;</a>", xml::XmlError::kBadEntity), "nửa đầu &#xD800; bị từ chối");
    context.expect(fails_with("<a>&#xDFFF;</a>", xml::XmlError::kBadEntity), "nửa cuối &#xDFFF; bị từ chối");
    context.expect(fails_with("<a>&#55296;</a>", xml::XmlError::kBadEntity), "thập phân 55296 bị từ chối");
    context.expect(fails_with("<a>&#57343;</a>", xml::XmlError::kBadEntity), "thập phân 57343 bị từ chối");
    context.expect(
        fails_with("<a x=\"&#xDC00;\"/>", xml::XmlError::kBadEntity), "trong thuộc tính cũng bị từ chối");
    context.expect(xml::parse("<a>&#xD7FF;</a>").has_value(), "&#xD7FF; kề dưới vẫn đọc được");
    context.expect(xml::parse("<a>&#xE000;</a>").has_value(), "&#xE000; kề trên vẫn đọc được");
}

constexpr std::array kCases{
    Case{.name = "parse_builds_tree_in_file_order", .body = &parse_builds_tree_in_file_order},
    Case{.name = "parse_decodes_entities_and_text", .body = &parse_decodes_entities_and_text},
    Case{.name = "parse_reports_broken_input", .body = &parse_reports_broken_input},
    Case{.name = "parse_reports_offset_of_fault", .body = &parse_reports_offset_of_fault},
    Case{.name = "parse_reads_utf16_with_bom", .body = &parse_reads_utf16_with_bom},
    Case{.name = "parse_skips_utf8_bom", .body = &parse_skips_utf8_bom},
    Case{.name = "parse_rejects_broken_utf16", .body = &parse_rejects_broken_utf16},
    Case{.name = "parse_rejects_surrogate_entities", .body = &parse_rejects_surrogate_entities},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "xml_tests: mọi ca phải qua");
    return 0;
}
