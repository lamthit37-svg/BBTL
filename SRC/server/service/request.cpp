// Đọc dòng lệnh của một tiến trình máy chủ. Dòng lệnh là dữ liệu ngoài: mọi sai sót thành một câu
// lỗi cho người chạy, không dừng chương trình bằng check.
#include "service/detail/request.hpp"

#include "core/check.hpp"
#include "core/number.hpp"
#include "io/file.hpp"
#include "service/service.hpp"

#include <cstddef>
#include <expected>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::service::detail {
namespace {

struct Cursor {
    std::span<const std::string> arguments;
    std::size_t index = 0;
};

struct Parse {
    Kind kind = Kind::kSupervisor;
    Request request;
    std::string error;
};

// Loại có khối [[process]] trong cluster.toml, tức có thể chạy nhiều tiến trình đánh số.
[[nodiscard]] bool has_instances(Kind kind) noexcept {
    return kind != Kind::kSupervisor && kind != Kind::kGate;
}

// Giá trị đứng sau một cờ; rỗng khi dòng lệnh hết ở đó.
[[nodiscard]] std::string_view take_value(Cursor& cursor) noexcept {
    if (cursor.index + 1 >= cursor.arguments.size()) return {};
    ++cursor.index;
    return cursor.arguments[cursor.index];
}

void take_config(Parse& parse, Cursor& cursor) {
    const std::string_view value = take_value(cursor);
    if (value.empty()) {
        parse.error = "--config cần một thư mục";
        return;
    }
    parse.request.config_dir = io::path_from_utf8(value);
}

void take_id(Parse& parse, Cursor& cursor) {
    const std::optional<int> id = core::parse_whole_int(take_value(cursor));
    if (!has_instances(parse.kind)) {
        parse.error = "loại tiến trình này không nhận --id";
    } else if (!id) {
        parse.error = "--id cần một số nguyên không âm";
    }
    parse.request.id = id;
}

void take_postgres_switch(Parse& parse) {
    parse.request.skips_postgres = true;
    if (parse.kind == Kind::kSupervisor) return;
    parse.error = "chỉ thienlong_server nhận --no-postgres";
}

void take_gen_key(Parse& parse, Cursor& cursor) {
    if (parse.kind != Kind::kGate) {
        parse.error = "chỉ thienlong_gate nhận --gen-key";
        return;
    }
    const std::string_view value = take_value(cursor);
    if (value.empty()) {
        parse.error = "--gen-key cần một đường dẫn";
        return;
    }
    parse.request.identity_out = io::path_from_utf8(value);
}

void take_word(Parse& parse, Cursor& cursor) {
    const std::string_view word = cursor.arguments[cursor.index];
    if (word == "--config") {
        take_config(parse, cursor);
    } else if (word == "--id") {
        take_id(parse, cursor);
    } else if (word == "--no-postgres") {
        take_postgres_switch(parse);
    } else if (word == "--gen-key") {
        take_gen_key(parse, cursor);
    } else {
        parse.error = std::format("đối số lạ {}", word);
    }
}

} // namespace

RequestResult parse_request(Kind kind, std::span<const std::string> arguments) {
    Parse parse;
    parse.kind = kind;
    Cursor cursor{.arguments = arguments};
    while (parse.error.empty() && cursor.index < arguments.size()) {
        take_word(parse, cursor);
        ++cursor.index;
    }
    const bool wants_key = parse.request.identity_out.has_value();
    const bool lacks_config = parse.error.empty() && !wants_key && parse.request.config_dir.empty();
    if (lacks_config) parse.error = "thiếu --config <thư mục cấu hình>";
    if (!parse.error.empty()) return std::unexpected(std::move(parse.error));
    if (has_instances(kind) && !parse.request.id) parse.request.id = 0;
    return std::move(parse.request);
}

std::string_view kind_name(Kind kind) noexcept {
    switch (kind) {
    case Kind::kSupervisor: return "server";
    case Kind::kStore: return "store";
    case Kind::kAuth: return "auth";
    case Kind::kBilling: return "billing";
    case Kind::kWorld: return "world";
    case Kind::kZone: return "zone";
    case Kind::kGate: return "gate";
    }
    core::fail("loại tiến trình ngoài miền");
}

std::string usage(Kind kind) {
    if (kind == Kind::kGate) {
        return "cách dùng: thienlong_gate --config <thư mục> | thienlong_gate --gen-key <tệp khoá>";
    }
    std::string_view extra;
    if (kind == Kind::kSupervisor) extra = " [--no-postgres]";
    if (has_instances(kind)) extra = " [--id <số thứ tự>]";
    const std::string_view name = kind_name(kind);
    return std::format("cách dùng: thienlong_{} --config <thư mục cấu hình>{}", name, extra);
}

} // namespace game::service::detail
