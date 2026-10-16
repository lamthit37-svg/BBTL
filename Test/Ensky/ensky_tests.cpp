// Test của bầu trời EnScene: đọc .EnScene (UTF-8 và GBK), pha trăng và mặt trời, hướng trăng của cảnh
// đăng nhập, nội suy TimeNode tuần hoàn 24 giờ, đồng hồ ngày và mây vòng xoay cộng dồn.
#include "core/check.hpp"
#include "ensky/plan.hpp"
#include "ensky/scene.hpp"
#include "ensky/sky.hpp"
#include "ensky/star.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <numbers>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ensky::Playback;
using ensky::Scene;

// Rút gọn từ erengu_DL.EnScene của kho gốc: một lớp mây alpha 0, hai lớp mây vòng, trăng cố định,
// mặt trời tắt và một EnvKey.
constexpr std::string_view kLogin = R"(<EnScene version="1.0">
  <EnRegionComposite>
    <EnRegion name="backgroud" maxAffectDistance="779">
      <RegionGroups />
      <EnSky>
        <SkyDome>
          <texture>DJLTyewan_color1.tga</texture>
          <hight>-573</hight>
          <mieAmount>0.01</mieAmount>
          <vertexHeightEffect>1</vertexHeightEffect>
          <sunHeightEffect>1</sunHeightEffect>
          <power>1</power>
        </SkyDome>
        <SkyClouds>
          <SkyCloudsLayer>
            <name>bottom</name>
            <layer>9</layer>
            <turnoverMesh>false</turnoverMesh>
            <skyCloudHeight>-210</skyCloudHeight>
            <meshname>enskycloud.mesh</meshname>
            <texturename>a.jpg</texturename>
            <rotangle>1.0472</rotangle>
            <textureTile>12 12 0 0</textureTile>
            <scatteringStrength>0.12</scatteringStrength>
            <scatteringPower>12.95</scatteringPower>
            <rimStrength>0.12</rimStrength>
            <rimPower>4.57</rimPower>
            <rimDetectPower>3</rimDetectPower>
            <rimDetectWidth>0.12</rimDetectWidth>
            <TimeNodesInfo>
              <TimeNode time="0" fog="-1" alpha="0" cloudspeed="0.05" ambientBlend="0" />
            </TimeNodesInfo>
          </SkyCloudsLayer>
        </SkyClouds>
        <SkyRingClouds>
          <RingCloudsLayer>
            <name>shan</name>
            <layer>5</layer>
            <meshname>ringcloud.mesh</meshname>
            <turnoverMesh>false</turnoverMesh>
            <texturename>b.png</texturename>
            <CloudHeight>-60</CloudHeight>
            <CloudScale>3.7</CloudScale>
            <TextureRepeat>2</TextureRepeat>
            <CloudOffset>85</CloudOffset>
            <parallax>0.005</parallax>
            <scatteringStrength>0.12</scatteringStrength>
            <scatteringPower>1</scatteringPower>
            <rimStrength>0.38</rimStrength>
            <rimPower>4.57</rimPower>
            <rimDetectPower>3</rimDetectPower>
            <rimDetectWidth>0.12</rimDetectWidth>
            <TimeNodesInfo>
              <TimeNode time="0" fogblend="0" ambientBlend="0" alpha="0.6" rollspeed="0"
                verticalSpeed="0" fadeRange="0.17" />
            </TimeNodesInfo>
          </RingCloudsLayer>
        </SkyRingClouds>
        <Star Enable="false" StarCount="2000" />
        <Moon Enable="true" moon_tex_name="erengumoon_red.png" scale="11" moonOrient="344"
          moonAngle="9" moonUpTime="18" moonDownTime="6" moonfix="true" layer="30" />
        <Sun Enable="false" sun_tex_name="sun.dds" scale="10" sunOrient="0" sunAngle="50"
          sunUpTime="6" sunDownTime="18" sunfix="false" layer="5" />
        <Effects>
          <Effect effect_name="cj_hieu_ung" />
        </Effects>
        <LightAndFog>
          <EnvKey time="0" ambient="0.266667 0.286275 0.337255" fog="0.0901961 0.176471 0.239216"
            fog_near_distance="1000" fog_far_distance="25000" light_one="0.639216 0.721569 0.756863"
            light_one_direction="-0.3 -0.3 -0.5" light_one_intensity="1"
            light_two_direction="0 0 0" skyDomeAmbientColor="1 1 1"
            skyDomeAmbientColorStrength="1" />
        </LightAndFog>
      </EnSky>
    </EnRegion>
  </EnRegionComposite>
