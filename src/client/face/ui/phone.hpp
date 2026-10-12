// Android và iOS dùng chung một bộ layout. PC không bật cờ này.
#pragma once

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

namespace game::ui {

#if defined(__ANDROID__)
inline constexpr bool kPhone = true;
#elif defined(__APPLE__)
inline constexpr bool kPhone = TARGET_OS_IPHONE != 0;
#else
inline constexpr bool kPhone = false;
#endif

} // namespace game::ui
