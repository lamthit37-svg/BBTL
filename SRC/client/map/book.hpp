// Danh sách map của client gốc (Config/SceneDefineEx.txt). Cả tệp nằm một khối. Mỗi map chỉ
// giữ resid, kích thước và vị trí chữ trong khối đó — không cấp phát chuỗi riêng. Dòng '#' bỏ.
// Tìm resid bằng tìm nhị phân. Vào map chỉ đọc đúng một file .Scene.
#pragma once

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::client::map {

enum class [[nodiscard]] BookError : std::uint8_t {
    kBadTable,
    kUnknownScene,
};

// Mặt cắt xa và gần của camera khi dòng không ghi, như hàm dựng CScene của client 2026 (Game.exe
// 0x1406c2130).
inline constexpr int kDefaultFarClip = 15000;
inline constexpr int kDefaultNearClip = 10;

// Một map. name, file, path và radar là độ lệch vào Book::text, không phải bộ nhớ riêng. radar là cột
// szSceneMap (cột thứ 11): token tên ảnh minimap của cảnh, rỗng khi dòng thiếu cột đó. far_clip và
// near_clip là cột thứ 16 và 17: mặt cắt của camera cảnh, đơn vị thế giới (CScene::Initial,
// Game.exe 0x1406bfaff); dòng thiếu cột, số không dương, hay gần không nhỏ hơn xa thì lấy mặc
// định.
struct SceneRef {
    int id = 0;
    int x_size = 0;
    int z_size = 0;
    int far_clip = kDefaultFarClip;
    int near_clip = kDefaultNearClip;
    std::uint32_t name_at = 0;
    std::uint32_t file_at = 0;
    std::uint32_t radar_at = 0;
    // Cột thứ 6: tên tệp lưới đi (.path) nằm cạnh tệp cảnh; độ dài 0 khi dòng thiếu cột hay ô không
    // phải tên tệp trần.
    std::uint32_t path_at = 0;
    std::uint16_t name_len = 0;
    std::uint16_t file_len = 0;
    std::uint16_t radar_len = 0;
    std::uint16_t path_len = 0;
};

struct Book {
    std::string text;
    // Tăng dần theo id. resid trùng thì giữ dòng gặp trước.
    std::vector<SceneRef> rows;
};

using BookResult = std::expected<Book, BookError>;

// `text` là cả tệp UTF-8, cột cách nhau bằng tab. Không có dòng dùng được thì kBadTable.
[[nodiscard]] BookResult read_book(std::string_view text);

[[nodiscard]] std::string_view name_of(const Book& book, const SceneRef& row) noexcept;

[[nodiscard]] std::string_view file_of(const Book& book, const SceneRef& row) noexcept;

// Token ảnh minimap (szSceneMap); rỗng khi bảng không có.
[[nodiscard]] std::string_view radar_of(const Book& book, const SceneRef& row) noexcept;

// Tên tệp lưới đi (.path) của cảnh; rỗng khi bảng không có.
[[nodiscard]] std::string_view path_of(const Book& book, const SceneRef& row) noexcept;

[[nodiscard]] const SceneRef* find_id(const Book& book, int id) noexcept;

// Khớp tên file hoặc tên không đuôi, không phân biệt hoa thường của chữ Latin.
[[nodiscard]] const SceneRef* find_scene(const Book& book, std::string_view name) noexcept;

[[nodiscard]] std::string_view describe(BookError error) noexcept;

} // namespace game::client::map
