// Dò lỗi huỷ thread_local của GCC MinGW (emutls) theo độ dài chuỗi; không dùng mã dự án.
#include <cstdio>
#include <cstdlib>
#include <string>
#include <thread>
#include <vector>

thread_local std::string t_name;

void body(std::size_t length) {
    t_name.assign(length, 'a');
}

int main(int argc, char** argv) {
    const int rounds = argc > 1 ? std::atoi(argv[1]) : 20000;
    const std::size_t length = argc > 2 ? static_cast<std::size_t>(std::atoi(argv[2])) : 8;
    const bool churn = argc > 3;
    for (int round = 0; round < rounds; ++round) {
        std::vector<std::jthread> threads;
        for (int i = 0; i < 4; ++i) {
            threads.emplace_back(body, length);
        }
        std::vector<std::string> junk;
        for (int k = 0; churn && k < 64; ++k) {
            junk.emplace_back(40, 'x');
        }
    }
    std::printf("xong %d vòng, chuỗi %zu ký tự\n", rounds, length);
    return 0;
}
