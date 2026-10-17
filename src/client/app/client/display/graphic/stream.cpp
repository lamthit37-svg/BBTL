/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/stream.cpp
 *  PHÂN HỆ   : Display / Graphic / Stream
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nạp cảnh theo lát: luồng nền đọc đĩa, luồng vẽ chỉ đưa lên GPU phần đã
 *    xong. Prefetch cảnh chọn nhân vật không đổi cảnh đang vẽ.
 *  - Thấy trước nạp trước: mesh xếp hạng theo khung nhìn (trong khung trước,
 *    gần mắt trước), xếp lại khi camera đổi; thứ tự vẽ cuối vẫn theo bảng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"
namespace game::client {
namespace {

// Hạng nạp: vật thể trong khung nhìn đứng trước mọi vật thể ngoài khung, trong mỗi nhóm thì gần
// mắt trước. Chỉ biết gốc phép đặt (mesh chưa đọc nên chưa có cỡ), nên khung nhìn nới kSeenMargin
// mét để nhà lớn có gốc nằm ngay ngoài mép vẫn tính là thấy.
constexpr float kUnseen = 1.0e6F;
constexpr float kSeenMargin = 10.0F;
constexpr float kNoScore = std::numeric_limits<float>::max();
// Xếp lại theo khung nhìn chừng này một lần khi cảnh đang chảy vào: theo kịp camera quay mà vài
// nghìn phép thử cầu không thành gánh của luồng vẽ.
constexpr std::chrono::milliseconds kRankEvery{250};
// Nhịp chờ luồng đọc khi nạp đồng bộ cảnh đầu (settle_first_scene).
constexpr std::chrono::microseconds kWaitPause{100};

using Order = std::vector<std::size_t>;

// Điểm nhỏ trước. Đi với stable_sort: điểm bằng nhau giữ thứ tự bảng, cùng cảnh cho cùng thứ tự.
struct ScoreFirst {
    std::span<const float> scores;

