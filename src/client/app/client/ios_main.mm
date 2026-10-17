/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/ios_main.mm
 *  PHÂN HỆ   : Client / Client / Ios Main
 *  CHUẨN     : Objective-C++
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Điểm vào iOS. Cùng phiên đăng nhập với bản PC và Android (client/boot):
 *    erengu_DL, rồi tl3chuangjian, rồi cảnh Config/startup.id khi vào game.
 *    Display vẽ qua MoltenVK (VK_EXT_metal_surface, gpu/vulkan/surface_ios.mm).
 *    Apple đã gỡ OpenGL ES: thiếu Vulkan 1.3 thì nền màu đặc. Bundle đọc thẳng
 *    data/. Sổ nhân vật ghi ở Documents vì bundle chỉ đọc. Chạm đi qua
 *    control::TouchGestures, cùng luật với Android (chạm hai ngón là nhảy).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// CADisplayLink bơm mỗi khung: âm thanh màn chơi và mạng (client/host, cùng mã với Android), rồi lời nhờ của giao
// diện. Phiên mạng sống qua các lần huỷ Display khi ứng dụng xuống nền. Trang Coming soon mở trong ứng dụng vì ứng
// dụng khác không đọc được tệp trong bundle.

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#include "audio/engine.hpp"
#include "client/boot.hpp"
#include "client/display/display.hpp"
#include "client/host/host.hpp"
#include "client/mobile.hpp"
#include "control/input.hpp"
#include "control/touch.hpp"
#include "core/number.hpp"

#include <os/log.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace {

void log_info(const std::string& text) noexcept {
    os_log(OS_LOG_DEFAULT, "%{public}s", text.c_str());
}

void log_error(const std::string& text) noexcept {
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_ERROR, "%{public}s", text.c_str());
}

[[nodiscard]] std::filesystem::path data_root() noexcept {
    NSString* resource = [NSBundle mainBundle].resourcePath;
    if (resource == nil) return {};
    return std::filesystem::path(resource.UTF8String) / "data";
}

// Display huỷ trước boot và online. save_root là Documents, nơi ghi Save/roles.tsv.
struct Session {
    game::client::BootLoad boot;
    std::optional<game::client::host::Online> online;
    game::client::host::Soundscape sounds;
    std::chrono::steady_clock::time_point last_serve{};
    std::optional<game::client::Display> display;
    game::control::TouchGestures gestures;
    std::vector<game::control::InputEvent> events;
    std::optional<game::audio::Engine> speaker;
    std::filesystem::path save_root;
    game::client::KeptRole played;
    bool is_prepared = false;
    bool is_playing = false;
    // Dựng phần hiển thị thất bại: không thử lại mỗi khung. Lần về trước màn hình xoá cờ này.
    bool display_failed = false;
};

Session session;

void start_speaker() {
    if (session.speaker && session.speaker->is_open()) return;
    session.speaker.emplace();
    game::audio::OpenRequest request;
    request.data_root = session.boot.data_root;
    const game::core::Status opened = session.speaker->open(request);
    if (!opened) {
        session.speaker.reset();
        return;
    }
    // Loa mở lại (về trước màn hình) giữa màn chơi: sounds phát lại nhạc cảnh, không về nhạc đăng nhập.
    session.sounds = {};
    if (session.is_playing) return;
    static_cast<void>(session.speaker->play_music(game::audio::kLoginMusicId, 0.F));
    static_cast<void>(session.speaker->play_flat(game::audio::kButtonClickId, 1.F));
}

void stop_speaker() {
    if (!session.speaker) return;
    const game::audio::Stats heard = session.speaker->stats();
    log_info("âm thanh: " + game::audio::describe(heard));
    session.speaker->close();
    session.speaker.reset();
}

void log_boot(const game::client::BootLoad& boot) {
    for (const game::client::BootLoad::Line& line : boot.lines) {
        if (line.is_problem) log_error(line.text);
        if (!line.is_problem) log_info(line.text);
    }
}

void log_notes(game::client::host::Notes& notes) {
    for (const game::client::host::Note& note : notes) {
        if (note.is_problem) log_error(note.text);
        if (!note.is_problem) log_info(note.text);
    }
    notes.clear();
}

void absorb_requests() {
    if (!session.display) return;
    const game::client::KeptRole live = session.display->kept_role();
    if (live.has) session.played = live;
    const std::vector<game::client::Request> requests = session.display->take_requests();
    for (const game::client::Request& request : requests) {
        if (request.kind != game::client::RequestKind::kEnterGame) continue;
        const game::client::HostStep step = game::client::host_step(session.boot, session.is_playing, request);
        if (step.detail.empty()) continue;
        log_error("Vào game: " + step.detail);
        if (request.entry && session.online) session.online->abandon(*session.display);
    }
}

