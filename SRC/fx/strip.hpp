// Hình của Beam, NewRibbonTrail và Projector. Beam theo WXBeamElement::_updateBillboardChains:
// đích còn là (0, 1, 0) thì chưa có mục tiêu, không dựng. Các mốc giữa cộng RangeRandom.
// Ribbon: đầu bám vị trí hiện tại, cắt khi dài hơn TrailLength hoặc quá số mốc.
#pragma once

#include "fx/system.hpp"

#include <cstdint>
#include <vector>

namespace game::fx {

struct TrailMark {
    ogre::Vec3 position{};
    float age = 0.0F;
};

struct TrailRun {
    std::vector<TrailMark> marks;
};

struct ChainSample {
    ogre::Vec3 position{};
    float width = 1.0F;
    float along = 0.0F;
    Colour colour{1.0F, 1.0F, 1.0F, 1.0F};
};

// Rỗng khi dest là (0, 1, 0), đúng sentinel mDestPos của BeamElement. phase là pha sóng độ tại
// +0x144: mỗi mốc cộng 1 khi IsSinPlay, và lần gọi sau thấy pha mới. Quá 360 thì đưa về 0 trước
// khi dùng.
[[nodiscard]] std::vector<ChainSample> beam_points(const ElementDef& element, ogre::Vec3 dest, std::uint32_t seed,
    float& phase);

void trail_step(TrailRun& run, const ElementDef& element, ogre::Vec3 head, float dt);

[[nodiscard]] std::vector<ChainSample> trail_points(const TrailRun& run, const ElementDef& element);

} // namespace game::fx