</EnScene>
)";

constexpr float kNear = 1.0e-3F;

[[nodiscard]] bool close(float left, float right, float eps = kNear) noexcept {
    return std::fabs(left - right) <= eps;
}

void reads_login_sample(Context& context) noexcept {
    const auto scene = ensky::read_scene(kLogin);
    context.expect(scene.has_value(), "cảnh mẫu đọc được");
    if (!scene) return;
    context.expect(scene->regions.size() == 1, "một vùng");
    const ensky::Region& region = scene->regions.front();
    context.expect(region.name == "backgroud", "tên vùng");
    context.expect(region.max_distance == 779.0F, "maxAffectDistance");
    const ensky::Sky& sky = region.sky;
    context.expect(sky.dome.texture == "DJLTyewan_color1.tga", "ảnh vòm");
    context.expect(sky.dome.height == -573.0F, "hight");
    context.expect(sky.dome.mie_amount == 0.01F, "mieAmount");
    context.expect(sky.clouds.size() == 1 && sky.rings.size() == 1, "số lớp mây");
    context.expect(sky.clouds.front().tile[1] == 12.0F, "textureTile");
    context.expect(sky.clouds.front().keys.size() == 1, "một TimeNode");
    context.expect(sky.rings.front().keys.front().alpha == 0.6F, "alpha mây vòng");
    context.expect(sky.rings.front().offset == 85.0F, "CloudOffset");
    context.expect(sky.moon.is_enabled && sky.moon.is_fixed, "trăng bật và cố định");
    context.expect(!sky.sun.is_enabled && !sky.sun.is_fixed, "mặt trời tắt");
    context.expect(sky.effects.size() == 1, "một hiệu ứng");
    context.expect(sky.env.size() == 1, "một EnvKey");
    context.expect(sky.env.front().fog_far == 25000.0F, "fog_far_distance");
    context.expect(sky.env.front().light_two_direction.x == 0.0F, "hướng đèn hai bằng 0");
}

void reads_gbk_texture_names(Context& context) noexcept {
    // Cùng tệp nhưng tên ảnh là GBK: "汴京天空边缘01.png".
    std::string xml = R"(<EnScene><EnSky><SkyRingClouds><RingCloudsLayer><name>a</name>)"
                      "<texturename>\xe3\xea\xbe\xa9\xcc\xec\xbf\xd5\xb1\xdf\xd4\xb5"
                      "01.png</texturename>"
                      "</RingCloudsLayer></SkyRingClouds></EnSky></EnScene>";
    const auto scene = ensky::read_scene(xml);
    context.expect(scene.has_value(), "tệp GBK đọc được");
    if (!scene) return;
    const ensky::Sky& sky = scene->regions.front().sky;
    context.expect(sky.rings.size() == 1, "một lớp");
    if (sky.rings.empty()) return;
    context.expect(sky.rings.front().texture == "汴京天空边缘01.png", "tên ảnh giải sang UTF-8");
    const std::vector<std::string> names = ensky::textures_of(*scene);
    context.expect(names.size() == 1, "textures_of không trùng");
}

