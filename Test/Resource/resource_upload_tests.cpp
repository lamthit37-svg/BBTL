// Test đường tải lên GPU của resource/upload trên thiết bị giả (resource_upload_device.hpp): số và
// thứ tự lời gọi của đường thành công, mỗi tay nắm được trả đúng một lần và theo thứ tự lưới, ảnh
// (view trước texture), sampler; tiêm lỗi vào từng lời gọi có thể hỏng thì không rò và không trả
// hai lần; và byte của chuỗi mip so với bảng băm vàng. Không đụng GPU thật, không đọc tệp.
// Sinh lại bảng vàng: resource_upload_tests.exe --golden rồi dán các dòng in ra vào kGolden. Chỉ
// làm thế khi đã chứng minh byte mới là đúng: bảng hiện tại sinh ngày 2026-10-08 từ bản mà bộ thử
// vi sai đã so trùng từng byte với bản chép từ Forge2.
#include "core/check.hpp"
#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"
#include "resource_upload_device.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

// Model thử: ba hình nguyên thuỷ có ba đích morph, bốn ảnh, hai sampler.
constexpr std::uint32_t kMeshBuffers = 9;
constexpr std::uint32_t kImages = 4;
constexpr std::uint32_t kSamplers = 2;
constexpr std::uint32_t kMipLevels = 18;
// Mỗi buffer của lưới có một buffer trung chuyển; mỗi ảnh có một buffer trung chuyển cho mọi mức.
constexpr std::uint32_t kStagingBuffers = kMeshBuffers + kImages;
// Tay nắm còn lại sau khi tải: buffer của lưới, texture và view của ảnh, sampler và sampler mặc định.
constexpr std::uint32_t kOwnedHandles = kMeshBuffers + (2 * kImages) + kSamplers + 1;

enum class Way : std::uint8_t {
    kWait,
    kQueued,
    kBaked,
};

constexpr std::array kWays{Way::kWait, Way::kQueued, Way::kBaked};

// Số giả ngẫu nhiên tất định, để dữ liệu thử giống nhau ở mọi trình dịch.
class Dice {
public:
    explicit Dice(std::uint32_t seed) noexcept : state_(seed) {}

    [[nodiscard]] std::uint32_t next() noexcept {
        state_ = (state_ * 1664525U) + 1013904223U;
        return state_ >> 8U;
    }

private:
    std::uint32_t state_;
};

struct ImageSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

[[nodiscard]] resource::Image make_image(std::string_view name, ImageSize size, std::uint32_t seed) {
    resource::Image image;
    image.name = name;
    image.width = size.width;
    image.height = size.height;
    image.rgba.resize(static_cast<std::size_t>(size.width) * size.height * 4);
    Dice dice(seed);
    for (std::uint8_t& value : image.rgba) {
        value = static_cast<std::uint8_t>(dice.next());
    }
    return image;
}

// Số đỉnh, số chỉ số và số đích morph của một hình nguyên thuỷ thử.
struct PrimitivePlan {
    std::uint32_t vertices = 0;
    std::uint32_t indices = 0;
    std::uint32_t targets = 0;
};

[[nodiscard]] resource::Primitive make_primitive(PrimitivePlan plan) {
    resource::Primitive primitive;
    primitive.vertices.resize(plan.vertices);
    primitive.indices.resize(plan.indices);
    for (std::uint32_t target = 0; target < plan.targets; ++target) {
        primitive.targets.emplace_back().vertices.resize(plan.vertices);
    }
    return primitive;
}

[[nodiscard]] resource::Model mesh_model() {
    resource::Model model;
    resource::Mesh first;
    first.primitives.push_back(make_primitive({.vertices = 3, .indices = 3, .targets = 2}));
    first.primitives.push_back(make_primitive({.vertices = 4, .indices = 6, .targets = 0}));
    model.meshes.push_back(std::move(first));
    model.meshes.emplace_back();
    resource::Mesh third;
    third.primitives.push_back(make_primitive({.vertices = 5, .indices = 9, .targets = 1}));
    model.meshes.push_back(std::move(third));
    return model;
}