// Biến môi trường của tiến trình; rỗng khi không đặt. Chỉ đọc lúc dựng phần hiển thị, chưa luồng nào đổi môi trường.
[[nodiscard]] std::string_view env_text(const char* key) noexcept {
    const char* const value = std::getenv(key); // NOLINT(concurrency-mt-unsafe): xem trên
    return value == nullptr ? std::string_view{} : std::string_view(value);
}

// Chẩn đoán, cùng nghĩa với debug.thienlong.direct và debug.thienlong.scene của Android: THIENLONG_DIRECT=1 (Xcode:
// Scheme, Run, Environment Variables) bỏ màn đăng nhập, vào thẳng cảnh khởi đầu cục bộ; THIENLONG_SCENE=<resid> đổi
// cảnh đó như --scene-id của bản PC, để ba nền đo cùng một cảnh ở cùng chỗ đứng mặc định. Mặc định tắt.
void enter_directly() {
    if (session.is_playing || !env_text("THIENLONG_DIRECT").starts_with('1')) return;
    const std::string_view scene_text = env_text("THIENLONG_SCENE");
    const std::optional<int> scene = game::core::parse_whole_int(scene_text);
    if (scene) session.boot.first_scene = scene;
    const bool is_bad_scene = !scene_text.empty() && !scene;
    if (is_bad_scene) log_error("THIENLONG_SCENE: phải là resid, số nguyên không âm");
    const game::client::Request request{.kind = game::client::RequestKind::kEnterGame};
    const game::client::HostStep step = game::client::host_step(session.boot, session.is_playing, request);
    if (!step.detail.empty()) log_error("Vào thẳng: " + step.detail);
}

void remember_save_root() {
    NSArray<NSString*>* paths =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docs = paths.firstObject;
    if (docs == nil) {
        log_info("không có thư mục Documents để ghi nhân vật");
        return;
    }
    session.save_root = std::filesystem::path(docs.UTF8String);
}

enum class TouchPhase : std::uint8_t { kDown, kMove, kUp };

void one_touch(UITouch* touch, UIView* view, TouchPhase phase) {
    const CGPoint at = [touch locationInView:view];
    const game::control::TouchPoint point{.x = static_cast<float>(at.x), .y = static_cast<float>(at.y)};
    const auto finger = static_cast<std::uint64_t>(reinterpret_cast<std::uintptr_t>(touch));
    const auto nanos = static_cast<std::int64_t>(std::llround(touch.timestamp * 1.0e9));
    const game::control::TouchTime now{nanos};
    if (phase == TouchPhase::kDown) session.gestures.down(finger, point, now, session.events);
    if (phase == TouchPhase::kMove) session.gestures.move(finger, point, now, session.events);
    if (phase == TouchPhase::kUp) session.gestures.up(finger, point, now, session.events);
}

void feed_touches(NSSet* touches, UIView* view, TouchPhase phase) {
    if (!session.display || touches == nil || view == nil) return;
    const CGSize size = view.bounds.size;
    session.gestures.resize(static_cast<float>(size.width), static_cast<float>(size.height), 1.0F);
    session.events.clear();
    for (UITouch* touch in touches) {
        one_touch(touch, view, phase);
    }
    session.display->input(session.events);
    // Chạm hai ngón là nhảy (Space của bản PC); ngoài màn chơi Display bỏ thao tác này.
    for (std::uint32_t taps = session.gestures.take_pair_taps(); taps > 0; --taps) {
        session.display->act(game::client::PlayAct::kJump);
    }
}

} // namespace

@class ThienlongDelegate;

