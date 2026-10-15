/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/world.hpp
 *  PHÂN HỆ   : Server / Play / World
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dữ liệu chơi nạp một lần lúc zone khởi động: danh mục nhiệm vụ, chương
 *    trình hội thoại, sách chữ, luật thân thể và danh mục vật phẩm, đều từ
 *    dev/server/tables (không có Lua nào chạy). Mọi thứ chỉ đọc sau khi nạp,
 *    nên nhiều người chơi dùng chung mà không khoá. Thiếu hoặc hỏng một bảng
 *    bắt buộc thì nạp thất bại kèm câu tiếng Việt nêu bảng: zone vẫn chạy nhưng
 *    không có hội thoại.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "actor/body.hpp"
#include "actor/rules.hpp"
#include "combat/catalog.hpp"
#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/limits.hpp"
#include "loot/tables.hpp"
#include "mission/catalog.hpp"
#include "play/text.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"

#include <expected>
#include <filesystem>
#include <memory>
#include <span>
#include <string>

namespace game::play {

struct Paths {
    // dev/server/tables: có thư mục con shared, server, client.
    std::filesystem::path tables;
    // config/text: tệp chữ nhà phát hành đè lên, có thể rỗng hoặc không tồn tại.
    std::filesystem::path text_override;
    // Đuôi tên tệp chữ: dialogue.<language>.txt.
    std::string language = "zh";
};

class World {
public:
    [[nodiscard]] static std::expected<World, std::string> load(const Paths& paths);

    World(World&&) noexcept;
    World& operator=(World&&) noexcept;
    World(const World&) = delete;
    World& operator=(const World&) = delete;
    ~World();

    [[nodiscard]] const mission::Catalog& catalog() const noexcept;
    [[nodiscard]] const talk::Script& script() const noexcept;
    [[nodiscard]] const TextBook& text() const noexcept;
    [[nodiscard]] const actor::Rules& rules() const noexcept;
    [[nodiscard]] const actor::BodyLimits& body_limits() const noexcept;
    [[nodiscard]] const item::Catalog& items() const noexcept;
    [[nodiscard]] const item::Limits& item_limits() const noexcept;
    // Luật chiến đấu (kỹ năng, hiệu ứng, phe), bảng rơi đồ và nhà máy tạo vật phẩm.
    [[nodiscard]] const combat::Catalog& combat() const noexcept;
    [[nodiscard]] const loot::LootTables& loot() const noexcept;
    [[nodiscard]] const item::Factory& factory() const noexcept;
    [[nodiscard]] std::span<const talk::HandlerSpec> handlers() const noexcept;
    // Script NPC này có hộp thoại gốc chạy được không: zone đặt cờ "nói chuyện được" lên NPC theo câu trả lời này.
    [[nodiscard]] bool speaks(std::uint32_t script) const noexcept;

private:
    struct Data;
    explicit World(std::unique_ptr<Data> data) noexcept;

    std::unique_ptr<Data> data_;
};

} // namespace game::play
