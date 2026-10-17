/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/compiler.cpp
 *  PHÂN HỆ   : Shader / Compiler
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trình dịch shader: Slang dịch nguồn .slang ra SPIR-V, DXIL và DXBC
 *    (shader/detail/slang.cpp). DXC chỉ còn lấy phản chiếu của DXIL:
 *    IDxcUtils::CreateReflection đọc phần STAT của container DXIL mà Slang sinh
 *    ra.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mỗi lần dịch, bất kể đích nào, đều dịch cả SPIR-V lẫn DXIL của cùng nguồn rồi đối chiếu phản
// chiếu của chúng (shader/detail/reconcile.cpp): SPIR-V cho tên sạch và bố cục descriptor của
// Vulkan, DXIL cho semantic và bố cục của D3D12. Hai bên lệch nhau thì dừng ở đây, nên ba đích của
// một gói luôn ra cùng một phản chiếu. DXBC lấy phản chiếu chung đó vì bytecode shader model 5
// không mang đủ thông tin cho bố cục của dự án.

#include "shader/compiler.hpp"

#include "core/text.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"
#include "shader/detail/library.hpp"
#include "shader/detail/reconcile.hpp"
#include "shader/detail/slang.hpp"
#include "shader/dxil.hpp"
#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/spirv.hpp"
#include "shader/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <filesystem>
#include <format>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d12shader.h>
#include <dxcapi.h>
#include <guiddef.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