// Lưới của mesh_model cộng bốn ảnh (một ảnh màu sRGB, ba ảnh tuyến tính) và hai sampler.
[[nodiscard]] resource::Model full_model() {
    resource::Model model = mesh_model();
    model.images.push_back(make_image("màu", {.width = 5, .height = 3}, 11));
    model.images.push_back(make_image("pháp tuyến", {.width = 64, .height = 64}, 22));
    model.images.push_back(make_image("", {.width = 1, .height = 1}, 33));
    model.images.push_back(make_image("cả hai", {.width = 70, .height = 9}, 44));
    model.samplers.resize(kSamplers);
    resource::Material paint;
    paint.color.image = 0;
    paint.normal.image = 1;
    paint.emissive_map.image = 3;
    paint.occlusion.image = 3;
    model.materials.push_back(paint);
    return model;
}

[[nodiscard]] core::Result<resource::Uploaded> run_upload(gpu::Device& device, const resource::Model& model, Way way) {
    if (way == Way::kWait) return resource::upload(device, model);
    if (way == Way::kQueued) return resource::upload_queued(device, model);
    const auto baked = resource::stage_images(model);
    if (!baked) return std::unexpected(baked.error());
    return resource::upload_queued(device, model, *baked);
}

void add_primitive_slots(const resource::GpuPrimitive& primitive, std::vector<Slot>& out) {
    out.push_back({.kind = Kind::kBuffer, .index = primitive.vertices.index});
    out.push_back({.kind = Kind::kBuffer, .index = primitive.indices.index});
    for (const gpu::BufferHandle morph : primitive.morphs) {
        out.push_back({.kind = Kind::kBuffer, .index = morph.index});
    }
}

void add_mesh_slots(const resource::GpuMesh& mesh, std::vector<Slot>& out) {
    for (const resource::GpuPrimitive& primitive : mesh.primitives) {
        add_primitive_slots(primitive, out);
    }
}

void add_image_slots(const resource::Uploaded& loaded, std::vector<Slot>& out) {
    for (const resource::GpuImage& image : loaded.images()) {
        out.push_back({.kind = Kind::kView, .index = image.view.index});
        out.push_back({.kind = Kind::kTexture, .index = image.texture.index});
    }
}

void add_sampler_slots(const resource::Uploaded& loaded, std::vector<Slot>& out) {
    for (const gpu::SamplerHandle sampler : loaded.samplers()) {
        out.push_back({.kind = Kind::kSampler, .index = sampler.index});
    }
    const gpu::SamplerHandle fallback = loaded.default_sampler();
    if (fallback.valid()) out.push_back({.kind = Kind::kSampler, .index = fallback.index});
}

// Mọi tay nắm mà loaded giữ, theo đúng thứ tự nó phải trả: lưới, ảnh (view trước texture), sampler.
[[nodiscard]] std::vector<Slot> owned_slots(const resource::Uploaded& loaded) {
    std::vector<Slot> slots;
    for (const resource::GpuMesh& mesh : loaded.meshes()) {
        add_mesh_slots(mesh, slots);
    }
    add_image_slots(loaded, slots);
    add_sampler_slots(loaded, slots);
    return slots;
}

[[nodiscard]] bool is_empty(const resource::Uploaded& loaded) noexcept {
    const bool has_handles = !loaded.meshes().empty() || !loaded.images().empty() || !loaded.samplers().empty();
    return !has_handles && !loaded.default_sampler().valid();
}

[[nodiscard]] bool is_clean(const Seen& seen) noexcept {
    return seen.live.empty() && seen.double_frees == 0 && seen.dead_uses == 0 && seen.strays == 0;
}

// Lệnh của một lần tải đủ model: chép buffer của lưới, rào sang CopyDest, chép ảnh, rào về đọc.
[[nodiscard]] std::vector<Command> expected_commands() {
    std::vector<Command> commands(kMeshBuffers, Command::kCopyBuffer);
    commands.push_back(Command::kToCopyDest);
    commands.insert(commands.end(), kImages, Command::kCopyImage);
    commands.push_back(Command::kToRead);
    return commands;
}

