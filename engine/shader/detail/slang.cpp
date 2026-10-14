// Dịch nguồn .slang bằng Slang (slang.dll): ba đích SPIR-V, DXIL, DXBC từ một nguồn. Bộ cờ khớp
// những gì DXC và D3DCompile từng nhận để phản chiếu và bố cục không đổi:
// - ma trận xếp theo cột như DXC (Slang mặc định xếp theo hàng, sẽ đảo mọi mul(M, v));
// - SPIR-V: -fvk-use-dx-layout giữ bố cục cbuffer của HLSL, định dạng ảnh storage để unknown, binding
//   = slot cộng độ dịch của lớp register (b 0, t 1000, u 2000, s 3000; binding_shift), tên entry giữ
//   nguyên thay cho "main";
// - cảnh báo là lỗi khi options.strict.
// Include đi qua một hệ thống tệp của riêng mình: "f2/shader.inc.slang" lấy từ bộ nhớ (builtin.hpp),
// mọi tệp khác đọc bằng fs::read_file và được ghi lại làm phụ thuộc.
#include "shader/detail/slang.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"
#include "shader/builtin.hpp"
#include "shader/compiler.hpp"
#include "shader/detail/library.hpp"
#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <slang-com-helper.h>
#include <slang-com-ptr.h>
#include <slang.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <format>
#include <iterator>
#include <memory>
#include <mutex>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shader::detail {

namespace {

using Slang::ComPtr;

// Mức shader model thấp nhất mà profile của stage tồn tại.
[[nodiscard]] ShaderModel least_model(Stage stage) noexcept {
    const bool meshlet = stage == Stage::kMesh || stage == Stage::kAmplification;
    if (meshlet) return {.major = 6, .minor = 5};
    return kOldestModel;
}

[[nodiscard]] SlangStage stage_of(Stage stage) noexcept {
    switch (stage) {
    case Stage::kVertex: return SLANG_STAGE_VERTEX;
    case Stage::kHull: return SLANG_STAGE_HULL;
    case Stage::kDomain: return SLANG_STAGE_DOMAIN;
    case Stage::kGeometry: return SLANG_STAGE_GEOMETRY;
    case Stage::kPixel: return SLANG_STAGE_FRAGMENT;
    case Stage::kCompute: return SLANG_STAGE_COMPUTE;
    case Stage::kMesh: return SLANG_STAGE_MESH;
    case Stage::kAmplification: return SLANG_STAGE_AMPLIFICATION;
    case Stage::kLibrary: break;
    }
    return SLANG_STAGE_NONE;
}

// SPIR-V mà môi trường vulkan1.<minor> nhận: 1.0 nhận 1.0, 1.1 nhận 1.3, 1.2 nhận 1.5, 1.3 trở lên 1.6.
[[nodiscard]] std::string_view spirv_profile(std::uint8_t vulkan_minor) noexcept {
    if (vulkan_minor == 0) return "spirv_1_0";
    if (vulkan_minor == 1) return "spirv_1_3";
    if (vulkan_minor == 2) return "spirv_1_5";
    return "spirv_1_6";
}

[[nodiscard]] std::string profile_of(const CompileOptions& options) {
    if (options.target == Target::kSpirV) return std::string(spirv_profile(options.vulkan_minor));
    if (options.target == Target::kDxbc) return "sm_5_0";
    const ShaderModel model = std::max(options.model, least_model(options.stage));
    return std::format("sm_{}_{}", model.major, model.minor);
}

[[nodiscard]] std::string_view target_of(Target target) noexcept {
    if (target == Target::kSpirV) return "spirv";
    if (target == Target::kDxbc) return "dxbc";
    return "dxil";
}

// Define báo đích cho nguồn: F2_DXBC hạ register space về slot D3D11, F2_SPIRV bật push constant của Vulkan.
[[nodiscard]] std::string_view define_of(Target target) noexcept {
    if (target == Target::kSpirV) return "F2_SPIRV";
    if (target == Target::kDxbc) return "F2_DXBC";
    return "F2_DXIL";
}

[[nodiscard]] char upper(char letter) noexcept {
    const bool lower = letter >= 'a' && letter <= 'z';
    return lower ? static_cast<char>(letter - 'a' + 'A') : letter;
}

// "F2_STAGE_VS" cho Stage::kVertex.
[[nodiscard]] std::string stage_define(Stage stage) {
    std::string define = "F2_STAGE_";
    std::ranges::transform(tag(stage), std::back_inserter(define), upper);
    return define;
}

// Độ dịch binding của một lớp register, áp cho mọi register space.
void add_shift(std::vector<std::string>& args, char group, RegisterType type) {
    args.push_back(std::format("-fvk-{}-shift", group));
    args.push_back(std::to_string(binding_shift(type)));
    args.emplace_back("all");
}

void add_define(std::vector<std::string>& args, std::string_view define) {
    args.emplace_back("-D");
    args.emplace_back(define);
}

// Cờ dòng lệnh của slangc mà IGlobalSession::parseCommandLineArguments đổi thành SessionDesc. Entry,
// stage và tệp nguồn không nằm ở đây: chúng đi qua API.
[[nodiscard]] std::vector<std::string> arguments(const CompileOptions& options) {
    std::vector<std::string> args;
    args.emplace_back("-target");
    args.emplace_back(target_of(options.target));
    args.emplace_back("-profile");
    args.push_back(profile_of(options));
    args.emplace_back("-matrix-layout-column-major");
    if (options.strict) {
        args.emplace_back("-warnings-as-errors");
        args.emplace_back("all");
    }
    if (options.debug) {
        args.emplace_back("-O0");
        args.emplace_back("-g");
        add_define(args, "F2_DEBUG");
    } else {
        args.emplace_back("-O3");
    }
    if (options.target == Target::kSpirV) {
        args.emplace_back("-fvk-use-dx-layout");
        args.emplace_back("-fvk-use-entrypoint-name");
        args.emplace_back("-default-image-format-unknown");
        add_shift(args, 'b', RegisterType::kConstant);
        add_shift(args, 't', RegisterType::kResource);
        add_shift(args, 'u', RegisterType::kUnordered);
        add_shift(args, 's', RegisterType::kSampler);
    }
    add_define(args, define_of(options.target));
    add_define(args, stage_define(options.stage));
    for (const std::string& define : options.defines) {
        add_define(args, define);
    }
    for (const std::string& directory : options.include_dirs) {
        args.emplace_back("-I");
        args.push_back(directory);
    }
    return args;
}

[[nodiscard]] bool is_builtin(std::string_view path) noexcept {
    if (!path.ends_with(kBuiltinName)) return false;
    const std::size_t before = path.size() - kBuiltinName.size();
    return before == 0 || fs::is_separator(path.at(before - 1));
}

// Giao diện COM của Slang không khai destructor ảo, nên -Wnon-virtual-dtor của GCC báo hai lớp dưới
// đây. Cả hai không bao giờ bị xoá qua con trỏ giao diện: MemoryBlob tự xoá trong release() bằng
// kiểu cuối của nó, SourceFiles đứng trên stack.
#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnon-virtual-dtor"
#endif

// Vùng nhớ chỉ đọc cho Slang. Đối tượng COM sống trên heap, tự xoá khi bộ đếm về 0.
class MemoryBlob final : public ISlangBlob {
public:
    explicit MemoryBlob(std::string bytes) : bytes_(std::move(bytes)) {}

