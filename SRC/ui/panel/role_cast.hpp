// Dữ liệu của màn tạo nhân vật: ảnh chân dung, kiểu mặt, kiểu tóc và bộ đồ tân thủ, tra đúng như
// ba bộ quản của thủ tục tạo nhân vật trong Game.exe của client 2026 (docs/TAO-NHAN-VAT-2026.md):
// - CharacterFaceMng (nạp ở 0x14063df70): mỗi giới một dãy MỌI dòng chân dung theo thứ tự tệp, sắp
//   ổn định tăng dần theo cột order; số ảnh "cho màn tạo" là số dòng có choice 1 hay 3, và ảnh hay
//   id chỉ trả cho dòng có choice 1 hay 3.
// - FaceModelMng (0x14063fa20): mỗi giới một dãy mọi dòng kiểu mặt theo thứ tự tệp, không lọc;
//   script tự lọc theo choice.
// - HairModelMng (0x140642d20) ở chế độ của thủ tục tạo: chỉ giữ dòng có choice 1 hay 3.
// - Bộ đồ tân thủ (0x140640ec0): mọi dòng của NewRoleEquipset theo thứ tự tệp.
// Script CreateRole.lua trao đổi với game bằng giới (0 nữ, 1 nam) và vị trí của dòng trong dãy của
// giới đó, kể cả vị trí âm hay ngoài dãy; mọi hàm tra ở đây nhận mọi cặp số và trả "không có" đúng
// như hàm gốc (chuỗi rỗng, 0, -1).
// Bảng: Table/portraits.tsv (collect_ui.py), faces.tsv và hairs.tsv (export_look.py),
// newbie_outfits.tsv (export_config.py). Thuần logic, không I/O.
#pragma once

#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

inline constexpr std::int32_t kFemale = 0;
inline constexpr std::int32_t kMale = 1;
// Dòng cao mô của một kiểu mặt hay tóc mang id thường cộng số này; người mẫu của màn tạo vẽ bằng
// dòng đó (SetFaceModelId và SetHairModelId của Game.exe cộng 0x2710 trước khi đổi lưới).
inline constexpr std::int32_t kHighPolyStep = 10000;

// Bốn bảng của màn tạo. Con trỏ rỗng là không có bảng: phần đó của dữ liệu rỗng.
struct CastTables {
    const table::Tsv* portraits = nullptr;
    const table::Tsv* faces = nullptr;
    const table::Tsv* hairs = nullptr;
    const table::Tsv* outfits = nullptr;
};

// Một dòng theo cách script gọi: giới và vị trí (từ 0) trong dãy của giới đó.
struct CastRow {
    std::int32_t sex = kFemale;
    std::int32_t index = 0;
};

// Mặt và tóc của một giới theo id của bảng ngoại hình.
struct ModelLook {
    std::int32_t sex = kFemale;
    std::int32_t face = 0;
    std::int32_t hair = 0;
};

// Một bộ đồ tân thủ: id của dòng, tên, và id hình trang phục (bảng outfits của module look) của
// áo, giày, bao tay.
struct NewbieOutfit {
    std::int32_t id = 0;
    std::string name;
    std::uint16_t body = 0;
    std::uint16_t foot = 0;
    std::uint16_t arm = 0;
};

class RoleCast {
public:
    // Dòng có ô sai kiểu hay ngoài miền bị bỏ và đếm vào skipped(); dòng của giới khác 0 và 1 bị
    // bỏ không đếm. Bảng thiếu cột thì mọi dòng của nó bị bỏ. O(n log n) theo số dòng.
    [[nodiscard]] static RoleCast from_tables(const CastTables& tables);

    // GetWomanFaceCountForCreate (giới 0), GetManFaceCountForCreate (giới 1); giới khác thì 0.
    [[nodiscard]] std::int32_t portrait_count(std::int32_t sex) const noexcept;
    // GetFaceName: ảnh "set:<bộ> image:<tên>" của dòng; rỗng khi không có dòng hay dòng không chọn
    // được lúc tạo. Chuỗi sống cùng đối tượng.
    [[nodiscard]] std::string_view portrait_image(CastRow row) const noexcept;
    // Id chân dung mà SetFaceId ghi; nullopt khi hàm gốc không ghi gì (không có dòng, dòng không
    // chọn được).
    [[nodiscard]] std::optional<std::int32_t> portrait_id(CastRow row) const noexcept;

