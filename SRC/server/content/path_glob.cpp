// Khớp * trong một đoạn đường dẫn. Hai * trong một đoạn là sai hình, không phải "không khớp".
#include "content/path_glob.hpp"

#include "content/detail/scan.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::content {
namespace {

using Size = std::size_t;
using Views = std::vector<TextView>;

[[nodiscard]] bool push_part(TextView text, Size& start, Views& parts) {
    const auto stop = text.find('/', start);
    const bool last = stop == TextView::npos;
    const auto end = last ? text.size() : stop;
    parts.push_back(text.substr(start, end - start));
    start = end + 1;
    return last;
}

void split_slash(TextView text, Views& parts) {
    parts.clear();
    std::size_t start = 0;
    bool done = false;
    while (!done)
        done = push_part(text, start, parts);
}

[[nodiscard]] bool segment_match(TextView pattern, TextView text, std::string& out, bool& starred) {
    starred = false;
    out.clear();
    const auto star = pattern.find('*');
    if (star == TextView::npos) return pattern == text;
    if (pattern.find('*', star + 1) != TextView::npos) return false;
    const auto prefix = pattern.substr(0, star);
    const auto suffix = pattern.substr(star + 1);
    if (!text.starts_with(prefix)) return false;
    const auto rest = text.substr(prefix.size());
    if (!rest.ends_with(suffix)) return false;
    out.assign(rest.substr(0, rest.size() - suffix.size()));
    starred = true;
    return true;
}

struct SegmentStep {
    bool ok = false;
    bool took = false;
    std::string capture;
};

void keep_first(SegmentStep& step, std::string capture, bool starred, bool already) {
    if (!starred || already) return;
    step.took = true;
    step.capture = std::move(capture);
}

[[nodiscard]] SegmentStep step_segment(TextView pattern, TextView text, bool already) {
    SegmentStep step;
    std::string capture;
    bool starred = false;
    if (!segment_match(pattern, text, capture, starred)) return step;
    step.ok = true;
    keep_first(step, std::move(capture), starred, already);
    return step;
}

void take_capture(GlobHit& hit, const SegmentStep& step) {
    if (!step.took) return;
    hit.starred = true;
    hit.capture = step.capture;
}

[[nodiscard]] bool apply_step(GlobHit& hit, const SegmentStep& step) {
    if (!step.ok) return false;
    take_capture(hit, step);
    return true;
}

[[nodiscard]] bool one_star(TextView segment) noexcept {
    const auto star = segment.find('*');
    if (star == TextView::npos) return true;
    return segment.find('*', star + 1) == TextView::npos;
}

struct ShapeWalk {
    std::size_t start = 0;
    bool ok = true;
    bool done = false;
};

void step_shape(ShapeWalk& walk, TextView pattern) noexcept {
    if (walk.done || !walk.ok) return;
    const auto stop = pattern.find('/', walk.start);
    const bool last = stop == TextView::npos;
    const auto end = last ? pattern.size() : stop;
    walk.ok = one_star(pattern.substr(walk.start, end - walk.start));
    walk.done = last;
    walk.start = end + 1;
}

[[nodiscard]] bool segments_ok(TextView pattern) noexcept {
    ShapeWalk walk;
    while (!walk.done && walk.ok)
        step_shape(walk, pattern);
    return walk.ok;
}

} // namespace

GlobHit match_glob(GlobQuery query) {
    Views left;
    Views right;
    split_slash(query.pattern, left);
    split_slash(query.path, right);
    GlobHit hit;
    bool alive = left.size() == right.size();
    for (std::size_t i = 0; alive && i < left.size(); ++i) {
        const SegmentStep step = step_segment(left[i], right[i], hit.starred);
        alive = apply_step(hit, step);
    }
    if (!alive) return {};
    hit.matched = true;
    return hit;
}

std::string fill_glob_star(StarFill fill) {
    const auto star = fill.pattern.find('*');
    if (star == TextView::npos) return std::string(fill.pattern);
    std::string out;
    out.append(fill.pattern.substr(0, star));
    out.append(fill.capture);
    out.append(fill.pattern.substr(star + 1));
    return out;
}

bool glob_shape_ok(TextView pattern) noexcept {
    if (pattern.empty()) return false;
    if (pattern.contains('?')) return false;
    if (pattern.contains('[')) return false;
    if (pattern.contains(']')) return false;
    return segments_ok(pattern);
}

} // namespace game::content
