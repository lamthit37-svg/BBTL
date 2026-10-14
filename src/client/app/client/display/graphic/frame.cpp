// Vòng khung của luồng vẽ: mở thiết bị, xin ảnh, ghi lệnh, nộp và trình bày.
// Shot và cache pipeline nằm ở đây vì chúng đi cùng lệnh của khung.
#include "client/display/graphic/state.hpp"
namespace game::client {

SceneTitle scene_title_lookup(const std::filesystem::path& data_root) {
    const auto book = std::make_shared<const gui::StringBook>(ui::scene_names(data_root));
    return [book](std::string_view name) { return std::string(book->find(name).value_or(name)); };
}

Display::Display(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}

Display::Display(Display&&) noexcept = default;

Display& Display::operator=(Display&&) noexcept = default;

Display::~Display() {
    if (state_ == nullptr) return;
    try {
        state_->settle();
    } catch (...) {
        // Huỷ tử không được ném; dừng luồng vẽ mà lỗi thì chỉ còn kịp nói ra bằng log.
        static_cast<void>(std::fputs("Lỗi khi dừng luồng vẽ\n", stderr));
    }
}

struct DisplayPreload::Work {
    std::filesystem::path data_root;
    std::optional<ui::HudPrep> hud;
    // Chỉ để giữ luồng nạp driver sống tới khi xong; kết quả của nó không ai cần.
    std::future<void> driver;
};

DisplayPreload::DisplayPreload(const std::filesystem::path& data_root, const std::optional<std::string>& backend)
    : work_(std::make_unique<Work>()) {
    work_->driver = std::async(std::launch::async, [backend] {
        const std::optional<gpu::Backend> parsed = backend ? gpu::parse_backend(*backend) : std::nullopt;
        static_cast<void>(gpu::enumerate_adapters(parsed.value_or(gpu::Backend::kVulkan)));
    });
    if (data_root.empty()) return;
    ui::HudDesc hud_desc;
    hud_desc.data_root = data_root;
    work_->data_root = data_root;
    work_->hud.emplace(ui::HudPrep::start(hud_desc));
}
DisplayPreload::DisplayPreload(DisplayPreload&&) noexcept = default;
DisplayPreload& DisplayPreload::operator=(DisplayPreload&&) noexcept = default;
DisplayPreload::~DisplayPreload() = default;

std::optional<ui::HudPrep> Display::State::take_early_hud(const DisplayDesc& desc) {
    if (!desc.preload || !desc.preload->work_) return std::nullopt;
    DisplayPreload::Work& early = *desc.preload->work_;
    if (!early.hud || early.data_root != desc.data_root) return std::nullopt;
    return std::exchange(early.hud, std::nullopt);
}

core::Result<Display> Display::create(const DisplayDesc& desc) {
    if (desc.window == nullptr) {
        return core::fail(core::ErrorCode::kInvalidArgument, "phần hiển thị thiếu cửa sổ");
    }
    auto state = std::make_unique<State>();
    // Luồng giữ con trỏ thô của chính State (đối tượng heap, thuộc Display, luồng bị join trước
    // khi nó bị huỷ); giữ unique_ptr cục bộ thì nó hoá null ngay khi create trả về.
    State* const home = state.get();
    Launch launch;
    // jthread chỉ gọi được khi lời gọi nhận stop_token theo giá trị; ở đây chỉ chuyển tiếp cho
    // State::run, không giữ bản sao.
    // NOLINTNEXTLINE(performance-unnecessary-value-param)
    auto born = [home, &launch, &desc](std::stop_token stop) { home->run(launch, desc, stop); };
    state->spinner = std::jthread(std::move(born));
    std::unique_lock<std::mutex> waiting(launch.mutex);
    launch.done.wait(waiting, [&launch] { return launch.is_ready; });
    if (launch.is_ok) return Display(std::move(state));
    if (launch.error.has_value()) return std::unexpected(std::move(*launch.error));
    return core::fail(core::ErrorCode::kInternal, "luồng vẽ không báo kết quả khởi tạo");
}

void Display::notify_resized(PixelSize size) noexcept {
    state_->posted_size.store(pack(size), std::memory_order_relaxed);
    state_->is_resize_pending.store(true, std::memory_order_relaxed);
}

void Display::steer(const Steering& input) noexcept {
    const std::scoped_lock<std::mutex> locked(state_->steer_guard);
    Steering& kept = state_->steering;
    kept.turn_keys += input.turn_keys;
    kept.zoom_keys += input.zoom_keys;
    kept.is_home = kept.is_home || input.is_home;
    kept.toggles_pace = kept.toggles_pace != input.toggles_pace;
    kept.wants_jump = kept.wants_jump || input.wants_jump;
    if (!input.has_walk) return;
    kept.walk_forward = input.walk_forward;
    kept.walk_right = input.walk_right;
}

void Display::input(std::span<const control::InputEvent> events) {
    const std::scoped_lock<std::mutex> locked(state_->steer_guard);
    std::vector<control::InputEvent>& queued = state_->queued;
    const std::size_t room = queued.size() < kMaxQueued ? kMaxQueued - queued.size() : 0;
    const std::span<const control::InputEvent> kept = events.first(std::min(events.size(), room));
    queued.insert(queued.end(), kept.begin(), kept.end());
}

void Display::show(const std::shared_ptr<const world::ShownScene>& scene) {
    const std::scoped_lock<std::mutex> locked(state_->pending_guard);
    state_->pending = scene;
}

void Display::play(const std::shared_ptr<const world::ShownScene>& scene) {
    show(scene);
    state_->wants_play.store(true, std::memory_order_relaxed);
}

KeptRole Display::kept_role() const {
    const std::scoped_lock<std::mutex> locked(state_->kept_guard);
    return state_->played_role;
}

std::vector<Request> Display::take_requests() {
    const std::scoped_lock<std::mutex> locked(state_->request_guard);
    return std::exchange(state_->requests, {});
}

core::Status Display::finish() {
    state_->settle();
    const std::scoped_lock<std::mutex> locked(state_->outcome_guard);
    return state_->outcome;
}

std::uint64_t Display::validation_errors() const noexcept {
    return state_->reported_faults.load(std::memory_order_relaxed);
}

std::uint32_t Display::draw_count() const noexcept {
    return state_->reported_draws.load(std::memory_order_relaxed);
}

bool Display::is_spinning() const noexcept {
    return state_->is_spinning.load(std::memory_order_relaxed);
}

std::string Display::description() const {
    return state_->reported_description;
}

std::optional<control::CursorKind> Display::cursor_choice() const noexcept {
    const std::uint8_t bits = state_->cursor_bits.load(std::memory_order_relaxed);
    if (bits >= control::kCursorKinds) return std::nullopt;
    return static_cast<control::CursorKind>(bits);
}

core::Status Display::State::open_gpu(const DisplayDesc& desc) {
    gpu::DeviceDesc device_desc;
    device_desc.is_validated = desc.is_validated;
    const core::Status backend = apply_backend(device_desc, desc);
    if (!backend) return backend;
    const std::string shaders = shader_dir_of(desc.data_root);
    const std::string folder = render::resolved_shader_folder(shaders);
    const std::uint64_t shader_hash = hash_packages(folder);
    const std::filesystem::path root = writable_root(desc);
    std::vector<std::byte> cache;
    if (!root.empty()) cache = read_cache(cache_file(root, predict_cache(device_desc, shader_hash)));
    device_desc.pipeline_cache = cache;
    const bool is_forced = desc.backend.has_value();
    auto made = is_forced ? gpu::create_device(device_desc) : gpu::create_present_device(device_desc);
    if (!made) return std::unexpected(made.error());
    device = std::move(*made);
    core::mark("GPU: thiết bị tạo xong");
    const gpu::AdapterInfo& adapter = device->adapter();
    if (!root.empty()) {
        CacheId actual;
        actual.backend = adapter.backend;
        actual.vendor = adapter.vendor_id;
        actual.device = adapter.device_id;
        actual.shaders = shader_hash;
        pipeline_cache_file = cache_file(root, actual);
    }
    render::ScreenDesc screen_desc;
    screen_desc.window = desc.window;
    screen_desc.width = desc.size.width;
    screen_desc.height = desc.size.height;
    screen_desc.samples = kSamples;
    screen_desc.clear = kBackdrop;
    // Mọi nền trình Fifo: khung khoá vào nhịp quét của màn. Đo 2026-10-13 trên màn 60 Hz: mailbox với
    // trần 120 Hz vẽ 893 khung 8,3 ms mà màn chỉ hiện một nửa, khung được hiện lệch pha so với nhịp
    // quét nên bước di chuyển mỗi lần quét lúc một lúc hai nhịp mô phỏng: nhân vật chạy bị run.
    screen_desc.present_mode = gpu::PresentMode::kFifo;
    const gpu::FormatSupport astc = device->format_support(gpu::Format::kAstc4x4Unorm);
    const bool has_astc = gpu::has(astc, gpu::FormatSupport::kSampled);
    if (ui::kPhone) texture_tier = has_astc ? resource::TextureTier::kAstc : resource::TextureTier::kEtc2;
    if (ui::kPhone) kick_loading(desc);
    core::Result<render::Screen> shown = render::Screen::create(*device, screen_desc);
    if (!shown) return std::unexpected(shown.error());
    screen = std::make_unique<render::Screen>(std::move(*shown));
    core::mark("GPU: swapchain tạo xong");
    render::CatalogDesc catalog_desc;
    catalog_desc.color = screen->color_format();
    catalog_desc.depth = screen->depth_format();
    catalog_desc.samples = screen->samples();
    catalog_desc.shader_dir = shaders;
    core::Result<render::Catalog> opened = render::Catalog::open(*device, std::move(catalog_desc));
    if (!opened) return std::unexpected(opened.error());
    catalog = std::make_unique<render::Catalog>(std::move(*opened));
    const core::Status bootstrap = catalog->prepare(render::Tier::kBootstrap);
    if (!bootstrap) return bootstrap;
    // Tầng 1 trước Forward: bốn PSO model vẽ nền đăng nhập và người, không chờ tới lúc vào thế giới.
    const core::Status essential = catalog->prepare(render::Tier::kEssential);
    if (!essential) return essential;
    if (render::optional_tier_allowed(device->adapter(), device->caps())) {
        const core::Status optional = catalog->prepare(render::Tier::kOptional);
        if (!optional) std::println(stderr, "Pipeline: tầng 3: {}", optional.error());
    }
    // Gói shader cũ không có terrain.ps: mặt đất vẽ như chất liệu thường (xem Forward::create).
    if (const core::Error* fault = catalog->fault(render::Pso::kTerrain)) {
        std::println(stderr, "Pipeline địa hình: {}", *fault);
    }
    core::Result<render::Forward> pass = make_forward(*device, *screen, shaders, *catalog);
    if (!pass) return std::unexpected(pass.error());
    forward = std::make_unique<render::Forward>(std::move(*pass));
    core::mark("GPU: lượt vẽ và pipeline xong");
    open_hud(desc);
    core::mark("HUD: Hud::open xong");
    return core::ok();
}

core::Status Display::State::launch(const DisplayDesc& desc) {
    // PC: texture luôn BC, nên việc đọc đĩa không phải chờ thiết bị.
    if (!ui::kPhone) kick_loading(desc);
    const core::Status opened = open_gpu(desc);
    if (!opened) return opened;
    arm_scene(desc);
    core::mark("arm_scene xong");
    const std::string gap = closed_port_line();
    if (!gap.empty()) std::println("{}", gap);
    // Cache ghi sau tầng 0, tầng 1 và cảnh đầu. Tầng 2 tạo trong warm_scene.
    store_pipeline_cache();
    return core::ok();
}

void Display::State::run(Launch& handshake, const DisplayDesc& desc, const std::stop_token& stop) {
    const core::Status made = launch(desc);
    {
        const std::scoped_lock<std::mutex> locked(handshake.mutex);
        handshake.is_ok = made.has_value();
        if (!made) handshake.error = made.error();
        handshake.is_ready = true;
    }
    handshake.done.notify_one();
    if (!made) return;
    is_spinning.store(true, std::memory_order_relaxed);
    frame_ms.reserve(8192);
    settle_first_scene(stop);
    spin(stop);
    is_spinning.store(false, std::memory_order_relaxed);
    wrap_up();
}

void Display::State::spin(const std::stop_token& stop) {
    core::Clock::time_point previous = core::Clock::now();
    bool is_running = !stop.stop_requested();
    while (is_running) {
        is_running = turn_one(previous) && !stop.stop_requested();
    }
}

[[nodiscard]] bool Display::State::turn_one(core::Clock::time_point& previous) {
    adopt();
    const TimePoint load_began = core::Clock::now();
    pump_load();
    last_load_ms = millis_between(load_began, core::Clock::now());
    const PixelSize size = unpack(posted_size.load(std::memory_order_relaxed));
    const bool is_hidden = size.width == 0 || size.height == 0;
    if (is_hidden) {
        nap(previous);
        return true;
    }
    return turn(previous);
}

bool Display::State::turn(core::Clock::time_point& previous) {
    const bool wants_fit = is_resize_pending.exchange(false, std::memory_order_relaxed);
    const Refit state = wants_fit ? refit() : Refit::kDone;
    if (state == Refit::kFailed) return false;
    if (state == Refit::kRetry) {
        nap(previous);
        return true;
    }
    const TimePoint render_began = core::Clock::now();
    const core::Status frame = render();
    const double render_ms = millis_between(render_began, core::Clock::now());
    const TimePoint pace_began = core::Clock::now();
    const double spent_ms = last_load_ms + render_ms;
    if (frame && !stale_flag) hold_pace(spent_ms);
    const double pace_ms = millis_between(pace_began, core::Clock::now());
    const core::Clock::time_point now = core::Clock::now();
    if (frame && wait_flag) {
        wait_flag = false;
        nap(previous);
        return true;
    }
    const bool is_stale = frame && stale_flag;
    if (is_stale) {
        // Bề mặt đã đổi cỡ giữa chừng: chờ cỡ mới tới rồi dựng lại, không quay cứng chờ nó.
        ++stale_frames;
        is_resize_pending.store(true, std::memory_order_relaxed);
        nap(previous);
        return true;
    }
    IntervalNote note;
    note.interval = std::chrono::duration<double, std::milli>(now - previous).count();
    note.render_ms = render_ms;
    note.pace_ms = pace_ms;
    record_interval(note);
    previous = now;
    publish();
    if (!frame) {
        keep(frame);
        return false;
    }
    return true;
}

core::Status Display::State::fit() {
    const PixelSize size = unpack(posted_size.load(std::memory_order_relaxed));
    if (size.width == 0 || size.height == 0) return core::ok();
    return screen->resize(size.width, size.height);
}

Refit Display::State::refit() {
    const core::Status fitted = fit();
    const bool is_pending = !fitted && (screen->width() == 0 || screen->height() == 0);
    if (is_pending) {
        // Bề mặt chưa báo cỡ thật: xin thử lại ở lượt sau.
        is_resize_pending.store(true, std::memory_order_relaxed);
        return Refit::kRetry;
    }
    if (!fitted) {
        keep(fitted);
        return Refit::kFailed;
    }
    return Refit::kDone;
}

float Display::State::step_clock(float elapsed) noexcept {
    if (walk_stamp < 0.0F) {
        walk_stamp = elapsed;
        return 0.0F;
    }
    const float dt = std::clamp(elapsed - walk_stamp, 0.0F, kMaxStep);
    walk_stamp = elapsed;
    return dt;
}

Display::State::Taken Display::State::take_steering() {
    const std::scoped_lock<std::mutex> locked(steer_guard);
    Taken taken;
    taken.keys = steering;
    taken.events.swap(queued);
    steering.turn_keys = 0;
    steering.zoom_keys = 0;
    steering.is_home = false;
    if (steering.toggles_pace) shows_pace = !shows_pace;
    steering.toggles_pace = false;
    steering.wants_jump = false;
    return taken;
}

core::Status Display::State::present_drawn(PresentAsk ask) const {
    const core::Status submitted = submit_frame(*ask.list);
    if (!submitted) {
        discard_shot(*device, ask.shot);
        return submitted;
    }
    if (ask.shot) finish_shot(*ask.shot);
    return submitted;
}

core::Status Display::State::render() {
    stale_flag = false;
    wait_flag = false;
    const core::Clock::time_point asked = core::Clock::now();
    prepare_board();
    last_prepare_ms = millis_between(asked, core::Clock::now());
    const core::Clock::time_point drawing = core::Clock::now();
    const core::Result<gpu::CommandList*> list = device->begin_commands(gpu::QueueType::kGraphics);
    if (!list) return std::unexpected(list.error());
    screen->set_clear(light.clear_color());
    const core::Result<std::uint32_t> slot = screen->begin(**list);
    // Bề mặt đổi cỡ giữa chừng: bỏ khung này, spin() dựng lại ở khung kế.
    const bool is_wait = !slot && slot.error().code() == core::ErrorCode::kTimeout;
    if (is_wait) {
        wait_flag = true;
        return device->end_frame();
    }
    const bool is_stale = !slot && slot.error().code() == core::ErrorCode::kInvalidState;
    stale_flag = is_stale;
    if (is_stale) return device->end_frame();
    if (!slot) return std::unexpected(slot.error());
    const core::Clock::time_point acquired = core::Clock::now();
    const core::Status shown = draw_world(**list, *slot);
    if (!shown) return shown;
    const core::Clock::time_point recorded = core::Clock::now();
    screen->end(**list);
    scene_draws = forward->draw_count();
    record_head(**list);
    const std::optional<ShotPlan> shot = record_shot(**list, *slot);
    const PresentAsk present{.list = *list, .shot = shot};
    const core::Status submitted = present_drawn(present);
    if (!submitted) return submitted;
    if (!has_marked_first) {
        has_marked_first = true;
        core::mark("khung đầu đã trình");
    }
    const core::Status ended = device->end_frame();
    // Chia thời gian khung vào ba chặng để biết chặng nào chặn: xin ảnh (chờ GPU nhả ảnh cũ), ghi
    // lệnh vẽ, và nộp + trình bày (chờ vblank hoặc chờ GPU). Số in ra là trung bình mỗi khung.
    const FrameMarks marks{.asked = drawing, .acquired = acquired, .recorded = recorded};
    stamp_phases(marks);
    return ended;
}

core::Status Display::State::draw_world(gpu::CommandList& list, std::uint32_t slot) {
    const float elapsed = std::chrono::duration<float>(core::Clock::now() - started).count();
    FrameAsk ask;
    ask.elapsed = elapsed;
    ask.size = render::ViewSize{.width = screen->width(), .height = screen->height()};
    const render::Camera camera = ask.size.height > 0 ? frame_camera(ask) : render::Camera{};
    advance_fx(elapsed);
    compose_frame();
    ensure_sky();
    append_sky(camera);
    ensure_water();
    append_water();
    append_fx_meshes();
    render::Lighting lighting = light.view();
    lighting.seconds = elapsed;
    const core::Status drawn = forward->draw(list, slot, camera, lighting, frame_instances);
    if (!drawn) return drawn;
    const FxAsk effects{.list = &list, .camera = &camera, .slot = slot, .elapsed = elapsed};
    draw_fx(effects);
    return paint_hud(list, slot);
}

core::Status Display::State::submit_frame(gpu::CommandList& list) const {
    const std::array<gpu::CommandList*, 1> one{&list};
    gpu::SubmitDesc submit;
    submit.lists = one;
    submit.present_target = screen->swapchain();
    const core::Status sent = device->submit(gpu::QueueType::kGraphics, submit);
    if (!sent) return sent;
    return screen->present();
}

std::optional<ShotPlan> Display::State::record_shot(gpu::CommandList& list, std::uint32_t slot) {
    if (shot_taken || shot_path.empty() || arrival.has_value()) return std::nullopt;
    // Bảng đo đang hiện thì chờ đủ mẫu: khung đầu chưa có số nào để chụp.
    constexpr std::size_t kSamplesForShot = 30;
    if (shows_pace && pace_filled < kSamplesForShot) return std::nullopt;
    shot_taken = true;
    const gpu::Format colour = screen->color_format();
    const std::uint32_t width = screen->width();
    const std::uint32_t height = screen->height();
    const auto format = shot_format(colour);
    if (!format) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), format.error());
        return std::nullopt;
    }
    const std::uint64_t stride = gpu::padded_row_bytes(colour, width);
    gpu::BufferDesc buffer;
    buffer.name = "client.shot.readback";
    buffer.size = stride * height;
    buffer.usage = gpu::BufferUsage::kCopyDest;
    buffer.memory = gpu::MemoryDomain::kReadback;
    const auto made = device->create_buffer(buffer);
    if (!made) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), made.error());
        return std::nullopt;
    }
    const gpu::TextureHandle image = screen->swapchain()->image(slot);
    shot_barrier(list, image, true);
    gpu::BufferTextureCopy region;
    region.width = width;
    region.height = height;
    list.copy_texture_to_buffer(image, *made, std::span(&region, 1));
    shot_barrier(list, image, false);
    ShotPlan plan;
    plan.staging = *made;
    plan.size = buffer.size;
    plan.stride = stride;
    plan.width = width;
    plan.height = height;
    plan.format = *format;
    return plan;
}

