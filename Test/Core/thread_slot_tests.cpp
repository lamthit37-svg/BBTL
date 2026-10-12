// core::thread_slot: mỗi luồng một giá trị, giữ qua các lần gọi; giá trị được huỷ khi luồng kết
// thúc ở toolchain làm được việc đó; và ca tái hiện lỗi của GCC MinGW (TLS giả lập trả bộ nhớ trước
// khi destructor chạy, docs/NGHI-NGO.md mục 12): hàng trăm luồng ngắn giữ một std::string dài trong
// ô rồi thoát, tiến trình không được hỏng heap.
#include "core/thread_slot.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <functional>
#include <memory>
#include <string>
#include <thread>
#include <vector>

namespace game::test {
namespace {

constexpr std::size_t kChurnThreads = 400;
constexpr std::size_t kLongText = 200;
constexpr std::size_t kWatched = 8;

std::string& note() {
    return core::thread_slot([] { return std::string(); });
}

std::shared_ptr<int>& held() {
    return core::thread_slot([] { return std::make_shared<int>(0); });
}

void slot_is_per_thread(Context& context) {
    note() = "chính";
    std::string seen = "chưa chạy";
    std::jthread other([&seen] {
        seen = note();
        note() = "phụ";
    });
    other.join();
    context.expect(seen.empty(), "luồng khác thấy giá trị mới dựng của riêng nó");
    context.expect(note() == "chính", "giá trị của luồng này còn nguyên qua các lần gọi");
}

void fill_and_leave(std::atomic<std::size_t>& finished) {
    note().assign(kLongText, 'x');
    finished.fetch_add(1, std::memory_order_relaxed);
}

// Chuỗi 200 ký tự nằm trên heap, nên destructor chạy trên vùng TLS đã trả là trả một con trỏ rác.
void slot_survives_thread_churn(Context& context) {
    std::atomic<std::size_t> finished = 0;
    std::vector<std::jthread> threads;
    threads.reserve(kChurnThreads);
    for (std::size_t i = 0; i < kChurnThreads; ++i)
        threads.emplace_back(&fill_and_leave, std::ref(finished));
    threads.clear();
    context.expect(finished.load() == kChurnThreads, "mọi luồng dùng ô rồi thoát êm");
}

void watch_slot(std::weak_ptr<int>& watcher) {
    watcher = held();
}

// Luồng đã join thì destructor của ô đã chạy xong (nơi nào huỷ được), nên con trỏ yếu hết hạn.
void slot_dies_with_its_thread(Context& context) {
    std::array<std::weak_ptr<int>, kWatched> watchers;
    std::vector<std::jthread> threads;
    threads.reserve(kWatched);
    for (std::weak_ptr<int>& watcher : watchers)
        threads.emplace_back(&watch_slot, std::ref(watcher));
    threads.clear();
    const auto is_gone = [](const std::weak_ptr<int>& watcher) { return watcher.expired(); };
    const auto gone = static_cast<std::size_t>(std::ranges::count_if(watchers, is_gone));
    const std::size_t wanted = core::kThreadExitDestroys ? kWatched : 0;
    context.expect(gone == wanted, "giá trị huỷ theo luồng, trừ toolchain không huỷ được");
}

constexpr std::array kCases{
    Case{.name = "slot_is_per_thread", .body = &slot_is_per_thread},
    Case{.name = "slot_survives_thread_churn", .body = &slot_survives_thread_churn},
    Case{.name = "slot_dies_with_its_thread", .body = &slot_dies_with_its_thread},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "thread_slot_tests: mọi ca phải qua");
    return 0;
}
