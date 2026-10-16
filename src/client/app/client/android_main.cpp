/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/android_main.cpp
 *  PHÂN HỆ   : Client / Client / Android Main
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vỏ NativeActivity của Android. Cùng phiên đăng nhập với bản PC
 *    (client/boot): bảng tài khoản trên erengu_DL, chọn nhân vật trên
 *    tl3chuangjian, nút vào game mới nạp cảnh Config/startup.id. Vulkan 1.3
 *    phần cứng, không có thì GLES. Luồng này chỉ bơm sự kiện. Cảm ứng đi qua
 *    control::TouchGestures rồi Display::input.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Vòng chờ 8 ms khi đang vẽ, cùng nhịp luồng cửa sổ PC, để lời nhờ của nút (xử lý ở luồng vẽ) không bị ngủ đến lần
// chạm sau. Mỗi lần chạy so sổ assets với sổ đã giữ và chép những tệp đổi. Màu đặc chỉ khi không dựng được phần hiển
// thị.

#if defined(__ANDROID__)
#include "audio/engine.hpp"
#include "client/android_stdio.hpp"
#include "client/assets.hpp"
#include "client/boot.hpp"
#include "client/display/display.hpp"
#include "client/host/host.hpp"
#include "client/mobile.hpp"
#include "client/viewer/client_size.hpp"
#include "control/input.hpp"
#include "control/touch.hpp"
#include "io/file.hpp"