void Display::State::finish_shot(const ShotPlan& plan) const {
    core::mark("chụp ảnh (trước khi mã hoá PNG)");
    const core::Status waited = device->wait_idle();
    if (!waited) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), waited.error());
        return;
    }
    std::vector<std::byte> pixels(plan.size);
    const core::Status read = device->read_buffer(plan.staging, 0, pixels);
    device->destroy(plan.staging);
    if (!read) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), read.error());
        return;
    }
    capture::FrameView taken;
    taken.pixels = pixels;
    taken.width = plan.width;
    taken.height = plan.height;
    taken.stride = plan.stride;
    taken.format = plan.format;
    capture::PngOptions options;
    options.alpha = false;
    const auto png = capture::encode_png(taken, options);
    if (!png) {
        std::println(stderr, "Lỗi chụp {}: {}", io::utf8_of(shot_path), png.error());
        return;
    }
    if (!write_bytes(shot_path, *png)) {
        std::println(stderr, "Lỗi chụp {}: không ghi được tệp", io::utf8_of(shot_path));
        return;
    }
    std::println("Đã ghi ảnh chụp {} ({} byte)", io::utf8_of(shot_path), png->size());
}

void Display::State::publish() noexcept {
    reported_faults.store(device->validation_errors(), std::memory_order_relaxed);
    reported_draws.store(scene_draws, std::memory_order_relaxed);
}

