#pragma once
// IID của Direct3D và DXGI lấy từ hằng IID_* của SDK. Không dùng __uuidof.
// Include sau header D3D của tệp .cpp: specialization chỉ hiện khi macro giao diện đã có.
// Khuôn IidOf cố ý không định nghĩa. Thiếu specialization là lỗi dịch, không phải IID rỗng.
#include "core/win32.hpp"

#include <wrl/client.h>

namespace game::gpu {

template <typename T>
struct IidOf;

template <typename T>
[[nodiscard]] const IID& iid_of() noexcept {
    return IidOf<T>::get();
}

template <typename T>
[[nodiscard]] const IID& com_iid(const Microsoft::WRL::ComPtr<T>&) noexcept {
    return iid_of<T>();
}

template <typename T>
[[nodiscard]] const IID& com_iid(T**) noexcept {
    return iid_of<T>();
}

template <typename T>
[[nodiscard]] void** com_pp(Microsoft::WRL::ComPtr<T>& slot) noexcept {
    // T** không đổi được sang void** bằng static_cast. Đây là biên COM.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return reinterpret_cast<void**>(slot.GetAddressOf());
}

template <typename T>
[[nodiscard]] void** com_pp(T** slot) noexcept {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): cùng biên COM với overload trên
    return reinterpret_cast<void**>(slot);
}

#define GAME_GPU_IID(type) \
    template <> \
    struct IidOf<type> { \
        static const IID& get() noexcept { return IID_##type; } \
    };

#if defined(__ID3D10Multithread_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D10Multithread)
#endif
#if defined(__ID3D11ComputeShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11ComputeShader)
#endif
#if defined(__ID3D11DomainShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11DomainShader)
#endif
#if defined(__ID3D11GeometryShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11GeometryShader)
#endif
#if defined(__ID3D11HullShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11HullShader)
#endif
#if defined(__ID3D11InfoQueue_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11InfoQueue)
#endif
#if defined(__ID3D11PixelShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11PixelShader)
#endif
#if defined(__ID3D11Texture2D_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11Texture2D)
#endif
#if defined(__ID3D11VertexShader_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11VertexShader)
#endif
#if defined(__ID3D11Device_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D11Device)
#endif
#if defined(__ID3D12CommandAllocator_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12CommandAllocator)
#endif
#if defined(__ID3D12CommandQueue_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12CommandQueue)
#endif
#if defined(__ID3D12CommandSignature_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12CommandSignature)
#endif
#if defined(__ID3D12Debug_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Debug)
#endif
#if defined(__ID3D12DescriptorHeap_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12DescriptorHeap)
#endif
#if defined(__ID3D12Device_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Device)
#endif
#if defined(__ID3D12Device2_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Device2)
#endif
#if defined(__ID3D12Device10_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Device10)
#endif
#if defined(__ID3D12Fence_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Fence)
#endif
#if defined(__ID3D12GraphicsCommandList7_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12GraphicsCommandList7)
#endif
#if defined(__ID3D12Heap_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Heap)
#endif
#if defined(__ID3D12InfoQueue_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12InfoQueue)
#endif
#if defined(__ID3D12PipelineLibrary_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12PipelineLibrary)
#endif
#if defined(__ID3D12PipelineState_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12PipelineState)
#endif
#if defined(__ID3D12QueryHeap_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12QueryHeap)
#endif
#if defined(__ID3D12Resource_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12Resource)
#endif
#if defined(__ID3D12RootSignature_INTERFACE_DEFINED__)
GAME_GPU_IID(ID3D12RootSignature)
#endif
#if defined(__IDXGIAdapter1_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIAdapter1)
#endif
#if defined(__IDXGIAdapter3_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIAdapter3)
#endif
#if defined(__IDXGIFactory1_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIFactory1)
#endif
#if defined(__IDXGIFactory2_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIFactory2)
#endif
#if defined(__IDXGIFactory4_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIFactory4)
#endif
#if defined(__IDXGIFactory5_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIFactory5)
#endif
#if defined(__IDXGIInfoQueue_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGIInfoQueue)
#endif
#if defined(__IDXGISwapChain3_INTERFACE_DEFINED__)
GAME_GPU_IID(IDXGISwapChain3)
#endif

#undef GAME_GPU_IID

} // namespace game::gpu
