// Ba cổng giả của sổ cái: túi theo ô, ví hai ngăn, kinh nghiệm cộng dồn. Có chèn lỗi (fail_after) để thử đường quay lui.
#pragma once

#include "ledger/ledger.hpp"

#include <algorithm>
#include <cstdint>
#include <map>
#include <span>
#include <utility>

namespace game::test {

// NOLINTBEGIN(cppcoreguidelines-non-private-member-variables-in-classes,bugprone-exception-escape,bugprone-easily-swappable-parameters):
// đồ giả của test — dữ liệu cấu hình để test chỉnh trực tiếp, bad_alloc làm test dừng, không cần xử lý (HP-07)
class FakeItems final : public ledger::ItemPort {
public:
    std::map<std::uint32_t, std::int64_t> total;  // tổng mỗi mẫu
    std::map<std::uint32_t, std::int64_t> bound;  // phần khoá của mỗi mẫu
    std::int32_t capacity = 20;                   // số ô
    std::int64_t stack_max = 99;
    std::int64_t fail_after = -1;                 // số thao tác còn chạy được trước khi báo lỗi; -1 là không chèn lỗi
    std::int64_t operations = 0;

    [[nodiscard]] std::int64_t count(std::uint32_t item) const noexcept override { return value_of(total, item); }

    [[nodiscard]] std::int32_t free_slots() const noexcept override { return capacity - slots(total); }

    [[nodiscard]] bool fits(std::span<const ledger::Stack> removes,
        std::span<const ledger::Stack> gives) const noexcept override {
        std::map<std::uint32_t, std::int64_t> after = total;
        for (const ledger::Stack& one : removes) after[one.item] -= one.count;
        for (const ledger::Stack& one : gives) after[one.item] += one.count;
        return slots(after) <= capacity;
    }

    bool remove(std::uint32_t item, std::int64_t amount) noexcept override {
        if (!allowed() || value_of(total, item) < amount) return false;
        total[item] -= amount;
        // Khoá bị thu trước: như túi thật thu ô khoá sau cùng nên đây chỉ là mô hình đơn giản, đủ cho bất biến tổng.
        bound[item] = std::min(value_of(bound, item), total[item]);
        return true;
    }

    bool give(std::uint32_t item, std::int64_t amount, bool lock) noexcept override {
        if (!allowed()) return false;
        total[item] += amount;
        if (lock) bound[item] += amount;
        return true;
    }

    void checkpoint() override { saved_ = Saved{.total = total, .bound = bound, .operations = operations}; }
    void rollback() noexcept override {
        total = saved_.total;
        bound = saved_.bound;
        operations = saved_.operations;
    }

private:
    struct Saved {
        std::map<std::uint32_t, std::int64_t> total;
        std::map<std::uint32_t, std::int64_t> bound;
        std::int64_t operations = 0;
    };

    [[nodiscard]] static std::int64_t value_of(const std::map<std::uint32_t, std::int64_t>& map, std::uint32_t key) {
        const auto found = map.find(key);
        return found == map.end() ? 0 : found->second;
    }

    [[nodiscard]] std::int32_t slots(const std::map<std::uint32_t, std::int64_t>& counts) const {
        std::int64_t used = 0;
        for (const auto& [item, amount] : counts) {
            static_cast<void>(item);
            if (amount > 0) used += (amount + stack_max - 1) / stack_max;
        }
        return static_cast<std::int32_t>(std::min<std::int64_t>(used, 1'000'000));
    }

    [[nodiscard]] bool allowed() noexcept {
        ++operations;
        return fail_after < 0 || operations <= fail_after;
    }

    Saved saved_;
};

class FakeWallet final : public ledger::WalletPort {
public:
    std::int64_t normal = 0;
    std::int64_t locked = 0;
    std::int64_t cap = std::int64_t{1} << 40;
    bool fail_give = false;

    [[nodiscard]] std::int64_t balance(bool lock) const noexcept override { return lock ? locked : normal; }
    [[nodiscard]] std::int64_t room(bool lock) const noexcept override { return cap - balance(lock); }
    bool take(std::int64_t amount, bool lock) noexcept override {
        std::int64_t& pool = lock ? locked : normal;
        if (pool < amount) return false;
        pool -= amount;
        return true;
    }
    bool give(std::int64_t amount, bool lock) noexcept override {
        std::int64_t& pool = lock ? locked : normal;
        if (fail_give || pool + amount > cap) return false;
        pool += amount;
        return true;
    }
    void checkpoint() override { saved_ = {normal, locked}; }
    void rollback() noexcept override {
        normal = saved_.first;
        locked = saved_.second;
    }

private:
    std::pair<std::int64_t, std::int64_t> saved_;
};

class FakeExp final : public ledger::ExpPort {
public:
    std::int64_t total = 0;
    bool fail = false;

    bool give(std::int64_t amount) noexcept override {
        if (fail) return false;
        total += amount;
        return true;
    }
    void checkpoint() override { saved_ = total; }
    void rollback() noexcept override { total = saved_; }

private:
    std::int64_t saved_ = 0;
};

struct FakeBundle {
    FakeItems items;
    FakeWallet wallet;
    FakeExp exp;

    [[nodiscard]] ledger::Ports ports() noexcept { return ledger::Ports{.items = items, .wallet = wallet, .exp = exp}; }
};
// NOLINTEND(cppcoreguidelines-non-private-member-variables-in-classes,bugprone-exception-escape,bugprone-easily-swappable-parameters)

}  // namespace game::test
