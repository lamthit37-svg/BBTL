// Cầu nối tới Slang (slang.dll): dịch một nguồn .slang ra SPIR-V, DXIL hoặc DXBC trong tiến trình.
// Slang thay DXC làm trình dịch nguồn (DXC chỉ còn lấy phản chiếu của DXIL, shader/compiler.cpp) và
// thay D3DCompile của đích DXBC: cùng một nguồn, cùng một bộ cờ, ba đích. DLL nạp lúc chạy.
// Slang không an toàn luồng khi dùng chung một session, nên mỗi lần dịch tạo session riêng trên
// một global session dùng chung và các lần dịch nối đuôi nhau (một mutex): bộ dựng chạy một lần
// rồi cache theo băm nội dung, nên song song hoá không đáng.
// Nguồn: tệp mới của THIENLONG. Khác gốc: Forge2 không dùng Slang.
#pragma once

#include "shader/compiler.hpp"

#include <cstddef>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader::detail {

struct SlangSource {
    std::string_view path;
    std::string_view text;
};

struct Translated {
    // SPIR-V, DXIL (container đã ký) hoặc DXBC.
    std::vector<std::byte> code;
    // Báo của Slang nguyên văn (cảnh báo khi dịch được); rỗng khi không có.
    std::string messages;
    // Mọi tệp include, đường dẫn đã chuẩn hoá, theo thứ tự gặp, không lặp. Không gồm tệp nguồn và
    // phần dùng chung sẵn có (shader/builtin.hpp).
    std::vector<std::string> dependencies;
};

class SlangCompiler {
public:
    // Unsupported khi không tìm thấy slang.dll hoặc DLL không dựng được global session.
    [[nodiscard]] static Result<SlangCompiler> create();

    SlangCompiler(SlangCompiler&&) noexcept;
    SlangCompiler& operator=(SlangCompiler&&) noexcept;
    SlangCompiler(const SlangCompiler&) = delete;
    SlangCompiler& operator=(const SlangCompiler&) = delete;
    ~SlangCompiler();

    // InvalidArgument kèm báo của Slang khi nguồn sai; Unsupported cho Stage::kLibrary và Target::kGlsl
    // (GLSL của GLES viết tay, shader/builder.cpp).
    [[nodiscard]] Result<Translated> translate(const SlangSource& source, const CompileOptions& options) const;

    // "slang 2026.17-25-gc7954ebd1"; đi vào khoá kiểm cũ mới của gói.
    [[nodiscard]] std::string_view version() const noexcept;
    // Đường dẫn DLL đã nạp.
    [[nodiscard]] std::string_view library() const noexcept;

private:
    struct State;

    explicit SlangCompiler(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::shader::detail