void Display::State::keep(const core::Status& failure) noexcept {
    const std::scoped_lock<std::mutex> locked(outcome_guard);
    if (!outcome) return;
    outcome = failure;
#ifdef __ANDROID__
    std::string text(failure.error().message());
    const std::string_view extra = failure.error().detail();
    if (!extra.empty()) {
        text.push_back(' ');
        text.append(extra);
    }
    __android_log_write(ANDROID_LOG_ERROR, "THIENLONG", text.c_str());
#endif
}

void Display::State::store_pipeline_cache() const {
    if (device == nullptr || pipeline_cache_file.empty()) return;
    const std::vector<std::byte> bytes = device->pipeline_cache();
    if (bytes.empty()) return;
    std::error_code error;
    std::filesystem::create_directories(pipeline_cache_file.parent_path(), error);
    if (error) {
        std::println(stderr, "Pipeline: không tạo được thư mục cache {}", io::utf8_of(pipeline_cache_file));
        return;
    }
    if (write_bytes(pipeline_cache_file, bytes)) return;
    std::println(stderr, "Pipeline: không ghi được {}", io::utf8_of(pipeline_cache_file));
}

void Display::State::wrap_up() {
    if (is_wrapped || device == nullptr) return;
    is_wrapped = true;
    store_pipeline_cache();
    publish();
    report_frames();
    const core::Status waited = device->wait_idle();
    const std::scoped_lock<std::mutex> locked(outcome_guard);
    if (outcome) outcome = waited;
}

