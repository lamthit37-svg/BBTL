// Xem catalog.hpp. Chỉ nhận XML mà module xml đọc được; không tự viết parser.
#include "audio/catalog.hpp"

#include "core/error.hpp"
#include "xml/document.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace game::audio {
namespace {

struct Row {
    std::string name;
    std::string path;
};

struct Columns {
    const std::vector<std::string>* names = nullptr;
    const std::vector<std::string>* paths = nullptr;
};

struct Probe {
    std::size_t index = 0;
    std::string_view name;
};

void consider(std::string_view* hit, const Columns& columns, Probe probe) {
    if (hit == nullptr || !hit->empty()) return;
    if (columns.names == nullptr || columns.paths == nullptr) return;
    if (probe.index >= columns.names->size()) return;
    if (probe.index >= columns.paths->size()) return;
    if ((*columns.names)[probe.index] != probe.name) return;
    *hit = (*columns.paths)[probe.index];
}

void take_row(std::vector<Row>& rows, const xml::Element& element) {
    if (element.name != "item") return;
    const xml::OptionalText name = xml::attribute(element, "name");
    const xml::OptionalText path = xml::attribute(element, "value");
    if (!name || !path) return;
    if (name->empty() || path->empty()) return;
    const std::string row_name(*name);
    const std::string row_path(*path);
    const Row row{.name = row_name, .path = row_path};
    rows.push_back(row);
}

} // namespace

void Catalog::add_unique(NamedPath row) {
    if (!find(row.name).empty()) return;
    names_.emplace_back(row.name);
    paths_.emplace_back(row.path);
}

core::Status Catalog::load(std::string_view xml_text) {
    const xml::ParseResult parsed = xml::parse(xml_text);
    if (!parsed) return core::fail(core::ErrorCode::kCorrupt, "bảng âm thanh hỏng");
    std::vector<Row> rows;
    for (const xml::Element& element : parsed->elements)
        take_row(rows, element);
    names_.clear();
    paths_.clear();
    for (const Row& row : rows) {
        const NamedPath named{.name = row.name, .path = row.path};
        add_unique(named);
    }
    if (names_.empty()) return core::fail(core::ErrorCode::kCorrupt, "bảng âm thanh không có mục");
    return core::ok();
}

std::string_view Catalog::find(std::string_view name) const noexcept {
    std::string_view hit;
    const Columns columns{.names = &names_, .paths = &paths_};
    for (std::size_t index = 0; index < names_.size(); ++index) {
        const Probe probe{.index = index, .name = name};
        consider(&hit, columns, probe);
    }
    return hit;
}

} // namespace game::audio