void expect_full_counts(Context& context, const Seen& seen, Way way) {
    context.expect(seen.begins == 1 && seen.submits == 1, "một danh sách lệnh, nộp đúng một lần");
    context.expect(seen.waits == (way == Way::kWait ? 1U : 0U), "chỉ upload chờ GPU, upload_queued thì không");
    context.expect(seen.end_frames == 0, "đường thành công không đóng khung");
    context.expect(seen.buffers == kMeshBuffers + kStagingBuffers, "mỗi buffer đích kèm một buffer trung chuyển");
    context.expect(seen.writes == kStagingBuffers, "mỗi buffer trung chuyển được ghi một lần");
    context.expect(seen.textures == kImages && seen.views == kImages, "mỗi ảnh một texture và một view");
    context.expect(seen.samplers == kSamplers + 1, "sampler của model cộng một sampler mặc định");
    context.expect(seen.commands == expected_commands(), "chép buffer, rào CopyDest, chép ảnh, rào về đọc");
    context.expect(seen.copy_regions == kMipLevels, "mỗi mức mip một vùng chép");
    context.expect(seen.buffer_barriers == kMeshBuffers, "mỗi buffer của lưới một rào về đọc");
    context.expect(seen.texture_barriers == 2 * kImages, "mỗi texture hai rào: sang CopyDest rồi về đọc");
}

// Đường thành công của cả ba lối vào: số lời gọi theo đúng model, và mọi tay nắm còn sống sau khi
// tải đều nằm trong Uploaded (buffer trung chuyển đã trả hết).
void check_success(Context& context, Way way) {
    FakeDevice device;
    const resource::Model model = full_model();
    const auto loaded = run_upload(device, model, way);
    context.expect(loaded.has_value(), "tải đủ model phải thành công");
    if (!loaded) return;
    const Seen& seen = device.seen();
    expect_full_counts(context, seen, way);
    const std::vector<Slot> owned = owned_slots(*loaded);
    context.expect(owned.size() == kOwnedHandles, "Uploaded giữ đủ tay nắm của lưới, ảnh và sampler");
    context.expect(std::ranges::is_permutation(seen.live, owned), "tay nắm còn sống đều thuộc Uploaded");
    context.expect(seen.released.size() == kStagingBuffers, "buffer trung chuyển đã trả hết sau khi nộp");
    context.expect(seen.double_frees == 0 && seen.dead_uses == 0 && seen.strays == 0, "không lời gọi sai nào");
}

void success_issues_expected_calls(Context& context) {
    for (const Way way : kWays) {
        check_success(context, way);
    }
}

// Huỷ Uploaded: mỗi tay nắm được trả đúng một lần, theo thứ tự lưới, ảnh (view trước texture),
// sampler rồi sampler mặc định.
void destroying_releases_in_order(Context& context) {
    FakeDevice device;
    const resource::Model model = full_model();
    auto loaded = resource::upload(device, model);
    context.expect(loaded.has_value(), "tải đủ model phải thành công");
    if (!loaded) return;
    const std::vector<Slot> owned = owned_slots(*loaded);
    *loaded = resource::Uploaded{};
    const Seen& seen = device.seen();
    context.expect(is_clean(seen), "không rò, không trả hai lần");
    context.expect(seen.released.size() == kStagingBuffers + kOwnedHandles, "mỗi tay nắm trả đúng một lần");
    if (seen.released.size() != kStagingBuffers + kOwnedHandles) return;
    const std::span<const Slot> tail = std::span(seen.released).last(kOwnedHandles);
    context.expect(std::ranges::equal(tail, owned), "trả theo thứ tự lưới, ảnh, sampler");
}

// Nhận bằng giá trị rồi trả lại: hai lần dựng bằng move, và bản đã bị lấy ruột bị huỷ ngay ở đây.
[[nodiscard]] resource::Uploaded pass_through(resource::Uploaded source) noexcept {
    return source;
}