    SlangResult SLANG_MCALL queryInterface(const SlangUUID& uuid, void** object) noexcept override {
        if (object == nullptr) return SLANG_E_INVALID_ARG;
        const bool mine = uuid == ISlangUnknown::getTypeGuid() || uuid == ISlangBlob::getTypeGuid();
        *object = mine ? static_cast<ISlangBlob*>(this) : nullptr;
        if (!mine) return SLANG_E_NO_INTERFACE;
        addRef();
        return SLANG_OK;
    }

    uint32_t SLANG_MCALL addRef() noexcept override { return ++refs_; }

    uint32_t SLANG_MCALL release() noexcept override {
        const uint32_t left = --refs_;
        if (left == 0) delete this;
        return left;
    }

    const void* SLANG_MCALL getBufferPointer() noexcept override { return bytes_.data(); }
    size_t SLANG_MCALL getBufferSize() noexcept override { return bytes_.size(); }

private:
    std::string bytes_;
    std::atomic<uint32_t> refs_{1};
};

// Hệ thống tệp của một lần dịch. Đối tượng đứng trên stack và sống lâu hơn session, nên đếm tham
// chiếu không làm gì.
class SourceFiles final : public ISlangFileSystem {
public:
    SlangResult SLANG_MCALL queryInterface(const SlangUUID& uuid, void** object) noexcept override {
        if (object == nullptr) return SLANG_E_INVALID_ARG;
        void* const found = castAs(uuid);
        *object = found;
        return found == nullptr ? SLANG_E_NO_INTERFACE : SLANG_OK;
    }

    uint32_t SLANG_MCALL addRef() noexcept override { return 1; }
    uint32_t SLANG_MCALL release() noexcept override { return 1; }

