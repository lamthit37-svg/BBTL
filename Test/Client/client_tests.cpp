/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Client/client_tests.cpp
 *  PHÂN HỆ   : Client / Client Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test của client: tuỳ chọn dòng lệnh, việc chọn cảnh và sổ assets của bản
 *    di động. Sai cách dùng (khoá lạ, khoá không có giá trị, số vòng lặp không
 *    phải số nguyên dương) phải bị từ chối thay vì chạy với giá trị đoán. Chạy
 *    không đối số (bấm đúp exe) là hợp lệ: cảnh được chọn là cảnh duy nhất của
 *    thư mục dữ liệu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/assets.hpp"
#include "client/display/auto_login.hpp"
#include "client/display/display.hpp"
#include "client/display/frame_fit.hpp"
#include "client/display/policy.hpp"
#include "client/options.hpp"
#include "client/viewer/client_size.hpp"
#include "client/viewer/viewer.hpp"
#include "core/check.hpp"
#include "io/file.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using Text = std::string_view;

// Số đo từ System.cfg và Bin64/Game.exe của client 2026 (xem client/viewer/client_size.hpp).
static_assert(client::kDefaultClientSize == client::ClientSize{.width = 1280, .height = 720});
static_assert(client::kMinClientSize == client::ClientSize{.width = 800, .height = 600});

void options_take_scene_alone(Context& context) {
    constexpr std::array<Text, 2> kArguments{"--scene", "huoyangu"};
    const std::optional<client::Options> options = client::parse_options(kArguments);
    context.expect(options.has_value(), "chỉ cần --scene là đủ");
    if (!options) return;
    context.expect(options->scene_name == "huoyangu", "tên cảnh giữ nguyên");
    context.expect(options->data_folder.empty(), "không nêu --data thì để rỗng");
    context.expect(options->shot_path.empty(), "không nêu --shot thì để rỗng");
    context.expect(!options->frames.has_value(), "không nêu --frames thì chạy tới khi đóng");
}

void options_take_data_folder_and_frames(Context& context) {
    constexpr std::array<Text, 6> kArguments{"--frames", "120", "--data", "D:/dữ liệu", "--scene", "大理"};
    const std::optional<client::Options> options = client::parse_options(kArguments);
    context.expect(options.has_value(), "ba khoá theo thứ tự bất kỳ");
    if (!options) return;
    context.expect(options->scene_name == "大理", "tên cảnh UTF-8 giữ nguyên");
    context.expect(io::utf8_of(options->data_folder) == "D:/dữ liệu", "thư mục dữ liệu UTF-8");
    context.expect(options->frames == 120U, "số vòng lặp đọc thành số");
}

struct BadCase {
    std::array<Text, 4> arguments;
    std::size_t count = 0;
    Text what;
};

constexpr std::array kBadCases{
    BadCase{.arguments = {"--scene"}, .count = 1, .what = "khoá không có giá trị"},
    BadCase{.arguments = {"--what", "1", "--scene", "a"}, .count = 4, .what = "khoá lạ"},
    BadCase{.arguments = {"--scene", "a", "--frames", "abc"}, .count = 4, .what = "vòng lặp chữ"},
    BadCase{.arguments = {"--scene", "a", "--frames", "0"}, .count = 4, .what = "không vòng nào"},
    BadCase{.arguments = {"--scene", "a", "--frames", "12x"}, .count = 4, .what = "số kèm rác"},
    BadCase{.arguments = {"--scene", "a", "--frames", "-3"}, .count = 4, .what = "số âm"},
    BadCase{.arguments = {"--size", "1280"}, .count = 2, .what = "cỡ thiếu dấu tách"},
    BadCase{.arguments = {"--size", "1280x"}, .count = 2, .what = "cỡ thiếu cạnh cao"},
    BadCase{.arguments = {"--size", "x720"}, .count = 2, .what = "cỡ thiếu cạnh rộng"},
    BadCase{.arguments = {"--size", "12a0x720"}, .count = 2, .what = "cạnh có chữ"},
    BadCase{.arguments = {"--size", "1280x720x60"}, .count = 2, .what = "cỡ thừa đoạn"},
    BadCase{.arguments = {"--size", "1280 x720"}, .count = 2, .what = "cỡ có dấu cách"},
    BadCase{.arguments = {"--size", "-1280x720"}, .count = 2, .what = "cạnh âm"},
    BadCase{.arguments = {"--size", "799x600"}, .count = 2, .what = "rộng dưới 800"},
    BadCase{.arguments = {"--size", "800x599"}, .count = 2, .what = "cao dưới 600"},
    BadCase{.arguments = {"--size", "0x0"}, .count = 2, .what = "cỡ bằng không"},
    BadCase{.arguments = {"--size", "16385x720"}, .count = 2, .what = "rộng quá trần"},
    BadCase{.arguments = {"--size", "1280x16385"}, .count = 2, .what = "cao quá trần"},
};

