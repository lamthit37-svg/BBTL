// Số đo của một tiến trình máy chủ: bộ đếm, mức đo và biểu đồ thời gian từng pha. Danh mục cố định
// lúc biên dịch (không đăng ký động, không nhãn động: nhãn nằm trong tên, như gate.drop.rate), nên
// tăng một số chỉ là một phép cộng atomic vào ô cấp sẵn: không cấp phát, không khoá, gọi được trong
// tick. Bên ngoài đọc qua một ảnh chụp văn bản (metrics/serve gửi nó qua loopback); mọi bên đọc
// dùng chung parse_snapshot, bộ đọc có trần cứng vì ảnh chụp tới từ socket và tệp.
// Thứ tự nhớ là relaxed: mỗi số tự nhất quán, một lần chụp KHÔNG hứa hai số thuộc cùng một thời điểm.
// Nguồn thiết kế: TLBB Dev docs/GM.md và docs/LOGIC.md (bộ đếm u64 và biểu đồ cố định, cập nhật
// trong tick, đồng hồ do bên gọi đo); Dev chưa có mã. Đặc tả: thienlong-specs/coder-server/metrics.md.
// Số tự đặt, không có nguồn: bề rộng và số cột biểu đồ, bốn trần danh mục.
#pragma once

#include "core/effects.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>
#include <utility>

