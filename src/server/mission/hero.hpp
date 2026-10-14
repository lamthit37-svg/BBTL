#pragma once
// Cửa vào của mission tới MỘT nhân vật: sổ nhiệm vụ của nó, vài chỉ số chỉ đọc (cấp, môn phái, đội, bang, kỹ năng) và ba cổng
// của sổ cái (túi, ví, kinh nghiệm). Lõi không biết Actor hay Inventory thật (thuộc vai khác); zone hay test nối chúng vào
// đây, nhờ vậy mission chạy và thử được thuần.

#include "ids/ids.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "ops/ops.hpp"

#include <cstdint>

namespace game::mission {

class Catalog;

class Character {
public:
    Character() = default;
    Character(const Character&) = delete;
    Character& operator=(const Character&) = delete;
    Character(Character&&) = delete;
    Character& operator=(Character&&) = delete;
    virtual ~Character() = default;

    [[nodiscard]] virtual ids::CharacterId id() const noexcept = 0;
    [[nodiscard]] virtual Book& book() noexcept = 0;
    [[nodiscard]] virtual const Book& book() const noexcept = 0;

    [[nodiscard]] virtual std::int32_t level() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t sect() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t gender() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t team_size() const noexcept = 0;
    [[nodiscard]] virtual bool team_leader() const noexcept = 0;
    [[nodiscard]] virtual std::int32_t guild() const noexcept = 0;  // -1 là không có bang
    [[nodiscard]] virtual std::int32_t ability(std::int32_t skill) const noexcept = 0;
    [[nodiscard]] virtual bool skill_known(std::int32_t skill) const noexcept = 0;
    // Đang chịu hiệu ứng (buff) mã `impact`; hệ hiệu ứng thuộc vai combat, mặc định chưa có hiệu ứng nào.
    [[nodiscard]] virtual bool has_impact(std::int32_t impact) const noexcept {
        static_cast<void>(impact);
        return false;
    }

    [[nodiscard]] virtual ledger::Ports ports() noexcept = 0;
};

// Góc nhìn chỉ đọc của ops trên một Character: tiền, vật phẩm đọc qua cổng, nhiệm vụ đọc từ Book.
class HeroFacade final : public ops::HeroView {
public:
    // `catalog` có thì mới trả được tên nhiệm vụ đang giữ (TGetMissionName); thiếu thì quest_name luôn 0.
    explicit HeroFacade(Character& who, const Catalog* catalog = nullptr) noexcept : who_(who), catalog_(catalog) {}

    [[nodiscard]] std::int32_t level() const noexcept override { return who_.level(); }
    [[nodiscard]] std::int32_t sect() const noexcept override { return who_.sect(); }
    [[nodiscard]] std::int32_t gender() const noexcept override { return who_.gender(); }
    [[nodiscard]] std::int32_t team_size() const noexcept override { return who_.team_size(); }
    [[nodiscard]] bool team_leader() const noexcept override { return who_.team_leader(); }
    [[nodiscard]] std::int32_t guild() const noexcept override { return who_.guild(); }
    [[nodiscard]] std::int32_t bag_space() const noexcept override;
    [[nodiscard]] std::int64_t money(bool bound) const noexcept override;
    [[nodiscard]] std::int64_t item_count(std::uint32_t item) const noexcept override;
    [[nodiscard]] std::int32_t ability(std::int32_t skill) const noexcept override { return who_.ability(skill); }
    [[nodiscard]] bool skill_known(std::int32_t skill) const noexcept override { return who_.skill_known(skill); }
    [[nodiscard]] bool impact_active(std::int32_t impact) const noexcept override { return who_.has_impact(impact); }
    [[nodiscard]] bool quest_active(std::uint32_t quest) const noexcept override;
    [[nodiscard]] bool quest_done(std::uint32_t quest) const noexcept override;
    [[nodiscard]] std::uint32_t quest_name(std::uint32_t quest) const noexcept override;
    [[nodiscard]] std::int32_t quest_count() const noexcept override;
    [[nodiscard]] std::int32_t quest_slots_free() const noexcept override;
    [[nodiscard]] std::int32_t objective(std::uint32_t quest, std::int32_t index) const noexcept override;
    [[nodiscard]] std::int64_t counter(std::int32_t index) const noexcept override;
    [[nodiscard]] bool flag(std::int32_t index) const noexcept override;

private:
    Character& who_;
    const Catalog* catalog_;
};

}  // namespace game::mission
