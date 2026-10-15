// Lượt chạy hàng loạt của giao diện Lua: mở host cho cả sổ cửa sổ (Script/windows.tsv), rồi với từng cửa sổ hiện nó (nạp layout,
// _OnLoad, sự kiện Shown), gửi từng sự kiện nó đăng ký (không đối số) và giấu nó, và kê những gì script đòi mà client chưa có:
// hàm và bảng toàn cục của game (tầng B), phương thức của widget (chế độ Missing::kRecord của ui/script/widget.hpp).
// Dùng để xếp việc cho tầng B và widget bằng số lần gặp thật thay cho đoán; không phải test (không đỏ khi còn thiếu).
// Chạy ở gốc dự án:
//   ui_script_survey [--data dev/client/assets] [--events] [--out báo-cáo.txt]
// Không đụng chuột, bàn phím hay cửa sổ. Báo cáo ra stdout nếu không có --out.
#include "gui/loader.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "ui/script/context.hpp"
#include "ui/script/gui_screen.hpp"
#include "ui/script/host.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/natives.hpp"
#include "ui/script/widget.hpp"
#include "ui/script/windows.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <map>
#include <ostream>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

extern "C" {
#include "lua.h"
}

namespace {

using game::ui::script::Host;

struct Options {
    std::filesystem::path data = "dev/client/assets";
    std::filesystem::path out;
    bool is_events = false;
};

// Một dòng lỗi của Lua 5.0: "attempt to <call|index> <global|method|field|local|upvalue> `tên' (a nil value)". Trả loại và tên;
// rỗng khi không phải dạng đó.
struct Missing {
    std::string kind;
    std::string name;
};

[[nodiscard]] Missing classify(std::string_view note) {
    // Lỗi chạy của lua::State kèm traceback ở các dòng sau; chỉ dòng đầu là lời lỗi.
    note = note.substr(0, note.find('\n'));
    constexpr std::string_view kMark = "attempt to ";
    const std::size_t at = note.find(kMark);
    if (at == std::string_view::npos) return {};
    const std::string_view rest = note.substr(at + kMark.size());
    const std::size_t open = rest.find('`');
    const std::size_t close = rest.find('\'', open == std::string_view::npos ? 0 : open);
    if (open == std::string_view::npos || close == std::string_view::npos || !rest.substr(close).contains("nil value")) return {};
    return Missing{.kind = std::string(rest.substr(0, open - 1)), .name = std::string(rest.substr(open + 1, close - open - 1))};
}

class Tally {
public:
    void add(const Missing& missing, const std::string& window) {
        if (missing.kind.empty()) {
            ++other_;
            return;
        }
        Row& row = rows_[std::format("{} {}", missing.kind, missing.name)];
        ++row.count;
        if (row.windows.size() < 5 && !std::ranges::contains(row.windows, window)) row.windows.push_back(window);
    }

