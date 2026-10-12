// Test của xml: cây phần tử, thuộc tính, thực thể, chữ trong phần tử, và các lỗi cú pháp phải được
// báo đúng loại thay vì đọc sai (KT-01, KT-02).
#include "core/check.hpp"
#include "test.hpp"
#include "xml/document.hpp"

#include <array>
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

constexpr std::array kCases{
    Case{.name = "parse_builds_tree_in_file_order", .body = &parse_builds_tree_in_file_order},
    Case{.name = "parse_decodes_entities_and_text", .body = &parse_decodes_entities_and_text},
    Case{.name = "parse_reports_broken_input", .body = &parse_reports_broken_input},
    Case{.name = "parse_reports_offset_of_fault", .body = &parse_reports_offset_of_fault},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "xml_tests: mọi ca phải qua");
    return 0;
}
