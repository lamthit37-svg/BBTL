/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/player.hpp
 *  PHÂN HỆ   : Client / Display / Player
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Người chơi trên màn hình: ngoại hình đã giải từ bảng, các lưới bộ phận đã
 *    tải lên GPU, tư thế theo clip (đứng, nghỉ, chạy) và hướng mặt xoay mượt.
 *    Nơi vẽ nạp lưới giúp qua MeshLoader, nên lớp này không giữ tài nguyên GPU:
 *    chỉ trỏ vào drawable do nơi vẽ sở hữu. Hướng mặt 0 là +z (quy ước của
 *    client gốc: hướng = atan2(dx, dz), mô hình quay quanh +y bằng
 *    Quaternion::FromAngleAxis).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Bản mới của dự án, theo client_app/world_view.cpp của TLBB Dev (đặt nút mẫu, Gait, Turning).

#pragma once

#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "avatar/turning.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "look/look.hpp"
#include "look/skill.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "render/forward.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <functional>
#include <future>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <vector>

namespace game::client {

// Tên lưới (tên gốc dưới Model/, không có .glb) thành drawable đã tải lên GPU của nơi vẽ; nullptr
// khi không nạp được. Drawable phải sống lâu hơn PlayerActor.
using MeshLoader = std::function<const render::Drawable*(const std::string& mesh)>;

// Một lưới của mẫu vũ khí và mẫu con (chỉ số trong look::Figure::held) mà nó thuộc về.
struct HeldMesh {
    std::size_t mount = 0;
    const render::Drawable* drawable = nullptr;
};

// Mọi bảng mà người chơi cần: ngoại hình (kèm bảng vũ khí) và đòn đánh. Phân tích TSV tốn vài chục ms, nên đọc ở luồng
// riêng từ đầu tiến trình (DisplayPreload) và đưa vào PlayerDesc::tables để khung đầu không chờ.
struct PlayerTables {
    look::Tables look;
    look::SkillTables skills;
};

// Đọc cả ba nhóm bảng dưới data_root/Table. Lỗi thì nêu bảng hỏng.
[[nodiscard]] core::Result<std::shared_ptr<const PlayerTables>> load_player_tables(const std::filesystem::path& data_root);

// Việc đọc PlayerTables ở luồng riêng. Kết quả null khi đọc lỗi: PlayerActor::create sẽ đọc lại và nêu lỗi.
using PlayerTablesJob = std::future<std::shared_ptr<const PlayerTables>>;
[[nodiscard]] PlayerTablesJob start_player_tables(std::filesystem::path data_root);

struct PlayerDesc {
    // Thư mục dữ liệu client: Table/ và Model/.
    std::filesystem::path data_root;
    look::Race race = look::Race::kFemale;
    // Có thì dùng khối này; không thì bộ mặc định của giới.
    std::optional<look::Look> look;
    // Vật phẩm khe 0 (vũ khí) đang cầm; có thì đè loại và hình vũ khí của look (look::equip_weapon).
    // Cần bảng vũ khí trong Table/.
    std::optional<std::uint32_t> weapon_item;
    // Vật phẩm đá quý gắn vào vũ khí (Get_EquipGem của ref); 0 là không có. Cho hiệu ứng đồ (look::gem_effect).
    std::uint32_t weapon_gem = 0;
    // Skill đã học (hero.skills): clip của mọi bước của chúng được nạp theo giới và loại vũ khí cầm. Rỗng thì
    // không nạp bảng đòn đánh.
    std::vector<std::uint32_t> skills;
    // Có thì người mẫu là mẫu riêng của môn (Table/sect_models.tsv), không phải look ở trên.
    std::optional<std::uint8_t> sect;
    // Bảng đã đọc sẵn (load_player_tables). Không có thì create tự đọc phần mà desc cần.
    std::shared_ptr<const PlayerTables> tables;
};

// Một bước của một skill (SkillTemplate_V1 id và số bước).
struct StrikeCall {
    std::uint32_t skill = 0;
    std::uint32_t step = 0;
};

// Chỗ đứng của người chơi trong một khung: chân trên mặt đất (toạ độ thế giới), hướng mặt logic
// (radian) và đang đi hay không.
struct Stand {
    math::Point3 foot;
    float facing = 0.0F;
    // Tỉ lệ quanh chân; người mẫu của màn tạo đứng to gấp rưỡi.
    float scale = 1.0F;
    bool is_moving = false;
    // Cú nhảy bắt đầu trong khung này (kJumpStand hay kJumpRun của avatar::Stance), và chạm đất
    // trong khung này. Bắt đầu áp trước chạm đất.
    std::optional<avatar::Stance> jump;
    bool has_landed = false;
    // Đòn bắt đầu trong khung này; không có clip cho đòn đó thì bỏ qua.
    std::optional<StrikeCall> strike;
};

// Khối con của kịch bản vừa tới mốc trong một khung (AnimEffect, Ribbon, Sound, SceneLight), ở toạ độ thế giới: hiệu ứng
// dựng ở position, orientation; âm thanh chỉ cần name (đường dẫn trong SoundInfo). Nơi vẽ lấy bằng take_cues.
struct SkillCue {
    look::EventKind kind = look::EventKind::kAnimEffect;
    std::string name;
    ogre::Vec3 position;
    ogre::Quat orientation;
    // Attach của kịch bản: hiệu ứng bám theo điểm gắn thay vì đặt một lần.
    bool is_attached = false;
    // Dấu để nơi vẽ nối hiệu ứng bám với follows() (CueFollow::token); 0 khi không bám.
    std::uint32_t token = 0;
    // Ribbon: chuỗi PointCount=…|LifeTime=… của all.skill. Rỗng với hạt và tiếng.
    std::string props;
};

// Vị trí mới của một hiệu ứng bám (SkillCue::token) trong khung: nơi vẽ dời hệ hạt theo đó.
struct CueFollow {
    std::uint32_t token = 0;
    ogre::Vec3 position;
    ogre::Quat orientation;
};

// Chỗ của hiệu ứng đồ trong khung: mẫu con (chỉ số trong figure().held; tên effect và màu ở đó) và điểm 武器特效点
// của nó ở toạ độ thế giới.
struct GearEffect {
    std::size_t mount = 0;
    ogre::Vec3 position;
    ogre::Quat orientation;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
class PlayerActor {
public:
    // Nạp bảng, giải bộ mặc định của giới, nạp skeleton, clip và lưới bộ phận. Thiếu một lưới thì
    // bỏ lưới đó và ghi log; lỗi khi thiếu bảng, skeleton hay clip.
    [[nodiscard]] static core::Result<PlayerActor> create(const PlayerDesc& desc, const MeshLoader& load_mesh);