namespace {

ThienlongDelegate* delegate_ref = nil;

void leave_client();
void open_page(game::client::WebLink link);

// Nhịp quét mà lớp Metal thật sự trình được, Hz. iPhone giới hạn 60 cho tới khi Info.plist khai
// CADisableMinimumFrameDurationOnPhone (chưa khai: 120 Hz tốn pin, chưa có số đo trên máy); iPad
// ProMotion không bị giới hạn ấy. 0 khi không biết màn.
[[nodiscard]] double refresh_rate(UIScreen* screen) noexcept {
    if (screen == nil) return 0.0;
    const NSInteger most = screen.maximumFramesPerSecond;
    const bool is_phone = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    const NSInteger shown = is_phone ? std::min<NSInteger>(most, 60) : most;
    return static_cast<double>(shown);
}

void apply_request(game::client::Request request) {
    if (!session.display) return;
    const game::client::HostStep step = game::client::host_step(session.boot, session.is_playing, request);
    if (!step.detail.empty()) log_error("Vào game: " + step.detail);
    // Trực tuyến mà không vào được cảnh máy chủ nói: trả phiên, không để máy chủ tưởng người chơi đã vào.
    if (!step.detail.empty() && request.entry && session.online) session.online->abandon(*session.display);
    const bool entered = step.ask == game::client::HostAsk::kEntered && session.boot.playing && session.display;
    if (entered) session.display->play(game::client::world::current_scene(*session.boot.playing), step.entry);
    if (step.ask == game::client::HostAsk::kOpenWeb) open_page(step.link);
    if (step.ask == game::client::HostAsk::kLeave) leave_client();
}

void show_playing() {
    if (!session.is_playing || !session.boot.playing || !session.display) return;
    const std::shared_ptr<const game::client::world::ShownScene> scene =
        game::client::world::current_scene(*session.boot.playing);
    if (scene) session.display->show(scene);
}

// Âm thanh và mạng (đăng nhập, tin thế giới, chỗ đứng) của mỗi khung, trước lời nhờ của giao diện như vòng của viewer PC.
void serve_host() {
    const auto now = std::chrono::steady_clock::now();
    const float seconds = std::chrono::duration<float>(now - session.last_serve).count();
    session.last_serve = now;
    game::client::host::Notes notes;
    const bool is_playing = session.is_playing && session.boot.playing;
    const std::shared_ptr<const game::client::world::ShownScene> scene =
        is_playing ? game::client::world::current_scene(*session.boot.playing) : nullptr;
    game::audio::Engine* speaker = session.speaker ? &*session.speaker : nullptr;
    session.sounds.on_frame(speaker, *session.display, scene.get(), notes);
    if (session.online) {
        game::client::world::World* playing = is_playing ? &*session.boot.playing : nullptr;
        session.online->on_frame(*session.display, playing, session.boot.data_root / "Scene", seconds, notes);
    }
    log_notes(notes);
}

void serve_session() {
    if (!session.display) return;
    serve_host();
    const std::vector<game::client::Request> requests = session.display->take_requests();
    for (const game::client::Request& request : requests) {
        apply_request(request);
    }
    show_playing();
}

} // namespace

@interface ThienlongView : UIView
@end

@implementation ThienlongView

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    auto* const layer = static_cast<CAMetalLayer*>(self.layer);
    const CGSize size = self.bounds.size;
    const auto scale = static_cast<float>(self.contentScaleFactor);
    layer.contentsScale = scale;
    layer.drawableSize = CGSizeMake(size.width * scale, size.height * scale);
    session.gestures.resize(static_cast<float>(size.width), static_cast<float>(size.height), 1.0F);
    if (!session.display) return;
    session.display->notify_resized({.width = static_cast<std::uint32_t>(size.width * scale),
        .height = static_cast<std::uint32_t>(size.height * scale)});
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    (void)event;
    feed_touches(touches, self, TouchPhase::kDown);
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    (void)event;
    feed_touches(touches, self, TouchPhase::kMove);
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    (void)event;
    feed_touches(touches, self, TouchPhase::kUp);
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    (void)event;
    feed_touches(touches, self, TouchPhase::kUp);
}

@end

@interface ThienlongController : UIViewController
@end

@implementation ThienlongController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end

@interface PageController : UIViewController
@property(nonatomic, copy) NSString* path;
@property(nonatomic, strong) WKWebView* page;
@property(nonatomic, strong) UIButton* close;
@end

@implementation PageController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.page = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.page.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.page];
    self.close = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.close setTitle:@"关闭" forState:UIControlStateNormal];
    [self.close addTarget:self action:@selector(closePage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.close];
    if (self.path == nil) return;
    NSURL* url = [NSURL fileURLWithPath:self.path];
    if (url == nil) return;
    [self.page loadFileURL:url allowingReadAccessToURL:url.URLByDeletingLastPathComponent];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    const UIEdgeInsets inset = self.view.safeAreaInsets;
    self.close.frame = CGRectMake(inset.left + 12.0, inset.top + 12.0, 72.0, 44.0);
}

- (void)closePage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end

@interface ThienlongDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow* window;
@property(nonatomic, strong) ThienlongView* content;
@property(nonatomic, strong) CADisplayLink* link;
- (void)openPage:(NSString*)path;
@end

