// Mỗi dòng: hãng, họ, dải model, dải stepping, tên. Dòng đầu tiên khớp thắng, nên dòng hẹp
// (stepping riêng, model lẻ) đứng trước dải rộng cùng họ. Họ AMD cũ trùng với vi kiến trúc (0Fh là
// K8, 10h là K10...) nên cả họ là một dòng; cpu_features liệt kê từng model và trả "không rõ" cho
// model khác.
// Nguồn: Forge2 src/core/uarch.cpp@d7fcd76. Khác gốc: Row dựng bằng khởi tạo ghi tên thành viên
// (gốc khởi tạo theo vị trí, cùng giá trị từng trường); bỏ {} thừa của các thành viên string_view.
#include "core/uarch.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <string_view>

namespace game::core {

namespace {

constexpr std::string_view kIntel = "GenuineIntel";
constexpr std::string_view kAmd = "AuthenticAMD";
constexpr std::string_view kHygon = "HygonGenuine";
constexpr std::string_view kCentaur = "CentaurHauls";
constexpr std::string_view kShanghai = "  Shanghai  ";

constexpr std::uint32_t kAnyStepping = 0xF;

struct Row {
    std::string_view vendor;
    std::uint32_t family = 0;
    std::uint32_t first = 0;
    std::uint32_t last = 0;
    std::uint32_t stepping_first = 0;
    std::uint32_t stepping_last = kAnyStepping;
    std::string_view name;
};

struct Key {
    std::string_view vendor;
    std::uint32_t family = 0;
    std::uint32_t model = 0;
    std::uint32_t stepping = 0;
};

// Khác gốc: ba hàm dựng Row dưới đây ở gốc khởi tạo theo vị trí, Row{vendor, family, ...}.
[[nodiscard]] constexpr Row one(std::string_view vendor, std::uint32_t family, std::uint32_t model,
    std::string_view name) {
    return Row{
        .vendor = vendor,
        .family = family,
        .first = model,
        .last = model,
        .stepping_first = 0,
        .stepping_last = kAnyStepping,
        .name = name,
    };
}

[[nodiscard]] constexpr Row span(std::string_view vendor, std::uint32_t family, std::uint32_t first, std::uint32_t last,
    std::string_view name) {
    return Row{
        .vendor = vendor,
        .family = family,
        .first = first,
        .last = last,
        .stepping_first = 0,
        .stepping_last = kAnyStepping,
        .name = name,
    };
}

// Cùng model, vi kiến trúc đổi theo stepping (Kaby, Coffee, Whiskey, Comet Lake chung model 8Eh).
[[nodiscard]] constexpr Row stepped(std::uint32_t model, std::uint32_t first, std::uint32_t last,
    std::string_view name) {
    return Row{
        .vendor = kIntel,
        .family = 0x6,
        .first = model,
        .last = model,
        .stepping_first = first,
        .stepping_last = last,
        .name = name,
    };
}

constexpr auto kRows = std::to_array<Row>({
    span(kIntel, 0x4, 0x01, 0x09, "Intel 80486"),
    span(kIntel, 0x5, 0x01, 0x02, "Intel P5"),
    one(kIntel, 0x5, 0x04, "Intel P5"),
    span(kIntel, 0x5, 0x07, 0x08, "Intel P5"),
    span(kIntel, 0x5, 0x09, 0x0A, "Intel Lakemont"),
    span(kIntel, 0x6, 0x0E, 0x0F, "Intel Core"),
    one(kIntel, 0x6, 0x16, "Intel Core"),
    one(kIntel, 0x6, 0x17, "Intel Penryn"),
    one(kIntel, 0x6, 0x1D, "Intel Penryn"),
    one(kIntel, 0x6, 0x1A, "Intel Nehalem"),
    span(kIntel, 0x6, 0x1E, 0x1F, "Intel Nehalem"),
    one(kIntel, 0x6, 0x2E, "Intel Nehalem"),
    one(kIntel, 0x6, 0x25, "Intel Westmere"),
    one(kIntel, 0x6, 0x2C, "Intel Westmere"),
    one(kIntel, 0x6, 0x2F, "Intel Westmere"),
    one(kIntel, 0x6, 0x2A, "Intel Sandy Bridge"),
    one(kIntel, 0x6, 0x2D, "Intel Sandy Bridge"),
    one(kIntel, 0x6, 0x3A, "Intel Ivy Bridge"),
    one(kIntel, 0x6, 0x3E, "Intel Ivy Bridge"),
    one(kIntel, 0x6, 0x3C, "Intel Haswell"),
    one(kIntel, 0x6, 0x3F, "Intel Haswell"),
    span(kIntel, 0x6, 0x45, 0x46, "Intel Haswell"),
    one(kIntel, 0x6, 0x3D, "Intel Broadwell"),
    one(kIntel, 0x6, 0x47, "Intel Broadwell"),
    one(kIntel, 0x6, 0x4F, "Intel Broadwell"),
    one(kIntel, 0x6, 0x56, "Intel Broadwell"),
    one(kIntel, 0x6, 0x4E, "Intel Skylake"),
    one(kIntel, 0x6, 0x5E, "Intel Skylake"),
    stepped(0x55, 6, 7, "Intel Cascade Lake"),
    one(kIntel, 0x6, 0x55, "Intel Skylake"),
    stepped(0x8E, 9, 9, "Intel Kaby Lake"),
    stepped(0x8E, 10, 10, "Intel Coffee Lake"),
    stepped(0x8E, 11, 11, "Intel Whiskey Lake"),
    stepped(0x8E, 12, 12, "Intel Comet Lake"),
    stepped(0x9E, 0, 9, "Intel Kaby Lake"),
    stepped(0x9E, 10, kAnyStepping, "Intel Coffee Lake"),
    span(kIntel, 0x6, 0xA5, 0xA6, "Intel Comet Lake"),
    one(kIntel, 0x6, 0x66, "Intel Cannon Lake"),
    one(kIntel, 0x6, 0x6A, "Intel Ice Lake"),
    one(kIntel, 0x6, 0x6C, "Intel Ice Lake"),
    span(kIntel, 0x6, 0x7D, 0x7E, "Intel Ice Lake"),
    one(kIntel, 0x6, 0x9D, "Intel Ice Lake"),
    one(kIntel, 0x6, 0xA7, "Intel Rocket Lake"),
    span(kIntel, 0x6, 0x8C, 0x8D, "Intel Tiger Lake"),
    one(kIntel, 0x6, 0x8A, "Intel Lakefield"),
    one(kIntel, 0x6, 0x8F, "Intel Sapphire Rapids"),
    one(kIntel, 0x6, 0xCF, "Intel Emerald Rapids"),
    span(kIntel, 0x6, 0xAD, 0xAE, "Intel Granite Rapids"),
    one(kIntel, 0x6, 0x97, "Intel Alder Lake"),
    one(kIntel, 0x6, 0x9A, "Intel Alder Lake"),
    one(kIntel, 0x6, 0xBE, "Intel Alder Lake-N"),
    one(kIntel, 0x6, 0xB7, "Intel Raptor Lake"),
    one(kIntel, 0x6, 0xBA, "Intel Raptor Lake"),
    one(kIntel, 0x6, 0xBF, "Intel Raptor Lake"),
    one(kIntel, 0x6, 0xAA, "Intel Meteor Lake"),
    one(kIntel, 0x6, 0xAC, "Intel Meteor Lake"),
    one(kIntel, 0x6, 0xB5, "Intel Arrow Lake"),
    span(kIntel, 0x6, 0xC5, 0xC6, "Intel Arrow Lake"),
    one(kIntel, 0x6, 0xBD, "Intel Lunar Lake"),
    one(kIntel, 0x6, 0xCC, "Intel Panther Lake"),
    one(kIntel, 0x6, 0xE5, "Intel Panther Lake"),
    one(kIntel, 0x6, 0xD5, "Intel Wildcat Lake"),
    one(kIntel, 0x6, 0xD7, "Intel Bartlett Lake"),
    one(kIntel, 0x6, 0x1C, "Intel Atom Bonnell"),
    one(kIntel, 0x6, 0x26, "Intel Atom Bonnell"),
    one(kIntel, 0x6, 0x27, "Intel Atom Saltwell"),
    span(kIntel, 0x6, 0x35, 0x36, "Intel Atom Saltwell"),
    one(kIntel, 0x6, 0x37, "Intel Atom Silvermont"),
    one(kIntel, 0x6, 0x4A, "Intel Atom Silvermont"),
    one(kIntel, 0x6, 0x4D, "Intel Atom Silvermont"),
    one(kIntel, 0x6, 0x5A, "Intel Atom Silvermont"),
    one(kIntel, 0x6, 0x4C, "Intel Atom Airmont"),
    one(kIntel, 0x6, 0x75, "Intel Atom Airmont"),
    one(kIntel, 0x6, 0x5C, "Intel Atom Goldmont"),
    one(kIntel, 0x6, 0x5F, "Intel Atom Goldmont"),
    one(kIntel, 0x6, 0x7A, "Intel Atom Goldmont Plus"),
    one(kIntel, 0x6, 0x86, "Intel Atom Tremont"),
    one(kIntel, 0x6, 0x96, "Intel Atom Tremont"),
    one(kIntel, 0x6, 0x9C, "Intel Atom Tremont"),
    one(kIntel, 0x6, 0xAF, "Intel Sierra Forest"),
    one(kIntel, 0x6, 0xB6, "Intel Grand Ridge"),
    one(kIntel, 0x6, 0xDD, "Intel Clearwater Forest"),
    one(kIntel, 0x6, 0x57, "Intel Knights Landing"),
    one(kIntel, 0x6, 0x85, "Intel Knights Mill"),
    one(kIntel, 0xB, 0x00, "Intel Knights Ferry"),
    one(kIntel, 0xB, 0x01, "Intel Knights Corner"),
    span(kIntel, 0xF, 0x01, 0x04, "Intel NetBurst"),
    one(kIntel, 0xF, 0x06, "Intel NetBurst"),
    one(kIntel, 0x12, 0x01, "Intel Nova Lake"),
    one(kIntel, 0x12, 0x03, "Intel Nova Lake"),
    one(kIntel, 0x13, 0x01, "Intel Diamond Rapids"),
    span(kAmd, 0xF, 0x00, 0xFF, "AMD K8"),
    span(kAmd, 0x10, 0x00, 0xFF, "AMD K10"),
    span(kAmd, 0x11, 0x00, 0xFF, "AMD K11"),
    span(kAmd, 0x12, 0x00, 0xFF, "AMD K12"),
    span(kAmd, 0x14, 0x00, 0xFF, "AMD Bobcat"),
    one(kAmd, 0x15, 0x01, "AMD Bulldozer"),
    one(kAmd, 0x15, 0x02, "AMD Piledriver"),
    span(kAmd, 0x15, 0x10, 0x1F, "AMD Piledriver"),
    span(kAmd, 0x15, 0x30, 0x3F, "AMD Steamroller"),
    span(kAmd, 0x15, 0x60, 0x7F, "AMD Excavator"),
    span(kAmd, 0x16, 0x00, 0x2F, "AMD Jaguar"),
    span(kAmd, 0x16, 0x30, 0x3F, "AMD Puma"),
    one(kAmd, 0x17, 0x08, "AMD Zen+"),
    span(kAmd, 0x17, 0x00, 0x2F, "AMD Zen"),
    span(kAmd, 0x17, 0x50, 0x5F, "AMD Zen"),
    span(kAmd, 0x17, 0x30, 0x4F, "AMD Zen 2"),
    span(kAmd, 0x17, 0x60, 0x7F, "AMD Zen 2"),
    one(kAmd, 0x17, 0x84, "AMD Zen 2"),
    span(kAmd, 0x17, 0x90, 0x91, "AMD Zen 2"),
    one(kAmd, 0x17, 0x98, "AMD Zen 2"),
    span(kAmd, 0x17, 0xA0, 0xAF, "AMD Zen 2"),
    span(kAmd, 0x19, 0x00, 0x0F, "AMD Zen 3"),
    span(kAmd, 0x19, 0x20, 0x5F, "AMD Zen 3"),
    span(kAmd, 0x19, 0x10, 0x1F, "AMD Zen 4"),
    span(kAmd, 0x19, 0x60, 0xAF, "AMD Zen 4"),
    span(kAmd, 0x1A, 0x00, 0x4F, "AMD Zen 5"),
    span(kAmd, 0x1A, 0x60, 0x7F, "AMD Zen 5"),
    span(kAmd, 0x1A, 0xD0, 0xD7, "AMD Zen 5"),
    span(kAmd, 0x1A, 0x50, 0x5F, "AMD Zen 6"),
    span(kAmd, 0x1A, 0x80, 0xAF, "AMD Zen 6"),
    span(kAmd, 0x1A, 0xC0, 0xCF, "AMD Zen 6"),
    span(kAmd, 0x1A, 0xD8, 0xEF, "AMD Zen 6"),
    span(kHygon, 0x18, 0x00, 0xFF, "Hygon Dhyana"),
    one(kCentaur, 0x6, 0x0F, "Zhaoxin ZhangJiang"),
    one(kCentaur, 0x6, 0x19, "Zhaoxin ZhangJiang"),
    one(kShanghai, 0x6, 0x0F, "Zhaoxin ZhangJiang"),
    one(kShanghai, 0x6, 0x19, "Zhaoxin ZhangJiang"),
    one(kCentaur, 0x7, 0x1B, "Zhaoxin WuDaoKou"),
    one(kCentaur, 0x7, 0x3B, "Zhaoxin LuJiaZui"),
    one(kCentaur, 0x7, 0x5B, "Zhaoxin YongFeng"),
    one(kShanghai, 0x7, 0x1B, "Zhaoxin WuDaoKou"),
    one(kShanghai, 0x7, 0x3B, "Zhaoxin LuJiaZui"),
    one(kShanghai, 0x7, 0x5B, "Zhaoxin YongFeng"),
});

[[nodiscard]] bool matches(const Row& row, const Key& key) noexcept {
    const bool model = key.model >= row.first && key.model <= row.last;
    const bool stepping = key.stepping >= row.stepping_first && key.stepping <= row.stepping_last;
    return row.vendor == key.vendor && row.family == key.family && model && stepping;
}

} // namespace

std::string_view microarchitecture(std::string_view vendor, std::uint32_t family, std::uint32_t model,
    std::uint32_t stepping) noexcept {
    const Key key{.vendor = vendor, .family = family, .model = model, .stepping = stepping};
    const auto found = std::ranges::find_if(kRows, [&key](const Row& row) { return matches(row, key); });
    return found == kRows.end() ? std::string_view() : found->name;
}

} // namespace game::core
