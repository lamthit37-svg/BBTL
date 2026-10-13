// Giá trị riêng của từng luồng cho kiểu có destructor (bộ đệm std::string, handle RAII).
// Biến thread_local thường là đủ ở MSVC, Clang và mọi nền POSIX. GCC MinGW bản luồng POSIX thì
// không: nó dùng TLS giả lập và trả bộ nhớ của biến thread_local trước khi chạy destructor của
// biến đó, nên luồng tạo bằng std::thread hay std::jthread thoát là destructor đọc vùng nhớ đã trả
// và thỉnh thoảng làm hỏng heap (0xC0000374; số đo và backtrace ở docs/NGHI-NGO.md mục 12). Ở
// toolchain đó thread_slot để giá trị trên heap, giữ bằng một con trỏ thread_local không có
// destructor, và không bao giờ trả nó: rò một giá trị mỗi luồng thay cho hỏng heap. Bản GCC MinGW
// chỉ để kiểm chéo, không phát hành; các toolchain khác vẫn huỷ giá trị khi luồng kết thúc.
// Mã cần biến thread_local có destructor thì gọi thread_slot; kiểu không có destructor (số, con
// trỏ không sở hữu, std::array) cứ khai thread_local thẳng.
#pragma once

#include <concepts>
#include <type_traits>

namespace game::core {

// Luồng kết thúc thì giá trị của thread_slot có được huỷ không.
#if defined(__MINGW32__) && !defined(__clang__)
inline constexpr bool kThreadExitDestroys = false;
#else
inline constexpr bool kThreadExitDestroys = true;
#endif

// Giá trị của luồng gọi cho ô này, dựng bằng make() ở lần đầu luồng tới đây. Mỗi kiểu Make là một
// ô riêng, nên mỗi nơi dùng truyền lambda của chính nó (hai lambda không bao giờ cùng kiểu).
template <std::invocable Make>
[[nodiscard]] std::invoke_result_t<Make>& thread_slot(Make make) {
    using Value = std::invoke_result_t<Make>;
    if constexpr (kThreadExitDestroys) {
        // Huỷ giá trị khi luồng kết thúc là hợp đồng của nhánh này (đầu tệp), nên -Wexit-time-destructors
        // báo nhầm ở đây. Tái hiện: clang++ 23.1.2 -Werror -Wexit-time-destructors dịch clock.cpp.
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wexit-time-destructors"
#endif
        thread_local Value value = make();
#if defined(__clang__)
#pragma clang diagnostic pop
#endif
        return value;
    } else {
        // NOLINTNEXTLINE(cppcoreguidelines-owning-memory): cố ý không trả, lý do ở đầu tệp (SH-01).
        thread_local auto* const kValue = new Value(make());
        return *kValue;
    }
}

} // namespace game::core
