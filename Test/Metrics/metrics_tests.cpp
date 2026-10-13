// Test của game::metrics: kho số đo, cột biểu đồ ở từng mép, ảnh chụp văn bản khứ hồi, trần cứng
// của bộ đọc và từng mã lỗi của nó, phân vị. Logic thuần, không socket (cổng đọc ở
// metrics_serve_tests). "Không cấp phát" không đếm ở đây: add, set, record khai GAME_NONBLOCKING,
// snapshot, write_snapshot, parse_snapshot khai GAME_NONALLOCATING, Clang của check.py chứng minh
// lúc biên dịch.
#include "core/check.hpp"
#include "metrics/metrics.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using metrics::Counter;
using metrics::Gauge;
using metrics::Percentile;
using metrics::Phase;
using metrics::PhaseRow;
using metrics::Registry;
using metrics::Snapshot;
using metrics::SnapshotError;
using metrics::Spread;

constexpr std::string_view kMaxUnsigned = "18446744073709551615";
constexpr std::string_view kMinSigned = "-9223372036854775808";

// Tên dài đúng kMaxNameBytes, khác nhau theo index.
[[nodiscard]] std::string long_name(char lead, std::size_t index) {
    return std::format("{}{}{:03}", lead, std::string(metrics::kMaxNameBytes - 4, 'a'), index);
}

// Ảnh chụp đúng ngữ pháp dài nhất có thể: đủ trần số dòng, tên dài nhất, số dài nhất, mọi cột có
// mặt với chỉ số viết đủ bốn chữ số.
[[nodiscard]] std::string largest_text() {
    std::string text = "metrics 1\n";
    text.reserve(metrics::kSnapshotMaxBytes);
    for (std::size_t index = 0; index < metrics::kMaxCounters; ++index) {
        text += std::format("counter {} {}\n", long_name('c', index), kMaxUnsigned);
    }
    for (std::size_t index = 0; index < metrics::kMaxGauges; ++index) {
        text += std::format("gauge {} {}\n", long_name('g', index), kMinSigned);
    }
    for (std::size_t index = 0; index < metrics::kMaxPhases; ++index) {
        text += std::format("phase {} count={} sum_ns={} max_ns={}", long_name('p', index), kMaxUnsigned, kMaxUnsigned,
            kMaxUnsigned);
        for (std::uint32_t column = 0; column < metrics::kPhaseBucketCount; ++column) {
            text += std::format(" b{:04}={}", column, kMaxUnsigned);
        }
        text += std::format(" over={}\n", kMaxUnsigned);
    }
    text += "end\n";
    return text;
}

[[nodiscard]] std::optional<SnapshotError> error_of(std::string_view text) {
    const auto snapshot = std::make_unique<Snapshot>();
    const std::expected<void, SnapshotError> parsed = metrics::parse_snapshot(text, *snapshot);
    if (parsed) return std::nullopt;
    return parsed.error();
}

[[nodiscard]] std::string text_of(const Snapshot& snapshot) {
    std::vector<char> buffer(metrics::kSnapshotMaxBytes);
    const std::size_t size = metrics::write_snapshot(snapshot, buffer);
    return std::string{buffer.data(), size};
}

[[nodiscard]] std::uint64_t bucket_of(const Registry& registry, Phase phase, std::size_t column) {
    const auto snapshot = std::make_unique<Snapshot>();
    registry.snapshot(*snapshot);
    const PhaseRow& row = std::span{snapshot->phases}[std::to_underlying(phase)];
    return std::span{row.buckets}[column];
}