// Hai lần tải trên cùng thiết bị rồi đổi chủ. Mọi Uploaded của hàm này bị huỷ khi hàm trả về, kể
// cả các bản đã bị lấy ruột: bản nào còn giữ tay nắm thì thiết bị sẽ thấy trả hai lần.
void shuffle_owners(Context& context, FakeDevice& device) {
    const resource::Model model = full_model();
    auto first = resource::upload_queued(device, model);
    auto second = resource::upload_queued(device, model);
    context.expect(first.has_value() && second.has_value(), "hai lần tải đều thành công");
    if (!first || !second) return;
    const std::vector<Slot> kept = owned_slots(*second);
    const std::size_t both = std::size_t{2} * kOwnedHandles;
    resource::Uploaded owner = pass_through(std::move(*first));
    context.expect(device.seen().live.size() == both, "dựng bằng move không trả tay nắm nào");
    owner = std::move(*second);
    context.expect(owned_slots(owner) == kept, "gán bằng move: đích nhận đúng tay nắm của nguồn");
    context.expect(device.seen().live.size() == kOwnedHandles, "gán bằng move trả tay nắm cũ của đích");
}

// Chuyển chủ bằng move: không tay nắm nào bị trả lúc dựng, gán thì trả tay nắm cũ của đích, và khi
// mọi chủ đã huỷ thì mỗi tay nắm được trả đúng một lần.
void moving_keeps_one_owner(Context& context) {
    FakeDevice device;
    shuffle_owners(context, device);
    const std::size_t all_handles = std::size_t{2} * (kStagingBuffers + kOwnedHandles);
    context.expect(is_clean(device.seen()), "mọi chủ đã huỷ: không rò, không trả hai lần");
    context.expect(device.seen().released.size() == all_handles, "mỗi tay nắm trả đúng một lần");
}

// Lỗi mà một lượt tiêm phải trả: end_frame hỏng thì lỗi của nó thắng, trừ khi lỗi tiêm rơi vào
// begin_commands hay wait_idle, là hai chỗ không đóng khung.
[[nodiscard]] core::ErrorCode expected_error(const Seen& seen, Plan plan) noexcept {
    const bool closes_frame = seen.tripped != Call::kBeginCommands && seen.tripped != Call::kWaitIdle;
    if (plan.fail_end_frame && closes_frame) return core::ErrorCode::kDeviceLost;
    return core::ErrorCode::kCorrupt;
}

void check_failure(Context& context, Way way, Plan plan) {
    FakeDevice device(plan);
    const resource::Model model = full_model();
    const auto loaded = run_upload(device, model, way);
    const Seen& seen = device.seen();
    context.expect(seen.tripped.has_value(), "lỗi đã được tiêm vào đúng một lời gọi");
    context.expect(!loaded.has_value(), "lời gọi thiết bị hỏng thì tải phải báo lỗi");
    if (loaded.has_value() || !seen.tripped.has_value()) return;
    context.expect(loaded.error().code() == expected_error(seen, plan), "lỗi trả về là lỗi tiêm hoặc lỗi end_frame");
    context.expect(seen.live.empty(), "không tay nắm nào rò sau khi hỏng");
    context.expect(seen.double_frees == 0 && seen.strays == 0, "không tay nắm nào bị trả hai lần");
    const bool closes_frame = seen.tripped != Call::kBeginCommands && seen.tripped != Call::kWaitIdle;
    context.expect(seen.end_frames == (closes_frame ? 1U : 0U), "hỏng giữa lúc ghi hay nộp thì đóng khung một lần");
}

[[nodiscard]] std::uint32_t fallible_calls(Way way) {
    FakeDevice device;
    const resource::Model model = full_model();
    const auto loaded = run_upload(device, model, way);
    return loaded.has_value() ? device.seen().fallible : 0;
}

// Tiêm lỗi lần lượt vào từng lời gọi có thể hỏng của một lối vào, có và không kèm end_frame hỏng.
void check_every_failure(Context& context, Way way) {
    const std::uint32_t calls = fallible_calls(way);
    const std::uint32_t expected = (2 * kStagingBuffers) + kMeshBuffers + (2 * kImages) + kSamplers + 3;
    context.expect(calls == (way == Way::kWait ? expected + 1 : expected), "số lời gọi có thể hỏng theo đúng model");
    Plan plan;
    for (plan.fail_at = 1; plan.fail_at <= calls; ++plan.fail_at) {
        plan.fail_end_frame = false;
        check_failure(context, way, plan);
        plan.fail_end_frame = true;
        check_failure(context, way, plan);
    }
}

