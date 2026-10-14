// Giao diện 2D trên khung: bảng đăng nhập, nhịp khung và việc nút nhờ vòng cửa sổ.
#include "client/display/graphic/state.hpp"
namespace game::client {

// Mở giao diện nếu đủ shader và dữ liệu; thiếu thì ghi một dòng và bỏ qua, không làm hỏng game.
void Display::State::open_hud(const DisplayDesc& desc) {
    const gpu::PipelineHandle pipeline = catalog->get(render::Pso::kUi);
    if (!pipeline) {
        const core::Error* fault = catalog->fault(render::Pso::kUi);
        if (fault != nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", *fault);
        if (fault == nullptr) std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D");
        return;
    }
    std::string shaders = shader_dir_of(desc.data_root);
    core::Result<render::UiPass> made = make_ui(*device, *screen, std::move(shaders), pipeline);
    if (!made) {
        std::println(stderr, "Giao diện: bỏ qua, không dựng được lượt vẽ 2D: {}", made.error());
        return;
    }
    ui_pass = std::make_unique<render::UiPass>(std::move(*made));
    ui::HudDesc hud_desc;
    hud_desc.data_root = desc.data_root;
    // Phần đọc đĩa đã chạy từ trước thiết bị (kick_loading); chưa có thì Hud::open tự bắt đầu.
    core::Result<ui::Hud> opened =
        hud_prep ? ui::Hud::open(*ui_pass, hud_desc, std::move(*hud_prep)) : ui::Hud::open(*ui_pass, hud_desc);
    hud_prep.reset();
    if (!opened) {
        std::println(stderr, "Giao diện: bỏ qua, không mở được dữ liệu: {}", opened.error());
        return;
    }
    hud = std::make_unique<ui::Hud>(std::move(*opened));
    const std::filesystem::path font_file = desc.data_root / "Interface" / "Schema" / "VTNAM14.bin";
    core::Result<ui::BitmapFont> font = ui::BitmapFont::open(font_file);
    if (!font) {
        std::println(stderr, "Nhịp: không có phông bảng số: {}", font.error());
        return;
    }
    const core::Result<std::uint32_t> texture = ui_pass->add_texture(font->atlas());
    if (!texture) {
        std::println(stderr, "Nhịp: không tải được phông: {}", texture.error());
        return;
    }
    pace_font = std::move(*font);
    pace_texture = *texture;
}

void Display::State::kick_loading(const DisplayDesc& desc) {
    if (feeder || desc.data_root.empty()) return;
    hud_prep = take_early_hud(desc);
    if (!hud_prep) {
        ui::HudDesc hud_desc;
        hud_desc.data_root = desc.data_root;
        hud_prep.emplace(ui::HudPrep::start(hud_desc));
    }
    // Cảnh đầu: lập bảng mesh rồi giao luồng đọc ngay. arm_scene chỉ còn dựng pipeline của cảnh (warm_scene) và
    // phần dựng GPU; mesh đọc xong trong lúc thiết bị còn đang tạo.
    held = desc.scene;
    data_root = desc.data_root;
    feeder = std::make_unique<Feed>();
    if (held) post_load(held, false);
}

void Display::State::arm_scene(const DisplayDesc& desc) {
    held = desc.scene;
    role_scene = desc.role_scene;
    {
        const std::scoped_lock<std::mutex> locked(pending_guard);
        pending = held;
    }
    data_root = desc.data_root;
    save_root = desc.save_root;
    shot_path = desc.shot_path;
    is_bare = desc.is_bare;
    shows_pace = desc.shows_pace;
    procedure = desc.procedure;
    if (!feeder) feeder = std::make_unique<Feed>();
    if (!held) {
        stage = desc.stage;
        ground = desc.ground;
        light = stage != nullptr ? light_of(*stage) : SceneLight{};
        load_stage();
    }
    // Gốc của đồng hồ khung đặt trước mọi lần dựng giao diện: open_login và prepare_board đã gọi
    // prepare_hud, trước đây chúng đọc một gốc chưa đặt và đưa cho giao diện một mốc rất lớn rồi
    // mốc tụt về 0 ở khung thật đầu tiên.
    started = core::Clock::now();
    // Nướng địa hình bắt đầu trước khi dựng giao diện và người chơi, để ba việc chạy cùng lúc.
    // Lượt đọc của cảnh đầu đã giao ở kick_loading: ở đây chỉ còn pipeline và hiệu ứng của cảnh.
    if (held && arrival.has_value()) warm_scene();
    if (held && !arrival.has_value()) begin_load(held);
    if (!held && stage != nullptr) warm_scene();
    // Màn đăng nhập chưa có nhân vật nào: không nạp mô hình. Sổ và danh sách tạo đọc trước khung đầu.
    if (desc.restored.has) apply_kept(desc.restored);
    if (procedure == Procedure::kLogin) open_login();
    if (procedure == Procedure::kPlay) load_player();
    prepare_board();
    const gpu::AdapterInfo& adapter = device->adapter();
    const gpu::PresentMode shown = screen->swapchain()->present_mode();
    const std::string_view api = gpu::name(adapter.backend);
    const std::string_view mode = gpu::name(shown);
    reported_description = std::format("{} trên {}, trình {}, có forward", api, adapter.name, mode);
    posted_size.store(pack(desc.size), std::memory_order_relaxed);
}

// Rời thủ tục đăng nhập: từ khung này camera, người chơi và giao diện là của màn chơi. Người chơi
// lấy mặt, tóc và giới của nhân vật vừa chọn; chưa chọn thì là nhân vật mới mặc định.
void Display::State::start_play() {
    if (procedure == Procedure::kPlay) return;
    procedure = Procedure::kPlay;
    typed.clear();
    apply_role();
    load_player();
}

void Display::State::open_login() {
    if (!hud || roles_loaded) return;
    roles_loaded = true;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    const std::filesystem::path file = root / "Save" / "roles.tsv";
    const std::string text = read_save_text(file);
    if (!hud->recall_roles(text)) std::println(stderr, "Nhân vật: sổ hỏng phiên bản, bắt đầu sổ trống");
    static_cast<void>(hud->recall_last_server(read_save_text(root / "Save" / "last_server.tsv")));
}

void Display::State::store_roles() const {
    if (!hud) return;
    const std::filesystem::path root = save_root.empty() ? data_root : save_root;
    if (const std::optional<std::string> text = hud->roles_text()) {
        if (write_save_text(root / "Save" / "roles.tsv", *text)) hud->mark_roles_saved();
    }
    if (const std::optional<std::string> text = hud->last_server_text()) {
        if (write_save_text(root / "Save" / "last_server.tsv", *text)) hud->mark_last_server_saved();
    }
}

void Display::State::apply_role() {
    const ui::panel::Role* role = hud ? hud->entering_role() : nullptr;
    if (role == nullptr) return;
    hero = hero::newcomer();
    hero.name = role->name;
    hero.level = role->level;
    hero.portrait = hero::PortraitId{role->portrait};
    hero.sect = static_cast<hero::Sect>(role->sect);
    // Trần kinh nghiệm theo cấp thật của nhân vật (Config/PlayerExpLevel.txt), không giữ số của cấp 1.
    const std::filesystem::path levels = data_root / "Config" / "PlayerExpLevel.txt";
    const auto table = hero::read_exp_table(read_save_text(levels));
    if (!table) std::println(stderr, "Nhân vật: {}: {}", io::utf8_of(levels), table.error());
    const std::optional<std::int64_t> need = table ? hero::exp_need(*table, hero.level) : std::nullopt;
    if (table && !need) std::println(stderr, "Nhân vật: cấp {} không có trong bảng kinh nghiệm", hero.level);
    if (need) hero.experience.top = *need;
    role_look = {};
    role_look.face = role->face;
    role_look.hair = role->hair;
    role_look.body = role->body;
    role_look.arm = role->arm;
    role_look.foot = role->foot;
    const bool is_female = role->sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
    KeptRole copy;
    copy.has = true;
    copy.sex = role->sex;
    copy.face = role->face;
    copy.hair = role->hair;
    copy.body = role->body;
    copy.arm = role->arm;
    copy.foot = role->foot;
    const std::scoped_lock<std::mutex> locked(kept_guard);
    played_role = std::move(copy);
}

void Display::State::apply_kept(const KeptRole& restored) {
    if (!restored.has) return;
    role_look = {};
    role_look.face = restored.face;
    role_look.hair = restored.hair;
    role_look.body = restored.body;
    role_look.arm = restored.arm;
    role_look.foot = restored.foot;
    const bool is_female = restored.sex == 0;
    role_race = is_female ? look::Race::kFemale : look::Race::kMale;
    has_role_look = true;
}

// Giao diện của khung: đưa đầu vào (kể cả ký tự vừa gõ) rồi lấy việc nó nhờ vòng cửa sổ làm.
void Display::State::prepare_hud() {
    if (!hud) return;
    hud->prepare(hud_view());
    typed.clear();
    hud_wheel = 0;
    const std::optional<ui::Action> action = hud->take_action();
    if (action) post_request(*action);
    if (const std::optional<ui::RunTo> run = hud->take_run_to()) run_to_scene_point(*run);
    if (body) body->set_spin(hud->equip_spin());
    store_roles();
}

void Display::State::post_request(ui::Action action) {
    const auto found = std::ranges::find(kActionRequests, action, &ActionRequest::action);
    if (found == kActionRequests.end()) return;
    const std::scoped_lock<std::mutex> locked(request_guard);
    requests.push_back(found->request);
}

// Đầu vào của HUD ở khung này: cỡ khung, chuột theo điểm ảnh, nhân vật, đồng hồ, và cảnh cùng chỗ
// đứng, hướng mặt cho minimap.
ui::HudView Display::State::hud_view() const {
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    ui::HudView view;
    view.phase = procedure == Procedure::kLogin ? ui::Phase::kLogin : ui::Phase::kPlay;
    view.width = width;
    view.height = height;
    view.hero = &hero;
    if (view_count > 0) view.views = std::span(head_views).first(view_count);
    view.clock = std::chrono::duration_cast<std::chrono::milliseconds>(core::Clock::now() - started);
    view.pointer.emplace();
    view.pointer->x = pointer.x * width;
    view.pointer->y = pointer.y * height;
    view.pointer->is_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kLeft)];
    view.pointer->is_right_down = is_button_down[static_cast<std::size_t>(control::MouseButton::kRight)];
    view.typed = typed;
    view.wheel = hud_wheel;
    view.loading = scene_load();
    if (!held || !terrain) return view;
    const core::GroundPoint feet = terrain->to_game(foot());
    view.scene.radar = held->radar;
    view.scene.width = static_cast<float>(held->x_size);
    view.scene.depth = static_cast<float>(held->z_size);
    view.scene.player_x = feet.x;
    view.scene.player_z = feet.z;
    view.scene.name = held->name;
    view.scene.facing = facing;
    view.scene.id = held->id;
    return view;
}