#include <android/asset_manager.h>
#include <android/configuration.h>
#include <android/input.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android_native_app_glue.h>
#include <jni.h>
#include <sys/system_properties.h>

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace {

constexpr const char* kTag = "THIENLONG";
constexpr std::uint8_t kFallback[3] = {0x1B, 0x4B, 0x6E};
constexpr std::string_view kKeptBook = "assets.book";
constexpr float kBaseDensity = 160.0F;
// Cùng kFramePause của viewer Windows: lời nhờ từ luồng vẽ được nhận trong một khung.
constexpr int kPollMs = 8;

void log_line(std::string_view text) noexcept {
    __android_log_write(ANDROID_LOG_INFO, kTag, std::string(text).c_str());
}

void log_error(std::string_view text) noexcept {
    __android_log_write(ANDROID_LOG_ERROR, kTag, std::string(text).c_str());
}

void fill_row(std::uint8_t* row, int width) noexcept {
    for (int column = 0; column < width; ++column) {
        std::uint8_t* pixel = row + static_cast<std::ptrdiff_t>(column) * 4;
        pixel[0] = kFallback[0];
        pixel[1] = kFallback[1];
        pixel[2] = kFallback[2];
        pixel[3] = 0xFF;
    }
}

void fill_buffer(const ANativeWindow_Buffer& buffer) noexcept {
    auto* pixels = static_cast<std::uint8_t*>(buffer.bits);
    if (pixels == nullptr || buffer.width <= 0 || buffer.height <= 0) return;
    for (int row = 0; row < buffer.height; ++row) {
        const auto offset = static_cast<std::ptrdiff_t>(row) * buffer.stride * 4;
        fill_row(pixels + offset, buffer.width);
    }
}

void paint_fallback(ANativeWindow* window) noexcept {
    if (window == nullptr) return;
    if (ANativeWindow_setBuffersGeometry(window, 0, 0, WINDOW_FORMAT_RGBA_8888) != 0) return;
    ANativeWindow_Buffer buffer{};
    if (ANativeWindow_lock(window, &buffer, nullptr) != 0) return;
    fill_buffer(buffer);
    ANativeWindow_unlockAndPost(window);
}

[[nodiscard]] bool copy_asset(AAssetManager* manager, const std::string& in_assets,
    const std::filesystem::path& target) noexcept {
    AAsset* asset = AAssetManager_open(manager, in_assets.c_str(), AASSET_MODE_BUFFER);
    if (asset == nullptr) return false;
    const auto size = static_cast<std::size_t>(AAsset_getLength(asset));
    std::vector<std::byte> bytes(size);
    const int read = AAsset_read(asset, bytes.data(), size);
    AAsset_close(asset);
    if (read < 0 || static_cast<std::size_t>(read) != size) return false;
    std::error_code ignored;
    std::filesystem::create_directories(target.parent_path(), ignored);
    FILE* file = std::fopen(target.string().c_str(), "wb");
    if (file == nullptr) return false;
    const std::size_t written = std::fwrite(bytes.data(), 1, size, file);
    std::fclose(file);
    return written == size;
}

[[nodiscard]] bool write_text(const std::filesystem::path& target, std::string_view text) noexcept {
    FILE* file = std::fopen(target.string().c_str(), "wb");
    if (file == nullptr) return false;
    const std::size_t written = std::fwrite(text.data(), 1, text.size(), file);
    std::fclose(file);
    return written == text.size();
}

[[nodiscard]] std::string packed_book(AAssetManager* manager) {
    AAsset* book = AAssetManager_open(manager, "manifest.txt", AASSET_MODE_BUFFER);
    if (book == nullptr) return {};
    const auto size = static_cast<std::size_t>(AAsset_getLength(book));
    std::string text(size, '\0');
    const int read = AAsset_read(book, text.data(), size);
    AAsset_close(book);
    if (read < 0 || static_cast<std::size_t>(read) != size) return {};
    return text;
}

struct CopyJob {
    AAssetManager* manager = nullptr;
    const std::filesystem::path* data_root = nullptr;
    std::size_t copied = 0;
};

void copy_entry(CopyJob& job, const game::client::AssetEntry& entry) {
    const bool is_data = entry.group == 'D';
    const std::string relative(entry.path);
    const std::string in_assets = is_data ? "data/" + relative : "shaders/" + relative;
    const std::filesystem::path target = is_data ? *job.data_root / relative : *job.data_root / "shaders" / relative;
    if (copy_asset(job.manager, in_assets, target)) ++job.copied;
}

void extract_assets(android_app* app, const std::filesystem::path& data_root) {
    const std::string packed = packed_book(app->activity->assetManager);
    if (packed.empty()) {
        log_error("APK không có manifest.txt của assets");
        return;
    }
    const std::filesystem::path kept_path = data_root / kKeptBook;
    const game::io::TextResult kept = game::io::read_text(kept_path);
    const std::string_view installed = kept ? std::string_view(*kept) : std::string_view{};
    const game::client::AssetBooks books{.installed = installed, .packed = packed};
    const std::vector<game::client::AssetEntry> stale = game::client::assets_to_copy(books);
    if (stale.empty()) return;
    CopyJob job;
    job.manager = app->activity->assetManager;
    job.data_root = &data_root;
    for (const game::client::AssetEntry& entry : stale) {
        copy_entry(job, entry);
    }
    const std::string counts = std::to_string(job.copied) + "/" + std::to_string(stale.size());
    if (job.copied != stale.size()) {
        log_error("giải nén assets thiếu tệp: " + counts);
        return;
    }
    if (!write_text(kept_path, packed)) log_error("không ghi được sổ assets");
    log_line("đã giải nén " + counts + " tệp assets đổi ra " + data_root.string());
}

// Display huỷ trước boot và online: nó giữ shared_ptr cảnh cắt từ boot. online sống qua các lần huỷ Display (ứng dụng
// xuống nền): phiên mạng không đứt khi người chơi tạm rời ứng dụng.
struct Shell {
    game::client::BootLoad boot;
    std::optional<game::client::host::Online> online;
    game::client::host::Soundscape sounds;
    std::chrono::steady_clock::time_point last_serve{};
    std::optional<game::client::Display> display;
    game::control::TouchGestures gestures;
    std::vector<game::control::InputEvent> events;
    std::optional<game::audio::Engine> speaker;
    // Ngoại hình đã áp khi vào game, để lần dựng lại sau khi tạm dừng không về nhân vật mặc định.
    game::client::KeptRole played;
    // Điểm trên mỗi dp. 1 khi mật độ không biết: pixel trùng điểm.
    float per_dp = 1.0F;
    bool is_prepared = false;
    bool is_playing = false;
    // Giữa APP_CMD_RESUME và APP_CMD_PAUSE. Chỉ vẽ khi vừa resumed vừa có cửa sổ: bề mặt có thể
    // được tạo lại (INIT_WINDOW) lúc activity còn dừng.
    bool is_resumed = false;
};

[[nodiscard]] Shell* shell_of(android_app* app) noexcept {
    return static_cast<Shell*>(app->userData);
}

void log_boot(const game::client::BootLoad& boot) {
    for (const game::client::BootLoad::Line& line : boot.lines) {
        if (line.is_problem) log_error(line.text);
        if (!line.is_problem) log_line(line.text);
    }
}

void log_notes(game::client::host::Notes& notes) {
    for (const game::client::host::Note& note : notes) {
        if (note.is_problem) log_error(note.text);
        if (!note.is_problem) log_line(note.text);
    }
    notes.clear();
}

void prepare_shell(android_app* app, Shell& shell) {
    const std::filesystem::path root = shell.boot.data_root;
    extract_assets(app, root);
    try {
        shell.boot = game::client::load_login(root);
    } catch (const std::exception& error) {
        log_error(error.what());
        return;
    } catch (...) {
        log_error("lỗi khi nạp cảnh");
        return;
    }
    log_boot(shell.boot);
    game::client::host::GateBookLoad gates = game::client::host::load_gate_book(root);
    log_notes(gates.notes);
    shell.online.emplace(std::move(gates.book));
}

// Màn điện thoại theo cách Android chia: cạnh ngắn nhỏ hơn 600 dp (sw600dp là máy tính bảng). Không hỏi được thì coi là
// điện thoại, vì giao diện PC trên màn điện thoại không bấm được.
[[nodiscard]] bool is_phone_screen(const android_app* app) noexcept {
    constexpr int32_t kTabletDp = 600;
    const int32_t smallest = AConfiguration_getSmallestScreenWidthDp(app->config);
    if (smallest == ACONFIGURATION_SMALLEST_SCREEN_WIDTH_DP_ANY || smallest <= 0) return true;
    return smallest < kTabletDp;
}

void fit_gestures(const android_app* app, Shell& shell) noexcept {
    if (app->window == nullptr) return;
    const auto width = static_cast<float>(ANativeWindow_getWidth(app->window));
    const auto height = static_cast<float>(ANativeWindow_getHeight(app->window));
    const int32_t density = AConfiguration_getDensity(app->config);
    const bool is_known =
        density > 0 && density != ACONFIGURATION_DENSITY_ANY && density != ACONFIGURATION_DENSITY_NONE;
    shell.per_dp = is_known ? static_cast<float>(density) / kBaseDensity : 1.0F;
    // Cử chỉ tính bằng điểm (dp), không phải pixel: slop 16 và pinch 48 là điểm.
    shell.gestures.resize(width / shell.per_dp, height / shell.per_dp, 1.0F);
}

void start_speaker(Shell& shell) {
    if (shell.speaker && shell.speaker->is_open()) return;
    shell.speaker.emplace();
    game::audio::OpenRequest request;
    request.data_root = shell.boot.data_root;
    const game::core::Status opened = shell.speaker->open(request);
    if (!opened) {
        shell.speaker.reset();
        return;
    }
    // Loa mở lại (sau tạm dừng) giữa màn chơi: sounds phát lại nhạc cảnh, không về nhạc đăng nhập.
    shell.sounds = {};
    if (!shell.is_playing) {
        static_cast<void>(shell.speaker->play_music(game::audio::kLoginMusicId, 0.F));
        static_cast<void>(shell.speaker->play_flat(game::audio::kButtonClickId, 1.F));
    }
    const char* text = "âm thanh: không mở được thiết bị";
    if (shell.speaker->device_is_open()) text = "âm thanh: thiết bị mở";
    log_line(text);
}

void stop_speaker(Shell& shell) noexcept {
    if (!shell.speaker) return;
    const game::audio::Stats heard = shell.speaker->stats();
    log_line("âm thanh: " + game::audio::describe(heard));
    shell.speaker->close();
    shell.speaker.reset();
}

void arm_desc(const Shell& shell, game::client::DisplayDesc& desc) {
    desc.data_root = shell.boot.data_root;
    desc.restored = shell.played;
    const bool playing = shell.is_playing && shell.boot.playing && shell.boot.playing->current;
    if (playing) {
        desc.procedure = game::client::Procedure::kPlay;
        desc.scene = game::client::world::current_scene(*shell.boot.playing);
        return;
    }
    desc.procedure = game::client::Procedure::kLogin;
    desc.scene = shell.boot.backdrop;
    desc.role_scene = shell.boot.role_scene;
    if (shell.online) desc.online_servers = shell.online->servers();
}

// Chẩn đoán trên thiết bị: `adb shell setprop debug.thienlong.backend gles` ép backend đồ hoạ (giả lập hay driver có
// Vulkan hỏng thì thử GLES). Không đặt hoặc tên lạ thì tự chọn, như bản PC không có --backend.
[[nodiscard]] std::optional<std::string> backend_override() {
    char value[PROP_VALUE_MAX] = {};
    const int length = __system_property_get("debug.thienlong.backend", value);
    if (length <= 0) return std::nullopt;
    const std::string_view name(value, static_cast<std::size_t>(length));
    if (name != "vulkan" && name != "gles") {
        log_error("debug.thienlong.backend: chỉ nhận vulkan hoặc gles");
        return std::nullopt;
    }
    return std::string(name);
}

// Chẩn đoán trên thiết bị: `adb shell setprop debug.thienlong.direct 1` bỏ qua màn đăng nhập và vào thẳng cảnh khởi đầu
// cục bộ (Config/startup.id), như --scene-id của bản PC, để đo và chụp cảnh chơi mà không cần máy chủ. Mặc định tắt.
[[nodiscard]] bool wants_direct_entry() {
    char value[PROP_VALUE_MAX] = {};
    const int length = __system_property_get("debug.thienlong.direct", value);
    return length > 0 && value[0] == '1';
}

void enter_directly(Shell& shell) {
    if (shell.is_playing || !wants_direct_entry()) return;
    const game::client::Request request{.kind = game::client::RequestKind::kEnterGame};
    const game::client::HostStep step = game::client::host_step(shell.boot, shell.is_playing, request);
    if (!step.detail.empty()) log_error("Vào thẳng: " + step.detail);
}

// Chẩn đoán: `adb shell setprop debug.thienlong.quality desktop` chạy chính sách đồ hoạ của PC trên máy này (display/policy.hpp),
// để so cùng một đường vẽ ở hai bộ số. Không đặt hoặc tên lạ thì theo nền tảng.
[[nodiscard]] std::optional<game::client::QualityClass> quality_override() {
    char value[PROP_VALUE_MAX] = {};
    const int length = __system_property_get("debug.thienlong.quality", value);
    if (length <= 0) return std::nullopt;
    const std::string_view name(value, static_cast<std::size_t>(length));
    const std::optional<game::client::QualityClass> quality = game::client::quality_class_of(name);
    if (!quality) log_error("debug.thienlong.quality: chỉ nhận desktop hoặc mobile");
    return quality;
}

// Tần số quét của màn đang chứa activity, Hz; định nghĩa cạnh các hàm JNI bên dưới.
[[nodiscard]] double refresh_rate(android_app* app);

void start_display(android_app* app) {
    Shell* shell = shell_of(app);
    if (shell == nullptr || app->window == nullptr || shell->display || !shell->is_resumed) return;
    if (!shell->is_prepared) {
        prepare_shell(app, *shell);
        shell->is_prepared = true;
    }
    enter_directly(*shell);
    start_speaker(*shell);
    game::client::DisplayDesc desc;
    desc.backend = backend_override();
    desc.quality = quality_override();
    desc.window = app->window;
    desc.size = {.width = static_cast<std::uint32_t>(ANativeWindow_getWidth(app->window)),
        .height = static_cast<std::uint32_t>(ANativeWindow_getHeight(app->window))};
    arm_desc(*shell, desc);
    desc.uses_phone_layout = is_phone_screen(app);
    log_line(desc.uses_phone_layout ? "giao diện: layout điện thoại" : "giao diện: layout PC (máy tính bảng)");
    // Máy tính bảng 16:10 mở màn đăng nhập trong khung 1280x720 như cửa sổ PC; điện thoại dùng layout riêng nên để trọn màn.
    const game::client::ClientSize login = game::client::kLoginClientSize;
    const game::client::PixelSize login_frame{.width = login.width, .height = login.height};
    if (!desc.uses_phone_layout) desc.login_frame = login_frame;
    fit_gestures(app, *shell);
    desc.is_validated = game::client::validation_by_build();
    auto made = game::client::Display::create(desc);
    if (!made) {
        log_error("không dựng được phần hiển thị: " + std::string(made.error().detail()));
        paint_fallback(app->window);
        return;
    }
    shell->display.emplace(std::move(*made));
    log_line("phần hiển thị đã chạy: " + shell->display->description());
    shell->display->set_refresh(refresh_rate(app));
    if (shell->online) shell->online->on_display_made(*shell->display, shell->is_playing);
    shell->last_serve = std::chrono::steady_clock::now();
}

// Lời nhờ còn nằm trên phần hiển thị sắp huỷ: vào game phải kịp đặt is_playing, không thì lần
// dựng lại mở lại bảng đăng nhập. Không gọi play() trên phần hiển thị sắp chết.
void absorb_requests(Shell& shell) {
    if (!shell.display) return;
    const game::client::KeptRole live = shell.display->kept_role();
    if (live.has) shell.played = live;
    const std::vector<game::client::Request> requests = shell.display->take_requests();
    for (const game::client::Request& request : requests) {
        if (request.kind != game::client::RequestKind::kEnterGame) continue;
        const game::client::HostStep step = game::client::host_step(shell.boot, shell.is_playing, request);
        if (step.detail.empty()) continue;
        log_error("Vào game: " + step.detail);
        if (request.entry && shell.online) shell.online->abandon(*shell.display);
    }
}

void stop_display(android_app* app) {
    Shell* shell = shell_of(app);
    if (shell == nullptr) return;
    absorb_requests(*shell);
    stop_speaker(*shell);
    shell->display.reset();
}

void note_resized(android_app* app) noexcept {
    Shell* shell = shell_of(app);
    if (shell == nullptr || !shell->display || app->window == nullptr) return;
    fit_gestures(app, *shell);
    shell->display->notify_resized({.width = static_cast<std::uint32_t>(ANativeWindow_getWidth(app->window)),
        .height = static_cast<std::uint32_t>(ANativeWindow_getHeight(app->window))});
}

// JNIEnv của luồng android_main. Luồng glue không gắn sẵn; gắn ở đây thì gỡ khi hết việc.
struct JniEnv {
    JavaVM* vm = nullptr;
    JNIEnv* env = nullptr;
    bool attached = false;

    explicit JniEnv(JavaVM* machine) : vm(machine) {
        if (vm == nullptr) return;
        void* raw = nullptr;
        const jint existing = vm->GetEnv(&raw, JNI_VERSION_1_6);
        if (existing == JNI_OK) {
            env = static_cast<JNIEnv*>(raw);
            return;
        }
        if (existing != JNI_EDETACHED) return;
        if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) env = nullptr;
        if (env != nullptr) attached = true;
    }
    JniEnv(const JniEnv&) = delete;
    JniEnv& operator=(const JniEnv&) = delete;
    ~JniEnv() {
        if (attached && vm != nullptr) vm->DetachCurrentThread();
    }
};