void rejects_other_documents(Context& context) noexcept {
    const auto other = ensky::read_scene("<Scene/>");
    context.expect(!other && other.error() == ensky::Fault::kNotScene, "gốc không phải EnScene");
    const auto empty = ensky::read_scene("<EnScene/>");
    context.expect(!empty && empty.error() == ensky::Fault::kNoSky, "không có EnSky");
    const auto broken = ensky::read_scene("<EnScene><EnSky>");
    context.expect(!broken && broken.error() == ensky::Fault::kBadXml, "XML hỏng");
}

void phase_follows_machine_code(Context& context) noexcept {
    // Mặt trời 6..18 (start = up, end = down).
    context.expect(close(ensky::phase_of(12.0F, 6.0F, 18.0F), 0.5F), "trưa");
    context.expect(close(ensky::phase_of(0.0F, 6.0F, 18.0F), 1.0F), "nửa đêm: nhánh h < start");
    context.expect(close(ensky::phase_of(20.0F, 6.0F, 18.0F), 0.75F + (2.0F / 24.0F)), "h > end");
    context.expect(close(ensky::phase_of(18.0F, 6.0F, 18.0F), 0.75F), "h = end");
    // end < start: 18 -> 6 qua nửa đêm.
    context.expect(close(ensky::phase_of(20.0F, 18.0F, 6.0F), 0.25F + (2.0F / 24.0F)), "h > start");
    context.expect(close(ensky::phase_of(3.0F, 18.0F, 6.0F), 0.25F + (9.0F / 24.0F)), "h < end");
    context.expect(close(ensky::phase_of(12.0F, 18.0F, 6.0F), 1.0F), "giữa end và start");
}

void login_moon_points_where_the_original_does(Context& context) noexcept {
    const auto scene = ensky::read_scene(kLogin);
    if (!scene) return;
    const ensky::Moon& moon = scene->regions.front().sky.moon;
    const ensky::Pose fixed_pose = ensky::moon_pose(moon, 0.0F);
    context.expect(close(fixed_pose.toward.x, 0.2722F), "moon x");
    context.expect(close(fixed_pose.toward.y, 0.1564F), "moon y");
    context.expect(close(fixed_pose.toward.z, 0.9494F), "moon z");
    const ensky::Pose later = ensky::moon_pose(moon, 13.0F);
    context.expect(close(later.toward.y, fixed_pose.toward.y, 1.0e-6F), "trăng cố định không đổi theo giờ");
}

void sun_direction_at_midnight(Context& context) noexcept {
    const auto scene = ensky::read_scene(kLogin);
    if (!scene) return;
    const ensky::Sun& sun = scene->regions.front().sky.sun;
    const ensky::Pose midnight = ensky::sun_pose(sun, 0.0F);
    context.expect(close(midnight.toward.x, 0.0F), "x");
    context.expect(close(midnight.toward.y, -0.7660F), "y dưới chân trời");
    context.expect(close(midnight.toward.z, -0.6428F), "z");
    const ensky::Pose noon = ensky::sun_pose(sun, 12.0F);
    context.expect(noon.toward.y > 0.0F, "giữa trưa mặt trời trên chân trời");
}

void clock_runs_one_day_in_a_minute(Context& context) noexcept {
    ensky::DayClock clock;
    clock.advance(30.0F);
    context.expect(close(clock.fraction(), 0.5F), "30 giây là nửa ngày");
    context.expect(close(clock.hour(), 12.0F), "giờ 12");
    clock.advance(40.0F);
    context.expect(close(clock.fraction(), 0.1667F), "quấn qua ngày mới");
    clock.pin(0.9479F);
    clock.advance(100.0F);
    context.expect(clock.fraction() == 0.9479F, "đồng hồ dừng không chạy");
    clock.pin(1.0F);
    context.expect(clock.hour() == ensky::kLastHour, "giờ kẹp ở 23,999");
    clock.run();
    context.expect(!clock.is_pinned(), "chạy lại");
}

