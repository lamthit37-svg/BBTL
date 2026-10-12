// Con trỏ chuột của client 2026: 23 loại theo thứ tự LoadCursorA của CCursorMng::Initial, và luật
// chọn con trỏ của một khung (ProcessInput_Mouse, MouseCommand_Set, GetCursor). Các chế độ sửa,
// giám định, kết bạn, giao dịch chưa có đường nào bật.
// Nguồn: TLBB Dev src/control/cursor_rules.hpp và cursor_rules.cpp@e0d89a6. Khác gốc: namespace
// game::control; enumerator mang tiền tố k. Tên tệp và thứ tự loại giữ nguyên.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::control {

enum class CursorKind : std::uint8_t {
    kSystem,
    kNormal,
    kNormalDown,
    kAttack,
    kAutoRun,
    kPickUp,
    kUnreachable,
    kMine,
    kHerbs,
    kFish,
    kSpeak,
    kInteract,
    kRepair,
    kHover,
    kIdentify,
    kAddFriend,
    kExchange,
    kCatchPet,
    kScroll,
    kCabinet,
    kHouse,
    kBow,
    kBowDown,
};

inline constexpr std::size_t kCursorKinds = 23;

// Tên sạch của từng loại theo thứ tự CursorKind. kSystem là mũi tên hệ thống, không có tệp.
inline constexpr std::array<std::string_view, kCursorKinds> kCursorNames = {"system", "normal", "normal_down", "attack",
    "auto_run", "pick_up", "unreachable", "mine", "herbs", "fish", "speak", "interact", "repair", "hover", "identify",
    "add_friend", "exchange", "catch_pet", "scroll", "cabinet", "house", "bow", "bow_down"};

// Tên sạch của loại; chỉ số hỏng thì ném.
[[nodiscard]] std::string_view cursor_name(CursorKind kind);

// Loại theo tên sạch; tên lạ thì nullopt.
[[nodiscard]] std::optional<CursorKind> cursor_named(std::string_view name);

// Thứ dưới chuột mà con trỏ quan tâm, theo lớp chọn của Find_HitWXObject.
enum class HoverKind : std::uint8_t { kNpc, kMonster, kOtherPlayer, kMyself, kPet };

// Trạng thái chuột của một khung.
struct CursorState {
    // Chuột trên cửa sổ giao diện không rỗng (CUISystem::IsMouseHover).
    bool over_ui = false;
    std::optional<HoverKind> hover;
    // Đang tự chạy theo chuột (Pilot::auto_run).
    bool auto_run = false;
    // Nút chính đang giữ: bản 2026 đổi con trỏ thường sang con trỏ đang nhấn.
    bool primary_down = false;
    // Đang kéo camera (Pilot::holds_cursor): nút phải đã kéo quá ngưỡng, hoặc nút giữa đang giữ.
    // Con trỏ ẩn.
    bool camera_held = false;
};

// Con trỏ của khung; nullopt là ẩn.
[[nodiscard]] std::optional<CursorKind> choose_cursor(const CursorState& state);

} // namespace game::control
