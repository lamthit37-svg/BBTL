#pragma once
// Hội thoại do máy chủ giữ (ADR-005): client chỉ gửi Ý ĐỊNH, không bao giờ gửi id script hay tên hàm.
//
//   Talk(npc)                       mở phiên, trả hộp thoại đầu của NPC + dấu nhiệm vụ nhận/nộp được tại NPC
//   ChooseOption(session, index)    chọn một lựa chọn của hộp thoại hiện tại
//   AcceptQuest(session, quest)     nhận nhiệm vụ đang được mời trong phiên
//   TurnInQuest(session, quest, c)  nộp nhiệm vụ (c: phần thưởng chọn một, -1 nếu không có nhóm đó)
//   AbandonQuest(quest)             bỏ nhiệm vụ (không cần phiên: bấm từ sổ nhiệm vụ)
//
// Phiên: mỗi nhân vật tối đa MỘT, mã tăng ngặt trên toàn Service (không bao giờ dùng lại) nên mã cũ luôn bị nhận ra là cũ. Phiên
// đóng khi: nhân vật đi xa NPC (range), đổi cảnh, NPC biến mất, quá hạn (idle tick không hoạt động), mở phiên khác, hoặc ý
// định kết thúc hội thoại (nhận, nộp). Phiên đóng vì lý do môi trường thì kết quả lỗi mang `closed = true` để zone báo client.
//
// Chọn mục: máy chủ TÍNH LẠI hộp thoại hiện tại trên trạng thái bây giờ (chạy khô, không áp hiệu ứng) và chỉ chạy lựa chọn nếu
// nó vẫn còn và đúng là lựa chọn đó (script đích, giá trị, biểu tượng, chữ). Nếu trạng thái đã đổi (đã nhận nhiệm vụ ở cửa sổ
// khác, hết điều kiện...) trả kOptionGone kèm hộp thoại mới thay vì chạy nhầm.
//
// Nguyên tử: mỗi bước `effects` của hộp thoại là MỘT giao dịch (hoặc đủ hoặc không gì cả); một lần chạy gồm nhiều bước `effects`
// dừng ở bước bị từ chối và giữ các bước trước đó đã xong, đúng như script gốc đã chạy tới đó. Khoảng cách và tồn tại của NPC do
// zone trả qua talk::World, nên Service không biết thế giới.
//
// Tất định, một luồng: lịch (ops::Calendar) và tick là đầu vào; ngẫu nhiên (chọn biến thể nhiệm vụ vòng) là dice::Dice trong
// mission::Engine. Không có khoá: Service thuộc luồng mô phỏng của cảnh/world, giống mission::Engine.

#include "ids/ids.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"
#include "talk/view.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::talk {

using SessionId = ids::StrongId<struct SessionTag, std::uint64_t>;  // 0 là không có phiên

// Khoảng cách và cảnh của nhân vật so với NPC, đo ngay lúc hỏi.
struct Presence {
    std::int32_t hero_scene = -1;
    std::int32_t npc_scene = -1;
    float distance = 0.0F;  // đơn vị thế giới (mét), 2D
};

class World {
public:
    World() = default;
    World(const World&) = delete;
    World& operator=(const World&) = delete;
    World(World&&) = delete;
    World& operator=(World&&) = delete;
    virtual ~World() = default;

    // nullopt: nhân vật hoặc NPC không còn (NPC chết, bị xoá, nhân vật rời).
    [[nodiscard]] virtual std::optional<Presence> presence(ids::CharacterId hero, const NpcRef& npc) const = 0;
};

enum class [[nodiscard]] Error : std::uint8_t {
    kNoNpc = 1,     // NPC hay nhân vật không còn trong thế giới
    kFar,           // quá xa NPC
    kSceneChanged,  // nhân vật đã sang cảnh khác với NPC
    kNoSession,     // nhân vật không có phiên đang mở
    kStale,         // mã phiên không phải phiên đang mở của nhân vật (đã thay hoặc bịa)
    kExpired,       // phiên quá hạn không hoạt động
    kBadOption,     // chỉ số lựa chọn ngoài hộp thoại hiện tại
    kOptionGone,    // lựa chọn đã đổi/biến mất khi tính lại ở trạng thái hiện tại; xem Failure::view
    kNoDialog,      // điểm vào không có hội thoại, hoặc chưa có bộ chạy (xem lý do ở Script::report)
    kNotOffered,    // nhiệm vụ không được mời / nộp được trong hộp thoại này
    kMission,       // mission::Engine hay sổ cái từ chối; xem Failure::mission
    kTooLong,       // một lần chạy vượt trần bước hay độ sâu
    kTooMany,       // quá nhiều phiên đang mở
};

[[nodiscard]] std::string_view describe(Error error) noexcept;

