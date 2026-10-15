// Ảnh bộ nhớ của CDataPool (DAT_141034c40 của Game.exe 2026) cho các hàm Lua chỉ đọc một trường số của nó (native_pool.cpp, sinh bằng
// TOOLS/port/luagen/gen_pool_natives.py). Gốc đọc thẳng byte ở offset của kho dữ liệu máy chủ cấp; client này chưa có kho đó, nên một
// trường có giá trị là: giá trị phía mạng đã ghi theo offset, không thì giá trị mà hàm dựng CDataPool đặt (bảng PoolInitial do bộ sinh
// kèm theo), không thì 0.
#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <span>

namespace game::ui::script {

// Độ rộng và dấu của một lần đọc, đúng kiểu mà hàm gốc ép con trỏ (int, uint, short, ushort, byte, char).
enum class Width : std::uint8_t { kI8, kU8, kI16, kU16, kI32, kU32 };

struct PoolField {
    std::uint32_t offset = 0;
    Width width = Width::kI32;
};

// Giá trị đầu của một trường theo hàm dựng; trường vắng trong bảng là 0.
struct PoolInitial {
    std::uint32_t offset;
    Width width;
    std::int64_t value;
};

class PoolImage {
public:
    // Trần số trường được ghi đè: offset hợp lệ của CDataPool chỉ vài nghìn trường được đọc, quá trần thì bỏ lần ghi mới.
    static constexpr std::size_t kLimit = 4096;

    // Phía mạng ghi một trường (giá trị thô; lúc đọc sẽ bị cắt theo độ rộng như bộ nhớ). false khi quá kLimit trường khác nhau.
    bool write(std::uint32_t offset, std::int64_t value);

    // Giá trị của trường theo độ rộng và dấu của field: ghi đè nếu có, không thì dòng khớp (offset, độ rộng) của initial, không thì 0.
    // Độ phức tạp O(log n + initial.size()); initial do bộ sinh kèm theo (vài trăm dòng).
    [[nodiscard]] std::int64_t read(PoolField field, std::span<const PoolInitial> initial) const noexcept;

private:
    std::map<std::uint32_t, std::int64_t> values_;
};

} // namespace game::ui::script
