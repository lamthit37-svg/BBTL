// Trạng thái của luồng vẽ. Nằm ở header nội bộ để mỗi domain một tệp dịch.
#pragma once
#include "client/display/graphic/prelude.hpp"
#include "motion/jump.hpp"

#include <random>
namespace game::client {

// Toàn bộ trạng thái của luồng vẽ. Luồng thông điệp chỉ đọc các ô atomic cuối tệp; mọi thứ khác
// thuộc riêng luồng vẽ. Huỷ ngược thứ tự khai báo: mesh (drawable trước uploaded trước model),
// forward, screen rồi device.
struct Display::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State() = default;

    // Khởi tạo thiết bị, màn hình vẽ, renderer và nội dung; gọi trên luồng vẽ, báo kết quả qua bàn.
    [[nodiscard]] core::Status launch(const DisplayDesc& desc);
    [[nodiscard]] core::Status open_gpu(const DisplayDesc& desc);
    void open_hud(const DisplayDesc& desc);
    // Việc đọc đĩa không cần thiết bị GPU, bắt đầu trước khi tạo thiết bị để chạy trùng với nó: phần đọc của
    // giao diện (ui::HudPrep) và lượt nạp của cảnh đầu (đọc mesh, nướng địa hình). Gọi một lần; lần sau bỏ qua.
    // Trên điện thoại cấp texture (ASTC hay ETC2) chỉ biết sau khi có thiết bị nên open_gpu gọi lại ở đó.
    void kick_loading(const DisplayDesc& desc);
    // Phần đọc đĩa của giao diện do DisplayPreload bắt đầu, nếu có và cùng data_root; lấy đi nên chỉ lấy được một lần.
    [[nodiscard]] static std::optional<ui::HudPrep> take_early_hud(const DisplayDesc& desc);
    // Việc đọc bảng người chơi do DisplayPreload bắt đầu, nếu có và cùng data_root (không thì future rỗng); lấy một lần.
    [[nodiscard]] static PlayerTablesJob take_early_tables(const DisplayDesc& desc);
    void arm_scene(const DisplayDesc& desc);
    // Thân của luồng vẽ: khởi tạo qua bàn tay bắt tay, báo kết quả, rồi quay tới khi dừng.
    void run(Launch& handshake, const DisplayDesc& desc, const std::stop_token& stop);
    // Vòng của luồng vẽ tới khi bị dừng hoặc lỗi vẽ.
    void spin(const std::stop_token& stop);
    // Một lượt của luồng vẽ, kể cả lúc cửa sổ bị che; false khi dừng vì lỗi vẽ.
    [[nodiscard]] bool turn_one(core::Clock::time_point& previous);
    // Một lượt khi cửa sổ còn hiện: dựng lại nếu vừa đổi cỡ, vẽ một khung, đo nhịp; false khi dừng.
    [[nodiscard]] bool turn(core::Clock::time_point& previous);
    // Dựng lại màn hình vẽ theo cỡ vùng vẽ mới nhất. Cửa sổ thu nhỏ (cỡ 0) thì giữ nguyên cờ.
    [[nodiscard]] core::Status fit();
    // Dựng lại qua refit(): giữa lúc khôi phục từ thu nhỏ, bề mặt có lúc còn báo cỡ 0 — chờ một
    // nhịp rồi thử lại (kRetry) thay vì coi là lỗi.
    [[nodiscard]] Refit refit();
    // Vẽ một khung: camera và đèn, rồi mọi instance; nộp và trình bày.
    [[nodiscard]] float step_clock(float elapsed) noexcept;
    void ensure_sim();
    void simulate_motion(const Steering& keys, core::Clock::time_point now);
    // Điều khiển đã gom của một khung: phím và các sự kiện chuột, chạm theo thứ tự tới.
    struct Taken {
        Steering keys;
        std::vector<control::InputEvent> events;
    };
    [[nodiscard]] Taken take_steering();
    // Gom sự kiện chuột và chạm của khung thành một mẫu chuột; sự kiện chưa dùng được trả lại
    // hàng chờ cho khung sau.
    void take_events(std::span<const control::InputEvent> events);
    [[nodiscard]] bool absorb(const control::InputEvent& event);
    [[nodiscard]] bool flip_button(const control::InputEvent& event);
    void move_pointer(const control::InputEvent& event);
    void cancel_left() noexcept;
    void turn_wheel(float notches);
    void release_stick();
    // Vào cảnh, phím camera, rồi một khung chuột của màn chơi (control::Pilot).
    void enter_camera(int scene_id);
    void steer_camera(const Steering& keys);
    void pilot_frame(core::Clock::time_point now, float seconds);
    [[nodiscard]] control::MouseSample mouse_sample() const noexcept;
    // Ghi con trỏ của khung cho luồng cửa sổ. Chưa có chọn đối tượng dưới chuột nên hover để
    // trống.
    void publish_cursor() noexcept;
    void hold_stick_frame(core::Clock::time_point now);
    void apply_stick_step(const control::StickStep& step);
    void order_move(std::optional<core::GroundPoint> target, nav::MoveMode mode);
    [[nodiscard]] std::optional<core::GroundPoint> pick_at(control::ScreenPoint point) const;
    [[nodiscard]] ogre::Vec3 foot() const;
    void move_player(const Steering& keys, float dt);
    void walk_free(const Steering& keys, float dt);
    void step_jump(bool wants_jump, float dt);
    [[nodiscard]] float jump_lift(float surface) const noexcept;
    void walk_order(float dt);
    // Một khung Tick_Move rồi kéo điểm vào trong map (VerifyPos).
    void apply_tick(motion::MoveAsk ask);
    void place_step(const motion::MoveStep& step, core::GroundPoint from);
    void finish_leg();
    void rebuild_terrain(int scene_id);
    // Đọc ScenePosDefineEx một lần. Thiếu tệp thì in một dòng và đứng giữa map.
    void ensure_gates();
    // Resid đổi: điểm đến của cổng, không có điểm thì ô trống gần giữa map.
    void place_at(int scene_id);
    [[nodiscard]] render::Camera frame_camera(FrameAsk ask);
    [[nodiscard]] render::Camera idle_view(FrameAsk ask);
    [[nodiscard]] bool shows_world_role() const;
    [[nodiscard]] bool shows_role_scene() const;
    [[nodiscard]] render::Camera role_scene_camera(render::ViewSize size) const;
    void append_login_role();
    void close_mouse_frame() noexcept;
    void prepare_hud();
    void post_request(ui::Action action);
    void pump_online();
    void run_to_scene_point(ui::RunTo target);
    void open_login();
    void store_roles() const;
    void apply_role();
    // Gieo vật phẩm của công cụ thử (weapon_item) vào hero.equipment; gọi lại mỗi lần hero dựng mới.
    void seed_equipment();
    // Phím ô thao tác thành lệnh dùng skill (CAI_MySelf::UseSkill): chọn bước liên hoàn kế của skill ở ô đó.
    void begin_strike(std::optional<std::uint32_t> slot);
    // Khối con kịch bản đòn vừa tới mốc: hiệu ứng thành hệ hạt trong FxView, âm thanh vào sounds_due cho luồng cửa sổ.
    void dispatch_cues();
    // Hiệu ứng đồ của người chơi (PlayerActor::gear_effects): dựng khi có, dừng khi hết, dời theo điểm 武器特效点 mỗi khung.
    void sync_gear();
    // Hiệu ứng bám của đòn (SkillCue::token): dời theo điểm gắn mỗi khung tới khi hiệu ứng hết.
    void sync_follows();
    void apply_kept(const KeptRole& restored);
    void start_play();
    [[nodiscard]] ui::HudView hud_view() const;
    [[nodiscard]] std::optional<ui::SceneLoad> scene_load() const;
    [[nodiscard]] bool is_on_hud(control::ScreenPoint point) const;
    void fill_pace_board();
    void prepare_board();
    // Ba mốc của một khung: bắt đầu xin ảnh, đã có ảnh, đã ghi xong lệnh vẽ.
    struct FrameMarks {
        TimePoint asked;
        TimePoint acquired;
        TimePoint recorded;
    };
    void stamp_phases(const FrameMarks& marks);
    [[nodiscard]] core::Clock::time_point await_shown();
    struct IntervalNote {
        double interval = 0.0;
        double render_ms = 0.0;
        double pace_ms = 0.0;
    };
    void note_pace(double interval);
    void record_interval(IntervalNote note);
    void ensure_clock();
    void hold_pace(double spent_ms);
    // Ngân sách một khung của bảng đo, ms; 0 khi chưa biết gì.
    [[nodiscard]] float frame_budget_ms() const noexcept;
    // --walk: thay phím đi của khung bằng "giữ W" và xoay hướng nhìn theo thời gian khung.
    [[nodiscard]] Steering auto_walk(const Steering& keys, float seconds);
    void note_auto_strike(Steering& keys);
    // --walk: ghi quãng chân đi được ở khung này (sau simulate_motion) và in tổng kết lúc thoát.
    void note_walk_step();
    void report_walk() const;
    [[nodiscard]] core::Status paint_hud(gpu::CommandList& list, std::uint32_t slot) const;
    struct FxAsk {
        gpu::CommandList* list = nullptr;
        const render::Camera* camera = nullptr;
        std::uint32_t slot = 0;
        float elapsed = 0.0F;
    };
    void advance_fx(float elapsed);
    [[nodiscard]] std::size_t fx_mesh_slot(const fx::Field& field);
    void push_fx_field(const fx::Field& field, std::size_t slot);
    void append_fx_meshes();
    void draw_fx(const FxAsk& ask) const;
    // Camera, mọi instance, hiệu ứng rồi HUD của một khung, vào ảnh slot.
    [[nodiscard]] core::Status draw_world(gpu::CommandList& list, std::uint32_t slot);
    struct PresentAsk {
        gpu::CommandList* list = nullptr;
        std::optional<ShotPlan> shot;
    };
    [[nodiscard]] core::Status present_drawn(PresentAsk ask) const;
    [[nodiscard]] core::Status render();
    // Lấy cảnh mới nếu luồng cửa sổ vừa đổi resid. Mesh prop đã có thì không đọc lại đĩa.
    void adopt();
    void clear_shown();
    void clear_if_shown();
    void begin_load(std::shared_ptr<const world::ShownScene> next, bool prefetch = false);
    // Phần begin_load không cần GPU: lập bảng mesh của cảnh và giao việc đọc cho luồng đọc.
    void post_load(std::shared_ptr<const world::ShownScene> next, bool prefetch);
    // Cảnh nạp trước trở thành cảnh đang vẽ: đặt những mesh đã vào nhớ, phần còn lại chảy tiếp.
    void promote_prefetch(Arrival& loading);
    // Tầng 2 khi đã có cảnh, kể cả cảnh đưa thẳng qua stage, không chỉ cảnh đổi bằng begin_load.
    void warm_scene();
    // Mở bộ vẽ hiệu ứng sau khi tầng 2 đã tạo PSO. Chưa có cảnh thì chưa gọi prepare, không báo lỗi.
    void open_fx();
    void say_fx_fault();
    void ensure_sky();
    void append_sky(const render::Camera& camera);
    void ensure_water();
    void append_water();
    [[nodiscard]] const std::string& material_script();
    void remember_mesh(Arrival& loading, FeedJob& job, std::size_t index);
    void remember_meshes(Arrival& loading, FeedJob& job);
    [[nodiscard]] bool needs_fresh_ground(const Arrival& loading) const;
    void pump_load();
    // Nạp đồng bộ cảnh đầu tiên: chạy hết phần nạp (mặt đất, mọi mesh, trời, nước) trước khi trình khung đầu,
    // để khung đầu hiện đủ cảnh lẫn giao diện thay vì hiện giao diện rồi cảnh lấp dần.
    void settle_first_scene(const std::stop_token& stop);
    void open_ground(Arrival& loading);
    [[nodiscard]] bool pull_mesh(Arrival& loading);
    [[nodiscard]] bool step_mesh(Arrival& loading);
    void stream_ground(Arrival& loading);
    void reveal(Arrival& loading);
    void show_mesh(Arrival& loading);
    void publish_mesh(Arrival& loading, std::size_t mesh_slot);
    void seal_mesh(std::size_t index, std::vector<std::size_t>& slots);
    void finish_stream();
    [[nodiscard]] core::Status submit_frame(gpu::CommandList& list) const;
    // Chờ GPU chạy xong mọi khung trước còn dùng bộ đệm của ảnh slot; xem frame_line.
    [[nodiscard]] core::Status wait_slot(std::uint32_t slot);
    void load_props();
    [[nodiscard]] std::vector<std::size_t> load_listed(const PropTable& table);
    void load_stage();
    void load_player();
    void load_head(const PlayerDesc& desc, const MeshLoader& loader);
    void keep_view(HeadShot& shot, std::string_view name);
    void record_head(gpu::CommandList& list);
    void open_role(const ui::panel::ShownModel& model);
    void step_role_stage();
    [[nodiscard]] PlayerDesc role_player(const ui::panel::ShownModel& model) const;
    [[nodiscard]] MeshLoader meshes();
    void compose_frame();
    void append_ground();
    void attach_cached_ground();
    void bind_ground(const KeptGround* slot);
    [[nodiscard]] KeptGround* make_ground(int scene_id);
    [[nodiscard]] std::size_t load_mesh(const std::string& mesh);
    // Mesh của hạt, tô bằng material hạt. Khoá nhớ là tên mesh và tên material, không dùng chung BaseWhite.
    [[nodiscard]] std::size_t load_painted_mesh(const std::string& mesh, std::string_view material,
        const fx::Paint& paint);
    [[nodiscard]] std::size_t keep_model(const std::string& mesh, ReadMesh read);
    bool keep_ground(int scene_id, ReadMesh read);
    void grow_world(const math::Aabb& local, const math::Matrix4& placed);
    void push_matrix(const render::Drawable& drawable, const math::Matrix4& placed);
    struct CrowdFill {
        std::size_t index = 0;
        math::Matrix4 placed = math::Matrix4::identity();
        std::vector<std::size_t>* crowd_of = nullptr;
    };
    void add_crowd(CrowdFill fill);
    void push_crowd(const Crowd& crowd);
    void push_crowds();
    struct PropPlace {
        const PlacedProp* prop = nullptr;
        std::span<const std::size_t> loaded;
        std::vector<std::size_t>* crowd_of = nullptr;
    };
    void place_prop(PropPlace place);
    void build_instances(const PropTable& table, std::span<const std::size_t> loaded);
    // Ghi lệnh chép ảnh khung ra buffer đọc ngược; rỗng khi không chụp hoặc hỏng.
    [[nodiscard]] std::optional<ShotPlan> record_shot(gpu::CommandList& list, std::uint32_t slot);
    // Chờ GPU chép xong, đọc buffer, nén PNG và ghi tệp; lỗi được in ra.
    void finish_shot(const ShotPlan& plan) const;
    // Lưu các số báo cáo cho luồng thông điệp đọc không khoá.
    void publish() noexcept;
    // In một dòng tổng kết khoảng thời gian khung; gọi một lần lúc dừng.
    void report_frames() const;
    // Lưu lỗi vẽ của luồng vào outcome (giữ lỗi đầu tiên).
    void keep(const core::Status& failure) noexcept;
    // Cuối vòng đời của luồng vẽ: lưu số cuối, chờ GPU rỗi, giữ lỗi đầu tiên. Không join.
    void wrap_up();
    // Ghi blob pipeline_cache của thiết bị. D3D11 trả rỗng nên không tạo file.
    void store_pipeline_cache() const;
    // Dừng khéo từ luồng thông điệp: join luồng vẽ rồi wrap_up nếu luồng chưa tự làm.
    void settle();