void every_failure_releases_everything(Context& context) {
    for (const Way way : kWays) {
        check_every_failure(context, way);
    }
}

// Model chỉ có lưới: không ảnh thì không sampler mặc định, không rào texture, và huỷ vẫn sạch dù
// upload trả cả tay nắm sampler rỗng.
void mesh_only_model_has_no_samplers(Context& context) {
    FakeDevice device;
    const resource::Model model = mesh_model();
    auto loaded = resource::upload(device, model);
    context.expect(loaded.has_value(), "model chỉ có lưới vẫn tải được");
    if (!loaded) return;
    const Seen& seen = device.seen();
    context.expect(seen.samplers == 0 && !loaded->default_sampler().valid(), "không ảnh thì không sampler nào");
    const std::vector<Command> copies(kMeshBuffers, Command::kCopyBuffer);
    context.expect(seen.commands.size() == kMeshBuffers + 1, "chép buffer rồi đúng một rào");
    context.expect(std::ranges::equal(std::span(seen.commands).first(kMeshBuffers), copies), "chỉ có lệnh chép buffer");
    context.expect(seen.commands.back() == Command::kToRead && seen.texture_barriers == 0, "rào cuối chỉ có buffer");
    *loaded = resource::Uploaded{};
    const std::size_t all_buffers = std::size_t{2} * kMeshBuffers;
    context.expect(is_clean(seen) && seen.released.size() == all_buffers, "trả hết buffer, mỗi cái một lần");
}

// Bị từ chối trước khi đụng thiết bị: thiết bị đã mất, số chuỗi mip nướng sẵn lệch số ảnh; và model
// không có gì để tải thì thành công mà không gọi thiết bị.
void refused_models_touch_nothing(Context& context) {
    const resource::Model model = full_model();
    FakeDevice lost(Plan{.is_lost = true});
    const auto on_lost = resource::upload(lost, model);
    context.expect(!on_lost && on_lost.error().code() == core::ErrorCode::kDeviceLost, "thiết bị mất thì từ chối");
    context.expect(lost.seen().fallible == 0, "thiết bị mất: không lời gọi nào");
    FakeDevice device;
    const std::vector<resource::StagedImage> one(1);
    const auto mismatched = resource::upload_queued(device, model, one);
    const bool is_refused = !mismatched && mismatched.error().code() == core::ErrorCode::kInvalidArgument;
    context.expect(is_refused && device.seen().fallible == 0, "số chuỗi nướng sẵn lệch số ảnh thì từ chối");
    resource::Model hollow;
    hollow.meshes.emplace_back();
    hollow.samplers.emplace_back();
    const auto nothing = resource::upload(device, hollow);
    context.expect(nothing.has_value() && is_empty(*nothing), "không có gì để tải thì trả Uploaded rỗng");
    context.expect(device.seen().fallible == 0 && device.seen().strays == 0, "model rỗng: không lời gọi nào");
}

// Nội dung hỏng phát hiện giữa lúc ghi lệnh: báo đúng mã lỗi, đóng khung một lần, không rò.
void check_bad_content(Context& context, const resource::Model& model, core::ErrorCode wanted) {
    FakeDevice device;
    const auto loaded = resource::upload(device, model);
    context.expect(!loaded && loaded.error().code() == wanted, "nội dung hỏng thì báo đúng mã lỗi");
    context.expect(is_clean(device.seen()), "nội dung hỏng: không rò, không trả hai lần");
    context.expect(device.seen().end_frames == 1 && device.seen().submits == 0, "đóng khung một lần, không nộp");
}

