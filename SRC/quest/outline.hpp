// Nhiệm vụ nhận được ("可接任务" của bảng nhiệm vụ): bảng Config/MissionOutline.txt của client 2026
// (Table/mission_outline.tsv do TOOLS/content/export_config.py xuất), bảng tên loại nhiệm vụ
// (Table/mission_kinds.tsv từ Config/MissionKind.txt) và bộ lọc theo người chơi.
// Bộ lọc và các hàm tra port từ mã máy Game.exe 2026, địa chỉ và mã giả ở
// docs/NHIEM-VU-VO-CONG-2026.md: CollectMissionOutline 0x1406dd8e0, bộ lọc từng dòng 0x1406ddeb0,
// GetMissionOutlineNum 0x140248990, GetMissionOutlineInfo 0x1406ddad0, GetMissionInfo_Kind
// 0x1402cc5c0. Logic thuần, không I/O; mọi so sánh số nguyên là 32 bit có dấu như mã gốc.
#pragma once

#include "quest/log.hpp"
#include "table/tsv.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::quest {

// Số loại nhiệm vụ: cột kind nhận 1..200, mỗi loại một danh sách.
inline constexpr std::size_t kKindCount = 200;
// Ô của bảng gốc mang nghĩa "không có" (môn phái bất kỳ, không có nhiệm vụ tiền đề, cấp theo người
// chơi).
inline constexpr std::int32_t kAny = -1;
// Môn phái "chưa nhập môn" của máy chủ gốc.
inline constexpr std::int32_t kNoSect = 9;

// Một dòng của MissionOutline. Ba cột hidden nhận 0 (hiện), 1 (giấu ở loại máy chủ đó) hay 2
// (hiện với tên riêng của loại máy chủ đó); needs là ba nhiệm vụ tiền đề, kAny là không có.
struct OutlineRow {
    std::int32_t id = 0;
    std::int32_t mission = 0;
    std::int32_t kind = 0;
    std::int32_t sect = kAny;
    // Cấp hiển thị; kAny là bằng cấp người chơi.
    std::int32_t level = 0;
    std::int32_t min_level = 0;
    std::int32_t max_level = 0;
    std::int32_t scene = kAny;
    std::array<std::int32_t, 3> needs = {kAny, kAny, kAny};
    std::int32_t x = 0;
    std::int32_t z = 0;
    std::int32_t hidden = 0;
    std::int32_t hidden_original = 0;
    std::int32_t hidden_light = 0;
    std::string npc;
    std::string name;
    std::string name_original;
    std::string name_light;
    // Tên cảnh của ô scene theo Config/SceneDefineEx.txt (nối sẵn lúc xuất); rỗng khi không có cảnh.
    std::string scene_name;
};

using OutlineRows = std::expected<std::vector<OutlineRow>, std::string>;

// Đọc Table/mission_outline.tsv; lỗi là câu của bộ đọc bảng (thiếu cột, ô không phải số nguyên).
[[nodiscard]] OutlineRows read_outline(const table::Tsv& table);

// Một loại nhiệm vụ: id và tên gốc.
struct KindRow {
    std::int32_t id = 0;
    std::string name;
};

using KindRows = std::expected<std::vector<KindRow>, std::string>;

// Đọc Table/mission_kinds.tsv; các dòng trả về xếp tăng dần theo id, id lặp thì giữ dòng gặp
// trước.
[[nodiscard]] KindRows read_kinds(const table::Tsv& table);

// Tên của loại kind như DataPool:GetMissionInfo_Kind: kind ngoài 0..199 thì gốc trả số 0, script
// nối nó thành chữ "0" (kể cả kind 200 dù bảng có dòng đó).
// Khác gốc: kind trong 0..199 mà bảng không có dòng thì trả rỗng; mã gốc ném ngoại lệ.
[[nodiscard]] std::string_view kind_title(std::span<const KindRow> kinds, std::int32_t kind) noexcept;