void options_reject_wrong_usage(Context& context) {
    for (const BadCase& one : kBadCases) {
        const std::span<const Text> arguments = std::span(one.arguments).first(one.count);
        context.expect(!client::parse_options(arguments).has_value(), one.what);
    }
}

void options_take_shot_path(Context& context) {
    constexpr std::array<Text, 4> kArguments{"--scene", "a", "--shot", "khung.png"};
    const std::optional<client::Options> options = client::parse_options(kArguments);
    context.expect(options.has_value(), "--shot ghép được với khoá khác");
    if (!options) return;
    context.expect(io::utf8_of(options->shot_path) == "khung.png", "đường dẫn ảnh chụp UTF-8");
}

// --size nhận RỘNGxCAO hoặc RỘNG,CAO (cách System.cfg ghi View_Resoution) ở khoảng 800x600..16384;
// không nêu thì để trống cho viewer dùng kDefaultClientSize.
void options_take_client_size(Context& context) {
    constexpr client::ClientSize kFullHd{.width = 1920, .height = 1080};
    constexpr client::ClientSize kXga{.width = 1024, .height = 768};
    constexpr std::array<Text, 2> kLetter{"--size", "1920x1080"};
    const std::optional<client::Options> letter = client::parse_options(kLetter);
    context.expect(letter.has_value(), "--size nhận dạng RỘNGxCAO");
    if (letter) context.expect(letter->client_size == kFullHd, "cỡ 1920x1080 đọc đúng");
    constexpr std::array<Text, 2> kComma{"--size", "1024,768"};
    const std::optional<client::Options> comma = client::parse_options(kComma);
    context.expect(comma.has_value(), "--size nhận dấu phẩy như System.cfg");
    if (comma) context.expect(comma->client_size == kXga, "cỡ 1024,768 đọc đúng");
    constexpr std::array<Text, 2> kCapital{"--size", "1920X1080"};
    const std::optional<client::Options> capital = client::parse_options(kCapital);
    context.expect(capital.has_value(), "X hoa cũng là dấu tách");
    if (capital) context.expect(capital->client_size == kFullHd, "cỡ 1920X1080 đọc đúng");
    constexpr std::array<Text, 2> kSceneOnly{"--scene", "a"};
    const std::optional<client::Options> plain = client::parse_options(kSceneOnly);
    if (plain) context.expect(!plain->client_size.has_value(), "không nêu --size thì để trống");
}

// Thủ tục đăng nhập của client 2026 luôn mở vùng chơi 0x500 x 0x2d0 (Game.exe 0x140631270), kể cả
// khi View_Resoution khác; màn chơi dùng cỡ đã chọn.
void login_window_ignores_chosen_size(Context& context) {
    constexpr client::ClientSize kLoginSeen{.width = 1280, .height = 720};
    constexpr client::ClientSize kChosen{.width = 1024, .height = 768};
    client::ViewerDesc desc;
    desc.client_size = kChosen;
    context.expect(client::client_size_of(desc) == kChosen, "màn chơi dùng cỡ đã chọn");
    desc.procedure = client::Procedure::kLogin;
    context.expect(client::client_size_of(desc) == kLoginSeen, "đăng nhập bỏ qua cỡ đã chọn");
    desc.client_size.reset();
    context.expect(client::client_size_of(desc) == kLoginSeen, "đăng nhập không chọn cỡ cũng 1280 x 720");
    desc.procedure = client::Procedure::kPlay;
    context.expect(client::client_size_of(desc) == client::kDefaultClientSize, "màn chơi không chọn thì mặc định");
}

