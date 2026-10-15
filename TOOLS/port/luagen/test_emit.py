# Test của bộ phát C++ (emit.py) và bộ sinh (generate.py). Chỉ ca mà sai thì mã sinh hỏng thầm: literal số và chuỗi,
# thứ tự đánh giá theo lparser.c 5.0.1, chia chunk vào các tệp, viết-nếu-đổi. Việc mã sinh biên dịch sạch và chạy đúng
# do cổng check.py và bộ đối soát hàng loạt (thienlong_lua_mass) bảo đảm, không lặp lại ở đây.
# Chạy: python -B -m unittest discover -s TOOLS/port/luagen -p "test_emit.py"
from __future__ import annotations

import math
import os
import pathlib
import re
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))

from luagen import generate, mass_units  # noqa: E402
from luagen.emit import (  # noqa: E402
    LFIELDS_PER_FLUSH,
    NESTED_IF_LIMIT,
    EmitError,
    emit_chunk,
    number_literal,
    string_view_literal,
)
from luagen.parser import parse  # noqa: E402


def emit(source: str, prefix: str = "c0") -> str:
    return emit_chunk(parse(source.encode("utf-8"), "t"), prefix).body


class LiteralTests(unittest.TestCase):
    def test_numbers_round_trip_exactly(self) -> None:
        for value in (0.1, 1e300, 5e-324, 123456789.123, 2.0**53, 2.0**53 + 2.0, 1.0 / 3.0):
            text = number_literal(value)
            self.assertEqual(float.fromhex(text) if text.startswith("0x") else float(text), value, text)

    def test_integers_and_zero_are_plain(self) -> None:
        self.assertEqual(number_literal(3.0), "3.0")
        self.assertEqual(number_literal(-7.0), "-7.0")
        self.assertEqual(number_literal(0.0), "0.0")

    def test_non_finite(self) -> None:
        self.assertIn("infinity", number_literal(math.inf))
        self.assertTrue(number_literal(-math.inf).startswith("-"))
        self.assertIn("quiet_NaN", number_literal(math.nan))

    def test_string_view_has_explicit_length_with_nul_and_utf8(self) -> None:
        self.assertEqual(string_view_literal(b"a\0b"), 'std::string_view("a\\000b", 3)')
        self.assertTrue(string_view_literal("é".encode()).endswith(", 2)"))

    def test_string_view_never_forms_trigraph_or_bad_escape(self) -> None:
        text = string_view_literal(b'??= "\\ \n\r\t?')
        self.assertNotIn("??=", text)
        self.assertEqual(text.count('"') - text.count('\\"'), 2)

    def test_long_string_is_split_into_pieces(self) -> None:
        # MSVC từ chối chuỗi quá 16 KB: chuỗi dài phải thành nhiều đoạn kề nhau, độ dài tổng vẫn đúng.
        text = string_view_literal(b"x" * 20000)
        self.assertGreater(text.count('"'), 4)
        self.assertTrue(text.endswith(", 20000)"))


class EvaluationOrderTests(unittest.TestCase):
    def test_every_fallible_operation_is_followed_by_a_failure_check(self) -> None:
        text = emit("x = a.b + f(c)")
        lines = [line.strip() for line in text.splitlines()]
        for index, line in enumerate(lines):
            if line.startswith(("const Value t", "const Results r", "const bool t")) and "(L," in line:
                self.assertEqual(lines[index + 1], "if (failed(L)) return {};", line)

    def test_loop_heads_tick(self) -> None:
        for source in ("while x do end", "repeat until x", "for i = 1, 2 do end", "for k, v in t do end"):
            self.assertIn("if (!tick(L)) return {};", emit(source), source)

    def test_method_object_is_evaluated_before_arguments(self) -> None:
        text = emit("o:m(f())")
        self.assertLess(text.index("method_of"), text.index("get_global(L, self.constant(2))"))

    def test_multi_value_call_only_expands_in_last_position(self) -> None:
        text = emit("x = {f(), g()}")
        self.assertEqual(text.count("append("), 1)

    def test_greater_than_swaps_operands_like_lua(self) -> None:
        # a > b là less(b, a): thứ tự đánh giá vẫn a trước b, chỉ lời gọi so sánh đổi chỗ.
        text = emit("local a, b = 1, 2 x = a > b")
        self.assertIn("less(L, l1_b, l0_a)", text.replace("Value::number", "").replace("  ", " "))

    def test_table_size_hints_count_only_named_record_items(self) -> None:
        # lparser.c recfield chỉ tăng nh ở nhánh TK_NAME; `[khoá] = v` không đếm, làm thế sẽ lệch thứ tự pairs (đo trên DLL).
        self.assertIn("new_table(L, 2, 2)", emit('x = {n = 1, "x", "y", z = 2, [10] = 3, [2.5] = 4}'))
        self.assertIn("new_table(L, 1, 0)", emit("x = {f()}"))

    def test_table_constructor_flushes_every_32_items(self) -> None:
        items = ", ".join(str(index) for index in range(LFIELDS_PER_FLUSH * 2 + 1))
        self.assertEqual(emit(f"x = {{{items}}}").count("set_list("), 3)

    def test_long_elseif_chain_does_not_nest(self) -> None:
        # Hồi quy C1061 của MSVC (giới hạn 128 khối lồng): script giao diện có chuỗi elseif hàng trăm nhánh. Mã sinh phải
        # phẳng, không `else if`, và mỗi nhánh đúng một lần chạy-nếu-được-chọn.
        count = max(NESTED_IF_LIMIT * 40, 300)
        branches = "".join(f" elseif x == {index} then y = {index}" for index in range(count))
        text = emit("if x == -1 then y = -1" + branches + " else y = 0 end")
        self.assertNotIn("else if", text)
        depth = peak = 0
        for character in text:
            if character == "{":
                depth += 1
                peak = max(peak, depth)
            elif character == "}":
                depth -= 1
        self.assertLess(peak, 16)
        self.assertEqual(len(re.findall(r"if \(s0 == [1-9][0-9]*\) \{", text)), count + 1)