    void* SLANG_MCALL castAs(const SlangUUID& guid) noexcept override {
        const bool mine = guid == ISlangUnknown::getTypeGuid() || guid == ISlangCastable::getTypeGuid() ||
            guid == ISlangFileSystem::getTypeGuid();
        return mine ? static_cast<ISlangFileSystem*>(this) : nullptr;
    }

    SlangResult SLANG_MCALL loadFile(const char* path, ISlangBlob** blob) noexcept override {
        if (path == nullptr || blob == nullptr) return SLANG_E_INVALID_ARG;
        // Ngoại lệ không được thoát qua ranh giới COM.
        try {
            return load(std::string_view(path), *blob);
        } catch (...) {
            return SLANG_E_OUT_OF_MEMORY;
        }
    }

    // Tệp include đã đọc, theo thứ tự gặp, không lặp.
    [[nodiscard]] std::vector<std::string> take_loaded() noexcept { return std::move(loaded_); }

private:
    [[nodiscard]] SlangResult load(std::string_view path, ISlangBlob*& blob) {
        // Tệp cùng tên trên đĩa không thay được phần dùng chung sẵn có.
        if (is_builtin(path)) {
            blob = new MemoryBlob(std::string(kBuiltinText)); // NOLINT(cppcoreguidelines-owning-memory): COM
            return SLANG_OK;
        }
        const Result<fs::Bytes> file = fs::read_file(path);
        if (!file) return SLANG_E_NOT_FOUND;
        const std::span<const std::byte> bytes = file->span();
        std::string text(bytes.size(), '\0');
        if (!bytes.empty()) std::memcpy(text.data(), bytes.data(), bytes.size());
        std::string normal = fs::normalize(path);
        if (std::ranges::find(loaded_, normal) == loaded_.end()) loaded_.push_back(std::move(normal));
        blob = new MemoryBlob(std::move(text)); // NOLINT(cppcoreguidelines-owning-memory): COM
        return SLANG_OK;
    }

    std::vector<std::string> loaded_;
};

#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

void note(std::string& messages, slang::IBlob* diagnostics) {
    if (diagnostics == nullptr || diagnostics->getBufferSize() == 0) return;
    messages.append(static_cast<const char*>(diagnostics->getBufferPointer()), diagnostics->getBufferSize());
}

[[nodiscard]] core::Failure refuse(std::string_view what, std::string_view messages) {
    return fail(ErrorCode::kInvalidArgument, "shader không dịch được", "{}: {}", what, messages);
}

// Mọi thứ Slang cấp cho một lần dịch. Khai theo thứ tự phụ thuộc: huỷ ngược lại nên module và
// component sống không lâu hơn session, session không lâu hơn hệ thống tệp.
struct Job {
    std::string messages;
    SourceFiles files;
    ComPtr<ISlangUnknown> allocation;
    ComPtr<slang::ISession> session;
    ComPtr<slang::IModule> module;
    ComPtr<slang::IEntryPoint> entry;
    ComPtr<slang::IComponentType> program;
    ComPtr<slang::IComponentType> linked;
    ComPtr<slang::IBlob> code;
};

[[nodiscard]] Status open_session(slang::IGlobalSession& global, Job& job, std::span<const char* const> argv) {
    slang::SessionDesc desc{};
    const SlangResult parsed =
        global.parseCommandLineArguments(static_cast<int>(argv.size()), argv.data(), &desc, job.allocation.writeRef());
    if (SLANG_FAILED(parsed)) return refuse("cờ dịch không hợp lệ", job.messages);
    desc.fileSystem = &job.files;
    if (SLANG_FAILED(global.createSession(desc, job.session.writeRef()))) {
        return fail(ErrorCode::kInternal, "Slang không tạo được session");
    }
    return ok();
}

[[nodiscard]] Status link_entry(Job& job, const SlangSource& source, const CompileOptions& options) {
    const std::string path(source.path);
    const std::string text(source.text);
    ComPtr<slang::IBlob> diagnostics;
    job.module = job.session->loadModuleFromSourceString("shader", path.c_str(), text.c_str(), diagnostics.writeRef());
    note(job.messages, diagnostics.get());
    if (job.module == nullptr) return refuse(path, job.messages);
    diagnostics = nullptr;
    const bool found = SLANG_SUCCEEDED(job.module->findAndCheckEntryPoint(options.entry.c_str(),
        stage_of(options.stage), job.entry.writeRef(), diagnostics.writeRef()));
    note(job.messages, diagnostics.get());
    if (!found) return refuse(options.entry, job.messages);
    diagnostics = nullptr;
    const std::array<slang::IComponentType*, 2> parts{job.module.get(), job.entry.get()};
    const auto part_count = static_cast<SlangInt>(parts.size());
    const bool composed = SLANG_SUCCEEDED(job.session->createCompositeComponentType(parts.data(), part_count,
        job.program.writeRef(), diagnostics.writeRef()));
    note(job.messages, diagnostics.get());
    if (!composed) return refuse(path, job.messages);
    diagnostics = nullptr;
    const bool linked = SLANG_SUCCEEDED(job.program->link(job.linked.writeRef(), diagnostics.writeRef()));
    note(job.messages, diagnostics.get());
    if (!linked) return refuse(path, job.messages);
    return ok();
}

[[nodiscard]] Status generate(Job& job, std::string_view path) {
    ComPtr<slang::IBlob> diagnostics;
    const bool made = SLANG_SUCCEEDED(job.linked->getEntryPointCode(0, 0, job.code.writeRef(), diagnostics.writeRef()));
    note(job.messages, diagnostics.get());
    if (!made || job.code == nullptr) return refuse(path, job.messages);
    return ok();
}

} // namespace

