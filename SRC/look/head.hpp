#pragma once
// Cách đặt camera của ảnh đầu 3D (ô chân dung) theo từng mô hình, như client 2026. Đường đi gốc:
// script gọi SetFakeObject(tên) rồi Character:AdjustHeadCamera(tên, loại) (Game.exe RVA 0x2BC050):
// đọc Config/Character_3DHead.txt theo id mô hình, giao height, distance, pitch, shift cho bộ vẽ
// (Render.dll RVA 0x35550) và gọi SetFaceDir(turn) lên mô hình (quay quanh +y đúng góc turn).
// Bộ vẽ đặt camera (Render.dll RVA 0x36DC0):
//   điểm nhìn = (shift, height * scale, 0);  mắt = (0, (height + distance * pitch) * scale,
//   distance * scale), với mô hình đứng ở gốc và scale là số đơn vị mô hình trên một đơn vị game.
// Mỗi mô hình có bốn bộ số theo loại ô: loại 0 quay mặt sang trái màn hình, loại 1 tới 3 sang
// phải. Dữ liệu của dự án là Table/head_cameras.tsv do TOOLS/content/collect_ui.py trích từ bảng
// gốc cho các mô hình người chơi. Logic thuần, không I/O.
// Số mặc định khi bảng không có dòng: height 0,3, distance 1,2, pitch 0,28 (Render.dll 0x35E50).

#include "table/tsv.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Số đơn vị mô hình trên một đơn vị game (GetSacle của bộ vẽ gốc: mô hình tính bằng centimet).
inline constexpr float kModelScale = 100.0F;

// Số loại ô chân dung trong bảng gốc.
inline constexpr std::uint8_t kHeadKinds = 4;

// Loại ô của khung đội: lời gọi duy nhất còn trong script 2026 (PartyFrame.lua, đã tắt:
// Target:AdjustHeadCamera(model, 2)). Khung này nằm ở mép trái màn hình, mặt quay vào giữa.
inline constexpr std::uint8_t kPartyHeadKind = 2;

struct HeadPose {
    // Hướng mặt của mô hình (radian, quanh +y; 0 là nhìn thẳng vào camera, dương là quay về +x tức
    // sang phải màn hình).
    float turn = 0.0F;
    // Độ cao điểm nhìn, khoảng lùi của mắt và hệ số nhích mắt lên, theo đơn vị game.
    float height = 0.3F;
    float distance = 1.2F;
    float pitch = 0.28F;
    // Độ lệch ngang của điểm nhìn, theo đơn vị mô hình (bản gốc cộng thẳng, không nhân scale).
    float shift = 0.0F;
};

// Một dòng của bảng: mô hình (tên mẫu như "女主角.obj"), loại ô và bộ số của nó.
struct HeadRow {
    std::string model;
    std::uint8_t kind = 0;
    HeadPose pose;
};

// Đọc Table/head_cameras.tsv (cột model, kind, turn, height, distance, pitch, shift). Dòng có ô số
// hỏng hay kind ngoài 0..3 bị bỏ; thiếu cột thì rỗng.
[[nodiscard]] std::vector<HeadRow> read_heads(const table::Tsv& table);

using HeadsResult = std::expected<std::vector<HeadRow>, std::string>;

// Như read_heads từ nội dung tệp TSV; lỗi là câu của bộ đọc bảng khi tệp hỏng.
[[nodiscard]] HeadsResult parse_heads(std::string_view text);

// Một mô hình và một loại ô chân dung.
struct HeadKey {
    std::string_view model;
    std::uint8_t kind = 0;
};

// Bộ số của key; không có dòng thì số mặc định của bản gốc.
[[nodiscard]] HeadPose find_head(const std::vector<HeadRow>& rows, const HeadKey& key) noexcept;

// Mắt và điểm nhìn của camera theo đơn vị mô hình (x, y, z), mô hình đứng ở gốc.
struct HeadSight {
    std::array<float, 3> eye{};
    std::array<float, 3> target{};
};

[[nodiscard]] constexpr HeadSight head_sight(const HeadPose& pose) noexcept {
    const float lift = pose.distance * pose.pitch;
    HeadSight sight;
    sight.target = {pose.shift, pose.height * kModelScale, 0.0F};
    sight.eye = {0.0F, (lift + pose.height) * kModelScale, pose.distance * kModelScale};
    return sight;
}

} // namespace game::look
