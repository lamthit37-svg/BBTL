/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/gameplay.hpp
 *  PHÂN HỆ   : Server / Play / Gameplay
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lối vào gameplay của zone: giữ người chơi (play::Player), phiên hội thoại
 *    (talk::Service) và bộ chạy nhiệm vụ (mission::Engine), nhận ý định của
 *    client (Talk, DialogChoose, QuestAccept, QuestTurnIn, QuestAbandon,
 *    DialogClose) và trả tin cho client qua Output. Thuần theo nghĩa của zone:
 *    không socket, không đồng hồ thật (giờ Unix là đầu vào của set_time), ngẫu
 *    nhiên từ dice::Dice có hạt cố định, nên cùng dãy gọi cho cùng Output.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Client chỉ gửi ý định (id NPC, chỉ số lựa chọn, id nhiệm vụ): không bao giờ id script hay tên hàm. Mọi con số ở đây (thưởng, kinh
// nghiệm, tiền) do máy chủ tính; client không có đường nào để đặt chúng. Dữ liệu từ client không đi vào check/assert: id lạ, phiên
// cũ, khoảng cách, tốc độ gửi đều trả Reject có mã.

#pragma once

#include "account/play.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "ipc/relay.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "play/player.hpp"
#include "play/text.hpp"
#include "play/world.hpp"
#include "protocol/messages.hpp"
#include "talk/service.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace game::play {

// Cái zone cho gameplay biết về thế giới: NPC nào đứng đó và cách người chơi bao xa. Tách khỏi Scene để gameplay thử được riêng.
class Surroundings {
public:
    // NPC nói chuyện được: `entity` là id thực thể trong cảnh (duy nhất mỗi cảnh, khác GUID của bảng cảnh vốn có thể trùng).
    struct Npc {
        std::uint32_t entity = 0;
        std::int32_t scene = -1;
        // GUID của bảng cảnh: khoá của danh bạ nhiệm vụ theo NPC (không duy nhất trong cảnh; `entity` mới duy nhất).
        std::uint32_t guid = 0;
        std::uint32_t script = 0;
        std::string name;
    };
    // Thực thể được hỏi (đóng gói để không lẫn với mã phiên cùng kiểu số nguyên).
    struct Target {
        std::uint32_t entity = 0;
    };
    struct Spot {
        std::uint32_t entity = 0;
        std::int32_t scene = -1;
    };
    struct Presence {
        std::int32_t hero_scene = -1;
        std::int32_t npc_scene = -1;
        float distance_m = 0.0F;
    };

    Surroundings() = default;
    Surroundings(const Surroundings&) = delete;
    Surroundings& operator=(const Surroundings&) = delete;
    Surroundings(Surroundings&&) = delete;
    Surroundings& operator=(Surroundings&&) = delete;
    virtual ~Surroundings() = default;

    // NPC (kind = Npc) có id thực thể `entity` trong cảnh của người chơi `session`; nullopt khi không có hay không phải NPC.
    [[nodiscard]] virtual std::optional<Npc> npc(std::uint64_t session, Target target) const = 0;
    // Cảnh và khoảng cách (mét, 2D) giữa người chơi và NPC; nullopt khi một trong hai không còn.
    [[nodiscard]] virtual std::optional<Presence> presence(std::uint64_t session, Spot npc) const = 0;
};

struct Output {
    struct Frame {
        std::uint64_t session = 0;
        std::vector<std::byte> bytes;
    };
    // Trạng thái chơi cần ghi: host ghép với điểm đứng hiện tại của nhân vật thành một lần ghi.
    struct Keep {
        std::uint64_t session = 0;
        std::uint64_t character = 0;
        account::PlayRecord record;
    };

    std::vector<Frame> frames;
    std::vector<Keep> keeps;
    // Tin không mã hoá được (trường quá trần): scene luôn điền trong trần, nên đây là lỗi lập trình lộ ra bằng số.
    std::size_t encode_failures = 0;

    template <typename Message>
    void down(std::uint64_t session, const Message& message);
    void reject(std::uint64_t session, std::uint16_t request, protocol::ErrorCode code);
};

class Gameplay {
public:
    struct Settings {
        std::uint64_t seed = 1;
        // Trần số ý định mỗi giây mỗi người chơi; quá thì Reject kRateLimited (không đóng phiên).
        std::uint32_t intents_per_second = 10;
        // Đổi giờ Unix sang giờ của lịch nhiệm vụ: Bắc Kinh như máy chủ gốc.
        std::int32_t utc_offset_seconds = 8 * 3600;
    };

    Gameplay(const World& world, const Settings& settings);

    struct Clock {
        std::int64_t unix_seconds = 0;
        std::uint64_t tick = 0;
    };
    // Giờ Unix hiện tại (giây) và tick của zone; host gọi mỗi tick trước các lời gọi khác.
    void set_time(const Clock& clock) noexcept;

    // Người chơi vào cảnh (sau SceneEnter): dựng Player từ khối của gate, gửi QuestBook và SelfStats. false khi khối hỏng hay đã có.
    [[nodiscard]] bool attach(std::uint64_t session, const ipc::Attach& arrival, Output& out);
    // Người chơi rời (hoặc rớt): đóng phiên hội thoại, đưa trạng thái lần cuối vào Output::keeps.
    void detach(std::uint64_t session, Output& out);
    // Người chơi sang cảnh khác: đóng phiên hội thoại (gửi DialogClosed), giữ nguyên Player.
    void left_scene(std::uint64_t session, Output& out);
    // Một khung protocol của client (Relay::kUp). Khung hỏng hay loại lạ thì bỏ và đếm.
    void intent(std::uint64_t session, protocol::ByteView frame, const Surroundings& around, Output& out);
    // Ghi định kỳ trạng thái đã đổi mà chưa ghi (phần thưởng bên ngoài hội thoại). Gọi theo chu kỳ tự ghi của scene.
    void autosave(Output& out);

    [[nodiscard]] std::size_t player_count() const noexcept { return players_.size(); }
    [[nodiscard]] std::size_t ignored() const noexcept { return ignored_; }
    [[nodiscard]] const Player* find(std::uint64_t session) const noexcept;

private:
    struct Entry {
        std::unique_ptr<Player> player;
        std::uint64_t character = 0;
        // Điều đã gửi / đã ghi: so với trạng thái hiện tại để chỉ gửi và ghi khi có đổi.
        mission::Book sent_book;
        std::uint64_t sent_exp = 0;
        std::uint64_t sent_money = 0;
        std::uint64_t sent_bound = 0;
        std::uint16_t sent_level = 0;
        bool sent_once = false;
        std::optional<account::PlayRecord> saved;
        // NPC của phiên hội thoại gần nhất: các bước sau của cùng phiên vẽ lại với đúng NPC này, không tin client nhắc lại.
        std::uint32_t npc_entity = 0;
        std::string npc_name;
        // Cửa sổ tốc độ: tick đầu của giây hiện tại và số ý định đã nhận trong giây đó.
        std::uint64_t window_start = 0;
        std::uint32_t window_count = 0;
    };

    [[nodiscard]] ops::Calendar calendar() const noexcept;
    [[nodiscard]] bool allow(Entry& who) const noexcept;
    // Một lời gọi của client đã qua kiểm khung và tốc độ.
    struct Call {
        std::uint64_t session = 0;
        Entry* who = nullptr;
        const Surroundings* around = nullptr;
        Output* out = nullptr;
    };
    void on(const Call& call, const protocol::Talk& message);
    void on(const Call& call, const protocol::DialogChoose& message);
    void on(const Call& call, const protocol::QuestAccept& message);
    void on(const Call& call, const protocol::QuestTurnIn& message);
    void on(const Call& call, const protocol::QuestAbandon& message);
    void on(const Call& call, const protocol::DialogClose& message);
    // Mọi tin khác trong nhóm client không thuộc gameplay hội thoại/nhiệm vụ (di chuyển do gate xử lý).
    template <typename Other>
    void on(const Call&, const Other&) noexcept {
        ++ignored_;
    }
    void finish(const Call& call, std::uint16_t request, talk::Result& answer);
    void fill_texts(protocol::DialogOpen& open, const talk::View& view, const Names& names, const ops::Context& context) const;
    static void fill_marks(protocol::DialogOpen& open, const talk::View& view);
    void sync(std::uint64_t session, Entry& who, Output& out);
    void handle(std::uint64_t session, Entry& who, const protocol::GameClientMessage& message, const Surroundings& around,
        Output& out);
    void reply(std::uint64_t session, Entry& who, const std::string& npc_name, std::uint32_t npc_entity,
        const talk::Reply& answer, Output& out);
    void fail(std::uint64_t session, std::uint16_t request, const talk::Failure& failure, Entry& who, const std::string& npc_name,
        std::uint32_t npc_entity, Output& out);
    void notices(std::uint64_t session, const Entry& who, const std::string& npc_name, const mission::Outcome& outcome, Output& out);

    const World* world_;
    Settings settings_;
    dice::Dice dice_;
    mission::Engine engine_;
    talk::Service service_;
    std::int64_t unix_seconds_ = 0;
    std::uint64_t tick_ = 0;
    std::unordered_map<std::uint64_t, Entry> players_;
    std::size_t ignored_ = 0;
};

} // namespace game::play
