// Gói shader `.f2s`: một shader đã dịch cho mọi đích và mọi biến thể, kèm phản chiếu của từng bản
// và danh sách tệp nguồn nó phụ thuộc. Thay tệp nhị phân `@FSL` của _Ref (compilers.py ghi,
// ResourceLoader.cpp đọc): ở đó mỗi đích một thư mục tệp riêng, khoá của biến thể là số thứ tự (có
// TODO "nếu dùng hash thì phải khớp với C++"), không có phản chiếu, không có tổng kiểm, và bộ đọc
// tin mọi offset trong tệp. Ở đây khoá biến thể là băm của tập define, cả tệp có tổng kiểm XXH3,
// mọi offset được kiểm trước khi dùng, và bytecode nằm ở offset bội số 8 nên tầng đồ hoạ trỏ thẳng
// vào vùng nhớ của gói mà không chép (SPIR-V cần con trỏ căn 4 byte). Đặc tả byte ở
// docs/modules/shader.md.
// Nguồn: Forge2 src/shader/package.hpp@d7fcd76. Khác gốc: bỏ {} thừa ở thành viên string, vector,
// span và fs::Bytes.
#pragma once

#include "fs/stream.hpp"
#include "shader/reflection.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader {

// Khoá của biến thể không có define nào.
inline constexpr std::uint64_t kDefaultVariant = 0;

// Phần mở rộng của tệp gói, không có dấu chấm.
inline constexpr std::string_view kPackageExtension = "f2s";

// Dạng chuẩn của một tập define: bỏ trùng, sắp theo byte, nối bằng ';' ("FOG;SHADOW=2").
[[nodiscard]] std::string variant_text(std::span<const std::string> defines);

// Khoá của một tập define: kDefaultVariant cho tập rỗng, XXH3-64 của dạng chuẩn cho tập khác. Thứ
// tự viết define không đổi khoá.
[[nodiscard]] std::uint64_t variant_key(std::span<const std::string> defines);

// Một bản dịch trong gói.
struct Variant {
    Target target = Target::kDxil;
    std::uint64_t key = kDefaultVariant;
    // Dạng chuẩn của tập define đã dịch ra bản này.
    std::string defines;
    // Mượn vùng nhớ của Package; địa chỉ là bội số 8 và không đổi khi Package bị move.
    std::span<const std::byte> code;
    // XXH3-64 của code và của phản chiếu: khoá cache pipeline và layout cho tầng đồ hoạ.
    std::uint64_t code_hash = 0;
    StageReflection reflection{};
    std::uint64_t reflection_hash = 0;
};

// Một tệp nguồn mà gói được dịch từ đó, kèm XXH3-64 của nội dung lúc dịch.
struct Dependency {
    std::string path;
    std::uint64_t hash = 0;

    [[nodiscard]] bool operator==(const Dependency&) const = default;
};

class Package {
public:
    // Nhận quyền sở hữu bytes. Corrupt khi sai magic, phiên bản, tổng kiểm, hay một offset trỏ ra
    // ngoài tệp.
    [[nodiscard]] static Result<Package> parse(fs::Bytes bytes);
    // Đọc cả tệp rồi parse.
    [[nodiscard]] static Result<Package> load(std::string_view path);

    [[nodiscard]] std::string_view name() const noexcept { return name_; }
    [[nodiscard]] Stage stage() const noexcept { return stage_; }
    // Gói dịch ở chế độ gỡ lỗi (không tối ưu, kèm thông tin gỡ lỗi).
    [[nodiscard]] bool debug() const noexcept { return debug_; }
    // Băm của mọi thứ quyết định kết quả dịch ngoài nội dung tệp: trình dịch, tuỳ chọn, define.
    [[nodiscard]] std::uint64_t options_hash() const noexcept { return options_hash_; }
    [[nodiscard]] std::span<const Variant> variants() const noexcept { return variants_; }
    [[nodiscard]] std::span<const Dependency> dependencies() const noexcept { return dependencies_; }

    // Bản dịch cho target với khoá key; nullptr khi gói không có.
    [[nodiscard]] const Variant* find(Target target, std::uint64_t key = kDefaultVariant) const noexcept;

private:
    Package() = default;

    fs::Bytes bytes_;
    std::string name_;
    Stage stage_ = Stage::kVertex;
    bool debug_ = false;
    std::uint64_t options_hash_ = 0;
    std::vector<Variant> variants_;
    std::vector<Dependency> dependencies_;
};

// Đường dẫn tệp gói của shader name trong thư mục output. Nằm ở package (không ở builder) vì
// trình chạy chỉ đọc gói, không dịch: bản dựng cho thiết bị không có builder.cpp.
[[nodiscard]] std::string package_path(std::string_view output, std::string_view name);

// Một bản dịch đưa vào bộ ghi gói.
struct PackageVariant {
    Target target = Target::kDxil;
    std::vector<std::string> defines;
    std::vector<std::byte> code;
    StageReflection reflection{};
};

struct PackageSource {
    std::string name;
    Stage stage = Stage::kVertex;
    bool debug = false;
    std::uint64_t options_hash = 0;
    std::vector<PackageVariant> variants;
    std::vector<Dependency> dependencies;
};

// Dựng nội dung tệp gói. InvalidArgument khi không có bản dịch nào hoặc hai bản trùng (đích, khoá);
// Overflow khi gói vượt 4 GiB.
[[nodiscard]] Result<std::vector<std::byte>> write_package(const PackageSource& source);

} // namespace game::shader
