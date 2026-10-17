/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/mount.hpp
 *  PHÂN HỆ   : Figure / Look / Ride
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thú cưỡi của client 2026: mô hình, neo, động tác, tốc độ, quầng, hạt và
 *    danh sách lưới Entity. Logic thuần, không I/O. Không phải ma trận vũ khí.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: Game.exe 2026, Obj_Character.cpp. Tạo 0x1405e2160, gắn khách 0x1405e5490,
// chọn động tác người cưỡi 0x1405e4ef0, động tác của thú 0x1405e51a0, lệch quầng
// 0x1405dc6f0 (bảng PetPossPositionValue, id DBC 0x282). Ghế 0 là chủ. Mã giới là
// dword character-data +0x1c: 0 hay khác 0, chưa đổi sang look::Race.
// Hạt: thẻ Effect trong Effects của all.obj. Không colour. translateAll thiếu là false.
// Lưới: thẻ Entity. materials ngăn bởi ';' theo thứ tự submesh. Ô rỗng giữ tên trong lưới.

#pragma once

#include "look/look.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Ghế 0 là người cưỡi chủ. Ghế 1..5 là khách. Ngoài khoảng đó không có neo.
inline constexpr int kRideOwner = 0;
inline constexpr int kRideSeats = 6;

// Tên điểm render vfunc +0x288/+0x290 nhận. Byte GBK tại 0x140c15d28, con trỏ
// PTR_DAT_140faee08 (RVA 0xfaee08): quầng dưới chân.
inline constexpr std::string_view kHaloSlot = "脚下光圈点偏移";

// Một dòng CharMount (bản ghi 0x80 byte). Cột 16..21 chưa có người đọc, giữ số.
struct RideRow {
    std::int32_t id = 0;
    std::string name;
    std::int32_t passenger_capacity = 1;
    std::int32_t model_id = -1;
    // +0x18, float đưa vào render người cưỡi vfunc +0x1b8. Giữ đúng số gốc.
    float add_height = 0.0F;
    std::int32_t ride_recipe = -1;
    // +0x20 và +0x24: bộ động tác người cưỡi khi mã giới là 0, rồi khi khác 0.
    std::array<std::int32_t, 2> driver_action{-1, -1};
    // +0x30 và +0x34: bộ động tác của khách, cùng cách chọn theo mã giới.
    std::array<std::int32_t, 2> passenger_action{-1, -1};
    // anchor_0 là +0x28, anchor_1 là +0x38, rồi +0x40, +0x48, +0x50, +0x58.
    std::array<std::string, kRideSeats> anchors{};
    std::array<std::int32_t, 6> extra{-1, -1, -1, -1, -1, -1};
    // +0x78 cộng vào Y camera của người chơi cục bộ (0x1405e6d10).
    float camera_y = 0.0F;
    // +0x7c: id dòng PetPossPositionValue. -1 là không gọi +0x288.
    std::int32_t effect_id = -1;
    // Exterior_Ride cột Speed, khoá MountId. 0 là không có dòng: không cộng phần trăm.
    std::int32_t speed_percent = 0;
};

// CharModelEx của mô hình thú: lưới, cột 5, bộ động tác cột 20 (+0x5c).
struct RideModel {
    std::int32_t id = 0;
    std::string mesh;
    float scale = 1.0F;
    std::int32_t action_set = -1;
};

// Bảy float của +0x288, đúng thứ tự lời gọi: x, y, z, góc, rồi trục.
struct RideOffset {
    std::int32_t id = -1;
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float angle = 0.0F;
    float axis_x = 0.0F;
    float axis_y = 0.0F;
    float axis_z = 0.0F;
    std::string label;
};

// Một lưới của mẫu. file là thuộc tính Entity, không phải tên .mesh suy từ tên mẫu.
struct RideEntity {
    std::string object;
    std::int32_t slot = 0;
    std::string file;
    // Thuộc tính material nguyên văn. Rỗng là không chồng.
    std::string materials;
    // Khác rỗng thì không vẽ: chưa có luật condition của thú.
    std::string condition;
};

// Một hạt gắn sẵn trên mẫu thú. Không phải quầng PetPoss (effect_id).
struct RideEffect {
    std::string object;
    // Thuộc tính name. addEffect từ chối tên trùng trong cùng mẫu.
    std::string slot;
    std::string effect;
    std::string locator;
    // translateAll. Sai thì hạt chỉ lấy vị trí điểm, không lấy hướng xương.
    bool translate_all = false;
};

struct RideTables {
    std::vector<RideRow> rides;
    std::vector<RideModel> models;
    std::vector<RideOffset> offsets;

    [[nodiscard]] const RideRow* find_ride(std::int32_t id) const noexcept;
    [[nodiscard]] const RideModel* find_model(std::int32_t id) const noexcept;
    [[nodiscard]] const RideOffset* find_offset(std::int32_t id) const noexcept;
};

