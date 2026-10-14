// Trình dịch shader: bọc Slang (slang.dll) để dịch một nguồn .slang ra SPIR-V, DXIL hoặc DXBC kèm
// phản chiếu và danh sách tệp phụ thuộc; DXC (dxcompiler.dll) chỉ đọc phản chiếu của DXIL. Thay
// compilers.py cùng ba bộ sinh của FSL (_Ref): ở đó mỗi lần dịch là một tiến trình mcpp rồi một
// tiến trình dxc hay glslangValidator, lỗi dò bằng cách tách chuỗi stdout. Ở đây hai DLL nạp một lần
// trong tiến trình qua giao diện COM, lỗi và cảnh báo trả nguyên văn. DLL nạp lúc chạy nên module
// không phụ thuộc chúng lúc link: thiếu DLL thì create() trả Unsupported, còn gói đã dịch sẵn vẫn
// đọc được (shader/package.hpp).
// Nguồn: Forge2 src/shader/compiler.hpp@d7fcd76. Khác gốc: bỏ {} thừa ở thành viên string và
// vector của các struct; nguồn là Slang, đích thêm DXBC, bỏ Stage::kLibrary.
#pragma once

#include "shader/reflection.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader {

struct CompileOptions {
    Stage stage = Stage::kVertex;
    Target target = Target::kDxil;
    std::string entry = "main";
    // Mức thấp hơn mức stage cần (mesh và amplification 6.5) được tự nâng lên.
    ShaderModel model{};
    // "TÊN" hoặc "TÊN=GIÁ_TRỊ".
    std::vector<std::string> defines;
    std::vector<std::string> include_dirs;
    // Tắt tối ưu, nhúng thông tin gỡ lỗi, định nghĩa F2_DEBUG.
    bool debug = false;
    // Hiến pháp I.3: cảnh báo là lỗi.
    bool strict = true;
    // Môi trường đích của SPIR-V: vulkan1.<vulkan_minor>.
    std::uint8_t vulkan_minor = 3;
};

struct Compiled {
    // SPIR-V, DXIL (container đã ký) hoặc DXBC.
    std::vector<std::byte> code;
    // Phản chiếu chung của cả ba đích (shader/detail/reconcile.hpp).
    StageReflection reflection{};
    // Nguồn rồi tới mọi tệp nó include, đường dẫn đã chuẩn hoá, theo thứ tự gặp, không lặp. Phần
    // dùng chung sẵn có (shader/builtin.hpp) không tính.
    std::vector<std::string> dependencies;
    // Cảnh báo của Slang, nguyên văn; rỗng khi không có.
    std::string messages;
};

struct CompilerConfig {
    // Đường dẫn đầy đủ của dxcompiler.dll (đọc phản chiếu DXIL). Rỗng: tìm cạnh exe rồi tới
    // %VULKAN_SDK%\Bin. Không bao giờ tìm theo PATH: nạp DLL theo tên trần là cửa cho DLL lạ.
    std::string library;
};

struct MemorySource {
    std::string_view path;
    std::string_view text;
};

class Compiler {
public:
    // Unsupported khi không tìm thấy slang.dll hay dxcompiler.dll, hoặc DLL không có hàm khởi tạo.
    [[nodiscard]] static Result<Compiler> create(const CompilerConfig& config = {});

    Compiler(Compiler&&) noexcept;
    Compiler& operator=(Compiler&&) noexcept;
    Compiler(const Compiler&) = delete;
    Compiler& operator=(const Compiler&) = delete;
    ~Compiler();

    // Dịch tệp path. Nhiều luồng gọi cùng lúc được: Slang nối đuôi các lần dịch, DXC tạo đối tượng
    // riêng. InvalidArgument kèm thông điệp của Slang khi nguồn sai; NotFound khi không có tệp;
    // Internal khi SPIR-V và DXIL của cùng nguồn lệch bố cục; InvalidArgument cho Target::kGlsl (GLSL
    // của GLES viết tay, shader/builder.cpp).
    [[nodiscard]] Result<Compiled> compile(std::string_view path, const CompileOptions& options) const;

    // Dịch text có sẵn trong bộ nhớ; path chỉ dùng trong thông điệp lỗi và làm gốc cho #include
    // tương đối.
    [[nodiscard]] Result<Compiled> compile(std::string_view path, std::string_view text,
        const CompileOptions& options) const;
    [[nodiscard]] Result<Compiled> compile(const MemorySource& source, const CompileOptions& options) const;

    // "slang 2026.17-25-gc7954ebd1; dxc 1.9.5512 (01b62ad4); quy trình 2"; đi vào khoá kiểm cũ mới
    // của gói.
    [[nodiscard]] std::string_view version() const noexcept;
    // Đường dẫn dxcompiler.dll đã nạp.
    [[nodiscard]] std::string_view library() const noexcept;

private:
    struct State;

    explicit Compiler(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::shader
