// Dịch một nguồn HLSL bằng DXC ra DXIL hoặc SPIR-V. DXBC dùng D3DCompile (shader/dxbc.cpp):
// phản chiếu lấy từ lượt DXIL của cùng nguồn, bytecode là shader model 5.
// -fvk-use-dx-layout giữ bố cục cbuffer HLSL để hai đích cùng offset.
// Thiếu -fspv-use-unknown-image-format thì DXC tự đoán định dạng ảnh storage.
#include "shader/compiler.hpp"

#include "core/system.hpp"
#include "core/text.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "shader/builtin.hpp"
#include "shader/dxbc.hpp"
#include "shader/dxil.hpp"
#include "shader/failure.hpp"
#include "shader/spirv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <filesystem>
#include <format>
#include <limits>
#include <type_traits>
#include <utility>

#include <windows.h>

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

struct LibraryCloser {
    void operator()(HMODULE module) const noexcept { ::FreeLibrary(module); }
};

using Library = std::unique_ptr<std::remove_pointer_t<HMODULE>, LibraryCloser>;
using WideText = std::vector<std::wstring>;
using Utils = IDxcUtils;
using StageResult = Result<StageReflection>;

// Mức shader model thấp nhất mà profile của stage tồn tại.
[[nodiscard]] ShaderModel least_model(Stage stage) noexcept {
    const bool meshlet = stage == Stage::kMesh || stage == Stage::kAmplification;
    if (meshlet) return {.major = 6, .minor = 5};
    if (stage == Stage::kLibrary) return {.major = 6, .minor = 3};
    return kOldestModel;
}

[[nodiscard]] std::string profile(const CompileOptions& options) {
    const ShaderModel model = std::max(options.model, least_model(options.stage));
    return std::format("{}_{}_{}", tag(options.stage), model.major, model.minor);
}

[[nodiscard]] char upper(char c) noexcept {
    const bool lower = c >= 'a' && c <= 'z';
    return lower ? static_cast<char>(c - 'a' + 'A') : c;
}

// "F2_STAGE_VS" cho Stage::kVertex.
[[nodiscard]] std::string stage_define(Stage stage) {
    std::string define = "F2_STAGE_";
    std::ranges::transform(tag(stage), std::back_inserter(define), upper);
    return define;
}

void add(std::vector<std::wstring>& args, std::wstring_view flag) {
    args.emplace_back(flag);
}

void add(std::vector<std::wstring>& args, std::wstring_view flag, std::string_view value) {
    args.emplace_back(flag);
    args.push_back(core::widen(value));
}

// Độ dịch binding của một lớp register, áp cho mọi register space.
void add_shift(std::vector<std::wstring>& args, std::wstring_view flag, RegisterType group) {
    args.emplace_back(flag);
    args.push_back(std::to_wstring(binding_shift(group)));
    args.emplace_back(L"all");
}

// Cờ riêng của SPIR-V. -fvk-use-dx-layout giữ bố cục cbuffer của HLSL để hai đích cùng offset.
// -fspv-use-unknown-image-format: không có nó DXC đoán định dạng storage image từ kiểu HLSL
// (RWTexture2D<float4> thành Rgba32f), và gắn ảnh khác định dạng vào là sai với Vulkan.
void add_spirv(std::vector<std::wstring>& args, const CompileOptions& options) {
    add(args, L"-spirv");
    args.push_back(std::format(L"-fspv-target-env=vulkan1.{}", options.vulkan_minor));
    add(args, L"-fvk-use-dx-layout");
    add(args, L"-fspv-use-unknown-image-format");
    add_shift(args, L"-fvk-b-shift", RegisterType::kConstant);
    add_shift(args, L"-fvk-t-shift", RegisterType::kResource);
    add_shift(args, L"-fvk-u-shift", RegisterType::kUnordered);
    add_shift(args, L"-fvk-s-shift", RegisterType::kSampler);
}

