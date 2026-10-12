// Dò lỗi thứ tự huỷ thread_local của GCC MinGW (emutls): không dùng mã dự án.
#include <cstdio>
#include <cstdlib>
#include <string>
#include <thread>
#include <vector>

thread_local std::string t_name;

void body(int index) {
    t_name = "QAJobs " + std::to_string(index);
}

int main(int argc, char** argv) {
    const int rounds = argc > 1 ? std::atoi(argv[1]) : 20000;
    const int threads_per_round = argc > 2 ? std::atoi(argv[2]) : 4;
    for (int round = 0; round < rounds; ++round) {
        std::vector<std::jthread> threads;
        for (int i = 0; i < threads_per_round; ++i) {
            threads.emplace_back(body, i);
        }
        std::vector<std::string> junk;
        for (int k = 0; k < 64; ++k) {
            junk.emplace_back(40, 'x');
        }
    }
    std::printf("xong %d vòng\n", rounds);
    return 0;
}
