// thienlong_audio — cook cây âm thanh gốc thành tệp .tla trên máy dựng. Game không gọi công cụ này.
//   thienlong_audio cook <thư mục sound gốc> <thư mục ra>
// Tệp .wav và .mp3 thành .tla cùng đường dẫn tương đối; tệp khác (bảng id) chép nguyên. Tệp ra
// không cũ hơn tệp gốc thì bỏ qua, nên chạy lại chỉ cook phần đổi. Chạy song song trên mọi nhân.
// Mã thoát: 0 xong, 1 có tệp lỗi, 2 sai cách dùng.
#include "audio/cook.hpp"
#include "audio/pack.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <functional>
#include <ios>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

namespace {

using Bytes = std::vector<std::byte>;

struct Job {
    std::filesystem::path source;
    std::filesystem::path target;
    // Đường dẫn trong cây sound, dấu gạch xuôi: dùng để phân lớp và in lỗi.
    std::string relative;
    bool is_sound = false;
};

struct Tally {
    std::atomic<std::uint64_t> bytes_in{0};
    std::atomic<std::uint64_t> bytes_out{0};
    std::atomic<std::uint32_t> as_pcm{0};
    std::atomic<std::uint32_t> as_opus{0};
    std::atomic<std::uint32_t> copied{0};
    std::atomic<std::uint32_t> skipped{0};
    std::atomic<std::uint32_t> failed{0};
};

[[nodiscard]] char lower(char letter) noexcept {
    const bool is_upper = letter >= 'A' && letter <= 'Z';
    return is_upper ? static_cast<char>(letter - 'A' + 'a') : letter;
}

[[nodiscard]] bool has_sound_extension(const std::filesystem::path& path) {
    std::string extension = path.extension().string();
    std::ranges::transform(extension, extension.begin(), &lower);
    return extension == ".wav" || extension == ".mp3";
}

[[nodiscard]] std::optional<Bytes> read_file(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input) return std::nullopt;
    const std::streamoff end = input.tellg();
    if (end <= 0) return std::nullopt;
    Bytes bytes(static_cast<std::size_t>(end));
    input.seekg(0);
    // ifstream nhận char; std::byte và char được phép trỏ cùng vùng nhớ.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    input.read(reinterpret_cast<char*>(bytes.data()), end);
    if (!input) return std::nullopt;
    return bytes;
}

// Ghi ra tệp tạm cạnh đích rồi đổi tên: lần chạy bị ngắt không để lại tệp .tla dở.
[[nodiscard]] bool write_file(const std::filesystem::path& path, std::span<const std::byte> bytes) {
    std::error_code failure;
    std::filesystem::create_directories(path.parent_path(), failure);
    std::filesystem::path pending = path;
    pending += ".part";
    std::ofstream output(pending, std::ios::binary | std::ios::trunc);
    if (!output) return false;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    const auto* raw = reinterpret_cast<const char*>(bytes.data());
    output.write(raw, static_cast<std::streamsize>(bytes.size()));
    output.close();
    if (!output) return false;
    std::filesystem::rename(pending, path, failure);
    return !failure;
}

struct Roots {
    std::filesystem::path from;
    std::filesystem::path into;
};

void add_job(std::vector<Job>& jobs, const std::filesystem::directory_entry& entry, const Roots& roots) {
    if (!entry.is_regular_file()) return;
    Job job;
    job.source = entry.path();
    const std::filesystem::path relative = job.source.lexically_relative(roots.from);
    job.relative = game::io::utf8_of(relative);
    std::ranges::replace(job.relative, '\\', '/');
    job.is_sound = has_sound_extension(job.source);
    job.target = roots.into / relative;
    if (job.is_sound) job.target.replace_extension(".tla");
    jobs.push_back(std::move(job));
}

[[nodiscard]] std::vector<Job> plan_jobs(const Roots& roots) {
    std::vector<Job> jobs;
    std::error_code failure;
    const std::filesystem::recursive_directory_iterator walk(roots.from, failure);
    for (const std::filesystem::directory_entry& entry : walk) {
        add_job(jobs, entry, roots);
    }
    return jobs;
}

[[nodiscard]] bool is_fresh(const Job& job) {
    std::error_code failure;
    const auto made = std::filesystem::last_write_time(job.target, failure);
    if (failure) return false;
    const auto source = std::filesystem::last_write_time(job.source, failure);
    return !failure && made >= source;
}

void fail_job(const Job& job, std::string_view why, Tally& tally) {
    tally.failed.fetch_add(1, std::memory_order_relaxed);
    std::println(stderr, "Lỗi: {}: {}", job.relative, why);
}