// Màn đăng nhập của máy tính bảng 1280x800 (16:10) vào khung 1280x720: dải đen 40 điểm trên và dưới.
void login_frame_letterboxes_tablet(Context& context) {
    using Rect = client::FrameRect;
    const Rect tablet = client::fit_frame(1280, 800, 1280, 720);
    context.expect(tablet == Rect{.x = 0, .y = 40, .width = 1280, .height = 720}, "16:10 thu về 16:9");
    const Rect same = client::fit_frame(1280, 720, 1280, 720);
    context.expect(same == Rect{.x = 0, .y = 0, .width = 1280, .height = 720}, "đúng tỉ lệ thì trọn màn");
    const Rect wide = client::fit_frame(2400, 1080, 1280, 720);
    context.expect(wide == Rect{.x = 240, .y = 0, .width = 1920, .height = 1080}, "màn dài thì dải đen hai bên");
    const Rect big = client::fit_frame(1920, 1200, 1280, 720);
    context.expect(big == Rect{.x = 0, .y = 60, .width = 1920, .height = 1080}, "cỡ lớn vẫn giữ tỉ lệ");
}

// Bảng chỉ thiết kế cho 1280x720 đặt giữa màn, cỡ vật lý theo mật độ: không lớn hơn 1280x720 điểm giao diện nhân mật độ,
// thu nhỏ giữ tỉ lệ khi màn không đủ chỗ. Mật độ không dương coi như 1.
void placed_frame_caps_by_density(Context& context) {
    using Rect = client::FrameRect;
    const Rect tablet = client::placed_frame(1280, 800, 1.0F);
    context.expect(tablet == Rect{.x = 0, .y = 40, .width = 1280, .height = 720}, "tablet 160 dpi: 1280x720 giữa màn");
    const Rect same = client::placed_frame(1280, 720, 1.0F);
    context.expect(same == Rect{.x = 0, .y = 0, .width = 1280, .height = 720}, "PC 1280x720 trọn màn");
    const Rect retina = client::placed_frame(2732, 2048, 2.0F);
    context.expect(retina == Rect{.x = 86, .y = 304, .width = 2560, .height = 1440}, "iPad Pro mật độ 2: 2560x1440");
    const Rect cramped = client::placed_frame(2048, 1536, 2.0F);
    context.expect(cramped == Rect{.x = 0, .y = 192, .width = 2048, .height = 1152}, "không đủ chỗ thì thu giữ tỉ lệ");
    const Rect roomy = client::placed_frame(1920, 1200, 1.0F);
    context.expect(roomy == Rect{.x = 320, .y = 240, .width = 1280, .height = 720}, "màn lớn mật độ 1 giữ 1:1");
    const Rect broken = client::placed_frame(1280, 800, 0.0F);
    context.expect(broken == tablet, "mật độ hỏng coi như 1");
}

// Cỡ suy biến không được chia cho 0: trả trọn màn để khung vẫn vẽ được.
void login_frame_survives_empty_sizes(Context& context) {
    using Rect = client::FrameRect;
    const Rect no_design = client::fit_frame(1280, 800, 0, 720);
    context.expect(no_design == Rect{.x = 0, .y = 0, .width = 1280, .height = 800}, "khung thiết kế rỗng");
    const Rect no_screen = client::fit_frame(0, 0, 1280, 720);
    context.expect(no_screen == Rect{}, "màn rỗng thì khung rỗng");
}

// Chạm vào mép khung phải ra 0 và 1, chạm vào dải đen thì ra ngoài [0, 1] để giao diện không nhận.
void login_frame_maps_touch_to_frame(Context& context) {
    const client::FrameRect frame = client::fit_frame(1280, 800, 1280, 720);
    const client::FrameSpan across{.origin = frame.x, .length = frame.width};
    const client::FrameSpan down{.origin = frame.y, .length = frame.height};
    const auto is_near = [](float value, float want) { return std::abs(value - want) < 1e-5F; };
    context.expect(is_near(client::unit_in_frame(0.5F, 1280, across), 0.5F), "giữa ngang vẫn giữa");
    context.expect(is_near(client::unit_in_frame(0.5F, 800, down), 0.5F), "giữa dọc vẫn giữa");
    context.expect(is_near(client::unit_in_frame(0.05F, 800, down), 0.0F), "mép trên khung là 0");
    context.expect(is_near(client::unit_in_frame(0.95F, 800, down), 1.0F), "mép dưới khung là 1");
    context.expect(client::unit_in_frame(0.0F, 800, down) < 0.0F, "dải đen trên ra ngoài khung");
    context.expect(client::unit_in_frame(1.0F, 800, down) > 1.0F, "dải đen dưới ra ngoài khung");
    context.expect(is_near(client::unit_in_frame(0.25F, 800, client::FrameSpan{}), 0.25F), "khung rỗng giữ nguyên");
}

