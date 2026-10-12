// Bảng tài nguyên có thế hệ đứng sau mỗi loại Handle: chỉ số trỏ vào ô, thế hệ nói ô ấy còn là
// tài nguyên lúc cấp tay nắm hay không. Dùng nội bộ trong hai backend. Platium viết một bảng riêng
// cho từng loại tài nguyên của từng backend, khoá mutex ở cả lần tra; ở đây một bản mẫu, và tra
// (find) không khoá: ô nằm trong các khối cấp một lần không dời chỗ, thế hệ là số nguyên tử, lẻ khi
// ô đang sống. Thêm và gỡ đi qua một mutex. Tra song song với gỡ CHÍNH tay nắm ấy là lỗi của chỗ
// gọi (huỷ tài nguyên khi luồng khác còn ghi lệnh dùng nó); tra song song với mọi thao tác khác
// thì an toàn.
// Nguồn: Forge2 src/gpu/slots.hpp@d7fcd76. Khác gốc: bỏ {} thừa của Slot::value; NOLINT cho ba chỗ
// đọc value sau khi kiểm thế hệ (clang-tidy chỉ báo khi bản mẫu được dựng với kiểu thật).
#pragma once

#include "gpu/handle.hpp"

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <utility>
#include <vector>

namespace game::gpu {

template <class T, class Tag>
class Slots {
public:
    using Key = Handle<Tag>;

    Slots() = default;
    ~Slots() = default;
    Slots(const Slots&) = delete;
    Slots& operator=(const Slots&) = delete;
    Slots(Slots&&) = delete;
    Slots& operator=(Slots&&) = delete;

    // Tay nắm rỗng khi đã hết kCapacity ô.
    [[nodiscard]] Key insert(T value) {
        const std::scoped_lock lock(mutex_);
        const std::optional<std::uint32_t> index = take_index();
        if (!index) return {};
        Slot& slot = slot_at(*index);
        slot.value.emplace(std::move(value));
        // Giá trị dựng xong rồi mới công bố thế hệ lẻ: luồng tra không thấy ô nửa chừng.
        const std::uint32_t generation = slot.generation.load(std::memory_order_relaxed) + 1;
        slot.generation.store(generation, std::memory_order_release);
        ++live_;
        return {.index = *index, .generation = generation};
    }

    // nullptr khi tay nắm rỗng, đã chết hoặc chưa từng được cấp.
    // Khác gốc: thêm NOLINT. Câu bảo vệ của value là thế hệ lẻ khớp tay nắm (live_slot): insert
    // dựng value xong mới công bố thế hệ lẻ, remove công bố thế hệ chẵn rồi mới lấy value ra;
    // clang-tidy chỉ hiểu câu bảo vệ trên chính optional (lệch STD-09).
    // NOLINTBEGIN(bugprone-unchecked-optional-access)
    [[nodiscard]] T* find(Key key) noexcept {
        Slot* const slot = live_slot(key);
        return slot == nullptr ? nullptr : &*slot->value;
    }

    [[nodiscard]] const T* find(Key key) const noexcept {
        const Slot* const slot = live_slot(key);
        return slot == nullptr ? nullptr : &*slot->value;
    }
    // NOLINTEND(bugprone-unchecked-optional-access)

    // Lấy giá trị ra và làm mọi tay nắm của ô chết; rỗng khi tay nắm đã chết.
    [[nodiscard]] std::optional<T> remove(Key key) {
        const std::scoped_lock lock(mutex_);
        Slot* const slot = live_slot(key);
        if (slot == nullptr) return std::nullopt;
        // Thế hệ chẵn trước, lấy giá trị sau: luồng tra thấy ô chết trước khi giá trị bị dời.
        slot->generation.store(key.generation + 1, std::memory_order_release);
        std::optional<T> value = std::exchange(slot->value, std::nullopt);
        spare_.push_back(key.index);
        --live_;
        return value;
    }

    // Lấy hết giá trị còn sống ra, cho lúc huỷ thiết bị.
    [[nodiscard]] std::vector<T> drain() {
        const std::scoped_lock lock(mutex_);
        std::vector<T> values;
        values.reserve(live_);
        for (std::uint32_t index = 0; index < next_; ++index) {
            take_live(slot_at(index), values);
        }
        spare_.clear();
        live_ = 0;
        return values;
    }

    [[nodiscard]] std::size_t size() const {
        const std::scoped_lock lock(mutex_);
        return live_;
    }

private:
    static constexpr std::uint32_t kChunkSlots = 1024;
    static constexpr std::uint32_t kChunks = 4096;
    static constexpr std::uint32_t kCapacity = kChunkSlots * kChunks;

    struct Slot {
        // Lẻ: ô đang giữ value. Chẵn: ô trống.
        std::atomic<std::uint32_t> generation{0};
        // Khác gốc: bỏ {} mà clang-tidy báo thừa.
        std::optional<T> value;
    };

    using Chunk = std::array<Slot, kChunkSlots>;

    // Gọi khi đang giữ mutex_; ô phải thuộc khối đã cấp.
    [[nodiscard]] Slot& slot_at(std::uint32_t index) noexcept {
        Chunk* const chunk = chunks_.at(index / kChunkSlots).load(std::memory_order_relaxed);
        return chunk->at(index % kChunkSlots);
    }

    [[nodiscard]] Slot* live_slot(Key key) const noexcept {
        const bool is_possible = key.index < kCapacity && (key.generation & 1U) != 0;
        if (!is_possible) return nullptr;
        Chunk* const chunk = chunks_.at(key.index / kChunkSlots).load(std::memory_order_acquire);
        if (chunk == nullptr) return nullptr;
        Slot& slot = chunk->at(key.index % kChunkSlots);
        const bool is_same = slot.generation.load(std::memory_order_acquire) == key.generation;
        return is_same ? &slot : nullptr;
    }

    // Chỉ số của một ô trống: ô đã trả, hoặc ô mới (cấp thêm khối khi cần).
    [[nodiscard]] std::optional<std::uint32_t> take_index() {
        if (!spare_.empty()) {
            const std::uint32_t index = spare_.back();
            spare_.pop_back();
            return index;
        }
        if (next_ == kCapacity) return std::nullopt;
        if (next_ % kChunkSlots == 0) add_chunk(next_ / kChunkSlots);
        return next_++;
    }

    void add_chunk(std::uint32_t position) {
        owned_.push_back(std::make_unique<Chunk>());
        chunks_.at(position).store(owned_.back().get(), std::memory_order_release);
    }

    static void take_live(Slot& slot, std::vector<T>& values) {
        const std::uint32_t generation = slot.generation.load(std::memory_order_relaxed);
        if ((generation & 1U) == 0) return;
        slot.generation.store(generation + 1, std::memory_order_release);
        // Khác gốc: thêm NOLINT. Thế hệ lẻ vừa kiểm ở trên là câu bảo vệ của value (lệch STD-09).
        // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
        values.push_back(std::move(*slot.value));
        slot.value.reset();
    }

    // mutex_ bảo vệ owned_, spare_, next_, live_ và việc ghi vào ô; chunks_ và generation đọc được
    // không khoá.
    mutable std::mutex mutex_;
    std::array<std::atomic<Chunk*>, kChunks> chunks_{};
    std::vector<std::unique_ptr<Chunk>> owned_;
    std::vector<std::uint32_t> spare_;
    std::uint32_t next_ = 0;
    std::size_t live_ = 0;
};

} // namespace game::gpu