void add_mode(std::vector<std::wstring>& args, const CompileOptions& options) {
    const bool dxil = options.target == Target::kDxil;
    if (options.debug) {
        add(args, L"-Od");
        add(args, L"-Zi");
        add(args, L"-D", "F2_DEBUG");
    }
    if (options.debug && dxil) add(args, L"-Qembed_debug");
    if (options.debug || !dxil) return;
    // Phản chiếu vẫn lấy được qua DXC_OUT_REFLECTION; container giao cho D3D12 không cần mang nó.
    add(args, L"-Qstrip_debug");
    add(args, L"-Qstrip_reflect");
}

[[nodiscard]] WideText arguments(PathView path, const CompileOptions& options) {
    std::vector<std::wstring> args;
    args.push_back(core::widen(path));
    add(args, L"-T", profile(options));
    if (options.stage != Stage::kLibrary) add(args, L"-E", options.entry);
    add(args, L"-HV", "2021");
    if (options.strict) add(args, L"-WX");
    add_mode(args, options);
    if (options.target == Target::kSpirV) add_spirv(args, options);
    // Thuộc tính [[vk::...]] chỉ có nghĩa với SPIR-V; ở lượt DXIL nó là cảnh báo "ignored
    // attribute" mà -WX biến thành lỗi, trong khi cùng một nguồn phải dịch được cho cả hai đích.
    if (options.target == Target::kDxil) add(args, L"-Wno-ignored-attributes");
    add(args, L"-D", options.target == Target::kDxil ? "F2_DXIL" : "F2_SPIRV");
    add(args, L"-D", stage_define(options.stage));
    for (const std::string& define : options.defines) {
        add(args, L"-D", define);
    }
    for (const std::string& directory : options.include_dirs) {
        add(args, L"-I", directory);
    }
    return args;
}

// Đường dẫn tuyệt đối đã chuẩn hoá: DXC ghép tên include vào thư mục của nguồn, nên nguồn tuyệt
// đối thì mọi tệp phụ thuộc cũng về dạng tuyệt đối.
[[nodiscard]] std::string absolute(std::string_view path) {
    if (fs::is_absolute(path)) return fs::normalize(path);
    const std::string current = core::narrow(std::filesystem::current_path().wstring());
    return fs::join(current, path);
}

[[nodiscard]] bool is_builtin(std::string_view path) noexcept {
    if (!path.ends_with(kBuiltinName)) return false;
    const std::size_t before = path.size() - kBuiltinName.size();
    return before == 0 || fs::is_separator(path.at(before - 1));
}

// Trạng thái của một lần dịch mà bộ nạp include ghi vào. IncludeObject chỉ giữ con trỏ:
// bảng hàm COM không có destructor, nên đối tượng không được sở hữu gì.
struct Includes {
    IDxcUtils* utils = nullptr;
    std::vector<std::string> files{};
};

[[nodiscard]] HRESULT make_blob(IDxcUtils& utils, std::span<const std::byte> data, IDxcBlob** out) {
    if (data.size() > std::numeric_limits<UINT32>::max()) return E_FAIL;
    ComPtr<IDxcBlobEncoding> blob;
    const auto size = static_cast<UINT32>(data.size());
    const HRESULT made = utils.CreateBlob(data.data(), size, DXC_CP_UTF8, &blob);
    if (FAILED(made)) return made;
    *out = blob.Detach();
    return S_OK;
}

void remember(std::vector<std::string>& files, std::string path) {
    const bool known = std::ranges::find(files, path) != files.end();
    if (!known) files.push_back(std::move(path));
}

// DXC hỏi lần lượt từng chỗ một tệp include có thể nằm: cạnh tệp đang dịch, rồi từng thư mục -I.
// Trả lỗi cho chỗ không có tệp thì nó hỏi chỗ kế.
[[nodiscard]] HRESULT load(Includes& includes, LPCWSTR name, IDxcBlob** out) {
    if (name == nullptr || out == nullptr) return E_POINTER;
    *out = nullptr;
    const std::string path = fs::normalize(core::narrow(name));
    const std::span<const std::byte> builtin = std::as_bytes(std::span(kBuiltinText));
    if (is_builtin(path)) return make_blob(*includes.utils, builtin, out);
    Result<fs::Bytes> file = fs::read_file(path);
    if (!file) return E_FAIL;
    const HRESULT made = make_blob(*includes.utils, file->span(), out);
    if (SUCCEEDED(made)) remember(includes.files, path);
    return made;
}

