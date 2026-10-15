// Màn của host (ui::script::Screen) trên giao diện thật của client: nạp layout vào gui::GuiLoader, hỏi vị trí cửa sổ ở
// gui::Hub theo lần dàn trang gần nhất. HUD giữ GuiLoader và Hub; lớp này chỉ mượn con trỏ.
// Hub dựng từ asset lúc đó nên không biết cửa sổ của layout nạp sau: load_layout nạp thêm layout thì đánh dấu, chủ của Hub
// hỏi take_grown() mỗi khung rồi dựng lại Hub và bind lại.
// Một luồng, như Host. Thuần logic, không đụng GPU.
#pragma once

#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "ui/script/host.hpp"

#include <expected>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::script {

class GuiScreen final : public Screen {
public:
    // loader phải sống lâu hơn GuiScreen và không bị di chuyển.
    explicit GuiScreen(gui::GuiLoader& loader) noexcept : loader_(&loader) {}

    // Hub để hỏi toạ độ; nullptr thì offset và hits trả "không biết" (nullopt, false).
    void bind(const gui::Hub* hub) noexcept { hub_ = hub; }
    // true khi load_layout đã nạp thêm layout kể từ lần gọi trước: Hub cũ chưa biết cửa sổ mới, chủ phải dựng lại.
    [[nodiscard]] bool take_grown() noexcept;

    [[nodiscard]] std::expected<gui::GuiRange, std::string> load_layout(std::string_view layout) override;
    [[nodiscard]] const gui::GuiAsset& asset() const noexcept override { return loader_->asset(); }
    [[nodiscard]] std::optional<Spot> offset(std::string_view window, std::string_view root) const override;
    [[nodiscard]] bool hits(std::string_view window, Spot spot) const override;

private:
    gui::GuiLoader* loader_;
    const gui::Hub* hub_ = nullptr;
    bool is_grown_ = false;
};

} // namespace game::ui::script
