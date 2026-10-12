// Số vàng của collision_tests (DE-BAI DH đợt 1, mục 4), đọc đúng so-do/b-dinh-dang-tsv.md của B (sha256 aceeed42…):
// mọi collision_get_*.tsv trong tests/golden (CMake đặt GAME_COLLISION_GOLDEN); lớp new chỉ để kiểm OPCODE, không đọc.
// Cách đọc chọn theo chữ đầu của dòng dữ liệu đầu tiên (L 15:17): "file"/"o2"/"o3" là bảng get ở đây, "bd" là số vàng
// biến đổi V-2 (tests/collision_bien_doi.hpp), chữ khác là lỗi dữ liệu (main trả 2); trong bảng get, dòng có chữ đầu
// khác "#", "file", "o2", "o3" cũng là lỗi dữ liệu.
// Dòng "#" là chú thích, dòng "#" thứ hai là "# nạp True|False; N đỉnh; …". Ô cách nhau bằng TAB: "file<TAB><hex cả
// tệp>" (chỉ tệp ≤ 64 KB); "o2 x z y" (4 cột, "-" ở cột 4 là trượt, có thể kèm 1 ô: 5 cột); "o3 ox oy oz dx dy dz px
// py pz" (hướng chưa chuẩn hoá; trúng 10 cột, "-" ở cột 8 là trượt: 8 cột, hay 11 cột kèm 3 ô). Số thực là 8 chữ số
// hex thường của bit float32 big-endian, chỉ so bit. Gốc không ghi out khi trượt (L chốt) nên port trả nullopt; test
// không mô phỏng giá trị canh. Thứ tự dò byte nguồn (find_source): dòng "file", rồi GAME_CLIENT_DATA/Scene/<cảnh>
// .WCollision, rồi GAME_RAW_SCENE/<cảnh>.WCollision (CMake đặt GAME_COLLISION_SCENE), không có gì thì trả 77; riêng
// lingxingfeng và xihu_Valentine đọc GAME_CLIENT_DATA rồi GAME_RAW_SCENE trước; hai tệp tuve chỉ có dòng "file"; in
// nguồn mỗi cảnh. Chưa có Model vẫn làm thật: phân tích TSV, giải hex, parse_building_file rồi so với "nạp"; phần
// height và raycast chờ Model (main trả 77). Header Model chưa có tên trong docs/VA-CHAM-2026.md ("API port C chốt");
// test chờ "collision/model.hpp".
#pragma once

#include "collision/building_file.hpp"
#include "collision_report.hpp"
#include "test.hpp"

#if __has_include("collision/model.hpp")
#include "collision/model.hpp"
#endif

#include <algorithm>
#include <array>
#include <bit>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <functional>
#include <ios>
#include <iterator>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

namespace game::test::golden {

#if defined(GAME_COLLISION_GOLDEN)
inline constexpr std::string_view kGoldenDir = GAME_COLLISION_GOLDEN;
#else
inline constexpr std::string_view kGoldenDir;
#endif
#if defined(GAME_CLIENT_DATA)
inline constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
inline constexpr std::string_view kClientData;
#endif
#if defined(GAME_COLLISION_SCENE)
inline constexpr std::string_view kRawScene = GAME_COLLISION_SCENE;
#else
inline constexpr std::string_view kRawScene;
#endif

inline constexpr std::string_view kProgram = "collision_tests";
inline constexpr std::array<std::string_view, 2> kClientScenes{"lingxingfeng", "xihu_Valentine"};

enum class Kind : std::uint8_t { kHeight, kRay };

// Một truy vấn: line là số dòng trong TSV (từ 1), index là thứ tự trong loại (tia thứ mấy, từ 0).
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
    if (!query.hit) return std::nullopt;
    if (query.kind == Kind::kHeight) return std::array{query.output[0], 0U, 0U};
    return query.output;
}

[[nodiscard]] inline std::string answer_text(const Answer& answer, Kind kind) {
    if (!answer) return "trượt";
    if (kind == Kind::kHeight) return word_text((*answer)[0]);
    return word_text((*answer)[0]) + " " + word_text((*answer)[1]) + " " + word_text((*answer)[2]);
}

// Một dòng lệch: tệp TSV, số dòng, loại và chỉ số truy vấn, mong đợi và nhận được (hex và thập phân).
inline void report_mismatch(const Table& table, const Query& query, const Answer& wanted, const Answer& got) {
    const std::string kind = query.kind == Kind::kHeight ? "o2 (height) #" : "o3 (raycast) #";
    const std::string where = "dòng " + std::to_string(query.line) + ", " + kind + std::to_string(query.index);
    const std::string expected = ": mong đợi " + answer_text(wanted, query.kind);
    say(kProgram, table.name, where + expected + ", nhận " + answer_text(got, query.kind));
}

// 1 nếu truy vấn lệch số vàng (đã in dòng lệch), 0 nếu trùng từng bit.
[[nodiscard]] inline std::size_t mismatch(const collision::Model& model, const Table& table, const Query& query) {
    const Answer got = ask(model, query);
    const Answer wanted = wanted_answer(query);
    if (got == wanted) return 0;
    report_mismatch(table, query, wanted, got);
    return 1;
}

[[nodiscard]] inline std::size_t compare_table(const collision::Model& model, const Table& table) {
    std::size_t differ = 0;
    for (const Query& query : table.queries) {
        differ += mismatch(model, table, query);
    }
    return differ;
}