// Việc nạp cảnh mà bảng chuyển cảnh của giao diện báo cho người chơi: cảnh của màn chơi đang được
// nạp, kèm phần mesh đã đặt xong. Chỉ báo khi RỜI một cảnh của thế giới: bản gốc phát
// PLAYER_LEAVE_WORLD ở GCNotifyChangeScene (Game.exe 0x1405493da), còn lần vào đầu từ bảng chọn
// (LCRetCharLogin -> ChangeScene -> Enter) và thủ tục đăng nhập đổi cảnh nền không phát. Trước khi
// mặt đất sẵn thì phần trăm là 0.
std::optional<ui::SceneLoad> Display::State::scene_load() const {
    if (procedure != Procedure::kPlay || !has_entered_world) return std::nullopt;
    if (!arrival.has_value() || !arrival->scene) return std::nullopt;
    ui::SceneLoad load;
    load.name = arrival->scene->name;
    const std::size_t total = arrival->table.meshes.size();
    if (arrival->ground_done && total > 0) {
        load.percent = static_cast<std::int32_t>((std::min(arrival->cursor, total) * 100U) / total);
    }
    return load;
}

bool Display::State::is_on_hud(control::ScreenPoint point) const {
    if (!hud) return false;
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    return hud->contains(point.x * width, point.y * height);
}

