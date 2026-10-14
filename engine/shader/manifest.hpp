// Danh sách shader của một thư mục: tệp chữ khai mỗi gói dịch từ nguồn nào, stage nào, với những
// define và biến thể nào. Thay ShaderList.fsl của _Ref, vốn là một tệp FSL có `#frag tên`,
// `#include` và `#end` mà fsl.py tách bằng cách dò từng dòng rồi đưa cả tệp qua mcpp một lần cho
// mỗi shader. Ở đây mỗi dòng là một lệnh, tên lạ hay khoá lạ là lỗi kèm số dòng chứ không bị bỏ
// qua:
//   include ../common — thư mục tìm #include, tính từ thư mục của danh sách
//   define QUALITY=2 — define cho mọi shader
//   model 6.6 — shader model mặc định
//   shader sky.ps sky.slang entry=sky_main variant=FOG variant=FOG,SHADOW permute=A,B
// Stage lấy từ khoá stage=, không có thì từ đuôi của tên gói ("sky.ps") hoặc của nguồn
// ("sky.ps.slang"). Mã thông báo có khoảng trắng thì bọc trong dấu nháy kép; `#` mở chú thích.
// Nguồn: Forge2 src/shader/manifest.hpp@d7fcd76. Khác gốc: bỏ {} thừa ở thành viên string, vector
// và optional của các struct.
#pragma once

#include "shader/types.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader {

// Số biến thể tối đa của một shader, kể cả biến thể mặc định; permute nhận tối đa 6 define.
inline constexpr std::size_t kMaxVariants = 64;

struct ShaderSpec {
    // Tên gói, cũng là tên tệp ra khi thêm đuôi .f2s: chỉ chữ, số, '.', '_', '-'.
    std::string name;
    // Đường dẫn nguồn đã ghép với thư mục của danh sách.
    std::string source;
    Stage stage = Stage::kVertex;
    std::string entry = "main";
    // nullopt: dùng model của danh sách.
    std::optional<ShaderModel> model;
    // Define riêng của shader này, áp cho mọi biến thể.
    std::vector<std::string> defines;
    // Tập define của từng biến thể; phần tử đầu luôn là tập rỗng (biến thể mặc định).
    std::vector<std::vector<std::string>> variants;
    // Dòng khai trong danh sách, để báo lỗi.
    std::uint32_t line = 0;
};

struct Manifest {
    // Thư mục chứa danh sách; đường dẫn tương đối trong danh sách tính từ đây.
    std::string directory;
    std::vector<std::string> include_dirs;
    std::vector<std::string> defines;
    ShaderModel model{};
    std::vector<ShaderSpec> shaders;

    // InvalidArgument kèm số dòng khi một dòng sai.
    [[nodiscard]] static Result<Manifest> parse(std::string_view text, std::string_view directory);
    // Đọc tệp path; thư mục của danh sách là thư mục chứa path.
    [[nodiscard]] static Result<Manifest> load(std::string_view path);

    [[nodiscard]] const ShaderSpec* find(std::string_view name) const noexcept;
};

} // namespace game::shader