// Ba số của người chơi mà sáu dòng "hào hiệp võ dụ" (id nhiệm vụ 3138..3143) xét thêm. Mã gốc đọc
// chúng từ dữ liệu nhân vật do máy chủ gửi; nghĩa và nguồn chưa lần ra (docs/NGHI-NGO.md), nên
// tên theo đúng điều mã so sánh: has_card là kết quả hàm 0x140509c00, tokens là WORD ở sd+0x6678,
// stage là DWORD ở sd+0x6340. Chưa có máy chủ thì cả ba bằng 0.
struct Edict {
    bool has_card = false;
    std::int16_t tokens = 0;
    std::int32_t stage = 0;
};

// Người chơi dưới mắt bộ lọc. Ba cờ loại máy chủ là ba ô IsPKServer_JD, IsOriginalJD, Is2606S của
// CDataPool (chỉ máy chủ đổi được; chưa có máy chủ thì cả ba tắt).
struct Seeker {
    std::int32_t level = 1;
    // LEVEL_CompatPKLV: thay cho level khi is_pk và nó nhỏ hơn level.
    std::int32_t compat_level = 1;
    std::int32_t sect = kNoSect;
    bool is_pk = false;
    bool is_original = false;
    bool is_light = false;
    Edict edict;
};

// Cấp mà bộ lọc và cấp hiển thị dùng: cấp tương thích PK khi máy chủ là máy chủ PK và nó nhỏ hơn.
[[nodiscard]] constexpr std::int32_t effective_level(const Seeker& seeker) noexcept {
    const bool is_lowered = seeker.is_pk && seeker.compat_level < seeker.level;
    return is_lowered ? seeker.compat_level : seeker.level;
}

// Các nhiệm vụ nhận được theo loại: by_kind[kind - 1] là chỉ số dòng của bảng, theo thứ tự của
// bảng (không sắp xếp lại).
struct Offers {
    std::array<std::vector<std::uint32_t>, kKindCount> by_kind;
};

// Dựng lại offers cho người chơi seeker với sổ log, như CollectMissionOutline. Một dòng lọt khi:
// không bị giấu ở loại máy chủ đang chạy, cấp trong [min_level, max_level], môn phái hợp (kAny,
// đúng môn phái, 9, hoặc ngoài 0..15), loại trong 1..200, chưa xong và không đang giữ, cả ba nhiệm
// vụ tiền đề đã xong; sáu id 3138..3143 xét thêm seeker.edict. O(số dòng x số ô); giữ bộ nhớ đã
// cấp của offers.
void collect_offers(std::span<const OutlineRow> rows, const Seeker& seeker, const Log& log, Offers& offers);

// Số nhiệm vụ nhận được của loại kind (1..200), như GetMissionOutlineNum; loại ngoài miền là 0.
[[nodiscard]] std::size_t offer_count(const Offers& offers, std::int32_t kind) noexcept;

// Điều GetMissionOutlineInfo trả cho script. Chuỗi mượn bảng rows.
struct OfferView {
    std::int32_t level = 0;
    std::int32_t min_level = 0;
    std::int32_t max_level = 0;
    std::string_view npc;
    std::string_view scene_name;
    std::string_view name;
    std::int32_t x = 0;
    std::int32_t z = 0;
    std::int32_t scene = kAny;
};

// Một lần hỏi GetMissionOutlineInfo(kind, number): number đếm từ 1 như script.
struct OfferAsk {
    std::int32_t kind = 0;
    std::int32_t number = 0;
};

// Nhiệm vụ thứ ask.number của loại ask.kind. nullopt khi loại hay số thứ tự ngoài miền, hay dòng
// bị giấu ở loại máy chủ của seeker. Cấp kAny của bảng thành cấp của seeker; tên là tên riêng của
// loại máy chủ khi cột hidden của loại đó bằng 2 và tên riêng khác rỗng.
// Khác gốc: không trả chuỗi "(x,z)" ghép từ hai cột chữ của bảng (cả 994 dòng để rỗng, script
// không dùng); khi ngoài miền mã gốc vẫn đẩy sáu số chưa khởi tạo, ở đây là nullopt.
[[nodiscard]] std::optional<OfferView> offer_at(
    std::span<const OutlineRow> rows, const Offers& offers, const Seeker& seeker, const OfferAsk& ask) noexcept;

} // namespace game::quest
