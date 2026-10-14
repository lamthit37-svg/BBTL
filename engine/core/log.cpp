// Vòng đệm dùng chung: mảng tĩnh 4 MiB gồm các word atomic (vùng BSS, không cấp phát, còn nguyên
// khi heap hỏng lúc crash). Vị trí là số byte tăng mãi, 64 bit không bao giờ quấn; chỉ số trong
// mảng là vị trí chia lấy dư. Bản ghi = một word đầu + văn bản đóng gói 8 byte một word, không vắt
// qua cuối mảng (thiếu chỗ thì một bản ghi Skip lấp phần còn lại).
//   head: luồng gọi đặt chỗ bằng CAS relaxed — không dữ liệu nào đi qua head.
//   word đầu: luồng gọi chép văn bản (relaxed) rồi ghi word đầu (release); bên xả đọc nó (acquire).
//   tail: chỉ bên xả ghi, dưới khoá consumer, sau khi đã xoá về 0 mọi word đã đọc; luồng gọi đọc
//   tail (acquire) trước khi ghi đè, nên vùng nó ghi luôn đã sạch. Word đầu bằng 0 nghĩa là chưa
//   xong.
// So với VnS và No1: không mutex, không biến đếm "đang bay" toàn cục (hai RMW seq_cst mỗi dòng),
// không State bị huỷ dưới tay luồng gọi — vòng đệm và phần điều phối đều tĩnh, sống tới khi tiến
// trình thoát.
// Nguồn: Forge2 src/core/log.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của windows.h
// lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp; check là bản
// của THIENLONG; thân vòng lặp của reserve, deliver, deliver_flushed, run_writer tách thành hàm một
// lượt (ghi tại chỗ); bỏ phép ép Word sang size_t mà GCC báo thừa; lệnh return kèm lời gọi hàm void
// tách làm hai; không tạo được luồng thì create trả Status, không ném system_error.
#include "core/log.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "core/text.hpp"
#include "core/thread.hpp"
#include "core/thread_slot.hpp"
#if defined(_WIN32)
#include "core/win32.hpp" // IWYU pragma: keep

#include <fileapi.h>
#include <minwinbase.h>
#include <sysinfoapi.h>
#include <timezoneapi.h>
#else
#include <ctime>
#include <time.h>
#endif

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <format>
#include <functional>
#include <iterator>
#include <memory>
#include <mutex>
#include <optional>
#include <ranges>
#include <source_location>
#include <span>
#include <stop_token>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <vector>

