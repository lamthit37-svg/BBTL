// Đọc XML thành cây phần tử, đủ cho các tệp văn bản của client Thiên Long Bát Bộ (.Scene, .Terrain,
// .model, layout giao diện): khai báo <?xml?>, chú thích, phần tử có thuộc tính, phần tử tự đóng,
// chữ nằm trong phần tử, thực thể &lt; &gt; &amp; &quot; &apos; &#N; &#xH;.
// Quyết định:
// - Tệp là dữ liệu ngoài: mọi lỗi cú pháp trả về kèm vị trí byte, không dừng tiến trình; độ sâu có
//   trần để tệp hỏng không làm tràn bộ nhớ.
// - Cây lưu phẳng trong một vector, phần tử con trỏ nhau bằng chỉ số, nên Document chép và dời được
//   mà không có tham chiếu treo. Tên và giá trị là chuỗi sở hữu, không trỏ vào văn bản nguồn.
// - Không hỗ trợ DTD và CDATA (kho gốc không dùng); gặp thì báo lỗi.
// - Không đổi bảng mã: văn bản vào là UTF-8 thì chuỗi ra là UTF-8.
#pragma once

#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::xml {

struct Attribute {
    std::string name;
    std::string value;
};

struct Element {
    std::string name;
    std::vector<Attribute> attributes;
    // Chỉ số của các phần tử con trong Document::elements, theo thứ tự trong tệp.
    std::vector<std::uint32_t> children;
    // Chữ nằm trực tiếp trong phần tử, đã giải thực thể, bỏ khoảng trắng hai đầu từng đoạn.
    std::string text;
};

struct Document {
    // Phần tử gốc ở chỉ số 0; parse không bao giờ trả về tài liệu rỗng.
    std::vector<Element> elements;
};

enum class [[nodiscard]] XmlError : std::uint8_t {
    kTruncated,
    kBadSyntax,
    kBadEntity,
    kMismatchedClose,
    kTooDeep,
    kNoRoot,
    kUnsupported,
};

struct Fault {
    XmlError error = XmlError::kBadSyntax;
    // Vị trí byte trong văn bản nguồn nơi phát hiện lỗi.
    std::size_t offset = 0;
};

using ParseResult = std::expected<Document, Fault>;
using OptionalText = std::optional<std::string_view>;

// Cây phần tử của văn bản XML.
[[nodiscard]] ParseResult parse(std::string_view source);

// Giá trị của thuộc tính mang tên này; view sống cùng element.
[[nodiscard]] OptionalText attribute(const Element& element, std::string_view name) noexcept;

} // namespace game::xml
