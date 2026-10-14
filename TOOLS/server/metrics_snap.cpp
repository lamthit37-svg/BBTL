// thienlong_metrics_snap: chụp ảnh số đo của một tiến trình máy chủ qua cổng metrics của nó, và đọc
// một số ra khỏi ảnh chụp đã lưu. Kịch bản kiểm chỉ gọi exe này rồi đọc một số hoặc một dòng
// `khoá=số`; không có bộ đọc ảnh chụp thứ hai nào ngoài metrics::parse_snapshot.
//   capture --port <cổng> --out <tệp> [--timeout-ms <n>]   nối 127.0.0.1:<cổng>, ghi đúng byte đã nhận
//   counter --after <tệp> [--before <tệp>] --name <tên>      in after − before (hoặc after)
//   gauge   --at <tệp> --name <tên>                           in một số có dấu
//   phase   --after <tệp> [--before <tệp>] --name <tên>      in count=.. p50_us=.. p99_us=.. max_ns=..
// stdout chỉ mang kết quả cho máy đọc; câu cho người đọc ra stderr. Mã thoát: 0 xong, 1 lỗi lúc
// chạy (nối hỏng, hết hạn, ảnh chụp sai, tên không có, before lớn hơn after), 2 dùng sai.
// Ảnh chụp tới từ socket hay tệp đều là dữ liệu không tin được: đọc tối đa kSnapshotMaxBytes + 1 byte.
// Đặc tả: thienlong-specs/coder-server/metrics.md mục 7.3. Hạn mặc định 2000 ms là số tự đặt.
#include "core/clock.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "metrics/metrics.hpp"
#include "net/net.hpp"
#include "process/process.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <fstream>
#include <ios>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace {

using game::core::Clock;
using game::metrics::Percentile;
using game::metrics::PhaseRow;
using game::metrics::Snapshot;
using game::metrics::Spread;
using game::net::Milliseconds;
using game::net::NetResult;
using game::net::TcpStream;

constexpr int kExitRuntime = 1;
constexpr int kExitUsage = 2;
constexpr Milliseconds kDefaultTimeout{2000};
// Trần của --timeout-ms: mười phút, đủ cho mọi kịch bản mà không để một số gõ nhầm treo cả lượt chạy.
constexpr std::int64_t kMaxTimeoutMs = 600'000;
constexpr std::size_t kReadCap = game::metrics::kSnapshotMaxBytes + 1;

constexpr std::string_view kUsage =
    "cách dùng:\n"
    "  thienlong_metrics_snap capture --port <cổng> --out <tệp> [--timeout-ms <n>]\n"
    "  thienlong_metrics_snap counter --after <tệp> [--before <tệp>] --name <tên>\n"
    "  thienlong_metrics_snap gauge --at <tệp> --name <tên>\n"
    "  thienlong_metrics_snap phase --after <tệp> [--before <tệp>] --name <tên>";

using Flag = std::optional<std::string_view>;

struct Flags {
    Flag port;
    Flag out;
    Flag timeout;
    Flag after;
    Flag before;
    Flag at;
    Flag name;
};

// Con trỏ tới một cờ của Flags.
using Slot = Flag Flags::*;

struct Key {
    std::string_view text;
    Slot slot = nullptr;
};

constexpr std::array kKeys{
    Key{.text = "--port", .slot = &Flags::port},     Key{.text = "--out", .slot = &Flags::out},
    Key{.text = "--timeout-ms", .slot = &Flags::timeout}, Key{.text = "--after", .slot = &Flags::after},
    Key{.text = "--before", .slot = &Flags::before}, Key{.text = "--at", .slot = &Flags::at},
    Key{.text = "--name", .slot = &Flags::name},
};

// Một lệnh con: cờ bắt buộc và cờ tuỳ chọn. Cờ ngoài hai danh sách là dùng sai.
struct Command {
    std::string_view word;
    std::span<const Slot> required;
    std::span<const Slot> optional;
};