[[nodiscard]] bool jni_ok(JNIEnv* env) noexcept {
    if (env->ExceptionCheck() == JNI_FALSE) return true;
    env->ExceptionClear();
    return false;
}

// Không gọi JNI tiếp khi đã có ngoại lệ đang chờ: spec cấm, trừ ExceptionCheck và ExceptionClear.
[[nodiscard]] jmethodID method_of(JNIEnv* env, jclass type, const char* name, const char* signature) noexcept {
    if (env->ExceptionCheck() == JNI_TRUE || type == nullptr) return nullptr;
    const jmethodID method = env->GetMethodID(type, name, signature);
    if (!jni_ok(env)) return nullptr;
    return method;
}

[[nodiscard]] jmethodID static_method_of(JNIEnv* env, jclass type, const char* name, const char* signature) noexcept {
    if (env->ExceptionCheck() == JNI_TRUE || type == nullptr) return nullptr;
    const jmethodID method = env->GetStaticMethodID(type, name, signature);
    if (!jni_ok(env)) return nullptr;
    return method;
}

// Local ref của một lời gọi JNI; trả lại khi ra khỏi tầm (luồng của vỏ có thể đã gắn sẵn với máy ảo, khi ấy ref không tự
// mất lúc gỡ).
struct LocalRef {
    JNIEnv* env = nullptr;
    jobject held = nullptr;
    LocalRef(JNIEnv* owner, jobject object) noexcept : env(owner), held(object) {}
    LocalRef(const LocalRef&) = delete;
    LocalRef& operator=(const LocalRef&) = delete;
    ~LocalRef() {
        if (held != nullptr) env->DeleteLocalRef(held);
    }
};