void time_nodes_wrap_around_the_day(Context& context) noexcept {
    ensky::Sky sky;
    ensky::RingLayer ring;
    ring.keys = {ensky::RingKey{.time = 0.0F, .alpha = 0.0F}, ensky::RingKey{.time = 12.0F, .alpha = 1.0F}};
    sky.rings.push_back(ring);
    Playback play(sky);
    play.update({.seconds = 0.0F, .hour = 6.0F});
    context.expect(close(play.rings()[0].alpha, 0.5F), "giữa hai nút");
    play.update({.seconds = 0.0F, .hour = 18.0F});
    context.expect(close(play.rings()[0].alpha, 0.5F), "sau nút cuối nối về nút đầu cộng 24 giờ");
    play.update({.seconds = 0.0F, .hour = 23.0F});
    context.expect(close(play.rings()[0].alpha, 1.0F / 12.0F), "gần cuối ngày");
    sky.rings.front().keys = {ensky::RingKey{.time = 4.0F, .alpha = 1.0F}, ensky::RingKey{.time = 8.0F, .alpha = 0.0F}};
    Playback early(sky);
    early.update({.seconds = 0.0F, .hour = 2.0F});
    // Trước nút đầu: nút cuối lùi 24 giờ (8 - 24 = -16, alpha 0) tới nút đầu (4, alpha 1): (2 + 16) / 20.
    context.expect(close(early.rings()[0].alpha, 0.9F), "trước nút đầu");
}

void time_nodes_update_by_steps(Context& context) noexcept {
    ensky::Sky sky;
    ensky::CloudLayer cloud;
    cloud.keys = {ensky::CloudKey{.time = 0.0F, .alpha = 0.0F}, ensky::CloudKey{.time = 10.0F, .alpha = 1.0F}};
    sky.clouds.push_back(cloud);
    Playback play(sky);
    play.update({.seconds = 0.0F, .hour = 5.0F});
    context.expect(close(play.clouds()[0].alpha, 0.5F), "lần đầu tính ngay");
    play.update({.seconds = 0.0F, .hour = 5.005F});
    context.expect(close(play.clouds()[0].alpha, 0.5F, 1.0e-6F), "lệch dưới 0,01 giờ thì giữ giá trị cũ");
    play.update({.seconds = 0.0F, .hour = 5.02F});
    context.expect(close(play.clouds()[0].alpha, 0.502F, 1.0e-5F), "lệch quá 0,01 giờ thì tính lại");
}

void cloud_wind_and_ring_offset_accumulate(Context& context) noexcept {
    ensky::Sky sky;
    ensky::CloudLayer cloud;
    cloud.keys = {ensky::CloudKey{.time = 0.0F, .speed = 0.5F}};
    sky.clouds.push_back(cloud);
    ensky::RingLayer ring;
    ring.keys = {ensky::RingKey{.time = 0.0F, .vertical_speed = 0.6F}};
    sky.rings.push_back(ring);
    Playback play(sky);
    play.update({.seconds = 1.0F, .hour = 0.0F});
    play.update({.seconds = 1.0F, .hour = 0.0F});
    // Khung đầu tính nút trước khi cộng dồn: gió = 2 * 0,5 * 1 * 0,1.
    context.expect(close(play.clouds()[0].wind, 0.1F), "gió cộng dồn cloudspeed * dt * 0,1");
    context.expect(close(play.rings()[0].v_offset, 0.2F), "v quấn: 0,6 + 0,6 = 1,2 vượt 1 thì trừ 1");
}

void ring_orientation_is_absolute_without_roll(Context& context) noexcept {
    ensky::Sky sky;
    ensky::RingLayer ring;
    ring.offset = 90.0F;
    ring.keys = {ensky::RingKey{.time = 0.0F}};
    sky.rings.push_back(ring);
    Playback play(sky);
    play.update({.seconds = 0.5F, .hour = 0.0F});
    const ogre::Quat turned = play.rings()[0].orientation;
    context.expect(close(turned.w, std::cos(std::numbers::pi_v<float> / 4.0F)), "w = cos(45 độ)");
    context.expect(close(turned.y, std::sin(std::numbers::pi_v<float> / 4.0F)), "y = sin(45 độ)");
    sky.rings.front().is_flipped = true;
    Playback flipped(sky);
    flipped.update({.seconds = 0.5F, .hour = 0.0F});
    context.expect(flipped.rings()[0].is_flipped, "đã lật");
    context.expect(!close(flipped.rings()[0].orientation.y, turned.y), "lật đổi hướng nút");
}