constexpr std::array<Slot, 2> kCaptureNeeds{&Flags::port, &Flags::out};
constexpr std::array<Slot, 1> kCaptureMay{&Flags::timeout};
constexpr std::array<Slot, 2> kDeltaNeeds{&Flags::after, &Flags::name};
constexpr std::array<Slot, 1> kDeltaMay{&Flags::before};
constexpr std::array<Slot, 2> kGaugeNeeds{&Flags::at, &Flags::name};

[[nodiscard]] int fail_usage(std::string_view why) {
    std::println(stderr, "thienlong_metrics_snap: {}", why);
    std::println(stderr, "{}", kUsage);
    return kExitUsage;
}

[[nodiscard]] int fail_run(std::string_view why) {
    std::println(stderr, "thienlong_metrics_snap: {}", why);
    return kExitRuntime;
}

// Các cặp `--cờ giá_trị`. false khi gặp cờ lạ, cờ lặp hay cờ thiếu giá trị.
[[nodiscard]] bool read_flags(std::span<const std::string> words, Flags& flags) {
    for (std::size_t index = 0; index < words.size(); index += 2) {
        const std::string_view word = words[index];
        const auto key = std::ranges::find(kKeys, word, &Key::text);
        if (key == kKeys.end() || index + 1 >= words.size()) return false;
        Flag& slot = flags.*(key->slot);
        if (slot) return false;
        slot = words[index + 1];
    }
    return true;
}

[[nodiscard]] bool fits(const Flags& flags, const Command& command) {
    const auto is_set = [&flags](Slot slot) { return (flags.*slot).has_value(); };
    if (!std::ranges::all_of(command.required, is_set)) return false;
    const auto is_allowed = [&command](const Key& key) {
        return std::ranges::contains(command.required, key.slot) || std::ranges::contains(command.optional, key.slot);
    };
    return std::ranges::all_of(kKeys, [&](const Key& key) { return !is_set(key.slot) || is_allowed(key); });
}

// Trọn text là một số nguyên trong least..most.
[[nodiscard]] std::optional<std::int64_t> number_in(std::string_view text, std::int64_t least, std::int64_t most) {
    std::int64_t value = 0;
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{} || stop != last || value < least || value > most) return std::nullopt;
    return value;
}

// Đọc một ảnh chụp đã lưu. Tệp dài hơn trần bị từ chối trước khi đọc byte nào.
[[nodiscard]] std::unique_ptr<Snapshot> load(std::string_view file) {
    const std::filesystem::path path = game::io::path_from_utf8(file);
    std::error_code error;
    const std::uintmax_t size = std::filesystem::file_size(path, error);
    if (error) {
        std::println(stderr, "thienlong_metrics_snap: không đọc được {}", file);
        return nullptr;
    }
    if (size > game::metrics::kSnapshotMaxBytes) {
        std::println(stderr, "thienlong_metrics_snap: {} sai: kTooLarge", file);
        return nullptr;
    }
    std::string text(static_cast<std::size_t>(size), '\0');
    std::ifstream in{path, std::ios::binary};
    in.read(text.data(), static_cast<std::streamsize>(text.size()));
    if (!in || static_cast<std::size_t>(in.gcount()) != text.size()) {
        std::println(stderr, "thienlong_metrics_snap: không đọc được {}", file);
        return nullptr;
    }
    auto snapshot = std::make_unique<Snapshot>();
    const std::expected<void, game::metrics::SnapshotError> parsed = game::metrics::parse_snapshot(text, *snapshot);
    if (parsed) return snapshot;
    std::println(stderr, "thienlong_metrics_snap: {} sai: {}", file, game::metrics::name_of(parsed.error()));
    return nullptr;
}

// Chờ socket có sự kiện tới hạn deadline; false khi hết hạn hoặc tập chờ lỗi.
[[nodiscard]] bool wait_until(game::net::SocketHandle socket, bool for_write, Clock::time_point deadline) {
    const auto left = std::chrono::duration_cast<Milliseconds>(deadline - Clock::now());
    if (left <= Milliseconds::zero()) return false;
    game::net::PollSet poll;
    game::net::PollEvents events;
    if (!poll.add(socket, 1)) return false;
    poll.want_write(1, for_write);
    return poll.wait(left, events).has_value() && !events.empty();
}