void Display::State::fill_pace_board() {
    pace_board.vertices.clear();
    pace_board.batches.clear();
    if (!pace_font || !shows_pace) return;
    ui::PacePlace place;
    place.font = &*pace_font;
    place.texture = pace_texture;
    // Góc phải, dưới bản đồ nhỏ: bên trái là khung chat, bên trên là khung nhân vật.
    place.origin_x = 16.0F;
    place.origin_y = 240.0F;
    place.screen_width = static_cast<float>(screen->width());
    ui::write_pace(place, pace_shown, pace_board);
}

void Display::State::prepare_board() {
    prepare_hud();
    fill_pace_board();
}

void Display::State::stamp_phases(const FrameMarks& marks) {
    pace_last.acquire_ms = static_cast<float>(millis_between(marks.asked, marks.acquired));
    pace_last.draw_ms = static_cast<float>(millis_between(marks.acquired, marks.recorded));
    pace_last.submit_ms = static_cast<float>(millis_between(marks.recorded, core::Clock::now()));
    pace_last.draws = scene_draws;
    const std::size_t quads = hud ? hud->quad_count() : 0;
    pace_last.quads = static_cast<std::uint32_t>(quads);
    phase_ms.acquire += static_cast<double>(pace_last.acquire_ms);
    phase_ms.draw += static_cast<double>(pace_last.draw_ms);
    phase_ms.submit += static_cast<double>(pace_last.submit_ms);
    ++phase_ms.frames;
}

