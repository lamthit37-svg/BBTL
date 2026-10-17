/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/ogre_program.hpp
 *  PHÂN HỆ   : Resource / Ogre Program
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc Material/programs.tsv (TOOLS/content/export_material_programs.py):
 *    luồng sáng, viền sáng và pass ghi depth của chất liệu nhân vật client 2026
 *    mà bộ đọc all.material từng dòng không thấy. Logic thuần, không I/O.
 *  - Dòng sai là lỗi kèm số dòng: bảng do công cụ sinh, sai là công cụ hỏng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/error.hpp"
#include "resource/model.hpp"

#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::resource {

// Một chất liệu của bảng, đã diễn giải theo pass hiện màu của nó. Khe ảnh của flow còn trống: tên
// ảnh nằm ở ba trường dưới, tính từ thư mục Material/, UTF-8; rỗng là không có ảnh.
struct ProgramLook {
    Flow flow;
    std::string ctl;
    std::string flow_map;
    std::string outline_map;
    Alpha alpha = Alpha::kOpaque;
    // Ngưỡng cắt của alpha_rejection pass hiện màu; 0 là không cắt.
    float cutoff = 0.0F;
    // cull_hardware của pass hiện màu; không khai thì giữ thiết lập đã có.
    std::optional<bool> double_sided;
    std::optional<float> depth_prepass;
};

// Khoá là tên chất liệu UTF-8.
using ProgramTable = std::unordered_map<std::string, ProgramLook>;

[[nodiscard]] core::Result<ProgramTable> parse_programs(std::string_view text);

// Ngưỡng cắt của "greater N" và "greater_equal N" theo cùng phép làm tròn với bộ đọc all.material;
// nullopt khi chuỗi không phải hai dạng ấy.
[[nodiscard]] std::optional<float> rejection_cutoff(std::string_view text);

} // namespace game::resource