enum class Fetch : std::uint8_t { kDone, kConnect, kTimeout, kBroken, kTooLarge };

// Nối 127.0.0.1:port và đọc tới khi bên kia đóng. Đủ kReadCap byte thì dừng: ảnh chụp vượt trần.
[[nodiscard]] Fetch fetch(std::uint16_t port, Clock::time_point deadline, std::vector<char>& text) {
    NetResult<TcpStream> stream = TcpStream::begin_connect(game::net::Endpoint{.address = {127, 0, 0, 1}, .port = port});
    if (!stream) return Fetch::kConnect;
    if (!wait_until(stream->handle(), true, deadline)) return Fetch::kTimeout;
    const NetResult<bool> joined = stream->finish_connect();
    if (!joined || !*joined) return Fetch::kConnect;
    text.assign(kReadCap, '\0');
    std::size_t got = 0;
    while (got < kReadCap) {
        if (!wait_until(stream->handle(), false, deadline)) return Fetch::kTimeout;
        const NetResult<std::size_t> read = stream->receive(std::as_writable_bytes(std::span{text}.subspan(got)));
        if (!read && read.error() == game::net::NetError::kClosed) {
            text.resize(got);
            return Fetch::kDone;
        }
        if (!read) return Fetch::kBroken;
        got += *read;
    }
    return Fetch::kTooLarge;
}

// Ghi qua tệp tạm cùng thư mục rồi đổi tên: bên đọc không bao giờ thấy tệp dở.
[[nodiscard]] bool write_whole(const std::filesystem::path& path, std::span<const char> text) {
    std::filesystem::path partial = path;
    partial += ".tmp";
    {
        std::ofstream out{partial, std::ios::binary | std::ios::trunc};
        out.write(text.data(), static_cast<std::streamsize>(text.size()));
        out.flush();
        if (!out) return false;
    }
    std::error_code error;
    std::filesystem::rename(partial, path, error);
    if (!error) return true;
    std::filesystem::remove(partial, error);
    return false;
}

[[nodiscard]] int capture(const Flags& flags) {
    const std::optional<std::int64_t> port = number_in(flags.port.value_or(""), 1, 65535);
    if (!port) return fail_usage("--port phải là số trong 1..65535");
    std::optional<std::int64_t> timeout = kDefaultTimeout.count();
    if (flags.timeout) timeout = number_in(*flags.timeout, 1, kMaxTimeoutMs);
    if (!timeout) return fail_usage("--timeout-ms phải là số trong 1..600000");
    const NetResult<game::net::Network> network = game::net::Network::start();
    if (!network) return fail_run("không khởi động được thư viện mạng");
    std::vector<char> text;
    const Clock::time_point deadline = Clock::now() + Milliseconds{*timeout};
    switch (fetch(static_cast<std::uint16_t>(*port), deadline, text)) {
    case Fetch::kDone: break;
    case Fetch::kConnect: return fail_run("không nối được cổng metrics");
    case Fetch::kTimeout: return fail_run("hết hạn chờ cổng metrics");
    case Fetch::kBroken: return fail_run("kết nối tới cổng metrics bị đứt");
    case Fetch::kTooLarge: return fail_run("ảnh chụp sai: kTooLarge");
    }
    const auto snapshot = std::make_unique<Snapshot>();
    const std::string_view view{text.data(), text.size()};
    const std::expected<void, game::metrics::SnapshotError> parsed = game::metrics::parse_snapshot(view, *snapshot);
    if (!parsed) {
        std::println(stderr, "thienlong_metrics_snap: ảnh chụp sai: {}", game::metrics::name_of(parsed.error()));
        return kExitRuntime;
    }
    if (!write_whole(game::io::path_from_utf8(flags.out.value_or("")), text)) return fail_run("không ghi được tệp ảnh chụp");
    return 0;
}

struct Pair {
    std::unique_ptr<Snapshot> after;
    std::unique_ptr<Snapshot> before;
    bool is_loaded = false;
};

