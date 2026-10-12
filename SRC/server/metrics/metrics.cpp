// Kho số đo, ảnh chụp văn bản và bộ đọc có trần (metrics/metrics.hpp).
#include "metrics/metrics.hpp"

#include "core/check.hpp"
#include "core/effects.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::metrics {
namespace {

static_assert(std::atomic<std::uint64_t>::is_always_lock_free);
static_assert(std::atomic<std::int64_t>::is_always_lock_free);

constexpr std::uint64_t kBucketWidthNs = std::uint64_t{kPhaseBucketWidthUs} * 1000;
constexpr auto kRelaxed = std::memory_order_relaxed;

using Parsed = std::expected<void, SnapshotError>;

[[nodiscard]] Parsed refuse(SnapshotError error) noexcept {
    return std::unexpected{error};
}

// Trọn text là một số của kiểu Number, không quá kMaxNumberBytes ký tự. from_chars không nhận dấu
// cộng hay khoảng trắng, và chỉ nhận dấu trừ cho kiểu có dấu.
template <class Number>
[[nodiscard]] std::optional<Number> read_number(std::string_view text) noexcept {
    if (text.empty() || text.size() > kMaxNumberBytes) return std::nullopt;
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    Number value{};
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{} || stop != last) return std::nullopt;
    return value;
}

// count ký tự đầu của text. Thay cho substr: substr ném khi vị trí ngoài chuỗi nên Clang không coi nó là
// hàm không cấp phát.
[[nodiscard]] std::string_view head_of(std::string_view text, std::size_t count) noexcept {
    text.remove_suffix(text.size() - std::min(count, text.size()));
    return text;
}

// Cắt phần đứng trước dấu mark đầu tiên vào head và bỏ cả dấu; không có dấu thì false, rest giữ nguyên.
[[nodiscard]] bool cut(std::string_view& rest, char mark, std::string_view& head) noexcept {
    // find_if thay cho string_view::find: bản find của STL MSVC gọi hàm véc-tơ hoá nằm ngoài header,
    // Clang không chứng minh được nó không cấp phát. Bộ đọc này không nằm trên đường nóng.
    const auto found = std::ranges::find_if(rest, [mark](char one) { return one == mark; });
    if (found == rest.end()) return false;
    const auto where = static_cast<std::size_t>(std::ranges::distance(rest.begin(), found));
    head = head_of(rest, where);
    rest.remove_prefix(where + 1);
    return true;
}

// Bỏ word ở đầu text; không mở đầu bằng word thì false.
[[nodiscard]] bool eat(std::string_view& text, std::string_view word) noexcept {
    if (!text.starts_with(word)) return false;
    text.remove_prefix(word.size());
    return true;
}

template <class Row>
[[nodiscard]] bool has_name(std::span<const Row> rows, std::string_view name) noexcept {
    return std::ranges::any_of(rows, [name](const Row& row) { return row.name.view() == name; });
}

// Dòng "<tên> <số>" của counter và gauge: kiểm trần, tên, trùng tên rồi mới ghi ô kế.
template <class Row, std::size_t Size>
[[nodiscard]] Parsed read_scalar(std::string_view rest, std::array<Row, Size>& rows, std::size_t& count) noexcept {
    std::string_view name;
    if (!cut(rest, ' ', name)) return refuse(SnapshotError::kLine);
    if (count >= Size) return refuse(SnapshotError::kTooMany);
    const std::span<Row> all{rows};
    Row& row = all[count];
    if (!row.name.assign(name)) return refuse(SnapshotError::kName);
    if (has_name<Row>(all.first(count), name)) return refuse(SnapshotError::kDuplicate);
    const auto value = read_number<decltype(row.value)>(rest);
    if (!value) return refuse(SnapshotError::kNumber);
    row.value = *value;
    ++count;
    return {};
}

// Trường "<nhãn><số>" đứng trước một dấu cách.
[[nodiscard]] Parsed read_field(std::string_view& rest, std::string_view label, std::uint64_t& out) noexcept {
    std::string_view field;
    if (!cut(rest, ' ', field) || !eat(field, label)) return refuse(SnapshotError::kLine);
    const std::optional<std::uint64_t> value = read_number<std::uint64_t>(field);
    if (!value) return refuse(SnapshotError::kNumber);
    out = *value;
    return {};
}