void catalog_fills_snapshot(Context& context) {
    const auto registry = std::make_unique<Registry>();
    const auto snapshot = std::make_unique<Snapshot>();
    registry->snapshot(*snapshot);
    context.expect(snapshot->counter_count == metrics::kCounterCount, "đủ số bộ đếm của danh mục");
    context.expect(snapshot->gauge_count == metrics::kGaugeCount, "đủ số mức đo của danh mục");
    context.expect(snapshot->phase_count == metrics::kPhaseCount, "đủ số pha của danh mục");
    context.expect(metrics::name_of(Counter::kGateDropRate) == "gate.drop.rate", "tên bộ đếm theo danh mục");
    context.expect(metrics::name_of(Counter::kCount).empty(), "kCount không có tên");
    context.expect(metrics::find_counter(*snapshot, "gate.drop.rate") == 0U, "bộ đếm mới bằng 0");
    context.expect(!metrics::find_counter(*snapshot, "gate.khong.co"), "tên lạ không có");
    context.expect(metrics::find_gauge(*snapshot, "gate.live") == 0, "mức đo mới bằng 0");
    context.expect(metrics::find_phase(*snapshot, "gate.phase.tick") != nullptr, "tìm được pha theo tên");
    context.expect(metrics::find_phase(*snapshot, "gate.live") == nullptr, "pha không lẫn với mức đo");
}

void add_and_set_read_back(Context& context) {
    const auto registry = std::make_unique<Registry>();
    for (int round = 0; round < 100; ++round) {
        registry->add(Counter::kGateDropRate);
    }
    registry->add(Counter::kGateDropFull, 7);
    registry->set(Gauge::kGateLive, 12);
    registry->set(Gauge::kGateLive, -3);
    context.expect(registry->read(Counter::kGateDropRate) == 100, "100 lần add ra 100");
    context.expect(registry->read(Counter::kGateDropFull) == 7, "add theo lượng");
    context.expect(registry->read(Counter::kGateDropIdle) == 0, "bộ đếm khác không đổi");
    context.expect(registry->read(Gauge::kGateLive) == -3, "set ghi đè, giữ số âm");
}

void two_threads_lose_nothing(Context& context) {
    constexpr std::uint64_t kEach = 1'000'000;
    const auto registry = std::make_unique<Registry>();
    const auto work = [&registry] {
        for (std::uint64_t round = 0; round < kEach; ++round) {
            registry->add(Counter::kGateTickTotal);
        }
    };
    {
        const std::jthread first{work};
        const std::jthread second{work};
    }
    context.expect(registry->read(Counter::kGateTickTotal) == 2 * kEach, "hai luồng cộng đủ hai triệu");
}

void record_picks_column_at_edges(Context& context) {
    struct Edge {
        std::int64_t nanos = 0;
        std::size_t column = 0;
    };
    // kTickNs của gate là 16.666.666 ns; phán quyết p99 dùng mép 16,7 ms (mép phải của cột 166).
    constexpr std::array kEdges{
        Edge{.nanos = 0, .column = 0},          Edge{.nanos = 1, .column = 0},
        Edge{.nanos = 100'000, .column = 0},    Edge{.nanos = 100'001, .column = 1},
        Edge{.nanos = 16'666'666, .column = 166}, Edge{.nanos = 16'700'000, .column = 166},
        Edge{.nanos = 16'700'001, .column = 167}, Edge{.nanos = 200'000'000, .column = 1999},
    };
    for (const Edge& edge : kEdges) {
        const auto registry = std::make_unique<Registry>();
        registry->record(Phase::kGateTick, edge.nanos);
        context.expect(bucket_of(*registry, Phase::kGateTick, edge.column) == 1, "mẫu rơi đúng cột ở mép");
    }
}