namespace game::core {

namespace {

using Word = std::uint64_t;
// Khác gốc: gốc ép Word sang std::size_t ở length_of và index_of. Trên nền 64 bit hai kiểu cùng độ
// rộng (GCC báo -Wuseless-cast), nên bỏ phép ép và chặn nền 32 bit ngay tại đây.
static_assert(sizeof(std::size_t) == sizeof(Word), "log cần nền 64 bit");

constexpr std::size_t kWordBytes = sizeof(Word);
constexpr std::size_t kRingBytes = std::size_t{4} << 20U;
constexpr std::size_t kRingWords = kRingBytes / kWordBytes;
// Dòng dài hơn bị cắt: không bản ghi nào chiếm quá một phần 64 vòng đệm.
constexpr std::size_t kMaxLine = std::size_t{64} << 10U;
constexpr std::string_view kCutMarker = "…[cắt]\n";

constexpr auto kLabels = std::to_array<std::string_view>({
    "",
    "GỠ-LỖI",
    "TIN",
    "CẢNH-BÁO",
    "LỖI",
});

// Bên xả. Chờ bản ghi chưa xong (Wait::kYes cho flush và lúc huỷ) hay dừng ở đó (luồng log).
enum class Wait : std::uint8_t {
    kNo,
    kYes,
};

enum class Kind : std::uint8_t {
    kEmpty,
    kLine,
    kSkip,
};

// Word đầu: bit 0–31 độ dài văn bản (Skip: số byte bỏ qua), 32–39 mức, 40–47 loại. Line và Skip
// khác 0 nên word đầu khác 0 đúng khi bản ghi đã xong.
[[nodiscard]] constexpr Word make_header(Kind kind, Level level, std::size_t length) noexcept {
    const Word type = Word{std::to_underlying(kind)} << 40U;
    const Word grade = Word{std::to_underlying(level)} << 32U;
    return type | grade | Word{length};
}

[[nodiscard]] constexpr Kind kind_of(Word header) noexcept {
    return static_cast<Kind>((header >> 40U) & 0xFFU);
}

[[nodiscard]] constexpr Level level_of(Word header) noexcept {
    return static_cast<Level>((header >> 32U) & 0xFFU);
}

[[nodiscard]] constexpr std::size_t length_of(Word header) noexcept {
    return header & 0xFFFF'FFFFU;
}

// Byte một bản ghi chiếm: word đầu cộng văn bản làm tròn lên bội 8.
[[nodiscard]] constexpr std::size_t record_bytes(std::size_t length) noexcept {
    return kWordBytes + ((length + kWordBytes - 1) / kWordBytes * kWordBytes);
}

[[nodiscard]] constexpr std::size_t index_of(Word position) noexcept {
    return (position % kRingBytes) / kWordBytes;
}

constexpr std::size_t kCacheLine = 64;

// head, tail và mảng mỗi thứ một dòng cache: luồng gọi CAS head không làm bẩn dòng của tail mà bên
// xả ghi. Đệm viết tường minh và căn lề đặt trên biến, nên không có đệm ngầm (C4324 vẫn bật).
struct Ring {
    std::atomic<Word> head{0};
    std::array<std::byte, kCacheLine - sizeof(Word)> after_head{};
    std::atomic<Word> tail{0};
    std::array<std::byte, kCacheLine - sizeof(Word)> after_tail{};
    std::array<std::atomic<Word>, kRingWords> words{};
};

// Khởi tạo hằng: không mã chạy lúc khởi động, không trang nào được chạm tới khi có dòng đầu tiên.
[[nodiscard]] Ring& ring() noexcept {
    alignas(kCacheLine) static Ring instance;
    return instance;
}

// Đích của Log đang sống.
struct Output {
    LevelMask levels = 0;
    std::unique_ptr<LogSink> sink;
};

// Phần điều phối dùng chung, sống tới khi tiến trình thoát nên Log tạo, huỷ không làm hỏng luồng
// gọi đang ghi dở. consumer giữ quyền xả vòng đệm (luồng log, flush, crash) và bảo vệ outputs.
// wake_mutex bảo vệ urgent. Hai khoá không bao giờ giữ cùng lúc.
struct Hub {
    std::atomic<bool> live{false};
    std::atomic<LevelMask> levels{kAllLevels};
    // Full::kWait của Log đang sống: mọi mức chờ chỗ thay vì bị bỏ.
    std::atomic<bool> wait_when_full{false};
    std::atomic<std::uint64_t> dropped_pending{0};
    std::atomic<std::uint64_t> dropped_total{0};
    std::atomic<bool> wake_pending{false};
    std::mutex wake_mutex;
    std::condition_variable_any wake;
    bool urgent = false;
    std::timed_mutex consumer;
    std::vector<Output>* outputs = nullptr;
    // Tuần tự hoá dòng ghi thẳng stderr khi không có Log.
    std::mutex direct;