    // Dựng tư thế và ma trận đặt cho khung ở thời điểm now.
    [[nodiscard]] core::Status update(core::Clock::time_point now, const Stand& stand);

    // Thêm một instance cho mỗi bộ phận và mỗi lưới của vũ khí; ma trận skin trỏ vào bộ đệm của lần
    // update gần nhất.
    void append(std::vector<render::Instance>& out) const;

    [[nodiscard]] const look::Figure& figure() const noexcept { return avatar_.figure(); }
    // Số bước đã nạp clip của skill, theo thứ tự bước; rỗng khi skill không có đòn cho người chơi này.
    [[nodiscard]] std::vector<std::uint32_t> steps_of(std::uint32_t skill) const;
    // Start_MagicSend lúc now. roll là giá trị ngẫu nhiên của nơi gọi (chỉ kRandom dùng). nullopt khi
    // hoãn tới hết clip, hoặc skill không có clip phát được. Hoãn thì is_locked giữ lệnh sau.
    [[nodiscard]] std::optional<std::uint32_t> accept_strike(std::uint32_t skill, std::uint32_t roll,
        core::Clock::time_point now);
    // Từ lúc bắt đầu bước call tới mốc đòn trúng đầu tiên của clip (HitTime), theo tốc độ phát thật; 0 khi bước không có clip
    // hay kịch bản không có mốc trúng.
    [[nodiscard]] std::chrono::milliseconds hit_after(const StrikeCall& call) const;
    // Đang trong đòn mà chưa tới BreakTime, hoặc đã nhận lệnh nối và đang chờ hết clip (m_bCanBreak
    // bị Start_MagicSend đặt lại false). Lệnh đi, nhảy, đòn khác phải chờ.
    [[nodiscard]] bool is_locked(core::Clock::time_point now) const;
    // Chuyển các khối vừa tới mốc ở update gần nhất sang out (cộng thêm), rồi xoá khỏi người chơi.
    void take_cues(std::vector<SkillCue>& out);
    // Chỗ mới của các hiệu ứng bám đang theo (SkillCue::token), tính ở update gần nhất.
    [[nodiscard]] std::span<const CueFollow> follows() const noexcept { return follows_; }
    // Thôi theo hiệu ứng đó (nơi vẽ báo hiệu ứng đã hết).
    void drop_follow(std::uint32_t token);
    // Hiệu ứng đồ ở update gần nhất: mỗi mẫu con có hiệu ứng một phần tử.
    [[nodiscard]] std::span<const GearEffect> gear_effects() const noexcept { return gear_; }

private:
    PlayerActor(avatar::Avatar avatar, std::vector<const render::Drawable*> parts, std::vector<HeldMesh> held,
        bool fidget, bool demo);