namespace game::metrics {

// Mười sáu lý do ngắt đứng đầu theo đúng thứ tự gate::Drop (gate/table.hpp buộc hai bên bằng
// static_assert): thêm một lý do thì thêm ở cả hai nơi, ngay trước kGateAcceptTotal.
enum class Counter : std::uint8_t {
    kGateDropHandshake,
    kGateDropIdle,
    kGateDropRate,
    kGateDropFrame,
    kGateDropProtocol,
    kGateDropSecure,
    kGateDropFull,
    kGateDropPerIp,
    kGateDropDenied,
    kGateDropSlow,
    kGateDropForeign,
    kGateDropVersion,
    kGateDropLogout,
    kGateDropClosed,
    kGateDropStop,
    kGateDropLocal,
    kGateAcceptTotal,
    kGateAcceptError,
    kGateAdmitOk,
    kGateHandshakeDone,
    kGateClosedOverflow,
    kGateTickTotal,
    kGateTickOverrun,
    kGateTickSkipped,
    kMetricsReaderDropped,
    kCount,
};

enum class Gauge : std::uint8_t {
    kGateLive,
    kGateListening,
    kGateHandshakePerTick,
    kCount,
};

enum class Phase : std::uint8_t {
    kGateWait,
    kGateResume,
    kGateAccept,
    kGatePump,
    kGateAdvance,
    kGateFlush,
    kGateTick,
    kCount,
};

inline constexpr std::size_t kCounterCount = std::to_underlying(Counter::kCount);
inline constexpr std::size_t kGaugeCount = std::to_underlying(Gauge::kCount);
inline constexpr std::size_t kPhaseCount = std::to_underlying(Phase::kCount);

// Biểu đồ pha: kPhaseBucketCount cột tuyến tính, mỗi cột rộng kPhaseBucketWidthUs, đóng bên phải
// (cột i chứa (i × 100 µs, (i + 1) × 100 µs], 0 ns vào cột 0), thêm một cột tràn cho mọi thứ trên
// kPhaseCeilingUs. Ba hằng này mô tả trọn biểu đồ cho bên đọc.
inline constexpr std::uint32_t kPhaseBucketWidthUs = 100;
inline constexpr std::uint32_t kPhaseBucketCount = 2000;
inline constexpr std::uint32_t kPhaseCeilingUs = kPhaseBucketWidthUs * kPhaseBucketCount;

// Trần của ảnh chụp: bộ đọc từ chối mọi thứ vượt các số này.
inline constexpr std::size_t kMaxNameBytes = 64;
inline constexpr std::size_t kMaxCounters = 256;
inline constexpr std::size_t kMaxGauges = 64;
inline constexpr std::size_t kMaxPhases = 16;
// Số chữ số nhiều nhất của một số trong ảnh chụp: UINT64_MAX có 20, INT64_MIN có 19 và một dấu trừ.
inline constexpr std::size_t kMaxNumberBytes = 20;

// Số byte nhiều nhất của một ảnh chụp đúng ngữ pháp (mọi dòng dài nhất, mọi cột có mặt, chỉ số
// cột viết đủ bốn chữ số).
[[nodiscard]] constexpr std::size_t snapshot_bound() noexcept {
    constexpr std::size_t kHead = 10; // "metrics 1\n"
    constexpr std::size_t kTail = 4;  // "end\n"
    constexpr std::size_t kCounterLine = 8 + kMaxNameBytes + 1 + kMaxNumberBytes + 1;
    constexpr std::size_t kGaugeLine = 6 + kMaxNameBytes + 1 + kMaxNumberBytes + 1;
    constexpr std::size_t kBucketField = 2 + 4 + 1 + kMaxNumberBytes; // " b" chỉ số "=" số
    constexpr std::size_t kPhaseHead = 6 + kMaxNameBytes + 7 + kMaxNumberBytes + 8 + kMaxNumberBytes + 8 + kMaxNumberBytes;
    constexpr std::size_t kPhaseLine = kPhaseHead + (kPhaseBucketCount * kBucketField) + 6 + kMaxNumberBytes + 1;
    return kHead + (kMaxCounters * kCounterLine) + (kMaxGauges * kGaugeLine) + (kMaxPhases * kPhaseLine) + kTail;
}
inline constexpr std::size_t kSnapshotMaxBytes = snapshot_bound();
// Số viết ra để ai đổi một trần thì phải đổi cả tài liệu và -max_len của đích fuzz.
static_assert(kSnapshotMaxBytes == 896846);

// Tên hợp lệ: 1..kMaxNameBytes ký tự trong [a-z0-9_.].
[[nodiscard]] constexpr bool is_name(std::string_view text) noexcept {
    if (text.empty() || text.size() > kMaxNameBytes) return false;
    const auto allowed = [](char one) {
        const bool lower = one >= 'a' && one <= 'z';
        const bool digit = one >= '0' && one <= '9';
        return lower || digit || one == '_' || one == '.';
    };
    return std::ranges::all_of(text, allowed);
}

inline constexpr std::array<std::string_view, kCounterCount> kCounterNames{
    "gate.drop.handshake",
    "gate.drop.idle",
    "gate.drop.rate",
    "gate.drop.frame",
    "gate.drop.protocol",
    "gate.drop.secure",
    "gate.drop.full",
    "gate.drop.per_ip",
    "gate.drop.denied",
    "gate.drop.slow",
    "gate.drop.foreign",
    "gate.drop.version",
    "gate.drop.logout",
    "gate.drop.closed",
    "gate.drop.stop",
    "gate.drop.local",
    "gate.accept.total",
    "gate.accept.error",
    "gate.admit.ok",
    "gate.handshake.done",
    "gate.closed.overflow",
    "gate.tick.total",
    "gate.tick.overrun",
    "gate.tick.skipped",
    "metrics.reader.dropped",
};

inline constexpr std::array<std::string_view, kGaugeCount> kGaugeNames{
    "gate.live",
    "gate.listening",
    "gate.handshake.per_tick",
};

inline constexpr std::array<std::string_view, kPhaseCount> kPhaseNames{
    "gate.phase.wait",  "gate.phase.resume",  "gate.phase.accept", "gate.phase.pump",
    "gate.phase.advance", "gate.phase.flush", "gate.phase.tick",
};

namespace detail {

// Mọi tên hợp lệ và không tên nào lặp trong bảng.
template <std::size_t Size>
[[nodiscard]] constexpr bool names_ok(std::array<std::string_view, Size> names) noexcept {
    if (!std::ranges::all_of(names, is_name)) return false;
    std::ranges::sort(names);
    return std::ranges::adjacent_find(names) == names.end();
}

// Tên ở ô index; ngoài bảng là chuỗi rỗng.
template <std::size_t Size>
[[nodiscard]] constexpr std::string_view name_at(const std::array<std::string_view, Size>& names,
    std::size_t index) noexcept {
    if (index >= Size) return {};
    return std::span{names}[index];
}

} // namespace detail

static_assert(kCounterCount <= kMaxCounters && kGaugeCount <= kMaxGauges && kPhaseCount <= kMaxPhases);
static_assert(detail::names_ok(kCounterNames) && detail::names_ok(kGaugeNames) && detail::names_ok(kPhaseNames));

// Tên trong ảnh chụp. kCount (không phải một số đo) trả chuỗi rỗng.
[[nodiscard]] constexpr std::string_view name_of(Counter which) noexcept {
    return detail::name_at(kCounterNames, std::to_underlying(which));
}
[[nodiscard]] constexpr std::string_view name_of(Gauge which) noexcept {
    return detail::name_at(kGaugeNames, std::to_underlying(which));
}
[[nodiscard]] constexpr std::string_view name_of(Phase which) noexcept {
    return detail::name_at(kPhaseNames, std::to_underlying(which));
}

// Tên một dòng của ảnh chụp, chép vào chỗ cấp sẵn để ảnh chụp không mượn bộ đệm nào.
class Name {
public:
    [[nodiscard]] std::string_view view() const noexcept { return std::string_view{bytes_.data(), size_}; }
    // false và giữ nguyên tên cũ khi text không phải tên hợp lệ (is_name).
    [[nodiscard]] bool assign(std::string_view text) noexcept;

private:
    std::array<char, kMaxNameBytes> bytes_{};
    std::size_t size_ = 0;
};

struct CounterRow {
    Name name;
    std::uint64_t value = 0;
};

struct GaugeRow {
    Name name;
    std::int64_t value = 0;
};

struct PhaseRow {
    Name name;
    std::uint64_t count = 0;
    std::uint64_t sum_ns = 0;
    // Lớn nhất từ lúc tiến trình chạy: hiệu hai ảnh chụp không cho ra max của một khoảng.
    std::uint64_t max_ns = 0;
    std::uint64_t over = 0;
    std::array<std::uint64_t, kPhaseBucketCount> buckets{};
};

// Một lần chụp, hoặc một ảnh chụp đọc lại từ văn bản. Khoảng 280 KB: cấp bằng
// std::make_unique<Snapshot>() một lần rồi dùng lại, không đặt trên stack.
struct Snapshot {
    std::array<CounterRow, kMaxCounters> counters{};
    std::size_t counter_count = 0;
    std::array<GaugeRow, kMaxGauges> gauges{};
    std::size_t gauge_count = 0;
    std::array<PhaseRow, kMaxPhases> phases{};
    std::size_t phase_count = 0;
};

// Tra theo tên; không có thì nullopt hoặc nullptr. O(số dòng), tối đa trần danh mục.
[[nodiscard]] std::optional<std::uint64_t> find_counter(const Snapshot& snapshot, std::string_view name) noexcept;
[[nodiscard]] std::optional<std::int64_t> find_gauge(const Snapshot& snapshot, std::string_view name) noexcept;
[[nodiscard]] const PhaseRow* find_phase(const Snapshot& snapshot, std::string_view name) noexcept;

// Kho số đo của một tiến trình. main tạo một lần (std::make_unique, khoảng 16 KB mỗi pha), truyền
// tham chiếu xuống; không biến toàn cục, nên test tạo nhiều kho độc lập. Mọi hàm gọi được từ nhiều
// luồng cùng lúc. Counter::kCount hay giá trị ngoài danh mục là lỗi lập trình (core::check).
class Registry {
public:
    Registry() = default;
    ~Registry() = default;
    Registry(const Registry&) = delete;
    Registry& operator=(const Registry&) = delete;
    Registry(Registry&&) = delete;
    Registry& operator=(Registry&&) = delete;