class ConstantFoldingTests(unittest.TestCase):
    # Clang -Werror (-Wunreachable-code, -Wself-assign-overloaded) từ chối ba dạng mã mà script giao diện có thật.
    def test_true_test_makes_following_code_dead_and_is_not_emitted(self) -> None:
        text = emit("function f() if true then return 1 end g() end")
        self.assertNotIn("if (true)", text)
        self.assertNotIn('std::string_view("g", 1)', text)

    def test_false_test_drops_the_branch(self) -> None:
        text = emit("if false then a() elseif nil then b() else c() end")
        self.assertNotIn('std::string_view("a", 1)', text)
        self.assertNotIn('std::string_view("b", 1)', text)
        self.assertIn('std::string_view("c", 1)', text)

    def test_branches_after_a_true_test_are_cut(self) -> None:
        text = emit("if x then a() elseif 1 then b() elseif y then c() else d() end")
        self.assertIn('std::string_view("b", 1)', text)
        self.assertNotIn('std::string_view("c", 1)', text)
        self.assertNotIn('std::string_view("d", 1)', text)

    def test_not_of_constant_is_constant(self) -> None:
        self.assertNotIn('std::string_view("a", 1)', emit("if not 1 then a() end"))

    def test_runtime_conditions_are_kept(self) -> None:
        text = emit("if x then a() end")
        self.assertIn("truthy()", text)

    def test_code_after_break_or_return_in_nested_blocks_is_dropped(self) -> None:
        text = emit("while x do do break end a() end")
        self.assertNotIn('std::string_view("a", 1)', text)

    def test_long_chain_of_returns_keeps_the_final_return(self) -> None:
        # Chuỗi dài phát dạng bộ chọn nên trình dịch không chứng minh nó đầy đủ: thiếu `return {};` cuối thì -Wreturn-type.
        branches = "".join(f" elseif x == {index} then return {index}" for index in range(NESTED_IF_LIMIT + 2))
        text = emit("function f() if x == -1 then return -1" + branches + " else return 0 end end")
        body = re.search(r"Results c0_f1\([^;]*?\{\n(.*?)\n\}\n", text, re.S)
        assert body is not None
        self.assertEqual(body.group(1).splitlines()[-1], "  return {};")

    def test_identical_branches_run_the_body_once_after_the_condition(self) -> None:
        # bugprone-branch-clone từ chối `if (c) { B } else { B }`; điều kiện vẫn được tính vì có thể có tác dụng phụ hay lỗi.
        text = emit("if f(x) then y = 1 else y = 1 end")
        self.assertNotIn("else", text)
        self.assertEqual(text.count("set_global("), 1)
        self.assertIn("static_cast<void>(", text)

    def test_different_branches_keep_if_else(self) -> None:
        text = emit("if x then y = 1 else y = 2 end")
        self.assertIn("} else {", text)
        self.assertEqual(text.count("set_global("), 2)

    def test_names_never_contain_double_underscore_or_simple_escapes(self) -> None:
        text = emit('local _txt, a__b, __ = 1, 2, 3 x = _txt .. a__b .. __ .. "a\\\\b\\"c\\n"')
        self.assertNotIn("__", text)
        self.assertNotIn('\\"', text)
        self.assertNotIn("\\n", text)
        self.assertNotIn("\\\\", text)

    def test_empty_string_is_default_constructed_view(self) -> None:
        self.assertEqual(string_view_literal(b""), "std::string_view{}")

    def test_self_assignment_of_a_local_emits_nothing(self) -> None:
        text = emit("local x = f() x = x")
        self.assertNotIn("l0_x = l0_x", text)
        self.assertNotIn("->value = l0_x->value", text)


