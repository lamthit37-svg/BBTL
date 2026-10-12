// Bộ đếm cấp phát của probe R (P2 đợt 2, mục 6): operator new toàn cục thay thế, đếm khi bật.
#pragma once

#include <cstddef>

namespace probe {

struct Counter {
    std::size_t count = 0;
    std::size_t bytes = 0;
    std::size_t largest = 0;
    bool on = false;
};

extern Counter g_counter;

// Cách đếm đang dùng, in ở đầu log.
const char* counter_mode();

inline void reset() noexcept {
    g_counter = Counter{};
    g_counter.on = true;
}

inline Counter stop() noexcept {
    Counter copy = g_counter;
    copy.on = false;
    g_counter.on = false;
    return copy;
}

} // namespace probe