// Trường "b<cột>=<số>". Cột phải tăng dần trong một dòng, nên cột lặp hay lùi đều bị từ chối;
// next là cột nhỏ nhất còn được nhận.
[[nodiscard]] Parsed read_bucket(std::string_view field, PhaseRow& row, std::uint32_t& next) noexcept {
    std::string_view column;
    if (!eat(field, "b") || !cut(field, '=', column)) return refuse(SnapshotError::kLine);
    const bool digits = !column.empty() && std::ranges::all_of(column, [](char one) { return one >= '0' && one <= '9'; });
    if (!digits) return refuse(SnapshotError::kLine);
    if (column.size() > 4) return refuse(SnapshotError::kBucket);
    const std::optional<std::uint32_t> index = read_number<std::uint32_t>(column);
    if (!index || *index >= kPhaseBucketCount || *index < next) return refuse(SnapshotError::kBucket);
    const std::optional<std::uint64_t> value = read_number<std::uint64_t>(field);
    if (!value) return refuse(SnapshotError::kNumber);
    std::span{row.buckets}[*index] = *value;
    next = *index + 1;
    return {};
}

[[nodiscard]] Parsed read_phase_body(std::string_view rest, PhaseRow& row) noexcept {
    for (const auto& [label, slot] : {std::pair<std::string_view, std::uint64_t*>{"count=", &row.count},
             std::pair<std::string_view, std::uint64_t*>{"sum_ns=", &row.sum_ns},
             std::pair<std::string_view, std::uint64_t*>{"max_ns=", &row.max_ns}}) {
        const Parsed field = read_field(rest, label, *slot);
        if (!field) return field;
    }
    row.buckets.fill(0);
    std::uint32_t next = 0;
    std::string_view field;
    while (cut(rest, ' ', field)) {
        const Parsed bucket = read_bucket(field, row, next);
        if (!bucket) return bucket;
    }
    if (!eat(rest, "over=")) return refuse(SnapshotError::kLine);
    const std::optional<std::uint64_t> over = read_number<std::uint64_t>(rest);
    if (!over) return refuse(SnapshotError::kNumber);
    row.over = *over;
    return {};
}

[[nodiscard]] Parsed read_phase(std::string_view rest, Snapshot& out) noexcept {
    std::string_view name;
    if (!cut(rest, ' ', name)) return refuse(SnapshotError::kLine);
    if (out.phase_count >= kMaxPhases) return refuse(SnapshotError::kTooMany);
    const std::span<PhaseRow> all{out.phases};
    PhaseRow& row = all[out.phase_count];
    if (!row.name.assign(name)) return refuse(SnapshotError::kName);
    if (has_name<PhaseRow>(all.first(out.phase_count), name)) return refuse(SnapshotError::kDuplicate);
    const Parsed body = read_phase_body(rest, row);
    if (!body) return body;
    ++out.phase_count;
    return {};
}

[[nodiscard]] Parsed read_row(std::string_view line, Snapshot& out) noexcept {
    std::string_view kind;
    if (!cut(line, ' ', kind)) return refuse(SnapshotError::kLine);
    if (kind == "counter") return read_scalar(line, out.counters, out.counter_count);
    if (kind == "gauge") return read_scalar(line, out.gauges, out.gauge_count);
    if (kind == "phase") return read_phase(line, out);
    return refuse(SnapshotError::kLine);
}

// Ghi nối vào một vùng cấp sẵn. Vùng hết chỗ thì phần thừa bị bỏ: write_snapshot đã kiểm vùng đủ
// cho ảnh chụp lớn nhất nên nhánh đó không tới được, nó chỉ để một ảnh chụp bị sửa hỏng không ghi
// ra ngoài vùng.
class Writer {
public:
    explicit Writer(std::span<char> out) noexcept : out_(out) {}

    void text(std::string_view piece) noexcept {
        const std::span<char> room = out_.subspan(at_);
        const std::size_t take = std::min(piece.size(), room.size());
        std::ranges::copy(head_of(piece, take), room.begin());
        at_ += take;
    }

    template <class Number>
    void number(Number value) noexcept {
        std::array<char, kMaxNumberBytes> digits{};
        char* const first = digits.data();
        char* const last = std::to_address(digits.end());
        const auto [stop, error] = std::to_chars(first, last, value);
        if (error != std::errc{}) return;
        text(std::string_view{first, stop});
    }

    [[nodiscard]] std::size_t size() const noexcept { return at_; }

private:
    std::span<char> out_;
    std::size_t at_ = 0;
};

void write_phase(Writer& writer, const PhaseRow& row) noexcept {
    writer.text("phase ");
    writer.text(row.name.view());
    writer.text(" count=");
    writer.number(row.count);
    writer.text(" sum_ns=");
    writer.number(row.sum_ns);
    writer.text(" max_ns=");
    writer.number(row.max_ns);
    std::uint32_t column = 0;
    for (const std::uint64_t held : row.buckets) {
        if (held != 0) {
            writer.text(" b");
            writer.number(column);
            writer.text("=");
            writer.number(held);
        }
        ++column;
    }
    writer.text(" over=");
    writer.number(row.over);
    writer.text("\n");
}

