#pragma once
// Tạo SERVER/data/gate/identity.key bằng thienlong_gate --gen-key nếu chưa có.
// Tệp khoá không vào git. Test boot cần nó trước khi gate chịu in ready.

#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "process/process.hpp"

#include <array>
#include <chrono>
#include <filesystem>
#include <string>
#include <string_view>
#include <system_error>

namespace game::test {

[[nodiscard]] inline bool ensure_gate_identity(std::string_view config_dir) {
    const std::filesystem::path config = io::path_from_utf8(config_dir);
    const std::filesystem::path key = (config / ".." / "data" / "gate" / "identity.key").lexically_normal();
    std::error_code error;
    if (std::filesystem::exists(key, error) && !error) return true;
    const std::filesystem::path exe = io::executable_directory() / "thienlong_gate.exe";
    const std::string program = io::utf8_of(exe);
    const std::string file = io::utf8_of(key);
    const std::array<std::string_view, 2> arguments{"--gen-key", file};
    process::Spawn request;
    request.executable = program;
    request.arguments = arguments;
    request.mode = process::Mode::kCommand;
    core::Result<process::Child> child = process::spawn(request);
    if (!child) return false;
    const process::ExitStatus status = child->wait_for(std::chrono::seconds{15});
    const bool exited = status.kind == process::WaitKind::kExited && status.code == 0;
    return exited && std::filesystem::exists(key, error) && !error;
}

} // namespace game::test
