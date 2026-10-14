// Nhân vật giả cho test của ops, mission, talk: mọi đại lượng là trường công khai, tra cứu bằng map.
#pragma once

#include "ops/ops.hpp"

#include <algorithm>
#include <cstdint>
#include <map>
#include <set>
#include <utility>

namespace game::test {

class FakeHero final : public ops::HeroView {
public:
    std::int32_t level_value = 1;
    std::int32_t sect_value = 9;
    std::int32_t gender_value = 0;
    std::int32_t team_size_value = 1;
    bool team_leader_value = false;
    std::int32_t guild_value = -1;
    std::int32_t bag_space_value = 20;
    std::int64_t money_value = 0;
    std::int64_t bound_money_value = 0;
    std::int32_t quest_count_value = 0;
    std::int32_t slots_free_value = 20;
    std::map<std::uint32_t, std::int64_t> items;
    std::map<std::int32_t, std::int32_t> abilities;
    std::set<std::int32_t> skills;
    std::set<std::int32_t> impacts;
    std::set<std::uint32_t> active;
    std::map<std::uint32_t, std::uint32_t> names;  // mã tên của nhiệm vụ đang giữ
    std::set<std::uint32_t> done;
    std::map<std::pair<std::uint32_t, std::int32_t>, std::int32_t> objectives;
    std::map<std::int32_t, std::int64_t> counters;
    std::set<std::int32_t> flags;

    [[nodiscard]] std::int32_t level() const noexcept override { return level_value; }
    [[nodiscard]] std::int32_t sect() const noexcept override { return sect_value; }
    [[nodiscard]] std::int32_t gender() const noexcept override { return gender_value; }
    [[nodiscard]] std::int32_t team_size() const noexcept override { return team_size_value; }
    [[nodiscard]] bool team_leader() const noexcept override { return team_leader_value; }
    [[nodiscard]] std::int32_t guild() const noexcept override { return guild_value; }
    [[nodiscard]] std::int32_t bag_space() const noexcept override { return bag_space_value; }
    [[nodiscard]] std::int64_t money(bool bound) const noexcept override {
        return bound ? bound_money_value : money_value;
    }
    [[nodiscard]] std::int64_t item_count(std::uint32_t item) const noexcept override {
        const auto found = items.find(item);
        return found == items.end() ? 0 : found->second;
    }
    [[nodiscard]] std::int32_t ability(std::int32_t skill) const noexcept override {
        const auto found = abilities.find(skill);
        return found == abilities.end() ? 0 : found->second;
    }
    [[nodiscard]] bool skill_known(std::int32_t skill) const noexcept override { return skills.contains(skill); }
    [[nodiscard]] bool impact_active(std::int32_t impact) const noexcept override { return impacts.contains(impact); }
    [[nodiscard]] bool quest_active(std::uint32_t quest) const noexcept override { return active.contains(quest); }
    [[nodiscard]] bool quest_done(std::uint32_t quest) const noexcept override { return done.contains(quest); }
    [[nodiscard]] std::uint32_t quest_name(std::uint32_t quest) const noexcept override {
        const auto found = names.find(quest);
        return found == names.end() ? 0 : found->second;
    }
    [[nodiscard]] std::int32_t quest_count() const noexcept override { return quest_count_value; }
    [[nodiscard]] std::int32_t quest_slots_free() const noexcept override { return slots_free_value; }
    [[nodiscard]] std::int32_t objective(std::uint32_t quest, std::int32_t index) const noexcept override {
        const auto found = objectives.find({quest, index});
        return found == objectives.end() ? 0 : found->second;
    }
    [[nodiscard]] std::int64_t counter(std::int32_t index) const noexcept override {
        const auto found = counters.find(index);
        return found == counters.end() ? 0 : found->second;
    }
    [[nodiscard]] bool flag(std::int32_t index) const noexcept override { return flags.contains(index); }
};

}  // namespace game::test