// Vòng mây của cảnh đăng nhập: tên, layer, độ cao, alpha (bảy lớp alpha > 0, hai lớp tắt).
struct RingSpec {
    const char* name;
    int layer;
    float height;
    float alpha;
};

constexpr std::array kLoginRings{
    RingSpec{"yun1", 6, -132.0F, 0.0F}, RingSpec{"shan", 5, -60.0F, 0.6F},
    RingSpec{"tianbian", 0, -76.0F, 0.87F}, RingSpec{"shan22", 12, -32.0F, 0.0F},
    RingSpec{"jianbian", 7, -11.0F, 1.0F}, RingSpec{"cloud1", 7, -76.0F, 1.0F},
    RingSpec{"XUEYUE", 8, -23.0F, 0.21F}, RingSpec{"XUEYUE2", 8, -127.0F, 0.43F},
    RingSpec{"XUEYUE3", 11, -11.0F, 0.63F}};

[[nodiscard]] ensky::Sky login_sky() {
    ensky::Sky sky;
    for (const RingSpec& spec : kLoginRings) {
        ensky::RingLayer ring;
        ring.name = spec.name;
        ring.layer = spec.layer;
        ring.height = spec.height;
        ring.keys = {ensky::RingKey{.time = 0.0F, .alpha = spec.alpha}};
        sky.rings.push_back(ring);
    }
    sky.moon.is_enabled = true;
    sky.moon.is_fixed = true;
    sky.moon.layer = 30;
    sky.moon.scale = 11.0F;
    return sky;
}

void plan_orders_like_the_render_queue(Context& context) noexcept {
    const ensky::Sky sky = login_sky();
    Playback play(sky);
    play.update({.seconds = 0.0F, .hour = 0.0F});
    const std::vector<ensky::Draw> draws = ensky::plan_of(play);
    // alpha 0 không được tạo; ưu tiên tăng dần; cùng ưu tiên thì xa trước (|độ cao| lớn trước).
    const std::array<std::string_view, 8> wanted{
        "tianbian", "shan", "cloud1", "jianbian", "XUEYUE2", "XUEYUE", "", "XUEYUE3"};
    context.expect(draws.size() == wanted.size(), "bảy lớp mây vòng và một mặt trăng");
    if (draws.size() != wanted.size()) return;
    for (std::size_t index = 0; index < wanted.size(); ++index) {
        const ensky::Draw& draw = draws[index];
        const bool is_moon = draw.kind == ensky::Kind::kMoon;
        context.expect(is_moon == wanted[index].empty(), "trăng nằm giữa ưu tiên 118 và 121");
        if (is_moon) continue;
        context.expect(sky.rings[draw.index].name == wanted[index], wanted[index]);
    }
}

void plan_places_the_moon_far_away(Context& context) noexcept {
    const ensky::Sky sky = login_sky();
    Playback play(sky);
    play.update({.seconds = 0.0F, .hour = 0.0F});
    for (const ensky::Draw& draw : ensky::plan_of(play)) {
        if (draw.kind != ensky::Kind::kMoon) continue;
        const float reach = ogre::length_vec3(draw.offset);
        context.expect(close(reach, ensky::kBodyDistance, 0.5F), "trăng cách 9000");
        context.expect(draw.scale.x == 11.0F && draw.scale.y == 11.0F, "tỉ lệ đều");
        context.expect(draw.priority == 120, "ưu tiên 90 + layer");
    }
}

