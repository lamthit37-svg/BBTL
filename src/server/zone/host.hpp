/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/host.hpp
 *  PHÂN HỆ   : Server / Zone / Host
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cầu giữa khung ipc và các cảnh: Host nhận khung gate gửi (Attach, Detach,
 *    Moved), chọn cảnh, chạy logic và đổ kết quả vào Outbox. Không biết socket
 *    nên test được bằng cách đưa thẳng ipc::Frame.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cảnh tạo lười khi người chơi đầu tiên vào, tới trần scene_max (id cảnh là u16, nên trần chặn kẻ gửi
// Attach với hàng nghìn id lạ làm phình bộ nhớ). Cảnh đã tạo được giữ lại: quái và NPC sống ở đó. Lúc tạo,
// Seeder (nếu có) đưa quái và NPC đặt sẵn vào cảnh và cho cảnh luật đi; số đặt được bị chặn để còn chỗ cho
// player_max người chơi.
//
// Khung hỏng hay phiên lạ không làm hỏng Host: Attach hỏng bị từ chối (kRefuse), khung khác bị bỏ và đếm.

#pragma once

#include "ipc/link.hpp"
#include "play/gameplay.hpp"
#include "play/world.hpp"
#include "zone/content.hpp"
#include "zone/scene.hpp"

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <unordered_map>
#include <vector>

namespace game::zone {

class Host {
public:
    struct Config {
        Grid::Spec grid{.cell_cm = 1000.0F, .radius = 2};
        std::size_t player_max = 4000;
        std::size_t scene_max = 256;
        // Quái và NPC đặt sẵn khi cảnh được tạo; rỗng thì cảnh chỉ có người chơi.
        Seeder seeder{};
        // Dữ liệu chơi (hội thoại, nhiệm vụ). Con trỏ rỗng thì Host không có gameplay: chỉ ai thấy ai. World sống lâu hơn Host.
        const play::World* world = nullptr;
        play::Gameplay::Settings play{};
    };

    explicit Host(Config config);
    // Giờ Unix hiện tại (giây) cho lịch nhiệm vụ; zone gọi trước mỗi advance. Mặc định 0: test tất định.
    void set_unix_time(std::int64_t seconds) noexcept;

    // Một khung từ gate.
    void handle(const ipc::Frame& frame, Outbox& out);
    // Một bước mô phỏng (1/kTickHz giây) cho mọi cảnh, theo thứ tự id cảnh.
    void advance(Outbox& out);
    // Chu kỳ ghi điểm đứng, tính bằng tick.
    static constexpr std::uint32_t kAutosaveTicks = 60 * 20;
    // Kênh tới gate mất: mọi phiên đã mất, nên bỏ hết người chơi. Gate đóng ô của họ ở phía nó.
    void drop_all(Outbox& out);

    [[nodiscard]] std::size_t scene_count() const noexcept { return scenes_.size(); }
    [[nodiscard]] std::size_t player_count() const noexcept { return where_.size(); }
    [[nodiscard]] std::uint64_t ignored() const noexcept { return ignored_; }
    [[nodiscard]] const Scene* find(std::uint16_t scene) const noexcept;
    [[nodiscard]] Scene* find(std::uint16_t scene) noexcept;
    [[nodiscard]] const play::Gameplay* gameplay() const noexcept { return play_.get(); }

private:
    class Around;
    [[nodiscard]] const Scene* scene_of(std::uint64_t session) const noexcept;
    void deliver(play::Output& output, Outbox& out);
    void clock_play() noexcept;
    void attach(std::uint64_t session, const ipc::Frame& frame, Outbox& out);
    void detach(std::uint64_t session, Outbox& out);
    [[nodiscard]] Scene* scene_for(std::uint16_t id);
    void seed(Scene& scene, const std::vector<Seed>& seeds) const;

    Config config_;
    // map để thứ tự chạy các cảnh cố định (logic tất định).
    std::map<std::uint16_t, Scene> scenes_;
    std::unordered_map<std::uint64_t, std::uint16_t> where_;
    std::uint64_t ignored_ = 0;
    std::uint32_t ticks_ = 0;
    std::int64_t unix_seconds_ = 0;
    std::unique_ptr<play::Gameplay> play_;
};

} // namespace game::zone
