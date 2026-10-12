// D3DCompile là đường shader model 5. DXC không phát vs_5_0. Include xử tại chỗ vì giao diện
// ID3DInclude không dùng được handler DXC. Khác gốc: không có bản Forge2 để chép.
#include "shader/dxbc.hpp"

#include "core/win32.hpp" // IWYU pragma: keep
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"
#include "shader/builtin.hpp"
#include "shader/compiler.hpp"
#include "shader/types.hpp"

#include <d3dcommon.h>
#include <d3dcompiler.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <iterator>
#include <limits>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

using Microsoft::WRL::ComPtr;

struct Blob {
    std::string path;
    std::vector<std::byte> bytes;
};

struct IncludeState {
    std::string source_dir;
    std::vector<std::string> include_dirs;
    // unique_ptr: con trỏ đã trả cho fxc không bị vector cấp phát lại làm hỏng.
    std::vector<std::unique_ptr<Blob>> kept;
};

struct MacroList {
    std::vector<std::string> storage;
    std::vector<D3D_SHADER_MACRO> macros;
};

constexpr std::array<const char*, kStageCount> kProfiles{
    "vs_5_0", "hs_5_0", "ds_5_0", "gs_5_0", "ps_5_0", "cs_5_0", "", "", ""};

[[nodiscard]] const char* profile_of(Stage stage) noexcept {
    const auto index = static_cast<std::size_t>(std::to_underlying(stage));
    if (index >= kProfiles.size()) return "";
    return kProfiles.at(index);
}

[[nodiscard]] char upper(char letter) noexcept {
    const bool lower = letter >= 'a' && letter <= 'z';
    return lower ? static_cast<char>(letter - 'a' + 'A') : letter;
}

[[nodiscard]] std::string stage_define(Stage stage) {
    std::string define = "F2_STAGE_";
    std::ranges::transform(tag(stage), std::back_inserter(define), upper);
    return define;
}

[[nodiscard]] UINT flags_of(const CompileOptions& options) noexcept {
    UINT flags = D3DCOMPILE_ENABLE_STRICTNESS;
    if (options.strict) flags |= D3DCOMPILE_WARNINGS_ARE_ERRORS;
    if (options.debug) flags |= D3DCOMPILE_DEBUG | D3DCOMPILE_SKIP_OPTIMIZATION;
    if (options.debug) return flags;
    return flags | D3DCOMPILE_OPTIMIZATION_LEVEL3;
}

// name đứng trước value, cùng thứ tự Name rồi Definition của macro fxc.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void add_pair(MacroList& list, std::string_view name, std::string_view value) {
    list.storage.emplace_back(name);
    list.storage.emplace_back(value);
}

void add_user(MacroList& list, std::string_view text) {
    const auto split = text.find('=');
    if (split == std::string_view::npos) add_pair(list, text, "1");
    if (split == std::string_view::npos) return;
    add_pair(list, text.substr(0, split), text.substr(split + 1));
}

void point_one(MacroList& list, std::size_t& index) {
    D3D_SHADER_MACRO macro{};
    macro.Name = list.storage[index].c_str();
    macro.Definition = list.storage[index + 1].c_str();
    list.macros.push_back(macro);
    index += 2;
}

void add_points(MacroList& list) {
    std::size_t index = 0;
    while (index + 1 < list.storage.size()) {
        point_one(list, index);
    }
    const D3D_SHADER_MACRO end{};
    list.macros.push_back(end);
}

[[nodiscard]] MacroList macros_of(const CompileOptions& options) {
    MacroList list;
    add_pair(list, "F2_DXBC", "1");
    if (options.debug) add_pair(list, "F2_DEBUG", "1");
    const std::string stage = stage_define(options.stage);
    add_pair(list, stage, "1");
    for (const std::string& define : options.defines)
        add_user(list, define);
    add_points(list);
    return list;
}

[[nodiscard]] std::string_view strip_bom(std::string_view text) noexcept {
    const auto bom = std::string_view("\xEF\xBB\xBF");
    if (!text.starts_with(bom)) return text;
    return text.substr(bom.size());
}

[[nodiscard]] bool is_builtin(std::string_view path) noexcept {
    if (!path.ends_with(kBuiltinName)) return false;
    const std::size_t before = path.size() - kBuiltinName.size();
    return before == 0 || fs::is_separator(path.at(before - 1));
}