// Một dòng tổng kết khoảng thời gian khung: giật hiện ra ngay ở p95 và số khung trần 20 ms.
void Display::State::report_frames() const {
    if (frame_ms.size() < 8) return;
    std::vector<double> sorted = frame_ms;
    std::ranges::sort(sorted);
    say_rank("Khung hình", rank_frames(sorted), sorted.size());
    const bool has_steady = steady_from && *steady_from + 8 < frame_ms.size();
    if (has_steady) say_steady(frame_ms, *steady_from);
    std::println("Khung bỏ vì đổi cỡ: {}", stale_frames);
    if (phase_ms.frames == 0) return;
    const auto frames = static_cast<double>(phase_ms.frames);
    const std::string acquire_ms = std::format("{:.2f}", phase_ms.acquire / frames);
    const std::string draw_ms = std::format("{:.2f}", phase_ms.draw / frames);
    const std::string submit_ms = std::format("{:.2f}", phase_ms.submit / frames);
    const std::string phases = "Chặng mỗi khung: xin ảnh " + acquire_ms + " ms, ghi lệnh vẽ " + draw_ms +
        " ms, nộp và trình bày " + submit_ms + " ms";
    std::println("{}", phases);
#ifdef __ANDROID__
    __android_log_write(ANDROID_LOG_INFO, "THIENLONG", phases.c_str());
#endif
}

void Display::State::settle() {
    if (spinner.joinable()) {
        spinner.request_stop();
        spinner.join();
    }
    wrap_up();
}

} // namespace game::client
