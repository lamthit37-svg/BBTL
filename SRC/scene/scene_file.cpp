#include "scene/scene_file.hpp"

#include "xml/document.hpp"

#include <algorithm>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scene {
namespace {

[[nodiscard]] std::string text_of(const xml::Element& element, std::string_view name) {
    return std::string(xml::attribute(element, name).value_or(std::string_view{}));
}

// Thêm một phần tử con của Object vào danh sách thuộc tính; phần tử khác Property bị bỏ qua.
void add_property(Object& object, const xml::Element& item) {
    if (item.name != "Property") return;
    Property entry{.name = text_of(item, "name"), .value = text_of(item, "value")};
    object.properties.push_back(std::move(entry));
}

[[nodiscard]] Object object_of(const xml::Document& document, const xml::Element& element) {
    Object object;
    object.type = text_of(element, "type");
    object.name = text_of(element, "name");
    for (const std::uint32_t child : element.children) {
        add_property(object, document.elements[child]);
    }
    return object;
}

using Indices = std::vector<std::uint32_t>;

// Ghi index làm cha của mọi phần tử con của element.
void adopt_children(Indices& parents, const xml::Element& element, std::uint32_t index) {
    for (const std::uint32_t child : element.children) {
        parents[child] = index;
    }
}

// Chỉ số phần tử cha của từng phần tử; gốc tự làm cha của chính nó.
[[nodiscard]] Indices parents_of(const xml::Document& document) {
    Indices parents(document.elements.size(), 0);
    for (std::uint32_t index = 0; index < parents.size(); ++index) {
        adopt_children(parents, document.elements[index], index);
    }
    return parents;
}

// Việc trải phẳng: phần tử nào là nơi chứa vật thể (gốc Scene và các Group lồng trong nó).
struct Flattening {
    Indices parents;
    std::vector<bool> is_container;
    SceneFile scene;
};

// Xét một phần tử theo thứ tự tệp. Cha của nó luôn đứng trước nên cờ của cha đã có.
void visit(Flattening& state, const xml::Document& document, std::uint32_t index) {
    if (!state.is_container[state.parents[index]]) return;
    const xml::Element& element = document.elements[index];
    if (element.name == "Object") state.scene.objects.push_back(object_of(document, element));
    if (element.name == "Group") state.is_container[index] = true;
    if (element.name == "Terrain") state.scene.terrain_file = text_of(element, "filename");
    if (element.name != "SkySphere") return;
    const std::string filename = text_of(element, "filename");
    if (!filename.empty()) state.scene.sky_file = filename;
}

} // namespace

SceneResult read_scene(std::string_view text) {
    const auto document = xml::parse(text);
    if (!document) return std::unexpected(SceneError::kBadXml);
    const xml::Element& root = document->elements.front();
    if (root.name != "Scene") return std::unexpected(SceneError::kNotScene);
    Flattening state;
    state.parents = parents_of(*document);
    state.is_container.assign(document->elements.size(), false);
    state.is_container.front() = true;
    state.scene.name = text_of(root, "name");
    // xml::parse xếp phần tử theo thứ tự thẻ mở, nên duyệt theo chỉ số là duyệt theo thứ tự tệp.
    for (std::uint32_t index = 1; index < state.parents.size(); ++index) {
        visit(state, *document, index);
    }
    return std::move(state.scene);
}

OptionalText property(const Object& object, std::string_view name) noexcept {
    const auto found = std::ranges::find(object.properties, name, &Property::name);
    if (found == object.properties.end()) return std::nullopt;
    return std::string_view(found->value);
}

} // namespace game::scene