// Chuỗi uuid trong dxcapi.h và d3d12shader.h. DXC không phát hằng IID_*, chỉ __declspec(uuid).
constexpr GUID kIidUnknown{
    .Data1 = 0x00000000, .Data2 = 0x0000, .Data3 = 0x0000, .Data4 = {0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46}};
constexpr GUID kIidBlob{
    .Data1 = 0x8BA5FB08, .Data2 = 0x5195, .Data3 = 0x40E2, .Data4 = {0xAC, 0x58, 0x0D, 0x98, 0x9C, 0x3A, 0x01, 0x02}};
constexpr GUID kIidBlobUtf8{
    .Data1 = 0x3DA636C9, .Data2 = 0xBA71, .Data3 = 0x4024, .Data4 = {0xA3, 0x01, 0x30, 0xCB, 0xF1, 0x25, 0x30, 0x5B}};
constexpr GUID kIidInclude{
    .Data1 = 0x7F61FC7D, .Data2 = 0x950D, .Data3 = 0x467F, .Data4 = {0xB3, 0xE3, 0x3C, 0x02, 0xFB, 0x49, 0x18, 0x7C}};
constexpr GUID kIidUtils{
    .Data1 = 0x4605C4CB, .Data2 = 0x2019, .Data3 = 0x492A, .Data4 = {0xAD, 0xA4, 0x65, 0xF2, 0x0B, 0xB7, 0xD6, 0x7F}};
constexpr GUID kIidResult{
    .Data1 = 0x58346CDA, .Data2 = 0xDDE7, .Data3 = 0x4497, .Data4 = {0x94, 0x61, 0x6F, 0x87, 0xAF, 0x5E, 0x06, 0x59}};
constexpr GUID kIidCompiler3{
    .Data1 = 0x228B4687, .Data2 = 0x5A6A, .Data3 = 0x4730, .Data4 = {0x90, 0x0C, 0x97, 0x02, 0xB2, 0x20, 0x3F, 0x54}};
constexpr GUID kIidVersion2{
    .Data1 = 0xFB6904C4, .Data2 = 0x42F0, .Data3 = 0x4B62, .Data4 = {0x9C, 0x46, 0x98, 0x3A, 0xF7, 0xDA, 0x7C, 0x83}};
constexpr GUID kIidShader{
    .Data1 = 0x5A58797D, .Data2 = 0xA72C, .Data3 = 0x478D, .Data4 = {0x8B, 0xA2, 0xEF, 0xC6, 0xB0, 0xEF, 0xE8, 0x8E}};
constexpr GUID kIidLibrary{
    .Data1 = 0x8E349D19, .Data2 = 0x54DB, .Data3 = 0x4A56, .Data4 = {0x9D, 0xC9, 0x11, 0x9D, 0x87, 0xBD, 0xB8, 0x04}};

template <typename T>
[[nodiscard]] void** dxc_pp(Microsoft::WRL::ComPtr<T>& slot) noexcept {
    // T** không đổi được sang void** bằng static_cast. Đây là biên COM.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return reinterpret_cast<void**>(slot.GetAddressOf());
}

// Không kế thừa IDxcIncludeHandler: destructor ảo đổi bảng hàm, destructor không ảo thì GCC
// vẫn báo. Bốn slot: QueryInterface, AddRef, Release, LoadSource. Đối tượng sống trên stack.
using IncludeQuery = HRESULT(STDMETHODCALLTYPE*)(IDxcIncludeHandler*, REFIID, void**);
using IncludeCount = ULONG(STDMETHODCALLTYPE*)(IDxcIncludeHandler*);
using IncludeLoad = HRESULT(STDMETHODCALLTYPE*)(IDxcIncludeHandler*, LPCWSTR, IDxcBlob**);

struct IncludeVtable {
    IncludeQuery query = nullptr;
    IncludeCount add = nullptr;
    IncludeCount release = nullptr;
    IncludeLoad load = nullptr;
};

struct IncludeObject {
    const IncludeVtable* vptr = nullptr;
    Includes* includes = nullptr;
};