struct Failure {
    Error error = Error::kNoSession;
    mission::Failure mission{};  // chỉ có nghĩa với kMission
    bool closed = false;         // phiên đã đóng vì lỗi này; zone báo client đóng hộp thoại
    View view;                   // chỉ với kOptionGone: hộp thoại tính lại để client vẽ thay
};

struct Reply {
    SessionId session;            // 0 khi phiên đã đóng
    bool closed = false;
    View view;
    mission::Outcome outcome;     // thông báo và chỉ thị gộp của mọi bước đã chạy
};

using Result = std::expected<Reply, Failure>;

struct Options {
    // 5 phút không hoạt động thì đóng phiên: số tự đặt (script gốc không có phiên; xem docs/SERVER-MISSION.md).
    ids::TickSpan idle = ids::to_ticks(300'000, 20);
    // Khoảng cách tối đa: MAX_SERVER_DEFAULT_EVENT_DIST (3 * 2) + sai số 2 của AI_Human::Validate_Event (GameDefine.h, AI_Human.cpp).
    float range = 8.0F;
    std::size_t max_sessions = 200'000;
    std::size_t max_steps = 8192;  // trần bước của một lần chạy hộp thoại
};

class Service {
public:
    Service(const Script& script, mission::Engine& engine, std::span<const HandlerSpec> handlers, const Options& options);

    [[nodiscard]] Result talk(mission::Character& hero, const NpcRef& npc, const World& world, ids::Tick now,
        const ops::Calendar& calendar);
    [[nodiscard]] Result choose(mission::Character& hero, SessionId session, std::uint32_t index, const World& world,
        ids::Tick now, const ops::Calendar& calendar);
    [[nodiscard]] Result accept(mission::Character& hero, SessionId session, std::int32_t quest, const World& world,
        ids::Tick now, const ops::Calendar& calendar);
    [[nodiscard]] Result turn_in(mission::Character& hero, SessionId session, std::int32_t quest, std::int32_t choice,
        const World& world, ids::Tick now, const ops::Calendar& calendar);
    [[nodiscard]] mission::Result abandon(mission::Character& hero, std::int32_t quest, const ops::Calendar& calendar);

    // Đóng phiên của nhân vật (đăng xuất, chết, đổi cảnh do hệ thống). Không có phiên thì không làm gì.
    void close(ids::CharacterId hero) noexcept;
    // Dọn phiên quá hạn; trả số phiên đã đóng. Gọi thưa (vài giây một lần) vì phiên cũng tự kiểm hạn khi có ý định tới.
    std::size_t sweep(ids::Tick now);

    [[nodiscard]] std::size_t open_sessions() const noexcept { return sessions_.size(); }
    [[nodiscard]] std::optional<SessionId> session_of(ids::CharacterId hero) const noexcept;

private:
    struct Session {
        SessionId id;
        NpcRef npc;
        ids::Tick expires;
        std::uint32_t script = 0;     // điểm vào đang hiển thị; 0 và -1 khi phiên chỉ có lời mời nhiệm vụ kế
        std::int32_t num = -1;
        bool root = true;           // điểm vào gốc của NPC: có dấu nhiệm vụ của bảng
        std::vector<Option> options;
        std::vector<Mark> marks;
        std::int32_t panel_quest = -1;
        Mode mode = Mode::kList;
    };

    struct Built {
        View view;
        std::vector<Option> options;
        mission::Outcome outcome;
    };

    [[nodiscard]] std::expected<Session*, Failure> validate(mission::Character& hero, SessionId session, const World& world,
        ids::Tick now);
    [[nodiscard]] std::expected<Built, Failure> run(mission::Character& hero, const NpcRef& npc, std::uint32_t script,
        std::int32_t num, bool root, bool dry, const ops::Calendar& calendar);
    Result commit_open(mission::Character& hero, Session session, Built built, ids::Tick now);
    Result finish_intent(mission::Character& hero, Session& open, mission::Outcome outcome,
        const ops::Calendar& calendar);
    // Nộp thiếu thưởng chọn một: giữ phiên và mở bảng nộp. Không có hàng trong danh mục thì trả lỗi
    // gốc.
    [[nodiscard]] Result reward_sheet(Session& open, mission::Character& hero, std::int32_t quest,
        const mission::Failure& why);
    void erase(ids::CharacterId hero) noexcept;

    // NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): chương trình và Engine do cảnh sở hữu, sống lâu hơn Service, không sở hữu, không giữ qua tick (SH-04)
    const Script& script_;
    mission::Engine& engine_;
    // NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)
    std::map<std::pair<std::uint32_t, std::int32_t>, const HandlerSpec*> handlers_;
    Options options_;
    std::uint64_t next_id_ = 1;
    std::map<ids::CharacterId, Session> sessions_;
};

}  // namespace game::talk