struct RideTexts {
    std::string_view rides;
    std::string_view models;
    std::string_view offsets;
};

// Ba bảng rides.tsv, ride_models.tsv, ride_offsets.tsv. Lỗi nêu tên bảng.
[[nodiscard]] std::expected<RideTables, std::string> parse_ride_tables(const RideTexts& texts);

// ride_effects.tsv. Giữ thứ tự tệp. Trùng (object, slot) là lỗi.
[[nodiscard]] std::expected<std::vector<RideEffect>, std::string> parse_ride_effects(
    std::string_view text);

// ride_entities.tsv. Giữ thứ tự tệp. Trùng (object, slot) là lỗi.
[[nodiscard]] std::expected<std::vector<RideEntity>, std::string> parse_ride_entities(
    std::string_view text);

// Clip thân thú của một mô hình (ride_model_clips.tsv). Ô trống là bảng không có hành động ấy.
struct MountClips {
    std::optional<Clip> idle;
    std::optional<Clip> idle_alt;
    std::optional<Clip> idle_alt2;
    std::optional<Clip> run;
    std::optional<Clip> jump_stand;
    std::optional<Clip> jump_run;
};

// ride_locators.tsv: điểm gắn trên mẫu thú.
[[nodiscard]] Rows<LocatorRow> parse_ride_locators(std::string_view text);

// ride_anims.tsv: động tác người cưỡi theo giới, bộ CharMount và vũ khí.
[[nodiscard]] Rows<RacedAnimRow> parse_ride_anims(std::string_view text);

// Tên .skeleton của mô hình trong ride_skeletons.tsv, dòng khớp đầu tiên. Rỗng khi không có dòng.
// Dòng hỏng thì bỏ qua; bảng hỏng hay thiếu cột là lỗi.
[[nodiscard]] std::expected<std::string, std::string> parse_ride_skeleton(std::string_view text,
    std::int32_t model);

// Clip của mô hình trong ride_model_clips.tsv. Dòng hỏng hay hành động lạ thì bỏ qua; hành động
// lặp thì dòng sau thắng.
[[nodiscard]] std::expected<MountClips, std::string> parse_mount_clips(std::string_view text,
    std::int32_t model);

// Dòng của một mẫu, đúng thứ tự tệp. Con trỏ mượn rows.
[[nodiscard]] std::vector<const RideEffect*> effects_of(std::span<const RideEffect> rows,
    std::string_view object);

// Lưới của một mẫu, đúng thứ tự tệp. Con trỏ mượn rows.
[[nodiscard]] std::vector<const RideEntity*> entities_of(std::span<const RideEntity> rows,
    std::string_view object);

// Đọc ba tệp trong folder. Dừng ở tệp hỏng đầu tiên.
[[nodiscard]] std::expected<RideTables, std::string> load_ride_tables(std::string_view folder,
    const ReadFile& read);

// Neo chủ (ghế 0) theo 0x1405e2160. Khách theo 0x1405e5490. Rỗng là chuỗi gốc dài 0.
[[nodiscard]] std::string_view anchor_of(const RideRow& row, int owner_sex, int seat) noexcept;

// Id bộ động tác người đang cưỡi. -1 là cột gốc không có, nơi gọi rơi về bộ của mô hình.
[[nodiscard]] std::int32_t rider_action_of(const RideRow& row, int rider_sex, int seat) noexcept;

// Lệch quầng khi effect_id có dòng. -1 hay id lạ là không lệch, không phải lỗi.
[[nodiscard]] const RideOffset* halo_of(const RideTables& tables, const RideRow& row) noexcept;

// Hình để vẽ một ghế. model_id -1 hay không có mô hình là lỗi.
struct RideFigure {
    std::int32_t id = 0;
    std::string name;
    std::int32_t model_id = -1;
    std::string mesh;
    // Cột 5 của CharModelEx. Tạo thú ghi đè scale nút bằng scale người cưỡi.
    float model_scale = 1.0F;
    float add_height = 0.0F;
    float camera_y = 0.0F;
    // Cùng RideRow::speed_percent. Phép nhân tốc độ nằm ở motion, không ở đây.
    std::int32_t speed_percent = 0;
    std::string anchor;
    // Đã rơi về action_set của mô hình khi cột người cưỡi là -1. -1 nếu cả hai đều không có.
    std::int32_t rider_action = -1;
    // Bộ động tác của chính con thú (0x1405e51a0), tách khỏi rider_action.
    std::int32_t model_action = -1;
    std::optional<RideOffset> offset;
};

// owner_sex chọn neo; rider_sex chọn động tác. Chủ thì hai mã là một.
[[nodiscard]] std::expected<RideFigure, std::string> ride_figure(const RideTables& tables,
    std::int32_t mount_id, int owner_sex, int rider_sex, int seat);

} // namespace game::look
