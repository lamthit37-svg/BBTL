#pragma once
// Bộ ngẫu nhiên tất định của logic game (cpp23 MMO-17): xoshiro256** hạt giống bằng splitmix64, không
// dùng <random> vì phân phối của thư viện chuẩn khác nhau giữa các bản cài đặt nên cùng hạt giống ra
// khác kết quả. Mỗi nguồn ngẫu nhiên có chủ riêng (cảnh, nhân vật, hệ), hạt giống ghi được để phát lại.
//
// Nguồn: TLBB Dev src/dice. Khác gốc: thêm chance_permille và pick_weighted cho bảng xác suất nguyên
// của máy chủ (mọi xác suất của luật chơi là số nguyên phần nghìn hoặc phần triệu, KE-HOACH-SERVER mục 1).

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::dice {

class Dice {
public:
    explicit Dice(std::uint64_t seed) noexcept;

    [[nodiscard]] std::uint64_t next_u64() noexcept;

    // Đều trong [0, bound), không lệch (loại mẫu thừa). bound 0 trả 0.
    [[nodiscard]] std::uint64_t below(std::uint64_t bound) noexcept;

    // Đều trong [low, high] gồm cả hai đầu; low > high thì đổi chỗ.
    [[nodiscard]] std::int64_t between(std::int64_t low, std::int64_t high) noexcept;

    // Đúng với xác suất permille/1000. Từ 1000 trở lên luôn đúng, 0 luôn sai.
    [[nodiscard]] bool chance_permille(std::uint32_t permille) noexcept;

    // Như trên nhưng theo phần triệu, cho bảng xác suất mịn của bản gốc.
    [[nodiscard]] bool chance_ppm(std::uint32_t ppm) noexcept;

    // Chọn chỉ số theo trọng số nguyên. Rỗng hoặc tổng bằng 0 thì nullopt. Tổng cộng bằng u64, tràn
    // thì nullopt (trọng số do dữ liệu đưa vào, không tin).
    [[nodiscard]] std::optional<std::size_t> pick_weighted(std::span<const std::uint32_t> weights) noexcept;

    // Trạng thái để ghi nhật ký phát lại.
    [[nodiscard]] std::array<std::uint64_t, 4> state() const noexcept { return state_; }

private:
    std::array<std::uint64_t, 4> state_{};
};

} // namespace game::dice