void fill_builtin(Blob& blob) {
    const auto bytes = std::as_bytes(std::span(kBuiltinText));
    blob.bytes.assign(bytes.begin(), bytes.end());
    blob.path = std::string(kBuiltinName);
}

struct DataIs {
    LPCVOID data = nullptr;
    [[nodiscard]] bool operator()(const std::unique_ptr<Blob>& item) const noexcept {
        return item->bytes.data() == data;
    }
};

[[nodiscard]] const Blob* parent_blob(IncludeState& state, LPCVOID parent) {
    if (parent == nullptr) return nullptr;
    DataIs same;
    same.data = parent;
    const auto found = std::ranges::find_if(state.kept, same);
    if (found == state.kept.end()) return nullptr;
    return found->get();
}

struct Search {
    const std::vector<std::string>* dirs = nullptr;
    std::string_view name;
    std::size_t index = 0;
    std::string found;
};

void search_step(Search& search) {
    if (!search.found.empty()) return;
    if (search.index >= search.dirs->size()) return;
    const std::string path = fs::join(search.dirs->at(search.index), search.name);
    ++search.index;
    if (!fs::exists(path)) return;
    search.found = fs::normalize(path);
}

[[nodiscard]] std::string search_dirs(const std::vector<std::string>& dirs, std::string_view name) {
    if (fs::is_absolute(name)) return fs::normalize(name);
    Search search;
    search.dirs = &dirs;
    search.name = name;
    while (search.found.empty() && search.index < dirs.size()) {
        search_step(search);
    }
    return search.found;
}

struct DirIn {
    const IncludeState* state = nullptr;
    D3D_INCLUDE_TYPE type = D3D_INCLUDE_LOCAL;
    const Blob* parent = nullptr;
};

[[nodiscard]] std::vector<std::string> dirs_for(const DirIn& input) {
    std::vector<std::string> dirs;
    const bool local = input.type == D3D_INCLUDE_LOCAL;
    if (local && input.parent != nullptr) dirs.emplace_back(fs::parent(input.parent->path));
    if (local) dirs.emplace_back(input.state->source_dir);
    const std::vector<std::string>& more = input.state->include_dirs;
    dirs.insert(dirs.end(), more.begin(), more.end());
    if (!local) dirs.emplace_back(input.state->source_dir);
    return dirs;
}

struct FillIn {
    IncludeState* state = nullptr;
    D3D_INCLUDE_TYPE type = D3D_INCLUDE_LOCAL;
    LPCSTR name = nullptr;
    LPCVOID parent = nullptr;
    Blob* blob = nullptr;
};

[[nodiscard]] HRESULT fill_blob(const FillIn& input) {
    if (is_builtin(input.name)) fill_builtin(*input.blob);
    if (is_builtin(input.name)) return S_OK;
    const Blob* from = parent_blob(*input.state, input.parent);
    DirIn dirs_in;
    dirs_in.state = input.state;
    dirs_in.type = input.type;
    dirs_in.parent = from;
    const std::vector<std::string> dirs = dirs_for(dirs_in);
    const std::string path = search_dirs(dirs, input.name);
    if (path.empty()) return E_FAIL;
    Result<fs::Bytes> file = fs::read_file(path);
    if (!file) return E_FAIL;
    input.blob->path = path;
    const std::span<const std::byte> span = file->span();
    input.blob->bytes.assign(span.begin(), span.end());
    return S_OK;
}

[[nodiscard]] HRESULT expose(Blob& blob, LPCVOID* data, UINT* bytes) {
    if (blob.bytes.size() > std::numeric_limits<UINT>::max()) return E_FAIL;
    *data = blob.bytes.data();
    *bytes = static_cast<UINT>(blob.bytes.size());
    return S_OK;
}

struct OpenIn {
    IncludeState* state = nullptr;
    D3D_INCLUDE_TYPE type = D3D_INCLUDE_LOCAL;
    LPCSTR name = nullptr;
    LPCVOID parent = nullptr;
    LPCVOID* data = nullptr;
    UINT* bytes = nullptr;
};

[[nodiscard]] HRESULT open_named(const OpenIn& input) {
    if (input.name == nullptr || input.data == nullptr || input.bytes == nullptr) return E_POINTER;
    *input.data = nullptr;
    *input.bytes = 0;
    input.state->kept.push_back(std::make_unique<Blob>());
    Blob& blob = *input.state->kept.back();
    FillIn fill;
    fill.state = input.state;
    fill.type = input.type;
    fill.name = input.name;
    fill.parent = input.parent;
    fill.blob = &blob;
    const HRESULT filled = fill_blob(fill);
    if (FAILED(filled)) input.state->kept.pop_back();
    if (FAILED(filled)) return filled;
    return expose(blob, input.data, input.bytes);
}