void options_accept_client_size_limits(Context& context) {
    constexpr std::array<Text, 2> kSmallest{"--size", "800x600"};
    const std::optional<client::Options> smallest = client::parse_options(kSmallest);
    context.expect(smallest.has_value(), "800x600 là cỡ nhỏ nhất hợp lệ");
    constexpr std::array<Text, 2> kLargest{"--size", "16384x16384"};
    const std::optional<client::Options> largest = client::parse_options(kLargest);
    context.expect(largest.has_value(), "16384x16384 là cỡ lớn nhất hợp lệ");
}

void options_take_bare_validate_flag(Context& context) {
    constexpr std::array<Text, 1> kAlone{"--validate"};
    const std::optional<client::Options> alone = client::parse_options(kAlone);
    context.expect(alone.has_value(), "--validate đứng một mình là hợp lệ");
    if (alone) context.expect(alone->validate == true, "cờ đơn bật lớp kiểm tra");
    constexpr std::array<Text, 5> kMixed{"--scene", "a", "--validate", "--frames", "2"};
    const std::optional<client::Options> mixed = client::parse_options(kMixed);
    context.expect(mixed.has_value(), "cờ đơn xen giữa các cặp khoá-giá trị");
    if (!mixed) return;
    context.expect(mixed->validate == true, "cờ đơn đọc được khi lẫn cặp");
    context.expect(mixed->scene_name == "a", "cặp khoá-giá trị quanh cờ đơn vẫn đọc");
    context.expect(mixed->frames == 2U, "cặp cuối danh sách vẫn đọc");
    constexpr std::array<Text, 2> kOptionsShot{"--scene", "a"};
    const std::optional<client::Options> plain = client::parse_options(kOptionsShot);
    if (plain) context.expect(!plain->validate.has_value(), "không nêu --validate thì để trống");
}

// --login là cờ đơn: mở thủ tục đăng nhập thay vì vào thẳng một cảnh.
void options_take_bare_login_flag(Context& context) {
    constexpr std::array<Text, 1> kAlone{"--login"};
    const std::optional<client::Options> alone = client::parse_options(kAlone);
    context.expect(alone.has_value(), "--login đứng một mình là hợp lệ");
    if (alone) context.expect(alone->is_login, "cờ đơn chọn thủ tục đăng nhập");
    constexpr std::array<Text, 4> kMixed{"--login", "--frames", "3", "--validate"};
    const std::optional<client::Options> mixed = client::parse_options(kMixed);
    context.expect(mixed.has_value(), "--login đứng trước cặp khoá-giá trị và cờ đơn khác");
    if (!mixed) return;
    context.expect(mixed->is_login && mixed->validate == true, "hai cờ đơn cùng đọc được");
    context.expect(mixed->frames == 3U, "cặp sau --login vẫn đọc");
    constexpr std::array<Text, 2> kPlain{"--scene", "a"};
    const std::optional<client::Options> plain = client::parse_options(kPlain);
    if (plain) context.expect(!plain->is_login, "không nêu --login thì vào thẳng cảnh");
    constexpr std::array<Text, 2> kValued{"--login", "x"};
    context.expect(!client::parse_options(kValued).has_value(), "--login không nhận giá trị");
}

// --bare là cờ đơn: không vẽ lớp giao diện, để chụp cảnh nền.
void options_take_bare_flag(Context& context) {
    constexpr std::array<Text, 4> kMixed{"--login", "--bare", "--shot", "nen.png"};
    const std::optional<client::Options> mixed = client::parse_options(kMixed);
    context.expect(mixed.has_value(), "--bare đứng cùng cờ đơn khác và cặp khoá-giá trị");
    if (!mixed) return;
    context.expect(mixed->is_bare && mixed->is_login, "hai cờ đơn cùng đọc được");
    context.expect(!mixed->shot_path.empty(), "cặp sau --bare vẫn đọc");
    constexpr std::array<Text, 1> kPlain{"--login"};
    const std::optional<client::Options> plain = client::parse_options(kPlain);
    if (plain) context.expect(!plain->is_bare, "không nêu --bare thì vẽ giao diện");
    constexpr std::array<Text, 2> kValued{"--bare", "x"};
    context.expect(!client::parse_options(kValued).has_value(), "--bare không nhận giá trị");
}

