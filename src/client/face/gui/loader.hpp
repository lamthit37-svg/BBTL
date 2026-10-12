// Nạp giao diện gốc của client 2026 thẳng từ XML lúc chạy (chưa nấu): scheme (FalagardMapping: kiểu
// cửa sổ sang bộ vẽ và look), mọi looknfeel, các imageset và layout của từng cửa sổ, theo CEGUI
// 0.4.1 cùng Falagard của _ref (Falagard_xmlHandler, Imageset_xmlHandler, GUILayout_xmlHandler).
// Chỉ đưa vào GuiAsset những kiểu, look, section, ảnh, hoạt ảnh và texture mà các cửa sổ đã nạp
// dùng tới (bắc cầu qua Section của look khác và Child của look). Tham chiếu hỏng (ảnh, section,
// kiểu không có) không làm hỏng cả lượt: bỏ phần đó và ghi một dòng vào notes. GuiLoader giữ cây
// XML của scheme, looknfeel và imageset (nạp một lần) để thêm layout về sau như client gốc nạp cửa
// sổ khi cần; asset() đổi sau mỗi lần thêm nên Hub phải dựng lại. Nguồn: TLBB Dev
// tools/bake/gui_cook.hpp và gui_cook.cpp@e0d89a6 (nấu offline ra .tlgui). Khác gốc: chạy lúc nạp
// thay vì nấu trước; đường dẫn là tên gốc của kho Interface (tra không phân biệt hoa thường) thay
// cho tên sạch và manifest; nhận danh sách layout theo đường dẫn tệp thay cho tên cửa sổ; nạp thêm
// layout từng lần.
#pragma once

#include "gui/asset.hpp"

#include <expected>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::gui {

// Nguồn tệp văn bản theo đường dẫn tương đối với thư mục Interface (dấu /, hoa thường tuỳ ý). Đĩa
// cho client, bộ nhớ cho test.
class FileSource {
public:
    FileSource() = default;
    FileSource(const FileSource&) = delete;
    FileSource& operator=(const FileSource&) = delete;
    FileSource(FileSource&&) = delete;
    FileSource& operator=(FileSource&&) = delete;
    virtual ~FileSource() = default;

    // Trọn nội dung tệp; nullopt khi không có hay không đọc được.
    [[nodiscard]] virtual std::optional<std::string> read(std::string_view path) const = 0;
};

// Đọc từ một thư mục trên đĩa (dev/client/assets/Interface).
// phone: layout .xml có bản trong phone/ thì dùng bản đó, Android và iOS chung một thư mục.
class DiskSource final : public FileSource {
public:
    explicit DiskSource(std::filesystem::path root, bool phone = false) : root_(std::move(root)), phone_(phone) {}

    [[nodiscard]] std::optional<std::string> read(std::string_view path) const override;

private:
    std::filesystem::path root_;
    bool phone_ = false;
};

struct GuiSources {
    // Phải sống lâu hơn GuiLoader dùng nó.
    const FileSource* files = nullptr;
    // Scheme và tệp gộp mọi imageset.
    std::string scheme = "Schema/WoWLookSkin.scheme.xml";
    std::string imagesets = "Schema/all.imageset.xml";
    // Bảng hoạt ảnh của AnimateManager; không có tệp thì giao diện không có hoạt ảnh.
    std::string animates = "Schema/wowanimate.xml";
};

class GuiLoader {
public:
    // Nạp scheme, mọi looknfeel nó kê, các imageset và bảng hoạt ảnh. Lỗi là một câu tiếng Việt:
    // thiếu scheme hay imageset, hay XML hỏng.
    [[nodiscard]] static std::expected<GuiLoader, std::string> open(const GuiSources& sources);

    GuiLoader(GuiLoader&&) noexcept;
    GuiLoader& operator=(GuiLoader&&) noexcept;
    GuiLoader(const GuiLoader&) = delete;
    GuiLoader& operator=(const GuiLoader&) = delete;
    ~GuiLoader();

    // Thêm các cửa sổ của một layout (đường dẫn như "PlayerFrame/PlayerFrame.layout.xml"). Lỗi là
    // thiếu tệp hay XML hỏng; layout nạp rồi thì không thêm lần nữa.
    [[nodiscard]] std::expected<void, std::string> add_layout(std::string_view path);

    // Đưa trọn một imageset vào dù layout không nhắc: ảnh mà mã gán lúc chạy, như nền màn đăng
    // nhập.
    void add_imageset(std::string_view name);

    [[nodiscard]] const GuiAsset& asset() const noexcept;
    // Mọi tham chiếu hỏng gặp từ lúc mở.
    [[nodiscard]] std::span<const std::string> notes() const noexcept;

private:
    struct State;
    explicit GuiLoader(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::gui