    [[nodiscard]] bool operator()(std::size_t left, std::size_t right) const {
        return core::at(scores, left) < core::at(scores, right);
    }
};

[[nodiscard]] std::vector<math::Vector3> spots_of(const PropTable& table) {
    std::vector<math::Vector3> spots;
    spots.reserve(table.props.size());
    for (const PlacedProp& prop : table.props) {
        const math::Matrix4 placed = world_of(prop.world);
        spots.push_back(placed.translation());
    }
    return spots;
}

// Số không hữu hạn (phép đặt hỏng) xếp cuối, không làm hỏng phép so của sort.
[[nodiscard]] float spot_score(const LoadFocus& focus, const math::Vector3& spot) noexcept {
    math::Vector3 apart = spot - focus.eye;
    if (focus.is_flat) apart.set_y(0.0F);
    const float distance = math::length(apart);
    if (!std::isfinite(distance)) return kNoScore;
    if (!focus.frustum) return distance;
    if (render::sphere_in_view(*focus.frustum, spot, kSeenMargin)) return distance;
    return kUnseen + distance;
}

// Điểm của một mesh là điểm tốt nhất trong các vật thể dùng nó. Mesh không vật thể nào dùng xếp
// cuối.
[[nodiscard]] std::vector<float> mesh_scores(const Arrival& loading, const LoadFocus& focus) {
    std::vector<float> scores(loading.table.meshes.size(), kNoScore);
    const std::size_t count = loading.table.props.size();
    for (std::size_t prop = 0; prop < count; ++prop) {
        const std::size_t mesh = loading.table.props.at(prop).mesh;
        const float score = spot_score(focus, loading.spots.at(prop));
        scores.at(mesh) = std::min(scores.at(mesh), score);
    }
    return scores;
}

[[nodiscard]] Order slot_order(const Arrival& loading, std::span<const float> scores) {
    const std::size_t count = loading.slot_mesh.size();
    std::vector<float> slot_scores(count, kNoScore);
    Order order(count);
    for (std::size_t slot = 0; slot < count; ++slot) {
        slot_scores.at(slot) = core::at(scores, loading.slot_mesh.at(slot));
        order.at(slot) = slot;
    }
    const ScoreFirst is_first{.scores = slot_scores};
    std::ranges::stable_sort(order, is_first);
    return order;
}

// Chỉ phần chưa đặt của hàng mesh đã có trong nhớ được xếp lại.
void sort_kept(Arrival& loading, std::span<const float> scores) {
    const std::span<std::size_t> waiting = std::span(loading.kept_queue).subspan(loading.kept_next);
    const ScoreFirst is_first{.scores = scores};
    std::ranges::stable_sort(waiting, is_first);
}

// Lần đầu mọi mesh có vật thể trong khung nhìn đã xong: lúc người chơi thấy cảnh đủ.
void mark_seen(Arrival& loading) {
    if (loading.is_seen_marked) return;
    loading.is_seen_marked = true;
    const double millis = millis_between(loading.started, core::Clock::now());
    const auto seen = std::ranges::count(loading.is_seen, true);
    std::println("Khung nhìn đủ {} mesh sau {:.1f} ms nạp", seen, millis);
    core::mark("khung nhìn đủ mesh");
}

void note_seen(Arrival& loading, std::span<const float> scores) {
    std::size_t left = 0;
    for (std::size_t index = 0; index < scores.size(); ++index) {
        const bool is_seen = core::at(scores, index) < kUnseen;
        loading.is_seen.at(index) = is_seen;
        if (is_seen && !loading.is_settled.at(index)) ++left;
    }
    loading.seen_left = left;
    if (left == 0) mark_seen(loading);
}

void count_seen(Arrival& loading, std::size_t index) {
    if (!loading.is_seen.at(index) || loading.seen_left == 0) return;
    --loading.seen_left;
    if (loading.seen_left == 0) mark_seen(loading);
}

[[nodiscard]] std::size_t next_kept(Arrival& loading) {
    const std::size_t index = loading.kept_queue.at(loading.kept_next);
    ++loading.kept_next;
    return index;
}

} // namespace

// Một lượt của luồng vẽ, kể cả lúc cửa sổ bị che; false khi dừng vì lỗi vẽ.
void Display::State::adopt() {
    if (wants_play.exchange(false, std::memory_order_relaxed)) start_play();
    std::shared_ptr<const world::ShownScene> next;
    {
        const std::scoped_lock<std::mutex> locked(pending_guard);
        next = pending;
    }
    if (procedure == Procedure::kLogin && role_scene && shows_role_scene()) next = role_scene;
    if (!next) {
        clear_if_shown();
        return;
    }
    if (arrival.has_value() && arrival->scene == next) {
        if (arrival->prefetch) promote_prefetch(*arrival);
        return;
    }
    // Cảnh đang hiện vẫn là bảng tài khoản: để lần nạp trước của cảnh chọn chạy hết.
    if (arrival.has_value() && arrival->prefetch && next == held) return;
    if (!arrival.has_value() && next == held) return;
    begin_load(std::move(next));
}

void Display::State::clear_if_shown() {
    if (held || arrival.has_value()) clear_shown();
}

void Display::State::clear_shown() {
    held.reset();
    stage = nullptr;
    ground = nullptr;
    instances.clear();
    instance_mesh.clear();
    crowds.clear();
    scene_models.clear();
    scene_models_built = false;
    world = {};
    arrival.reset();
    if (feeder) feeder->cancel();
}

void Display::State::warm_scene() {
    if (catalog == nullptr) return;
    const core::Status tier = catalog->prepare(render::Tier::kScene);
    if (!tier) std::println(stderr, "Pipeline: tầng cảnh: {}", tier.error());
    open_fx();
    open_sky();
}

void Display::State::promote_prefetch(Arrival& loading) {
    loading.prefetch = false;
    if (!loading.ground_done) return;
    reveal(loading);
    const std::size_t count = loading.is_settled.size();
    for (std::size_t index = 0; index < count; ++index) {
        if (loading.is_settled.at(index)) publish_mesh(loading, index);
    }
}

void Display::State::begin_load(std::shared_ptr<const world::ShownScene> next, bool prefetch) {
    // Tầng 2: hiệu ứng và pipeline theo cảnh, prefetch trước khi cảnh xuất hiện.
    if (!prefetch) warm_scene();
    post_load(std::move(next), prefetch);
}

void Display::State::post_load(std::shared_ptr<const world::ShownScene> next, bool prefetch) {
    if (!next) {
        clear_shown();
        return;
    }
    Arrival loading;
    loading.scene = std::move(next);
    loading.prefetch = prefetch;
    loading.started = core::Clock::now();
    if (!data_root.empty()) loading.table = table_of(loading.scene->stage);
    const std::size_t count = loading.table.meshes.size();
    loading.loaded.assign(count, kMissing);
    loading.is_settled.assign(count, false);
    loading.is_seen.assign(count, false);
    loading.spots = spots_of(loading.table);
    index_users(loading);
    FeedJob job;
    job.root = data_root;
    job.tier = texture_tier;
    job.bake = bake_rules();
    job.pending_limit = policy.pending_bytes;
    job.scene = loading.scene;
    job.bake_ground = needs_fresh_ground(loading);
    remember_meshes(loading, job);
    rank_first(loading, job);
    const std::size_t fresh = job.needs.size();
    loading.epoch = feeder->post(std::move(job));
    if (!loading.table.meshes.empty()) {
        const std::string_view verb = prefetch ? "Nạp trước" : "Đang nạp";
        std::println("{} {} mesh cho resid {}, {} đọc đĩa", verb, count, loading.scene->id, fresh);
    }
    arrival = std::move(loading);
}

void Display::State::remember_mesh(Arrival& loading, FeedJob& job, std::size_t index) {
    const std::string& mesh = loading.table.meshes.at(index);
    const auto found = kept_by_name.find(mesh);
    if (found != kept_by_name.end()) {
        loading.loaded.at(index) = found->second;
        loading.kept_queue.push_back(index);
        return;
    }
    Need need;
    need.name = mesh;
    loading.feed_slot.at(index) = job.needs.size();
    loading.slot_mesh.push_back(index);
    job.needs.push_back(std::move(need));
}

void Display::State::remember_meshes(Arrival& loading, FeedJob& job) {
    const std::size_t count = loading.table.meshes.size();
    loading.feed_slot.assign(count, kMissing);
    for (std::size_t index = 0; index < count; ++index) {
        remember_mesh(loading, job, index);
    }
}

// Thứ tự đọc lúc giao việc: theo chỗ đứng khi vào cảnh, vì khung nhìn của cảnh mới chỉ có sau khi
// mặt đất xong. Không đoán được chỗ đứng thì giữ thứ tự bảng tới lần xếp theo khung nhìn đầu.
void Display::State::rank_first(Arrival& loading, FeedJob& job) {
    const std::optional<LoadFocus> focus = first_focus(*loading.scene);
    if (!focus) return;
    const std::vector<float> scores = mesh_scores(loading, *focus);
    job.order = slot_order(loading, scores);
    sort_kept(loading, scores);
}

// Chỗ đứng như place_at sẽ đặt, không lấy chỗ máy chủ gửi ra khỏi hàng.
std::optional<LoadFocus> Display::State::first_focus(const world::ShownScene& scene) {
    if (procedure != Procedure::kPlay || !scene.ground) return std::nullopt;
    LoadFocus focus;
    focus.is_flat = true;
    focus.eye = math::Vector3(walk.x, 0.0F, walk.z);
    if (walk.scene_id == scene.id) return focus;
    const std::optional<EntryPoint> entry = peek_entry();
    const map::GateStand stand = stand_for(scene.id, entry);
    WalkPose pose;
    place_walk(pose, *scene.ground, scene.id, stand);
    focus.eye = math::Vector3(pose.x, 0.0F, pose.z);
    return focus;
}

// Xếp lại theo khung nhìn của khung vừa vẽ, mỗi kRankEvery một lần khi cảnh đã hiện.
void Display::State::rank_arrival(Arrival& loading) const {
    if (!loading.revealed || !held) return;
    if (view_scene != held->id) return;
    const core::Clock::time_point now = core::Clock::now();
    const bool is_due = !loading.has_view_rank || now - loading.ranked_at >= kRankEvery;
    if (!is_due) return;
    loading.ranked_at = now;
    loading.has_view_rank = true;
    LoadFocus focus;
    focus.eye = view_eye;
    focus.frustum = view_frustum;
    const std::vector<float> scores = mesh_scores(loading, focus);
    const Order ranked = slot_order(loading, scores);
    feeder->rank(loading.epoch, ranked);
    sort_kept(loading, scores);
    note_seen(loading, scores);
}

bool Display::State::needs_fresh_ground(const Arrival& loading) const {
    if (data_root.empty() || !loading.scene || !loading.scene->ground) return false;
    if (loading.scene->ground->sheet.indices.empty()) return false;
    return find_ground(grounds, loading.scene->id) == nullptr;
}

void Display::State::reveal(Arrival& loading) {
    if (loading.revealed) return;
    held = loading.scene;
    stage = held ? &held->stage : nullptr;
    ground = held && held->ground ? &*held->ground : nullptr;
    walk_field = held && held->walk ? &*held->walk : nullptr;
    order.reset();
    instances.clear();
    instance_mesh.clear();
    crowds.clear();
    scene_models.clear();
    scene_models_built = false;
    loading.crowd_of.clear();
    world = {};
    light = stage != nullptr ? light_of(*stage) : SceneLight{};
    loading.revealed = true;
    attach_cached_ground();
    if (fx_view && stage != nullptr) fx_view->adopt(*stage);
    adopt_sky();
    if (shows_role_scene()) role_stage.replay();
}

void Display::State::stream_ground(Arrival& loading) {
    // Địa hình phải xong trước mesh đầu tiên: đọc tệp, nướng ảnh mặt và tải lên GPU đều nằm ở đây.
    loading.ground_ms = millis_between(loading.started, core::Clock::now());
    loading.ground_done = true;
    if (loading.prefetch) return;
    reveal(loading);
}

void Display::State::seal_mesh(std::size_t index, std::vector<std::size_t>& slots) {
    const std::size_t slot = slots.at(index);
    if (slot == kMissing) return;
    push_crowd(crowds.at(slot));
}

void Display::State::publish_mesh(Arrival& loading, std::size_t mesh_slot) {
    const std::size_t index = loading.loaded.at(mesh_slot);
    if (index == kMissing) return;
    grow_slots(loading.crowd_of, kept.size());
    const std::vector<std::size_t>& users = loading.users.at(mesh_slot);
    for (const std::size_t prop_index : users) {
        PropPlace place;
        place.prop = &loading.table.props.at(prop_index);
        place.loaded = loading.loaded;
        place.crowd_of = &loading.crowd_of;
        place_prop(place);
    }
    seal_mesh(index, loading.crowd_of);
    order_instances(mesh_slot);
}

// Instance của một mesh vừa thêm vào cuối (phần instances vượt instance_mesh) chuyển về chỗ của nó
// theo chỉ số bảng: mesh xong theo hạng khung nhìn mà thứ tự vẽ cuối vẫn giống hệt nạp tuần tự
// theo bảng, vì Forward giữ thứ tự instance giữa các lệnh cùng pipeline (mặt trùng nhau phân thắng
// thua theo thứ tự đó).
void Display::State::order_instances(std::size_t mesh_slot) {
    const std::size_t before = instance_mesh.size();
    core::check(instances.size() >= before, "instance_mesh dài hơn instances");
    const std::size_t added = instances.size() - before;
    const auto spot = std::ranges::upper_bound(instance_mesh, mesh_slot);
    const std::ptrdiff_t offset = std::distance(instance_mesh.begin(), spot);
    instance_mesh.insert(spot, added, mesh_slot);
    const auto first = std::next(instances.begin(), offset);
    const auto middle = std::next(instances.begin(), static_cast<std::ptrdiff_t>(before));
    std::ranges::rotate(first, middle, instances.end());
}

void Display::State::settle_mesh(Arrival& loading, std::size_t index) {
    loading.is_settled.at(index) = true;
    ++loading.settled;
    if (loading.revealed) publish_mesh(loading, index);
    count_seen(loading, index);
}

void Display::State::finish_stream() {
    if (!arrival.has_value()) return;
    const auto elapsed = core::Clock::now() - arrival->started;
    const double millis = std::chrono::duration<double, std::milli>(elapsed).count();
    const int id = arrival->scene ? arrival->scene->id : -1;
    const std::string millis_text = std::format("{:.1f}", millis);
    const std::string meshes_text = std::to_string(kept.size());
    const std::string props_text = std::to_string(instances.size());
    const std::string id_text = std::to_string(id);
    const std::string loaded = "Nạp cảnh resid " + id_text + " xong trong " + millis_text;
    const std::string loaded_tail = " ms, " + meshes_text + " mesh nhớ, " + props_text + " vật thể";
    std::println("{}", loaded + loaded_tail);
    // Mesh đã lên GPU, bản nướng đã thả: trả trang heap thừa cho hệ điều hành trước khi lmkd đo.
    core::trim_heap();
    const double gpu_mb = static_cast<double>(device->memory_budget().used_bytes) / 1048576.0;
    std::println("Bộ nhớ GPU {:.1f} MB (texture và buffer)", gpu_mb);
    core::mark("cảnh nạp xong (mọi mesh đã đặt)");
    const std::string ground_ms = std::format("{:.1f}", arrival->ground_ms);
    const std::string seat_ms = std::format("{:.1f}", arrival->seat_ms);
    const std::string stall_ms = std::format("{:.1f}", arrival->stall_ms);
    const std::string place_ms = std::format("{:.1f}", arrival->place_ms);
    const std::string show_ms = std::format("{:.1f}", arrival->show_ms);
    const std::string frames_text = std::to_string(arrival->load_frames);
    const std::string ground_part = "  địa hình " + ground_ms + " ms, đưa GPU " + seat_ms;
    const std::string timing = ground_part + " ms, chờ luồng đọc " + stall_ms;
    if (!steady_from) steady_from = frame_ms.size() + 30;
    const std::string built = " ms, dựng GPU " + place_ms + " ms, đặt vật thể " + show_ms;
    const std::string timing_tail = built + " ms, " + frames_text + " khung";
    std::println("{}", timing + timing_tail);
    const bool was_prefetch = arrival->prefetch;
    const bool login_holds = procedure == Procedure::kLogin && held != nullptr;
    const bool role_waits = role_scene != nullptr && held != nullptr && role_scene->id != held->id;
    if (!was_prefetch && procedure == Procedure::kPlay) has_entered_world = true;
    arrival.reset();
    if (was_prefetch || !login_holds || !role_waits) return;
    begin_load(role_scene, true);
}

void Display::State::open_ground(Arrival& loading) {
    if (loading.ground_done) return;
    if (!needs_fresh_ground(loading)) {
        stream_ground(loading);
        return;
    }
    std::optional<ReadMesh> read = feeder->take_ground(loading.epoch);
    if (!read) return;
    const TimePoint seat_began = core::Clock::now();
    keep_ground(loading.scene->id, std::move(*read));
    loading.seat_ms += millis_between(seat_began, core::Clock::now());
    stream_ground(loading);
}

// Mesh kế tiếp để đặt: mesh đã có trong nhớ trước (chỉ đặt vật thể, không chạm GPU), rồi mesh luồng
// đọc đã xong có hạng cao nhất. Chưa có gì thì ghi mốc đói dữ liệu.
std::optional<std::size_t> Display::State::pull_mesh(Arrival& loading) {
    const bool has_kept = loading.kept_next < loading.kept_queue.size();
    if (has_kept) return next_kept(loading);
    std::optional<MeshTake> taken = feeder->take_best(loading.epoch);
    if (!taken) return note_waiting(loading);
    if (loading.is_stalled) {
        loading.stall_ms += millis_between(loading.stall_started, core::Clock::now());
        loading.is_stalled = false;
    }
    const std::size_t index = loading.slot_mesh.at(taken->slot);
    if (!taken->mesh) return index;
    const std::string& mesh = loading.table.meshes.at(index);
    loading.loaded.at(index) = keep_model(mesh, std::move(*taken->mesh));
    return index;
}

bool Display::State::step_mesh(Arrival& loading) {
    const core::Clock::time_point before = core::Clock::now();
    const std::optional<std::size_t> index = pull_mesh(loading);
    const core::Clock::time_point pulled = core::Clock::now();
    if (!index) return false;
    loading.place_ms += millis_between(before, pulled);
    settle_mesh(loading, *index);
    loading.show_ms += millis_between(pulled, core::Clock::now());
    return true;
}

void Display::State::pump_load() {
    if (!arrival.has_value()) return;
    Arrival& loading = arrival.value();
    const bool was_grounded = loading.ground_done;
    open_ground(loading);
    if (!loading.ground_done) return;
    // Khung vừa đưa cả mặt đất lên GPU thì dừng: cộng mesh vào cùng khung là cú giật 30 ms.
    if (!was_grounded) return;
    ++loading.load_frames;
    rank_arrival(loading);
    const core::Clock::time_point deadline = core::Clock::now() + kLoadSlice;
    // Lệnh chép ảnh của mọi mesh trong lượt này đi một lần nộp: nộp riêng từng mesh chặn luồng vẽ
    // hàng chục ms mỗi lần trên GPU tile (xem resource::UploadBatch), và đó là phần lớn thời gian
    // nạp cảnh trên máy bảng.
    resource::UploadBatch batch(*device);
    load_batch = &batch;
    bool running = true;
    while (running) {
        running = mesh_waiting(loading, deadline) && step_mesh(loading);
    }
    load_batch = nullptr;
    const core::Status sent = batch.flush();
    if (!sent) std::println(stderr, "Lỗi nộp lệnh nạp mesh: {}", sent.error());
    if (!is_streamed(loading)) return;
    finish_stream();
}

// Đặt hết mesh của cảnh trước khung đầu, khi chính sách không cho hiện khung đầu sớm.
void Display::State::settle_meshes(Arrival& loading, const std::stop_token& stop) {
    while (!is_streamed(loading) && !stop.stop_requested()) {
        if (!step_mesh(loading)) core::sleep_for(kWaitPause);
    }
    if (is_streamed(loading)) finish_stream();
}

void Display::State::settle_first_scene(const std::stop_token& stop) {
    // Chỉ lượt nạp thật; lượt prefetch cảnh chọn nhân vật (finish_stream đặt sau cảnh nền) chạy
    // dần như cũ.
    while (arrival.has_value() && !arrival->prefetch && !stop.stop_requested()) {
        Arrival& loading = arrival.value();
        open_ground(loading);
        if (!loading.ground_done) core::sleep_for(kWaitPause);
        if (!loading.ground_done) continue;
        // Mặt đất xong là vẽ khung đầu, mesh vào dần qua pump_load (shows_first_frame_early).
        if (policy.shows_first_frame_early) break;
        settle_meshes(loading, stop);
    }
    // Trời và nước dựng ở khung đầu cũng là việc nạp: để sau khung đầu là cú khựng hơn nửa giây.
    ensure_sky();
    ensure_water();
}

std::vector<std::size_t> Display::State::load_listed(const PropTable& table) {
    std::vector<std::size_t> loaded(table.meshes.size(), kMissing);
    for (std::size_t index = 0; index < table.meshes.size(); ++index) {
        loaded.at(index) = load_mesh(table.meshes.at(index));
    }
    return loaded;
}

void Display::State::load_props() {
    const PropTable table = table_of(*stage);
    const std::vector<std::size_t> loaded = load_listed(table);
    build_instances(table, loaded);
}

void Display::State::load_stage() {
    if (stage != nullptr && !data_root.empty()) load_props();
    append_ground();
    std::println("Nạp cảnh: {} mesh nhớ, {} vật thể", kept.size(), instances.size());
}

namespace {

void append_material(std::vector<std::string>& names, std::string_view text, std::size_t from,
    std::size_t until) {
    names.emplace_back(text.substr(from, until - from));
}

[[nodiscard]] std::vector<std::string> material_names(std::string_view text) {
    std::vector<std::string> names;
    std::size_t from = 0;
    while (from <= text.size()) {
        const std::size_t mark = text.find(';', from);
        const bool last = mark == std::string_view::npos;
        const std::size_t until = last ? text.size() : mark;
        append_material(names, text, from, until);
        if (last) return names;
        from = mark + 1;
    }
    return names;
}

} // namespace

std::size_t Display::State::load_mesh(const std::string& mesh) {
    const auto found = kept_by_name.find(mesh);
    if (found != kept_by_name.end()) return found->second;
    auto model = resource::load_named_model(mesh, io::utf8_of(data_root), texture_tier);
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        kept_by_name.emplace(mesh, kMissing);
        return kMissing;
    }
    return keep_model(mesh, baked_mesh(std::move(*model), bake_rules(), true));
}

