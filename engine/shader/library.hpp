// Kho gói shader lúc chạy, kèm nạp nóng. Thay hai thứ của _Ref: phần nạp bytecode trong
// ResourceLoader.cpp (đọc tệp `@FSL` theo tên, không giữ lại) và ReloadServer — một tiến trình
// Python trên máy dev nhận yêu cầu qua TCP, gọi lại fsl.py rồi gửi bytecode về thiết bị, vì thiết
// bị không tự dịch được. Trên Windows Slang nằm ngay trong tiến trình, nên nạp nóng ở đây là: theo
// dõi thư mục nguồn (fs::Watcher), tới điểm an toàn của khung hình thì dịch lại đúng những gói có
// nguồn đổi nội dung, thay gói đang giữ, và báo tên các gói đã đổi để tầng đồ hoạ dựng lại
// pipeline. Lỗi dịch vào log và gói cũ ở lại, nên gõ sai một dòng không làm ứng dụng mất shader.
// Dịch cho thiết bị không tự dịch được (Android, iOS) chưa có; ghi ở docs/NGHI-NGO.md.
// Nguồn: Forge2 src/shader/library.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "shader/builder.hpp"

#include <chrono>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader {

// Mọi hàm của một Library gọi từ cùng một luồng; luồng theo dõi tệp chỉ dựng một cờ có khoá riêng.
class Library {
public:
    // Khoảng lặng sau thay đổi cuối trước khi dịch lại: trình soạn thảo ghi một tệp qua vài bước.
    static constexpr std::chrono::milliseconds kSettle{100};

    // directory chứa các tệp gói `.f2s`. NotFound khi không có thư mục ấy.
    [[nodiscard]] static Result<Library> open(std::string_view directory);

    Library(Library&&) noexcept;
    Library& operator=(Library&&) noexcept;
    Library(const Library&) = delete;
    Library& operator=(const Library&) = delete;
    ~Library();

    // Gói tên name ("sky.ps"): đọc từ đĩa lần đầu, sau đó trả bản đang giữ. Sở hữu chung vì khi
    // nạp nóng thay gói, nơi đang dùng gói cũ vẫn giữ được nó tới lúc dựng xong pipeline mới.
    [[nodiscard]] Result<std::shared_ptr<const Package>> get(std::string_view name);

    // Nhận nội dung một gói dựng ở nơi khác — máy dev đẩy sang thiết bị không tự dịch được — rồi
    // thay gói cùng tên đang giữ. Trả tên gói; Corrupt khi nội dung hỏng. Không ghi gì xuống đĩa.
    [[nodiscard]] Result<std::string> install(fs::Bytes bytes);

    // Bật nạp nóng cho danh sách ở manifest_path: theo dõi thư mục của danh sách và các thư mục
    // include. options.output bị thay bằng thư mục của kho. Lần refresh đầu dịch mọi gói đã cũ.
    [[nodiscard]] Status watch(std::string_view manifest_path, Compiler compiler, BuildOptions options);

    [[nodiscard]] bool watching() const noexcept;

    // Gọi mỗi khung ở điểm an toàn. Khi nguồn đã đổi và đã yên kSettle: đọc lại danh sách, dịch
    // lại gói đã cũ, thay gói đang giữ. Trả tên các gói vừa thay; rỗng khi không có gì đổi.
    [[nodiscard]] std::vector<std::string> refresh();

private:
    struct State;

    explicit Library(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::shader
