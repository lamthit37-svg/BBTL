/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/script.hpp
 *  PHÂN HỆ   : Client / Display / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kịch bản E2E của client (--script): đọc tệp văn bản thành danh sách bước
 *    để luồng vẽ chạy từng bước mỗi khung. Công cụ thử của dự án, client gốc
 *    không có; không bao giờ hiện trong giao diện người chơi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mỗi dòng một bước: "lệnh đối-số". Dòng trống và dòng bắt đầu bằng # bị bỏ (dòng #! là chỉ dẫn cho
// TOOLS/run/e2e_client.py, client coi như chú thích). Sai cú pháp thì cả kịch bản bị từ chối kèm số
// dòng, để client không chạy nửa chừng một kịch bản hỏng.

#pragma once

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::client {

enum class StepKind : std::uint8_t {
    kWait,
    kWaitSeconds,
    kWaitPlay,
    kShot,
    kEvent,
    kClick,
    kType,
    kWalk,
    kTalk,
    kChoose,
    kCast,
    kPick,
    kQuit,
};

// Một toạ độ của bước walk: mét của game, tuyệt đối hay cộng dồn từ chỗ đứng. Hai toạ độ của một
// bước luôn cùng kiểu (bộ đọc: có dấu ở một số thì cả cặp cộng dồn).
struct Coord {
    float value = 0.0F;
    bool is_relative = false;
};

struct Step {
    StepKind kind = StepKind::kQuit;
    // Dòng trong tệp (từ 1), cho thông báo và dòng SCRIPT.
    std::uint32_t line = 0;
    // Tên ảnh (shot), chuỗi sự kiện (event), tên cửa sổ (click), chữ gõ (type), id hay tên NPC
    // (talk).
    std::string text;
    // Số khung (wait), giây (wait Ns, wait play), thứ tự từ 1 (choose, cast).
    double amount = 0.0;
    Coord x;
    Coord z;
};

// Kết quả một lần chạy bước: chưa xong (khung sau chạy tiếp), xong, hay hỏng. note là câu cho dòng
// SCRIPT.
enum class StepFlow : std::uint8_t { kPending, kDone, kFailed };

struct StepOutcome {
    StepFlow flow = StepFlow::kPending;
    std::string note;
};

using ScriptSteps = std::vector<Step>;
using ScriptResult = std::expected<ScriptSteps, std::string>;

// Đọc cả tệp; lỗi là một câu có số dòng. Tệp không có bước nào là hợp lệ.
[[nodiscard]] ScriptResult parse_script(std::string_view text);

// Tên lệnh của bước, như trong tệp kịch bản.
[[nodiscard]] std::string_view name_of(StepKind kind) noexcept;

} // namespace game::client
