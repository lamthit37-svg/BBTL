// Danh sách lệnh: ghi lệnh cho GPU, chưa thực thi — Cmd và các hàm cmd* của IGraphics.h trong _Ref,
// rhi/command.hpp của Platium, phần lệnh của GraphicsDevice trong Wicked. Device cấp một
// CommandList cho một luồng, luồng ghi xong thì nộp (Device::submit), Device thu hồi khi GPU chạy
// xong; chỗ gọi không huỷ và không giữ qua lần nộp. Một CommandList thuộc đúng một luồng: nhiều
// luồng ghi song song thì mỗi luồng xin một cái. Khác gốc:
// - không begin/end tay và không pool lệnh lộ ra ngoài (initCmdPool, beginCmd, endCmd của _Ref);
// - vẽ vào attachment khai tại chỗ, load và store bắt khai, resolve đa mẫu ngay trong lần vẽ;
// - buffer đỉnh không nhận bước: bước nằm trong pipeline (gốc khai ở cả hai nơi, lệch là sai câm);
// - kết quả truy vấn phải resolve bằng lệnh rồi mới đọc (D3D12 đòi; Vulkan bỏ qua lệnh ấy).
// Lệnh ghi sai (tay nắm chết, thiếu cờ, sai trạng thái) không đi xuống trình điều khiển: lỗi đầu
// tiên được giữ lại, các lệnh sau của danh sách bị bỏ, và Device::submit trả lỗi ấy. Trạng thái
// động khi danh sách mới mở: stencil reference 0, hằng trộn 0, khoảng độ sâu [0, 1].
// Nguồn: Forge2 src/gpu/command.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố k;
// bỏ {} thừa của RenderingDesc::colors và RenderingDesc::depth.
#pragma once

#include "gpu/barrier.hpp"
#include "gpu/handle.hpp"
#include "gpu/types.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::gpu {

struct ColorTarget {
    TextureViewHandle view{};
    LoadOp load = LoadOp::kClear;
    StoreOp store = StoreOp::kStore;
    ClearColor clear{};
    // Khác rỗng: view là đích đa mẫu và được resolve vào đây lúc kết thúc vẽ, khi dữ liệu còn nằm
    // trong bộ nhớ trên chip của GPU chia ô.
    TextureViewHandle resolve{};
};

struct DepthTarget {
    TextureViewHandle view{};
    LoadOp load = LoadOp::kClear;
    StoreOp store = StoreOp::kDiscard;
    ClearDepth clear{};
    LoadOp stencil_load = LoadOp::kDiscard;
    StoreOp stencil_store = StoreOp::kDiscard;
    // Chỉ thử, không ghi: cùng view còn được lấy mẫu trong shader (bố cục DepthRead).
    bool is_read_only = false;
};

struct RenderingDesc {
    // Vùng vẽ; rộng hoặc cao bằng 0 thì lấy trọn attachment đầu tiên.
    Scissor area{};
    // Khác gốc: gốc viết colors{} và depth{}; clang-tidy báo thừa nên bỏ.
    std::span<const ColorTarget> colors;
    std::optional<DepthTarget> depth;
    std::uint32_t layers = 1;
};

struct BufferCopy {
    std::uint64_t source_offset = 0;
    std::uint64_t target_offset = 0;
    std::uint64_t size = 0;
};

// Một vùng của texture cùng chỗ dữ liệu của nó trong buffer.
struct BufferTextureCopy {
    // Bội của kTextureOffsetAlignment.
    std::uint64_t buffer_offset = 0;
    // Bước dòng trong buffer tính bằng byte, bội của kTextureRowAlignment; 0 là padded_row_bytes
    // của vùng.
    std::uint32_t row_bytes = 0;
    std::uint32_t mip = 0;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = 1;
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t z = 0;
    // 0 là tới hết mức mip theo chiều đó.
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t depth = 0;
};

struct TexturePoint {
    std::uint32_t mip = 0;
    std::uint32_t layer = 0;
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t z = 0;
};

struct TextureCopy {
    TexturePoint source{};
    TexturePoint target{};
    // 0 là tới hết mức mip nguồn theo chiều đó.
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t depth = 0;
    std::uint32_t layer_count = 1;
};

// Tham số của một lệnh vẽ gián tiếp trong buffer; bố cục giống nhau ở cả hai API.
struct DrawArguments {
    std::uint32_t vertex_count = 0;
    std::uint32_t instance_count = 1;
    std::uint32_t first_vertex = 0;
    std::uint32_t first_instance = 0;
};

struct DrawIndexedArguments {
    std::uint32_t index_count = 0;
    std::uint32_t instance_count = 1;
    std::uint32_t first_index = 0;
    std::int32_t vertex_offset = 0;
    std::uint32_t first_instance = 0;
};

struct DispatchArguments {
    std::uint32_t x = 1;
    std::uint32_t y = 1;
    std::uint32_t z = 1;
};

class CommandList {
public:
    CommandList() = default;
    CommandList(const CommandList&) = delete;
    CommandList& operator=(const CommandList&) = delete;
    CommandList(CommandList&&) = delete;
    CommandList& operator=(CommandList&&) = delete;
    virtual ~CommandList() = default;

