// Hệ hạt đang chạy. Bước cố định 0,033 s: hết hạn, affector, chuyển động, rồi phát.
// Ribbon giữ đúng OgreRibbonSet::updateRibbon rồi BillboardChain::updateVertexBuffer.
#pragma once

#include "fx/system.hpp"

#include <cstdint>
#include <limits>
#include <random>
#include <span>
#include <vector>

namespace game::fx {

struct Node {
    ogre::Vec3 position{};
    ogre::Quat orientation{};
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

struct Grain {
    ogre::Vec3 position{};
    ogre::Vec3 direction{};
    Colour colour{1.0F, 1.0F, 1.0F, 1.0F};
    float ttl = 1.0F;
    float total = 1.0F;
    float rotation = 0.0F;
    float rotation_speed = 0.0F;
    bool own = false;
    float width = 0.0F;
    float height = 0.0F;
    float depth = 0.0F;
    ogre::Vec3 angles{};
    ogre::Vec3 angle_speeds{};

    [[nodiscard]] float life() const noexcept { return total > 0.0F ? 1.0F - (ttl / total) : 1.0F; }
};

class Field {
public:
    Field(const SystemDef& definition, std::uint32_t seed);

    void update(float seconds, const Node& node);
    [[nodiscard]] const SystemDef& definition() const noexcept { return *definition_; }
    [[nodiscard]] const Node& node() const noexcept { return node_; }
    [[nodiscard]] std::span<const std::uint32_t> order() const noexcept { return active_; }
    [[nodiscard]] const Grain& grain(std::uint32_t index) const { return pool_.at(index); }

    struct ChainPoint {
        ogre::Vec3 position{};
        float width = 1.0F;
        float texcoord = 0.0F;
        Colour colour{1.0F, 1.0F, 1.0F, 1.0F};
    };

    [[nodiscard]] std::span<const ChainPoint> chain(std::uint32_t index) const;
    [[nodiscard]] float unit();
    [[nodiscard]] float range(float low, float high);

private:
    struct EmitterState {
        bool enabled = true;
        float remainder = 0.0F;
        float duration_left = 0.0F;
        float repeat_left = 0.0F;
        float radius = 0.0F;
        float theta = 0.0F;
        float phi = 0.0F;
        int reset_count = 0;
    };

    void step(float dt);
    void expire(float dt);
    void affect(float dt);
    void apply_kind(const Affector& affector, float dt);
    void revolve(const Revolution& spin, float dt);
    // Vòng của BillboardChain: head là mốc mới nhất, tail là mốc cũ nhất.
    struct RibbonChain {
        std::vector<ChainPoint> slots;
        std::uint32_t head = 0xffffffff;
        std::uint32_t tail = 0xffffffff;
        std::vector<ChainPoint> ordered;
    };

    static constexpr std::uint32_t kEmptyLink = 0xffffffff;
    static constexpr float kRealEpsilon = std::numeric_limits<float>::epsilon();

    void move(float dt);
    void update_ribbon(std::uint32_t index);
    void add_link(RibbonChain& chain, const ChainPoint& fresh);
    [[nodiscard]] float extend_link(RibbonChain& chain, const ChainPoint& fresh, float segment);
    void shrink_link(RibbonChain& chain, float leftover);
    void paint_link(RibbonChain& chain, const Grain& grain, float width);
    void publish_link(RibbonChain& chain);
    [[nodiscard]] static std::uint32_t link_count(const RibbonChain& chain);
    [[nodiscard]] ogre::Vec3 ribbon_local(ogre::Vec3 position) const;
    void emit(float dt);
    void spawn(std::size_t emitter, float offset);
    void init_grain(std::size_t emitter, Grain& grain);
    [[nodiscard]] std::uint16_t emission_count(std::size_t emitter, float dt);

    const SystemDef* definition_ = nullptr;
    Node node_{};
    std::mt19937 random_;
    std::vector<Grain> pool_;
    std::vector<std::uint32_t> active_;
    std::vector<std::uint32_t> free_;
    std::vector<EmitterState> emitters_;
    std::vector<RibbonChain> chains_;
    float remain_ = 0.0F;
};

} // namespace game::fx