struct SlangCompiler::State {
    // Thứ tự khai báo: module huỷ sau cùng, sau mọi thứ lấy từ nó.
    Library module;
    ComPtr<slang::IGlobalSession> global;
    std::string version;
    std::string library;
    // Slang không bảo đảm an toàn luồng khi nhiều lần dịch chạy cùng lúc trên một global session.
    std::mutex serial;
};

SlangCompiler::SlangCompiler(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
SlangCompiler::SlangCompiler(SlangCompiler&&) noexcept = default;
SlangCompiler& SlangCompiler::operator=(SlangCompiler&&) noexcept = default;
SlangCompiler::~SlangCompiler() = default;

Result<SlangCompiler> SlangCompiler::create() {
    auto state = std::make_unique<State>();
    for (const std::filesystem::path& path : library_candidates(L"slang.dll")) {
        state->module = open_library(path);
        if (state->module != nullptr) state->library = core::narrow(path.wstring());
        if (state->module != nullptr) break;
    }
    if (state->module == nullptr) {
        const std::string_view where = "đặt cạnh exe hoặc cài Vulkan SDK (biến VULKAN_SDK)";
        return fail(ErrorCode::kUnsupported, "không tìm thấy slang.dll", where);
    }
    using CreateGlobal = SlangResult (*)(const SlangGlobalSessionDesc*, slang::IGlobalSession**);
    const auto create = find_symbol<CreateGlobal>(state->module, "slang_createGlobalSession2");
    if (create == nullptr) {
        return fail(ErrorCode::kUnsupported, "DLL không có slang_createGlobalSession2", state->library);
    }
    const SlangGlobalSessionDesc desc{};
    if (SLANG_FAILED(create(&desc, state->global.writeRef())) || state->global == nullptr) {
        return fail(ErrorCode::kUnsupported, "Slang không dựng được global session", state->library);
    }
    state->version = std::format("slang {}", state->global->getBuildTagString());
    return SlangCompiler(std::move(state));
}

Result<Translated> SlangCompiler::translate(const SlangSource& source, const CompileOptions& options) const {
    if (options.target == Target::kGlsl)
        return fail(ErrorCode::kUnsupported, "GLSL của GLES viết tay, không đi qua Slang");
    if (stage_of(options.stage) == SLANG_STAGE_NONE) {
        return fail(ErrorCode::kUnsupported, "Slang chưa dịch stage này", tag(options.stage));
    }
    const std::vector<std::string> args = arguments(options);
    std::vector<const char*> argv(args.size());
    std::ranges::transform(args, argv.begin(), &std::string::c_str);
    const std::scoped_lock lock(state_->serial);
    Job job;
    if (Status opened = open_session(*state_->global, job, argv); !opened) return pass(opened);
    if (Status linked = link_entry(job, source, options); !linked) return pass(linked);
    if (Status made = generate(job, source.path); !made) return pass(made);
    Translated translated;
    const std::span<const std::byte> bytes(
        static_cast<const std::byte*>(job.code->getBufferPointer()), job.code->getBufferSize());
    translated.code.assign(bytes.begin(), bytes.end());
    translated.messages = std::move(job.messages);
    translated.dependencies = job.files.take_loaded();
    return translated;
}

std::string_view SlangCompiler::version() const noexcept {
    return state_->version;
}

std::string_view SlangCompiler::library() const noexcept {
    return state_->library;
}

} // namespace game::shader::detail
