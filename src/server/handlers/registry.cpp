#include "handlers/registry.hpp"

#include "talk/handler.hpp"
#include "talk/script.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <set>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::handlers {
namespace {

// Thêm handler: một dòng ở đây (sắp tăng theo script rồi num), hàm chạy ở tệp riêng của hệ thống sở hữu nó.
constexpr std::array<talk::HandlerSpec, 0> kSpecs{};

[[nodiscard]] constexpr bool strictly_increasing(std::span<const talk::HandlerSpec> specs) noexcept {
    for (std::size_t index = 1; index < specs.size(); ++index) {
        const auto previous = std::pair{specs[index - 1].script, specs[index - 1].num};
        if (!(previous < std::pair{specs[index].script, specs[index].num})) return false;
    }
    return true;
}

static_assert(strictly_increasing(kSpecs), "kSpecs phải sắp tăng theo (script, num) và không trùng khoá");

}  // namespace

std::span<const talk::HandlerSpec> registry() noexcept { return kSpecs; }

std::vector<Problem> audit(std::span<const talk::HandlerSpec> specs, const talk::Script& script) {
    std::vector<Problem> problems;
    std::set<std::pair<std::uint32_t, std::int32_t>> seen;
    for (const talk::HandlerSpec& spec : specs) {
        const auto report = [&](std::string what) { problems.push_back(Problem{.script = spec.script, .num = spec.num, .what = std::move(what)}); };
        if (!seen.emplace(spec.script, spec.num).second) report("khoá trùng");
        if (spec.run == nullptr) report("thiếu hàm chạy");
        if (spec.reason.empty()) report("thiếu dòng lý do");
        const talk::Entry* const entry = script.entry(spec.script, spec.num);
        if (entry == nullptr) {
            report("điểm vào không có trong chương trình hội thoại");
        } else if (entry->status == talk::EntryStatus::kOk) {
            report("đè lên điểm vào đã trích được");
        }
    }
    return problems;
}

}  // namespace game::handlers
