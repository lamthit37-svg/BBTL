// Trạng thái chung của bộ nạp giao diện (loader.cpp nạp tệp và cửa sổ, loader_look.cpp đổi look,
// kích thước, section thành mảng phẳng). Nội bộ module gui.
// Mỗi kiểu, look, section, ảnh và texture chỉ đổi một lần (chỉ mục theo tên). Look đổi vào vector
// cục bộ trước rồi mới nối vào asset, để khoảng của nó liền nhau dù lúc đổi có đệ quy sang look
// khác; kiểu và look được giữ chỗ trước khi đệ quy nên vòng tham chiếu không lặp vô hạn.
#pragma once

#include "gui/asset.hpp"
#include "gui/detail/name_map.hpp"
#include "gui/loader.hpp"
#include "xml/document.hpp"

#include <cstdint>
#include <deque>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

namespace game::gui::detail {

// Một phần tử XML cùng tài liệu chứa nó. Mượn tài liệu: sống tới khi Cook bị huỷ.
class Node {
public:
    Node(const xml::Document& document, std::uint32_t index) noexcept : document_(&document), index_(index) {}

    [[nodiscard]] const xml::Element& element() const { return document_->elements.at(index_); }
    [[nodiscard]] const std::string& name() const { return element().name; }
    // Giá trị thuộc tính; fallback khi không có.
    [[nodiscard]] std::string_view attr(std::string_view key, std::string_view fallback) const;
    // Phần tử con đầu tiên mang tên này.
    [[nodiscard]] std::optional<Node> first_child(std::string_view tag) const;
    [[nodiscard]] bool has_children() const { return !element().children.empty(); }
    // Các phần tử con theo thứ tự trong tệp.
    [[nodiscard]] auto children() const {
        const xml::Document* document = document_;
        const auto wrap = [document](std::uint32_t index) { return Node(*document, index); };
        return element().children | std::views::transform(wrap);
    }

private:
    const xml::Document* document_;
    std::uint32_t index_;
};

// FalagardMapping: kiểu cửa sổ sang bộ vẽ và look.
struct Mapping {
    std::string renderer;
    std::string look;
};

// Kiểu có look mà chưa dựng: chỉ số kiểu và tên look của nó.
struct PendingType {
    std::int32_t type = -1;
    std::string look;
};

struct Cook {
    GuiSources sources;
    GuiAsset asset;
    std::vector<std::string> notes;
    // Đường dẫn layout (chữ thường) đã nạp, để không nạp hai lần.
    std::vector<std::string> loaded;
    // deque: thêm tài liệu vào cuối không dời tài liệu đã có, nên Node trỏ vào chúng sống hết lượt.
    std::deque<xml::Document> files;
    NameMap<Mapping> mappings;
    NameMap<Node> look_xml;
    NameMap<Node> imageset_xml;
    NameMap<Node> animate_xml;
    NameMap<std::int32_t> animates;
    NameMap<std::int32_t> images;
    NameMap<std::int32_t> textures;
    NameMap<std::int32_t> sections;
    NameMap<std::int32_t> looks;
    NameMap<std::int32_t> types;
    // Các kiểu có look mà chưa dựng; settle_types dựng dần cho tới khi hết.
    std::vector<PendingType> pending;
};

void note(Cook& cook, std::string text);

[[nodiscard]] std::string lower(std::string_view text);

// Số thực của thuộc tính key; fallback khi vắng, 0 khi không đọc được.
[[nodiscard]] float number_attribute(const Node& node, std::string_view key, float fallback);

// Chỉ số ảnh (imageset, tên) trong asset; thêm lần đầu, -1 và một ghi chú khi không có.
[[nodiscard]] std::int32_t image_of(Cook& cook, std::string_view imageset, std::string_view name);

// Chỉ số kiểu cửa sổ; kiểu không có FalagardMapping là cửa sổ trơn, không look. Look của kiểu mới
// chưa dựng ngay: gọi settle_types sau khi đăng ký xong các kiểu.
[[nodiscard]] std::int32_t type_of(Cook& cook, std::string_view name);

// Dựng look của mọi kiểu đang chờ, kể cả kiểu mà look vừa dựng nhắc tới (Child), tới khi hết.
void settle_types(Cook& cook);

} // namespace game::gui::detail
