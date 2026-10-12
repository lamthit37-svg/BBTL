// Hai hàng của hệ thống việc (jobs.hpp), tách ra để phép thử và bài đo chạm được từng hàng.
//
// WorkQueue là hàng Chase-Lev của một thợ: chủ đẩy và lấy ở đáy, mới nhất trước để việc vừa sinh
// còn nóng trong cache; luồng khác trộm ở đỉnh, cũ nhất trước. Sức chứa cố định.
// SharedQueue là hàng của những bên không có hàng riêng: luồng ngoài hệ thống, job tràn khỏi hàng
// thợ. Vòng không khoá kiểu Vyukov, đầy thì tràn sang vòng có khoá. Cả hai lấy từ VnS
// (src/core/job_queue.*, đã đo cạnh No1, Platium, Wicked). Forge2 thêm pop_batch: một CAS nhận
// nhiều ô liền nhau đã sẵn, thay vì mỗi job một lần giành con trỏ đọc với mọi thợ khác.
// Nguồn: Forge2 src/jobs/queue.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k.
#pragma once

#include "jobs/jobs.hpp"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <span>
#include <vector>

namespace game::jobs::detail {

// Lost: luồng khác vừa giành đúng phần tử đó; hàng có thể còn việc nên thử lại là đáng công.
enum class Steal : std::uint8_t { kEmpty, kLost, kWon };

class WorkQueue {
public:
    // Sức chứa làm tròn lên lũy thừa của 2, ít nhất 2.
    explicit WorkQueue(std::uint32_t capacity);
    WorkQueue(const WorkQueue&) = delete;
    WorkQueue(WorkQueue&&) = delete;
    WorkQueue& operator=(const WorkQueue&) = delete;
    WorkQueue& operator=(WorkQueue&&) = delete;
    ~WorkQueue();

    [[nodiscard]] std::size_t capacity() const noexcept { return mask_ + 1U; }

    // Chỉ luồng chủ. false khi đầy.
    [[nodiscard]] bool push(const Job& job) noexcept;
    // Chỉ luồng chủ. false khi rỗng.
    [[nodiscard]] bool pop(Job& out) noexcept;
    // Mọi luồng.
    [[nodiscard]] Steal steal(Job& out) noexcept;

    // Ước lượng không hàng rào: sai thì chỉ trễ. Dùng để bỏ qua hàng rỗng khỏi phải trả hàng rào
    // của steal, và để quyết định có ngủ hay không.
    [[nodiscard]] bool looks_empty() const noexcept;

private:
    struct Bottom;
    struct Cell;
    struct Ends;

    [[nodiscard]] Cell& cell_at(std::int64_t cursor) noexcept;
    [[nodiscard]] bool has_room(std::int64_t end) noexcept;
    [[nodiscard]] bool give_back(std::int64_t end) noexcept;
    [[nodiscard]] bool settle_last(std::int64_t last) noexcept;
    static void write(Cell& cell, const Job& job) noexcept;
    [[nodiscard]] static Job read(const Cell& cell) noexcept;

    std::unique_ptr<Ends> ends_;
    std::vector<Cell> cells_;
    std::size_t mask_;
};

// Nhiều bên đẩy, nhiều bên lấy. Vòng chính không khoá: mỗi ô mang số thứ tự cho biết nó chờ bên
// đẩy hay bên lấy. Vòng đầy thì job tràn sang vòng có khoá, tự lớn, không co. Bên lấy rút phần tràn
// trước để nó không bị đói. Không bảo đảm thứ tự giữa hai đường.
class SharedQueue {
public:
    // Sức chứa của vòng không khoá, làm tròn lên lũy thừa của 2, ít nhất 2.
    explicit SharedQueue(std::uint32_t capacity = 1024);
    SharedQueue(const SharedQueue&) = delete;
    SharedQueue(SharedQueue&&) = delete;
    SharedQueue& operator=(const SharedQueue&) = delete;
    SharedQueue& operator=(SharedQueue&&) = delete;
    ~SharedQueue();

    // Ném khi hết bộ nhớ lúc phần tràn lớn thêm; khi đó hàng không đổi.
    void push(const Job& job);
    [[nodiscard]] bool pop(Job& out);
    // Lấy tối đa out.size() job trong một lần giành; trả số job đã lấy, 0 khi rỗng.
    [[nodiscard]] std::size_t pop_batch(std::span<Job> out);
    [[nodiscard]] bool looks_empty() const noexcept;

private:
    struct Slot;
    struct Ring;
    enum class Claim : std::uint8_t { kWon, kBlocked, kRetry };

    [[nodiscard]] Claim claim_push(std::uint64_t& position) noexcept;
    [[nodiscard]] Claim claim_pop(std::uint64_t& position, std::size_t limit, std::size_t& count) noexcept;
    [[nodiscard]] std::size_t ready_after(std::uint64_t position, std::size_t limit) noexcept;
    [[nodiscard]] bool ring_push(const Job& job) noexcept;
    [[nodiscard]] std::size_t ring_pop(std::span<Job> out) noexcept;
    void spill(const Job& job);
    [[nodiscard]] std::size_t unspill(std::span<Job> out);
    void grow();

    std::unique_ptr<Ring> ring_;
    std::vector<Slot> slots_;
    std::size_t mask_;
    // mutex_ bảo vệ spill_, head_, count_. spilled_ là bản không khoá của count_.
    std::mutex mutex_;
    std::vector<Job> spill_;
    std::size_t head_ = 0;
    std::size_t count_ = 0;
    std::atomic<std::size_t> spilled_{0};
};

} // namespace game::jobs::detail
