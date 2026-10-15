// Bảng biến toàn cục của client (CVariableSystem của Game.exe 9001, bản 3.71.9509 cùng hành vi): tên chuỗi, giá trị chuỗi. Script đọc
// và ghi qua Variable:GetVariable / Variable:SetVariable (tầng B của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-B.md). Thuần dữ liệu và
// luật, không Lua; dựng được ở mọi nền tảng.
//
// Địa chỉ mã máy: GetVariable là ô ảo 33 của CVariableSystem (0x1406aec60), SetVariable ô ảo 15 (0x1406aeda0); hai hàm Lua bọc chúng
// ở 0x1406b0990 và 0x1406b0870. Bảng gốc có sẵn nhiều biến mặc định nạp từ cấu hình lúc khởi động; ở đây bắt đầu rỗng
// (Khác gốc: chưa nạp bảng biến mặc định, nên GetVariable của biến chưa ai ghi trả không có thay vì giá trị mặc định của gốc).
#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::script {

// Giá trị phải ngắn hơn số này (0x1450 byte, đã tính byte NUL cuối của bộ đệm gốc); dài hơn thì SetVariable bỏ qua (gốc ghi một dòng log).
inline constexpr std::size_t kVariableValueLimit = 0x1450;
// Khác gốc: gốc không có trần số biến và độ dài tên; script lặp vô hạn trong trần lệnh vẫn tạo được hàng triệu biến. Quá trần thì bỏ như giá trị quá dài.
inline constexpr std::size_t kVariableCountLimit = 4096;
inline constexpr std::size_t kVariableNameLimit = 255;

// Sự kiện VARIABLE_CHANGED (id 0x13c) mà SetVariable phát khi giá trị đổi: đối số là tên rồi giá trị mới.
struct VariableChange {
    std::string name;
    std::string value;
};

class VariableSystem {
public:
    // Giá trị của biến; nullopt khi chưa có biến tên đó (khác biến có giá trị rỗng).
    [[nodiscard]] std::optional<std::string_view> get(std::string_view name) const;

    // Giá trị số nguyên của biến như ô ảo 22 của CVariableSystem (Game.exe 0x1406af810): atoi(giá trị), 0 khi chưa có biến. atoi của MSVC bỏ
    // khoảng trắng đầu, nhận dấu, đọc chữ số liền nhau, dừng ở ký tự đầu không phải số và kẹp ở biên int32 khi tràn.
    [[nodiscard]] std::int32_t get_int(std::string_view name) const;

    // Ghi biến, tạo nếu chưa có (biến mới có giá trị cũ là chuỗi rỗng, nên ghi chuỗi rỗng lên biến mới tạo biến mà không phát sự kiện).
    // Tên rỗng, tên quá dài, giá trị quá dài hay bảng đầy: bỏ qua. Trả sự kiện khi giá trị khác giá trị cũ, trừ biến View_DefaultCamera*
    // và View_FOV* (gốc chỉ phát chúng khi cờ DAT_14103e750 bật; chưa rõ cờ đó, coi như tắt).
    // noexcept: chạy dưới hàm C mà Lua gọi nên ngoại lệ C++ không được thoát; cấp phát thất bại (tối đa kVariableCountLimit biến,
    // mỗi biến dưới kVariableValueLimit byte) thì dừng tiến trình.
    [[nodiscard]] std::optional<VariableChange> set(std::string_view name, std::string_view value) noexcept;

    [[nodiscard]] std::size_t size() const noexcept { return values_.size(); }

private:
    std::map<std::string, std::string, std::less<>> values_;
};

} // namespace game::ui::script
