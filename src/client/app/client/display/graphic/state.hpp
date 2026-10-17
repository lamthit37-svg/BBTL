/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/state.hpp
 *  PHÂN HỆ   : Display / Graphic / State
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trạng thái của luồng vẽ. Nằm ở header nội bộ để mỗi domain một tệp dịch.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once
#include "client/display/auto_login.hpp"
#include "client/display/frame_fit.hpp"
#include "client/display/graphic/prelude.hpp"
#include "core/governor.hpp"
#include "core/stages.hpp"
#include "motion/jump.hpp"
#include "render/gpu_clock.hpp"
#include "ui/panel/skill_bar.hpp"

#include <array>
#include <random>
#include <string>
#include <string_view>
namespace game::client {

// Ô bấm đổi thú, điểm ảnh của frame_rect, gốc trái trên.
struct RideBox {
    float left = 0.0F;
    float top = 0.0F;
    float right = 0.0F;
    float bottom = 0.0F;
};

// Chặng CPU của draw_world, đúng thứ tự các lần cpu_stages.next() ở frame.cpp. Tên là vùng ATrace.
inline constexpr std::array<const char*, 7> kCpuStages{
    "chuẩn bị", "gom", "trời", "cảnh", "hiệu ứng", "lớp trời", "giao diện"};
// Chặng GPU: mốc đầu trước lượt vẽ màn hình, mốc giữa sau từng phần của draw_world, mốc cuối sau
// ảnh chân dung (lượt vẽ riêng).
inline constexpr std::array<const char*, 6> kGpuStages{
    "trời", "cảnh", "hiệu ứng", "lớp trời", "giao diện", "chân dung"};

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
    // Chạy người. Đang cưỡi thì nhân (100 + speed_percent) / 100.
    [[nodiscard]] float travel_speed() const noexcept;
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
    // Chỗ đứng khi vào scene_id: chỗ máy chủ đặt cho đúng cảnh ấy, không thì điểm đến của cổng.
    [[nodiscard]] map::GateStand stand_for(int scene_id, const std::optional<EntryPoint>& entry);
    // Chỗ vào game máy chủ đã gửi: take lấy ra khỏi hàng (place_at), peek chỉ xem.
    [[nodiscard]] std::optional<EntryPoint> take_entry();
    [[nodiscard]] std::optional<EntryPoint> peek_entry();
    // Áp tin thế giới tới từ phiên mạng: kéo về thì đặt lại chỗ đứng, còn lại cập nhật các thực thể.
    void apply_world();
    // Đặt nhân vật vào chỗ (đơn vị game) máy chủ nói: bỏ lệnh đi đang chạy.
    void pull_to(core::GroundPoint spot);
    // Ghi chỗ đứng cho luồng cửa sổ báo máy chủ (hoặc xoá khi không có gì để báo).
    void publish_spot(bool is_live);
    [[nodiscard]] render::Camera frame_camera(FrameAsk ask);
    // Ghi khung nhìn của khung đang vẽ.
    void note_view(const render::Camera& camera);
    // Chép mắt và hướng camera sang tai nghe cho luồng cửa sổ. Gọi khi has_lens vừa đúng.
    void publish_ear();
    [[nodiscard]] render::Camera idle_view(FrameAsk ask);
    [[nodiscard]] bool shows_world_role() const;
    [[nodiscard]] bool shows_role_scene() const;
    [[nodiscard]] render::Camera role_scene_camera(render::ViewSize size) const;
    void append_login_role();
    void close_mouse_frame() noexcept;
    void prepare_hud();
    void seed_ui_events(std::span<const std::string> texts);
    void post_request(ui::Action action);
    void pump_online();
    void arm_auto_login(const DisplayDesc& desc);
    void start_auto_login();
    void drive_auto_login(const ui::panel::OnlineReply& reply);
    void queue_online(ui::panel::OnlineAsk ask);
    void run_to_scene_point(ui::RunTo target);
    void open_login();
    void store_roles() const;
    void apply_role();
    // Cấp, kinh nghiệm và tiền máy chủ báo cho chính nhân vật (SelfStats): ghi vào hero, trần kinh nghiệm tra theo cấp.
    void apply_stats(const ui::panel::talk::Stats& stats);
    // Kinh nghiệm cần để lên từ cấp level (Config/PlayerExpLevel.txt, đọc một lần); nullopt khi bảng hỏng hay thiếu cấp.
    [[nodiscard]] std::optional<std::int64_t> exp_need_at(std::int32_t level);
    // Gieo vật phẩm của công cụ thử (weapon_item) vào hero.equipment; gọi lại mỗi lần hero dựng mới.
    void seed_equipment();
    // Phím ô thao tác thành lệnh dùng skill (CAI_MySelf::UseSkill): chọn bước liên hoàn kế của skill ở ô đó.
    void begin_strike(std::optional<std::uint32_t> slot);
    // Khối con kịch bản đòn vừa tới mốc: hiệu ứng thành hệ hạt trong FxView, âm thanh vào sounds_due cho luồng cửa sổ.
    void dispatch_cues();
    // Cùng pipe hạt, ribbon, tiếng của nhân vật mình. owner 0 là mình.
    void dispatch_actor_cues(PlayerActor& actor, std::uint32_t owner);
    // Hiệu ứng đồ của người chơi (PlayerActor::gear_effects): dựng khi có, dừng khi hết, dời theo điểm 武器特效点 mỗi khung.
    void sync_gear();
    // Hạt luôn bật của thú (PlayerActor::ride_fx): dựng theo thẻ Effect, dừng khi đổi thú.
    void sync_ride();
    // Hiệu ứng bám của đòn (SkillCue::token): dời theo điểm gắn mỗi khung tới khi hiệu ứng hết.
    void sync_follows();
    void apply_kept(const KeptRole& restored);
    void start_play();
    [[nodiscard]] ui::HudView hud_view() const;
    // Phần của policy mà việc nướng mesh cần (texture, LOD, atlas cọ).
    [[nodiscard]] BakeRules bake_rules() const noexcept {
        return {.texture_edge = policy.texture_edge, .builds_lods = policy.builds_lods, .atlas_edge = atlas_edge};
    }
    // Vùng giao diện của khung: khung tham chiếu (placed_frame) khi đang ở màn đăng nhập và frames_login, còn lại trọn
    // màn. Giao diện và toạ độ chuột tính theo vùng này; cảnh 3D luôn vẽ trọn màn (screen_size).
    [[nodiscard]] FrameRect frame_rect() const noexcept;
    // Điểm chuột của sự kiện (chuẩn hoá theo cả màn) đổi sang chuẩn hoá theo frame_rect.
    [[nodiscard]] control::ScreenPoint framed_point(const control::InputEvent& event) const noexcept;
    [[nodiscard]] std::optional<ui::SceneLoad> scene_load() const;
    [[nodiscard]] bool is_on_hud(control::ScreenPoint point) const;
    [[nodiscard]] bool hits_ride(float x, float y, const RideBox& box) const noexcept;
    void note_ride_press();
    void paint_ride_switch();
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
    // Điện thoại: trần khung theo năng lực đo được (core::RateGovernor). Gọi mỗi khung sau khi có khoảng cách khung.
    void govern_rate(double interval_ms);
    void adapt_detail(double interval_ms);
    void hold_governed_rate();
    // Ngân sách một khung của bảng đo, ms; 0 khi chưa biết gì.
    [[nodiscard]] float frame_budget_ms() const noexcept;
    // --walk: thay phím đi của khung bằng "giữ W" và xoay hướng nhìn theo thời gian khung.
    [[nodiscard]] Steering auto_walk(const Steering& keys, float seconds);
    // --auto-strike: ô cuối. Có --skill thì đứng yên tới khi bấm được, rồi giữ đứng cho clip khỏi bị chạy xoá.
    void note_auto_strike(Steering& keys);
    // --walk: ghi quãng chân đi được ở khung này (sau simulate_motion) và in tổng kết lúc thoát.
    void note_walk_step();
    void report_walk() const;
    // Đặt viewport của lượt vẽ vào frame_rect cho giao diện: cảnh vừa vẽ trọn màn, giao diện vẽ theo điểm ảnh của khung.
    void bound_hud(gpu::CommandList& list) const;
    [[nodiscard]] core::Status paint_hud(gpu::CommandList& list, std::uint32_t slot) const;
    struct FxAsk {
        gpu::CommandList* list = nullptr;
        const render::Camera* camera = nullptr;
        std::uint32_t slot = 0;
        float elapsed = 0.0F;
    };
    void advance_fx(float elapsed);
    [[nodiscard]] std::size_t fx_mesh_slot(const fx::Field& field);
    void push_fx_field(const fx::Field& field, std::size_t slot, const fx::CameraAxes& axes);
    void append_fx_meshes(const render::Camera& camera);
    void paint_select_ring(std::vector<fx::BillboardBatch>& out) const;
    void draw_fx(const FxAsk& ask) const;
    // Camera, mọi instance, hiệu ứng rồi HUD của một khung, vào ảnh slot.
    [[nodiscard]] core::Status draw_world(gpu::CommandList& list, std::uint32_t slot);
    // Sang chặng kế của cpu_stages; marks_gpu thì ghi cả mốc GPU (chỉ sau một phần đã ghi lệnh vẽ).
    void lap(gpu::CommandList& list, bool marks_gpu);
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
    // Bầu trời EnScene: mở sau tầng 2 như open_fx, mô phỏng mỗi khung, vòm vẽ trước thế giới còn mây,
    // trăng và mặt trời vẽ sau hiệu ứng (nhóm hàng đợi 59 của Render.dll).
    void open_sky();
    // Nhận bầu trời của stage hiện tại và buộc dựng lại ánh sáng theo EnvKey của nó ở khung kế.
    void adopt_sky();
    void advance_sky(float elapsed);
    // Cảnh có EnvKey: dựng lại ánh sáng mỗi khi môi trường tính lại theo giờ của ngày.
    void refresh_sky_light();
    // Effect của bầu trời bám camera: đặt vị trí mắt mỗi khung, hướng đơn vị (nút en_effect của Render.dll).
    void follow_sky_effects(const render::Camera& camera);
    void ensure_sky();
    void append_sky(const render::Camera& camera);
    void ensure_water();
    void append_water();
    // Quạ và các object Model có xương: nạp một lần khi cảnh đổi, dựng tư thế mỗi khung.
    void ensure_scene_models();
    void add_scene_model(const Ambient& item);
    void append_scene_models();
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
    // Chờ GPU chạy xong khung trước còn dùng ô bộ đệm của khung đang ghi; xem frame_line.
    [[nodiscard]] core::Status wait_slot();
    void load_props();
    [[nodiscard]] std::vector<std::size_t> load_listed(const PropTable& table);
    void load_stage();
    void load_player();
    // with_head false: đổi thú, không dựng lại chân dung.
    [[nodiscard]] bool spawn_player(bool with_head);
    void apply_ride_step();
    void clear_ride_jump();
    void say_ride_switch() const;
    [[nodiscard]] bool ensure_ride_catalog();
    [[nodiscard]] std::string ride_caption() const;
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
    // materials rỗng đi đường load_mesh. Khác rỗng thì chồng tên submesh và nhớ riêng.
    [[nodiscard]] std::size_t load_ride_mesh(const std::string& mesh, std::string_view materials);
    [[nodiscard]] const render::Drawable* ride_drawable(const std::string& mesh,
        std::string_view materials);
    // Quái và NPC (graphic/creature.cpp): bảng đọc ở luồng riêng từ lúc thấy thực thể đầu tiên, hình dùng chung theo
    // template, rồi từng thực thể dựng tư thế mỗi khung. budget là số hình mới còn được nạp ở khung này.
    void append_creatures();
    void seed_creature_demo(int scene_id);
    void seed_peer_demo(int scene_id);
    void seed_pet_demo(int scene_id);
    void show_creature(const cast::Actor& actor, std::size_t& budget);
    void show_player(const cast::Actor& actor, std::size_t& budget);
    [[nodiscard]] math::Point3 stand_of(const cast::Actor& actor) const;
    // Chân thực thể trong toạ độ thế giới (stand_of ở dạng ogre::Vec3, cho phép thử tia). Cần ground và terrain đã có.
    [[nodiscard]] ogre::Vec3 world_foot(const cast::Actor& actor) const;
    // Chiến đấu (graphic/fight.cpp). hear_fight nhận tin của phiên mạng về chiêu thức (true khi tin thuộc nhóm đó, HUD không
    // cần thấy); note_fight nhận tin thế giới về chiêu và đòn trúng (apply_world gọi sau khi Cast đã áp tin).
    [[nodiscard]] bool hear_fight(const ui::panel::talk::Hear& note);
    void note_fight(const cast::Note& note);
    // Chiêu của người chơi khác: cùng accept_strike và pipe hiệu ứng, không cần seq của mình.
    void play_peer_cast(const cast::Casting& casting);
    void apply_vitals(const ui::panel::talk::Vitals& vitals);
    void apply_skills(const ui::panel::talk::Skills& skills);
    // Hồi chiêu còn lại của mười ô thanh, cùng chỉ số với hero.skills. Chỉ luồng vẽ, trước mỗi hud_view.
    void fill_bar_cooldown();
    void note_bar_left(std::size_t slot);
    // Đưa sinh lực và danh sách kỹ năng máy chủ đã báo vào hero: lúc tin tới, và sau apply_role vì hero dựng mới đè mất chúng.
    void show_fight();
    // Phím ô thao tác lúc chơi nối máy chủ: ra chiêu ở ô đó lên mục tiêu đang chọn; đã chết thì ô 1 và 2 là hồi sinh.
    void press_slot(std::uint32_t slot);
    void send_say(const ui::panel::talk::Say& say);
    // Phát động tác của chiêu mà máy chủ vừa xác nhận cho chính mình: quay mặt về mục tiêu rồi chọn bước (cùng đường với
    // phím ô thao tác khi chơi tại chỗ). Trả độ trễ tới lúc đòn trúng trong động tác (0 khi không có clip).
    [[nodiscard]] std::chrono::milliseconds play_confirmed(const cast::Casting& casting);
    // Đánh tự động của khung: đi tới mục tiêu hay ra chiêu; bỏ khi người chơi tự đi.
    void pursue_target(core::Clock::time_point now, const Steering& keys);
    // Chuột trên quái hay vật rơi: hover cho con trỏ, nhấn trái lên quái thì đuổi và đánh, lên vật rơi thì đi tới nhặt.
    void pick_foe(bool is_over_hud);
    // Quái còn sống hay vật rơi nhặt được dưới điểm màn hình, cùng cách thử tia với talkable_at.
    [[nodiscard]] const cast::Actor* foe_at(control::ScreenPoint point) const;
    [[nodiscard]] const cast::Actor* pick_actor(control::ScreenPoint point, bool (*wanted)(const cast::Actor&)) const;
    // --talk-demo fight hay fall (graphic/fight_demo.cpp): máy chủ giả cho chiến đấu. start_fight_demo vào chế độ chơi nối máy chủ với
    // sinh lực, kỹ năng giả và tự đánh quái first; answer_fight_demo đáp chiêu bằng tin thế giới đúng hình protocol v6.
    void start_fight_demo(std::uint32_t first);
    [[nodiscard]] bool is_fight_demo() const noexcept { return talk_demo == "fight" || talk_demo == "fall"; }
    void answer_fight_demo(const ui::panel::talk::Say& said);
    void fall_in_demo(std::vector<cast::Note>& notes, std::uint32_t killer);
    // Chữ bay (số sát thương, hồi, trượt) và lời nhắc hồi sinh của khung, nối vào cuối bảng đo (pace_board). Gọi sau
    // frame_camera: cần lens của khung.
    void build_extras();
    // Đầu thực thể (hay chính nhân vật) trong toạ độ thế giới để đặt chữ bay; rỗng khi thực thể không còn trong cảnh.
    [[nodiscard]] std::optional<ogre::Vec3> head_of(std::uint32_t id) const;
    // Pump hội thoại NPC (graphic/talk.cpp): tin của phiên mạng vào giao diện trước khung, việc giao diện nhờ ra hàng chờ sau khung.
    void pump_talk();
    void drain_says();
    // --talk-demo: đáp một việc người chơi nhờ bằng kịch bản có sẵn (graphic/talk_demo.cpp), tin đáp vào talk_heard.
    void answer_demo(const ui::panel::talk::Say& said);
    // Mở sẵn hộp của kịch bản (talk_demo khác "click") trên NPC đầu tiên vừa dựng.
    void open_demo(std::uint32_t npc);
    // NPC bấm được dưới điểm màn hình (tia vào hộp quanh chân thực thể); nullptr khi không có.
    [[nodiscard]] const cast::Actor* talkable_at(control::ScreenPoint point) const;
    // Chuột trên NPC: ghi hover cho con trỏ, và nhấn trái lên NPC thì đi tới nó để nói chuyện (hoặc nói ngay khi đã đủ gần).
    void pick_npc(bool is_over_hud);
    void walk_to_talk(const Steering& keys, core::Clock::time_point now);
    [[nodiscard]] const look::CreatureTables* ready_creature_tables();
    [[nodiscard]] std::shared_ptr<const CreatureAsset> build_creature_asset(std::uint32_t template_id);
    [[nodiscard]] std::shared_ptr<const CreatureAsset> creature_asset(std::uint32_t template_id, std::size_t& budget);
    [[nodiscard]] const render::Drawable* load_creature_mesh(const std::string& mesh, const look::CreatureMaterial* skin);
    // Lưới tô bằng material chồng của quái; khoá nhớ là tên lưới và tên material.
    [[nodiscard]] std::size_t load_skinned_mesh(const std::string& mesh, const look::CreatureMaterial& skin);
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
    // Đã tới lúc chụp: có đường dẫn, chưa chụp, cảnh nạp xong và đủ điều kiện của chế độ chạy.
    [[nodiscard]] bool is_shot_due() const;
    // Khung này chụp thì tạo buffer đọc ngược; rỗng khi không chụp hoặc hỏng. Gọi trước
    // Screen::end để ảnh đi thẳng từ bố cục vẽ sang CopySource.
    [[nodiscard]] std::optional<ShotPlan> plan_shot();
    // Ghi lệnh chép ảnh khung ra buffer của plan rồi rào ảnh về Present.
    void copy_shot(gpu::CommandList& list, const ShotPlan& plan, std::uint32_t slot) const;
    // Chờ GPU chép xong, đọc buffer, nén PNG và ghi tệp; lỗi được in ra.
    void finish_shot(const ShotPlan& plan) const;
    // Lưu các số báo cáo cho luồng thông điệp đọc không khoá.
    void publish() noexcept;
    // In một dòng tổng kết khoảng thời gian khung; gọi một lần lúc dừng.
    void report_frames() const;
    // Thời gian theo chặng của draw_world trên CPU và trên GPU; gọi sau khi GPU rỗi.
    void report_stages() const;
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
    // Thời gian GPU theo kGpuStages; rỗng khi thiết bị không ghi dấu thời gian (GLES). Sau device.
    std::optional<render::GpuClock> gpu_clock;
    std::unique_ptr<FxView> fx_view;
    std::unique_ptr<SkyView> sky_view;
    // Hiệu ứng đồ đang chạy trong fx_view: mẫu con, tên effect và màu đã dựng (đổi một trong ba thì dựng lại), handle
    // (0 là fx không dựng được, không thử lại).
    struct GearHandle {
        std::size_t mount = 0;
        std::string name;
        std::uint32_t colour = 0;
        std::uint32_t handle = 0;
    };
    std::vector<GearHandle> gear_handles;
    // Hạt thú đang chạy. handle 0 là không dựng được, không thử lại. Đổi id thú thì thả cái cũ.
    struct RideHandle {
        std::int32_t ride = -1;
        std::uint32_t index = 0;
        std::string name;
        std::uint32_t handle = 0;
    };
    std::vector<RideHandle> ride_handles;
    [[nodiscard]] static bool same_ride(const RideFx& place, const RideHandle& prior);
    [[nodiscard]] const RideHandle* find_ride(const RideFx& place) const;
    [[nodiscard]] bool wants_ride(std::span<const RideFx> wanted, const RideHandle& prior) const;
    [[nodiscard]] bool drop_ride(const RideHandle& prior, std::span<const RideFx> wanted);
    void spawn_ride(const RideFx& place);
    void move_or_spawn_ride(const RideFx& place);
    // Hiệu ứng bám của đòn: dấu của PlayerActor và handle trong fx_view.
    struct FollowHandle {
        // 0 là nhân vật mình. Id thực thể là người chơi khác.
        std::uint32_t owner = 0;
        std::uint32_t token = 0;
        std::uint32_t handle = 0;
    };
    std::vector<FollowHandle> follow_handles;
    // Dải AnimationRibbon đang sống. Cạnh mới nhất ở đầu: tay và đầu ngoài (tay + trục X của xương * width).
    struct SkillRibbon {
        // 0 là nhân vật mình. Id thực thể là người chơi khác.
        std::uint32_t owner = 0;
        std::uint32_t token = 0;
        float age = 0.0F;
        float life = 0.0F;
        float width = 0.0F;
        std::uint32_t point_count = 0;
        float start_red = 1.0F;
        float start_green = 1.0F;
        float start_blue = 1.0F;
        float end_red = 1.0F;
        float end_green = 1.0F;
        float end_blue = 1.0F;
        float start_alpha = 1.0F;
        float end_alpha = 1.0F;
        std::vector<ogre::Vec3> hands;
        std::vector<ogre::Vec3> outers;
    };
    std::vector<SkillRibbon> skill_ribbons;
    core::Clock::time_point ribbon_stamp{};
    [[nodiscard]] std::optional<SkillRibbon> make_ribbon(const SkillCue& cue) const;
    void push_ribbon_edge(SkillRibbon& ribbon, ogre::Vec3 hand, ogre::Quat orientation) const;
    void paint_skill_ribbon(const SkillRibbon& ribbon, fx::BillboardBatch& batch) const;
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
    // Đăng nhập tự động của công cụ thử (auto_login.hpp) và máy chủ nó nối; rỗng khi không bật. Chỉ luồng vẽ chạm vào.
    std::optional<AutoLogin> auto_login;
    ui::panel::ServerName auto_server;
    // Có đăng nhập tự động thì --shot chờ tới khung online_shot_from (đặt khi vào game), để người chơi khác kịp hiện.
    bool shot_waits_online = false;
    std::optional<std::uint64_t> online_shot_from;
    // Số lần máy chủ kéo nhân vật về (pull_to), để đo đi giật khi chơi trực tuyến.
    std::uint32_t pulls = 0;
    // Hội thoại NPC: tin của phiên mạng chờ luồng vẽ và việc người chơi nhờ chờ vòng cửa sổ (talk_guard bảo vệ cả hai).
    // talk_title là tên NPC của hộp đang mở. hovered_npc là NPC bấm được dưới chuột ở khung này; is_npc_press: nhấn trái bắt
    // đầu trên NPC, quái hay vật rơi thì không thành lệnh đi tới khi nhả. talk_goal là NPC hay vật rơi người chơi vừa bấm và đang
    // đi tới (chỉ luồng vẽ chạm).
    // is_pickup: đích là vật rơi (tới nơi thì gửi PickUp) chứ không phải NPC (tới nơi thì gửi Talk).
    struct TalkGoal {
        std::uint32_t npc = 0;
        core::Clock::time_point until;
        bool is_pickup = false;
    };
    std::string talk_demo;
    // Phiên và NPC của hộp mà kịch bản --talk-demo đang đáp; chỉ luồng vẽ chạm.
    std::uint64_t demo_session = 0;
    std::uint32_t demo_npc = 0;
    std::mutex talk_guard;
    std::vector<ui::panel::talk::Hear> talk_heard;
    std::vector<ui::panel::talk::Say> talk_says;
    std::string talk_title;
    std::optional<std::uint32_t> hovered_npc;
    bool is_npc_press = false;
    std::optional<TalkGoal> talk_goal;
    // Chiến đấu của chính người chơi (mục tiêu, hồi chiêu, đánh tự động, số bay); chỉ luồng vẽ chạm.
    fight::Combat combat;
    // Ms còn lại của Button_Action1..10. hud_view mượn span này trong prepare.
    std::array<std::uint32_t, ui::panel::kSkillBarSlots> bar_left_ms{};
    // Tên mục tiêu đã tra. hud_view là const nên chuỗi này mutable, sống tới hết prepare.
    mutable std::string hud_target_name;
    // Sinh lực lần cuối máy chủ báo, để dựng lại hero sau apply_role.
    std::optional<ui::panel::talk::Vitals> vitals_seen;
    // Đã vào game qua máy chủ (chuỗi đăng nhập báo kEntered, tới khi mất phiên): ô thao tác gửi CastSkill thay vì phát đòn tại
    // chỗ, và chọn quái, nhặt đồ có nghĩa. Công cụ thử và chế độ cục bộ giữ đường tại chỗ.
    bool is_online_play = false;
    // Chiêu của mình vừa được xác nhận: số bay của đòn trúng tới trước mốc until hiện sau delay (đòn trúng giữa động tác chứ
    // không phải lúc chiêu bắt đầu).
    struct HitWindow {
        core::Clock::time_point until;
        std::chrono::milliseconds delay{0};
    };
    std::optional<HitWindow> hit_window;
    // Quái hay vật rơi dưới chuột ở khung này (pick_foe), và nơi đánh tự động đã đặt lệnh đi lần cuối để không tìm đường lại
    // mỗi khung.
    std::optional<std::uint32_t> hovered_foe;
    // since là lúc bắt đầu đuổi (không đổi qua các lần tìm đường lại), để bỏ cuộc sau kChasePatience.
    struct ChaseLeg {
        core::GroundPoint point;
        core::Clock::time_point at;
        core::Clock::time_point since;
    };
    std::optional<ChaseLeg> chase_leg;
    // Kịch bản --talk-demo fight: số chiêu đã đáp (quyết định trượt, hội tâm, hồi) và sinh lực còn lại của từng quái.
    std::uint32_t demo_hits = 0;
    std::unordered_map<std::uint32_t, std::int32_t> demo_life;
    // Đã vẽ ít nhất một số bay: --shot của chế độ fight chờ tới đó mới chụp.
    bool has_floated = false;
    // Tên tuyệt chiêu đang hiện trên đầu người chơi. text rỗng là không có.
    struct SkillBanner {
        std::string text;
        core::Clock::time_point from{};
    };
    SkillBanner skill_banner;
    // Tin thế giới của phiên mạng chờ luồng vẽ (world_guard), các thực thể đang thấy (chỉ luồng vẽ), và chỗ đứng cho
    // phiên báo máy chủ (spot_guard: luồng vẽ ghi mỗi khung, luồng cửa sổ đọc).
    std::mutex world_guard;
    std::vector<cast::Note> world_notes;
    cast::Cast people;
    // Quái và NPC đang vẽ: bảng (rỗng tới khi luồng đọc xong), hình theo template (nullptr là template hỏng, đã ghi log), và
    // từng thực thể theo id. seen là số thứ tự khung thấy gần nhất; thực thể không còn trong cast thì bị xoá cuối khung.
    struct CreatureSlot {
        std::uint32_t template_id = 0;
        std::uint64_t seen = 0;
        bool is_broken = false;
        CreatureActor actor;
    };
    CreatureTablesJob creature_job;
    std::shared_ptr<const look::CreatureTables> creature_tables;
    bool creature_tables_failed = false;
    std::unordered_map<std::uint32_t, std::shared_ptr<const CreatureAsset>> creature_assets;
    std::unordered_map<std::uint32_t, CreatureSlot> creatures;
    std::uint64_t creature_epoch = 0;
    // Người chơi khác: một PlayerActor mỗi id. Xác chưa vẽ (phần sau). seen cùng ý với CreatureSlot.
    struct PeerSlot {
        std::uint8_t gender = 0;
        std::uint16_t face = 0;
        std::uint16_t hair = 0;
        std::uint64_t seen = 0;
        bool is_broken = false;
        std::optional<PlayerActor> actor;
        // Clip đã nạp. Bắt đầu bằng bộ nhân vật mới; chiêu lạ của máy chủ được thêm khi họ đánh.
        std::vector<std::uint32_t> skills{0, 1, 21, 22, 34, 35};
        std::optional<std::uint32_t> pending_skill;
    };
    std::unordered_map<std::uint32_t, PeerSlot> peers;
    std::uint64_t peer_epoch = 0;
    // Bảng ngoại hình người mình vừa đọc, để người khác không đọc lại đĩa.
    std::shared_ptr<const PlayerTables> player_tables;
    mutable std::mutex spot_guard;
    std::optional<core::GroundPoint> spot_report;
    // Chỗ vào game cho lần place_at kế; spawn_guard bảo vệ (luồng cửa sổ ghi, luồng vẽ đọc).
    std::mutex spawn_guard;
    std::optional<EntryPoint> entry_spot;
    // Vòng cửa sổ đã gọi play: luồng vẽ rời thủ tục đăng nhập ở lượt kế.
    std::atomic<bool> wants_play{false};
    std::array<ui::ViewPaint, 2> head_views{};
    // Số ảnh 3D đã gắn vào giao diện: đầu, rồi toàn thân nếu dựng được.
    std::uint8_t view_count = 0;
    std::vector<render::Instance> instances;
    // Khung nhìn của khung vừa vẽ. note_view ghi.
    render::Frustum view_frustum{};
    math::Vector3 view_eye{0.0F, 0.0F, 0.0F};
    int view_scene = -1;
    std::vector<map::Gate> gates;
    std::vector<double> frame_ms;
    // Luồng vẽ; join trong settle.
    std::jthread spinner;
    control::StickMove stick;
    PhaseSums phase_ms;
    // Thời gian CPU theo kCpuStages của draw_world; chỉ luồng vẽ chạm, in lúc dừng.
    core::StageClock cpu_stages{kCpuStages};
    std::filesystem::path data_root;
    resource::TextureTier texture_tier = resource::TextureTier::kBc;
    std::filesystem::path save_root;
    std::filesystem::path shot_path;
    std::string reported_description;
    std::deque<KeptMesh> kept;
    std::deque<KeptGround> grounds;
    // deque: thêm đám mới không kéo đám cũ, span ma trận của lệnh vẽ không đứt.
    std::deque<Crowd> crowds;
    std::vector<SceneModel> scene_models;
    bool scene_models_built = false;
    ui::PaceOverlay pace_board;
    std::optional<core::FixedStep> frame_clock;
    // Điện thoại: bộ chọn trần khung, dựng lại khi tần số quét hay trần hạng máy đổi. Chỉ luồng vẽ đụng.
    std::optional<core::RateGovernor> governor;
    // Điện thoại: trần tam giác của cảnh theo thời gian khung thực. Chỉ luồng vẽ đụng.
    std::optional<render::DetailGovernor> detail;
    double governed_refresh = 0.0;
    std::uint32_t governed_ceiling = 0;
    // Mốc khung kế tiếp được phép bắt đầu khi trần thấp hơn nhịp quét.
    core::Clock::time_point governed_deadline{};
    std::optional<core::FixedStep> sim_clock;
    std::uint32_t render_hz = 120;
    // Display::set_refresh: tần số quét của màn, Hz; 0 là chưa biết. Luồng cửa sổ ghi, luồng vẽ đọc.
    std::atomic<double> refresh_hz{0.0};
    // Display::turns: số lượt của vòng vẽ. Luồng vẽ ghi, luồng cửa sổ đọc.
    std::atomic<std::uint64_t> turn_count{0};
    // Số thứ tự khung trên GPU. Lần nộp thứ n của khung báo frame_line lên n. Bộ đệm mỗi khung
    // (khối camera, ma trận vật thể, bảng xương, đỉnh giao diện, quad hạt) là bộ nhớ Upload ánh xạ
    // thẳng, xoay vòng kFrameSlots ô theo số khung, không theo ảnh swapchain. Acquire trả ảnh không
    // có nghĩa GPU đã vẽ xong khung trước, nên wait_slot chờ khung cuối dùng ô trước khi ghi.
    // gpu_waits đếm số khung đã phải chờ thật.
    std::unique_ptr<gpu::Timeline> frame_line;
    std::uint64_t frame_serial = 0;
    std::uint64_t gpu_waits = 0;
    double gpu_wait_ms = 0.0;
    double gpu_wait_peak = 0.0;
    std::uint64_t gpu_long_waits = 0;
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
    // Giữ đứng tới mốc này: Gait::update đổi đòn thành chạy ngay khung cơ thể đang đi.
    core::Clock::time_point auto_still_until{};
    // --skill đã được bấm một lần. Trước đó đuổi mục tiêu không kéo người chơi, vì press_slot bỏ lệnh lúc đang chạy.
    bool ultimate_sent = false;
    // DisplayDesc::creatures còn chờ khung màn chơi đầu tiên có chỗ đứng của nhân vật.
    std::vector<std::uint32_t> creature_demo;
    // --pet còn chưa gieo.
    std::vector<std::uint32_t> pet_demo;
    // --peer còn chưa gieo. 0 là không có.
    std::uint32_t peer_demo = 0;
    // DisplayDesc::ui_events đã phân tích, còn chờ khung màn chơi đầu tiên; hud_events là phần HUD nhận ở khung
    // đó (rỗng ở các khung khác).
    std::vector<ui::panel::PostedEvent> posted_events;
    std::vector<ui::panel::PostedEvent> hud_events;
    // DisplayDesc::weapon_item: vật phẩm khe 0 mà công cụ thử gieo vào hero.equipment như gói trang bị của
    // máy chủ; ngoại hình đọc từ hero.equipment, không đọc biến này.
    std::optional<std::uint32_t> weapon_item;
    // DisplayDesc::ride_id: id CharMount của --mount. Ảnh chân dung không dùng.
    std::optional<std::uint32_t> ride_id;
    // Mọi id CharMount >= 0, đúng thứ tự bảng, để nút duyệt từng con. Nạp một lần.
    std::vector<std::int32_t> ride_catalog;
    bool ride_catalog_ready = false;
    RideBox ride_prev{};
    RideBox ride_next{};
    bool ride_buttons_live = false;
    // -1 thú trước, +1 thú sau, 0 là không bấm. apply_ride_step xoá sau một lần.
    int ride_step = 0;
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
    std::optional<hero::ExpTable> exp_table;
    bool has_exp_table_failed = false;
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
    // Bảng đăng nhập nằm trong khung tham chiếu (placed_frame): mọi màn trừ layout điện thoại, vốn dàn cho trọn màn.
    bool frames_login = false;
    // DisplayDesc::ui_density, đã thay giá trị hỏng bằng 1.
    float ui_density = 1.0F;
    // Chính sách đồ hoạ của phiên (DisplayDesc::quality), đặt một lần đầu launch. Đường vẽ đọc nó thay vì hỏi nền tảng.
    GraphicsPolicy policy;
    // Trần cạnh atlas cọ: kAtlasEdge, hạ theo cỡ texture lớn nhất của thiết bị khi open_gpu đã có thiết bị.
    std::uint32_t atlas_edge = kAtlasEdge;
    // Mặt đất đang đi: độ cao tam giác đã vẽ, tia chạm đất, va chạm của mắt camera.
    std::optional<control::Ground> terrain;
    core::Status outcome{core::ok()};
    std::optional<Arrival> arrival;
    // Một cảnh của màn chơi đã nạp xong. Từ đó mỗi lần đổi cảnh là rời thế giới (PLAYER_LEAVE_WORLD, do
    // GCNotifyChangeScene của máy chủ phát, Game.exe 0x1405493da); lần vào đầu từ đăng nhập thì không.
    bool has_entered_world = false;
    float fx_stamp = -1.0F;
    float en_sky_stamp = -1.0F;
    std::uint32_t sky_light_serial = 0;
    std::vector<std::uint32_t> sky_effects;
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
    std::vector<HeardSound> sounds_due;
    std::optional<HeardEar> heard_ear;
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