void record_overflow_and_negative(Context& context) {
    const auto registry = std::make_unique<Registry>();
    registry->record(Phase::kGatePump, 200'000'001);
    registry->record(Phase::kGatePump, std::numeric_limits<std::int64_t>::max());
    registry->record(Phase::kGatePump, -5);
    registry->record(Phase::kGatePump, std::numeric_limits<std::int64_t>::min());
    registry->record(Phase::kGatePump, 250'000);
    const auto snapshot = std::make_unique<Snapshot>();
    registry->snapshot(*snapshot);
    const PhaseRow* row = metrics::find_phase(*snapshot, "gate.phase.pump");
    core::check(row != nullptr, "metrics_tests: pha pump có trong ảnh chụp");
    context.expect(row->over == 2, "trên 200 ms vào cột tràn");
    context.expect(std::span{row->buckets}[0] == 2, "số âm tính như 0, vào cột 0");
    context.expect(std::span{row->buckets}[2] == 1, "250 µs vào cột 2");
    context.expect(row->count == 5, "count đếm mọi mẫu");
    const auto largest = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    context.expect(row->max_ns == largest, "max_ns là mẫu lớn nhất");
    context.expect(row->sum_ns == largest + 200'000'001 + 250'000, "sum_ns cộng mẫu đã kẹp");
    const PhaseRow* other = metrics::find_phase(*snapshot, "gate.phase.tick");
    context.expect(other != nullptr && other->count == 0, "pha khác không đổi");
}

void registry_round_trips_through_text(Context& context) {
    const auto registry = std::make_unique<Registry>();
    registry->add(Counter::kGateDropRate, 500);
    registry->add(Counter::kMetricsReaderDropped, std::numeric_limits<std::uint64_t>::max());
    registry->set(Gauge::kGateLive, std::numeric_limits<std::int64_t>::min());
    registry->set(Gauge::kGateListening, 1);
    registry->record(Phase::kGateTick, 16'700'000);
    registry->record(Phase::kGateTick, 300'000'000);
    const auto before = std::make_unique<Snapshot>();
    registry->snapshot(*before);
    const std::string text = text_of(*before);
    context.expect(text.starts_with("metrics 1\ncounter gate.drop.handshake 0\n"), "dòng đầu và dòng bộ đếm đầu");
    context.expect(text.ends_with(" over=1\nend\n"), "pha cuối ghi cột tràn rồi dòng end");
    context.expect(text.contains(" b166=1 over=1\n"), "chỉ ghi cột khác 0");
    const auto after = std::make_unique<Snapshot>();
    const std::expected<void, SnapshotError> parsed = metrics::parse_snapshot(text, *after);
    context.expect(parsed.has_value(), "đọc lại được ảnh chụp vừa ghi");
    context.expect(text_of(*after) == text, "ghi lại ra đúng từng byte");
    context.expect(metrics::find_counter(*after, "gate.drop.rate") == 500U, "bộ đếm khứ hồi");
    const std::optional<std::uint64_t> dropped = metrics::find_counter(*after, "metrics.reader.dropped");
    context.expect(dropped == std::numeric_limits<std::uint64_t>::max(), "UINT64_MAX khứ hồi");
    const std::optional<std::int64_t> live = metrics::find_gauge(*after, "gate.live");
    context.expect(live == std::numeric_limits<std::int64_t>::min(), "INT64_MIN khứ hồi");
}

void largest_text_is_exactly_the_bound(Context& context) {
    const std::string text = largest_text();
    context.expect(text.size() == metrics::kSnapshotMaxBytes, "ảnh chụp dài nhất đúng bằng kSnapshotMaxBytes");
    const auto snapshot = std::make_unique<Snapshot>();
    const std::expected<void, SnapshotError> parsed = metrics::parse_snapshot(text, *snapshot);
    context.expect(parsed.has_value(), "văn bản dài đúng trần được nhận");
    context.expect(snapshot->counter_count == metrics::kMaxCounters, "đủ trần bộ đếm");
    context.expect(snapshot->gauge_count == metrics::kMaxGauges, "đủ trần mức đo");
    context.expect(snapshot->phase_count == metrics::kMaxPhases, "đủ trần pha");
    const PhaseRow& last = std::span{snapshot->phases}[metrics::kMaxPhases - 1];
    context.expect(std::span{last.buckets}[metrics::kPhaseBucketCount - 1] == std::numeric_limits<std::uint64_t>::max(),
        "cột cuối của pha cuối mang số lớn nhất");
    // Bản ghi lại bỏ số 0 đứng đầu của chỉ số cột nên ngắn hơn, và đọc lại ra cùng nội dung.
    const std::string again = text_of(*snapshot);
    context.expect(again.size() < text.size(), "bản chuẩn không dài hơn trần");
    const auto second = std::make_unique<Snapshot>();
    context.expect(metrics::parse_snapshot(again, *second).has_value(), "bản chuẩn đọc lại được");
    context.expect(text_of(*second) == again, "bản chuẩn khứ hồi từng byte");
    context.expect(error_of(text + "\n") == SnapshotError::kTooLarge, "dài hơn trần một byte là kTooLarge");
}

void parse_reports_each_error(Context& context) {
    struct Bad {
        std::string_view text;
        SnapshotError want = SnapshotError::kLine;
    };
    constexpr std::array kBad{
        Bad{.text = "", .want = SnapshotError::kHeader},
        Bad{.text = "metrics 2\nend\n", .want = SnapshotError::kHeader},
        Bad{.text = "metrics 1", .want = SnapshotError::kHeader},
        Bad{.text = "metrics 1\n", .want = SnapshotError::kNoEnd},
        Bad{.text = "metrics 1\nend", .want = SnapshotError::kNoEnd},
        Bad{.text = "metrics 1\ncounter a.b 1\n", .want = SnapshotError::kNoEnd},
        Bad{.text = "metrics 1\nend\nx", .want = SnapshotError::kTrailing},
        Bad{.text = "metrics 1\nend\n\n", .want = SnapshotError::kTrailing},
        Bad{.text = "metrics 1\nsomething a.b 1\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\n\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\ncounter a.b\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\nphase a.b sum_ns=1 count=1 max_ns=1 over=0\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 x1=1 over=0\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b=1 over=0\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b1x=1 over=0\nend\n", .want = SnapshotError::kLine},
        Bad{.text = "metrics 1\ncounter A.b 1\nend\n", .want = SnapshotError::kName},
        Bad{.text = "metrics 1\ncounter  1\nend\n", .want = SnapshotError::kName},
        Bad{.text = "metrics 1\ngauge a-b 1\nend\n", .want = SnapshotError::kName},
        Bad{.text = "metrics 1\nphase a/b count=1 sum_ns=1 max_ns=1 over=0\nend\n", .want = SnapshotError::kName},
        Bad{.text = "metrics 1\ncounter a.b x\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b \nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b -1\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b +1\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b 1 2\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b 18446744073709551616\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b 000000000000000000001\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ngauge a.b 9223372036854775808\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ngauge a.b -9223372036854775809\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\nphase a.b count=x sum_ns=1 max_ns=1 over=0\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b1=y over=0\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 over=\nend\n", .want = SnapshotError::kNumber},
        Bad{.text = "metrics 1\ncounter a.b 1\ncounter a.b 2\nend\n", .want = SnapshotError::kDuplicate},
        Bad{.text = "metrics 1\ngauge a.b 1\ngauge a.b 1\nend\n", .want = SnapshotError::kDuplicate},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 over=0\nphase a.b count=1 sum_ns=1 max_ns=1 over=0\nend\n",
            .want = SnapshotError::kDuplicate},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b2000=1 over=0\nend\n", .want = SnapshotError::kBucket},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b00001=1 over=0\nend\n", .want = SnapshotError::kBucket},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b7=1 b7=1 over=0\nend\n", .want = SnapshotError::kBucket},
        Bad{.text = "metrics 1\nphase a.b count=1 sum_ns=1 max_ns=1 b7=1 b6=1 over=0\nend\n", .want = SnapshotError::kBucket},
    };
    for (const Bad& bad : kBad) {
        const std::optional<SnapshotError> got = error_of(bad.text);
        if (got == bad.want) continue;
        const std::string_view name = got ? metrics::name_of(*got) : std::string_view{"không lỗi"};
        const std::string what = std::format("mong {} mà ra {}: {}", metrics::name_of(bad.want), name, bad.text);
        context.expect(false, what);
    }
}