    // GetFaceModelCount, GetFaceModelInfo (cột choice; -1 khi không có dòng), GetFaceModelName
    // (rỗng khi không có dòng) và id mà SetFaceModelId ghi (0 khi không có dòng).
    [[nodiscard]] std::int32_t face_count(std::int32_t sex) const noexcept;
    [[nodiscard]] std::int32_t face_choice(CastRow row) const noexcept;
    [[nodiscard]] std::string_view face_name(CastRow row) const noexcept;
    [[nodiscard]] std::int32_t face_id(CastRow row) const noexcept;

    // GetHairModelCount, GetHairModelName và id mà SetHairModelId ghi, trên dãy đã lọc.
    [[nodiscard]] std::int32_t hair_count(std::int32_t sex) const noexcept;
    [[nodiscard]] std::string_view hair_name(CastRow row) const noexcept;
    [[nodiscard]] std::int32_t hair_id(CastRow row) const noexcept;

    // GetEquipSetCount, GetEquipSetName (rỗng khi không có dòng) và dòng thứ index (nullptr khi
    // không có).
    [[nodiscard]] std::int32_t outfit_count() const noexcept;
    [[nodiscard]] std::string_view outfit_name(std::int32_t index) const noexcept;
    [[nodiscard]] const NewbieOutfit* outfit(std::int32_t index) const noexcept;

    // Mặt và tóc mà người mẫu của màn tạo vẽ khi nhân vật mang worn: dòng cao mô id + kHighPolyStep
    // của từng thứ khi bảng có dòng đó. O(log n).
    // Khác gốc: bảng không có dòng cao mô thì giữ chính id (hàm gốc vẫn cộng, người mẫu mất mặt
    // hay tóc).
    [[nodiscard]] ModelLook model_look(ModelLook worn) const noexcept;

    // Số dòng bị bỏ vì ô sai; nơi nạp ghi một dòng log khi khác 0.
    [[nodiscard]] std::size_t skipped() const noexcept { return skipped_; }

private:
    // Một giá trị cho mỗi giới; giới lạ không có chỗ nào để trỏ tới.
    template <typename Value>
    struct BySex {
        Value female{};
        Value male{};

        [[nodiscard]] const Value* of(std::int32_t sex) const noexcept {
            if (sex == kFemale) return &female;
            return sex == kMale ? &male : nullptr;
        }
        [[nodiscard]] Value* of(std::int32_t sex) noexcept {
            if (sex == kFemale) return &female;
            return sex == kMale ? &male : nullptr;
        }
    };

    struct Portrait {
        std::int32_t id = 0;
        std::string image;
        std::int32_t choice = 0;
        std::int32_t order = 0;
    };

    // Một dòng kiểu mặt hay kiểu tóc.
    struct Model {
        std::int32_t id = 0;
        std::string name;
        std::int32_t choice = 0;
    };

    // Dòng row của một dãy theo giới; nullptr khi giới lạ hay vị trí ngoài dãy (kể cả âm).
    template <typename Row>
    [[nodiscard]] static const Row* row_at(const BySex<std::vector<Row>>& lists, CastRow row) noexcept {
        const std::vector<Row>* own = lists.of(row.sex);
        if (own == nullptr || row.index < 0) return nullptr;
        const auto place = static_cast<std::size_t>(row.index);
        return place < own->size() ? &(*own)[place] : nullptr;
    }

    void take_portraits(const table::Tsv& table);
    void take_faces(const table::Tsv& table);
    void take_hairs(const table::Tsv& table);
    void take_outfits(const table::Tsv& table);

    BySex<std::vector<Portrait>> portraits_;
    BySex<std::int32_t> portrait_counts_;
    BySex<std::vector<Model>> faces_;
    // Kiểu tóc chọn được lúc tạo (dãy của bộ quản).
    BySex<std::vector<Model>> hairs_;
    // Id của mọi dòng mặt và mọi dòng tóc, xếp tăng, để tìm dòng cao mô.
    BySex<std::vector<std::int32_t>> face_ids_;
    BySex<std::vector<std::int32_t>> hair_ids_;
    std::vector<NewbieOutfit> outfits_;
    std::size_t skipped_ = 0;
};

} // namespace game::ui::panel
