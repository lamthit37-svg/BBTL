/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/trace.cpp
 *  PHÂN HỆ   : Client / Session / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt session/trace.hpp: bộ ghi mở tệp một lần theo biến môi trường, mỗi
 *    dòng xả ngay dưới một khoá.
 *  - Chỉ tin của phiên (sau bắt tay) được ghi; Hello và Welcome do link::Link
 *    xử lý nên không có dòng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/session/trace.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <variant>

namespace game::client::session::trace {
namespace {

constexpr const char* kVariable = "THIENLONG_NET_TRACE";
constexpr std::string_view kSent = "gửi";
constexpr std::string_view kReceived = "nhận";

// Tên kiểu tin lấy từ chữ ký hàm của trình dịch (không phải bảng tay): thêm tin vào giao thức là
// có tên ngay. Cắt phần sau dấu cách hay "::" cuối cùng.
template <typename Message>
[[nodiscard]] constexpr std::string_view message_name() noexcept {
#if defined(_MSC_VER)
    constexpr std::string_view kSignature = __FUNCSIG__;
    constexpr std::string_view kHead = "message_name<";
    constexpr std::string_view kTail = ">(void)";
#else
    constexpr std::string_view kSignature = __PRETTY_FUNCTION__;
    constexpr std::string_view kHead = "Message = ";
    constexpr std::string_view kTail = "]";
#endif
    constexpr std::size_t kFirst = kSignature.find(kHead) + kHead.size();
    constexpr std::size_t kLast = kSignature.rfind(kTail);
    constexpr std::string_view kFull = kSignature.substr(kFirst, kLast - kFirst);
    constexpr std::size_t kCut = kFull.find_last_of(": ");
    constexpr std::size_t kFrom = kCut == std::string_view::npos ? 0 : kCut + 1;
    return kFull.substr(kFrom);
}

[[nodiscard]] std::optional<std::string> trace_target() {
#if defined(_WIN32)
    char* value = nullptr;
    std::size_t length = 0;
    if (_dupenv_s(&value, &length, kVariable) != 0 || value == nullptr) return std::nullopt;
    std::string text(value);
    // NOLINTNEXTLINE(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory): của _dupenv_s
    std::free(value);
    if (text.empty()) return std::nullopt;
    return text;
#else
    // Đọc một lần lúc dựng bộ ghi, trước khi luồng nào đổi môi trường.
    const char* value = std::getenv(kVariable); // NOLINT(concurrency-mt-unsafe)
    if (value == nullptr || *value == '\0') return std::nullopt;
    return std::string(value);
#endif
}

[[nodiscard]] bool is_control(char letter) noexcept {
    return static_cast<unsigned char>(letter) < 0x20;
}

// Tab hay xuống dòng trong tên nhân vật không được làm vỡ cột của dòng vết.
[[nodiscard]] std::string clean(std::string_view text) {
    std::string out(text);
    std::ranges::replace_if(out, is_control, ' ');
    return out;
}

class Recorder {
public:
    Recorder() noexcept {
        try {
            const std::optional<std::string> target = trace_target();
            if (!target) return;
            out_.open(std::filesystem::path(*target), std::ios::app | std::ios::binary);
            is_on_.store(out_.is_open(), std::memory_order_relaxed);
        } catch (const std::exception&) {
            is_on_.store(false, std::memory_order_relaxed);
        }
    }
    ~Recorder() = default;
    Recorder(const Recorder&) = delete;
    Recorder& operator=(const Recorder&) = delete;
    Recorder(Recorder&&) = delete;
    Recorder& operator=(Recorder&&) = delete;

    [[nodiscard]] bool is_on() const noexcept { return is_on_.load(std::memory_order_relaxed); }

