/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/saver.hpp
 *  PHÂN HỆ   : Server / Zone / Saver
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Luồng ghi điểm đứng của người chơi vào store. Tick của zone không được chờ
 *    một lời gọi mạng, nên mọi lần ghi đi qua đây: tick đẩy vào bảng chờ, một
 *    luồng riêng gửi từng cái.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Bảng chờ khoá theo nhân vật: nhiều lần ghi của cùng một nhân vật gộp thành lần mới nhất, nên bộ nhớ bị chặn
// bởi số nhân vật chứ không bởi thời gian store ngừng. Gửi hỏng (store chưa lên, mạng đứt) thì giữ lại và
// thử sau; lần ghi mới hơn của cùng nhân vật thay lần cũ đang chờ.
//
// Huỷ đối tượng là dừng êm: luồng cố gửi nốt phần còn lại tới hạn kFlushWait rồi bỏ phần chưa gửi được (nói ra
// stderr) — dừng zone không được kẹt vì store chết.

#pragma once

#include "zone/outbox.hpp"

#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <mutex>
#include <thread>

namespace game::zone {

class Saver {
public:
    // Gửi một lần ghi tới store; true khi store đã ghi. Chạy trên luồng của Saver.
    using Send = std::function<bool(const Save&)>;

    static constexpr std::chrono::milliseconds kRetryWait{500};
    static constexpr std::chrono::milliseconds kFlushWait{5000};

    struct Waits {
        std::chrono::milliseconds retry = kRetryWait;
        std::chrono::milliseconds flush = kFlushWait;
    };

    // Hai hàm dựng thay vì đối số mặc định: Clang không cho NSDMI của Waits dùng làm đối số mặc định ngay trong lớp bao.
    explicit Saver(Send send);
    Saver(Send send, Waits waits);
    ~Saver();
    Saver(const Saver&) = delete;
    Saver& operator=(const Saver&) = delete;
    Saver(Saver&&) = delete;
    Saver& operator=(Saver&&) = delete;

    void push(const Save& spot);
    [[nodiscard]] std::size_t pending() const;
    // Số lần gửi hỏng từ lúc dựng (để test và để báo số đo).
    [[nodiscard]] std::uint64_t failures() const;
    // Số lần ghi đã được store nhận.
    [[nodiscard]] std::uint64_t saved() const;

private:
    void run(const std::stop_token& stop);

    Send send_;
    Waits waits_;
    mutable std::mutex lock_;
    std::condition_variable_any wake_;
    std::map<std::uint64_t, Save> waiting_;
    std::uint64_t failures_ = 0;
    std::uint64_t saved_ = 0;
    std::jthread thread_;
};

} // namespace game::zone