class ContinueTests(unittest.TestCase):
    def test_continue_with_captured_loop_local_is_refused(self) -> None:
        # LuaPlus không đóng upvalue ở `continue` nên closure dùng chung ô giữa các lượt; bộ phát từ chối thay vì phát sai.
        source = "for i = 1, 3 do local x = i f = function() return x end continue end"
        with self.assertRaises(EmitError):
            emit(source)

    def test_continue_without_captured_locals_is_accepted(self) -> None:
        self.assertIn("continue;", emit("for i = 1, 3 do local x = i if x then continue end end"))


class GeneratorTests(unittest.TestCase):
    def test_every_unit_lands_in_exactly_one_bucket_in_order(self) -> None:
        units = [
            generate.UnitRecord(f"n{index}", f"u{index}", [generate.translate("x = 1", f"n{index}", f"c{index}")])
            for index in range(37)
        ]
        buckets = generate.assign_buckets(units, 8)
        self.assertEqual(len(buckets), 8)
        flat = [unit.name for bucket in buckets for unit in bucket]
        self.assertEqual(flat, [unit.name for unit in units])

    def test_syntax_error_chunk_is_kept_with_message(self) -> None:
        record = generate.translate("();", "bad", "c0")
        self.assertIsNone(record.output)
        text = generate.chunk_initializer(record)
        self.assertIn(".main = nullptr", text)
        self.assertIn("bad", text)

    def test_unit_array_is_constant_initialised_and_may_be_empty(self) -> None:
        unit = generate.UnitRecord("u", "u3", [generate.translate("x = 1", "t", "c0"), generate.translate("();", "bad", "c1")])
        text = generate.unit_definition(unit)
        self.assertIn("extern const std::array<Chunk, 2> u3;", text)
        self.assertEqual(text.count("Chunk{.name"), 2)
        self.assertIn("const std::array<Chunk, 0> u4{};", generate.unit_definition(generate.UnitRecord("e", "u4", [])))

    def test_empty_bucket_still_writes_a_file(self) -> None:
        self.assertIn("Không có đơn vị", generate.translation_unit([]))

    def test_write_if_changed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "a" / "x.cpp"
            self.assertTrue(generate.write_if_changed(path, "một"))
            stamp = path.stat().st_mtime_ns
            self.assertFalse(generate.write_if_changed(path, "một"))
            self.assertEqual(path.stat().st_mtime_ns, stamp)
            self.assertTrue(generate.write_if_changed(path, "hai"))

    def test_run_is_deterministic_and_keeps_unit_order(self) -> None:
        # Layout là dữ liệu gitignore: worktree đưa thư mục của cây chính qua biến môi trường LUAGEN_LAYOUT_ROOT.
        layout_root = pathlib.Path(os.environ.get("LUAGEN_LAYOUT_ROOT", mass_units.LAYOUT_ROOT))
        if not layout_root.is_dir():
            self.skipTest("không có layout Interface (đặt LUAGEN_LAYOUT_ROOT)")
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            generate.run(pathlib.Path(first), 4, {"ProgressBar"}, layout_root)
            stats = generate.run(pathlib.Path(second), 4, {"ProgressBar"}, layout_root)
            self.assertGreater(stats["cpp_lines"], 0)
            names = sorted(path.name for path in pathlib.Path(first).iterdir())
            self.assertEqual(names, ["tu_000.cpp", "tu_001.cpp", "tu_002.cpp", "tu_003.cpp", "units.cpp", "units.hpp"])
            for name in names:
                self.assertEqual((pathlib.Path(first) / name).read_bytes(), (pathlib.Path(second) / name).read_bytes(), name)
            registry = (pathlib.Path(first) / "units.cpp").read_text(encoding="utf-8")
            self.assertIn('std::string_view("ProgressBar", 11)', registry)
            self.assertIn("world()", registry)


if __name__ == "__main__":
    unittest.main()