    // Thứ tự trường theo clang-analyzer-optin.performance.Padding. device đứng trước đối tượng
    // GPU dùng nó, nên chúng huỷ trước. feeder đứng trước spinner: luồng vẽ join xong rồi luồng
    // đọc mới join. settle join spinner trước khi State bị huỷ.
    // Nhịp đưa lên bảng: chặng của khung vừa xong.
    struct PaceLast {
        float acquire_ms = 0.0F;
        float draw_ms = 0.0F;
        float submit_ms = 0.0F;
        std::uint32_t draws = 0;
        std::uint32_t quads = 0;
    };

    // Hộp bao thế giới, cho camera quay khi chưa có mặt đất. Ánh sáng lấy một lần từ stage.
    math::Aabb world;
    SceneLight light;
    // Camera cảnh và phần chuột của màn chơi theo client 2026. Không giữ tài nguyên GPU.
    control::FollowCamera follow{control::CameraRules{}};
    control::Pilot pilot{control::PilotRules{}};
    std::optional<PlayerActor> player;
    std::unique_ptr<gpu::Device> device;
    // Sau device, trước forward và ui: huỷ các lượt vẽ trước, rồi PSO, rồi device.
    std::unique_ptr<render::Catalog> catalog;
    std::filesystem::path pipeline_cache_file;
    std::unique_ptr<render::Screen> screen;
    std::unique_ptr<render::Forward> forward;
    std::unique_ptr<FxView> fx_view;
    // Hiệu ứng đồ đang chạy trong fx_view: mẫu con, tên effect và màu đã dựng (đổi một trong ba thì dựng lại), handle
    // (0 là fx không dựng được, không thử lại).
    struct GearHandle {
        std::size_t mount = 0;
        std::string name;
        std::uint32_t colour = 0;
        std::uint32_t handle = 0;
    };
    std::vector<GearHandle> gear_handles;
    // Hiệu ứng bám của đòn: dấu của PlayerActor và handle trong fx_view.
    struct FollowHandle {
        std::uint32_t token = 0;
        std::uint32_t handle = 0;
    };
    std::vector<FollowHandle> follow_handles;
    // Đã in lỗi dựng hiệu ứng một lần. PSO chưa được yêu cầu thì fault còn trống, không in.
    bool fx_fault_noted = false;
    // Giao diện 2D. Rỗng khi thiếu shader hay dữ liệu; game vẫn chạy.
    std::unique_ptr<render::UiPass> ui_pass;
    // Phần đọc đĩa của giao diện đang chạy ở luồng riêng (kick_loading); open_hud lấy đi.
    std::optional<ui::HudPrep> hud_prep;
    // Bảng người chơi đang đọc ở luồng riêng (kick_loading); load_player lấy kết quả. Rỗng thì create tự đọc.
    PlayerTablesJob tables_job;
    std::unique_ptr<ui::Hud> hud;
    const Stage* stage = nullptr;
    // Vòm trời của cảnh đang vẽ. Drawable trỏ vào model và uploaded của chính optional này.
    std::optional<LoadedMesh> sky_mesh;
    std::string sky_stamp;
    std::optional<LoadedMesh> water_mesh;
    std::string water_stamp;
    std::string material_text;
    bool material_text_ready = false;
    float clip_near = 0.25F;
    float clip_far = 150.0F;
    const game::client::map::Ground* ground = nullptr;
    core::Clock::time_point started;
    std::atomic<PackedSize> posted_size{0};
    // Số khung bỏ vì bề mặt đã đổi cỡ. Quay nhiều nghĩa là đường này bị bão hoà.
    std::uint64_t stale_frames = 0;
    std::atomic<std::uint64_t> reported_faults{0};
    double last_load_ms = 0.0;
    double last_prepare_ms = 0.0;
    std::size_t pace_filled = 0;
    std::size_t pace_cursor = 0;
    // Đọc đĩa. Đứng trước spinner nên huỷ sau: luồng vẽ join xong rồi luồng đọc mới join.
    std::unique_ptr<Feed> feeder;
    // Ảnh đầu 3D. Đứng sau device, forward và ui_pass để huỷ trước chúng.
    std::optional<HeadShot> head;
    // Toàn thân trong vòng xem của bảng nhân vật. Cùng ngoại hình với head.
    std::optional<HeadShot> body;
    std::optional<RoleShot> role_shot;
    // Camera của bảng chọn và màn tạo cùng phần thủ tục điều khiển nó; chỉ luồng vẽ đụng.
    RoleStage role_stage;
    std::optional<core::Clock::time_point> role_stamp;
    std::shared_ptr<const world::ShownScene> held;
    // Cảnh tl3chuangjian. Chỉ luồng vẽ đọc, gán một lần lúc mở.
    std::shared_ptr<const world::ShownScene> role_scene;
    // libc++ không có atomic<shared_ptr>. Luồng cửa sổ ghi, luồng vẽ đọc, dưới pending_guard.
    std::shared_ptr<const world::ShownScene> pending;
    std::optional<std::size_t> steady_from;
    std::vector<render::Instance> frame_instances;
    std::vector<control::InputEvent> queued;
    // Ký tự gõ ở khung này, chờ lần prepare kế của giao diện. Chỉ luồng vẽ chạm vào.
    std::vector<char32_t> typed;
    // Việc giao diện nhờ vòng cửa sổ; request_guard bảo vệ requests.
    std::mutex request_guard;
    std::vector<Request> requests;
    // Chế độ trực tuyến: việc chuỗi đăng nhập nhờ phần nối máy chủ và trả lời đang chờ chuỗi; online_guard bảo vệ cả
    // hai. online_entry là chỗ vào máy chủ đặt, chờ nút vào game của chuỗi đăng nhập (chỉ luồng vẽ chạm vào).
    std::mutex online_guard;
    std::vector<ui::panel::OnlineAsk> online_asks;
    std::vector<ui::panel::OnlineReply> online_replies;
    std::optional<EntryPoint> online_entry;
    // Chỗ vào game cho lần place_at kế; spawn_guard bảo vệ (luồng cửa sổ ghi, luồng vẽ đọc).
    std::mutex spawn_guard;
    std::optional<EntryPoint> entry_spot;
    // Vòng cửa sổ đã gọi play: luồng vẽ rời thủ tục đăng nhập ở lượt kế.
    std::atomic<bool> wants_play{false};
    std::array<ui::ViewPaint, 2> head_views{};
    // Số ảnh 3D đã gắn vào giao diện: đầu, rồi toàn thân nếu dựng được.
    std::uint8_t view_count = 0;
    std::vector<render::Instance> instances;
    std::vector<map::Gate> gates;
    std::vector<double> frame_ms;
    // Luồng vẽ; join trong settle.
    std::jthread spinner;
    control::StickMove stick;
    PhaseSums phase_ms;
    std::filesystem::path data_root;
    resource::TextureTier texture_tier = resource::TextureTier::kBc;
    std::filesystem::path save_root;
    std::filesystem::path shot_path;
    std::string reported_description;
    std::deque<KeptMesh> kept;
    std::deque<KeptGround> grounds;
    // deque: thêm đám mới không kéo đám cũ, span ma trận của lệnh vẽ không đứt.
    std::deque<Crowd> crowds;
    ui::PaceOverlay pace_board;
    std::optional<core::FixedStep> frame_clock;
    std::optional<core::FixedStep> sim_clock;
    std::uint32_t render_hz = 120;
    // Display::set_refresh: tần số quét của màn, Hz; 0 là chưa biết. Luồng cửa sổ ghi, luồng vẽ đọc.
    std::atomic<double> refresh_hz{0.0};
    // Display::turns: số lượt của vòng vẽ. Luồng vẽ ghi, luồng cửa sổ đọc.
    std::atomic<std::uint64_t> turn_count{0};
    // Số thứ tự khung trên GPU. Lần nộp thứ n của khung báo frame_line lên n. Bộ đệm mỗi khung (khối
    // camera, ma trận vật thể, bảng xương, đỉnh giao diện, quad hạt) là bộ nhớ Upload ánh xạ thẳng,
    // đánh số theo ảnh swapchain (slot_serials: khung gần nhất đã dùng ảnh đó) hay theo vòng
    // image_count (ảnh đầu 3D). Acquire trả ảnh không có nghĩa GPU đã vẽ xong khung trước dùng ảnh ấy,
    // nên wait_slot chờ mốc đó trước khi ghi. gpu_waits đếm số khung đã phải chờ thật.
    std::unique_ptr<gpu::Timeline> frame_line;
    std::uint64_t frame_serial = 0;
    std::vector<std::uint64_t> slot_serials;
    std::uint64_t gpu_waits = 0;
    double gpu_wait_ms = 0.0;
    double gpu_wait_peak = 0.0;
    std::uint64_t gpu_long_waits = 0;
    std::uint64_t gpu_same_image_waits = 0;
    // Mốc thời gian của khung đang vẽ: lúc luồng vẽ thức sau khi khung trước nữa đã lên màn (await_shown),
    // hay lúc render bắt đầu khi bề mặt không báo được. Mô phỏng, hoạt ảnh, HUD và bảng đo cùng đọc mốc
    // này, nên hai khung liền nhau cách nhau đúng khoảng giữa hai lần ảnh lên màn. shown_wait_ms là phần
    // chờ màn của khung, cộng vào chặng "Xin ảnh"; shown_waits và shown_failures đếm số lần chờ.
    core::Clock::time_point frame_time{};
    double shown_wait_ms = 0.0;
    std::uint64_t shown_waits = 0;
    std::uint64_t shown_failures = 0;
    // Số khung đã nộp mà GPU chưa xong lúc await_shown trả về, cho dòng "Khung chậm".
    std::uint64_t shown_gpu_behind = 0;
    // DisplayDesc::is_auto_walk, và quãng chân đi được mỗi khung trong lúc tự chạy (cm), cho dòng
    // tổng kết lúc thoát. Có trần kMaxWalkSamples mẫu.
    bool is_auto_walk = false;
    // DisplayDesc::auto_strike_from, và số khung màn chơi đã chạy để đếm nhịp.
    std::uint32_t auto_strike_from = 0;
    std::uint32_t play_frames = 0;
    // DisplayDesc::weapon_item: vật phẩm khe 0 mà công cụ thử gieo vào hero.equipment như gói trang bị của
    // máy chủ; ngoại hình đọc từ hero.equipment, không đọc biến này.
    std::optional<std::uint32_t> weapon_item;
    // DisplayDesc::weapon_gem: đá quý của vũ khí mà công cụ thử gieo vào hero.equipment.
    std::optional<std::uint32_t> weapon_gem;
    // DisplayDesc::skill_id: skill học thêm mà công cụ thử gieo vào hero.skills.
    std::optional<std::uint32_t> skill_id;
    std::vector<float> walk_steps;
    std::optional<ogre::Vec3> walk_last_foot;
    float prev_x = 0.0F;
    float prev_z = 0.0F;
    float shown_x = 0.0F;
    float shown_z = 0.0F;
    bool has_shown = false;
    std::unordered_map<std::string, std::size_t> kept_by_name;
    std::mutex steer_guard;
    std::mutex pending_guard;
    std::mutex outcome_guard;
    std::optional<ui::BitmapFont> pace_font;
    // Nhân vật HUD. Có người vừa chọn thì là người đó; vào thẳng cảnh thì nhân vật mới mặc định.
    hero::Hero hero = hero::newcomer();
    look::Look role_look{};
    look::Race role_race = look::Race::kFemale;
    bool has_role_look = false;
    mutable std::mutex kept_guard;
    KeptRole played_role;
    bool roles_loaded = false;
    // Thủ tục đang chạy: HUD hiện bảng nhập tài khoản hay giao diện của màn chơi.
    Procedure procedure = Procedure::kPlay;
    // DisplayDesc::is_bare: paint_hud không ghi lệnh vẽ nào.
    bool is_bare = false;
    // Mặt đất đang đi: độ cao tam giác đã vẽ, tia chạm đất, va chạm của mắt camera.
    std::optional<control::Ground> terrain;
    core::Status outcome{core::ok()};
    std::optional<Arrival> arrival;
    // Một cảnh của màn chơi đã nạp xong. Từ đó mỗi lần đổi cảnh là rời thế giới (PLAYER_LEAVE_WORLD, do
    // GCNotifyChangeScene của máy chủ phát, Game.exe 0x1405493da); lần vào đầu từ đăng nhập thì không.
    bool has_entered_world = false;
    float fx_stamp = -1.0F;
    std::uint32_t head_turns = 0;
    std::uint32_t scene_draws = 0;
    std::uint32_t pace_texture = 0;
    std::atomic<std::uint32_t> reported_draws{0};
    // Mốc đi bộ, hướng mặt, cảnh của mặt đất và cảnh camera đã vào, zoom đã lưu khi rời cảnh
    // (biến Camera_Zoom của bản gốc), phần lẻ nấc lăn, độ dời con trỏ của khung.
    float walk_stamp = -1.0F;
    float facing = 0.0F;
    int terrain_scene = -1;
    std::optional<int> camera_scene;
    float saved_zoom = 1.0F;
    float wheel_carry = 0.0F;
    int drag_x = 0;
    int drag_y = 0;
    control::ScreenPoint pointer;
    render::ViewSize view_size{};
    std::optional<WalkOrder> order;
    // Lưới đi của cảnh đang đứng (rỗng khi cảnh không có tệp .path) và bộ nhớ làm việc của phép tìm
    // đường, giữ qua các lần nhấp chuột.
    const nav::Field* walk_field = nullptr;
    nav::Scratch scratch;
    std::optional<control::Tilt> tilt;
    WalkPose walk;
    PaceLast pace_last;
    Steering steering;
    ui::PaceNumbers pace_shown;
    // Thông số nhìn của khung trước, để cần gạt biết mắt.
    control::Lens lens;
    std::array<float, 90> pace_ring{};
    // Giá trị >= control::kCursorKinds là ẩn. Luồng vẽ ghi, luồng cửa sổ đọc.
    std::atomic<std::uint8_t> cursor_bits{static_cast<std::uint8_t>(control::CursorKind::kNormal)};
    bool is_player_running = false;
    // Cú nhảy của người chơi (đơn vị game), đồng hồ mô phỏng (ms, cộng theo bước cố định) làm
    // mốc cho CObject_Phy::Tick, và số lăn thay cho rand() của gốc.
    motion::Jump jump;
    // Cú nhảy bắt đầu và lần chạm đất từ các bước mô phỏng chưa đưa cho người chơi; compose_frame lấy.
    std::optional<avatar::Stance> jump_begun;
    bool jump_landed = false;
    // Đòn vừa chọn mà compose_frame chưa đưa cho người chơi, và bước liên hoàn kế của từng skill.
    std::optional<StrikeCall> strike_begun;
    // Số lăn thay cho rand() của Start_MagicSend khi chọn bước của skill kiểu ngẫu nhiên.
    std::linear_congruential_engine<std::uint32_t, 48271U, 0U, 2147483647U> strike_dice{std::random_device{}()};
    // Tên âm thanh của khối con kịch bản vừa tới mốc mà luồng cửa sổ chưa lấy, có khoá steer_guard.
    std::vector<std::string> sounds_due;
    std::uint32_t sim_ms = 0;
    // minstd_rand với kiểu kết quả đúng 32 bit trên mọi nền (như avatar::Gait), để không phải ép kiểu số lăn.
    std::linear_congruential_engine<std::uint32_t, 48271U, 0U, 2147483647U> jump_dice{std::random_device{}()};
    bool has_lens = false;
    // Ba nút chuột đang giữ theo sự kiện đã nhận, theo thứ tự của control::MouseButton, và nút
    // nào đã đổi trạng thái trong khung này.
    std::array<bool, 4> is_button_down{};
    std::array<bool, 4> has_button_changed{};
    bool is_wheel_up = false;
    bool is_wheel_down = false;
    // Nấc lăn chưa đưa cho giao diện (dương là lăn lên): cộng ở turn_wheel, prepare_hud lấy rồi
    // xoá. Tách khỏi hai cờ trên vì chúng hết ở close_mouse_frame, trước lúc giao diện chạy.
    std::int32_t hud_wheel = 0;
    // Cú nhấn trái bắt đầu trên HUD thì thuộc về giao diện tới khi nhả.
    bool is_hud_press = false;
    bool stale_flag = false;
    // Acquire hết hạn: bỏ khung này, không dựng lại swapchain. Vòng vẽ kiểm dừng rồi thử lại.
    bool wait_flag = false;
    // Ảnh chụp (--shot): chụp đúng một lần ở khung đầu vẽ được.
    bool shot_taken = false;
    // Mốc khung đầu trình đã in (core/timeline.hpp).
    bool has_marked_first = false;
    // Đã thử đọc bảng cổng. Không thử lại mỗi khung khi tệp thiếu hoặc hỏng.
    bool gates_ready = false;
    std::atomic<bool> is_resize_pending{false};
    // Luồng vẽ còn quay: sai nghĩa là lỗi vẽ hoặc thiết bị mất.
    std::atomic<bool> is_spinning{false};
    bool is_wrapped = false;
};
} // namespace game::client
