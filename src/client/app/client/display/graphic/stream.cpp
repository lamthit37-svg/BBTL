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
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"

#include <format>
namespace game::client {

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
    const std::size_t placed = loading.cursor;
    for (std::size_t index = 0; index < placed; ++index) {
        publish_mesh(loading, index);
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
    loading.loaded.assign(loading.table.meshes.size(), kMissing);
    index_users(loading);
    FeedJob job;
    job.root = data_root;
    job.tier = texture_tier;
    job.bake = bake_rules();
    job.pending_limit = policy.pending_bytes;
    job.scene = loading.scene;
    job.bake_ground = needs_fresh_ground(loading);
    remember_meshes(loading, job);
    const std::size_t fresh = job.needs.size();
    loading.epoch = feeder->post(std::move(job));
    if (!loading.table.meshes.empty()) {
        const std::size_t count = loading.table.meshes.size();
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
        return;
    }
    Need need;
    need.slot = job.needs.size();
    need.name = mesh;
    loading.feed_slot.at(index) = need.slot;
    job.needs.push_back(std::move(need));
}

void Display::State::remember_meshes(Arrival& loading, FeedJob& job) {
    const std::size_t count = loading.table.meshes.size();
    loading.feed_slot.assign(count, kMissing);
    for (std::size_t index = 0; index < count; ++index) {
        remember_mesh(loading, job, index);
    }
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
}

void Display::State::show_mesh(Arrival& loading) {
    if (!loading.revealed) return;
    publish_mesh(loading, loading.cursor - 1);
}

void Display::State::finish_stream() {
    if (!arrival.has_value()) return;
    const auto elapsed = core::Clock::now() - arrival->started;
    const double millis = std::chrono::duration<double, std::milli>(elapsed).count();
    const int id = arrival->scene ? arrival->scene->id : -1;
    const std::string millis_text = std::format("{:.1f}", millis);
    const std::string meshes_text = std::to_string(kept.size());
    const std::string props_text = std::to_string(instances.size());
    const std::string loaded = "Nạp cảnh resid " + std::to_string(id) + " xong trong " + millis_text;
    const std::string loaded_tail = " ms, " + meshes_text + " mesh nhớ, " + props_text + " vật thể";
    std::println("{}", loaded + loaded_tail);
    // Mesh đã lên GPU và bản nướng đã thả: trả trang heap còn giữ cho hệ điều hành trước khi lmkd đo.
    core::trim_heap();
    std::println("Bộ nhớ GPU {:.1f} MB (texture và buffer)", static_cast<double>(device->memory_budget().used_bytes) / 1048576.0);
    core::mark("cảnh nạp xong (mọi mesh đã đặt)");
    const std::string ground_ms = std::format("{:.1f}", arrival->ground_ms);
    const std::string seat_ms = std::format("{:.1f}", arrival->seat_ms);
    const std::string stall_ms = std::format("{:.1f}", arrival->stall_ms);
    const std::string place_ms = std::format("{:.1f}", arrival->place_ms);
    const std::string show_ms = std::format("{:.1f}", arrival->show_ms);
    const std::string frames_text = std::to_string(arrival->load_frames);
    const std::string timing = "  địa hình " + ground_ms + " ms, đưa GPU " + seat_ms + " ms, chờ luồng đọc " + stall_ms;
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

bool Display::State::pull_mesh(Arrival& loading) {
    const std::size_t index = loading.cursor;
    if (loading.feed_slot.at(index) == kMissing) {
        ++loading.cursor;
        return true;
    }
    const std::size_t slot = loading.feed_slot.at(index);
    MeshReady ready = feeder->take_mesh(loading.epoch, slot);
    if (!ready.is_ready) return note_waiting(loading);
    if (loading.is_stalled) {
        loading.stall_ms += millis_between(loading.stall_started, core::Clock::now());
        loading.is_stalled = false;
    }
    if (ready.mesh) {
        const std::string& mesh = loading.table.meshes.at(index);
        loading.loaded.at(index) = keep_model(mesh, std::move(*ready.mesh));
    }
    ++loading.cursor;
    return true;
}

bool Display::State::step_mesh(Arrival& loading) {
    const core::Clock::time_point before = core::Clock::now();
    const bool moved = pull_mesh(loading);
    const core::Clock::time_point pulled = core::Clock::now();
    if (!moved) return false;
    loading.place_ms += millis_between(before, pulled);
    show_mesh(loading);
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
    const core::Clock::time_point deadline = core::Clock::now() + kLoadSlice;
    bool running = true;
    while (running) {
        running = mesh_waiting(loading, deadline) && step_mesh(loading);
    }
    if (loading.cursor < loading.table.meshes.size()) return;
    finish_stream();
}

void Display::State::settle_first_scene(const std::stop_token& stop) {
    constexpr std::chrono::microseconds kWaitPause{100};
    // Chỉ lượt nạp thật; lượt prefetch cảnh chọn nhân vật (finish_stream đặt sau cảnh nền) chạy dần như cũ.
    while (arrival.has_value() && !arrival->prefetch && !stop.stop_requested()) {
        Arrival& loading = arrival.value();
        open_ground(loading);
        if (!loading.ground_done) {
            core::sleep_for(kWaitPause);
            continue;
        }
        // Mặt đất xong là vẽ khung đầu, mesh vào dần qua pump_load (GraphicsPolicy::shows_first_frame_early).
        if (policy.shows_first_frame_early) break;
        while (loading.cursor < loading.table.meshes.size() && !stop.stop_requested()) {
            if (!step_mesh(loading)) core::sleep_for(kWaitPause);
        }
        if (loading.cursor >= loading.table.meshes.size()) finish_stream();
    }
    // Trời và nước dựng ở khung đầu cũng là việc nạp: để chúng sau khung đầu là một cú khựng hơn nửa giây.
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
    if (!seat_model(target, std::move(read))) {
        kept.pop_back();
        return kMissing;
    }
    const std::size_t index = kept.size() - 1;
    kept_by_name.emplace(mesh, index);
    return index;
}
} // namespace game::client