void bad_content_fails_cleanly(Context& context) {
    resource::Model no_vertices = full_model();
    no_vertices.meshes.at(2).primitives.push_back(make_primitive({.vertices = 0, .indices = 3, .targets = 0}));
    check_bad_content(context, no_vertices, core::ErrorCode::kInvalidArgument);
    resource::Model no_indices = full_model();
    no_indices.meshes.at(2).primitives.push_back(make_primitive({.vertices = 3, .indices = 0, .targets = 1}));
    check_bad_content(context, no_indices, core::ErrorCode::kInvalidArgument);
    resource::Model empty_morph = full_model();
    empty_morph.meshes.at(0).primitives.at(0).targets.at(1).vertices.clear();
    check_bad_content(context, empty_morph, core::ErrorCode::kInvalidArgument);
    resource::Model short_image = full_model();
    short_image.images.at(1).rgba.pop_back();
    check_bad_content(context, short_image, core::ErrorCode::kCorrupt);
    resource::Model flat_image = full_model();
    flat_image.images.at(3).width = 0;
    check_bad_content(context, flat_image, core::ErrorCode::kInvalidArgument);
}

// Băm FNV-1a 64 bit gập còn 32 bit: đủ để bắt một byte lệch, và một dòng của bảng vàng vừa trần cột.
[[nodiscard]] std::uint32_t hash_of(std::span<const std::byte> bytes) noexcept {
    std::uint64_t hash = 1469598103934665603ULL;
    for (const std::byte value : bytes) {
        hash = (hash ^ std::to_integer<std::uint64_t>(value)) * 1099511628211ULL;
    }
    return static_cast<std::uint32_t>(hash ^ (hash >> 32U));
}

// Băm của ba kết quả cho một cỡ ảnh: mức 0 đã đóng gói, chuỗi mip tuyến tính, chuỗi mip sRGB.
struct Golden {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t packed = 0;
    std::uint32_t linear = 0;
    std::uint32_t srgb = 0;
};

// Cỡ chẵn, cỡ lẻ (cửa sổ biên ba texel), một hàng, một cột, và bề rộng chia hết lẫn không chia hết
// cho căn lề dòng 256 byte (hai đường đóng gói).
constexpr std::array kGolden{
    Golden{.width = 1, .height = 1, .packed = 0xf967ff0dU, .linear = 0xf967ff0dU, .srgb = 0xf967ff0dU},
    Golden{.width = 2, .height = 2, .packed = 0x3b298768U, .linear = 0xbe3fcf8bU, .srgb = 0xfc1de6e1U},
    Golden{.width = 3, .height = 3, .packed = 0x5458e4feU, .linear = 0x19dfdb34U, .srgb = 0xea5cf89bU},
    Golden{.width = 5, .height = 7, .packed = 0x53b88d1dU, .linear = 0x5d3f9257U, .srgb = 0x39fb340fU},
    Golden{.width = 64, .height = 64, .packed = 0xad74a70fU, .linear = 0x895f29bfU, .srgb = 0x5700dda5U},
    Golden{.width = 63, .height = 65, .packed = 0xe68eae7aU, .linear = 0xdec1137dU, .srgb = 0xe05f5299U},
    Golden{.width = 1, .height = 9, .packed = 0xb426a68fU, .linear = 0xe3a24698U, .srgb = 0x8533cf33U},
    Golden{.width = 9, .height = 1, .packed = 0x69b4c9b6U, .linear = 0x445c3352U, .srgb = 0xcae1e1e4U},
    Golden{.width = 128, .height = 1, .packed = 0x2c59f378U, .linear = 0xdec48d34U, .srgb = 0xa4f171ffU},
    Golden{.width = 130, .height = 3, .packed = 0xe009de9dU, .linear = 0x1d33fabeU, .srgb = 0x62e8d1e1U},
    Golden{.width = 257, .height = 131, .packed = 0xd5c87438U, .linear = 0x36e2c9e7U, .srgb = 0xbdf53db0U},
    Golden{.width = 256, .height = 256, .packed = 0xb8171ecbU, .linear = 0x65462bfcU, .srgb = 0x4992cc16U},
    Golden{.width = 192, .height = 100, .packed = 0x7d4349e8U, .linear = 0x04beffb2U, .srgb = 0x84460a49U},
    Golden{.width = 65, .height = 64, .packed = 0x425a817cU, .linear = 0xa725eba5U, .srgb = 0x82d332f3U},
    Golden{.width = 2, .height = 1, .packed = 0x82b852c9U, .linear = 0x2b900fa4U, .srgb = 0x62d524fbU},
    Golden{.width = 511, .height = 2, .packed = 0x34348c35U, .linear = 0x08f13923U, .srgb = 0xa31fa206U},
};

