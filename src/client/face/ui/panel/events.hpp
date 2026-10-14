// Sự kiện giao diện mà game đẩy vào script của từng cửa sổ (<Cửa sổ>_OnEvent) và bảng đăng ký sự kiện của
// <Cửa sổ>_PreLoad. Hành vi đọc từ UI_CEGUI.dll 3.71.9509:
//  - RegisterEvent(tên[, cờ]) (0x180077be0): cờ là đối số boolean thứ hai, mặc định true khi không nêu; chỉ
//    gọi được trong PreLoad. Bộ gửi (0x180079310) bỏ sự kiện đã đăng ký với cờ false khi cửa sổ đang ẩn,
//    nên cờ true là "nhận cả lúc ẩn".
//  - Bộ gửi sự kiện (0x18007b8e0): mỗi đối số thứ k (chuỗi) vào biến toàn cục arg<k> và eventTable[k + 1],
//    đối số rỗng thành chuỗi rỗng, rồi gọi <Cửa sổ>_OnEvent("<tên sự kiện>"). Các biến này dùng chung cho mọi
//    cửa sổ (một máy Lua) và KHÔNG được xoá giữa hai sự kiện: sự kiện mang ít đối số hơn lần trước thì script
//    đọc arg<k> thấy giá trị cũ. EventArgs giữ đúng kho đó.
// Thuần logic, không đụng GPU.
#pragma once

#include <cstddef>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Một sự kiện cùng kho đối số lúc script chạy: arg(k) là arg<k>, nullopt khi chưa sự kiện nào đặt arg<k> (nil).
// Trỏ vào kho của EventArgs nên chỉ đúng tới lần raise kế tiếp.
struct UiEvent {
    std::string_view name;
    std::span<const std::string> values;

    // arg<index>.
    [[nodiscard]] std::optional<std::string_view> arg(std::size_t index) const noexcept {
        if (index >= values.size()) return std::nullopt;
        return std::string_view(values[index]);
    }
    // eventTable[position] (từ 1): cùng kho với arg, lệch một.
    [[nodiscard]] std::optional<std::string_view> table(std::size_t position) const noexcept {
        if (position == 0) return std::nullopt;
        return arg(position - 1);
    }
};

// Kho arg<k> / eventTable dùng chung của mọi cửa sổ.
class EventArgs {
public:
    // Đặt arg<k> cho k < args.size() (các k lớn hơn giữ giá trị cũ) rồi trả sự kiện để đưa cho OnEvent.
    [[nodiscard]] UiEvent raise(std::string_view name, std::span<const std::string_view> args) {
        if (values_.size() < args.size()) values_.resize(args.size());
        for (std::size_t index = 0; index < args.size(); ++index)
            values_[index] = std::string(args[index]);
        return UiEvent{.name = name, .values = values_};
    }

private:
    std::vector<std::string> values_;
};

// Một dòng đăng ký của PreLoad: tên sự kiện và cờ (xem đầu tệp).
struct EventSub {
    std::string_view name;
    bool is_always = true;
};

// Cửa sổ có nhận sự kiện này không, theo bảng đăng ký của nó và cờ hiện của nó (0x180079310).
[[nodiscard]] constexpr bool is_delivered(std::span<const EventSub> subs, std::string_view name, bool is_shown) noexcept {
    for (const EventSub& sub : subs) {
        if (sub.name == name) return sub.is_always || is_shown;
    }
    return false;
}

// Sự kiện giữ chuỗi riêng, cho nơi xếp hàng sự kiện qua nhiều khung (công cụ thử --ui-event, về sau là gói
// tin của máy chủ).
struct PostedEvent {
    std::string name;
    std::vector<std::string> args;

    // Cùng tên và cùng mọi đối số (EventQueue bỏ sự kiện lặp trong một khung).
    [[nodiscard]] bool operator==(const PostedEvent&) const = default;

    // "TÊN|arg0|arg1|...": số đối số tuỳ ý, mỗi đối số là chuỗi (đối số rỗng là chuỗi rỗng như bộ gửi gốc).
    // Tên rỗng thì không có kết quả.
    [[nodiscard]] static std::optional<PostedEvent> parse(std::string_view text);
    // Các đối số dạng mượn chuỗi, để đưa cho EventArgs::raise; còn đúng tới khi sự kiện bị đổi hay huỷ.
    [[nodiscard]] std::vector<std::string_view> arguments() const;
};

} // namespace game::ui::panel
