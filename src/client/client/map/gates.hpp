// Bảng cổng ScenePosDefineEx của client 2026. Hàm tra ở Game.exe 0x9b8ff0 đổi câu hỏi cảnh 242
// thành 0 rồi so cột cảnh đi và cảnh đến; cùng cảnh thì không có cửa; gặp dòng đầu thì trả toạ độ
// đi dạng float và số nguyên ở cột thứ 9. Điểm đứng khi vào cảnh là toạ độ đến của dòng đó, đổi
// sang thế giới bằng gốc + ô * tỉ lệ (Axis_Trans PLAN sang GFX, chỉ X và Z). Tạo nhân vật nạp
// tl3chuangjian.Scene với id -2. Phông erengu nạp erengu_DL.Scene với id -1 khi biến kiểm tra khác
// 1. Màn loading của bản 2026 là video PlayLoadingVideo, không có toạ độ cảnh.
#pragma once

#include <cstdint>
#include <expected>
#include <span>
#include <string_view>
#include <vector>

namespace game::client::map {

// Scene_Load(-2, "tl3chuangjian.Scene") trong Game.exe 32-bit và 64-bit.
constexpr int kCharacterCreateScene = -2;
constexpr std::string_view kCharacterCreateFile = "tl3chuangjian.Scene";

// Scene_Load(-1, "erengu_DL.Scene") khi biến kiểm tra khác 1.
constexpr int kFactionLoginScene = -1;
constexpr std::string_view kFactionLoginFile = "erengu_DL.Scene";

// Bản sao Lạc Dương. Chỉ câu hỏi bị đổi thành cảnh 0; số ghi trong dòng giữ nguyên.
constexpr int kLuoyangMirror = 242;

enum class [[nodiscard]] GateError : std::uint8_t {
    kBadMagic,
    kBadShape,
};

// Một cổng. field_nine là số hàm tra ghi ra đối số thứ ba. Hai cột sau giữ nguyên byte: hàm tra
// đã dịch không đọc chúng, nên không phải hướng nhìn.
struct Gate {
    int id = 0;
    int source_scene = 0;
    int source_x = 0;
    int source_z = 0;
    int dest_scene = 0;
    int dest_x = 0;
    int dest_z = 0;
    int field_nine = 0;
    int field_ten = 0;
    int field_eleven = 0;
};

// Cặp cảnh của câu hỏi. Gộp để hai int không đứng cạnh nhau trên chữ ký.
struct GateEnds {
    int source_scene = 0;
    int dest_scene = 0;
};

// Cảnh trước và cảnh sắp vào. previous âm nghĩa là chưa có cảnh.
struct SceneStep {
    int previous = -1;
    int scene = 0;
};

// Điểm đứng trong đơn vị game. has sai khi bảng không chốt được một điểm.
struct GateStand {
    float x = 0.0F;
    float z = 0.0F;
    bool has = false;
};

// Ô logic (X, Z) của bảng cổng, đơn vị game.
struct GameCell {
    float x = 0.0F;
    float z = 0.0F;
};

// Gốc và tỉ lệ X, Z của địa hình. Độ cao lấy từ heightmap, không nằm ở đây.
struct PlanFrame {
    float origin_x = 0.0F;
    float origin_z = 0.0F;
    float scale_x = 1.0F;
    float scale_z = 1.0F;
};

// Điểm chân trên mặt phẳng thế giới, centimet của renderer.
struct WorldPoint {
    float x = 0.0F;
    float z = 0.0F;
};

using GateList = std::vector<Gate>;
using GateResult = std::expected<GateList, GateError>;

// Đọc cả tệp DBC; byte thừa sau khối chuỗi vẫn nhận.
[[nodiscard]] GateResult read_gates(std::string_view bytes);

// Dòng khớp đầu tiên sau khi câu hỏi đổi cảnh 242 thành 0; cùng cảnh thì nullptr.
[[nodiscard]] const Gate* find_gate(std::span<const Gate> rows, GateEnds ends) noexcept;

// Điểm đến của cửa thẳng, không có thì điểm đến chung của mọi cửa vào cảnh.
[[nodiscard]] GateStand arrival_at(std::span<const Gate> rows, SceneStep step) noexcept;

// Điểm đến chung của các dòng có cảnh đến đúng bằng scene, không đổi 242.
[[nodiscard]] GateStand entrance_of(std::span<const Gate> rows, int scene) noexcept;

// X và Z thế giới: gốc cộng ô nhân tỉ lệ, không cộng nửa ô.
[[nodiscard]] WorldPoint plan_to_world(PlanFrame frame, GameCell cell) noexcept;

// Câu tiếng Việt ngắn cho log.
[[nodiscard]] std::string_view describe(GateError error) noexcept;

} // namespace game::client::map
