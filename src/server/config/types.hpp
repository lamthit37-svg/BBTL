#pragma once
// Kiểu mạnh của cấu hình: cổng, id tiến trình, địa chỉ IPv4, loại tiến trình.
// parse từ chối giá trị ngoài miền của chính kiểu; miền riêng của từng khoá nằm ở bộ đọc.

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::config {

enum class ProcessKind : std::uint8_t { kStore, kAuth, kBilling, kWorld, kZone };

enum class ServiceKind : std::uint8_t { kStore, kAuth, kBilling, kWorld, kZone, kGate };

enum class LogLevel : std::uint8_t { kError, kWarn, kInfo, kDebug };

class Port {
public:
    Port() = default;

    // Cổng thật, 1 tới 65535.
    [[nodiscard]] static std::optional<Port> parse(std::int64_t value) noexcept;

    // Cổng 0: hệ điều hành chọn cổng lúc nghe, bên nghe đọc lại cổng thật rồi báo ở dòng `ready`.
    // Bộ đọc cấu hình chỉ trả giá trị này cho bên nghe trên đúng 127.0.0.1 (is_loopback).
    [[nodiscard]] static Port any() noexcept { return Port{}; }

    [[nodiscard]] std::uint16_t value() const noexcept { return value_; }

private:
    explicit Port(std::uint16_t value) noexcept : value_(value) {}

    std::uint16_t value_ = 0;
};

class ProcessId {
public:
    ProcessId() = default;

    [[nodiscard]] static std::optional<ProcessId> parse(std::int64_t value) noexcept;

    [[nodiscard]] std::int64_t value() const noexcept { return value_; }

    [[nodiscard]] bool same(ProcessId other) const noexcept { return value_ == other.value_; }

private:
    explicit ProcessId(std::int64_t value) noexcept : value_(value) {}

    std::int64_t value_ = 0;
};

class MachineId {
public:
    MachineId() = default;

    [[nodiscard]] static std::optional<MachineId> parse(std::int64_t value) noexcept;

    [[nodiscard]] std::int64_t value() const noexcept { return value_; }

    [[nodiscard]] bool same(MachineId other) const noexcept { return value_ == other.value_; }

private:
    explicit MachineId(std::int64_t value) noexcept : value_(value) {}

    std::int64_t value_ = 0;
};

class WorldId {
public:
    WorldId() = default;

    [[nodiscard]] static std::optional<WorldId> parse(std::int64_t value) noexcept;

    [[nodiscard]] std::int64_t value() const noexcept { return value_; }

private:
    explicit WorldId(std::int64_t value) noexcept : value_(value) {}

    std::int64_t value_ = 0;
};

class Ipv4Address {
public:
    Ipv4Address() = default;

    [[nodiscard]] static std::optional<Ipv4Address> parse(std::string_view text);

    [[nodiscard]] std::string_view text() const noexcept { return text_; }

private:
    explicit Ipv4Address(std::string text);

    std::string text_{"0.0.0.0"};
};

// Đúng địa chỉ 127.0.0.1, không phải cả dải 127.0.0.0/8: nơi duy nhất một bên nghe được khai cổng 0.
[[nodiscard]] bool is_loopback(const Ipv4Address& host) noexcept;

struct Endpoint {
    Ipv4Address host;
    Port port;

    // "a.b.c.d:cổng". Cổng 0 chỉ được nhận khi địa chỉ là 127.0.0.1: cấu hình chạy thật nghe địa
    // chỉ khác không được vô tình mở một cổng ngẫu nhiên.
    [[nodiscard]] static std::optional<Endpoint> parse(std::string_view text);
};

struct DatabaseLogin {
    std::string name;
    std::string user;
    std::int64_t pool = 0;
};

[[nodiscard]] std::string_view name_of(ProcessKind kind) noexcept;

[[nodiscard]] std::string_view name_of(ServiceKind kind) noexcept;

[[nodiscard]] ServiceKind service_of(ProcessKind kind) noexcept;

// Dải CIDR IPv4. Trần prefix 0 tới 32 là nghĩa của dạng CIDR trong chú thích.
[[nodiscard]] std::optional<std::string> parse_cidr(std::string_view text);

} // namespace game::config