// --creature nhận danh sách id mẫu cách nhau dấu phẩy; phần rỗng, chữ hay quá nhiều id là sai cách dùng.
void options_take_creature_list(Context& context) {
    constexpr std::array<Text, 2> kList{"--creature", "6,9,36"};
    const std::optional<client::Options> list = client::parse_options(kList);
    context.expect(list.has_value(), "danh sách id hợp lệ");
    if (list) context.expect(list->creatures == std::vector<std::uint32_t>({6, 9, 36}), "id giữ thứ tự");
    constexpr std::array<Text, 2> kTrailing{"--creature", "7,"};
    const std::optional<client::Options> trailing = client::parse_options(kTrailing);
    context.expect(trailing.has_value() && trailing->creatures == std::vector<std::uint32_t>({7}), "dấu phẩy cuối được bỏ");
    for (const Text bad : {Text{""}, Text{","}, Text{"6,,9"}, Text{"6,x"}, Text{"-1"}, Text{"12x"}}) {
        const std::array<Text, 2> arguments{"--creature", bad};
        context.expect(!client::parse_options(arguments).has_value(), "danh sách sai bị từ chối");
    }
    std::string many;
    for (int at = 0; at < 33; ++at) many += at == 0 ? "1" : ",1";
    const std::array<Text, 2> too_many{"--creature", many};
    context.expect(!client::parse_options(too_many).has_value(), "quá ba mươi hai id bị từ chối");
}

void options_take_impact(Context& context) {
    constexpr std::array<Text, 2> kOne{"--impact", "1"};
    const std::optional<client::Options> one = client::parse_options(kOne);
    context.expect(one.has_value() && one->impact_id == 1U, "--impact giữ id");
    constexpr std::array<Text, 2> kZero{"--impact", "0"};
    const std::optional<client::Options> zero = client::parse_options(kZero);
    context.expect(zero.has_value() && zero->impact_id == 0U, "id 0 vẫn hợp lệ");
    constexpr std::array<Text, 2> kBad{"--impact", "-1"};
    context.expect(!client::parse_options(kBad).has_value(), "id âm bị từ chối");
}

void options_take_pet_list(Context& context) {
    constexpr std::array<Text, 2> kList{"--pet", "339,11158"};
    const std::optional<client::Options> list = client::parse_options(kList);
    context.expect(list.has_value() && list->pets == std::vector<std::uint32_t>({339, 11158}), "--pet giữ id mẫu");
    constexpr std::array<Text, 2> kEmpty{"--pet", ""};
    context.expect(!client::parse_options(kEmpty).has_value(), "--pet rỗng bị từ chối");
}

void options_take_peer_count(Context& context) {
    constexpr std::array<Text, 2> kTwo{"--peer", "2"};
    const std::optional<client::Options> two = client::parse_options(kTwo);
    context.expect(two.has_value() && two->peer_count == 2, "--peer 2 nhận hai người");
    for (const Text bad : {Text{"0"}, Text{"5"}, Text{"x"}, Text{""}}) {
        const std::array<Text, 2> arguments{"--peer", bad};
        context.expect(!client::parse_options(arguments).has_value(), "--peer ngoài 1..4 bị từ chối");
    }
}

// Chính sách là nơi duy nhất PC và điện thoại khác nhau trên đường vẽ. Hai bộ số dưới đây là số đã đo trên máy thật (ghi ở
// policy.hpp); đổi một số là đổi hình hay nhịp khung, nên test giữ chúng.
void policy_desktop_is_full_detail(Context& context) {
    const client::GraphicsPolicy policy = client::policy_of(client::QualityClass::kDesktop);
    context.expect(policy.samples == 4, "PC khử răng cưa 4 mẫu");
    context.expect(!policy.is_raw_color, "PC giữ sRGB của phần cứng");
    context.expect(!policy.lights_at_vertices, "PC tính ánh sáng ở điểm ảnh");
    context.expect(policy.triangle_cap == 0 && !policy.adapts_detail, "PC không giới hạn tam giác");
    context.expect(!policy.builds_lods, "PC không sinh LOD");
    context.expect(policy.texture_edge == 0, "PC giữ cỡ texture gốc");
    context.expect(policy.pending_bytes == (std::size_t{1} << 30U), "PC cho hàng đợi mesh 1 GiB");
    context.expect(!policy.shows_first_frame_early && !policy.adapts_rate, "PC chờ đủ mesh và giữ nhịp quét");
    context.expect(policy.fixed_tier == resource::TextureTier::kBc, "PC luôn texture BC");
    context.expect(policy.start_zoom == 1.0F, "PC vào cảnh ở khoảng cách xa nhất như bản gốc");
    context.expect(!policy.fixed_vertical_fov, "PC giữ khung 16:9 trọn trong tầm nhìn");
}