struct Compared {
    std::size_t rows = 0;
    std::size_t differ = 0;
};

inline void compare_one(Context& context, const Table& table, Compared& compared) {
    const Source source = find_source(table);
    if (!source.bytes) {
        say_skipped(kProgram, table.name, "bỏ qua, thiếu byte nguồn (dòng file, GAME_CLIENT_DATA, GAME_RAW_SCENE)");
        return;
    }
    const auto model = collision::load(*source.bytes);
    context.expect(model.has_value() == table.loaded.value_or(true), "Model nạp đúng như DLL");
    if (!model) return;
    compared.rows += table.queries.size();
    compared.differ += compare_table(*model, table);
}

inline void compare_with_model(Context& context, std::span<const Table> tables) {
    Compared compared;
    for (const Table& table : tables) {
        compare_one(context, table, compared);
    }
    context.expect(compared.differ == 0, "height và raycast trùng từng bit số vàng");
    const std::string rows = "đã so " + std::to_string(compared.rows) + " dòng, lệch ";
    say(kProgram, "golden_files_match", rows + std::to_string(compared.differ));
}

[[nodiscard]] inline std::vector<Answer> answer_all(const collision::Model& model, const Table& table) {
    std::vector<Answer> answers;
    answers.reserve(table.queries.size());
    for (const Query& query : table.queries) {
        answers.push_back(ask(model, query));
    }
    return answers;
}

inline constexpr std::size_t kThreads = 4;
using Answers = std::array<std::vector<Answer>, kThreads>;

inline void answer_into(const collision::Model& model, const Table& table, std::vector<Answer>& out) {
    out = answer_all(model, table);
}

// Bốn jthread cùng hỏi một Model const; xoá vector luồng là join.
[[nodiscard]] inline Answers answer_in_threads(const collision::Model& model, const Table& table) {
    Answers results;
    std::vector<std::jthread> workers;
    workers.reserve(kThreads);
    for (std::vector<Answer>& out : results) {
        workers.emplace_back(answer_into, std::cref(model), std::cref(table), std::ref(out));
    }
    workers.clear();
    return results;
}

[[nodiscard]] inline bool loads_embedded(const Table& table) noexcept {
    return !table.embedded.empty() && table.loaded.value_or(false);
}

// Bảng đầu tiên có dòng "file" và DLL nạp được: kết quả mỗi luồng trùng từng bit bản một luồng.
inline void threads_match_one_thread(Context& context) {
    const std::vector<Table> tables = read_tables();
    const auto usable = std::ranges::find_if(tables, loads_embedded);
    if (usable == tables.end()) {
        say_skipped(kProgram, "threads_match_one_thread", "bỏ qua, chưa có bảng nào có dòng file");
        return;
    }
    const auto model = collision::load(usable->embedded);
    context.expect(model.has_value(), "Model nạp được tệp nguồn");
    if (!model) return;
    const std::vector<Answer> single = answer_all(*model, *usable);
    for (const std::vector<Answer>& result : answer_in_threads(*model, *usable)) {
        context.expect(result == single, "kết quả nhiều luồng trùng một luồng");
    }
    say(kProgram, "threads_match_one_thread", std::to_string(kThreads) + " luồng trên " + usable->name);
}

#else

inline void compare_with_model(Context&, std::span<const Table>) noexcept {
    say_skipped(kProgram, "golden_files_match", "chờ Model của C: chưa so height và raycast");
}

inline void threads_match_one_thread(Context&) noexcept {
    say_skipped(kProgram, "threads_match_one_thread", "chờ Model của C");
}

#endif

[[nodiscard]] inline bool names_drawn_table(const Table& table) noexcept {
    return is_drawn_table(table.name);
}

// Đọc và tự kiểm mọi bảng (chạy cả khi chưa có Model), rồi so với Model nếu có.
inline void golden_files_match(Context& context) {
    if (kGoldenDir.empty()) {
        say_skipped(kProgram, "golden_files_match", "bỏ qua, thiếu GAME_COLLISION_GOLDEN");
        return;
    }
    for (const std::filesystem::path& path : golden_paths()) {
        report_if_strange(path);
    }
    const std::vector<Table> tables = read_tables();
    std::size_t lines = 0;
    std::size_t queries = 0;
    Sources sources{};
    for (const Table& table : tables) {
        check_table(context, table, sources);
        lines += table.lines;
        queries += table.queries.size();
    }
    const auto drawn = static_cast<std::size_t>(std::ranges::count_if(tables, names_drawn_table));
    const std::string read = "đã phân tích " + std::to_string(lines) + " dòng TSV (" + std::to_string(queries);
    const std::string files = " truy vấn) trong " + std::to_string(tables.size()) + " tệp get, ";
    say(kProgram, "golden_files_match", read + files + std::to_string(drawn) + " tệp tự vẽ");
    const std::string loads = "byte nguồn: " + std::to_string(sources[1]) + " dòng file, " + std::to_string(sources[2]);
    const std::string scene = " GAME_CLIENT_DATA, " + std::to_string(sources[3]) + " GAME_RAW_SCENE, thiếu ";
    say(kProgram, "golden_files_match", loads + scene + std::to_string(sources[0]));
    if (drawn == 0) say_skipped(kProgram, "golden_files_match", "chưa có số vàng tệp tự vẽ có nhúng tệp (B)");
    compare_with_model(context, tables);
}

} // namespace game::test::golden