namespace {

void leave_client() {
    if (delegate_ref != nil) [delegate_ref.link invalidate];
    if (delegate_ref != nil) delegate_ref.link = nil;
    absorb_requests();
    stop_speaker();
    session.display.reset();
    std::exit(0);
}

void open_page(game::client::WebLink link) {
    const std::string name(game::client::web_link_name(link));
    const std::filesystem::path page = session.boot.data_root / "Web" / "coming_soon.html";
    std::error_code missing;
    const bool exists = std::filesystem::is_regular_file(page, missing);
    if (!exists || delegate_ref == nil) {
        log_info("Trang web " + name + ": không có tệp");
        return;
    }
    NSString* path = [NSString stringWithUTF8String:page.string().c_str()];
    if (path == nil) return;
    [delegate_ref openPage:path];
}

} // namespace

@implementation ThienlongDelegate

- (void)openPage:(NSString*)path {
    PageController* page = [[PageController alloc] init];
    page.path = path;
    page.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:page animated:YES completion:nil];
}

- (void)startDisplay {
    CAMetalLayer* const layer = static_cast<CAMetalLayer*>(self.content.layer);
    if (session.display || layer == nil) return;
    if (!session.is_prepared) {
        remember_save_root();
        try {
            session.boot = game::client::load_login(data_root());
        } catch (const std::exception& error) {
            log_info(error.what());
        }
        log_boot(session.boot);
        game::client::host::GateBookLoad gates = game::client::host::load_gate_book(session.boot.data_root);
        log_notes(gates.notes);
        session.online.emplace(std::move(gates.book));
        session.is_prepared = true;
    }
    enter_directly();
    start_speaker();
    const CGSize drawable = layer.drawableSize;
    const bool has_pixels = drawable.width > 0.0 && drawable.height > 0.0;
    if (!has_pixels) return;
    game::client::DisplayDesc desc;
    desc.window = layer;
    desc.size = {.width = static_cast<std::uint32_t>(drawable.width),
        .height = static_cast<std::uint32_t>(drawable.height)};
    desc.data_root = session.boot.data_root;
    desc.save_root = session.save_root;
    desc.uses_phone_layout = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    // Giao diện theo point như UIKit: layoutSubviews đặt contentsScale bằng contentScaleFactor (iPad Retina là 2).
    desc.ui_density = static_cast<float>(layer.contentsScale);
    desc.restored = session.played;
    const bool playing = session.is_playing && session.boot.playing && session.boot.playing->current;
    if (playing) {
        desc.procedure = game::client::Procedure::kPlay;
        desc.scene = game::client::world::current_scene(*session.boot.playing);
    } else {
        desc.procedure = game::client::Procedure::kLogin;
        desc.scene = session.boot.backdrop;
        desc.role_scene = session.boot.role_scene;
        if (session.online) desc.online_servers = session.online->servers();
    }
    desc.is_validated = game::client::validation_by_build();
    auto made = game::client::Display::create(desc);
    if (!made) {
        self.content.backgroundColor =
            [UIColor colorWithRed:0x1B / 255.0 green:0x4B / 255.0 blue:0x6E / 255.0 alpha:1];
        log_info("không dựng được phần hiển thị: " + std::string(made.error().detail()));
        session.display_failed = true;
        return;
    }
    session.display.emplace(std::move(*made));
    log_info("phần hiển thị đã chạy: " + session.display->description());
    session.display->set_refresh(refresh_rate(self.window.screen));
    if (session.online) session.online->on_display_made(*session.display, session.is_playing);
    session.last_serve = std::chrono::steady_clock::now();
}

- (void)stopDisplay {
    absorb_requests();
    stop_speaker();
    session.display.reset();
}

- (void)onFrame {
    if (!session.display && !session.display_failed) [self startDisplay];
    serve_session();
}

- (void)startRunning {
    if (self.link != nil) return;
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onFrame)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)stopRunning {
    [self.link invalidate];
    self.link = nil;
    session.display_failed = false;
    [self stopDisplay];
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    (void)application;
    (void)options;
    delegate_ref = self;
    const CGRect bounds = UIScreen.mainScreen.bounds;
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    ThienlongController* const controller = [[ThienlongController alloc] init];
    self.content = [[ThienlongView alloc] initWithFrame:bounds];
    controller.view = self.content;
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    const game::client::ProbeReport report = game::client::mobile_probe();
    log_info(report.detail);
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    (void)application;
    [self startRunning];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    (void)application;
    [self stopRunning];
}

@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        NSString* delegate = NSStringFromClass([ThienlongDelegate class]);
        return UIApplicationMain(argc, argv, nil, delegate);
    }
}