[[nodiscard]] std::uint32_t chain_hash(const resource::Image& image, resource::ColorSpace space) {
    const auto staged = resource::stage_image(image, space);
    return staged ? hash_of(staged->bytes) : 0;
}

[[nodiscard]] Golden measure(ImageSize size) {
    const resource::Image image = make_image("thử", size, (size.width * 7919U) + size.height);
    const auto level = resource::stage_rgba(image);
    Golden made;
    made.width = size.width;
    made.height = size.height;
    made.packed = level ? hash_of(*level) : 0;
    made.linear = chain_hash(image, resource::ColorSpace::kLinear);
    made.srgb = chain_hash(image, resource::ColorSpace::kSrgb);
    return made;
}

void check_golden(Context& context, const Golden& wanted) {
    const Golden made = measure({.width = wanted.width, .height = wanted.height});
    const std::string size = std::format("ảnh {}x{}", wanted.width, wanted.height);
    const std::string packed = size + ": byte mức 0 của stage_rgba lệch bảng vàng";
    const std::string linear = size + ": chuỗi mip tuyến tính của stage_image lệch bảng vàng";
    const std::string srgb = size + ": chuỗi mip sRGB của stage_image lệch bảng vàng";
    context.expect(made.packed == wanted.packed, packed);
    context.expect(made.linear == wanted.linear, linear);
    context.expect(made.srgb == wanted.srgb, srgb);
}

void mip_bytes_match_golden(Context& context) {
    for (const Golden& wanted : kGolden) {
        check_golden(context, wanted);
    }
}

// stage_images nướng mỗi ảnh trong đúng không gian màu mà lần tải dùng: chuỗi nướng sẵn phải trùng
// chuỗi mà stage_image cho ra với không gian ấy, nếu không upload_queued nướng sẵn vẽ khác màu.
void staged_images_follow_image_format(Context& context) {
    const resource::Model model = full_model();
    const auto baked = resource::stage_images(model);
    context.expect(baked.has_value() && baked->size() == kImages, "mỗi ảnh một chuỗi mip");
    if (!baked || baked->size() != kImages) return;
    const std::uint32_t colour = chain_hash(model.images.at(0), resource::ColorSpace::kSrgb);
    const std::uint32_t data = chain_hash(model.images.at(1), resource::ColorSpace::kLinear);
    const std::uint32_t mixed = chain_hash(model.images.at(3), resource::ColorSpace::kLinear);
    context.expect(hash_of(baked->at(0).bytes) == colour, "ảnh chỉ làm màu nướng trong sRGB");
    context.expect(hash_of(baked->at(1).bytes) == data, "ảnh dữ liệu nướng tuyến tính");
    context.expect(hash_of(baked->at(3).bytes) == mixed, "ảnh vừa màu vừa dữ liệu nướng tuyến tính");
}

// Ảnh BC1 64x32 đủ bảy mức, mức k tô toàn byte k để biết mức nào đứng đầu chuỗi đã nướng.
[[nodiscard]] resource::Image block_chain() {
    resource::Image image;
    image.name = "khoi";
    image.width = 64;
    image.height = 32;
    image.blocks = gpu::Format::kBc1Unorm;
    for (std::uint32_t level = 0; level < 7; ++level) {
        const std::uint32_t across = std::max(1U, ((image.width >> level) + 3U) / 4U);
        const std::uint32_t down = std::max(1U, ((image.height >> level) + 3U) / 4U);
        const std::size_t bytes = std::size_t{across} * down * 8U;
        image.levels.emplace_back(bytes, static_cast<std::byte>(level));
    }
    return image;
}

