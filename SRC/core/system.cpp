// Vị trí bit CPUID theo Intel SDM tập 2A (lệnh CPUID) và AMD APM tập 3. Một cờ AVX chỉ bật khi hệ
// điều hành lưu thanh ghi YMM (hay ZMM cho AVX-512) lúc đổi luồng: CPU có AVX mà Windows chưa bật
// XSAVE thì lệnh AVX là lỗi #UD. mSimd của _Ref suy từ cờ CPU; cpu_features mới kiểm XCR0,
// CPUConfig không.
// Nguồn: Forge2 src/core/system.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của
// windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp; check
// là bản của THIENLONG; enabled_states mang thuộc tính target xsave cho GCC và để auto cho xcr0;
// thân vòng lặp của require_cpu và exe_path tách thành hàm một lượt (ghi tại chỗ); lệnh return kèm
// lời gọi hàm void tách làm hai; hai biến cục bộ của brand thêm const.
#include "core/system.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "core/text.hpp"
#include "core/uarch.hpp"
#if defined(_WIN32)
#include "core/win32.hpp" // IWYU pragma: keep

#include <intrin.h>
#include <libloaderapi.h>
#include <sysinfoapi.h>
#include <winbase.h>
#include <winnt.h>
#include <winternl.h>
#endif

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <initializer_list>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#if defined(_WIN32)
// Hai hàm của ntdll không có trong header chế độ người dùng nên khai tay; liên kết qua ntdll.lib.
// Tên giữ đúng chính tả của ntdll (hiến pháp IV.1).
// NOLINTBEGIN(readability-identifier-naming)
extern "C" NTSYSAPI NTSTATUS NTAPI RtlGetVersion(PRTL_OSVERSIONINFOW version);
extern "C" NTSYSAPI NTSTATUS NTAPI NtQuerySystemInformationEx(SYSTEM_INFORMATION_CLASS type, PVOID input,
    ULONG input_size, PVOID output, ULONG output_size, PULONG returned);
// NOLINTEND(readability-identifier-naming)
#endif

