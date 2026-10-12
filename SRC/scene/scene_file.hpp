// Đọc tệp .Scene của client Thiên Long Bát Bộ (XML UTF-8 của trình sửa cảnh Fairy): tên địa hình
// và danh sách vật thể, mỗi vật thể một kiểu (StaticEntity, Model, Light, Enviroment...) cùng các
// thuộc tính dạng tên và giá trị chữ, giữ nguyên như trong tệp.
// Nguồn định dạng: WXSceneSerializer.cpp của client 2008 (G:\TLBB\_ref) và thống kê trên 513 cảnh
// của bản 3.71. Quyết định:
// - Giá trị thuộc tính không được diễn giải ở đây; đổi sang số là việc của placement.hpp và của
//   từng nơi dùng, để tệp đọc ra không mất gì.
// - Vật thể nằm trong <Group> được trải phẳng theo đúng thứ tự trong tệp: Group của bản 3.71 chỉ có
//   tên, không mang phép biến đổi, và toạ độ của vật thể bên trong đã là toạ độ thế giới (đã đo).
// - Phần tử lạ ở gốc (Author, MovieData...) bị bỏ qua, không phải lỗi. SkySphere chỉ giữ
//   tên tệp .skysphere; nội dung bầu trời đọc ở client/stage.
#pragma once

#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::scene {

struct Property {
    std::string name;
    std::string value;
};

struct Object {
    std::string type;
    // Tên riêng của vật thể; rỗng khi tệp không đặt.
    std::string name;
    std::vector<Property> properties;
};

struct SceneFile {
    std::string name;
    // Tên tệp .Terrain đi kèm, tương đối với thư mục của tệp cảnh; rỗng khi cảnh không có địa hình.
    std::string terrain_file;
    // Tên tệp .skysphere, cùng thư mục với tệp cảnh. Rỗng khi cảnh không có bầu trời.
    std::string sky_file;
    std::vector<Object> objects;
};

enum class [[nodiscard]] SceneError : std::uint8_t { kBadXml, kNotScene };

using SceneResult = std::expected<SceneFile, SceneError>;
using OptionalText = std::optional<std::string_view>;

// Nội dung của một tệp .Scene.
[[nodiscard]] SceneResult read_scene(std::string_view text);

// Giá trị của thuộc tính mang tên này; view sống cùng object.
[[nodiscard]] OptionalText property(const Object& object, std::string_view name) noexcept;

} // namespace game::scene