// Hiệu after − before của một ô; before lớn hơn after nghĩa là hai ảnh chụp không cùng một tiến
// trình (hoặc đưa ngược thứ tự).
[[nodiscard]] std::optional<std::uint64_t> grown(std::uint64_t after, std::uint64_t before) noexcept {
    if (after < before) return std::nullopt;
    return after - before;
}

} // namespace

bool Name::assign(std::string_view text) noexcept {
    if (!is_name(text)) return false;
    std::ranges::copy(text, bytes_.begin());
    size_ = text.size();
    return true;
}

std::optional<std::uint64_t> find_counter(const Snapshot& snapshot, std::string_view name) noexcept {
    const std::size_t count = std::min(snapshot.counter_count, kMaxCounters);
    for (const CounterRow& row : std::span{snapshot.counters}.first(count)) {
        if (row.name.view() == name) return row.value;
    }
    return std::nullopt;
}

std::optional<std::int64_t> find_gauge(const Snapshot& snapshot, std::string_view name) noexcept {
    const std::size_t count = std::min(snapshot.gauge_count, kMaxGauges);
    for (const GaugeRow& row : std::span{snapshot.gauges}.first(count)) {
        if (row.name.view() == name) return row.value;
    }
    return std::nullopt;
}

const PhaseRow* find_phase(const Snapshot& snapshot, std::string_view name) noexcept {
    const std::size_t count = std::min(snapshot.phase_count, kMaxPhases);
    for (const PhaseRow& row : std::span{snapshot.phases}.first(count)) {
        if (row.name.view() == name) return &row;
    }
    return nullptr;
}

void Registry::add(Counter which, std::uint64_t amount) noexcept GAME_NONBLOCKING {
    const std::size_t index = std::to_underlying(which);
    core::check(index < kCounterCount, "Registry::add: bộ đếm ngoài danh mục");
    std::span{counters_}[index].fetch_add(amount, kRelaxed);
}

void Registry::set(Gauge which, std::int64_t value) noexcept GAME_NONBLOCKING {
    const std::size_t index = std::to_underlying(which);
    core::check(index < kGaugeCount, "Registry::set: mức đo ngoài danh mục");
    std::span{gauges_}[index].store(value, kRelaxed);
}

void Registry::record(Phase which, std::int64_t nanos) noexcept GAME_NONBLOCKING {
    const std::size_t index = std::to_underlying(which);
    core::check(index < kPhaseCount, "Registry::record: pha ngoài danh mục");
    PhaseCells& cells = std::span{phases_}[index];
    // Kẹp trước khi tính cột: không có chỉ số âm. Cột đóng bên phải nên trừ 1 trước khi chia.
    const std::uint64_t spent = nanos > 0 ? static_cast<std::uint64_t>(nanos) : 0;
    const std::uint64_t column = spent == 0 ? 0 : (spent - 1) / kBucketWidthNs;
    std::atomic<std::uint64_t>& bucket =
        column < kPhaseBucketCount ? std::span{cells.buckets}[static_cast<std::size_t>(column)] : cells.over;
    bucket.fetch_add(1, kRelaxed);
    cells.count.fetch_add(1, kRelaxed);
    cells.sum_ns.fetch_add(spent, kRelaxed);
    std::uint64_t seen = cells.max_ns.load(kRelaxed);
    while (spent > seen && !cells.max_ns.compare_exchange_weak(seen, spent, kRelaxed)) {
    }
}

std::uint64_t Registry::read(Counter which) const noexcept {
    const std::size_t index = std::to_underlying(which);
    core::check(index < kCounterCount, "Registry::read: bộ đếm ngoài danh mục");
    return std::span{counters_}[index].load(kRelaxed);
}

std::int64_t Registry::read(Gauge which) const noexcept {
    const std::size_t index = std::to_underlying(which);
    core::check(index < kGaugeCount, "Registry::read: mức đo ngoài danh mục");
    return std::span{gauges_}[index].load(kRelaxed);
}

void Registry::snapshot(Snapshot& out) const noexcept GAME_NONALLOCATING {
    const std::span<CounterRow> counters = std::span{out.counters}.first(kCounterCount);
    for (std::size_t index = 0; index < kCounterCount; ++index) {
        // Tên của danh mục đã qua is_name lúc biên dịch (static_assert ở header) nên assign luôn nhận.
        static_cast<void>(counters[index].name.assign(std::span{kCounterNames}[index]));
        counters[index].value = std::span{counters_}[index].load(kRelaxed);
    }
    out.counter_count = kCounterCount;
    const std::span<GaugeRow> gauges = std::span{out.gauges}.first(kGaugeCount);
    for (std::size_t index = 0; index < kGaugeCount; ++index) {
        static_cast<void>(gauges[index].name.assign(std::span{kGaugeNames}[index]));
        gauges[index].value = std::span{gauges_}[index].load(kRelaxed);
    }
    out.gauge_count = kGaugeCount;
    const std::span<PhaseRow> phases = std::span{out.phases}.first(kPhaseCount);
    for (std::size_t index = 0; index < kPhaseCount; ++index) {
        PhaseRow& row = phases[index];
        const PhaseCells& cells = std::span{phases_}[index];
        static_cast<void>(row.name.assign(std::span{kPhaseNames}[index]));
        row.count = cells.count.load(kRelaxed);
        row.sum_ns = cells.sum_ns.load(kRelaxed);
        row.max_ns = cells.max_ns.load(kRelaxed);
        row.over = cells.over.load(kRelaxed);
        const auto load = [](const std::atomic<std::uint64_t>& cell) { return cell.load(kRelaxed); };
        std::ranges::transform(cells.buckets, row.buckets.begin(), load);
    }
    out.phase_count = kPhaseCount;
}

