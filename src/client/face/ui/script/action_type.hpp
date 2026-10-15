// Mã loại của CActionSystem (Game.exe 2026): hàm dựng 0x14002c290 điền map tên -> mã ở this + 0xf8, GetActionNum (0x140234160) tra
// tên ở đó. Bảng sinh ở action_type.cpp (TOOLS/port/luagen/gen_action_types.py).
#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::script {

// Mã lớn nhất trong bảng + 1 ("cangpin_qual_reset" = 203); action_type.cpp kiểm khớp bằng static_assert.
inline constexpr std::size_t kActionTypeLimit = 204;
// "packageitem": GetActionNum của loại này trả cỡ túi cố định 240 thay vì đếm (0x140017190).
inline constexpr std::int32_t kPackageItemType = 3;
inline constexpr std::int32_t kPackageItemCount = 0xf0;

// Mã loại của tên, so khớp đúng từng byte (std::map<std::string, int> của gốc); nullopt khi không có tên đó (gốc trả 0).
[[nodiscard]] std::optional<std::int32_t> action_type_of(std::string_view name) noexcept;

} // namespace game::ui::script