    [[nodiscard]] avatar::StrikePlan plan_of(std::size_t index) const;
    // Clip của bước này phát được: có trong avatar và length, rate đều dương (NaN thì không).
    [[nodiscard]] bool can_play(std::uint32_t skill, std::uint32_t step) const;
    // Bước thứ slot trong các đòn của skill, theo thứ tự strikes(). Không cấp phát.
    [[nodiscard]] std::optional<std::uint32_t> step_at(std::uint32_t skill, std::uint32_t slot) const noexcept;
    // Chỉ gọi khi chain_.do_next. finish_chain chạy trước, kể cả khi bước không phát được.
    [[nodiscard]] bool play_deferred(core::Clock::time_point now, const Stand& stand);
    void release_chain(core::Clock::time_point now, const Stand& stand);
    void begin_strike(core::Clock::time_point now, const StrikeCall& call);
    void fire_cues(const avatar::Playing& playing, const Stand& drawn);
    void place_gear(const Stand& drawn);
    void place_follows(const Stand& drawn);

    avatar::Avatar avatar_;
    avatar::Skinner skinner_;
    avatar::Gait gait_;
    avatar::Turning turning_;
    avatar::ClipLengths lengths_;
    std::vector<const render::Drawable*> parts_;
    std::vector<HeldMesh> held_;
    // Ma trận từng mẫu con trong không gian mẫu nhân vật, dựng lại mỗi update.
    std::vector<math::Matrix4> mounts_;
    math::Matrix4 placed_ = math::Matrix4::identity();
    // Đòn đang phát: chỉ số trong Avatar::strikes() và phần clip đã quét qua (khối con ở phần đó đã bắn).
    struct Active {
        std::size_t index = 0;
        float fraction = 0.0F;
    };
    std::optional<Active> active_;
    // Phiên đòn của người này (Start_MagicSend). Không dùng chung giữa hai nhân vật.
    look::Chain chain_;
    std::vector<SkillCue> cues_;
    std::vector<GearEffect> gear_;
    // Hiệu ứng bám đã bắn: đòn, khối con và dấu; chỗ mới của chúng tính lại mỗi update vào follows_.
    struct Follower {
        std::uint32_t token = 0;
        std::size_t strike = 0;
        std::size_t event = 0;
    };
    std::vector<Follower> followers_;
    std::vector<CueFollow> follows_;
    std::uint32_t last_token_ = 0;
    // Môn phái: khung đầu phát bài múa một lần. fidget sai thì không múa lại lúc nghỉ.
    bool cue_demo_ = false;
};

} // namespace game::client