void parse_caps_rows_per_kind(Context& context) {
    std::string counters = "metrics 1\n";
    for (std::size_t index = 0; index <= metrics::kMaxCounters; ++index) {
        counters += std::format("counter c{} 1\n", index);
    }
    context.expect(error_of(counters + "end\n") == SnapshotError::kTooMany, "257 bộ đếm là kTooMany");
    std::string gauges = "metrics 1\n";
    for (std::size_t index = 0; index <= metrics::kMaxGauges; ++index) {
        gauges += std::format("gauge g{} 1\n", index);
    }
    context.expect(error_of(gauges + "end\n") == SnapshotError::kTooMany, "65 mức đo là kTooMany");
    std::string phases = "metrics 1\n";
    for (std::size_t index = 0; index <= metrics::kMaxPhases; ++index) {
        phases += std::format("phase p{} count=0 sum_ns=0 max_ns=0 over=0\n", index);
    }
    context.expect(error_of(phases + "end\n") == SnapshotError::kTooMany, "17 pha là kTooMany");
}

void parse_accepts_plain_forms(Context& context) {
    const auto snapshot = std::make_unique<Snapshot>();
    const std::string_view text = "metrics 1\ngauge a.b -0\ncounter a.b 007\n"
                                  "phase a.b count=3 sum_ns=9 max_ns=5 b0000=1 b1999=2 over=0\nend\n";
    context.expect(metrics::parse_snapshot(text, *snapshot).has_value(), "số 0 đứng đầu và thứ tự loại dòng tuỳ ý");
    context.expect(metrics::find_counter(*snapshot, "a.b") == 7U, "007 đọc ra 7");
    context.expect(metrics::find_gauge(*snapshot, "a.b") == 0, "-0 đọc ra 0; cùng tên khác loại không trùng");
    const PhaseRow* row = metrics::find_phase(*snapshot, "a.b");
    context.expect(row != nullptr && std::span{row->buckets}[1999] == 2, "cột cuối đọc được");
    context.expect(error_of("metrics 1\nend\n") == std::nullopt, "ảnh chụp rỗng hợp lệ");
    // Ảnh chụp cũ còn trong out không rò sang lần đọc sau.
    context.expect(metrics::parse_snapshot("metrics 1\nend\n", *snapshot).has_value(), "đọc ảnh chụp rỗng vào out cũ");
    context.expect(!metrics::find_counter(*snapshot, "a.b"), "out được ghi đè trọn");
}

