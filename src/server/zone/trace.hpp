/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/trace.hpp
 *  PHÂN HỆ   : Server / Zone / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Log kiểm theo việc người chơi: mỗi việc một dòng stderr, bật bằng khoá
 *    play_trace ở log.toml. Mô tả dòng và danh sách việc ở
 *    dev/server/README.md.
 *  - Tắt thì mọi hàm trả ngay: không định dạng, không in, không nhớ gì.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Zone là nơi duy nhất ghi: gate chỉ chuyển tin, còn việc đã thành hay bị từ chối chỉ zone biết.
// Tài khoản chỉ là id số; mật khẩu và vé không bao giờ tới zone nên không có đường nào lọt vào
// dòng.

#pragma once

#include "ipc/relay.hpp"
#include "play/stage.hpp"

#include <cstdint>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::zone {

// Chỗ đứng lúc ghi dòng kiểm (centimet). scene = -1: phiên không còn ở cảnh nào.
struct TraceSpot {
    std::int32_t scene = -1;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
};

class Trace {
public:
    Trace(bool on, std::int64_t hz) noexcept : on_(on), hz_(hz) {}

    [[nodiscard]] bool on() const noexcept { return on_; }

    // Vào cảnh (nhớ tài khoản, nhân vật, tên cho các dòng sau) và rời cảnh (quên).
    void enter(std::uint64_t session, const ipc::Attach& arrival, const TraceSpot& spot,
        std::uint32_t tick);
    void leave(std::uint64_t session, const TraceSpot& spot, std::uint32_t tick);
    // Một bước đi được chấp nhận: tối đa một dòng mỗi giây mỗi người.
    void walk(std::uint64_t session, const TraceSpot& spot, std::uint32_t tick);
    // Zone chặn bước tới `refused` và kéo người chơi về `home`.
    void pull(std::uint64_t session, const TraceSpot& refused, const TraceSpot& home,
        std::uint32_t tick);
    // Một việc của gameplay (thành công hay bị từ chối).
    void act(const play::Note& note, const TraceSpot& spot, std::uint32_t tick);

private:
    struct Who {
        std::uint64_t account = 0;
        std::uint64_t character = 0;
        std::string name;
        std::uint32_t walked_at = 0;
        bool walked = false;
    };
    struct Row {
        std::uint32_t tick = 0;
        std::string_view act;
        const Who* who = nullptr;
        TraceSpot spot;
        std::string result;
        std::int64_t value = 0;
    };

    void emit(const Row& row, std::string_view extra) const;

    bool on_;
    std::int64_t hz_;
    std::unordered_map<std::uint64_t, Who> who_;
};

} // namespace game::zone
