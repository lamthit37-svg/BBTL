/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/system.hpp
 *  PHÂN HỆ   : Core / System
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thông tin máy: CPU, tải từng CPU logic, hệ điều hành. Thay CPUConfig
 *    (_Ref, dựa thư viện cpu_features chép vào gốc) bằng __cpuid trực tiếp có
 *    kiểm hệ điều hành bật trạng thái AVX (XGETBV); PerformanceStats (WMI qua
 *    COM, gọi CoInitializeSecurity cho cả tiến trình, chờ 15 ms mỗi CPU) bằng
 *    NtQuerySystemInformation; OSInfo ("Unknown" cứng cho tên máy) bằng
 *    RtlGetVersion và tên máy thật.
 *  - Nguồn: Forge2 src/core/system.hpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k; bỏ {} thừa của các thành viên chuỗi và bitset trong CpuInfo, OsInfo.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/error.hpp"

#include <bitset>
#include <cstdint>
#include <filesystem>
#include <initializer_list>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::core {

// Mức SIMD cao nhất CPU và hệ điều hành cùng hỗ trợ (SimdIntrinsic của _Ref, thêm AVX-512).
enum class Simd : std::uint8_t {
    kNone,
    kSse3,
    kSse41,
    kSse42,
    kAvx,
    kAvx2,
    kAvx512,
};

enum class CpuFeature : std::uint8_t {
    kSse3,
    kSsse3,
    kSse41,
    kSse42,
    kPopcnt,
    kAes,
    kPclmul,
    kMovbe,
    kAvx,
    kF16c,
    kFma,
    kAvx2,
    kBmi1,
    kBmi2,
    kLzcnt,
    kSha,
    kAvx512f,
    kAvx512dq,
    kAvx512bw,
    kAvx512vl,
    kCount,
};

struct CpuInfo {
    // "GenuineIntel", "AuthenticAMD".
    std::string vendor;
    std::string name;
    // Họ và model đã cộng phần mở rộng.
    std::uint32_t family = 0;
    std::uint32_t model = 0;
    std::uint32_t stepping = 0;
    // "Intel Raptor Lake", "AMD Zen 4"; rỗng khi CPU mới hơn bảng (core/uarch.hpp).
    std::string_view microarchitecture;
    Simd simd = Simd::kNone;
    std::bitset<std::to_underlying(CpuFeature::kCount)> features;

    [[nodiscard]] bool has(CpuFeature feature) const { return features.test(std::to_underlying(feature)); }
};

[[nodiscard]] CpuInfo cpu_info();

[[nodiscard]] std::string_view simd_name(Simd simd) noexcept;

// Tên cờ như nhà sản xuất viết: "SSE4.1", "AVX2", "AVX-512F".
[[nodiscard]] std::string_view name(CpuFeature feature) noexcept;

// Kiểm CPU và hệ điều hành đủ các cờ mà mã đã dịch cần; thiếu thì Unsupported kèm tên CPU và các cờ
// thiếu. Thiếu cờ thì lệnh đầu tiên dùng nó là lỗi lệnh không hợp lệ, không một thông điệp nào: gọi
// một lần ở đầu chương trình, trước mọi mã dùng chúng (math dựng trên SSE4.1). Bản hai tham số kiểm
// một CpuInfo cho sẵn, để thử đường lỗi mà không cần máy thiếu cờ.
[[nodiscard]] Status require_cpu(std::initializer_list<CpuFeature> required);
[[nodiscard]] Status require_cpu(const CpuInfo& info, std::initializer_list<CpuFeature> required);

// Tải từng CPU logic giữa hai lần sample (getPerformanceStats của _Ref), mọi nhóm bộ xử lý, thứ tự
// như chỉ số của CpuSet. Lần đầu tính từ lúc khởi động máy. Một luồng sở hữu một đối tượng.
class CpuUsage {
public:
    // Phần trăm bận 0–100 của từng CPU logic; CPU của nhóm bị hệ điều hành từ chối báo 0.
    [[nodiscard]] std::vector<float> sample();

private:
    struct Times {
        std::int64_t idle = 0;
        std::int64_t total = 0;
    };

    void record_group(std::uint16_t group, std::vector<float>& usage);
    void record(Times now, std::vector<float>& usage);
#if !defined(_WIN32)
    // Một dòng cpuN của /proc/stat. Bản Apple không gọi.
    void note_stat(std::string_view line, std::vector<float>& usage);
#endif

    std::vector<Times> last_;
};

struct OsInfo {
    // "Windows 11", "Windows 10".
    std::string name;
    // "10.0.26200".
    std::string version;
    // Tên máy (DNS); _Ref ghi cứng "Unknown".
    std::string device;
};

[[nodiscard]] OsInfo os_info();

// Đường dẫn đầy đủ của exe đang chạy, không giới hạn MAX_PATH. PathStatement, tệp log mặc định và
// báo cáo crash tính theo thư mục exe chứ không theo thư mục làm việc (_Ref mở PathStatement theo
// CWD).
[[nodiscard]] std::filesystem::path exe_path();
[[nodiscard]] std::filesystem::path exe_directory();

} // namespace game::core