void Display::State::ensure_clock() {
    if (frame_clock) return;
    core::TickConfig config;
    config.hz = render_hz;
    config.max_steps = 1;
    core::Result<core::FixedStep> made = core::FixedStep::create(config);
    if (!made) return;
    frame_clock = *made;
}

void Display::State::hold_pace(double spent_ms) {
    if constexpr (ui::kPhone) return;
    // Fifo đã chờ nhịp quét trong lúc xin ảnh và trình: ngủ thêm theo đồng hồ riêng chỉ làm khung trượt
    // khỏi nhịp quét. Đồng hồ trần chỉ còn cho bề mặt không có Fifo (driver từ chối, trình ngay).
    if (screen->swapchain()->present_mode() == gpu::PresentMode::kFifo) return;
    // Việc của khung đã nuốt hết một nhịp 120 Hz thì trình ngay. Ngủ thêm biến khung nạp thành
    // hai nhịp (đo: đưa đất 15 ms rồi ngủ 8 ms thành khung 26 ms).
    if (spent_ms >= 1000.0 / static_cast<double>(render_hz)) return;
    ensure_clock();
    if (!frame_clock) return;
    static_cast<void>(frame_clock->advance(core::Clock::now()));
    const std::optional<core::Clock::time_point> next = frame_clock->next_tick();
    if (!next) return;
    core::sleep_until(*next);
}

void Display::State::record_interval(IntervalNote note) {
    frame_ms.push_back(note.interval);
    note_pace(note.interval);
    SpikeParts spike;
    spike.interval = note.interval;
    spike.load_ms = last_load_ms;
    spike.render_ms = note.render_ms;
    spike.pace_ms = note.pace_ms;
    spike.acquire_ms = pace_last.acquire_ms;
    spike.draw_ms = pace_last.draw_ms;
    spike.submit_ms = pace_last.submit_ms;
    spike.prepare_ms = last_prepare_ms;
    report_spike(spike);
}

void Display::State::note_pace(double interval) {
    constexpr std::size_t kPaceWindow = 90;
    pace_ring.at(pace_cursor) = static_cast<float>(interval);
    pace_cursor = (pace_cursor + 1) % kPaceWindow;
    if (pace_filled < kPaceWindow) ++pace_filled;
    ui::PaceNumbers phases;
    phases.acquire_ms = pace_last.acquire_ms;
    phases.draw_ms = pace_last.draw_ms;
    phases.submit_ms = pace_last.submit_ms;
    phases.draws = pace_last.draws;
    phases.ui_quads = pace_last.quads;
    phases.prepare_ms = static_cast<float>(last_prepare_ms);
    if (render_hz > 0) phases.budget_ms = 1000.0F / static_cast<float>(render_hz);
    phases.output_width = screen->width();
    phases.output_height = screen->height();
    phases.samples = screen->samples();
    const std::span<const float> samples(pace_ring.data(), pace_filled);
    pace_shown = ui::pace_of(samples, phases);
    pace_shown.last_ms = static_cast<float>(interval);
}

core::Status Display::State::paint_hud(gpu::CommandList& list, std::uint32_t slot) const {
    if (!hud || is_bare) return core::ok();
    ui::Hud::HudExtra extra;
    extra.vertices = pace_board.vertices;
    extra.batches = pace_board.batches;
    return hud->draw(list, slot, extra);
}
} // namespace game::client