void cloud_orientation_flips_with_turnover(Context& context) noexcept {
    ensky::CloudLayer layer;
    layer.yaw = 1.0472F;
    const ogre::Quat plain = ensky::cloud_orientation(layer);
    context.expect(close(plain.y, std::sin(1.0472F * 0.5F)), "yaw quanh +Y");
    layer.is_flipped = true;
    const ogre::Quat flipped = ensky::cloud_orientation(layer);
    context.expect(!close(flipped.y, plain.y), "lật PI quanh z cục bộ đổi hướng");
}

ensky::Star typical_star() {
    ensky::Star star;
    star.is_enabled = true;
    star.count = 2000;
    star.radius = 10000.0F;
    star.intensity = 1.0F;
    star.size = 10.0F;
    star.flicker_speed = 0.2F;
    star.start_colour = {0.5F, 0.5F, 0.5F, 0.5F};
    star.end_colour = {1.0F, 1.0F, 1.0F, 1.0F};
    return star;
}

// FUN_180238200 nối bốn kênh bằng VÀ: EndColour (1,1,1,1) chỉ lệch kênh đỏ khỏi (0,1,1,1) mặc định
// nên không đổi được màu cực đại.
void star_colour_needs_every_channel_to_move(Context& context) {
    ensky::StarField field;
    field.apply(typical_star());
    context.expect(field.max_colour()[0] == 0.0F && field.max_colour()[1] == 1.0F, "cực đại giữ (0,1,1,1)");
    context.expect(field.min_colour()[0] == 0.5F, "cực tiểu 0,5");
    ensky::Star moved = typical_star();
    moved.end_colour = {0.9F, 0.6F, 0.6F, 0.6F};
    field.apply(moved);
    context.expect(close(field.max_colour()[0], 0.9F) && close(field.max_colour()[3], 0.6F), "cả bốn lệch thì đổi");
}

void star_setters_keep_the_original_thresholds(Context& context) {
    ensky::StarField field;
    ensky::Star config = typical_star();
    config.count = 2002;
    config.radius = 10000.005F;
    field.apply(config);
    context.expect(field.count() == 2000, "lệch không quá 2 sao thì bỏ qua");
    context.expect(field.radius() == ensky::kStarRadius, "lệch không quá 0,01 thì bỏ qua");
    config.count = 1000;
    config.radius = 6000.0F;
    field.apply(config);
    context.expect(field.count() == 1000 && close(field.radius(), 6000.0F), "lệch lớn thì đổi");
    config.count = 0;
    field.apply(config);
    context.expect(field.count() == 1000, "0 sao bị bỏ qua");
    config.is_enabled = false;
    config.size = 99.0F;
    field.apply(config);
    context.expect(!field.is_enabled() && field.size() == 10.0F, "tắt thì không áp gì khác");
}

void star_visibility_follows_the_hour(Context& context) {
    ensky::StarField field;
    field.apply(typical_star());
    field.set_hour(0.0F);
    context.expect(close(field.visibility(), 0.8F), "nửa đêm 0,8");
    field.set_hour(12.0F);
    context.expect(close(field.visibility(), -1.2F) && !field.is_shown(), "giữa trưa không vẽ");
    field.set_hour(4.8F);
    context.expect(close(field.visibility(), 0.0F, 1.0e-4F) && !field.is_shown(), "mép 4,8 giờ");
    field.set_hour(21.6F);
    context.expect(close(field.visibility(), 0.4F, 1.0e-4F) && field.is_shown(), "tối dần");
    ensky::Star fixed = typical_star();
    fixed.is_fixed = true;
    field.apply(fixed);
    field.set_hour(12.0F);
    context.expect(close(field.visibility(), 0.8F) && field.is_shown(), "starfix luôn 0,8");
}

