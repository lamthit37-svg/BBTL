// Bộ dựng: dịch các shader của một danh sách thành gói `.f2s`, chỉ dịch lại gói đã cũ. Thay phần
// điều phối của fsl.py (_Ref): ở đó "cũ hay mới" là so thời điểm sửa tệp với một tệp .deps do mcpp
// ghi, song song bằng multiprocessing, và lỗi của một shader dừng cả lượt. Ở đây gói tự mang băm
// nội dung của từng tệp nó phụ thuộc cùng băm của mọi tuỳ chọn dịch, nên chép cây nguồn sang máy
// khác, đổi nhánh git hay chạm tệp mà không đổi nội dung đều không gây dịch lại; đổi trình dịch,
// define hay cờ thì dịch lại đúng những gói bị ảnh hưởng. Các shader dịch song song trên JobSystem,
// mỗi shader một kết quả riêng. Wicked cũng so thời điểm sửa tệp (IsShaderOutdated).
// Nguồn: Forge2 src/shader/builder.hpp@d7fcd76. Khác gốc: bỏ {} thừa ở thành viên string và vector
// của các struct.
#pragma once

#include "shader/compiler.hpp"
#include "shader/manifest.hpp"
#include "shader/package.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::jobs {
class JobSystem;
}

namespace game::shader {

struct BuildOptions {
    // Thư mục nhận các gói; tạo nếu chưa có.
    std::string output;
    std::vector<Target> targets{Target::kDxil, Target::kSpirV};
    bool debug = false;
    // Dịch lại cả gói còn mới.
    bool force = false;
    std::uint8_t vulkan_minor = 3;
};

enum class Outcome : std::uint8_t {
    kBuilt,
    // Gói trên đĩa còn khớp nguồn và tuỳ chọn; không dịch.
    kFresh,
    kFailed,
};

struct BuildResult {
    std::string name;
    Outcome outcome = Outcome::kFailed;
    // Lỗi khi Failed; cảnh báo của DXC khi Built.
    std::string messages;
};

struct BuildReport {
    // Một kết quả cho mỗi shader, theo thứ tự của danh sách.
    std::vector<BuildResult> results;

    [[nodiscard]] std::size_t count(Outcome outcome) const noexcept;
    [[nodiscard]] bool succeeded() const noexcept { return count(Outcome::kFailed) == 0; }
};

// Một gói đã dựng trong bộ nhớ.
struct Packed {
    std::vector<std::byte> bytes;
    // Cảnh báo của DXC, gộp của mọi bản dịch.
    std::string messages;
};

// Dịch mọi biến thể của spec cho mọi đích và dựng nội dung gói; không ghi đĩa.
[[nodiscard]] Result<Packed> pack(const Compiler& compiler, const Manifest& manifest,
    const ShaderSpec& spec, const BuildOptions& options);

// Gói của spec trên đĩa có còn khớp không: cùng trình dịch, tuỳ chọn, define, và mọi tệp nó phụ
// thuộc còn nguyên nội dung.
[[nodiscard]] bool is_fresh(const Compiler& compiler, const Manifest& manifest,
    const ShaderSpec& spec, const BuildOptions& options);

// Dựng một shader: bỏ qua nếu còn mới, không thì dịch rồi ghi gói bằng một lần thay tệp nguyên tử.
[[nodiscard]] BuildResult build_shader(const Compiler& compiler, const Manifest& manifest,
    const ShaderSpec& spec, const BuildOptions& options);

// Dựng cả danh sách. jobs khác null thì các shader dịch song song và luồng gọi cùng làm; null thì
// tuần tự.
[[nodiscard]] BuildReport build(const Compiler& compiler, const Manifest& manifest,
    const BuildOptions& options, jobs::JobSystem* jobs = nullptr);

} // namespace game::shader