HRESULT STDMETHODCALLTYPE include_query(IDxcIncludeHandler* self, REFIID riid, void** object) noexcept {
    if (object == nullptr) return E_POINTER;
    const bool is_handler = IsEqualGUID(riid, kIidInclude) != FALSE;
    const bool is_unknown = IsEqualGUID(riid, kIidUnknown) != FALSE;
    const bool mine = is_handler || is_unknown;
    *object = mine ? static_cast<void*>(self) : nullptr;
    return mine ? S_OK : E_NOINTERFACE;
}

ULONG STDMETHODCALLTYPE include_add(IDxcIncludeHandler*) noexcept {
    return 1;
}

ULONG STDMETHODCALLTYPE include_release(IDxcIncludeHandler*) noexcept {
    return 1;
}

HRESULT STDMETHODCALLTYPE include_load(IDxcIncludeHandler* self, LPCWSTR name, IDxcBlob** out) noexcept {
    // Ngoại lệ không được thoát qua ranh giới COM.
    try {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): this của slot COM
        const auto* object = reinterpret_cast<const IncludeObject*>(self);
        return load(*object->includes, name, out);
    } catch (...) {
        return E_OUTOFMEMORY;
    }
}

const IncludeVtable kIncludeVtable{
    .query = include_query, .add = include_add, .release = include_release, .load = include_load};

[[nodiscard]] IDxcIncludeHandler* include_as(IncludeObject& object) noexcept {
    static_assert(offsetof(IncludeObject, vptr) == 0);
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): đối tượng đứng ở đầu bảng hàm
    return reinterpret_cast<IDxcIncludeHandler*>(&object);
}

[[nodiscard]] std::string text_of(IDxcResult& result, DXC_OUT_KIND kind) {
    ComPtr<IDxcBlobUtf8> blob;
    const HRESULT got = result.GetOutput(kind, kIidBlobUtf8, dxc_pp(blob), nullptr);
    if (FAILED(got) || blob == nullptr) return {};
    return {blob->GetStringPointer(), blob->GetStringLength()};
}

[[nodiscard]] std::vector<std::byte> bytes_of(IDxcBlob& blob) {
    std::vector<std::byte> out(blob.GetBufferSize());
    if (!out.empty()) std::memcpy(out.data(), blob.GetBufferPointer(), out.size());
    return out;
}

[[nodiscard]] Result<StageReflection> reflect_library(IDxcUtils& utils, const DxcBuffer& buffer) {
    ComPtr<ID3D12LibraryReflection> library;
    const HRESULT made = utils.CreateReflection(&buffer, kIidLibrary, dxc_pp(library));
    if (FAILED(made) || library == nullptr) return internal("DXC không mở được phản chiếu");
    return reflect_dxil(*library.Get());
}

[[nodiscard]] StageResult reflect(Utils& utils, IDxcResult& result, const CompileOptions& options) {
    ComPtr<IDxcBlob> blob;
    const HRESULT got = result.GetOutput(DXC_OUT_REFLECTION, kIidBlob, dxc_pp(blob), nullptr);
    if (FAILED(got) || blob == nullptr) return internal("DXC không trả phản chiếu");
    const DxcBuffer buffer{.Ptr = blob->GetBufferPointer(), .Size = blob->GetBufferSize(), .Encoding = DXC_CP_ACP};
    if (options.stage == Stage::kLibrary) return reflect_library(utils, buffer);
    ComPtr<ID3D12ShaderReflection> shader;
    const HRESULT made = utils.CreateReflection(&buffer, kIidShader, dxc_pp(shader));
    if (FAILED(made) || shader == nullptr) return internal("DXC không mở được phản chiếu");
    return reflect_dxil(*shader.Get(), options.stage, options.entry);
}

// Container DXIL: 4 byte "DXBC" rồi 16 byte digest. Digest toàn 0 là chưa ký, D3D12 sẽ từ chối.
[[nodiscard]] bool is_signed(std::span<const std::byte> code) noexcept {
    constexpr std::size_t kDigestAt = 4;
    constexpr std::size_t kDigestSize = 16;
    if (code.size() < kDigestAt + kDigestSize) return false;
    const auto set = [](std::byte value) { return value != std::byte{0}; };
    return std::ranges::any_of(code.subspan(kDigestAt, kDigestSize), set);
}