[[nodiscard]] Pair load_pair(const Flags& flags) {
    Pair pair;
    pair.after = load(flags.after.value_or(""));
    if (flags.before) pair.before = load(*flags.before);
    pair.is_loaded = pair.after != nullptr && (!flags.before || pair.before != nullptr);
    return pair;
}

[[nodiscard]] int counter(const Flags& flags) {
    const Pair pair = load_pair(flags);
    if (!pair.is_loaded) return kExitRuntime;
    const std::string_view name = flags.name.value_or("");
    const std::optional<std::uint64_t> after = game::metrics::find_counter(*pair.after, name);
    std::optional<std::uint64_t> before = 0;
    if (pair.before) before = game::metrics::find_counter(*pair.before, name);
    if (!after || !before) return fail_run("không có bộ đếm mang tên đó");
    if (*after < *before) return fail_run("bộ đếm ở --before lớn hơn ở --after");
    std::println("{}", *after - *before);
    return 0;
}

[[nodiscard]] int gauge(const Flags& flags) {
    const std::unique_ptr<Snapshot> snapshot = load(flags.at.value_or(""));
    if (!snapshot) return kExitRuntime;
    const std::optional<std::int64_t> value = game::metrics::find_gauge(*snapshot, flags.name.value_or(""));
    if (!value) return fail_run("không có mức đo mang tên đó");
    std::println("{}", *value);
    return 0;
}

// Một phân vị thành chữ: số micro giây, ">200000" khi rơi vào cột tràn, 0 khi không có mẫu.
[[nodiscard]] std::string shown(Percentile percentile) {
    if (percentile.spread == Spread::kOver) return std::format(">{}", game::metrics::kPhaseCeilingUs);
    return std::format("{}", percentile.spread == Spread::kWithin ? percentile.micros : 0);
}

[[nodiscard]] int phase(const Flags& flags) {
    const Pair pair = load_pair(flags);
    if (!pair.is_loaded) return kExitRuntime;
    const std::string_view name = flags.name.value_or("");
    const PhaseRow* const after = game::metrics::find_phase(*pair.after, name);
    const PhaseRow* const before = pair.before ? game::metrics::find_phase(*pair.before, name) : nullptr;
    if (after == nullptr || (pair.before && before == nullptr)) return fail_run("không có pha mang tên đó");
    const Percentile half = game::metrics::percentile_us(*after, before, 50);
    const Percentile most = game::metrics::percentile_us(*after, before, 99);
    if (half.spread == Spread::kMismatch || most.spread == Spread::kMismatch) {
        return fail_run("ảnh chụp --before không đứng trước --after");
    }
    const std::uint64_t count = after->count - (before != nullptr ? before->count : 0);
    // max_ns là lớn nhất từ lúc tiến trình chạy: hiệu hai ảnh chụp không cho max của riêng khoảng đo.
    std::println("count={} p50_us={} p99_us={} max_ns={}", count, shown(half), shown(most), after->max_ns);
    return 0;
}

[[nodiscard]] int run(std::span<const std::string> words) {
    if (words.empty()) return fail_usage("thiếu lệnh con");
    const std::array commands{
        Command{.word = "capture", .required = kCaptureNeeds, .optional = kCaptureMay},
        Command{.word = "counter", .required = kDeltaNeeds, .optional = kDeltaMay},
        Command{.word = "gauge", .required = kGaugeNeeds, .optional = {}},
        Command{.word = "phase", .required = kDeltaNeeds, .optional = kDeltaMay},
    };
    const auto command = std::ranges::find(commands, std::string_view{words.front()}, &Command::word);
    if (command == commands.end()) return fail_usage("lệnh con lạ");
    Flags flags;
    if (!read_flags(words.subspan(1), flags) || !fits(flags, *command)) return fail_usage("đối số sai");
    if (command->word == "capture") return capture(flags);
    if (command->word == "counter") return counter(flags);
    if (command->word == "gauge") return gauge(flags);
    return phase(flags);
}

} // namespace

int main(int argc, char** argv) {
    game::io::use_utf8_console();
    const std::vector<std::string> words = game::process::utf8_arguments(argc, argv);
    return run(words);
}
