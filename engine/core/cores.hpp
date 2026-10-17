/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/cores.hpp
 *  PHÂN HỆ   : Core / Cores
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Giữ luồng khung hình trên lõi mạnh: Android, Linux ghim vào lớp lõi mạnh
 *    nhất; iOS, macOS xin QoS USER_INTERACTIVE; Windows để Thread Director lo.
 *  - Sức lõi đọc từ cpu_capacity, nhân cũ không có thì cpuinfo_max_freq.
 *  - Chọn lõi (frame_cpus) là hàm thuần để kiểm bằng số liệu giả.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/thread.hpp"

#include <cstdint>
#include <span>
#include <vector>

namespace game::core {

// Sức của từng CPU theo chỉ số CPU, cùng một thước đo cho mọi CPU; 0 là không đọc được (CPU đang
// tắt cả cụm). Ngoài Android và Linux trả rỗng.
[[nodiscard]] std::vector<std::uint64_t> cpu_capacities();

// CPU cho luồng khung hình: lớp mạnh nhất, cộng lớp kế khi lớp ấy chưa đủ hai CPU (lõi prime) để
// luồng không kẹt sau một lõi bận. Rỗng là không ghim: mọi CPU cùng sức, không đọc được, hay tập
// chọn ra gồm mọi CPU đọc được.
[[nodiscard]] CpuSet frame_cpus(std::span<const std::uint64_t> capacity);

// frame_cpus của máy này, đọc một lần.
[[nodiscard]] const CpuSet& fast_cores();

// Xin lõi mạnh cho luồng gọi. Rẻ khi đã đúng, nên gọi lại định kỳ: Android đặt lại affinity mỗi
// lần đưa tiến trình sang cpuset khác (ra nền rồi vào lại). false khi hệ điều hành từ chối.
[[nodiscard]] bool prefer_fast_cores();

} // namespace game::core