[[nodiscard]] core::Failure refuse(std::string_view messages) {
    const bool has_spirv = !messages.contains("SPIR-V CodeGen not available");
    if (has_spirv) return fail(ErrorCode::kInvalidArgument, "shader không dịch được", messages);
    return fail(ErrorCode::kUnsupported, "bản DXC này không sinh được SPIR-V", messages);
}

struct Collected {
    Utils* utils = nullptr;
    IDxcResult* result = nullptr;
    const CompileOptions* options = nullptr;
    std::vector<std::string> files{};
};

[[nodiscard]] Result<Compiled> collect(Collected input) {
    Utils& utils = *input.utils;
    IDxcResult& result = *input.result;
    const CompileOptions& options = *input.options;
    std::vector<std::string> files = std::move(input.files);
    Compiled compiled;
    compiled.messages = text_of(result, DXC_OUT_ERRORS);
    HRESULT status = E_FAIL;
    const bool reported = SUCCEEDED(result.GetStatus(&status));
    if (!reported || FAILED(status)) return refuse(compiled.messages);
    ComPtr<IDxcBlob> object;
    const HRESULT got = result.GetOutput(DXC_OUT_OBJECT, kIidBlob, dxc_pp(object), nullptr);
    if (FAILED(got) || object == nullptr) return internal("DXC không trả mã đã dịch");
    compiled.code = bytes_of(*object.Get());
    const bool spirv = options.target == Target::kSpirV;
    Result<StageReflection> reflection =
        spirv ? reflect_spirv(compiled.code, options.stage, options.entry) : reflect(utils, result, options);
    if (!reflection) return pass(reflection);
    const bool unsigned_dxil = !spirv && !is_signed(compiled.code);
    if (unsigned_dxil) return fail(ErrorCode::kUnsupported, "DXC không ký được DXIL");
    compiled.reflection = std::move(*reflection);
    compiled.dependencies = std::move(files);
    return compiled;
}

// Dấu BOM của UTF-8 ở đầu tệp: DXC nhận mã hoá qua tham số nên ba byte ấy phải bỏ.
[[nodiscard]] std::string_view strip_bom(std::string_view text) noexcept {
    constexpr std::string_view kBom = "\xEF\xBB\xBF";
    if (text.starts_with(kBom)) text.remove_prefix(kBom.size());
    return text;
}

[[nodiscard]] std::wstring environment(const wchar_t* name) {
    const DWORD size = ::GetEnvironmentVariableW(name, nullptr, 0);
    if (size == 0) return {};
    std::wstring value(size, L'\0');
    const DWORD written = ::GetEnvironmentVariableW(name, value.data(), size);
    value.resize(written < size ? written : 0);
    return value;
}

[[nodiscard]] std::vector<std::filesystem::path> candidates(const CompilerConfig& config) {
    if (!config.library.empty()) return {std::filesystem::absolute(core::widen(config.library))};
    std::vector<std::filesystem::path> paths;
    paths.push_back(core::exe_directory() / L"dxcompiler.dll");
    const std::wstring sdk = environment(L"VULKAN_SDK");
    if (!sdk.empty()) paths.push_back(std::filesystem::path(sdk) / L"Bin" / L"dxcompiler.dll");
    return paths;
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

} // namespace

struct Compiler::State {
    // Thứ tự khai báo: module huỷ sau cùng, sau mọi thứ lấy từ nó.
    Library module{};
    DxcCreateInstanceProc create = nullptr;
    std::string version{};
    std::string library{};
};