    Hub() = default;
    Hub(const Hub&) = delete;
    Hub& operator=(const Hub&) = delete;
    Hub(Hub&&) = delete;
    Hub& operator=(Hub&&) = delete;
    ~Hub();
};

[[nodiscard]] Hub& hub() {
    static Hub instance;
    return instance;
}

// Luồng đang trong một lần ghi. Sink hay formatter gọi log lại thì lần lồng không đụng vòng đệm hay
// khoá nào và không định dạng tham số, để một formatter luôn ghi log cũng không đệ quy vô hạn.
[[nodiscard]] bool& writing() noexcept {
    thread_local bool active = false;
    return active;
}

// Luồng đang giữ consumer và đang xả. Trình báo crash chạy trên chính luồng này (sink của người
// dùng crash giữa lúc xả, ở luồng log, flush hay hàm huỷ) không được khoá lại consumer: khoá lại
// timed_mutex mình đang giữ là UB.
[[nodiscard]] bool& draining() noexcept {
    thread_local bool active = false;
    return active;
}

// Sink đang nhận dòng trên luồng này; báo cáo crash bỏ qua nó để không gọi lại đúng sink vừa crash.
[[nodiscard]] const LogSink*& active_sink() noexcept {
    thread_local const LogSink* sink = nullptr;
    return sink;
}

// Bật một cờ thread_local trong phạm vi. Lưu rồi trả giá trị cũ thay vì xoá về false: phạm vi lồng
// (luồng gọi tự xả khi Log vừa huỷ) không được xoá cờ của phạm vi ngoài.
class FlagScope {
public:
    explicit FlagScope(bool& flag) noexcept : flag_(flag), previous_(std::exchange(flag, true)) {}
    ~FlagScope() { flag_ = previous_; }
    FlagScope(const FlagScope&) = delete;
    FlagScope& operator=(const FlagScope&) = delete;
    FlagScope(FlagScope&&) = delete;
    FlagScope& operator=(FlagScope&&) = delete;

private:
    bool& flag_;
    bool previous_;
};

// Bộ đệm định dạng của luồng gọi và bộ đệm đọc của bên xả: dùng lại, không cấp phát sau lần đầu.
// std::string có destructor nên đi qua thread_slot, không khai thread_local thẳng (GCC MinGW, xem
// core/thread_slot.hpp).
[[nodiscard]] std::string& line_buffer() {
    return thread_slot([] { return std::string{}; });
}

[[nodiscard]] std::string& drain_buffer() {
    return thread_slot([] { return std::string{}; });
}

// Giây hiện tại đã định dạng "YYYY-MM-DD HH:MM:SS" theo giờ địa phương; chỉ tính lại khi sang giây
// mới, nên đa số dòng chỉ tốn một lần đọc đồng hồ và ba chữ số mili giây.
struct TimeCache {
    std::uint64_t second = ~std::uint64_t{0};
    std::array<char, 19> text{};
};

void put_digits(std::span<char> out, unsigned value) noexcept {
    for (char& digit : std::views::reverse(out)) {
        digit = static_cast<char>('0' + (value % 10U));
        value /= 10U;
    }
}

struct Civil {
    unsigned year = 0;
    unsigned month = 0;
    unsigned day = 0;
    unsigned hour = 0;
    unsigned minute = 0;
    unsigned second = 0;
    unsigned millis = 0;
    std::uint64_t key = 0;
};

void refresh(TimeCache& cache, const Civil& civil) {
    const std::span<char> text(cache.text);
    std::ranges::copy(std::string_view("0000-00-00 00:00:00"), text.begin());
    put_digits(text.subspan(0, 4), civil.year);
    put_digits(text.subspan(5, 2), civil.month);
    put_digits(text.subspan(8, 2), civil.day);
    put_digits(text.subspan(11, 2), civil.hour);
    put_digits(text.subspan(14, 2), civil.minute);
    put_digits(text.subspan(17, 2), civil.second);
    cache.second = civil.key;
}

#if defined(_WIN32)

[[nodiscard]] Civil local_civil_now() {
    FILETIME now{};
    GetSystemTimePreciseAsFileTime(&now);
    const std::uint64_t ticks = (std::uint64_t{now.dwHighDateTime} << 32U) | now.dwLowDateTime;
    FILETIME local{};
    SYSTEMTIME time{};
    FileTimeToLocalFileTime(&now, &local);
    FileTimeToSystemTime(&local, &time);
    Civil civil;
    civil.year = time.wYear;
    civil.month = time.wMonth;
    civil.day = time.wDay;
    civil.hour = time.wHour;
    civil.minute = time.wMinute;
    civil.second = time.wSecond;
    civil.millis = static_cast<unsigned>((ticks / 10'000U) % 1000U);
    civil.key = ticks / 10'000'000U;
    return civil;
}

#else

// CLOCK_REALTIME, rồi localtime_r.
[[nodiscard]] Civil local_civil_now() {
    timespec now{};
    if (::clock_gettime(CLOCK_REALTIME, &now) != 0) return {};
    std::tm broken{};
    if (::localtime_r(&now.tv_sec, &broken) == nullptr) return {};
    Civil civil;
    civil.year = static_cast<unsigned>(broken.tm_year + 1900);
    civil.month = static_cast<unsigned>(broken.tm_mon + 1);
    civil.day = static_cast<unsigned>(broken.tm_mday);
    civil.hour = static_cast<unsigned>(broken.tm_hour);
    civil.minute = static_cast<unsigned>(broken.tm_min);
    civil.second = static_cast<unsigned>(broken.tm_sec);
    const auto millis = now.tv_nsec / 1'000'000;
    civil.millis = static_cast<unsigned>(millis);
    civil.key = static_cast<std::uint64_t>(now.tv_sec);
    return civil;
}

#endif

void append_time(std::string& line) {
    thread_local TimeCache cache;
    const Civil civil = local_civil_now();
    if (civil.key != cache.second) refresh(cache, civil);
    line.append(cache.text.data(), cache.text.size());
    std::array<char, 4> millis{'.', '0', '0', '0'};
    put_digits(std::span(millis).subspan(1), civil.millis);
    line.append(millis.data(), millis.size());
}

void append_number(std::string& line, std::uint32_t value) {
    std::array<char, 10> digits{};
    const auto result = std::to_chars(std::to_address(digits.begin()), std::to_address(digits.end()), value);
    line.append(digits.data(), result.ptr);
}

// "2026-10-01 14:03:07.123 [chính] TIN src/core/log.cpp:42 " — viết tay, không qua std::format.
void append_prefix(std::string& line, Level level, const std::source_location& where) {
    append_time(line);
    line.append(" [");
    line.append(thread_name());
    line.append("] ");
    line.append(kLabels.at(std::to_underlying(level)));
    line.push_back(' ');
    line.append(where.file_name());
    line.push_back(':');
    append_number(line, where.line());
    line.push_back(' ');
}

// Cắt dòng quá kMaxLine ở đầu một ký tự UTF-8 rồi gắn dấu cắt.
void cut_long(std::string& line) {
    if (line.size() <= kMaxLine) return;
    const std::size_t keep = utf8_prefix(line, kMaxLine - kCutMarker.size()).size();
    line.resize(keep);
    line.append(kCutMarker);
}

void compose(std::string& line, Level level, const std::source_location& where, std::string_view format,
    std::format_args args) {
    line.clear();
    const bool plain = level == Level::kRaw;
    if (!plain) append_prefix(line, level, where);
    std::vformat_to(std::back_inserter(line), format, args);
    if (!plain) line.push_back('\n');
    cut_long(line);
}

// Đường thẳng stderr và debugger: chưa có Log, lần ghi lồng, hay đường crash không lấy được khoá.
// gate tuần tự hoá các dòng; nhận qua tham số vì ~Hub cũng gọi, lúc đó không được gọi lại hub().
void write_direct(std::mutex& gate, Level level, std::string_view line) {
    const std::unique_ptr<LogSink> console = console_sink(Color::kOff);
    const std::unique_ptr<LogSink> debugger = debugger_sink();
    const std::scoped_lock lock(gate);
    console->write(Level::kError, line);
    debugger->write(level, line);
}

void write_nested(Hub& shared, Level level, std::string_view format) {
    write_direct(shared.direct, level, std::format("[log lồng, bỏ tham số] {}\n", format));
}

void request_wake(Hub& shared) {
    std::unique_lock lock(shared.wake_mutex);
    shared.urgent = true;
    lock.unlock();
    shared.wake.notify_one();
}

[[nodiscard]] Word pack(std::string_view chunk) noexcept {
    Word word = 0;
    std::memcpy(&word, chunk.data(), chunk.size());
    return word;
}

// Bản ghi Skip lấp từ position tới cuối mảng; trả vị trí đầu mảng ở vòng kế.
[[nodiscard]] Word skip_to_start(Word position, Word room) noexcept {
    const Word header = make_header(Kind::kSkip, Level::kRaw, static_cast<std::size_t>(room));
    ring().words.at(index_of(position)).store(header, std::memory_order_release);
    return position + room;
}

// Byte cần đặt cho bản ghi bắt đầu ở head: thiếu chỗ tới cuối mảng thì cộng phần lấp.
// Vị trí và số byte là hai đại lượng khác nhau, chỉ trùng kiểu trên nền 64 bit (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] Word span_for(Word head, std::size_t need) noexcept {
    const Word room = kRingBytes - (head % kRingBytes);
    return need <= room ? need : room + need;
}

void drain_locked(Hub& shared, Wait wait);

// Ngủ ngắn chờ bên xả nhả chỗ; luồng log được đánh thức trước. Log vừa bị huỷ thì không còn ai xả:
// tự xả ra stderr. Trả head mới để đặt chỗ lại.
[[nodiscard]] Word wait_for_space(Hub& shared) {
    const Ring& shared_ring = ring();
    if (!shared.live.load()) drain_locked(shared, Wait::kNo);
    request_wake(shared);
    const Word tail = shared_ring.tail.load(std::memory_order_acquire);
    static_cast<void>(park(shared_ring.tail, tail, std::chrono::milliseconds(10)));
    return shared_ring.head.load(std::memory_order_relaxed);
}

// Khác gốc: gốc viết một vòng while (true) với bốn câu if trong thân; ở đây mỗi lượt thử là một lời
// gọi try_reserve, thứ tự các phép đọc, CAS và chờ giữ nguyên.
enum class Claim : std::uint8_t {
    kRetry,
    kDropped,
    kTaken,
};

struct Attempt {
    Claim claim = Claim::kRetry;
    Word position = 0;
};

// Một lượt thử đặt chỗ. head là head vừa đọc; CAS hỏng hay phải chờ chỗ thì nó nhận head mới.
[[nodiscard]] Attempt try_reserve(Hub& shared, Word& head, std::size_t need, bool keep) {
    Ring& shared_ring = ring();
    const Word total = span_for(head, need);
    const Word tail = shared_ring.tail.load(std::memory_order_acquire);
    // head đọc trước tail: bên xả có thể đã vượt head cũ, head - tail quấn thành số khổng lồ và
    // dòng bị bỏ oan. head cũ thì CAS hỏng và nạp head mới.
    const bool full = head >= tail && head - tail + total > kRingBytes;
    if (full && !keep) return {.claim = Claim::kDropped};
    const bool claimed = !full && shared_ring.head.compare_exchange_weak(head, head + total, std::memory_order_relaxed);
    const bool wraps = claimed && total > need;
    if (wraps) return {.claim = Claim::kTaken, .position = skip_to_start(head, total - need)};
    if (claimed) return {.claim = Claim::kTaken, .position = head};
    if (full) head = wait_for_space(shared);
    return {};
}

// Đặt chỗ cho một bản ghi need byte. Trả vị trí đầu bản ghi, hoặc nullopt khi đầy mà dòng được bỏ.
[[nodiscard]] std::optional<Word> reserve(Hub& shared, std::size_t need, bool keep) {
    Word head = ring().head.load(std::memory_order_relaxed);
    Attempt attempt = try_reserve(shared, head, need, keep);
    while (attempt.claim == Claim::kRetry) {
        attempt = try_reserve(shared, head, need, keep);
    }
    if (attempt.claim == Claim::kDropped) return std::nullopt;
    return attempt.position;
}

void store_record(Word position, Level level, std::string_view text) {
    Ring& shared_ring = ring();
    const std::size_t first = index_of(position);
    std::size_t index = first + 1;
    for (std::size_t offset = 0; offset < text.size(); offset += kWordBytes) {
        const Word word = pack(text.substr(offset, kWordBytes));
        shared_ring.words.at(index++).store(word, std::memory_order_relaxed);
    }
    const Word header = make_header(Kind::kLine, level, text.size());
    shared_ring.words.at(first).store(header, std::memory_order_release);
}

void note_drop(Hub& shared) {
    shared.dropped_pending.fetch_add(1, std::memory_order_relaxed);
    shared.dropped_total.fetch_add(1, std::memory_order_relaxed);
}

// Error vừa không bị bỏ vừa đánh thức luồng log ngay; Full::kWait chỉ giữ dòng, không đánh thức
// từng dòng (khoá mutex và notify mỗi dòng làm luồng gọi chậm thêm khoảng 40%).
void submit(Hub& shared, Level level, std::string_view text) {
    const bool urgent = level == Level::kError;
    const bool keep = urgent || shared.wait_when_full.load(std::memory_order_relaxed);
    const std::optional<Word> position = reserve(shared, record_bytes(text.size()), keep);
    if (!position) {
        note_drop(shared);
        return;
    }
    store_record(*position, level, text);
    const Ring& shared_ring = ring();
    const Word tail = shared_ring.tail.load(std::memory_order_relaxed);
    const bool half = *position >= tail && *position - tail > kRingBytes / 2;
    if (urgent || (half && !shared.wake_pending.exchange(true))) request_wake(shared);
}

[[nodiscard]] Word load_header(std::size_t index, Wait wait) noexcept {
    const std::atomic<Word>& slot = ring().words.at(index);
    Word header = slot.load(std::memory_order_acquire);
    while (header == 0 && wait == Wait::kYes) {
        std::this_thread::yield();
        header = slot.load(std::memory_order_acquire);
    }
    return header;
}

// Chép văn bản của bản ghi ra text rồi xoá các word về 0 cho vòng kế.
void unpack(std::size_t first, std::size_t length, std::string& text) {
    Ring& shared_ring = ring();
    text.resize(record_bytes(length) - kWordBytes);
    const std::span<char> out(text);
    for (std::size_t offset = 0; offset < out.size(); offset += kWordBytes) {
        std::atomic<Word>& slot = shared_ring.words.at(first + 1 + (offset / kWordBytes));
        const Word word = slot.load(std::memory_order_relaxed);
        std::memcpy(out.subspan(offset, kWordBytes).data(), &word, kWordBytes);
        slot.store(0, std::memory_order_relaxed);
    }
    text.resize(length);
}

// Khác gốc: phép lọc theo mức nằm ở đây thay vì trong thân vòng lặp của deliver.
void write_output(const Output& output, Level level, std::string_view line) {
    if ((output.levels & mask(level)) == 0) return;
    active_sink() = output.sink.get();
    output.sink->write(level, line);
    active_sink() = nullptr;
}

void deliver(Hub& shared, Level level, std::string_view line) {
    if (shared.outputs == nullptr) {
        write_direct(shared.direct, level, line);
        return;
    }
    for (const Output& output : *shared.outputs) {
        write_output(output, level, line);
    }
}

// Một bản ghi tại position: giao cho các đích, trả vị trí kế; nullopt khi bản ghi chưa xong.
[[nodiscard]] std::optional<Word> take(Hub& shared, Word position, Wait wait) {
    const std::size_t first = index_of(position);
    const Word header = load_header(first, wait);
    if (header == 0) return std::nullopt;
    ring().words.at(first).store(0, std::memory_order_relaxed);
    if (kind_of(header) == Kind::kSkip) return position + length_of(header);
    std::string& text = drain_buffer();
    unpack(first, length_of(header), text);
    deliver(shared, level_of(header), text);
    return position + record_bytes(length_of(header));
}

void report_dropped(Hub& shared) {
    const std::uint64_t count = shared.dropped_pending.exchange(0, std::memory_order_relaxed);
    if (count == 0) return;
    std::string line;
    const auto here = std::source_location::current();
    compose(line, Level::kWarning, here, "đã bỏ {} dòng log vì vòng đệm đầy", std::make_format_args(count));
    deliver(shared, Level::kWarning, line);
}

// Báo cáo crash: mỗi đích ghi rồi flush ngay, để một đích treo phía sau (đã đo: sink người dùng
// treo trong kịch bản stuck) không giữ báo cáo trong bộ đệm của tệp khi luồng canh kết thúc tiến
// trình.
// Khác gốc: thân vòng lặp của deliver_flushed tách ra đây.
void write_flushed(const Output& output, Level level, std::string_view line) {
    const bool skip = (output.levels & mask(level)) == 0 || output.sink.get() == active_sink();
    if (skip) return;
    output.sink->write(level, line);
    output.sink->flush();
}

void deliver_flushed(Hub& shared, Level level, std::string_view line) {
    if (shared.outputs == nullptr) {
        write_direct(shared.direct, level, line);
        return;
    }
    for (const Output& output : *shared.outputs) {
        write_flushed(output, level, line);
    }
}

void flush_outputs(const Hub& shared) {
    if (shared.outputs == nullptr) return;
    for (const Output& output : *shared.outputs) {
        active_sink() = output.sink.get();
        output.sink->flush();
        active_sink() = nullptr;
    }
}

// Xả tới head lúc bắt đầu. Người gọi giữ consumer. Sink ghi log trong lúc này đi đường lồng ra
// stderr, không đẩy dòng mới vào vòng đệm (mỗi dòng xả ra lại sinh một dòng, không bao giờ hết).
void drain(Hub& shared, Wait wait) {
    const FlagScope writing_scope(writing());
    const FlagScope draining_scope(draining());
    Ring& shared_ring = ring();
    report_dropped(shared);
    Word tail = shared_ring.tail.load(std::memory_order_relaxed);
    const Word head = shared_ring.head.load(std::memory_order_acquire);
    std::optional<Word> next = tail;
    while (next && *next < head) {
        tail = *next;
        next = take(shared, tail, wait);
    }
    tail = next.value_or(tail);
    shared_ring.tail.store(tail, std::memory_order_release);
    unpark_all(shared_ring.tail);
    flush_outputs(shared);
}

void drain_locked(Hub& shared, Wait wait) {
    const std::scoped_lock lock(shared.consumer);
    drain(shared, wait);
}

using Interval = std::chrono::milliseconds;

// Khác gốc: thân vòng lặp của run_writer tách ra đây. Một vòng của luồng log.
void sleep_then_drain(Hub& shared, Interval interval, const std::stop_token& stop) {
    std::unique_lock lock(shared.wake_mutex);
    const auto is_urgent = [&shared] { return shared.urgent; };
    static_cast<void>(shared.wake.wait_for(lock, stop, interval, is_urgent));
    shared.urgent = false;
    lock.unlock();
    shared.wake_pending.store(false);
    drain_locked(shared, Wait::kNo);
}

// Luồng log: ngủ tới khi có dòng Error, vòng đệm quá nửa, flush, hay hết khoảng xả định kỳ.
void run_writer(Hub& shared, Interval interval, const std::stop_token& stop) {
    while (!stop.stop_requested()) {
        sleep_then_drain(shared, interval, stop);
    }
}

// Thử khoá trong khoảng 100 ms. Trình báo crash dùng: luồng crash có thể đang giữ chính khoá này.
template <class Lock>
[[nodiscard]] bool lock_patiently(Lock& lock) {
    return lock.try_lock_for(std::chrono::milliseconds(100));
}

// Ném trong hàm huỷ là std::terminate: ngoại lệ thư viện chỉ có một đích là dừng tiến trình
// (LH-07). NOLINTNEXTLINE(bugprone-exception-escape)
Hub::~Hub() {
    // Dòng của luồng đẩy vào sau khi Log cuối cùng đã huỷ: ra stderr trước khi tiến trình thoát.
    const std::scoped_lock lock(consumer);
    outputs = nullptr;
    drain(*this, Wait::kNo);
}

// Trả Hub về như chưa có Log: open khi không tạo được luồng, ~Log khi bad_alloc sau khi nhận chỗ.
// live còn bật thì Log sau chết ở check, và outputs trỏ vào State sắp huỷ.
void abandon(Hub& shared) noexcept {
    shared.live.store(false);
    const std::scoped_lock lock(shared.consumer);
    shared.outputs = nullptr;
    shared.levels.store(kAllLevels);
    shared.wait_when_full.store(false, std::memory_order_relaxed);
}

} // namespace

struct Log::State {
    std::vector<Output> outputs;
    std::jthread writer;
};

Log::Log(Key) : state_(std::make_unique<State>()) {}

Result<std::unique_ptr<Log>> Log::create(const LogConfig& config) {
    auto created = std::make_unique<Log>(Key{});
    Status opened = created->open(config);
    if (!opened) return std::unexpected(std::move(opened.error()));
    return created;
}

Status Log::open(const LogConfig& config) {
    Hub& shared = hub();
    const bool first = !shared.live.exchange(true);
    check(first, "chỉ một Log sống mỗi lúc");
    try {
        prepare(config);
    } catch (const std::system_error& failure) {
        const std::string_view detail = failure.what();
        abandon(shared);
        return fail(ErrorCode::kExhausted, "không tạo được luồng log", detail);
    }
    return ok();
}

void Log::prepare(const LogConfig& config) {
    Hub& shared = hub();
    shared.levels.store(config.levels);
    shared.dropped_total.store(0, std::memory_order_relaxed);
    shared.wait_when_full.store(config.full == Full::kWait, std::memory_order_relaxed);
    if (config.console) add_sink(config.levels, console_sink(config.color));
    add_sink(config.levels, debugger_sink());
    std::unique_lock lock(shared.consumer);
    shared.outputs = &state_->outputs;
    lock.unlock();
    const auto interval = std::max(config.flush_interval, std::chrono::milliseconds(1));
    auto body = std::bind_front(&run_writer, std::ref(shared), interval);
    ThreadConfig thread;
    thread.name = "log";
    state_->writer = start_thread(std::move(thread), std::move(body));
    if (config.file.empty()) return;
    const Status added = add_file(config.file, config.levels, config.open);
    if (!added) error("{}", added.error());
}

// Dừng luồng log rồi tự xả tới hết, chờ cả bản ghi đặt chỗ mà chưa xong. Luồng gọi thấy live sai
// thì ghi thẳng stderr; dòng đẩy vào sau lần xả cuối nằm lại vòng đệm cho Log sau hay ~Hub.
// Ném ở đây là std::terminate, như ~Hub (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
Log::~Log() {
    // Chưa có luồng: open ném bad_alloc sau khi nhận chỗ, hoặc create trả lỗi. abandon để Log sau
    // không chết ở check "chỉ một Log".
    if (!state_->writer.joinable()) {
        abandon(hub());
        return;
    }
    info("Đóng log");
    Hub& shared = hub();
    state_->writer.request_stop();
    state_->writer.join();
    shared.live.store(false);
    const std::scoped_lock lock(shared.consumer);
    drain(shared, Wait::kYes);
    shared.outputs = nullptr;
    shared.levels.store(kAllLevels);
    shared.wait_when_full.store(false, std::memory_order_relaxed);
}

Status Log::add_file(const std::filesystem::path& path, LevelMask levels, FileOpen open) {
    Result<std::unique_ptr<LogSink>> sink = file_sink(path, open);
    if (!sink) return std::unexpected(std::move(sink.error()));
    add_sink(levels, std::move(*sink));
#if defined(_WIN32)
    const std::string shown = narrow(path.native());
#else
    const std::string shown = path.string();
#endif
    info("Mở tệp log {}", shown);
    return ok();
}

void Log::add_sink(LevelMask levels, std::unique_ptr<LogSink> sink) {
    Hub& shared = hub();
    const std::scoped_lock lock(shared.consumer);
    state_->outputs.push_back(Output{.levels = levels, .sink = std::move(sink)});
    shared.levels.fetch_or(levels);
}

// Hai thao tác của một Log đang sống; phần điều phối dùng chung là chi tiết cài đặt, nên không
// thành static dù không đọc state_.
// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
void Log::flush() {
    drain_locked(hub(), Wait::kYes);
}

// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
std::uint64_t Log::dropped() const noexcept {
    return hub().dropped_total.load(std::memory_order_relaxed);
}

void set_log_levels(LevelMask levels) noexcept {
    hub().levels.store(levels);
}

LevelMask log_levels() noexcept {
    return hub().levels.load();
}

// noexcept chủ ý (xem log.hpp): formatter ném hay hết bộ nhớ thì std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void emit(Level level, std::source_location where, std::string_view format, std::format_args args) noexcept {
    Hub& shared = hub();
    if ((shared.levels.load() & mask(level)) == 0) return;
    if (writing()) {
        write_nested(shared, level, format);
        return;
    }
    const FlagScope scope(writing());
    std::string& line = line_buffer();
    compose(line, level, where, format, args);
    if (!shared.live.load()) {
        write_direct(shared.direct, level, line);
        return;
    }
    submit(shared, level, line);
}

// noexcept chủ ý: đây là đường báo crash, ném thêm lần nữa thì std::terminate (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
void emit_fatal(std::string_view report) noexcept {
    Hub& shared = hub();
    // Crash giữa lúc chính luồng này xả: đã giữ consumer, giao thẳng cho các đích còn lại.
    if (draining()) {
        deliver_flushed(shared, Level::kError, report);
        return;
    }
    std::unique_lock lock(shared.consumer, std::defer_lock);
    if (!lock_patiently(lock)) {
        write_direct(shared.direct, Level::kError, report);
        return;
    }
    drain(shared, Wait::kNo);
    deliver_flushed(shared, Level::kError, report);
}

} // namespace game::core
