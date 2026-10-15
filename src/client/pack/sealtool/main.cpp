// thienlong_seal — niêm cây asset thành .tlpak trên máy dựng. Game không gọi công cụ này.
//   thienlong_seal new-key --out <khoá>
//   thienlong_seal seal --key <khoá> --from <thư mục> --out <tệp.tlpak>
//   thienlong_seal open --key <khoá> --from <tệp.tlpak> --out <thư mục>
//   thienlong_seal verify --key <khoá> --from <tệp.tlpak>
// Mã thoát: 0 xong, 1 dữ liệu, 2 cách dùng. Đối số lấy bằng io::command_arguments (Windows: dòng lệnh UTF-16).
#include "io/file.hpp"
#include "io/platform.hpp"
#include "seal/package.hpp"
#include "seal/tree.hpp"

#include <cstddef>
#include <cstdio>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace {

using game::seal::Error;
using game::seal::TreePaths;
using Texts = std::span<const std::string>;

constexpr std::string_view kUsage =
    "cách dùng:\n"
    "  thienlong_seal new-key --out <khoá>\n"
    "  thienlong_seal seal --key <khoá> --from <thư mục> --out <tệp.tlpak>\n"
    "  thienlong_seal open --key <khoá> --from <tệp.tlpak> --out <thư mục>\n"
    "  thienlong_seal verify --key <khoá> --from <tệp.tlpak>\n"
    "Khoá không nằm trong client. Game không đọc gói này nên tốc độ nạp và khung hình không đổi.\n"
    "Ảnh chụp GPU lúc game đang chạy vẫn thấy asset đã đưa lên bộ nhớ hình.\n";

struct Request {
    std::string command;
    std::string key;
    std::string from;
    std::string out;
    bool failed = false;
};

[[nodiscard]] int fail_usage(std::string_view message) {
    std::println(stderr, "thienlong_seal: {}", message);
    std::println(stderr, "{}", kUsage);
    return 2;
}

[[nodiscard]] int fail_data(Error error) {
    const std::string_view message = game::seal::describe(error);
    std::println(stderr, "thienlong_seal: {}", message);
    return 1;
}

struct FlagValue {
    std::string_view flag;
    std::string_view value;
};

void apply_flag(Request& request, FlagValue pair) {
    if (request.failed) return;
    if (pair.flag == "--key")
        request.key = std::string(pair.value);
    else if (pair.flag == "--from")
        request.from = std::string(pair.value);
    else if (pair.flag == "--out")
        request.out = std::string(pair.value);
    else
        request.failed = true;
}

[[nodiscard]] bool take_one(Request& request, Texts args, std::size_t& index) {
    if (request.failed || index >= args.size()) return false;
    const std::string_view flag = args[index];
    if (!flag.starts_with("--") || index + 1 >= args.size()) {
        request.failed = true;
        return false;
    }
    const FlagValue pair{.flag = flag, .value = args[index + 1]};
    apply_flag(request, pair);
    index += 2;
    return !request.failed;
}

[[nodiscard]] bool take_arguments(Request& request, Texts args) {
    if (args.empty()) return false;
    request.command = args[0];
    std::size_t index = 1;
    bool alive = true;
    while (index < args.size() && alive)
        alive = take_one(request, args, index);
    return alive && !request.failed;
}

[[nodiscard]] bool fields_of(const Request& request, std::string_view need) {
    const bool key = !need.contains('k') || !request.key.empty();
    const bool from = !need.contains('f') || !request.from.empty();
    const bool out = !need.contains('o') || !request.out.empty();
    const bool extra_key = need.contains('k') || request.key.empty();
    const bool extra_from = need.contains('f') || request.from.empty();
    const bool extra_out = need.contains('o') || request.out.empty();
    return key && from && out && extra_key && extra_from && extra_out;
}

[[nodiscard]] int run_new_key(const Request& request) {
    if (!fields_of(request, "o")) return fail_usage("new-key chỉ nhận --out");
    auto key = game::seal::random_key();
    if (!key) return fail_data(key.error());
    const auto path = game::io::path_from_utf8(request.out);
    const auto stored = game::seal::store_key(*key, path);
    if (!stored) return fail_data(stored.error());
    std::println("đã ghi khoá");
    return 0;
}

[[nodiscard]] int run_seal(const Request& request) {
    if (!fields_of(request, "kfo")) return fail_usage("seal cần --key, --from và --out");
    const auto key_path = game::io::path_from_utf8(request.key);
    const auto from = game::io::path_from_utf8(request.from);
    const auto into = game::io::path_from_utf8(request.out);
    auto key = game::seal::load_key(key_path);
    if (!key) return fail_data(key.error());
    const TreePaths paths{.from = &from, .into = &into};
    const auto saved = game::seal::seal_folder(*key, paths);
    if (!saved) return fail_data(saved.error());
    std::println("đã niêm {} tệp, {} byte", saved->files, saved->bytes);
    return 0;
}

[[nodiscard]] int run_open(const Request& request) {
    if (!fields_of(request, "kfo")) return fail_usage("open cần --key, --from và --out");
    const auto key_path = game::io::path_from_utf8(request.key);
    const auto from = game::io::path_from_utf8(request.from);
    const auto into = game::io::path_from_utf8(request.out);
    auto key = game::seal::load_key(key_path);
    if (!key) return fail_data(key.error());
    const TreePaths paths{.from = &from, .into = &into};
    const auto saved = game::seal::open_folder(*key, paths);
    if (!saved) return fail_data(saved.error());
    std::println("đã mở {} tệp, {} byte", saved->files, saved->bytes);
    return 0;
}

[[nodiscard]] int run_verify(const Request& request) {
    if (!fields_of(request, "kf")) return fail_usage("verify cần --key và --from");
    const auto key_path = game::io::path_from_utf8(request.key);
    const auto from = game::io::path_from_utf8(request.from);
    auto key = game::seal::load_key(key_path);
    if (!key) return fail_data(key.error());
    const auto saved = game::seal::verify_folder(*key, from);
    if (!saved) return fail_data(saved.error());
    std::println("gói nguyên, {} tệp, {} byte", saved->files, saved->bytes);
    return 0;
}

[[nodiscard]] int run_command(const Request& request) {
    if (request.command == "new-key") return run_new_key(request);
    if (request.command == "seal") return run_seal(request);
    if (request.command == "open") return run_open(request);
    if (request.command == "verify") return run_verify(request);
    return fail_usage("lệnh không rõ");
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    game::io::use_utf8_console();
    const std::vector<std::string> args = game::io::command_arguments(argc, argv);
    if (args.empty()) return fail_usage("thiếu lệnh");
    Request request;
    const bool parsed = take_arguments(request, args);
    if (!parsed) return fail_usage("đối số không hợp lệ");
    return run_command(request);
}
