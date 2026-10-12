#pragma once
// Khớp mẫu đường dẫn của refs: mỗi * nằm trong một đoạn, không vượt qua dấu /.

#include "content/detail/scan.hpp"

#include <string>

namespace game::content {

struct GlobHit {
    bool matched = false;
    bool starred = false;
    std::string capture;
};

// Hai TextView cạnh nhau dễ đảo. Gói lại để lời gọi nói rõ mẫu và đường dẫn.
struct GlobQuery {
    TextView pattern;
    TextView path;
};

struct StarFill {
    TextView pattern;
    TextView capture;
};

// Khớp pattern với path. * đầu tiên, nếu có, ghi vào capture.
[[nodiscard]] GlobHit match_glob(GlobQuery query);

// Thay * đầu tiên của pattern bằng capture. Không có * thì trả nguyên mẫu.
[[nodiscard]] std::string fill_glob_star(StarFill fill);

// false khi rỗng, có ?, có ngoặc, hoặc một đoạn chứa hơn một *.
[[nodiscard]] bool glob_shape_ok(TextView pattern) noexcept;

} // namespace game::content
