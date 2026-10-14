// Nhân vật giả cho test của mission, talk, handlers: sổ nhiệm vụ thật, túi/ví/kinh nghiệm giả, chỉ số công khai.
#pragma once

#include "ids/ids.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/hero.hpp"
#include "support/ledger_fakes.hpp"

#include <cstdint>
#include <map>
#include <set>

namespace game::test {

class FakeCharacter final : public mission::Character {
public:
    ids::CharacterId who{1};
    mission::Book book_;
    FakeBundle bundle;
    std::int32_t level_value = 1;
    std::int32_t sect_value = 9;
    std::int32_t gender_value = 0;
    std::int32_t team_size_value = 1;
    bool team_leader_value = false;
    std::int32_t guild_value = -1;
    std::map<std::int32_t, std::int32_t> abilities;
    std::set<std::int32_t> skills;

    FakeCharacter() { bundle.items.capacity = 30; }

    [[nodiscard]] ids::CharacterId id() const noexcept override { return who; }
    [[nodiscard]] mission::Book& book() noexcept override { return book_; }
    [[nodiscard]] const mission::Book& book() const noexcept override { return book_; }
    [[nodiscard]] std::int32_t level() const noexcept override { return level_value; }
    [[nodiscard]] std::int32_t sect() const noexcept override { return sect_value; }
    [[nodiscard]] std::int32_t gender() const noexcept override { return gender_value; }
    [[nodiscard]] std::int32_t team_size() const noexcept override { return team_size_value; }
    [[nodiscard]] bool team_leader() const noexcept override { return team_leader_value; }
    [[nodiscard]] std::int32_t guild() const noexcept override { return guild_value; }
    [[nodiscard]] std::int32_t ability(std::int32_t skill) const noexcept override {
        const auto found = abilities.find(skill);
        return found == abilities.end() ? 0 : found->second;
    }
    [[nodiscard]] bool skill_known(std::int32_t skill) const noexcept override { return skills.contains(skill); }
    [[nodiscard]] ledger::Ports ports() noexcept override { return bundle.ports(); }

    void give(std::uint32_t item, std::int64_t amount) { bundle.items.total[item] += amount; }
    [[nodiscard]] std::int64_t have(std::uint32_t item) const { return bundle.items.count(item); }
};

}  // namespace game::test