// Tốc độ 0,25 là lũy thừa của hai nên phép cộng dồn không sai số và các mốc 1 và 0 chạm đúng.
void star_flicker_bounces_between_zero_and_one(Context& context) {
    ensky::StarField field;
    ensky::Star config = typical_star();
    config.flicker_speed = 0.25F;
    field.apply(config);
    for (int step = 0; step < 4; ++step) field.advance(1.0F);
    context.expect(close(field.flicker(), 1.0F), "4 giây ở tốc độ 0,25 tới 1");
    field.advance(1.0F);
    context.expect(close(field.flicker(), 0.75F), "đã quay đầu");
    for (int step = 0; step < 3; ++step) field.advance(1.0F);
    context.expect(close(field.flicker(), 0.0F), "về 0");
    field.advance(1.0F);
    context.expect(close(field.flicker(), 0.25F), "lại đi lên");
}

void star_build_lays_stars_on_the_upper_hemisphere(Context& context) {
    ensky::StarField field;
    field.apply(typical_star());
    const std::vector<ensky::StarPoint> points = field.build();
    context.expect(points.size() == 1999, "count - 1 sao");
    bool is_upper = true;
    bool is_on_sphere = true;
    bool is_byte = true;
    for (const ensky::StarPoint& point : points) {
        const float length = std::sqrt((point.position[0] * point.position[0]) +
            (point.position[1] * point.position[1]) + (point.position[2] * point.position[2]));
        is_upper = is_upper && point.position[1] >= 0.0F;
        is_on_sphere = is_on_sphere && close(length, 10000.0F, 1.0F);
        const float scaled = point.colour[1] * 255.0F;
        is_byte = is_byte && close(scaled, std::round(scaled), 1.0e-3F);
    }
    context.expect(is_upper, "chỉ nửa trên");
    context.expect(is_on_sphere, "đúng bán kính");
    context.expect(is_byte, "màu lượng tử 8 bit");
    const std::vector<ensky::StarPoint> again = field.build();
    context.expect(again.size() == points.size() && again.front().position == points.front().position, "tất định");
    context.expect(points.front().colour[0] <= 0.5F + 1.0e-3F, "kênh đỏ nằm trong [0, 0,5]");
}

constexpr std::array kCases{
    Case{.name = "reads_login_sample", .body = &reads_login_sample},
    Case{.name = "reads_gbk_texture_names", .body = &reads_gbk_texture_names},
    Case{.name = "rejects_other_documents", .body = &rejects_other_documents},
    Case{.name = "phase_follows_machine_code", .body = &phase_follows_machine_code},
    Case{.name = "login_moon_points_where_the_original_does", .body = &login_moon_points_where_the_original_does},
    Case{.name = "sun_direction_at_midnight", .body = &sun_direction_at_midnight},
    Case{.name = "clock_runs_one_day_in_a_minute", .body = &clock_runs_one_day_in_a_minute},
    Case{.name = "time_nodes_wrap_around_the_day", .body = &time_nodes_wrap_around_the_day},
    Case{.name = "time_nodes_update_by_steps", .body = &time_nodes_update_by_steps},
    Case{.name = "cloud_wind_and_ring_offset_accumulate", .body = &cloud_wind_and_ring_offset_accumulate},
    Case{.name = "ring_orientation_is_absolute_without_roll", .body = &ring_orientation_is_absolute_without_roll},
    Case{.name = "plan_orders_like_the_render_queue", .body = &plan_orders_like_the_render_queue},
    Case{.name = "plan_places_the_moon_far_away", .body = &plan_places_the_moon_far_away},
    Case{.name = "cloud_orientation_flips_with_turnover", .body = &cloud_orientation_flips_with_turnover},
    Case{.name = "star_colour_needs_every_channel_to_move", .body = &star_colour_needs_every_channel_to_move},
    Case{.name = "star_setters_keep_the_original_thresholds", .body = &star_setters_keep_the_original_thresholds},
    Case{.name = "star_visibility_follows_the_hour", .body = &star_visibility_follows_the_hour},
    Case{.name = "star_flicker_bounces_between_zero_and_one", .body = &star_flicker_bounces_between_zero_and_one},
    Case{.name = "star_build_lays_stars_on_the_upper_hemisphere", .body = &star_build_lays_stars_on_the_upper_hemisphere},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ensky_tests: mọi ca phải qua");
    return 0;
}