namespace game::shader {

using PathView = std::string_view;
using CompileRef = const CompileOptions&;

namespace {

using Microsoft::WRL::ComPtr;

// Số hiệu của quy trình dịch trong tệp này và reconcile.cpp. Phiên bản Slang và DXC đã nằm trong
// khoá cache của gói, nhưng cách ghép phản chiếu thì không: đổi cách ghép mà không tăng số này thì
// gói cũ vẫn "còn mới" và mang phản chiếu của quy trình trước.
constexpr int kPipeline = 2;

using Utils = IDxcUtils;
using StageResult = Result<StageReflection>;

// Chuỗi uuid trong dxcapi.h và d3d12shader.h. DXC không phát hằng IID_*, chỉ __declspec(uuid).
constexpr GUID kIidUtils{
    .Data1 = 0x4605C4CB, .Data2 = 0x2019, .Data3 = 0x492A, .Data4 = {0xAD, 0xA4, 0x65, 0xF2, 0x0B, 0xB7, 0xD6, 0x7F}};
constexpr GUID kIidCompiler3{
    .Data1 = 0x228B4687, .Data2 = 0x5A6A, .Data3 = 0x4730, .Data4 = {0x90, 0x0C, 0x97, 0x02, 0xB2, 0x20, 0x3F, 0x54}};
constexpr GUID kIidVersion2{
    .Data1 = 0xFB6904C4, .Data2 = 0x42F0, .Data3 = 0x4B62, .Data4 = {0x9C, 0x46, 0x98, 0x3A, 0xF7, 0xDA, 0x7C, 0x83}};
constexpr GUID kIidShader{
    .Data1 = 0x5A58797D, .Data2 = 0xA72C, .Data3 = 0x478D, .Data4 = {0x8B, 0xA2, 0xEF, 0xC6, 0xB0, 0xEF, 0xE8, 0x8E}};

template <typename T>
[[nodiscard]] void** dxc_pp(Microsoft::WRL::ComPtr<T>& slot) noexcept {
    // T** không đổi được sang void** bằng static_cast. Đây là biên COM.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return reinterpret_cast<void**>(slot.GetAddressOf());
}

// Phản chiếu DXIL từ chính container mà Slang trả về.
[[nodiscard]] StageResult reflect_dxil_code(Utils& utils, std::span<const std::byte> code, const CompileOptions& options) {
    const DxcBuffer buffer{.Ptr = code.data(), .Size = code.size(), .Encoding = DXC_CP_ACP};
    ComPtr<ID3D12ShaderReflection> shader;
    const HRESULT made = utils.CreateReflection(&buffer, kIidShader, dxc_pp(shader));
    if (FAILED(made) || shader == nullptr) return internal("DXC không mở được phản chiếu của DXIL do Slang sinh ra");
    return reflect_dxil(*shader.Get(), options.stage, options.entry, options.locations);
}

// Container DXIL: 4 byte "DXBC" rồi 16 byte digest. Digest toàn 0 là chưa ký, D3D12 sẽ từ chối.
[[nodiscard]] bool is_signed(std::span<const std::byte> code) noexcept {
    constexpr std::size_t kDigestAt = 4;
    constexpr std::size_t kDigestSize = 16;
    if (code.size() < kDigestAt + kDigestSize) return false;
    const auto set = [](std::byte value) { return value != std::byte{0}; };
    return std::ranges::any_of(code.subspan(kDigestAt, kDigestSize), set);
}

// Dấu BOM của UTF-8 ở đầu tệp: Slang đọc nguồn như văn bản nên ba byte ấy phải bỏ.
[[nodiscard]] std::string_view strip_bom(std::string_view text) noexcept {
    constexpr std::string_view kBom = "\xEF\xBB\xBF";
    if (text.starts_with(kBom)) text.remove_prefix(kBom.size());
    return text;
}

// "1.9.5399 (a107ba613)": số phiên bản, số commit và mã commit của bản DXC đã nạp.
[[nodiscard]] std::string version_of(DxcCreateInstanceProc create) {
    ComPtr<IDxcCompiler3> compiler;
    if (FAILED(create(CLSID_DxcCompiler, kIidCompiler3, dxc_pp(compiler)))) return {};
    ComPtr<IDxcVersionInfo2> info;
    if (FAILED(compiler->QueryInterface(kIidVersion2, dxc_pp(info)))) return {};
    UINT32 major = 0;
    UINT32 minor = 0;
    UINT32 commits = 0;
    char* hash = nullptr;
    const bool read = SUCCEEDED(info->GetVersion(&major, &minor)) && SUCCEEDED(info->GetCommitInfo(&commits, &hash));
    if (!read || hash == nullptr) return std::format("{}.{}", major, minor);
    std::string text = std::format("{}.{}.{} ({})", major, minor, commits, hash);
    ::CoTaskMemFree(hash);
    return text;
}

// Đường dẫn tuyệt đối đã chuẩn hoá: Slang ghép tên include vào thư mục của nguồn, nên nguồn tuyệt
// đối thì mọi tệp phụ thuộc cũng về dạng tuyệt đối.
[[nodiscard]] std::string absolute(std::string_view path) {
    if (fs::is_absolute(path)) return fs::normalize(path);
    const std::string current = core::narrow(std::filesystem::current_path().wstring());
    return fs::join(current, path);
}

// Phản chiếu chung của một nguồn: SPIR-V đọc bằng spirv.cpp, DXIL đọc bằng DXC, rồi đối chiếu.
[[nodiscard]] StageResult unify(DxcCreateInstanceProc create, const detail::Translated& spirv,
    const detail::Translated& dxil, const CompileOptions& options) {
    Result<StageReflection> vulkan = reflect_spirv(spirv.code, options.stage, options.entry);
    if (!vulkan) return pass(vulkan);
    ComPtr<IDxcUtils> utils;
    if (FAILED(create(CLSID_DxcUtils, kIidUtils, dxc_pp(utils)))) return internal("DXC không tạo được IDxcUtils");
    if (!is_signed(dxil.code)) return fail(ErrorCode::kUnsupported, "Slang không ký được DXIL");
    Result<StageReflection> direct = reflect_dxil_code(*utils.Get(), dxil.code, options);
    if (!direct) return pass(direct);
    return detail::reconcile(std::move(*vulkan), *direct, options.locations);
}

} // namespace

struct Compiler::State {
    explicit State(detail::SlangCompiler compiler) noexcept : slang(std::move(compiler)) {}

