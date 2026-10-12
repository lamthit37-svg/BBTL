#include "window/aspect.hpp"

namespace game::window {

// Cài đặt tạm để test đỏ trước: chưa chỉnh gì.
Rect fit_aspect(const AspectFit& fit) noexcept {
    return fit.proposed;
}

} // namespace game::window
