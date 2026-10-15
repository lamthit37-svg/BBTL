/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/handle.hpp
 *  PHÂN HỆ   : Gpu / Handle
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tay nắm tài nguyên GPU: chỉ số kèm thế hệ, mỗi loại tài nguyên một kiểu
 *    riêng — rhi/handle.hpp của Platium. _Ref và Wicked trao con trỏ (Buffer*,
 *    shared_ptr<void>): dùng lại tài nguyên đã huỷ là use-after-free im lặng,
 *    và shared_ptr không trả lời được câu hỏi thật là GPU còn đọc tài nguyên
 *    mấy khung hình sau khi CPU thả nó. Ở đây tay nắm cũ thành một phép so số
 *    nguyên trả false ngay tại chỗ dùng, và truyền BufferHandle vào chỗ chờ
 *    TextureHandle là lỗi dịch.
 *  - Nguồn: Forge2 src/gpu/handle.hpp@d7fcd76. Khác gốc: không.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>

namespace game::gpu {

inline constexpr std::uint32_t kInvalidIndex = ~std::uint32_t{0};

template <class Tag>
struct Handle {
    std::uint32_t index = kInvalidIndex;
    std::uint32_t generation = 0;

    // Đã từng được cấp; không nói tài nguyên còn sống hay không (hỏi Device).
    [[nodiscard]] constexpr bool valid() const noexcept { return index != kInvalidIndex; }
    constexpr explicit operator bool() const noexcept { return valid(); }

    friend constexpr bool operator==(const Handle&, const Handle&) = default;
};

struct BufferTag;
struct TextureTag;
struct TextureViewTag;
struct SamplerTag;
struct ShaderTag;
struct PipelineTag;
struct BindGroupTag;
struct QueryPoolTag;

using BufferHandle = Handle<BufferTag>;
using TextureHandle = Handle<TextureTag>;
using TextureViewHandle = Handle<TextureViewTag>;
using SamplerHandle = Handle<SamplerTag>;
using ShaderHandle = Handle<ShaderTag>;
using PipelineHandle = Handle<PipelineTag>;
using BindGroupHandle = Handle<BindGroupTag>;
using QueryPoolHandle = Handle<QueryPoolTag>;

} // namespace game::gpu
