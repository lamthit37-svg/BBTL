// Truy vấn mặt công trình sau khi nạp .WCollision. height bắn tia từ y = 10000 thẳng xuống.
// raycast giữ mặt gần nhất, không loại mặt sau. Tệp rỗng nạp được và mọi truy vấn trượt.
// Model giữ lưới và cây; bộ đệm tệp được giải phóng ngay sau load.
#pragma once

#include "collision/building_file.hpp"

#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <span>

namespace game::collision {

struct Hit {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
};

struct Aabb {
    float min_x = 0.0F;
    float min_y = 0.0F;
    float min_z = 0.0F;
    float max_x = 0.0F;
    float max_y = 0.0F;
    float max_z = 0.0F;
};

class Model {
public:
    Model() = default;
    Model(Model&&) noexcept;
    Model& operator=(Model&&) noexcept;
    Model(const Model&) = delete;
    Model& operator=(const Model&) = delete;
    ~Model();

    // Độ cao mặt trên cùng tại (x, z), đơn vị game. Trượt thì nullopt.
    [[nodiscard]] std::optional<float> height(float x, float z) const noexcept;
    [[nodiscard]] std::optional<Hit> raycast(std::span<const float, 3> origin,
        std::span<const float, 3> direction) const noexcept;
    [[nodiscard]] Aabb bounds() const noexcept;

private:
    struct Body;
    explicit Model(std::unique_ptr<Body> body) noexcept;
    std::unique_ptr<Body> body_;
    friend std::expected<Model, LoadError> load(std::span<const std::byte> data);
};

// Nạp cả hai mã. Lưới hay cây vượt trần trả kTooLarge. Tệp rỗng cho model mà mọi tia đều trượt.
[[nodiscard]] std::expected<Model, LoadError> load(std::span<const std::byte> data);

} // namespace game::collision