void cook_job(const Job& job, const Bytes& source, Tally& tally) {
    const game::audio::CookClass kind = game::audio::classify(job.relative);
    const game::core::Result<game::audio::Cooked> cooked = game::audio::cook_sound(source, kind);
    if (!cooked) {
        fail_job(job, cooked.error().message(), tally);
        return;
    }
    if (!write_file(job.target, cooked->bytes)) {
        fail_job(job, "không ghi được tệp ra", tally);
        return;
    }
    const bool is_opus = cooked->codec == game::audio::PackCodec::kOpus;
    std::atomic<std::uint32_t>& counter = is_opus ? tally.as_opus : tally.as_pcm;
    counter.fetch_add(1, std::memory_order_relaxed);
    tally.bytes_out.fetch_add(cooked->bytes.size(), std::memory_order_relaxed);
}

void copy_job(const Job& job, const Bytes& source, Tally& tally) {
    if (!write_file(job.target, source)) {
        fail_job(job, "không chép được tệp", tally);
        return;
    }
    tally.copied.fetch_add(1, std::memory_order_relaxed);
    tally.bytes_out.fetch_add(source.size(), std::memory_order_relaxed);
}

void run_job(const Job& job, Tally& tally) {
    if (is_fresh(job)) {
        tally.skipped.fetch_add(1, std::memory_order_relaxed);
        return;
    }
    const std::optional<Bytes> source = read_file(job.source);
    if (!source) {
        fail_job(job, "không đọc được tệp gốc", tally);
        return;
    }
    tally.bytes_in.fetch_add(source->size(), std::memory_order_relaxed);
    if (job.is_sound) {
        cook_job(job, *source, tally);
        return;
    }
    copy_job(job, *source, tally);
}

// Mỗi luồng lấy việc kế tiếp bằng một bộ đếm chung: tệp nhạc dài và tiếng bấm ngắn tự cân.
void work(std::span<const Job> jobs, std::atomic<std::size_t>& next, Tally& tally) {
    std::size_t index = next.fetch_add(1, std::memory_order_relaxed);
    while (index < jobs.size()) {
        run_job(jobs[index], tally);
        index = next.fetch_add(1, std::memory_order_relaxed);
    }
}

void run_all(std::span<const Job> jobs, Tally& tally) {
    const unsigned cores = std::max(1U, std::thread::hardware_concurrency());
    std::atomic<std::size_t> next{0};
    std::vector<std::jthread> workers;
    workers.reserve(cores);
    for (unsigned core = 0; core < cores; ++core) {
        workers.emplace_back(&work, jobs, std::ref(next), std::ref(tally));
    }
}

[[nodiscard]] int cook_tree(const Roots& roots) {
    const auto started = std::chrono::steady_clock::now();
    const std::vector<Job> jobs = plan_jobs(roots);
    if (jobs.empty()) {
        std::println(stderr, "Lỗi: không thấy tệp nào trong {}", game::io::utf8_of(roots.from));
        return 1;
    }
    Tally tally;
    run_all(jobs, tally);
    const std::chrono::duration<double> spent = std::chrono::steady_clock::now() - started;
    constexpr double kMega = 1024.0 * 1024.0;
    const double megabytes_in = static_cast<double>(tally.bytes_in.load()) / kMega;
    const double megabytes_out = static_cast<double>(tally.bytes_out.load()) / kMega;
    std::println("Cook âm thanh: {} tệp, {} PCM, {} Opus, {} chép nguyên, {} bỏ qua, {} lỗi", jobs.size(),
        tally.as_pcm.load(), tally.as_opus.load(), tally.copied.load(), tally.skipped.load(), tally.failed.load());
    std::println("Cook âm thanh: {:.1f} MB vào, {:.1f} MB ra, {:.1f} giây", megabytes_in, megabytes_out, spent.count());
    return tally.failed.load() == 0 ? 0 : 1;
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(int argc, char** argv) {
    game::io::use_utf8_console();
    const std::span<char*> arguments(argv, static_cast<std::size_t>(argc));
    const bool is_cook = arguments.size() == 4 && std::string_view(arguments[1]) == "cook";
    if (!is_cook) {
        std::println(stderr, "cách dùng: thienlong_audio cook <thư mục sound gốc> <thư mục ra>");
        return 2;
    }
    const Roots roots{.from = game::io::path_from_utf8(arguments[2]), .into = game::io::path_from_utf8(arguments[3])};
    return cook_tree(roots);
}