// Activity.getWindowManager().getDefaultDisplay().getRefreshRate(): còn dùng được ở API 29 (Activity.getDisplay từ API
// 30). 0 khi không hỏi được: bảng đo giữ ngân sách của trần render_hz như Display::set_refresh nói.
double refresh_rate(android_app* app) {
    JniEnv jni(app->activity->vm);
    JNIEnv* env = jni.env;
    if (env == nullptr) return 0.0;
    jobject activity = app->activity->clazz;
    const LocalRef activity_class(env, env->GetObjectClass(activity));
    const jmethodID manager_of = method_of(
        env, static_cast<jclass>(activity_class.held), "getWindowManager", "()Landroid/view/WindowManager;");
    if (manager_of == nullptr) return 0.0;
    const LocalRef manager(env, env->CallObjectMethod(activity, manager_of));
    if (!jni_ok(env) || manager.held == nullptr) return 0.0;
    const LocalRef manager_class(env, env->GetObjectClass(manager.held));
    const jmethodID display_of = method_of(
        env, static_cast<jclass>(manager_class.held), "getDefaultDisplay", "()Landroid/view/Display;");
    if (display_of == nullptr) return 0.0;
    const LocalRef display(env, env->CallObjectMethod(manager.held, display_of));
    if (!jni_ok(env) || display.held == nullptr) return 0.0;
    const LocalRef display_class(env, env->GetObjectClass(display.held));
    const jmethodID rate_of = method_of(env, static_cast<jclass>(display_class.held), "getRefreshRate", "()F");
    if (rate_of == nullptr) return 0.0;
    const jfloat rate = env->CallFloatMethod(display.held, rate_of);
    if (!jni_ok(env)) return 0.0;
    log_line("màn hình: " + std::to_string(rate) + " Hz");
    return static_cast<double>(rate);
}

