/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/retire.hpp
 *  PHÂN HỆ   : Gpu / Retire
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hàng huỷ hoãn: tài nguyên bị destroy chỉ được giải phóng khi GPU đã chạy
 *    xong mọi lần nộp có thể còn dùng nó. Dùng nội bộ trong hai backend.
 *    Platium hoãn theo số khung hình cố định (frames_in_flight): khung nào
 *    không nộp gì vẫn phải chờ, và nộp nhiều hơn số khung đã định trong một
 *    khung là giải phóng sớm. Ở đây mốc là số thứ tự lần nộp của từng hàng đợi
 *    lúc huỷ: việc được chạy đúng khi mọi hàng đợi đã qua mốc ấy, không sớm hơn
 *    và không muộn hơn. An toàn đa luồng.
 *  - Nguồn: Forge2 src/gpu/retire.hpp@d7fcd76. Khác gốc: thân vòng lặp của
 *    take_due tách thành sort_entry; bỏ {} thừa của Entry::action.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <utility>
#include <vector>

namespace game::gpu {

// Số thứ tự lần nộp của từng hàng đợi (chỉ số là QueueType).
using QueueMarks = std::array<std::uint64_t, kQueueCount>;

// Mọi hàng đợi của done đã tới hoặc vượt mốc của wanted.
[[nodiscard]] constexpr bool has_passed(const QueueMarks& done, const QueueMarks& wanted) noexcept {
    return done.at(0) >= wanted.at(0) && done.at(1) >= wanted.at(1) && done.at(2) >= wanted.at(2);
}

// libc++ của NDK 30 chưa có std::move_only_function (đã đo bằng __cpp_lib_move_only_function):
// vỏ xóa kiểu chỉ di chuyển được thay thế, cùng hợp đồng đã dùng (mặc định rỗng, gọi được nhiều
// lần không sao vì mỗi việc chỉ được lấy ra một lần).
class MoveOnlyCall {
public:
    MoveOnlyCall() = default;
    ~MoveOnlyCall() = default;

    // NOLINTNEXTLINE(misc-explicit-constructor,cppcoreguidelines-explicit-constructor): nhận trực
    // tiếp lambda từ lời gọi push(marks, [] {...}), không phải phép chuyển kiểu ngầm ngoài ý muốn.
    template <class Fn>
    MoveOnlyCall(Fn taken) : held_(std::make_unique<Model<Fn>>(std::move(taken))) {}

    MoveOnlyCall(MoveOnlyCall&&) = default;
    MoveOnlyCall& operator=(MoveOnlyCall&&) = default;

    void operator()() {
        if (held_ != nullptr) held_->call();
    }

private:
    // NOLINTBEGIN(cppcoreguidelines-special-member-functions): gốc đa hình chỉ cần huỷ ảo.
    struct Base {
        Base() = default;
        virtual ~Base() = default;
        Base(const Base&) = delete;
        Base& operator=(const Base&) = delete;
        virtual void call() = 0;
    };
    // NOLINTEND(cppcoreguidelines-special-member-functions)

    template <class Fn>
    struct Model : Base {
        Fn held;
        explicit Model(Fn taken) : held(std::move(taken)) {}
        void call() override { held(); }
    };

    std::unique_ptr<Base> held_;
};

class Retired {
public:
#if defined(__cpp_lib_move_only_function)
    using Action = std::move_only_function<void()>;
#else
    using Action = MoveOnlyCall;
#endif

    // action chạy ở lần collect đầu tiên mà GPU đã qua marks.
    void push(const QueueMarks& marks, Action action) {
        const std::scoped_lock lock(mutex_);
        entries_.push_back({.marks = marks, .action = std::move(action)});
    }

    // Chạy các việc đã tới hạn, theo thứ tự đã đẩy vào. Việc chạy ngoài khoá, nên nó được đẩy
    // thêm việc khác.
    void collect(const QueueMarks& done) {
        for (Action& action : take_due(done)) {
            action();
        }
    }

    // Chạy hết, kể cả việc chưa tới hạn và việc sinh thêm trong lúc chạy. Chỉ gọi khi GPU đã rỗi.
    void flush() {
        QueueMarks all{};
        all.fill(~std::uint64_t{0});
        while (size() != 0) {
            collect(all);
        }
    }

    [[nodiscard]] std::size_t size() const {
        const std::scoped_lock lock(mutex_);
        return entries_.size();
    }

private:
    struct Entry {
        QueueMarks marks{};
        Action action;
    };

    using Actions = std::vector<Action>;
    using Entries = std::vector<Entry>;

    // Khác gốc: thân vòng lặp của take_due tách ra đây. Việc tới hạn sang due, còn lại sang kept.
    static void sort_entry(Entry& entry, const QueueMarks& done, Actions& due, Entries& kept) {
        const bool is_due = has_passed(done, entry.marks);
        if (is_due) due.push_back(std::move(entry.action));
        if (!is_due) kept.push_back(std::move(entry));
    }

    [[nodiscard]] std::vector<Action> take_due(const QueueMarks& done) {
        const std::scoped_lock lock(mutex_);
        std::vector<Action> due;
        std::vector<Entry> kept;
        for (Entry& entry : entries_) {
            sort_entry(entry, done, due, kept);
        }
        entries_ = std::move(kept);
        return due;
    }

    // Bảo vệ entries_.
    mutable std::mutex mutex_;
    std::vector<Entry> entries_;
};

} // namespace game::gpu
