#pragma once
// Bảng handler viết tay của hội thoại, tra theo (script, num). Handler chỉ dành cho điểm vào mà bộ trích tĩnh KHÔNG dịch được
// thành bước đóng (talk_entries.status = unsupported hoặc no_dialog) và việc đó cần một hệ thống chưa có trong làn của vai MISSION
// (kỹ năng sống, đội, thành phố bang, phụ bản, hiệu ứng): vai sở hữu hệ thống ấy thêm handler vào đây khi hệ thống đã nối.
// Handler KHÔNG được đè điểm vào `ok`: làm vậy là che dữ liệu đã trích bằng mã tay, và audit() báo lỗi.
//
// Hiện bảng rỗng: mọi họ điểm vào chưa trích được đều chờ một hệ thống ngoài làn (đếm theo lý do ở docs/SERVER-MISSION.md), và viết
// handler cho chúng trước khi hệ thống ấy tồn tại là viết mã giả. Cơ chế (khoá cố định, một dòng lý do, audit trên bảng thật,
// talk::Service nhận span) đã chạy và có test; thêm một handler là thêm một dòng vào kSpecs, một ca test và một dòng lý do.

#include "talk/handler.hpp"
#include "talk/script.hpp"

#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace game::handlers {

// Các handler đã đăng ký, sắp tăng theo (script, num), khoá không trùng (static_assert ở registry.cpp).
[[nodiscard]] std::span<const talk::HandlerSpec> registry() noexcept;

struct Problem {
    std::uint32_t script = 0;
    std::int32_t num = -1;
    std::string what;
};

// Kiểm một danh sách handler với chương trình hội thoại đã nạp. Mỗi vấn đề là một câu tiếng Việt:
// - khoá trùng; - thiếu hàm chạy hoặc lý do rỗng; - điểm vào không có trong chương trình; - điểm vào đã `ok` (handler đè dữ liệu trích).
[[nodiscard]] std::vector<Problem> audit(std::span<const talk::HandlerSpec> specs, const talk::Script& script);

}  // namespace game::handlers