// Mở Coming soon bằng Intent. file:// sang ứng dụng khác có thể ném FileUriExposedException;
// nuốt ngoại lệ và ghi log, không làm chết tiến trình.
void open_web(android_app* app, const std::filesystem::path& page, std::string_view link) {
    std::error_code missing;
    const bool exists = std::filesystem::is_regular_file(page, missing);
    if (!exists) {
        log_error("Trang web " + std::string(link) + ": không có tệp");
        return;
    }
    JniEnv jni(app->activity->vm);
    if (jni.env == nullptr) {
        log_error("Trang web " + std::string(link) + ": không gắn được JNI");
        return;
    }
    JNIEnv* env = jni.env;
    jclass file_class = env->FindClass("java/io/File");
    if (!jni_ok(env) || file_class == nullptr) {
        log_error("Trang web " + std::string(link) + ": thiếu lớp File");
        return;
    }
    jclass uri_class = env->FindClass("android/net/Uri");
    if (!jni_ok(env) || uri_class == nullptr) {
        log_error("Trang web " + std::string(link) + ": thiếu lớp Uri");
        return;
    }
    jclass intent_class = env->FindClass("android/content/Intent");
    if (!jni_ok(env) || intent_class == nullptr) {
        log_error("Trang web " + std::string(link) + ": thiếu lớp Intent");
        return;
    }
    jmethodID file_ctor = method_of(env, file_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID from_file = static_method_of(env, uri_class, "fromFile", "(Ljava/io/File;)Landroid/net/Uri;");
    jmethodID intent_ctor = method_of(env, intent_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID set_data = method_of(env, intent_class, "setData", "(Landroid/net/Uri;)Landroid/content/Intent;");
    jmethodID add_flags = method_of(env, intent_class, "addFlags", "(I)Landroid/content/Intent;");
    jfieldID flag_field = nullptr;
    if (env->ExceptionCheck() == JNI_FALSE)
        flag_field = env->GetStaticFieldID(intent_class, "FLAG_ACTIVITY_NEW_TASK", "I");
    if (!jni_ok(env) || file_ctor == nullptr || from_file == nullptr || intent_ctor == nullptr || set_data == nullptr ||
        add_flags == nullptr || flag_field == nullptr) {
        log_error("Trang web " + std::string(link) + ": thiếu hàm Intent");
        return;
    }
    jstring path = env->NewStringUTF(page.string().c_str());
    if (!jni_ok(env) || path == nullptr) {
        log_error("Trang web " + std::string(link) + ": không tạo được đường dẫn");
        return;
    }
    jstring action = env->NewStringUTF("android.intent.action.VIEW");
    if (!jni_ok(env) || action == nullptr) {
        log_error("Trang web " + std::string(link) + ": không tạo được chuỗi");
        return;
    }
    jobject file = env->NewObject(file_class, file_ctor, path);
    if (!jni_ok(env) || file == nullptr) {
        log_error("Trang web " + std::string(link) + ": không tạo được File");
        return;
    }
    jobject uri = env->CallStaticObjectMethod(uri_class, from_file, file);
    if (!jni_ok(env) || uri == nullptr) {
        log_error("Trang web " + std::string(link) + ": không tạo được Uri");
        return;
    }
    jobject intent = env->NewObject(intent_class, intent_ctor, action);
    if (!jni_ok(env) || intent == nullptr) {
        log_error("Trang web " + std::string(link) + ": không tạo được Intent");
        return;
    }
    const jint flag = env->GetStaticIntField(intent_class, flag_field);
    if (!jni_ok(env)) {
        log_error("Trang web " + std::string(link) + ": thiếu cờ Intent");
        return;
    }
    static_cast<void>(env->CallObjectMethod(intent, set_data, uri));
    if (!jni_ok(env)) {
        log_error("Trang web " + std::string(link) + ": không gắn được Uri");
        return;
    }
    static_cast<void>(env->CallObjectMethod(intent, add_flags, flag));
    if (!jni_ok(env)) {
        log_error("Trang web " + std::string(link) + ": không gắn được cờ");
        return;
    }
    jclass activity = env->GetObjectClass(app->activity->clazz);
    const jmethodID start = method_of(env, activity, "startActivity", "(Landroid/content/Intent;)V");
    if (!jni_ok(env) || start == nullptr) {
        log_error("Trang web " + std::string(link) + ": không có startActivity");
        return;
    }
    env->CallVoidMethod(app->activity->clazz, start, intent);
    if (!jni_ok(env)) {
        log_error("Trang web " + std::string(link) + ": không mở được");
        return;
    }
    log_line("Trang web " + std::string(link) + ": đã mở");
}

void apply_request(android_app* app, Shell& shell, game::client::Request request) {
    if (!shell.display) return;
    const game::client::HostStep step = game::client::host_step(shell.boot, shell.is_playing, request);
    if (!step.detail.empty()) log_error("Vào game: " + step.detail);
    // Trực tuyến mà không vào được cảnh máy chủ nói: trả phiên, không để máy chủ tưởng người chơi đã vào.
    if (!step.detail.empty() && request.entry && shell.online) shell.online->abandon(*shell.display);
    const bool entered = step.ask == game::client::HostAsk::kEntered && shell.boot.playing;
    if (entered) shell.display->play(game::client::world::current_scene(*shell.boot.playing), step.entry);
    if (step.ask == game::client::HostAsk::kOpenWeb) {
        const std::filesystem::path page = shell.boot.data_root / "Web" / "coming_soon.html";
        open_web(app, page, game::client::web_link_name(step.link));
    }
    if (step.ask == game::client::HostAsk::kLeave) ANativeActivity_finish(app->activity);
}

void show_playing(Shell& shell) {
    if (!shell.is_playing || !shell.boot.playing || !shell.display) return;
    const std::shared_ptr<const game::client::world::ShownScene> scene =
        game::client::world::current_scene(*shell.boot.playing);
    if (scene) shell.display->show(scene);
}

// Âm thanh và mạng (đăng nhập, tin thế giới, chỗ đứng) của mỗi vòng, trước lời nhờ của giao diện như vòng của viewer PC.
void serve_host(Shell& shell) {
    const auto now = std::chrono::steady_clock::now();
    const float seconds = std::chrono::duration<float>(now - shell.last_serve).count();
    shell.last_serve = now;
    game::client::host::Notes notes;
    const bool is_playing = shell.is_playing && shell.boot.playing;
    const std::shared_ptr<const game::client::world::ShownScene> scene =
        is_playing ? game::client::world::current_scene(*shell.boot.playing) : nullptr;
    game::audio::Engine* speaker = shell.speaker ? &*shell.speaker : nullptr;
    shell.sounds.on_frame(speaker, *shell.display, scene.get(), notes);
    if (shell.online) {
        game::client::world::World* playing = is_playing ? &*shell.boot.playing : nullptr;
        shell.online->on_frame(*shell.display, playing, shell.boot.data_root / "Scene", seconds, notes);
    }
    log_notes(notes);
}

void serve(android_app* app, Shell& shell) {
    if (!shell.display) return;
    serve_host(shell);
    const std::vector<game::client::Request> requests = shell.display->take_requests();
    for (const game::client::Request& request : requests) {
        apply_request(app, shell, request);
    }
    show_playing(shell);
}

// Hệ thống báo thiếu bộ nhớ. Khi đang dừng thì phần hiển thị đã huỷ; trả nốt loa (bộ đệm nhạc).
void trim_memory(android_app* app) noexcept {
    Shell* shell = shell_of(app);
    if (shell == nullptr) return;
    log_line("hệ thống báo thiếu bộ nhớ");
    if (!shell->display) stop_speaker(*shell);
}

void on_resume(android_app* app) {
    Shell* shell = shell_of(app);
    if (shell == nullptr) return;
    shell->is_resumed = true;
    start_display(app);
}

void on_pause(android_app* app) {
    Shell* shell = shell_of(app);
    if (shell == nullptr) return;
    shell->is_resumed = false;
    stop_display(app);
}

void on_command(android_app* app, int32_t command) {
    Shell* shell = shell_of(app);
    if (shell == nullptr) return;
    switch (command) {
    case APP_CMD_INIT_WINDOW: start_display(app); break;
    case APP_CMD_TERM_WINDOW: stop_display(app); break;
    // Xoay màn hình (configChanges giữ activity), đổi mật độ hay vùng nội dung: đo lại bề mặt.
    case APP_CMD_WINDOW_RESIZED:
    case APP_CMD_CONFIG_CHANGED:
    case APP_CMD_CONTENT_RECT_CHANGED: note_resized(app); break;
    case APP_CMD_RESUME: on_resume(app); break;
    case APP_CMD_PAUSE: on_pause(app); break;
    case APP_CMD_LOW_MEMORY: trim_memory(app); break;
    default: break;
    }
}

[[nodiscard]] game::control::TouchPoint touch_point(const AInputEvent* event, std::size_t index,
    float per_dp) noexcept {
    const float scale = per_dp > 0.0F ? per_dp : 1.0F;
    return {.x = AMotionEvent_getX(event, index) / scale, .y = AMotionEvent_getY(event, index) / scale};
}

[[nodiscard]] std::uint64_t finger_of(const AInputEvent* event, std::size_t index) noexcept {
    return static_cast<std::uint64_t>(AMotionEvent_getPointerId(event, index));
}

[[nodiscard]] std::size_t acting_index(int32_t action) noexcept {
    const int32_t shifted =
        (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
    return static_cast<std::size_t>(shifted);
}

void move_fingers(Shell& shell, const AInputEvent* event, game::control::TouchTime now) {
    const std::size_t count = AMotionEvent_getPointerCount(event);
    for (std::size_t index = 0; index < count; ++index) {
        shell.gestures.move(finger_of(event, index), touch_point(event, index, shell.per_dp), now, shell.events);
    }
}

void lift_fingers(Shell& shell, const AInputEvent* event, game::control::TouchTime now) {
    const std::size_t count = AMotionEvent_getPointerCount(event);
    for (std::size_t index = 0; index < count; ++index) {
        shell.gestures.up(finger_of(event, index), touch_point(event, index, shell.per_dp), now, shell.events);
    }
}

void feed_motion(Shell& shell, const AInputEvent* event) {
    const int32_t action = AMotionEvent_getAction(event);
    const std::size_t index = acting_index(action);
    const game::control::TouchTime now{AMotionEvent_getEventTime(event)};
    switch (action & AMOTION_EVENT_ACTION_MASK) {
    case AMOTION_EVENT_ACTION_DOWN:
    case AMOTION_EVENT_ACTION_POINTER_DOWN:
        shell.gestures.down(finger_of(event, index), touch_point(event, index, shell.per_dp), now, shell.events);
        break;
    case AMOTION_EVENT_ACTION_UP:
    case AMOTION_EVENT_ACTION_POINTER_UP:
        shell.gestures.up(finger_of(event, index), touch_point(event, index, shell.per_dp), now, shell.events);
        break;
    case AMOTION_EVENT_ACTION_MOVE: move_fingers(shell, event, now); break;
    case AMOTION_EVENT_ACTION_CANCEL: lift_fingers(shell, event, now); break;
    default: break;
    }
}

[[nodiscard]] int handle_motion(android_app* app, const AInputEvent* event) {
    Shell* shell = shell_of(app);
    if (shell == nullptr || !shell->display) return 0;
    shell->events.clear();
    feed_motion(*shell, event);
    shell->display->input(shell->events);
    // Chạm hai ngón là nhảy (Space của bản PC); ngoài màn chơi Display bỏ thao tác này.
    for (std::uint32_t taps = shell->gestures.take_pair_taps(); taps > 0; --taps) {
        shell->display->act(game::client::PlayAct::kJump);
    }
    return 1;
}

// Ký tự mà phím sinh ra theo bàn phím hiện hành và các phím bổ trợ (Shift, Alt): NDK không có hàm lấy ký tự, nên dựng
// một android.view.KeyEvent cùng mã phím rồi hỏi getUnicodeChar, cách mà các trò dùng NativeActivity vẫn làm. 0 khi phím
// không ra ký tự (mũi tên, Shift...) hay không hỏi được. Phím ghép dấu (bit COMBINING_ACCENT) bỏ: chữ Việt gõ kiểu Telex đi
// thẳng qua các phím a, s, f... của IME.
[[nodiscard]] char32_t unicode_of(android_app* app, const AInputEvent* event) {
    constexpr jint kActionDown = 0;
    constexpr jint kCombiningAccent = static_cast<jint>(0x80000000U);
    JniEnv jni(app->activity->vm);
    JNIEnv* env = jni.env;
    if (env == nullptr) return 0;
    const LocalRef type(env, env->FindClass("android/view/KeyEvent"));
    if (!jni_ok(env) || type.held == nullptr) return 0;
    const auto key_class = static_cast<jclass>(type.held);
    const jmethodID make = method_of(env, key_class, "<init>", "(II)V");
    const jmethodID unicode = method_of(env, key_class, "getUnicodeChar", "(I)I");
    if (make == nullptr || unicode == nullptr) return 0;
    const LocalRef key(env, env->NewObject(key_class, make, kActionDown, AKeyEvent_getKeyCode(event)));
    if (!jni_ok(env) || key.held == nullptr) return 0;
    const jint code = env->CallIntMethod(key.held, unicode, static_cast<jint>(AKeyEvent_getMetaState(event)));
    if (!jni_ok(env) || code <= 0 || (code & kCombiningAccent) != 0) return 0;
    return static_cast<char32_t>(code);
}

// Phím điều khiển của ô nhập (xoá lùi, Tab, Enter, Esc) như control_char của viewer PC; phím khác hỏi unicode_of.
[[nodiscard]] char32_t typed_of(android_app* app, const AInputEvent* event) {
    switch (AKeyEvent_getKeyCode(event)) {
    case AKEYCODE_DEL: return 8;
    case AKEYCODE_TAB: return 9;
    case AKEYCODE_ENTER:
    case AKEYCODE_NUMPAD_ENTER: return 13;
    case AKEYCODE_ESCAPE: return 27;
    default: return unicode_of(app, event);
    }
}

// Phím gõ (bàn phím rời, IME gửi dạng sự kiện phím, adb input text) đi vào ô nhập của giao diện như bản PC.
[[nodiscard]] int handle_key(android_app* app, const AInputEvent* event) {
    Shell* shell = shell_of(app);
    if (shell == nullptr || !shell->display) return 0;
    if (AKeyEvent_getAction(event) != AKEY_EVENT_ACTION_DOWN) return 0;
    const char32_t typed = typed_of(app, event);
    if (typed == 0) return 0;
    game::control::InputEvent text;
    text.kind = game::control::InputKind::kText;
    text.text = typed;
    const std::array<game::control::InputEvent, 1> one{text};
    shell->display->input(one);
    return 1;
}

[[nodiscard]] int on_input(android_app* app, AInputEvent* event) {
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) return handle_motion(app, event);
    if (AInputEvent_getType(event) != AINPUT_EVENT_TYPE_KEY) return 0;
    if (AKeyEvent_getKeyCode(event) != AKEYCODE_BACK) return handle_key(app, event);
    // Nhận cả lần nhấn: để lọt thì NativeActivity tự đóng activity trước lần nhả. Chỉ đóng khi
    // nhả thật (không bị huỷ, như cử chỉ back bị kéo ngược).
    if (AKeyEvent_getAction(event) != AKEY_EVENT_ACTION_UP) return 1;
    if ((AKeyEvent_getFlags(event) & AKEY_EVENT_FLAG_CANCELED) != 0) return 1;
    ANativeActivity_finish(app->activity);
    return 1;
}

[[nodiscard]] int poll_timeout(android_app* app) noexcept {
    const Shell* shell = shell_of(app);
    if (shell != nullptr && shell->display) return kPollMs;
    return -1;
}

[[nodiscard]] bool pump_once(android_app* app) noexcept {
    int events = 0;
    android_poll_source* source = nullptr;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    void** slot = reinterpret_cast<void**>(&source);
    const int identity = ALooper_pollOnce(poll_timeout(app), nullptr, &events, slot);
    if (identity < 0 || source == nullptr) return app->destroyRequested == 0;
    source->process(app, source);
    return app->destroyRequested == 0;
}

} // namespace

extern "C" void android_main(android_app* app) {
    // Trước mọi dòng in: stdout và stderr (std::println của client) về logcat trong suốt vòng đời của vỏ.
    const game::client::AndroidStdio stdio;
    const char* internal = app->activity->internalDataPath;
    if (internal == nullptr) {
        log_error("không có thư mục dữ liệu của ứng dụng");
        return;
    }
    Shell shell;
    shell.boot.data_root = std::filesystem::path(internal) / "data";
    app->userData = &shell;
    app->onAppCmd = on_command;
    app->onInputEvent = on_input;
    try {
        const game::client::ProbeReport report = game::client::mobile_probe();
        log_line(report.detail);
    } catch (const std::exception& error) {
        log_error(error.what());
    } catch (...) {
        log_error("lỗi không rõ khi kiểm tra nền tảng");
    }
    while (pump_once(app)) {
        if (shell_of(app) != nullptr) serve(app, *shell_of(app));
    }
    stop_display(app);
    app->userData = nullptr;
}

#endif
