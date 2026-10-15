/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/barrier.hpp
 *  PHÂN HỆ   : Gpu / Barrier
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Rào đồng bộ: giai đoạn đường ống, kiểu truy cập, bố cục ảnh —
 *    rhi/barrier.hpp của Platium, thay ResourceState và cmdResourceBarrier của
 *    _Ref. Gốc dùng một enum trạng thái gộp (kiểu D3D12_RESOURCE_STATES cũ) rồi
 *    backend Vulkan phải suy ngược ra stage và access bằng bảng. Ba trục ở đây
 *    là đúng hình dạng mà synchronization2 của Vulkan và Enhanced Barriers của
 *    D3D12 cùng có, nên hai backend ánh xạ thẳng, không máy trạng thái. Tầng
 *    này không tự theo dõi trạng thái tài nguyên: chỗ gọi (render graph) biết
 *    trước và sau, và theo dõi ngầm là thứ che lỗi thứ tự pass.
 *  - Nguồn: Forge2 src/gpu/barrier.hpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/handle.hpp"
#include "gpu/types.hpp"

#include <cstdint>

namespace game::gpu {

// Ánh xạ: VkPipelineStageFlags2 và D3D12_BARRIER_SYNC.
enum class SyncStage : std::uint32_t {
    kNone = 0,
    kDrawIndirect = 1U << 0U,
    // Nạp đỉnh và chỉ số, khác giai đoạn chạy vertex shader: Vulkan chỉ nhận truy cập đọc đỉnh ở
    // giai đoạn này.
    kVertexInput = 1U << 1U,
    kVertexShader = 1U << 2U,
    kPixelShader = 1U << 3U,
    kComputeShader = 1U << 4U,
    kEarlyDepth = 1U << 5U,
    kLateDepth = 1U << 6U,
    kColorOutput = 1U << 7U,
    kCopy = 1U << 8U,
    kResolve = 1U << 9U,
    // Mọi giai đoạn: đúng nhưng chậm; dùng lúc dựng, không dùng trên đường nóng.
    kAll = 1U << 31U,
};

template <>
inline constexpr bool kIsFlags<SyncStage> = true;

// Ánh xạ: VkAccessFlags2 và D3D12_BARRIER_ACCESS.
// Giữ kiểu nền của gốc: cùng độ rộng với SyncStage đi cặp trong mọi rào (lệch KG-06).
// NOLINTNEXTLINE(performance-enum-size)
enum class Access : std::uint32_t {
    kNone = 0,
    kIndirectRead = 1U << 0U,
    kIndexRead = 1U << 1U,
    kVertexRead = 1U << 2U,
    kUniformRead = 1U << 3U,
    kShaderRead = 1U << 4U,
    kShaderWrite = 1U << 5U,
    kColorRead = 1U << 6U,
    kColorWrite = 1U << 7U,
    kDepthRead = 1U << 8U,
    kDepthWrite = 1U << 9U,
    kCopyRead = 1U << 10U,
    kCopyWrite = 1U << 11U,
    kResolveRead = 1U << 12U,
    kResolveWrite = 1U << 13U,
};

template <>
inline constexpr bool kIsFlags<Access> = true;

// Ánh xạ: VkImageLayout và D3D12_BARRIER_LAYOUT. D3D12 có thêm biến thể theo loại hàng đợi; backend
// tự chọn theo hàng đợi của command list đang ghi.
enum class TextureLayout : std::uint8_t {
    kUndefined,
    // Dùng được cho mọi việc, chậm hơn bố cục chuyên; bắt buộc cho RWTexture.
    kGeneral,
    kColorTarget,
    kDepthWrite,
    // Attachment độ sâu chỉ đọc. Cũng là bố cục để shader lấy mẫu một texture có định dạng độ sâu:
    // texture độ sâu không dùng ShaderRead.
    kDepthRead,
    kShaderRead,
    kCopySource,
    kCopyDest,
    kResolveSource,
    kResolveDest,
    kPresent,
};

// Chuyển quyền dùng giữa hai hàng đợi. Vulkan bắt buộc khi tài nguyên tạo ở chế độ độc quyền (mặc
// định, vì chế độ dùng chung tắt nén màu của đích vẽ trên AMD và Intel); D3D12 bỏ qua.
struct QueueTransfer {
    QueueType from = QueueType::kGraphics;
    QueueType to = QueueType::kGraphics;
    bool is_active = false;
};

struct BufferBarrier {
    BufferHandle buffer{};
    SyncStage stage_before = SyncStage::kAll;
    SyncStage stage_after = SyncStage::kAll;
    Access access_before = Access::kNone;
    Access access_after = Access::kNone;
    QueueTransfer queue{};
};

// Mặc định của mip_count và layer_count là tất cả: rào quên hai trường này mà chỉ chuyển mức 0 thì
// chương trình vẫn chạy, chỉ lớp kiểm tra kêu.
struct TextureBarrier {
    TextureHandle texture{};
    SyncStage stage_before = SyncStage::kAll;
    SyncStage stage_after = SyncStage::kAll;
    Access access_before = Access::kNone;
    Access access_after = Access::kNone;
    TextureLayout layout_before = TextureLayout::kUndefined;
    TextureLayout layout_after = TextureLayout::kUndefined;
    std::uint32_t first_mip = 0;
    std::uint32_t mip_count = kAllMips;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = kAllLayers;
    QueueTransfer queue{};
};

// Rào không gắn với tài nguyên nào và không đổi bố cục, cho tài nguyên vừa ghi xong được đọc ngay
// (UAV dùng lại). Không đặt tên MemoryBarrier: winnt.h định nghĩa tên ấy thành macro.
struct GlobalBarrier {
    SyncStage stage_before = SyncStage::kAll;
    SyncStage stage_after = SyncStage::kAll;
    Access access_before = Access::kNone;
    Access access_after = Access::kNone;
};

} // namespace game::gpu
