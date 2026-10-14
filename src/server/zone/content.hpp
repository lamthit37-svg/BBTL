#pragma once
// Quái và NPC đặt sẵn của cảnh, lấy từ dữ liệu cảnh (dev/server/scenes/<tên>/spawns.tsv, do module scenedata
// nạp). Host tạo cảnh lười khi người chơi đầu tiên vào; lúc đó nó hỏi Seeder danh sách thực thể cần đặt.
//
// Tách làm hai phần: seeds_of là phép đổi THUẦN từ Scene của scenedata sang danh sách đặt (test được không cần
// đĩa), DiskSeeder là chỗ duy nhất chạm đĩa (bảng scene_ids.tsv, thư mục cảnh) và chỉ được gọi từ serve.cpp.
//
// Chỉ bảng quái gốc (spawns.tsv) được đặt. Các bảng theo cấp người chơi (spawns.level_*.tsv, chọn qua
// spawn_operates) và luật AI/tuần tra thuộc bước sau: cảnh dựng xong thì quái đứng yên đúng chỗ đặt.

#include "scenedata/types.hpp"
#include "zone/scene.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::zone {

// Một thực thể đặt sẵn. respawn_ms âm là không hồi sinh (cảnh chưa có cái chết, nên chưa dùng).
struct Seed {
    Spawn what;
    std::int32_t respawn_ms = -1;
};

struct Seeding {
    std::vector<Seed> seeds;
    // Dòng bảng không có toạ độ (ô x hoặc z rỗng): mã 2008 đặt chúng ở góc (0, 0) ngoài mọi lưới đi.
    std::size_t unplaced = 0;
    // Dòng bị bỏ vì vượt trần `cap`.
    std::size_t over_cap = 0;
};

// Hai thuộc tính của mẫu quái/NPC mà bảng cảnh không ghi (tables/shared/monsters.tsv của client 2026: cột
// monster_id, level, can_interact). Bảng này là bảng sinh ra từ client (git bỏ qua), nên có thể vắng: khi đó mọi
// dòng không phải trân thú là quái và cấp lấy từ bảng cảnh.
struct TemplateInfo {
    std::uint16_t level = 0;
    // can_interact == 1: đứng đó để nói chuyện/mua bán, không phải để đánh.
    bool interactive = false;
};

class TemplateTable {
public:
    // Đọc bằng cách tách theo tab, không dựng bảng ô: bảng thật 29 nghìn dòng × 70 cột. Lỗi trả câu tiếng Việt kèm số dòng.
    [[nodiscard]] static std::expected<TemplateTable, std::string> parse(std::string_view text);

    [[nodiscard]] const TemplateInfo* find(std::uint32_t template_id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return by_id_.size(); }

private:
    std::unordered_map<std::uint32_t, TemplateInfo> by_id_;
};

// Đơn vị toạ độ của bảng cảnh là đơn vị game (một đơn vị là một ô lưới); zone dùng centimet, 1 đơn vị = 100 cm
// (cùng phép đổi như điểm sinh của nhân vật, docs/SERVER-DI-CHUYEN.md).
// Hướng: bảng ghi độ (Spawn::heading_degrees); đổi sang 0..65535 ứng với 0..2π. Quy ước gốc của góc (từ trục nào,
// chiều nào) chưa đối chiếu với client 2026 (docs/NGHI-NGO.md), nên hướng NPC có thể lệch một góc cố định.
[[nodiscard]] Seeding seeds_of(const scenedata::Scene& scene, std::size_t cap, const TemplateTable& templates);

// Cầu từ id cảnh của client sang thư mục cảnh.
class SceneDirectory {
public:
    // Đọc scene_ids.tsv (cột client_id_first, client_id_last, scene_dir). Lỗi trả câu tiếng Việt.
    [[nodiscard]] static std::expected<SceneDirectory, std::string> parse(std::string_view text);

    // Tên thư mục của id; rỗng khi id không thuộc cảnh nào.
    [[nodiscard]] std::string_view dir_of(std::uint16_t scene) const noexcept;
    [[nodiscard]] std::size_t range_count() const noexcept { return ranges_.size(); }

private:
    struct Range {
        std::uint16_t last = 0;
        std::string dir;
    };
    // Khoá là id đầu của khoảng; khoảng không chồng nhau (parse từ chối).
    std::map<std::uint16_t, Range> ranges_;
};

using Seeder = std::function<std::vector<Seed>(std::uint16_t scene)>;

struct DiskPaths {
    std::filesystem::path scenes;
    std::filesystem::path ids_table;
    // Có thể vắng: xem TemplateTable.
    std::filesystem::path templates;
};

// Seeder đọc đĩa: thiếu bảng id hay thư mục cảnh thì cảnh để trống và nói ra stderr. `cap` là số thực thể tối đa
// mỗi cảnh. Chỉ một luồng được gọi nó (luồng tick của zone); đọc một cảnh lớn tốn vài chục mili giây, lần đầu
// có người vào cảnh đó.
[[nodiscard]] Seeder disk_seeder(const DiskPaths& paths, std::size_t cap);

} // namespace game::zone