    void add(Counter which, std::uint64_t amount = 1) noexcept GAME_NONBLOCKING;
    void set(Gauge which, std::int64_t value) noexcept GAME_NONBLOCKING;
    // Một lần đo pha, nanos là số nano giây bên gọi đo bằng đồng hồ đơn điệu. Số âm (đồng hồ lùi, lỗi
    // bên gọi) tính như 0.
    void record(Phase which, std::int64_t nanos) noexcept GAME_NONBLOCKING;
    [[nodiscard]] std::uint64_t read(Counter which) const noexcept;
    [[nodiscard]] std::int64_t read(Gauge which) const noexcept;
    // Chép mọi số của danh mục vào out (ghi đè trọn out).
    void snapshot(Snapshot& out) const noexcept GAME_NONALLOCATING;

private:
    struct PhaseCells {
        std::atomic<std::uint64_t> count;
        std::atomic<std::uint64_t> sum_ns;
        std::atomic<std::uint64_t> max_ns;
        std::atomic<std::uint64_t> over;
        std::array<std::atomic<std::uint64_t>, kPhaseBucketCount> buckets;
    };

    std::array<std::atomic<std::uint64_t>, kCounterCount> counters_{};
    std::array<std::atomic<std::int64_t>, kGaugeCount> gauges_{};
    std::array<PhaseCells, kPhaseCount> phases_{};
};

// Ghi ảnh chụp thành văn bản UTF-8 (thực ra ASCII): dòng "metrics 1", mỗi số một dòng
// ("counter <tên> <số>", "gauge <tên> <số có dấu>", "phase <tên> count=.. sum_ns=.. max_ns=..
// b<cột>=<số>.. over=.."; chỉ ghi cột khác 0), rồi dòng "end". Trả số byte đã ghi, luôn không quá
// kSnapshotMaxBytes. out ngắn hơn kSnapshotMaxBytes là lỗi lập trình.
[[nodiscard]] std::size_t write_snapshot(const Snapshot& snapshot, std::span<char> out) noexcept GAME_NONALLOCATING;

enum class [[nodiscard]] SnapshotError : std::uint8_t {
    // Dài hơn kSnapshotMaxBytes; không quét byte nào.
    kTooLarge = 1,
    // Dòng đầu không phải "metrics 1".
    kHeader,
    // Hết văn bản mà chưa gặp dòng "end".
    kNoEnd,
    // Còn byte sau dòng "end".
    kTrailing,
    // Dòng mở đầu bằng từ lạ, thiếu trường hay thừa trường.
    kLine,
    // Tên rỗng, dài quá kMaxNameBytes hay có ký tự ngoài [a-z0-9_.].
    kName,
    // Không phải chữ số, quá kMaxNumberBytes ký tự hay vượt miền của kiểu.
    kNumber,
    // Hai dòng cùng loại trùng tên.
    kDuplicate,
    // Chỉ số cột từ kPhaseBucketCount trở lên, hoặc một cột ghi hai lần trong một dòng.
    kBucket,
    // Số dòng của một loại vượt trần danh mục.
    kTooMany,
};

// Tên enumerator, cho công cụ in ra stderr.
[[nodiscard]] std::string_view name_of(SnapshotError error) noexcept;

// Đọc lại một ảnh chụp vào out (ghi đè trọn out; khi lỗi out ở trạng thái dở, không dùng). Văn bản
// là dữ liệu không tin được: mọi độ dài và số đều kiểm trước khi dùng, không cấp phát. Số được phép
// có số 0 đứng đầu, miễn không quá kMaxNumberBytes ký tự (chỉ số cột: bốn). O(byte) cộng phép dò
// trùng tên O(số dòng²), số dòng tối đa kMaxCounters.
[[nodiscard]] std::expected<void, SnapshotError> parse_snapshot(std::string_view text, Snapshot& out) noexcept
    GAME_NONALLOCATING;

// Một phân vị rơi vào đâu.
enum class Spread : std::uint8_t {
    // Không có mẫu nào trong khoảng đo.
    kEmpty,
    // Nằm trong một cột; micros là mép phải của cột đó.
    kWithin,
    // Rơi vào cột tràn: lớn hơn kPhaseCeilingUs. Bên gọi in ">200000" kèm max_ns, không nội suy.
    kOver,
    // before không phải ảnh chụp trước của cùng một tiến trình (một số giảm, hay tổng cột vượt count).
    kMismatch,
};

struct Percentile {
    Spread spread = Spread::kEmpty;
    std::uint32_t micros = 0;
};

// Phân vị của một pha theo hạng gần nhất, tính trên hiệu after − before (before là nullptr thì
// tính trên after). percent ngoài 1..100 là lỗi lập trình.
[[nodiscard]] Percentile percentile_us(const PhaseRow& after, const PhaseRow* before, std::uint32_t percent) noexcept;

} // namespace game::metrics
