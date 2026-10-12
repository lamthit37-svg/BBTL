// Tạm thời: đo độ dời của thân người trong clip đứng và clip chạy. Xoá sau khi đo.
#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"

#include <cstdio>
#include <expected>
#include <string>

namespace {

std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = game::io::read_text(game::io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(game::io::describe(text.error())));
    return *text;
}

void dump(game::avatar::Skinner& skinner, const game::avatar::Avatar& avatar,
    game::avatar::Stance stance, float length, const char* label) {
    for (int step = 0; step < 6; ++step) {
        const float time = length * static_cast<float>(step) / 6.0F;
        const game::avatar::Playing playing{.stance = stance, .time = time};
        static_cast<void>(skinner.update(avatar, playing));
        float sum_x = 0.0F;
        float sum_z = 0.0F;
        float sum_y = 0.0F;
        for (const game::math::Matrix4& joint : skinner.joints()) {
            sum_x += joint[3].x();
            sum_y += joint[3].y();
            sum_z += joint[3].z();
        }
        const float count = static_cast<float>(skinner.joints().size());
        const auto& root = skinner.joints()[0];
        std::printf("%s t=%.2f  mean(tx,ty,tz)=(%.1f, %.1f, %.1f)  root(tx,ty,tz)=(%.1f, %.1f, %.1f)\n",
            label, static_cast<double>(time), static_cast<double>(sum_x / count),
            static_cast<double>(sum_y / count), static_cast<double>(sum_z / count),
            static_cast<double>(root[3].x()), static_cast<double>(root[3].y()),
            static_cast<double>(root[3].z()));
    }
}

} // namespace

int main() {
    const std::string data = GAME_CLIENT_DATA;
    const auto tables = game::look::load_tables(data + "/Table", read_table);
    if (!tables) return 1;
    const auto* body = game::look::find_body(tables->bodies, game::look::Race::kFemale);
    game::look::Look wanted;
    wanted.face = body->face;
    wanted.hair = body->hair;
    const auto figure = game::look::resolve(*tables, game::look::Race::kFemale, wanted);
    if (!figure) return 2;
    const auto avatar = game::avatar::Avatar::load(*figure, game::io::path_from_utf8(data));
    if (!avatar) return 3;
    game::avatar::Skinner skinner;
    const game::avatar::ClipLengths lengths = avatar->lengths();
    dump(skinner, *avatar, game::avatar::Stance::kIdle, lengths.idle, "idle");
    dump(skinner, *avatar, game::avatar::Stance::kRun, lengths.run, "run ");
    return 0;
}
