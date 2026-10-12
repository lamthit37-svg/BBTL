// Ảnh của một fake object: mô hình 3D mà nơi vẽ dựng ra texture để giao diện hiện trong cửa sổ
// Falagard/MeshWindow (đầu nhân vật ở ô chân dung). Nơi vẽ đăng ký texture với render::UiPass rồi
// đưa tên và chỉ số của nó cho HUD mỗi khung.
#pragma once

#include "render/ui.hpp"
#include "ui/panel/player_frame.hpp"

#include <cstdint>
#include <string_view>

namespace game::ui {

// Tên fake object của đầu người chơi mà khung nhân vật chờ.
inline constexpr std::string_view kPlayerHead = panel::kPlayerHead;

struct ViewPaint {
    // Tên fake object, như đối số của SetFakeObject ở script gốc ("Player_Head").
    std::string_view name;
    // Chỉ số texture trong UiPass.
    std::uint32_t texture = render::kUiWhite;
    // Hàng đầu của texture là hàng dưới cùng của hình (ảnh vẽ ra texture trên OpenGL): bộ vẽ lật
    // trục v.
    bool is_bottom_up = false;
};

} // namespace game::ui