namespace game::core {

#if defined(_WIN32)

namespace {

using Registers = std::array<int, 4>;

constexpr std::size_t kEax = 0;
constexpr std::size_t kEbx = 1;
constexpr std::size_t kEcx = 2;
constexpr std::size_t kEdx = 3;

// Lá CPUID và thanh ghi chứa cờ.
enum class Source : std::uint8_t {
    kLeaf1Ecx,
    kLeaf7Ebx,
    kExtended1Ecx,
};

// Trạng thái thanh ghi hệ điều hành phải lưu khi đổi luồng.
enum class State : std::uint8_t {
    kNone,
    kYmm,
    kZmm,
};

struct Probe {
    CpuFeature feature = CpuFeature::kCount;
    Source source = Source::kLeaf1Ecx;
    int bit = 0;
    State state = State::kNone;
};

constexpr auto kProbes = std::to_array<Probe>({
    {.feature = CpuFeature::kSse3, .source = Source::kLeaf1Ecx, .bit = 0, .state = State::kNone},
    {.feature = CpuFeature::kPclmul, .source = Source::kLeaf1Ecx, .bit = 1, .state = State::kNone},
    {.feature = CpuFeature::kSsse3, .source = Source::kLeaf1Ecx, .bit = 9, .state = State::kNone},
    {.feature = CpuFeature::kFma, .source = Source::kLeaf1Ecx, .bit = 12, .state = State::kYmm},
    {.feature = CpuFeature::kSse41, .source = Source::kLeaf1Ecx, .bit = 19, .state = State::kNone},
    {.feature = CpuFeature::kSse42, .source = Source::kLeaf1Ecx, .bit = 20, .state = State::kNone},
    {.feature = CpuFeature::kMovbe, .source = Source::kLeaf1Ecx, .bit = 22, .state = State::kNone},
    {.feature = CpuFeature::kPopcnt, .source = Source::kLeaf1Ecx, .bit = 23, .state = State::kNone},
    {.feature = CpuFeature::kAes, .source = Source::kLeaf1Ecx, .bit = 25, .state = State::kNone},
    {.feature = CpuFeature::kAvx, .source = Source::kLeaf1Ecx, .bit = 28, .state = State::kYmm},
    {.feature = CpuFeature::kF16c, .source = Source::kLeaf1Ecx, .bit = 29, .state = State::kYmm},
    {.feature = CpuFeature::kBmi1, .source = Source::kLeaf7Ebx, .bit = 3, .state = State::kNone},
    {.feature = CpuFeature::kAvx2, .source = Source::kLeaf7Ebx, .bit = 5, .state = State::kYmm},
    {.feature = CpuFeature::kBmi2, .source = Source::kLeaf7Ebx, .bit = 8, .state = State::kNone},
    {.feature = CpuFeature::kAvx512f, .source = Source::kLeaf7Ebx, .bit = 16, .state = State::kZmm},
    {.feature = CpuFeature::kAvx512dq, .source = Source::kLeaf7Ebx, .bit = 17, .state = State::kZmm},
    {.feature = CpuFeature::kSha, .source = Source::kLeaf7Ebx, .bit = 29, .state = State::kNone},
    {.feature = CpuFeature::kAvx512bw, .source = Source::kLeaf7Ebx, .bit = 30, .state = State::kZmm},
    {.feature = CpuFeature::kAvx512vl, .source = Source::kLeaf7Ebx, .bit = 31, .state = State::kZmm},
    {.feature = CpuFeature::kLzcnt, .source = Source::kExtended1Ecx, .bit = 5, .state = State::kNone},
});

struct Rung {
    CpuFeature feature = CpuFeature::kCount;
    Simd simd = Simd::kNone;
};

// Bậc SIMD từ cao xuống; bậc đầu tiên CPU có là mức của máy.
constexpr auto kLadder = std::to_array<Rung>({
    {.feature = CpuFeature::kAvx512f, .simd = Simd::kAvx512},
    {.feature = CpuFeature::kAvx2, .simd = Simd::kAvx2},
    {.feature = CpuFeature::kAvx, .simd = Simd::kAvx},
    {.feature = CpuFeature::kSse42, .simd = Simd::kSse42},
    {.feature = CpuFeature::kSse41, .simd = Simd::kSse41},
    {.feature = CpuFeature::kSse3, .simd = Simd::kSse3},
});

[[nodiscard]] Registers cpuid(std::uint32_t leaf) {
    Registers result{};
    __cpuidex(result.data(), static_cast<int>(leaf), 0);
    return result;
}

[[nodiscard]] bool bit(int value, int index) noexcept {
    return ((static_cast<unsigned int>(value) >> index) & 1U) != 0;
}

[[nodiscard]] std::uint32_t highest(std::uint32_t base) {
    return static_cast<std::uint32_t>(cpuid(base).at(kEax));
}

// Lá 0: tên hãng nằm ở EBX, EDX, ECX theo thứ tự đó.
[[nodiscard]] std::string vendor_of(const Registers& leaf0) {
    const std::array<int, 3> parts{leaf0.at(kEbx), leaf0.at(kEdx), leaf0.at(kEcx)};
    const auto chars = std::bit_cast<std::array<char, 12>>(parts);
    return {chars.begin(), chars.end()};
}

// Chuỗi thương hiệu 48 byte ở lá 0x80000002–0x80000004, đệm khoảng trắng và byte 0 hai đầu.
[[nodiscard]] std::string brand() {
    constexpr std::uint32_t kFirst = 0x80000002;
    if (highest(0x80000000) < kFirst + 2) return {};
    const std::array<Registers, 3> leaves{cpuid(kFirst), cpuid(kFirst + 1), cpuid(kFirst + 2)};
    const auto chars = std::bit_cast<std::array<char, 48>>(leaves);
    const std::string text(chars.begin(), std::ranges::find(chars, '\0'));
    const std::size_t first = text.find_first_not_of(' ');
    if (first == std::string::npos) return {};
    return text.substr(first, text.find_last_not_of(' ') - first + 1);
}

// Họ và model hiển thị theo SDM: họ 0xF cộng họ mở rộng; họ 6 và 0xF cộng model mở rộng.
void read_signature(int eax, CpuInfo& info) {
    const auto value = static_cast<std::uint32_t>(eax);
    const std::uint32_t family = (value >> 8U) & 0xFU;
    const std::uint32_t model = (value >> 4U) & 0xFU;
    const bool extended = family == 0x6U || family == 0xFU;
    info.family = family == 0xFU ? family + ((value >> 20U) & 0xFFU) : family;
    info.model = extended ? model + (((value >> 16U) & 0xFU) << 4U) : model;
    info.stepping = value & 0xFU;
}

// Thanh ghi hệ điều hành đã bật trong XCR0: bit 1–2 (SSE, AVX) cho YMM, thêm 5–7 (opmask, ZMM) cho
// ZMM.
// Khác gốc: GCC chỉ cho gọi _xgetbv trong hàm bật tập lệnh xsave (gốc chỉ dịch bằng MSVC); lệnh
// chỉ chạy khi CPUID báo OSXSAVE, như gốc. xcr0 ở gốc khai unsigned long long; _xgetbv của GCC trả
// long long, nên để auto: hai phép so bit dưới đây cho cùng kết quả với cả hai kiểu.
#if !defined(_MSC_VER)
[[gnu::target("xsave")]]
#endif
[[nodiscard]] std::array<bool, 3> enabled_states(int leaf1_ecx) {
    constexpr int kOsXsave = 27;
    const auto xcr0 = bit(leaf1_ecx, kOsXsave) ? _xgetbv(0) : 0;
    return {true, (xcr0 & 0x6U) == 0x6U, (xcr0 & 0xE6U) == 0xE6U};
}

[[nodiscard]] bool supported(const Probe& probe, const std::array<int, 3>& words, const std::array<bool, 3>& states) {
    const int word = words.at(std::to_underlying(probe.source));
    return bit(word, probe.bit) && states.at(std::to_underlying(probe.state));
}

[[nodiscard]] std::string computer_name() {
    DWORD size = 0;
    GetComputerNameExW(ComputerNameDnsHostname, nullptr, &size);
    std::wstring name(size, L'\0');
    if (GetComputerNameExW(ComputerNameDnsHostname, name.data(), &size) == 0) return {};
    name.resize(size);
    return narrow(name);
}

} // namespace

CpuInfo cpu_info() {
    CpuInfo info;
    const Registers leaf0 = cpuid(0);
    const auto top = static_cast<std::uint32_t>(leaf0.at(kEax));
    const Registers leaf1 = cpuid(1);
    const int leaf7_ebx = top >= 7 ? cpuid(7).at(kEbx) : 0;
    const int extended_ecx = highest(0x80000000) >= 0x80000001 ? cpuid(0x80000001).at(kEcx) : 0;
    const std::array<int, 3> words{leaf1.at(kEcx), leaf7_ebx, extended_ecx};
    const std::array<bool, 3> states = enabled_states(leaf1.at(kEcx));
    for (const Probe& probe : kProbes) {
        info.features.set(std::to_underlying(probe.feature), supported(probe, words, states));
    }
    info.vendor = vendor_of(leaf0);
    info.name = brand();
    read_signature(leaf1.at(kEax), info);
    info.microarchitecture = microarchitecture(info.vendor, info.family, info.model, info.stepping);
    const auto rung = std::ranges::find_if(kLadder, [&](const Rung& step) { return info.has(step.feature); });
    info.simd = rung == kLadder.end() ? Simd::kNone : rung->simd;
    return info;
}

#endif

std::string_view simd_name(Simd simd) noexcept {
    switch (simd) {
    case Simd::kNone: return "không";
    case Simd::kSse3: return "SSE3";
    case Simd::kSse41: return "SSE4.1";
    case Simd::kSse42: return "SSE4.2";
    case Simd::kAvx: return "AVX";
    case Simd::kAvx2: return "AVX2";
    case Simd::kAvx512: return "AVX-512";
    }
    std::unreachable();
}

std::string_view name(CpuFeature feature) noexcept {
    switch (feature) {
    case CpuFeature::kSse3: return "SSE3";
    case CpuFeature::kSsse3: return "SSSE3";
    case CpuFeature::kSse41: return "SSE4.1";
    case CpuFeature::kSse42: return "SSE4.2";
    case CpuFeature::kPopcnt: return "POPCNT";
    case CpuFeature::kAes: return "AES";
    case CpuFeature::kPclmul: return "PCLMULQDQ";
    case CpuFeature::kMovbe: return "MOVBE";
    case CpuFeature::kAvx: return "AVX";
    case CpuFeature::kF16c: return "F16C";
    case CpuFeature::kFma: return "FMA";
    case CpuFeature::kAvx2: return "AVX2";
    case CpuFeature::kBmi1: return "BMI1";
    case CpuFeature::kBmi2: return "BMI2";
    case CpuFeature::kLzcnt: return "LZCNT";
    case CpuFeature::kSha: return "SHA";
    case CpuFeature::kAvx512f: return "AVX-512F";
    case CpuFeature::kAvx512dq: return "AVX-512DQ";
    case CpuFeature::kAvx512bw: return "AVX-512BW";
    case CpuFeature::kAvx512vl: return "AVX-512VL";
    case CpuFeature::kCount: break;
    }
    return "?";
}

namespace {

// Khác gốc: thân vòng lặp của require_cpu tách ra đây; gốc viết continue khi CPU có cờ.
void note_missing(const CpuInfo& info, CpuFeature feature, std::string& missing) {
    check(feature != CpuFeature::kCount, "require_cpu: CpuFeature::kCount không phải cờ");
    if (info.has(feature)) return;
    if (!missing.empty()) missing += ", ";
    missing += name(feature);
}

} // namespace

Status require_cpu(const CpuInfo& info, std::initializer_list<CpuFeature> required) {
    std::string missing;
    for (const CpuFeature feature : required) {
        note_missing(info, feature, missing);
    }
    if (missing.empty()) return ok();
    return fail(ErrorCode::kUnsupported, "CPU thiếu tập lệnh bắt buộc", "{}: thiếu {}", info.name, missing);
}

Status require_cpu(std::initializer_list<CpuFeature> required) {
    return require_cpu(cpu_info(), required);
}

#if defined(_WIN32)

std::vector<float> CpuUsage::sample() {
    std::vector<float> usage;
    const WORD groups = GetActiveProcessorGroupCount();
    for (WORD group = 0; group < groups; ++group) {
        record_group(group, usage);
    }
    return usage;
}

// Bản Ex nhận số nhóm làm đầu vào; bản thường chỉ trả nhóm của luồng gọi, tối đa 64 CPU.
void CpuUsage::record_group(std::uint16_t group, std::vector<float>& usage) {
    std::array<SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION, 64> cores{};
    USHORT input = group;
    ULONG bytes = 0;
    const auto room = static_cast<ULONG>(sizeof(cores));
    const NTSTATUS status = NtQuerySystemInformationEx(SystemProcessorPerformanceInformation, &input, sizeof(input),
        cores.data(), room, &bytes);
    // Nhóm bị từ chối vẫn giữ chỗ: chỉ số của các nhóm sau phải khớp CpuSet.
    // Khác gốc: gốc viết return usage.resize(...) trên một dòng.
    if (status < 0) {
        usage.resize(usage.size() + GetActiveProcessorCount(group), 0.0F);
        return;
    }
    const std::size_t count = bytes / sizeof(cores.front());
    for (std::size_t i = 0; i < count; ++i) {
        const SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION& core = cores.at(i);
        const std::int64_t total = core.KernelTime.QuadPart + core.UserTime.QuadPart;
        record(Times{.idle = core.IdleTime.QuadPart, .total = total}, usage);
    }
}

#endif

namespace {

// idle đã nằm trong total.
[[nodiscard]] float busy_percent(std::int64_t idle, std::int64_t total) {
    if (total <= 0) return 0.0F;
    const double busy = 1.0 - (static_cast<double>(idle) / static_cast<double>(total));
    return static_cast<float>(std::clamp(busy, 0.0, 1.0) * 100.0);
}

} // namespace

void CpuUsage::record(Times now, std::vector<float>& usage) {
    const std::size_t index = usage.size();
    if (last_.size() <= index) last_.resize(index + 1);
    Times& last = last_.at(index);
    usage.push_back(busy_percent(now.idle - last.idle, now.total - last.total));
    last = now;
}

#if defined(_WIN32)

// GetModuleFileNameW cắt câm khi bộ đệm nhỏ; nhân đôi tới khi vừa, trần 32 767 ký tự của Win32
// cộng ký tự kết thúc. Lần nhân đôi cuối kẹp ở trần chứ không nhảy qua nó: đường dẫn dài hơn 16 639
// ký tự vẫn được thử ở cỡ 32 768.
// Khác gốc: gốc viết một vòng while (true) với ba câu if trong thân; ở đây mỗi lượt thử là một lời
// gọi try_exe_path, thứ tự các phép kiểm và lần nhân đôi giữ nguyên.
namespace {

using ExePath = std::optional<std::filesystem::path>;

// Một lượt thử với bộ đệm path. nullopt: bộ đệm nhỏ, đã nhân đôi để thử lại. Đường dẫn rỗng: lỗi,
// hoặc bộ đệm đã ở trần mà vẫn không vừa.
[[nodiscard]] ExePath try_exe_path(std::wstring& path) {
    constexpr std::size_t kLargest = 32768;
    const auto room = static_cast<DWORD>(path.size());
    const DWORD length = GetModuleFileNameW(nullptr, path.data(), room);
    if (length == 0) return std::filesystem::path();
    if (length < room) return std::filesystem::path(path.substr(0, length));
    if (path.size() >= kLargest) return std::filesystem::path();
    path.resize(std::min(path.size() * 2, kLargest));
    return std::nullopt;
}

} // namespace

std::filesystem::path exe_path() {
    std::wstring path(MAX_PATH, L'\0');
    ExePath found = try_exe_path(path);
    while (!found) {
        found = try_exe_path(path);
    }
    return std::move(*found);
}

OsInfo os_info() {
    RTL_OSVERSIONINFOW version{};
    version.dwOSVersionInfoSize = sizeof(version);
    if (RtlGetVersion(&version) < 0) return {};
    const DWORD major = version.dwMajorVersion;
    const DWORD build = version.dwBuildNumber;
    // Windows 11 vẫn báo 10.0; phân biệt bằng số build từ 22000.
    const bool eleven = major == 10 && build >= 22000;
    const std::string modern = eleven ? "Windows 11" : "Windows 10";
    return OsInfo{
        .name = major == 10 ? modern : std::format("Windows {}.{}", major, version.dwMinorVersion),
        .version = std::format("{}.{}.{}", major, version.dwMinorVersion, build),
        .device = computer_name(),
    };
}

#endif

std::filesystem::path exe_directory() {
    return exe_path().parent_path();
}

} // namespace game::core