    // giờ_ms (từ lúc mở tệp), hướng, tên, trường chính; mỗi dòng xả ngay để công cụ đọc kịp khi
    // tiến trình bị dừng giữa chừng.
    void line(std::string_view way, std::string_view name, std::string_view fields) noexcept {
        try {
            const std::scoped_lock<std::mutex> locked(guard_);
            if (!is_on()) return;
            const auto since = std::chrono::steady_clock::now() - started_;
            const auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(since);
            const std::string body = clean(fields);
            out_ << millis.count() << '\t' << way << '\t' << name << '\t' << body << '\n';
            out_.flush();
            if (!out_) is_on_.store(false, std::memory_order_relaxed);
        } catch (const std::exception&) {
            is_on_.store(false, std::memory_order_relaxed);
        }
    }

private:
    // guard_ bảo vệ out_ (một dòng không xen vào dòng khác).
    std::mutex guard_;
    std::ofstream out_;
    std::atomic<bool> is_on_{false};
    const std::chrono::steady_clock::time_point started_ = std::chrono::steady_clock::now();
};

[[nodiscard]] Recorder& recorder() noexcept {
    static Recorder instance;
    return instance;
}

// Trường chính của từng tin. Mật khẩu và vé không bao giờ vào dòng: SignIn, CreateAccount và Login
// chỉ ghi tên tài khoản. Tin không có đặc tả riêng thì để trống.
template <typename Message>
[[nodiscard]] std::string fields_of(const Message& /*message*/) {
    return {};
}

std::string fields_of(const protocol::SignIn& message) {
    return std::format("account={}", message.account);
}

std::string fields_of(const protocol::CreateAccount& message) {
    return std::format("account={}", message.account);
}

std::string fields_of(const protocol::Login& message) {
    return std::format("account={}", message.account);
}

std::string fields_of(const protocol::CreateCharacter& message) {
    const auto gender = std::to_underlying(message.gender);
    const std::string look = std::format("face={} hair={}", message.face, message.hair);
    const std::uint16_t portrait = message.portrait;
    const std::uint16_t set = message.equip_set;
    const std::string pick = std::format("portrait={} equip_set={}", portrait, set);
    return std::format("name={} gender={} {} {}", message.name, gender, look, pick);
}

std::string fields_of(const protocol::DeleteCharacter& message) {
    return std::format("character={}", message.character);
}

std::string fields_of(const protocol::EnterGame& message) {
    return std::format("character={}", message.character);
}

std::string fields_of(const protocol::Move& message) {
    return std::format("x_cm={} z_cm={} tick={}", message.x_cm, message.z_cm, message.tick);
}

std::string fields_of(const protocol::Position& message) {
    return std::format("x_cm={} z_cm={} tick={}", message.x_cm, message.z_cm, message.tick);
}

std::string fields_of(const protocol::Ping& message) {
    return std::format("client_time={}", message.client_time.count());
}

std::string fields_of(const protocol::Pong& message) {
    return std::format("client_time={}", message.client_time.count());
}

std::string fields_of(const protocol::Talk& message) {
    return std::format("npc={}", message.npc);
}

std::string fields_of(const protocol::DialogChoose& message) {
    return std::format("session={} index={}", message.session, message.index);
}

std::string fields_of(const protocol::DialogClose& message) {
    return std::format("session={}", message.session);
}

std::string fields_of(const protocol::QuestAccept& message) {
    return std::format("session={} quest={}", message.session, message.quest);
}

std::string fields_of(const protocol::QuestTurnIn& message) {
    return std::format("session={} quest={}", message.session, message.quest);
}

std::string fields_of(const protocol::QuestAbandon& message) {
    return std::format("quest={}", message.quest);
}

std::string fields_of(const protocol::CastSkill& message) {
    const std::string spot = std::format("x_cm={} z_cm={}", message.x_cm, message.z_cm);
    return std::format("skill={} target={} {}", message.skill, message.target, spot);
}

std::string fields_of(const protocol::PickUp& message) {
    return std::format("drop={}", message.drop);
}

std::string fields_of(const protocol::Reject& message) {
    const auto code = std::to_underlying(message.code);
    return std::format("request={} code={}", message.request, code);
}

std::string fields_of(const protocol::Goodbye& message) {
    const auto reason = std::to_underlying(message.reason);
    return std::format("reason={}", reason);
}

std::string fields_of(const protocol::CharacterList& message) {
    std::string names;
    for (const protocol::CharacterSummary& one : message.characters)
        names += one.name + ",";
    const std::size_t count = message.characters.size();
    return std::format("count={} can_create={} names={}", count, message.can_create, names);
}

std::string fields_of(const protocol::SceneEnter& message) {
    const std::string spot = std::format("x_cm={} z_cm={}", message.x_cm, message.z_cm);
    return std::format("scene={} {} self_id={}", message.scene, spot, message.self_id);
}

std::string fields_of(const protocol::EntityAppear& message) {
    const auto kind = std::to_underlying(message.kind);
    return std::format("id={} kind={} name={}", message.id, kind, message.name);
}

std::string fields_of(const protocol::EntityDisappear& message) {
    return std::format("id={}", message.id);
}

std::string fields_of(const protocol::EntityPos& message) {
    return std::format("id={} x_cm={} z_cm={}", message.id, message.x_cm, message.z_cm);
}

std::string fields_of(const protocol::DialogOpen& message) {
    const auto count = message.choices.size();
    return std::format("session={} npc={} choices={}", message.session, message.npc, count);
}

std::string fields_of(const protocol::DialogClosed& message) {
    return std::format("session={}", message.session);
}

std::string fields_of(const protocol::SkillCast& message) {
    const std::string who = std::format("source={} target={}", message.source, message.target);
    return std::format("{} skill={}", who, message.skill);
}

std::string fields_of(const protocol::CombatEvent& message) {
    const std::string who = std::format("source={} target={}", message.source, message.target);
    return std::format("{} skill={} value={}", who, message.skill, message.value);
}

std::string fields_of(const protocol::EntityDied& message) {
    return std::format("id={} killer={}", message.id, message.killer);
}

// Một dòng cho một tin: tên lấy từ kiểu, trường từ fields_of.
struct Liner {
    std::string_view way;

    template <typename Message>
    void operator()(const Message& message) const {
        const std::string fields = fields_of(message);
        recorder().line(way, message_name<Message>(), fields);
    }
};

template <typename Variant>
void write_line(std::string_view way, const Variant& message) {
    std::visit(Liner{way}, message);
}

} // namespace

bool is_on() noexcept {
    return recorder().is_on();
}

void sent(const protocol::GameClientMessage& message) {
    if (is_on()) write_line(kSent, message);
}

void sent(const protocol::AuthClientMessage& message) {
    if (is_on()) write_line(kSent, message);
}

void received(const protocol::GameServerMessage& message) {
    if (is_on()) write_line(kReceived, message);
}

void received(const protocol::AuthServerMessage& message) {
    if (is_on()) write_line(kReceived, message);
}

} // namespace game::client::session::trace
