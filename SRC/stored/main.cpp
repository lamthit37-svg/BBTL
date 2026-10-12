#include "service/service.hpp"

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    return game::service::run(game::service::Kind::kStore, argc, argv);
}
