// Hành trang giả của world cho test thư: mỗi người có tiền và tập sê-ri vật phẩm/trân thú. Pha 1 giữ chỗ,
// pha 2 mới chuyển; test mail và test mô phỏng dùng chung để cùng một định nghĩa "bảo toàn".
#pragma once

#include "social/mail.hpp"
#include "social/types.hpp"

#include <cstdint>
#include <map>
#include <optional>
#include <set>

namespace game::test {

using social::AttachmentPort;
using social::Copper;
using social::MailItem;
using social::MailPayload;
using social::ReservationId;

class FakePort final : public AttachmentPort {
public:
    struct Inventory {
        Copper money = 0;
        std::set<std::uint64_t> items;
        std::set<std::uint64_t> pets;
    };
    struct Held {
        social::CharacterId sender{};
        MailPayload payload;
        Copper fee = 0;
    };

    std::map<social::CharacterId, Inventory> inventory;
    std::map<ReservationId, Held> held;
    ReservationId next = 1;
    bool refuse_claim = false;
    Copper fees_burned = 0;

    [[nodiscard]] std::optional<ReservationId> reserve(social::CharacterId sender, const MailPayload& payload, Copper fee) override {
        const Inventory& have = inventory[sender];
        for (const MailItem& item : payload.items) {
            if (!have.items.contains(item.serial.value())) return std::nullopt;
        }
        if (payload.pet.value() != 0 && !have.pets.contains(payload.pet.value())) return std::nullopt;
        // Giữ chỗ cộng dồn: mọi lần giữ chỗ đang mở cũng tính vào số tiền đã cam kết.
        Copper committed = payload.money + fee;
        for (const auto& [id, other] : held) {
            if (other.sender == sender) committed += other.payload.money + other.fee;
        }
        if (have.money < committed) return std::nullopt;
        const ReservationId id = next++;
        held.emplace(id, Held{.sender = sender, .payload = payload, .fee = fee});
        return id;
    }

    void commit(ReservationId reservation) override {
        const auto found = held.find(reservation);
        if (found == held.end()) return;
        Inventory& have = inventory[found->second.sender];
        for (const MailItem& item : found->second.payload.items) have.items.erase(item.serial.value());
        have.pets.erase(found->second.payload.pet.value());
        have.money -= found->second.payload.money + found->second.fee;
        fees_burned += found->second.fee;
        held.erase(found);
    }

    void release(ReservationId reservation) override { held.erase(reservation); }

    [[nodiscard]] bool claim(social::CharacterId recipient, const MailPayload& payload, Copper cod) override {
        if (refuse_claim) return false;
        Inventory& have = inventory[recipient];
        if (have.money < cod) return false;
        have.money += payload.money - cod;
        for (const MailItem& item : payload.items) have.items.insert(item.serial.value());
        if (payload.pet.value() != 0) have.pets.insert(payload.pet.value());
        return true;
    }

    // Tổng tiền trong mọi hành trang.
    [[nodiscard]] Copper total_money() const {
        Copper total = 0;
        for (const auto& [id, have] : inventory) total += have.money;
        return total;
    }
};

} // namespace game::test