void percentile_follows_nearest_rank(Context& context) {
    const auto registry = std::make_unique<Registry>();
    const auto before = std::make_unique<Snapshot>();
    registry->snapshot(*before);
    const PhaseRow* empty = metrics::find_phase(*before, "gate.phase.tick");
    core::check(empty != nullptr, "metrics_tests: pha tick có trong ảnh chụp");
    context.expect(metrics::percentile_us(*empty, nullptr, 99).spread == Spread::kEmpty, "chưa có mẫu là kEmpty");
    for (int round = 0; round < 99; ++round) {
        registry->record(Phase::kGateTick, 1'000'000);
    }
    registry->record(Phase::kGateTick, 16'700'000);
    const auto after = std::make_unique<Snapshot>();
    registry->snapshot(*after);
    const PhaseRow* row = metrics::find_phase(*after, "gate.phase.tick");
    core::check(row != nullptr, "metrics_tests: pha tick có trong ảnh chụp");
    const Percentile half = metrics::percentile_us(*row, nullptr, 50);
    context.expect(half.spread == Spread::kWithin && half.micros == 1000, "p50 là mép phải của cột 1 ms");
    const Percentile most = metrics::percentile_us(*row, nullptr, 99);
    context.expect(most.spread == Spread::kWithin && most.micros == 1000, "p99 của 100 mẫu là mẫu thứ 99");
    const Percentile all = metrics::percentile_us(*row, nullptr, 100);
    context.expect(all.spread == Spread::kWithin && all.micros == 16'700, "p100 là mép 16,7 ms");
    context.expect(metrics::percentile_us(*row, empty, 100).micros == 16'700, "hiệu với ảnh chụp trước");
    context.expect(metrics::percentile_us(*row, row, 50).spread == Spread::kEmpty, "hiệu với chính nó là kEmpty");
    context.expect(metrics::percentile_us(*empty, row, 50).spread == Spread::kMismatch, "ngược thứ tự là kMismatch");
    registry->record(Phase::kGateTick, 300'000'000);
    registry->record(Phase::kGateTick, 300'000'000);
    registry->snapshot(*after);
    context.expect(metrics::percentile_us(*row, nullptr, 99).spread == Spread::kOver, "p99 rơi vào cột tràn");
    context.expect(metrics::percentile_us(*row, nullptr, 50).spread == Spread::kWithin, "p50 vẫn trong cột");
}

void percentile_rejects_inconsistent_rows(Context& context) {
    const auto snapshot = std::make_unique<Snapshot>();
    // count nói 1 mẫu mà hai cột cộng lại 2: ảnh chụp bị sửa.
    const std::string_view text = "metrics 1\nphase a.b count=1 sum_ns=0 max_ns=0 b9=18446744073709551615 b10=5 over=0\nend\n";
    context.expect(metrics::parse_snapshot(text, *snapshot).has_value(), "ngữ pháp đúng nên đọc được");
    const PhaseRow* row = metrics::find_phase(*snapshot, "a.b");
    core::check(row != nullptr, "metrics_tests: pha a.b có trong ảnh chụp");
    context.expect(metrics::percentile_us(*row, nullptr, 100).spread == Spread::kMismatch, "tổng cột vượt count");
    const std::string_view huge = "metrics 1\nphase a.b count=18446744073709551615 sum_ns=0 max_ns=0 b3=18446744073709551615 over=0\nend\n";
    context.expect(metrics::parse_snapshot(huge, *snapshot).has_value(), "count lớn nhất đọc được");
    const Percentile most = metrics::percentile_us(*row, nullptr, 99);
    context.expect(most.spread == Spread::kWithin && most.micros == 400, "hạng của count lớn nhất không tràn");
}

void error_names_are_distinct(Context& context) {
    constexpr std::array kAll{
        SnapshotError::kTooLarge, SnapshotError::kHeader, SnapshotError::kNoEnd,     SnapshotError::kTrailing,
        SnapshotError::kLine,     SnapshotError::kName,   SnapshotError::kNumber,    SnapshotError::kDuplicate,
        SnapshotError::kBucket,   SnapshotError::kTooMany,
    };
    for (const SnapshotError one : kAll) {
        context.expect(metrics::name_of(one).starts_with("k"), "mỗi lỗi có tên enumerator");
        for (const SnapshotError other : kAll) {
            context.expect(one == other || metrics::name_of(one) != metrics::name_of(other), "tên lỗi không trùng");
        }
    }
    context.expect(metrics::name_of(SnapshotError{0}) == "?", "giá trị ngoài miền có tên riêng");
}

constexpr std::array kCases{
    Case{.name = "catalog_fills_snapshot", .body = catalog_fills_snapshot},
    Case{.name = "add_and_set_read_back", .body = add_and_set_read_back},
    Case{.name = "two_threads_lose_nothing", .body = two_threads_lose_nothing},
    Case{.name = "record_picks_column_at_edges", .body = record_picks_column_at_edges},
    Case{.name = "record_overflow_and_negative", .body = record_overflow_and_negative},
    Case{.name = "registry_round_trips_through_text", .body = registry_round_trips_through_text},
    Case{.name = "largest_text_is_exactly_the_bound", .body = largest_text_is_exactly_the_bound},
    Case{.name = "parse_reports_each_error", .body = parse_reports_each_error},
    Case{.name = "parse_caps_rows_per_kind", .body = parse_caps_rows_per_kind},
    Case{.name = "parse_accepts_plain_forms", .body = parse_accepts_plain_forms},
    Case{.name = "percentile_follows_nearest_rank", .body = percentile_follows_nearest_rank},
    Case{.name = "percentile_rejects_inconsistent_rows", .body = percentile_rejects_inconsistent_rows},
    Case{.name = "error_names_are_distinct", .body = error_names_are_distinct},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "metrics_tests: mọi ca phải qua");
    return 0;
}
