#include "service/service.hpp"

#include "process/process.hpp"

#include <chrono>
#include <cstdio>
#include <print>
#include <thread>

namespace game::service {
namespace {

[[nodiscard]] int run_cluster(const Request& request) {
    StartupFiles files;
    if (!configuration_ok(request, files)) return 2;
    return drive_supervisor(request, files);
}

} // namespace

int run(const Request& request) {
    game::process::binary_stdio();
    if (request.config_dir.empty()) {
        std::println(stderr, "thienlong: thiếu --config");
        return 2;
    }
    if (request.kind == Kind::kSupervisor) return run_cluster(request);
    if (!child_configuration_ok(request)) return 2;
    std::println("ready");
    std::fflush(stdout);
    while (!game::process::stop_requested())
        std::this_thread::sleep_for(std::chrono::milliseconds{20});
    return 0;
}

} // namespace game::service