// ID3DInclude không có destructor ảo. Đối tượng chỉ sống trên stack, không xoá qua base.
#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnon-virtual-dtor"
#endif
class IncludeHandler final : public ID3DInclude {
public:
    using Inc = D3D_INCLUDE_TYPE;
    using CStr = LPCSTR;
    using Void = LPCVOID;
    using Data = LPCVOID*;

    explicit IncludeHandler(IncludeState& state) noexcept : state_(&state) {}

    HRESULT Open(Inc kind, CStr name, Void from, Data data, UINT* size) noexcept override {
        try {
            OpenIn input;
            input.state = state_;
            input.type = kind;
            input.name = name;
            input.parent = from;
            input.data = data;
            input.bytes = size;
            return open_named(input);
        } catch (...) {
            return E_OUTOFMEMORY;
        }
    }

    HRESULT Close(LPCVOID data) noexcept override {
        static_cast<void>(data);
        return S_OK;
    }

private:
    IncludeState* state_ = nullptr;
};
#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

struct NativeIn {
    std::string_view text;
    std::string name;
    std::string entry;
    const char* profile = nullptr;
    const D3D_SHADER_MACRO* macros = nullptr;
    ID3DInclude* includes = nullptr;
    UINT flags = 0;
    ComPtr<ID3DBlob>* code = nullptr;
    ComPtr<ID3DBlob>* errors = nullptr;
};

[[nodiscard]] HRESULT compile_native(const NativeIn& input) {
    const auto* source = static_cast<const void*>(input.text.data());
    ID3DBlob** code = input.code->GetAddressOf();
    ID3DBlob** errors = input.errors->GetAddressOf();
    return D3DCompile(source, input.text.size(), input.name.c_str(), input.macros, input.includes,
        input.entry.c_str(), input.profile, input.flags, 0, code, errors);
}

[[nodiscard]] std::string message_of(ID3DBlob* errors) {
    if (errors == nullptr || errors->GetBufferPointer() == nullptr) return {};
    const auto* text = static_cast<const char*>(errors->GetBufferPointer());
    const std::size_t bytes = errors->GetBufferSize();
    std::string_view view(text, bytes);
    if (!view.empty() && view.back() == '\0') view.remove_suffix(1);
    return std::string{view};
}

[[nodiscard]] std::vector<std::byte> bytes_of(ID3DBlob& blob) {
    const auto* data = static_cast<const std::byte*>(blob.GetBufferPointer());
    const std::size_t size = blob.GetBufferSize();
    const std::span<const std::byte> bytes{data, size};
    return std::vector<std::byte>{bytes.begin(), bytes.end()};
}

} // namespace

ByteCode compile_bytecode(const BytecodeIn& input) {
    const char* profile = profile_of(input.options->stage);
    const std::string_view profile_text{profile};
    if (profile_text.empty()) return fail(ErrorCode::kUnsupported, "stage không có profile DXBC");
    IncludeState includes;
    includes.source_dir = std::string(fs::parent(input.path));
    includes.include_dirs = input.options->include_dirs;
    IncludeHandler handler(includes);
    const MacroList macros = macros_of(*input.options);
    ComPtr<ID3DBlob> code;
    ComPtr<ID3DBlob> errors;
    NativeIn native;
    native.text = strip_bom(input.text);
    native.name = std::string(input.path);
    native.entry = input.options->entry;
    native.profile = profile;
    native.macros = macros.macros.data();
    native.includes = &handler;
    native.flags = flags_of(*input.options);
    native.code = &code;
    native.errors = &errors;
    const HRESULT compiled = compile_native(native);
    ID3DBlob* errors_blob = errors.Get();
    const std::string detail = message_of(errors_blob);
    if (FAILED(compiled)) return fail(ErrorCode::kInvalidArgument, "fxc từ chối shader", detail);
    if (code == nullptr) return fail(ErrorCode::kInternal, "D3DCompile không trả bytecode");
    ID3DBlob* code_blob = code.Get();
    return bytes_of(*code_blob);
}

} // namespace game::shader