// max_edge bỏ các mức đầu tới khi cạnh dài nhất không quá giới hạn, giữ ít nhất một mức; 0 và ảnh không mip giữ nguyên.
void max_edge_skips_top_levels(Context& context) {
    const resource::Image image = block_chain();
    const auto whole = resource::stage_image(image, resource::ColorSpace::kLinear);
    context.expect(whole.has_value() && whole->mips.size() == 7, "không giới hạn thì đủ bảy mức");
    const auto capped = resource::stage_image(image, resource::ColorSpace::kLinear, 16);
    context.expect(capped.has_value() && capped->mips.size() == 5, "giới hạn 16 bỏ hai mức đầu");
    if (!capped || capped->mips.empty()) return;
    const resource::StagedMip& top = capped->mips.front();
    context.expect(top.width == 16 && top.height == 8, "mức đầu còn lại là 16x8");
    context.expect(capped->bytes.at(top.offset) == std::byte{2}, "byte của mức đầu là của mức 2 gốc");
    const auto tiny = resource::stage_image(image, resource::ColorSpace::kLinear, 1);
    context.expect(tiny.has_value() && tiny->mips.size() == 1, "giới hạn 1 vẫn giữ mức 1x1");
    resource::Image flat = image;
    flat.has_mips = false;
    const auto single = resource::stage_image(flat, resource::ColorSpace::kLinear, 16);
    const bool is_whole_top = single.has_value() && single->mips.size() == 1 && single->mips.front().width == 64;
    context.expect(is_whole_top, "ảnh không mip giữ mức 0");
}

constexpr std::array kCases{
    Case{.name = "max_edge_skips_top_levels", .body = &max_edge_skips_top_levels},
    Case{.name = "success_issues_expected_calls", .body = &success_issues_expected_calls},
    Case{.name = "destroying_releases_in_order", .body = &destroying_releases_in_order},
    Case{.name = "moving_keeps_one_owner", .body = &moving_keeps_one_owner},
    Case{.name = "every_failure_releases_everything", .body = &every_failure_releases_everything},
    Case{.name = "mesh_only_model_has_no_samplers", .body = &mesh_only_model_has_no_samplers},
    Case{.name = "refused_models_touch_nothing", .body = &refused_models_touch_nothing},
    Case{.name = "bad_content_fails_cleanly", .body = &bad_content_fails_cleanly},
    Case{.name = "mip_bytes_match_golden", .body = &mip_bytes_match_golden},
    Case{.name = "staged_images_follow_image_format", .body = &staged_images_follow_image_format},
};

[[nodiscard]] std::string golden_row(const Golden& made) {
    const std::string sizes = std::format(".width = {}, .height = {}", made.width, made.height);
    const std::string packed = std::format(".packed = {:#010x}U", made.packed);
    const std::string linear = std::format(".linear = {:#010x}U", made.linear);
    const std::string srgb = std::format(".srgb = {:#010x}U", made.srgb);
    return std::format("    Golden{{{}, {}, {}, {}}},\n", sizes, packed, linear, srgb);
}

// In lại bảng vàng theo đúng cú pháp của kGolden, từ mã đang dựng (đối số --golden).
void print_golden(Context&) {
    for (const Golden& row : kGolden) {
        const Golden made = measure({.width = row.width, .height = row.height});
        const std::string line = golden_row(made);
        static_cast<void>(std::fputs(line.c_str(), stdout));
    }
}

constexpr std::array kPrinters{
    Case{.name = "print_golden", .body = &print_golden},
};

} // namespace
} // namespace game::test

int main(int argc, char** argv) {
    const std::span<char*> arguments(argv, static_cast<std::size_t>(argc));
    const bool wants_golden = arguments.size() > 1 && std::string_view(arguments[1]) == "--golden";
    const std::span<const game::test::Case> tests = game::test::kCases;
    const std::span<const game::test::Case> printers = game::test::kPrinters;
    const std::int32_t failures = game::test::run_all(wants_golden ? printers : tests);
    game::core::check(failures == 0, "resource_upload_tests: mọi ca phải qua");
    return 0;
}