    // Thứ tự khai báo: module DXC huỷ sau cùng, sau mọi thứ lấy từ nó.
    detail::Library module;
    DxcCreateInstanceProc create = nullptr;
    detail::SlangCompiler slang;
    std::string version;
    std::string library;
};

Compiler::Compiler(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Compiler::Compiler(Compiler&&) noexcept = default;
Compiler& Compiler::operator=(Compiler&&) noexcept = default;
Compiler::~Compiler() = default;

Result<Compiler> Compiler::create(const CompilerConfig& config) {
    Result<detail::SlangCompiler> slang = detail::SlangCompiler::create();
    if (!slang) return pass(slang);
    auto state = std::make_unique<State>(std::move(*slang));
    const std::vector<std::filesystem::path> candidates = config.library.empty()
        ? detail::library_candidates(L"dxcompiler.dll")
        : std::vector<std::filesystem::path>{std::filesystem::absolute(core::widen(config.library))};
    for (const std::filesystem::path& path : candidates) {
        state->module = detail::open_library(path);
        if (state->module != nullptr) state->library = core::narrow(path.wstring());
        if (state->module != nullptr) break;
    }
    if (state->module == nullptr) {
        const PathView where = "đặt cạnh exe hoặc cài Vulkan SDK (biến VULKAN_SDK)";
        return fail(ErrorCode::kUnsupported, "không tìm thấy dxcompiler.dll", where);
    }
    state->create = detail::find_symbol<DxcCreateInstanceProc>(state->module, "DxcCreateInstance");
    if (state->create == nullptr) {
        return fail(ErrorCode::kUnsupported, "DLL không có DxcCreateInstance", state->library);
    }
    state->version = std::format("{}; dxc {}; quy trình {}", state->slang.version(), version_of(state->create), kPipeline);
    return Compiler(std::move(state));
}

Result<Compiled> Compiler::compile(PathView path, CompileRef options) const {
    const std::string source = absolute(path);
    Result<fs::Bytes> file = fs::read_file(source);
    if (!file) return pass(file);
    const std::span<const std::byte> bytes = file->span();
    std::string text(bytes.size(), '\0');
    if (!bytes.empty()) std::memcpy(text.data(), bytes.data(), bytes.size());
    const MemorySource memory{.path = source, .text = text};
    Result<Compiled> compiled = compile(memory, options);
    if (!compiled) return compiled;
    compiled->dependencies.insert(compiled->dependencies.begin(), source);
    return compiled;
}

Result<Compiled> Compiler::compile(const MemorySource& source, CompileRef options) const {
    if (options.target == Target::kGlsl) {
        return fail(ErrorCode::kInvalidArgument, "GLSL không đi qua Slang");
    }
    const std::string path = absolute(source.path);
    const detail::SlangSource unit{.path = path, .text = strip_bom(source.text)};
    // Phản chiếu luôn lấy từ cả hai bản của cùng nguồn, dù đích là gì.
    CompileOptions vulkan = options;
    vulkan.target = Target::kSpirV;
    CompileOptions direct = options;
    direct.target = Target::kDxil;
    Result<detail::Translated> spirv = state_->slang.translate(unit, vulkan);
    if (!spirv) return pass(spirv);
    Result<detail::Translated> dxil = state_->slang.translate(unit, direct);
    if (!dxil) return pass(dxil);
    Result<StageReflection> reflection = unify(state_->create, *spirv, *dxil, options);
    if (!reflection) return pass(reflection);
    // DXBC: phản chiếu của lượt DXIL, bytecode của lượt Slang thứ ba.
    if (options.target == Target::kDxbc) {
        Result<detail::Translated> bytecode = state_->slang.translate(unit, options);
        if (!bytecode) return pass(bytecode);
        *dxil = std::move(*bytecode);
    }
    detail::Translated& output = options.target == Target::kSpirV ? *spirv : *dxil;
    return Compiled{.code = std::move(output.code),
        .reflection = std::move(*reflection),
        .dependencies = std::move(output.dependencies),
        .messages = std::move(output.messages)};
}

std::string_view Compiler::version() const noexcept {
    return state_->version;
}

std::string_view Compiler::library() const noexcept {
    return state_->library;
}

} // namespace game::shader