    void print(std::ostream& out) const {
        std::vector<std::pair<std::string, Row>> sorted(rows_.begin(), rows_.end());
        std::ranges::sort(sorted, [](const auto& left, const auto& right) {
            return left.second.count != right.second.count ? left.second.count > right.second.count : left.first < right.first;
        });
        for (const auto& [name, row] : sorted) {
            std::string windows;
            for (const std::string& one : row.windows)
                windows += (windows.empty() ? "" : ",") + one;
            out << std::format("{}\t{}\t{}\n", row.count, name, windows);
        }
        out << std::format("# lỗi dạng khác (đối số nil, chuỗi, cú pháp...): {}\n", other_);
    }

private:
    struct Row {
        std::uint32_t count = 0;
        std::vector<std::string> windows;
    };
    std::map<std::string, Row> rows_;
    std::uint32_t other_ = 0;
};

bool parse(const std::vector<std::string>& args, Options& options) {
    for (std::size_t at = 0; at < args.size(); ++at) {
        const std::string_view arg = args[at];
        if (arg == "--events") {
            options.is_events = true;
        } else if ((arg == "--data" || arg == "--out") && at + 1 < args.size()) {
            (arg == "--data" ? options.data : options.out) = game::io::path_from_utf8(args[++at]);
        } else {
            std::cerr << "Cách dùng: ui_script_survey [--data <thư mục>] [--events] [--out <tệp>]\n";
            return false;
        }
    }
    return true;
}

void drain(Host& host, const std::string& window, Tally& tally) {
    for (const std::string& note : host.take_notes())
        tally.add(classify(note), window);
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    game::io::use_utf8_console();
    Options options;
    if (!parse(game::io::command_arguments(argc, argv), options)) return 2;
    const game::io::TextResult registry = game::io::read_text(options.data / "Script" / "windows.tsv");
    if (!registry) {
        std::cerr << "không đọc được Script/windows.tsv: " << game::io::describe(registry.error()) << '\n';
        return 1;
    }
    const auto windows = game::ui::script::parse_windows(*registry);
    if (!windows) {
        std::cerr << windows.error() << '\n';
        return 1;
    }
    const game::gui::DiskSource files(options.data / "Interface");
    game::gui::GuiSources sources;
    sources.files = &files;
    auto loader = game::gui::GuiLoader::open(sources);
    if (!loader) {
        std::cerr << loader.error() << '\n';
        return 1;
    }
    game::ui::script::GuiScreen screen(*loader);
    const auto begin = std::chrono::steady_clock::now();
    game::ui::script::HostDesc desc;
    desc.data_root = options.data;
    game::ui::script::Context script_context;
    desc.natives = [&script_context](lua_State* lua) {
        game::ui::script::open_natives(lua);
        game::ui::script::native::attach(lua, script_context);
        game::ui::script::open_widget_classes(lua, game::ui::script::Missing::kRecord);
    };
    auto opened = Host::open(desc, screen);
    if (!opened) {
        std::cerr << opened.error() << '\n';
        return 1;
    }
    Host& host = *opened;
    const auto opened_at = std::chrono::steady_clock::now();
    Tally tally;
    drain(host, "(mở)", tally);
    std::uint32_t events = 0;
    for (const game::ui::script::WindowDef& window : *windows) {
        static_cast<void>(host.set_shown(window.name, true));
        drain(host, window.name, tally);
        if (options.is_events) {
            const std::vector<game::ui::script::Registration> registered(host.registrations(window.name).begin(),
                host.registrations(window.name).end());
            for (const game::ui::script::Registration& one : registered) {
                host.post(one.name, {});
                ++events;
            }
            drain(host, window.name, tally);
            static_cast<void>(host.take_calls());
        }
        static_cast<void>(host.set_shown(window.name, false));
        drain(host, window.name, tally);
        static_cast<void>(host.take_calls());
    }
    const auto done = std::chrono::steady_clock::now();
    const auto millis = [](auto from, auto to) { return std::chrono::duration_cast<std::chrono::milliseconds>(to - from).count(); };
    std::ofstream file;
    if (!options.out.empty()) file.open(options.out, std::ios::binary);
    std::ostream& out = options.out.empty() ? std::cout : file;
    out << std::format("# {} cửa sổ, mở {} ms, hiện/giấu {}{} ms\n", host.window_count(), millis(begin, opened_at),
        options.is_events ? std::format("và {} sự kiện ", events) : std::string(), millis(opened_at, done));
    out << std::format("# bộ nhớ Lua {} KB\n", lua_getgccount(host.lua()));
    out << "# số lần\tloại và tên\tcửa sổ đầu tiên\n";
    tally.print(out);
    out << "# phương thức widget còn thiếu (số lần gọi, tên)\n";
    for (const game::ui::script::MissingMethod& method : game::ui::script::missing_methods(host.lua()))
        out << std::format("{}\t{}\n", method.calls, method.name);
    return 0;
}