Compiler::Compiler(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Compiler::Compiler(Compiler&&) noexcept = default;
Compiler& Compiler::operator=(Compiler&&) noexcept = default;
Compiler::~Compiler() = default;

Result<Compiler> Compiler::create(const CompilerConfig& config) {
    auto state = std::make_unique<State>();
    for (const std::filesystem::path& path : candidates(config)) {
        // Đường dẫn tuyệt đối cộng cờ này: DLL mà dxcompiler cần được tìm cạnh nó trước.
        state->module.reset(::LoadLibraryExW(path.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH));
        if (state->module != nullptr) state->library = core::narrow(path.wstring());
        if (state->module != nullptr) break;
    }
    if (state->module == nullptr) {
        const PathView where = "đặt cạnh exe hoặc cài Vulkan SDK (biến VULKAN_SDK)";
        return fail(ErrorCode::kUnsupported, "không tìm thấy dxcompiler.dll", where);
    }
    const FARPROC entry = ::GetProcAddress(state->module.get(), "DxcCreateInstance");
    if (entry == nullptr) {
        return fail(ErrorCode::kUnsupported, "DLL không có DxcCreateInstance", state->library);
    }
    // GetProcAddress trả con trỏ hàm không kiểu; chữ ký thật là DxcCreateInstanceProc của dxcapi.h.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    state->create = reinterpret_cast<DxcCreateInstanceProc>(entry);
    state->version = version_of(state->create);
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

namespace {

struct SourceText {
    const Compiler* compiler = nullptr;
    std::string_view path;
    std::string_view text;
    const CompileOptions* options = nullptr;
};

[[nodiscard]] Result<Compiled> dxbc_from(const SourceText& in) {
    CompileOptions reflected = *in.options;
    reflected.target = Target::kDxil;
    const MemorySource memory{.path = in.path, .text = in.text};
    Result<Compiled> compiled = in.compiler->compile(memory, reflected);
    if (!compiled) return compiled;
    BytecodeIn bytes;
    bytes.path = in.path;
    bytes.text = in.text;
    bytes.options = in.options;
    ByteCode code = compile_bytecode(bytes);
    if (!code) return std::unexpected(code.error());
    compiled->code = std::move(*code);
    return compiled;
}

} // namespace

Result<Compiled> Compiler::compile(const MemorySource& source, CompileRef options) const {
    const std::string_view text = source.text;
    const std::string path = absolute(source.path);
    if (options.target == Target::kGlsl) {
        return fail(ErrorCode::kInvalidArgument, "GLSL không đi qua DXC");
    }
    if (options.target == Target::kDxbc) {
        SourceText in;
        in.compiler = this;
        in.path = path;
        in.text = text;
        in.options = &options;
        return dxbc_from(in);
    }
    ComPtr<IDxcUtils> utils;
    ComPtr<IDxcCompiler3> compiler;
    const bool made = SUCCEEDED(state_->create(CLSID_DxcUtils, kIidUtils, dxc_pp(utils))) &&
        SUCCEEDED(state_->create(CLSID_DxcCompiler, kIidCompiler3, dxc_pp(compiler)));
    if (!made) return internal("DXC không tạo được trình dịch");
    Includes includes{.utils = utils.Get()};
    IncludeObject handler{.vptr = &kIncludeVtable, .includes = &includes};
    const std::vector<std::wstring> args = arguments(path, options);
    std::vector<LPCWSTR> raw(args.size());
    std::ranges::transform(args, raw.begin(), &std::wstring::c_str);
    const std::string_view body = strip_bom(text);
    const DxcBuffer buffer{.Ptr = body.data(), .Size = body.size(), .Encoding = DXC_CP_UTF8};
    ComPtr<IDxcResult> result;
    const auto count = static_cast<UINT32>(raw.size());
    const HRESULT called =
        compiler->Compile(&buffer, raw.data(), count, include_as(handler), kIidResult, dxc_pp(result));
    if (FAILED(called) || result == nullptr) {
        const auto code = static_cast<std::uint32_t>(called);
        return fail(ErrorCode::kInternal, "DXC từ chối lời gọi dịch", "HRESULT {:#010x}", code);
    }
    Collected gathered;
    gathered.utils = utils.Get();
    gathered.result = result.Get();
    gathered.options = &options;
    gathered.files = std::move(includes.files);
    return collect(std::move(gathered));
}

std::string_view Compiler::version() const noexcept {
    return state_->version;
}

std::string_view Compiler::library() const noexcept {
    return state_->library;
}

} // namespace game::shader