    [[nodiscard]] virtual QueueType queue() const noexcept = 0;

    // Nhãn cho RenderDoc, PIX, Nsight; lồng nhau được.
    virtual void begin_label(std::string_view name) = 0;
    virtual void end_label() = 0;
    virtual void insert_label(std::string_view name) = 0;

    // Một lời gọi cho cả lô: gộp rào rẻ hơn nhiều lần gọi lẻ, và chỉ chỗ gọi biết rào nào thuộc
    // cùng một điểm đồng bộ.
    virtual void barrier(std::span<const BufferBarrier> buffers, std::span<const TextureBarrier> textures,
        std::span<const GlobalBarrier> memory) = 0;

    // Chỉ trên danh sách của hàng Graphics. Đặt viewport và scissor phủ trọn vùng vẽ. Rào, lệnh
    // chép và dispatch không được nằm giữa begin_rendering và end_rendering.
    virtual void begin_rendering(const RenderingDesc& desc) = 0;
    virtual void end_rendering() = 0;

    virtual void set_viewport(const Viewport& viewport) = 0;
    virtual void set_scissor(const Scissor& scissor) = 0;
    virtual void set_stencil_reference(std::uint32_t value) = 0;
    virtual void set_blend_constants(const ClearColor& color) = 0;
    // Cần pipeline có DepthState::is_bounds_tested.
    virtual void set_depth_bounds(float nearest, float farthest) = 0;

    // Hàng Compute chỉ nhận pipeline compute; hàng Copy không nhận pipeline nào. Nhóm đã gắn còn
    // hiệu lực qua lần đổi pipeline chỉ khi hai pipeline cùng bố cục gắn (cùng tài nguyên ở mọi
    // register space và cùng khối push constant); khác đi thì phải gắn lại mọi nhóm.
    virtual void bind_pipeline(PipelineHandle pipeline) = 0;
    // Gắn nhóm vào register space space của pipeline đang gắn. Gắn pipeline trước. Nhóm phải được
    // tạo từ một pipeline có cùng bố cục ở register space ấy. Vẽ hay dispatch khi còn register
    // space có tài nguyên mà chưa gắn nhóm là lỗi.
    virtual void bind_group(std::uint32_t space, BindGroupHandle group) = 0;
    // Ghi vào khối F2_PUSH_CONSTANTS của pipeline đang gắn. offset và cỡ là bội của 4 và nằm trong
    // kMaxPushBytes.
    virtual void push_constants(std::span<const std::byte> data, std::uint32_t offset) = 0;

    // Gắn pipeline trước: D3D12 lấy bước đỉnh của khe từ pipeline.
    virtual void bind_vertex_buffer(std::uint32_t slot, BufferHandle buffer, std::uint64_t offset) = 0;
    virtual void bind_index_buffer(BufferHandle buffer, IndexType type, std::uint64_t offset) = 0;

    virtual void draw(const DrawArguments& arguments) = 0;
    virtual void draw_indexed(const DrawIndexedArguments& arguments) = 0;
    // count lệnh DrawArguments (hoặc DrawIndexedArguments) liền nhau, cách nhau stride byte.
    virtual void draw_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride) = 0;
    virtual void draw_indexed_indirect(BufferHandle arguments, std::uint64_t offset, std::uint32_t count,
        std::uint32_t stride) = 0;

    virtual void dispatch(const DispatchArguments& arguments) = 0;
    virtual void dispatch_indirect(BufferHandle arguments, std::uint64_t offset) = 0;

    virtual void copy_buffer(BufferHandle source, BufferHandle target, const BufferCopy& region) = 0;
    virtual void copy_texture(TextureHandle source, TextureHandle target, const TextureCopy& region) = 0;
    // Texture nguồn ở bố cục CopySource, texture đích ở CopyDest. Bố cục dữ liệu trong buffer và
    // các điều kiện căn: resolve_copy ở gpu/check.hpp (dòng cách nhau row_bytes, lát và lớp nối
    // liền nhau; định dạng có stencil chưa chép được).
    virtual void copy_buffer_to_texture(BufferHandle source, TextureHandle target,
        std::span<const BufferTextureCopy> regions) = 0;
    virtual void copy_texture_to_buffer(TextureHandle source, BufferHandle target,
        std::span<const BufferTextureCopy> regions) = 0;

    // Vulkan bắt đưa ô truy vấn về trạng thái trống trước khi ghi lại; D3D12 bỏ qua.
    virtual void reset_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) = 0;
    // Dấu thời gian của GPU khi mọi việc trước giai đoạn stage đã xong.
    virtual void write_timestamp(QueryPoolHandle pool, std::uint32_t index, SyncStage stage) = 0;
    // Đếm số mẫu qua được phép thử độ sâu giữa hai lệnh; phải nằm trong begin_rendering.
    virtual void begin_occlusion(QueryPoolHandle pool, std::uint32_t index) = 0;
    virtual void end_occlusion(QueryPoolHandle pool, std::uint32_t index) = 0;
    // Chốt kết quả của các ô để Device::read_queries đọc được sau khi lần nộp chạy xong.
    virtual void resolve_queries(QueryPoolHandle pool, std::uint32_t first, std::uint32_t count) = 0;
};

} // namespace game::gpu