void policy_mobile_keeps_measured_limits(Context& context) {
    const client::GraphicsPolicy policy = client::policy_of(client::QualityClass::kMobile);
    context.expect(policy.samples == 1, "điện thoại một mẫu");
    context.expect(policy.is_raw_color, "điện thoại dùng màu thô");
    context.expect(policy.lights_at_vertices, "điện thoại tính ánh sáng ở đỉnh");
    context.expect(policy.triangle_cap == 150'000 && policy.adapts_detail, "trần 150 nghìn tam giác, tự chỉnh");
    context.expect(policy.builds_lods, "điện thoại sinh LOD");
    context.expect(policy.texture_edge == 512, "texture cạnh tối đa 512");
    context.expect(policy.pending_bytes == (std::size_t{96} << 20U), "hàng đợi mesh 96 MiB");
    context.expect(policy.shows_first_frame_early && policy.adapts_rate, "hiện khung đầu sớm, trần nhịp tự chỉnh");
    context.expect(!policy.fixed_tier.has_value(), "loại texture nén do thiết bị khai");
    context.expect(policy.start_zoom == 0.45F, "điện thoại vào cảnh gần hơn để nhân vật không bé");
    context.expect(policy.fixed_vertical_fov, "điện thoại giữ góc dọc cố định như D:\\Dev");
}

void quality_names_round_trip(Context& context) {
    context.expect(client::quality_class_of("desktop") == client::QualityClass::kDesktop, "desktop");
    context.expect(client::quality_class_of("mobile") == client::QualityClass::kMobile, "mobile");
    context.expect(!client::quality_class_of("phone").has_value(), "tên lạ bị từ chối");
    context.expect(!client::quality_class_of("").has_value(), "tên rỗng bị từ chối");
    context.expect(client::quality_name(client::QualityClass::kMobile) == "mobile", "tên của mobile");
    context.expect(client::quality_name(client::QualityClass::kDesktop) == "desktop", "tên của desktop");
}

void options_take_quality(Context& context) {
    constexpr std::array<Text, 2> kMobile{"--quality", "mobile"};
    const std::optional<client::Options> mobile = client::parse_options(kMobile);
    context.expect(mobile.has_value() && mobile->quality == client::QualityClass::kMobile, "--quality mobile");
    const std::optional<client::Options> none = client::parse_options({});
    context.expect(none.has_value() && !none->quality.has_value(), "không nêu thì theo nền tảng");
    constexpr std::array<Text, 2> kBad{"--quality", "ultra"};
    context.expect(!client::parse_options(kBad).has_value(), "--quality lạ bị từ chối");
}

// Chuỗi của đăng nhập tự động: SignIn, rồi Create khi tài khoản chưa có nhân vật, rồi Enter nhân vật đầu, rồi vào game.
void auto_login_walks_sign_in_create_enter(Context& context) {
    using Kind = ui::panel::OnlineReply::Kind;
    client::AutoLogin login{.account = "tester01"};
    const ui::panel::OnlineAsk sign = client::auto_sign_in(login, ui::panel::ServerName{.area = "a", .server = "s"});
    context.expect(sign.work == ui::panel::OnlineWork::kSignIn && sign.account == "tester01", "đăng nhập đúng tài khoản");
    context.expect(sign.server.server == "s", "đúng máy chủ đã chọn");
    context.expect(sign.password.size() >= 6 && sign.password != sign.account, "mật khẩu máy chủ nhận được");
    ui::panel::OnlineReply empty;
    empty.kind = Kind::kRoster;
    const std::optional<ui::panel::OnlineAsk> create = client::auto_next(login, empty);
    context.expect(create && create->work == ui::panel::OnlineWork::kCreate, "chưa có nhân vật thì tạo");
    context.expect(create && create->role.name == "tester01" && create->role.sex == 1, "nhân vật nam tên tài khoản");
    ui::panel::OnlineReply roster = empty;
    ui::panel::Role made;
    made.name = "tester01";
    made.id = 42;
    roster.roles.push_back(made);
    const std::optional<ui::panel::OnlineAsk> enter = client::auto_next(login, roster);
    context.expect(enter && enter->work == ui::panel::OnlineWork::kEnter && enter->role.id == 42, "vào nhân vật đầu");
    context.expect(!client::auto_next(login, roster).has_value(), "danh sách lặp lại thì không gửi lần hai");
    ui::panel::OnlineReply entered;
    entered.kind = Kind::kEntered;
    context.expect(!client::auto_next(login, entered).has_value(), "vào game không cần gửi gì");
    context.expect(login.step == client::AutoLogin::Step::kPlay, "tới bước chơi");
}

// Bị từ chối hay mất phiên thì dừng hẳn, không thử lại và không gửi gì nữa.
void auto_login_stops_on_refusal(Context& context) {
    using Kind = ui::panel::OnlineReply::Kind;
    client::AutoLogin login{.account = "tester02"};
    static_cast<void>(client::auto_sign_in(login, ui::panel::ServerName{}));
    ui::panel::OnlineReply refused;
    refused.kind = Kind::kRefused;
    context.expect(!client::auto_next(login, refused).has_value(), "từ chối thì không gửi");
    context.expect(login.step == client::AutoLogin::Step::kStopped, "dừng hẳn");
    ui::panel::OnlineReply roster;
    roster.kind = Kind::kRoster;
    context.expect(!client::auto_next(login, roster).has_value(), "đã dừng thì bỏ qua trả lời sau");
}

void options_allow_launch_without_arguments(Context& context) {
    const std::optional<client::Options> bare = client::parse_options({});
    context.expect(bare.has_value(), "không đối số nào (bấm đúp exe) là hợp lệ");
    if (!bare) return;
    context.expect(bare->scene_name.empty(), "không nêu --scene thì tên cảnh để rỗng");
    constexpr std::array<Text, 2> kDataOnly{"--data", "x"};
    context.expect(client::parse_options(kDataOnly).has_value(), "chỉ nêu --data cũng hợp lệ");
}

void scene_choice_prefers_request_then_single_scene(Context& context) {
    const std::array<std::string, 1> one{"huoyangu"};
    const std::array<std::string, 2> two{"dali", "huoyangu"};
    const std::span<const std::string> none;
    context.expect(client::choose_scene("dali", one) == "dali", "cảnh được nêu thắng");
    context.expect(client::choose_scene("", one) == "huoyangu", "không nêu thì lấy cảnh duy nhất");
    context.expect(!client::choose_scene("", two).has_value(), "nhiều cảnh mà không nêu thì chịu");
    context.expect(!client::choose_scene("", none).has_value(), "không có cảnh nào thì chịu");
}

// Sổ của một gói cài: hai tệp dữ liệu (một có dấu cách trong tên) và một gói shader.
constexpr Text kPackedBook = "D 0a1b2c3d-120 Config/startup.id\n"
                             "D 99887766-4096 Model/ban ghe/ghe 1.glb\n"
                             "S deadbeef-28017 model.ps.f2s\n";

void asset_book_reads_group_stamp_and_path(Context& context) {
    const std::vector<client::AssetEntry> entries = client::read_asset_book(kPackedBook);
    context.expect(entries.size() == 3, "ba dòng hợp lệ");
    if (entries.size() != 3) return;
    const client::AssetEntry spaced{.group = 'D', .stamp = "99887766-4096", .path = "Model/ban ghe/ghe 1.glb"};
    context.expect(entries[1] == spaced, "đường dẫn giữ nguyên dấu cách");
    const client::AssetEntry shader{.group = 'S', .stamp = "deadbeef-28017", .path = "model.ps.f2s"};
    context.expect(entries[2] == shader, "nhóm S là gói shader");
    constexpr Text kOdd = "X 11-1 la\nD thieu-duong-dan\n\nD 22-2 a.txt\r\nD  rong.txt\nD 33-3 b.txt";
    const std::vector<client::AssetEntry> kept = client::read_asset_book(kOdd);
    context.expect(kept.size() == 2, "nhóm lạ, dòng thiếu phần và dấu rỗng bị bỏ");
    if (kept.size() != 2) return;
    context.expect(kept[0].path == "a.txt", "bỏ ký tự xuống dòng kiểu Windows");
    context.expect(kept[1].path == "b.txt", "dòng cuối không cần xuống dòng");
}

void assets_copy_only_what_changed(Context& context) {
    const client::AssetBooks fresh{.installed = "", .packed = kPackedBook};
    context.expect(client::assets_to_copy(fresh).size() == 3, "chưa có sổ thì chép hết");
    const client::AssetBooks same{.installed = kPackedBook, .packed = kPackedBook};
    context.expect(client::assets_to_copy(same).empty(), "sổ trùng thì không chép");
    // Gói shader đổi nội dung (dấu khác) và thêm một tệp dữ liệu mới; tệp cũ không đổi.
    constexpr Text kNewer = "D 0a1b2c3d-120 Config/startup.id\n"
                            "D 99887766-4096 Model/ban ghe/ghe 1.glb\n"
                            "D 12345678-95866 Config/ScenePosDefineEx.txt\n"
                            "S 0badf00d-32014 model.ps.f2s\n";
    const client::AssetBooks updated{.installed = kPackedBook, .packed = kNewer};
    const std::vector<client::AssetEntry> stale = client::assets_to_copy(updated);
    context.expect(stale.size() == 2, "chỉ tệp mới và tệp đổi dấu");
    if (stale.size() != 2) return;
    context.expect(stale[0].path == "Config/ScenePosDefineEx.txt", "tệp dữ liệu mới thêm");
    context.expect(stale[1].group == 'S' && stale[1].stamp == "0badf00d-32014", "gói shader đổi");
    // Cùng đường dẫn ở hai nhóm là hai tệp khác nhau.
    constexpr Text kKept = "D 11-1 model.ps.f2s\n";
    constexpr Text kBoth = "D 11-1 model.ps.f2s\nS 11-1 model.ps.f2s\n";
    const client::AssetBooks groups{.installed = kKept, .packed = kBoth};
    const std::vector<client::AssetEntry> other = client::assets_to_copy(groups);
    context.expect(other.size() == 1 && other[0].group == 'S', "nhóm khác thì vẫn phải chép");
}

constexpr std::array kCases{
    Case{.name = "options_take_scene_alone", .body = &options_take_scene_alone},
    Case{.name = "options_allow_launch_without_arguments", .body = &options_allow_launch_without_arguments},
    Case{.name = "scene_choice_prefers_request_then_single_scene",
        .body = &scene_choice_prefers_request_then_single_scene},
    Case{.name = "options_take_data_folder_and_frames", .body = &options_take_data_folder_and_frames},
    Case{.name = "options_reject_wrong_usage", .body = &options_reject_wrong_usage},
    Case{.name = "options_take_shot_path", .body = &options_take_shot_path},
    Case{.name = "options_take_client_size", .body = &options_take_client_size},
    Case{.name = "options_accept_client_size_limits", .body = &options_accept_client_size_limits},
    Case{.name = "login_window_ignores_chosen_size", .body = &login_window_ignores_chosen_size},
    Case{.name = "login_frame_letterboxes_tablet", .body = &login_frame_letterboxes_tablet},
    Case{.name = "placed_frame_caps_by_density", .body = &placed_frame_caps_by_density},
    Case{.name = "login_frame_survives_empty_sizes", .body = &login_frame_survives_empty_sizes},
    Case{.name = "login_frame_maps_touch_to_frame", .body = &login_frame_maps_touch_to_frame},
    Case{.name = "options_take_bare_validate_flag", .body = &options_take_bare_validate_flag},
    Case{.name = "options_take_bare_login_flag", .body = &options_take_bare_login_flag},
    Case{.name = "options_take_bare_flag", .body = &options_take_bare_flag},
    Case{.name = "options_take_creature_list", .body = &options_take_creature_list},
    Case{.name = "options_take_pet_list", .body = &options_take_pet_list},
    Case{.name = "options_take_impact", .body = &options_take_impact},
    Case{.name = "options_take_peer_count", .body = &options_take_peer_count},
    Case{.name = "policy_desktop_is_full_detail", .body = &policy_desktop_is_full_detail},
    Case{.name = "policy_mobile_keeps_measured_limits", .body = &policy_mobile_keeps_measured_limits},
    Case{.name = "quality_names_round_trip", .body = &quality_names_round_trip},
    Case{.name = "options_take_quality", .body = &options_take_quality},
    Case{.name = "auto_login_walks_sign_in_create_enter", .body = &auto_login_walks_sign_in_create_enter},
    Case{.name = "auto_login_stops_on_refusal", .body = &auto_login_stops_on_refusal},
    Case{.name = "asset_book_reads_group_stamp_and_path", .body = &asset_book_reads_group_stamp_and_path},
    Case{.name = "assets_copy_only_what_changed", .body = &assets_copy_only_what_changed},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "client_tests: mọi ca phải qua");
    return 0;
}
