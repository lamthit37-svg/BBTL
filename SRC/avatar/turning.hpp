#pragma once
// Hướng mặt vẽ ra xoay dần tới hướng logic, để đổi hướng không quay ngoắt trong một khung. Client
// ref đặt hướng tức thì (CObject::SetFaceDir, CRFObj_Actor::SetOrientation), nhưng ref lái bằng
// chuột đổi hướng mỗi khung nên mỗi bước quay nhỏ; ở đây lệnh đi được lọc nên phải làm mượt ở khâu
// vẽ. Lệch có chủ đích theo yêu cầu "cực mượt" của người dùng TLBB.
// Mỗi khung tiến 1 − e^(−dt / kTurnTime) phần góc còn lại theo cung ngắn nhất: không vượt quá đích,
// không phụ thuộc tốc độ khung. Đối tượng mới thấy lấy thẳng hướng logic. Logic thuần, thời gian do
// bên gọi truyền.
// Nguồn: TLBB Dev src/client_app/turning.hpp@e0d89a6. Khác gốc: namespace game::avatar; id đối
// tượng là số nguyên không dấu; core::Clock.

#include "core/clock.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <unordered_map>

namespace game::avatar {

// Sau chừng này còn 1/e góc phải quay; quay 90 độ xong 95 % sau khoảng ba lần chừng này (sáu khung
// ở 60 Hz). Dài hơn thì thân nhân vật lệch hướng đi đủ lâu để trông như trượt ngang.
inline constexpr std::chrono::milliseconds kTurnTime{35};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
class Turning {
public:
    // Hướng vẽ của id ở khung now khi hướng logic là target, radian trong (−π, π]. Gọi mỗi khung
    // cho mỗi đối tượng đang vẽ.
    [[nodiscard]] float face(std::uint32_t id, float target, core::Clock::time_point now);
    // Bỏ đối tượng không được gọi face từ lần bỏ trước (đã rời vùng nhìn); gọi một lần mỗi khung.
    void drop_unseen();
    [[nodiscard]] std::size_t size() const { return turns_.size(); }

private:
    struct Turn {
        float angle = 0.0F;
        core::Clock::time_point at;
        bool is_seen = false;
    };

    std::unordered_map<std::uint32_t, Turn> turns_;
};

} // namespace game::avatar
