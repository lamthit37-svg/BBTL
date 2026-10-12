// Test phiên mở đầu: tên cảnh bị từ chối trước khi đọc đĩa, thiếu tệp không ném, vào game chỉ
// đổi trạng thái khi enter thành công, lời nhờ lạ không bị coi là thoát.
#include "client/boot.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <ios>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::test {
namespace {

constexpr std::string_view kScene = "<Scene name=\"a\"></Scene>\n";
constexpr std::string_view kBroken = "<Scene><Object></Scene>\n";
constexpr std::string_view kTerrain = "<Scene name=\"a\"><Terrain filename=\"khong-co.Terrain\"/></Scene>\n";

struct Scratch {
    std::filesystem::path root;
    explicit Scratch(std::filesystem::path path) : root(std::move(path)) {
        std::error_code ignored;
        std::filesystem::remove_all(root, ignored);
        std::filesystem::create_directories(root / "Scene");
        std::filesystem::create_directories(root / "Config");
    }
    Scratch(const Scratch&) = delete;
    Scratch& operator=(const Scratch&) = delete;
    Scratch(Scratch&&) = delete;
    Scratch& operator=(Scratch&&) = delete;
    // NOLINTNEXTLINE(bugprone-exception-escape): remove_all(error_code) không ném
    ~Scratch() noexcept {
        std::error_code ignored;
        std::filesystem::remove_all(root, ignored);
    }
};

[[nodiscard]] bool write_text(const std::filesystem::path& path, std::string_view text) {
    std::ofstream out(path, std::ios::binary);
    out.write(text.data(), static_cast<std::streamsize>(text.size()));
    return static_cast<bool>(out);
}

[[nodiscard]] Scratch scratch_of(std::string_view leaf) {
    return Scratch(std::filesystem::temp_directory_path() / leaf);
}

[[nodiscard]] bool problem_has(const client::BootLoad& boot, std::string_view piece) {
    bool found = false;
    for (const client::BootLoad::Line& line : boot.lines) {
        found = found || (line.is_problem && line.text.contains(piece));
    }
    return found;
}

void reject_a_name_that_leaves_the_scene_folder(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-name");
    const client::NamedScene named = client::load_named_scene(dir.root, "../ngoai", client::kBackdropSceneId);
    context.expect(!named.shown, "không mở cảnh khi tên có đường thoát");
    context.expect(named.error == "tên cảnh không hợp lệ", "báo tên không hợp lệ");
    context.expect(!std::filesystem::exists(dir.root / "ngoai.Scene"), "không tạo và không đọc tệp ngoài Scene");
    const client::NamedScene drive = client::load_named_scene(dir.root, "C:ngoai", client::kBackdropSceneId);
    context.expect(!drive.shown && drive.error == "tên cảnh không hợp lệ", "tên có dấu hai chấm không đọc đĩa");
}

void missing_scene_is_an_error_without_a_throw(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-miss");
    const client::NamedScene named = client::load_named_scene(dir.root, "erengu_DL", client::kBackdropSceneId);
    context.expect(!named.shown, "thiếu tệp thì không có cảnh");
    context.expect(!named.error.empty(), "thiếu tệp thì có một dòng lỗi");
}

void broken_scene_is_an_error(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-bad");
    context.expect(write_text(dir.root / "Scene" / "erengu_DL.Scene", kBroken), "ghi được tệp hỏng");
    const client::NamedScene named = client::load_named_scene(dir.root, "erengu_DL", client::kBackdropSceneId);
    context.expect(!named.shown, "XML hỏng không thành cảnh");
    context.expect(named.error.contains("tệp cảnh hỏng"), "lỗi nói tệp hỏng");
}

void terrain_miss_keeps_the_scene(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-terrain");
    context.expect(write_text(dir.root / "Scene" / "erengu_DL.Scene", kTerrain), "ghi được cảnh");
    const client::NamedScene named = client::load_named_scene(dir.root, "erengu_DL", client::kBackdropSceneId);
    context.expect(named.shown != nullptr, "thiếu địa hình vẫn giữ cảnh");
    context.expect(!named.terrain.empty(), "địa hình thiếu có một dòng");
    context.expect(named.summary.empty(), "không có dòng đã nạp");
    if (!named.shown) return;
    context.expect(named.shown->id == client::kBackdropSceneId, "giữ id nền đăng nhập");
}

void empty_folder_loads_a_login_without_throwing(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-empty");
    const client::BootLoad boot = client::load_login(dir.root);
    context.expect(!boot.playing, "không có bảng thì chưa có thế giới");
    context.expect(!boot.backdrop, "không có nền đăng nhập");
    context.expect(!boot.role_scene, "không có nền chọn nhân vật");
    context.expect(!boot.first_scene, "không có cảnh đầu");
    context.expect(problem_has(boot, "không đọc được Config/startup.id") || problem_has(boot, "Bảng cảnh"),
        "mỗi thứ thiếu để lại một dòng lỗi");
}

void login_keeps_scenes_and_does_not_enter(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-login");
    context.expect(write_text(dir.root / "Scene" / "erengu_DL.Scene", kScene), "ghi nền đăng nhập");
    context.expect(write_text(dir.root / "Scene" / "tl3chuangjian.Scene", kScene), "ghi nền chọn nhân vật");
    constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\n";
    context.expect(write_text(dir.root / "Config" / "SceneDefineEx.txt", kTable), "ghi bảng cảnh");
    context.expect(write_text(dir.root / "Config" / "startup.id", "251\n"), "ghi startup.id");
    context.expect(write_text(dir.root / "Scene" / "huoyangu.Scene", kScene), "ghi cảnh chơi");
    const client::BootLoad boot = client::load_login(dir.root);
    context.expect(boot.backdrop != nullptr && boot.backdrop->id == client::kBackdropSceneId, "nền đăng nhập");
    context.expect(boot.role_scene != nullptr && boot.role_scene->id == client::kRoleSceneId, "nền chọn nhân vật");
    context.expect(boot.playing.has_value(), "bảng mở được");
    context.expect(boot.first_scene == 251, "startup.id là resid cảnh chơi");
    context.expect(boot.playing && !boot.playing->current, "chưa vào cảnh chơi");
}

void bad_startup_id_does_not_invent_a_scene(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-id");
    constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\n";
    context.expect(write_text(dir.root / "Config" / "SceneDefineEx.txt", kTable), "ghi bảng cảnh");
    context.expect(write_text(dir.root / "Config" / "startup.id", "nope\n"), "ghi startup.id hỏng");
    const client::BootLoad boot = client::load_login(dir.root);
    context.expect(boot.playing.has_value(), "bảng vẫn mở");
    context.expect(!boot.first_scene, "chữ không phải resid thì không có cảnh đầu");
    context.expect(problem_has(boot, "Config/startup.id không phải resid"), "nói tệp không phải resid");
}

void enter_rejects_a_missing_file_and_a_second_enter_stays(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-enter");
    constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\n";
    context.expect(write_text(dir.root / "Config" / "SceneDefineEx.txt", kTable), "ghi bảng cảnh");
    auto opened = client::world::open_world(kTable);
    context.expect(opened.has_value(), "bảng mở được");
    if (!opened) return;
    const client::EnterNote missing = client::enter_startup(*opened, 251, dir.root);
    context.expect(!missing.ok && !missing.detail.empty(), "thiếu tệp thì không vào");
    context.expect(!opened->current, "thất bại không đặt cảnh hiện tại");
    context.expect(write_text(dir.root / "Scene" / "huoyangu.Scene", kScene), "ghi cảnh chơi");
    const client::EnterNote entered = client::enter_startup(*opened, 251, dir.root);
    context.expect(entered.ok && entered.detail.empty(), "đủ tệp thì vào");
    context.expect(opened->current && opened->current->id == 251, "đang ở resid 251");
    const client::EnterNote again = client::enter_startup(*opened, 251, dir.root);
    context.expect(again.ok, "vào lại cùng resid vẫn thành công");
    context.expect(opened->current && opened->current->id == 251, "vẫn resid 251");
}

void host_step_enters_once_and_ignores_a_strange_request(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-host");
    constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\n";
    context.expect(write_text(dir.root / "Config" / "SceneDefineEx.txt", kTable), "ghi bảng cảnh");
    context.expect(write_text(dir.root / "Config" / "startup.id", "251\n"), "ghi startup.id");
    context.expect(write_text(dir.root / "Scene" / "huoyangu.Scene", kScene), "ghi cảnh chơi");
    client::BootLoad boot = client::load_login(dir.root);
    bool is_playing = false;
    client::Request strange;
    strange.kind = static_cast<client::RequestKind>(255);
    const client::HostStep ignored = client::host_step(boot, is_playing, strange);
    context.expect(ignored.ask == client::HostAsk::kNone && !is_playing, "lời nhờ lạ không phải thoát");
    client::Request enter;
    enter.kind = client::RequestKind::kEnterGame;
    const client::HostStep first = client::host_step(boot, is_playing, enter);
    context.expect(first.ask == client::HostAsk::kEntered && is_playing, "vào game lần đầu");
    context.expect(boot.playing && boot.playing->current && boot.playing->current->id == 251, "đang ở 251");
    const client::HostStep second = client::host_step(boot, is_playing, enter);
    context.expect(second.ask == client::HostAsk::kNone && is_playing, "vào game lần hai không làm lại");
    client::Request leave;
    leave.kind = client::RequestKind::kLeave;
    const client::HostStep quit = client::host_step(boot, is_playing, leave);
    context.expect(quit.ask == client::HostAsk::kLeave, "rời client");
}

void host_step_stays_when_the_book_or_the_file_is_missing(Context& context) {
    const Scratch dir = scratch_of("thienlong-boot-stay");
    client::BootLoad boot = client::load_login(dir.root);
    bool is_playing = false;
    client::Request enter;
    enter.kind = client::RequestKind::kEnterGame;
    const client::HostStep no_book = client::host_step(boot, is_playing, enter);
    context.expect(no_book.ask == client::HostAsk::kNone && !is_playing, "thiếu bảng thì ở lại đăng nhập");
    context.expect(!no_book.detail.empty(), "có lý do để vỏ in");
    constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\n";
    context.expect(write_text(dir.root / "Config" / "SceneDefineEx.txt", kTable), "ghi bảng cảnh");
    context.expect(write_text(dir.root / "Config" / "startup.id", "251\n"), "ghi startup.id");
    boot = client::load_login(dir.root);
    const client::HostStep no_file = client::host_step(boot, is_playing, enter);
    context.expect(no_file.ask == client::HostAsk::kNone && !is_playing, "thiếu tệp cảnh thì ở lại");
    context.expect(!no_file.detail.empty(), "lỗi enter có một dòng");
}

void unknown_web_link_has_a_name(Context& context) {
    context.expect(client::web_link_name(client::WebLink::kRegister) == "đăng ký tài khoản", "tên trang đăng ký");
    const auto strange = static_cast<client::WebLink>(255);
    context.expect(client::web_link_name(strange) == "trang web", "liên kết lạ vẫn có tên");
}

constexpr std::array kCases{
    Case{.name = "reject_a_name_that_leaves_the_scene_folder", .body = &reject_a_name_that_leaves_the_scene_folder},
    Case{.name = "missing_scene_is_an_error_without_a_throw", .body = &missing_scene_is_an_error_without_a_throw},
    Case{.name = "broken_scene_is_an_error", .body = &broken_scene_is_an_error},
    Case{.name = "terrain_miss_keeps_the_scene", .body = &terrain_miss_keeps_the_scene},
    Case{.name = "empty_folder_loads_a_login_without_throwing", .body = &empty_folder_loads_a_login_without_throwing},
    Case{.name = "login_keeps_scenes_and_does_not_enter", .body = &login_keeps_scenes_and_does_not_enter},
    Case{.name = "bad_startup_id_does_not_invent_a_scene", .body = &bad_startup_id_does_not_invent_a_scene},
    Case{.name = "enter_rejects_a_missing_file_and_a_second_enter_stays",
        .body = &enter_rejects_a_missing_file_and_a_second_enter_stays},
    Case{.name = "host_step_enters_once_and_ignores_a_strange_request",
        .body = &host_step_enters_once_and_ignores_a_strange_request},
    Case{.name = "host_step_stays_when_the_book_or_the_file_is_missing",
        .body = &host_step_stays_when_the_book_or_the_file_is_missing},
    Case{.name = "unknown_web_link_has_a_name", .body = &unknown_web_link_has_a_name},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "boot_tests: mọi ca phải qua");
    return 0;
}