std::size_t Display::State::load_ride_mesh(const std::string& mesh, std::string_view materials) {
    if (materials.empty()) return load_mesh(mesh);
    const std::string key = std::format("{}\n{}", mesh, materials);
    const auto found = kept_by_name.find(key);
    if (found != kept_by_name.end()) return found->second;
    const std::vector<std::string> names = material_names(materials);
    const std::string root = io::utf8_of(data_root);
    auto model = resource::load_mesh_painted(mesh, root, names, texture_tier);
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        kept_by_name.emplace(key, kMissing);
        return kMissing;
    }
    return keep_model(key, baked_mesh(std::move(*model), bake_rules(), true));
}

const render::Drawable* Display::State::ride_drawable(const std::string& mesh,
    std::string_view materials) {
    const std::size_t index = load_ride_mesh(mesh, materials);
    if (index == kMissing) return nullptr;
    return &kept.at(index).loaded.drawable;
}

std::size_t Display::State::keep_model(const std::string& mesh, ReadMesh read) {
    kept.emplace_back();
    SeatTarget target;
    target.slot = &kept.back();
    target.device = device.get();
    target.forward = forward.get();
    target.batch = load_batch;
    if (!seat_model(target, std::move(read))) {
        kept.pop_back();
        return kMissing;
    }
    const std::size_t index = kept.size() - 1;
    kept_by_name.emplace(mesh, index);
    return index;
}
} // namespace game::client