std::size_t write_snapshot(const Snapshot& snapshot, std::span<char> out) noexcept GAME_NONALLOCATING {
    core::check(out.size() >= kSnapshotMaxBytes, "write_snapshot: vùng ghi ngắn hơn kSnapshotMaxBytes");
    Writer writer{out};
    writer.text("metrics 1\n");
    for (const CounterRow& row : std::span{snapshot.counters}.first(std::min(snapshot.counter_count, kMaxCounters))) {
        writer.text("counter ");
        writer.text(row.name.view());
        writer.text(" ");
        writer.number(row.value);
        writer.text("\n");
    }
    for (const GaugeRow& row : std::span{snapshot.gauges}.first(std::min(snapshot.gauge_count, kMaxGauges))) {
        writer.text("gauge ");
        writer.text(row.name.view());
        writer.text(" ");
        writer.number(row.value);
        writer.text("\n");
    }
    for (const PhaseRow& row : std::span{snapshot.phases}.first(std::min(snapshot.phase_count, kMaxPhases))) {
        write_phase(writer, row);
    }
    writer.text("end\n");
    return writer.size();
}

std::string_view name_of(SnapshotError error) noexcept {
    switch (error) {
    case SnapshotError::kTooLarge: return "kTooLarge";
    case SnapshotError::kHeader: return "kHeader";
    case SnapshotError::kNoEnd: return "kNoEnd";
    case SnapshotError::kTrailing: return "kTrailing";
    case SnapshotError::kLine: return "kLine";
    case SnapshotError::kName: return "kName";
    case SnapshotError::kNumber: return "kNumber";
    case SnapshotError::kDuplicate: return "kDuplicate";
    case SnapshotError::kBucket: return "kBucket";
    case SnapshotError::kTooMany: return "kTooMany";
    }
    return "?";
}

std::expected<void, SnapshotError> parse_snapshot(std::string_view text, Snapshot& out) noexcept GAME_NONALLOCATING {
    if (text.size() > kSnapshotMaxBytes) return refuse(SnapshotError::kTooLarge);
    out.counter_count = 0;
    out.gauge_count = 0;
    out.phase_count = 0;
    std::string_view rest = text;
    std::string_view line;
    if (!cut(rest, '\n', line) || line != "metrics 1") return refuse(SnapshotError::kHeader);
    while (cut(rest, '\n', line)) {
        if (line == "end") return rest.empty() ? Parsed{} : refuse(SnapshotError::kTrailing);
        const Parsed row = read_row(line, out);
        if (!row) return row;
    }
    return refuse(SnapshotError::kNoEnd);
}

Percentile percentile_us(const PhaseRow& after, const PhaseRow* before, std::uint32_t percent) noexcept {
    core::check(percent >= 1 && percent <= 100, "percentile_us: percent ngoài 1..100");
    const std::optional<std::uint64_t> count = grown(after.count, before != nullptr ? before->count : 0);
    if (!count) return Percentile{.spread = Spread::kMismatch};
    if (*count == 0) return Percentile{.spread = Spread::kEmpty};
    // Hạng gần nhất: ceil(percent × count / 100), tách thương và dư để không tràn 64 bit.
    const std::uint64_t rank = ((*count / 100) * percent) + ((((*count % 100) * percent) + 99) / 100);
    std::uint64_t seen = 0;
    for (std::uint32_t column = 0; column < kPhaseBucketCount; ++column) {
        const std::uint64_t was = before != nullptr ? std::span{before->buckets}[column] : 0;
        const std::optional<std::uint64_t> more = grown(std::span{after.buckets}[column], was);
        // Tổng các cột vượt count chỉ có ở ảnh chụp bị sửa: coi như hai ảnh không khớp nhau.
        if (!more || *more > *count - seen) return Percentile{.spread = Spread::kMismatch};
        seen += *more;
        if (seen >= rank) return Percentile{.spread = Spread::kWithin, .micros = (column + 1) * kPhaseBucketWidthUs};
    }
    return Percentile{.spread = Spread::kOver};
}

} // namespace game::metrics
