"""Trích toàn bộ dữ liệu phân tích của Game.exe 2026 ra docs/TAILIEU/GAME-EXE-2026 từ một phiên REA (Ghidra).

Dòng chảy (README.md trong docs/TAILIEU/GAME-EXE-2026 ghi lệnh đầy đủ):
  1. rea_server.mjs giữ phiên; rea_bulk.mjs plan_a.json (mở, danh sách hàm/tên/chuỗi, đoạn, tài nguyên, xuất bundle).
  2. game_exe_dump.py core      -> sinh plan_vt, plan_callees_*, plan_xrefs_*, plan_dec_* trong <work>/plans.
  3. rea_bulk.mjs trên các plan đó; game_exe_dump.py hier -> sinh plan_hb, plan_hc; rea_bulk.mjs hai plan này.
  4. game_exe_dump.py assemble  -> ghi các bảng vào docs/TAILIEU/GAME-EXE-2026 (nếu còn hàm decompile hỏng thì sinh plan_dec_retry
     rồi dừng với mã 3; chạy plan đó và assemble lại).

Mọi quan hệ "chuỗi/xref -> hàm" suy bằng bisect trên địa chỉ vào hàm gần nhất phía trước: gần đúng ở chỗ Ghidra để dữ liệu
(bảng nhảy) xen giữa hai hàm; chỗ nào chính xác hơn (trace_feature của REA) thì README nói rõ.
"""

from __future__ import annotations

import argparse
import bisect
import collections
import json
import os
import re
import struct
import sys
import zipfile
from pathlib import Path

IMAGE_BASE = 0x140000000
REPO = Path(__file__).resolve().parents[3]
OUT_DIR = REPO / "docs" / "TAILIEU" / "GAME-EXE-2026"
WORK = Path(os.environ.get("REA_WORK", "D:/rea/work"))
PLANS = WORK / "plans"
BULK = WORK / "out"

NOISE_PREFIXES = (
    "LAB_", "UNWIND_", "Unwind", "IPToStateMapEntry_", "UnwindMapEntry_", "HandlerType_", "TryBlockMapEntry_",
    "switchD_", "s_", "Catch_", "FUN_", "thunk_FUN_", "EXTERNAL:",
)
DATA_EXT = re.compile(r"\.(txt|tab|ini|xml|lua|skill|mesh|scene|material|particle|anim|skeleton|layout|imageset|looknfeel|scheme|cfg|csv|dat|bin|track|png|wav|dds|tga)$", re.I)


def esc(text: str) -> str:
    return text.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n").replace("\r", "\\r")


def hexa(value: int) -> str:
    return f"0x{value:x}"


def load_json(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def dump_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, ensure_ascii=False)


def write_tsv(path: Path, header: list[str], rows) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("\t".join(header) + "\n")
        for row in rows:
            handle.write("\t".join(str(cell) for cell in row) + "\n")
            count += 1
    return count


def bulk(name: str) -> list[dict]:
    return load_json(BULK / f"{name}.bulk.json")


def bulk_parts(prefix: str) -> list[dict]:
    items: list[dict] = []
    numbered = [(int(m.group(1)), p) for p in BULK.glob(f"{prefix}_*.bulk.json") if (m := re.fullmatch(rf"{prefix}_(\d+)\.bulk\.json", p.name))]
    for _, path in sorted(numbered):
        items.extend(load_json(path))
    return items


def write_plans(prefix: str, jobs: list[dict], part_size: int) -> int:
    parts = [jobs[i:i + part_size] for i in range(0, len(jobs), part_size)] or [[]]
    for index, part in enumerate(parts):
        dump_json(PLANS / f"{prefix}_{index}.json", part)
    return len(parts)


# --- đọc bundle ---------------------------------------------------------------------------------------------------

def read_bundle() -> dict[str, object]:
    records = load_json(WORK / "bundle_full.json")["records"]
    found: dict[str, object] = {}
    for record in records:
        evidence = record.get("evidence", record)
        found[evidence["operation"]] = evidence["normalized_result"]
    for need in ("list_procedures", "list_names", "list_strings"):
        if need not in found:
            raise SystemExit(f"bundle_full.json thiếu bằng chứng {need}; chạy lại plan_a")
    return found


def classify(procedure: dict, name: str) -> str:
    info = procedure.get("procedure", {})
    if info.get("external"):
        return "external"
    if info.get("thunk"):
        return "thunk"
    return "internal"


def build_core(found) -> dict:
    functions = []
    for entry in found["list_procedures"]:
        info = entry.get("procedure", {})
        functions.append({
            "a": entry["address"], "n": entry["value"], "k": classify(entry, entry["value"]),
            "t": info.get("thunk_target"),
        })
    names = [(n["address"], n["value"]) for n in found["list_names"]]
    strings = [(s["address"], s["value"]) for s in found["list_strings"]]
    return {"functions": functions, "names": names, "strings": strings}


def class_labels(names) -> dict[str, dict[str, str]]:
    classes: dict[str, dict[str, str]] = collections.defaultdict(dict)
    for address, value in names:
        for suffix, key in (("::vftable", "vftable"), ("::RTTI_Class_Hierarchy_Descriptor", "chd"),
                            ("::RTTI_Complete_Object_Locator", "col"), ("::RTTI_Type_Descriptor", "td")):
            if value.endswith(suffix):
                classes[value[: -len(suffix)]].setdefault(key, address)
    return classes


# --- stage core -----------------------------------------------------------------------------------------------------

def stage_core(_args) -> None:
    found = read_bundle()
    core = build_core(found)
    dump_json(WORK / "core.json", core)
    PLANS.mkdir(parents=True, exist_ok=True)
    classes = class_labels(core["names"])
    vt_jobs = []
    for cls, labels in sorted(classes.items()):
        if "vftable" in labels:
            vt_jobs.append({"name": f"vt|{cls}", "tool": "read_bytes", "args": {"address": labels["vftable"], "length": 1024}})
        if "chd" in labels:
            vt_jobs.append({"name": f"chd|{cls}", "tool": "read_bytes", "args": {"address": labels["chd"], "length": 16}})
    dump_json(PLANS / "plan_vt.json", vt_jobs)
    internal = [f["a"] for f in core["functions"] if f["k"] != "external"]
    callees = [{"name": a, "tool": "procedure_callees", "args": {"procedure": a}} for a in internal]
    xrefs = [{"name": a, "tool": "xrefs", "args": {"address": a}} for a, _ in core["strings"]]
    chunks = [internal[i:i + 25] for i in range(0, len(internal), 25)]
    decomp = [{"name": f"dec{i}", "tool": "batch_decompile", "args": {"addresses": c}} for i, c in enumerate(chunks)]
    counts = {
        "callees": write_plans("plan_callees", callees, 15000), "xrefs": write_plans("plan_xrefs", xrefs, 15000),
        "dec": write_plans("plan_dec", decomp, 400),
    }
    print(f"hàm {len(core['functions'])} (nội bộ {len(internal)}), tên {len(core['names'])}, chuỗi {len(core['strings'])}, "
          f"lớp có vftable {sum(1 for l in classes.values() if 'vftable' in l)}; số phần plan {counts}")


# --- stage hier -----------------------------------------------------------------------------------------------------

def stage_hier(_args) -> None:
    rows = bulk("plan_vt")
    base_jobs = []
    seen = set()
    chd: dict[str, tuple[int, int, int, int]] = {}
    for row in rows:
        if not row["name"].startswith("chd|") or not row["ok"]:
            continue
        raw = bytes.fromhex(row["result"]["bytes_hex"])
        signature, attributes, count, array_rva = struct.unpack("<IIII", raw[:16])
        cls = row["name"][4:]
        chd[cls] = (signature, attributes, count, array_rva)
        if count and 0 < count < 256 and array_rva not in seen:
            seen.add(array_rva)
            base_jobs.append({"name": f"hb|{array_rva}", "tool": "read_bytes", "args": {"address": hexa(IMAGE_BASE + array_rva), "length": 4 * count}})
    dump_json(WORK / "chd.json", chd)
    dump_json(PLANS / "plan_hb.json", base_jobs)
    print("mảng lớp cơ sở cần đọc:", len(base_jobs), "cho", len(chd), "lớp")


def stage_hier2(_args) -> None:
    rows = bulk("plan_hb")
    descriptors = set()
    arrays: dict[int, list[int]] = {}
    for row in rows:
        if not row["ok"]:
            continue
        raw = bytes.fromhex(row["result"]["bytes_hex"])
        rvas = list(struct.unpack("<" + "I" * (len(raw) // 4), raw))
        arrays[int(row["name"][3:])] = rvas
        descriptors.update(rvas)
    dump_json(WORK / "bases.json", {str(k): v for k, v in arrays.items()})
    jobs = [{"name": f"hc|{rva}", "tool": "read_bytes", "args": {"address": hexa(IMAGE_BASE + rva), "length": 28}} for rva in sorted(descriptors)]
    dump_json(PLANS / "plan_hc.json", jobs)
    print("bộ mô tả lớp cơ sở cần đọc:", len(jobs))


# --- stage assemble ---------------------------------------------------------------------------------------------------

def demangle(value: str) -> str:
    match = re.fullmatch(r"\.\?A[VU](.+)@@", value)
    if not match or "?$" in value:
        return value
    return "::".join(reversed(match.group(1).split("@")))


def pseudocode_map(failed_out: list[str]) -> dict[str, tuple[str, str]]:
    code: dict[str, tuple[str, str]] = {}
    parts = bulk_parts("plan_dec")
    retry = BULK / "plan_dec_retry.bulk.json"
    if retry.exists():
        parts.extend(load_json(retry))
    for row in parts:
        result = row["result"]
        if not row["ok"] or not isinstance(result, dict):
            continue
        for item in result["items"]:
            if item.get("status") == "ok" and item.get("pseudocode") is not None:
                code[item["address"]] = (item["procedure"].get("name", ""), item["pseudocode"].replace("\r\n", "\n").strip("\n"))
    internal = [f["a"] for f in load_json(WORK / "core.json")["functions"] if f["k"] != "external"]
    failed_out.extend(a for a in internal if a not in code)
    return code


def stage_assemble(_args) -> None:
    core = load_json(WORK / "core.json")
    functions = core["functions"]
    by_addr = {f["a"]: f for f in functions}
    names = core["names"]
    strings = core["strings"]
    internal = sorted((int(f["a"], 16), f["a"]) for f in functions if f["k"] != "external")
    entries = [value for value, _ in internal]
    entry_text = [text for _, text in internal]

    def containing(address_text: str) -> str:
        value = int(address_text, 16)
        index = bisect.bisect_right(entries, value) - 1
        return entry_text[index] if index >= 0 else ""

    failed: list[str] = []
    code = pseudocode_map(failed)
    if failed:
        retry_jobs = [{"name": f"retry{i}", "tool": "batch_decompile", "args": {"addresses": [a]}} for i, a in enumerate(failed)]
        dump_json(PLANS / "plan_dec_retry.json", retry_jobs)
        if not (BULK / "plan_dec_retry.bulk.json").exists():
            print(f"{len(failed)} hàm chưa có pseudo-code; chạy rea_bulk.mjs plans/plan_dec_retry.json rồi assemble lại")
            raise SystemExit(3)
        # Decompiler của Ghidra bỏ cuộc ở những hàm cực lớn (bản đo: 5 hàm, 6 đến 34 nghìn lệnh, sau 72 đến 296 giây); lưu bản
        # disassembly của chúng thay cho pseudo-code, lấy bằng read_function_instructions (plan_disasm.json, tên việc = địa chỉ).
        disasm_path = BULK / "plan_disasm.bulk.json"
        if not disasm_path.exists():
            dump_json(PLANS / "plan_disasm.json", [{"name": a, "tool": "read_function_instructions", "args": {"procedure": a}} for a in failed])
            print(f"{len(failed)} hàm không decompile được; chạy rea_bulk.mjs plans/plan_disasm.json rồi assemble lại")
            raise SystemExit(3)
        (OUT_DIR / "disasm").mkdir(parents=True, exist_ok=True)
        disasm = {row["name"]: row for row in load_json(disasm_path)}
        for address in failed:
            row = disasm.get(address)
            if row is None or not row["ok"]:
                raise SystemExit(f"thiếu disassembly của {address}")
            lines = "\n".join(row["result"]["instructions"])
            (OUT_DIR / "disasm" / f"{address}.asm").write_text(f"; {address} {by_addr[address]['n']} — decompiler không hoàn tất\n{lines}\n", encoding="utf-8", newline="\n")
        (OUT_DIR / "decompile_missing.txt").write_text("\n".join(failed) + "\n", encoding="utf-8", newline="\n")
        print(f"{len(failed)} hàm không decompile được, đã lưu disassembly ở disasm/")

    # callgraph ----------------------------------------------------------------------------------------------------
    callees: dict[str, list[str]] = {}
    for row in bulk_parts("plan_callees"):
        if row["ok"] and isinstance(row["result"], list) and row["result"]:
            callees[row["name"]] = row["result"]
    caller_count: collections.Counter[str] = collections.Counter()
    for targets in callees.values():
        for target in set(targets):
            caller_count[target] += 1

    # chuỗi -> hàm tham chiếu -------------------------------------------------------------------------------------
    referrers: dict[str, list[str]] = {}
    for row in bulk_parts("plan_xrefs"):
        if row["ok"] and isinstance(row["result"], list):
            referrers[row["name"]] = sorted({containing(a) for a in row["result"] if a.startswith("0x")} - {""})
    string_value = dict(strings)

    # tệp nguồn ------------------------------------------------------------------------------------------------
    file_funcs: dict[str, set[str]] = collections.defaultdict(set)
    source_marker = re.compile(r"gamecode\\", re.I)
    for address, value in strings:
        found_marker = source_marker.search(value)
        if found_marker and value.lower().endswith((".cpp", ".h")):
            funcs = file_funcs[value[found_marker.end():]]
            funcs.update(referrers.get(address, []))
    ranges = {}
    for path, funcs in file_funcs.items():
        values = [int(f, 16) for f in funcs]
        ranges[path] = (min(values), max(values), len(funcs)) if values else (0, 0, 0)
    ordered = sorted(((p, r) for p, r in ranges.items() if r[2]), key=lambda kv: kv[1][0])
    overlap = sum(1 for (_, a), (_, b) in zip(ordered, ordered[1:]) if b[0] <= a[1])
    starts = [r[0] for _, r in ordered]
    func_file: dict[str, str] = {}
    for _, address in internal:
        value = int(address, 16)
        index = bisect.bisect_right(starts, value) - 1
        if index >= 0 and ordered[index][1][0] <= value <= ordered[index][1][1]:
            func_file[address] = ordered[index][0]

    # lớp: vtable, cơ sở -------------------------------------------------------------------------------------------
    text_lo, text_hi = 0x140001000, 0x140a3a800
    slots_of: dict[str, list[int]] = {}
    for row in bulk("plan_vt"):
        if row["name"].startswith("vt|") and row["ok"]:
            raw = bytes.fromhex(row["result"]["bytes_hex"])
            slots = []
            for (pointer,) in struct.iter_unpack("<Q", raw[: len(raw) // 8 * 8]):
                if not text_lo <= pointer < text_hi:
                    break
                slots.append(pointer)
            slots_of[row["name"][3:]] = slots
    chd = load_json(WORK / "chd.json")
    arrays = {int(k): v for k, v in load_json(WORK / "bases.json").items()}
    td_name: dict[int, str] = {}
    for row in bulk("plan_hc"):
        if row["ok"]:
            raw = bytes.fromhex(row["result"]["bytes_hex"])
            td_rva = struct.unpack("<I", raw[:4])[0]
            text = string_value.get(hexa(IMAGE_BASE + td_rva + 0x10))
            td_name[int(row["name"][3:])] = demangle(text) if text else f"?td@{td_rva:#x}"
    bases_of: dict[str, list[str]] = {}
    for cls, (_sig, _attr, count, array_rva) in chd.items():
        bases_of[cls] = [td_name.get(rva, "?") for rva in arrays.get(array_rva, [])[1:]]
    labels = class_labels(names)

    # gói tin ----------------------------------------------------------------------------------------------------
    num = r"(0x[0-9a-fA-F]+|\d+)"
    read_call = re.compile(r"\w+\(param_2,\s*(?:param_1\s*\+\s*" + num + r"|param_1)\s*,\s*" + num + r"\)")
    ret_const = re.compile(r"\{\s*return\s+(0x[0-9a-fA-F]+|\d+);\s*\}")

    def const_of(address: int) -> int | None:
        entry = code.get(hexa(address))
        if not entry:
            return None
        match = ret_const.search(re.sub(r"\s+", " ", entry[1]))
        return int(match.group(1), 0) if match else None

    packet_rows = []
    for cls in sorted(c for c in slots_of if c.startswith("Packets::") and not c.endswith("Factory")):
        slots = slots_of[cls]
        if len(slots) < 6:
            continue
        read_code = code.get(hexa(slots[1]), ("", ""))[1]
        fields = [(int(m.group(1), 0) if m.group(1) else 0, int(m.group(2), 0)) for m in read_call.finditer(read_code)]
        branching = bool(re.search(r"\b(for|while|do|if|switch)\b", read_code))
        execute = by_addr.get(hexa(slots[3]), {})
        execute_target = execute.get("t") or (execute.get("n", "")[len("thunk_FUN_"):] if execute.get("n", "").startswith("thunk_FUN_") else "")
        execute_fn = execute_target if execute_target.startswith("0x") else (("0x" + execute_target) if execute_target else hexa(slots[3]))
        # empty = thân chỉ `return 1;`; flat = chuỗi gọi đọc tuần tự; branching = có if/for/while/switch (đọc pseudo-code trong
        # decompile.zip); delegated = chuyển cho hàm đọc của cấu trúc con; unparsed = không nhận ra lệnh đọc nào.
        if re.fullmatch(r"undefined\d* \w+\(void\)\s*\{\s*return 1;\s*\}", read_code.strip()):
            read_kind = "empty"
        elif branching:
            read_kind = "branching"
        elif fields:
            read_kind = "flat"
        elif re.search(r"\bFUN_[0-9a-f]+\(param_1 \+ 0x[0-9a-f]+\)", read_code):
            read_kind = "delegated"  # Read chỉ gọi hàm đọc của một cấu trúc con tại param_1 + offset
        else:
            read_kind = "unparsed"
        packet_rows.append((
            cls[len("Packets::"):], const_of(slots[4]), const_of(slots[5]), labels[cls]["vftable"], read_kind,
            len(fields), sum(size for _, size in fields), int(branching), hexa(slots[1]), hexa(slots[3]), execute_fn,
            func_file.get(execute_fn, ""), " ".join(f"{o:x}:{s}" for o, s in fields),
        ))
    packet_rows.sort(key=lambda r: (r[1] is None, r[1] if r[1] is not None else 0, r[0]))
    ids = [r[1] for r in packet_rows if r[1] is not None]
    duplicates = len(ids) - len(set(ids))

    # ghi các bảng -------------------------------------------------------------------------------------------------
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    slot_of: dict[str, str] = {}
    for cls, slots in slots_of.items():
        for index, pointer in enumerate(slots):
            slot_of.setdefault(hexa(pointer), f"{cls}#{index}")
    n_packets = write_tsv(OUT_DIR / "packets.tsv", [
        "class", "packet_id", "fixed_size", "vftable", "read", "read_fields", "read_bytes", "read_branching",
        "read_fn", "execute_slot", "execute_fn", "execute_file", "fields(offset:size)"], packet_rows)
    n_classes = write_tsv(OUT_DIR / "classes.tsv", ["class", "vftable", "slot_count", "bases", "slots"], (
        (cls, labels[cls]["vftable"], len(slots_of.get(cls, [])), ",".join(bases_of.get(cls, [])),
         ",".join(hexa(p) for p in slots_of.get(cls, [])))
        for cls in sorted(labels) if "vftable" in labels[cls]))
    n_functions = write_tsv(OUT_DIR / "functions.tsv", ["address", "kind", "name", "thunk_target", "end_hint", "source_file", "vslot", "callers", "callees"], (
        (f["a"], f["k"], f["n"], f["t"] or "",
         entry_text[bisect.bisect_right(entries, int(f["a"], 16))] if f["k"] != "external" and bisect.bisect_right(entries, int(f["a"], 16)) < len(entries) else "",
         func_file.get(f["a"], ""), slot_of.get(f["a"], ""), caller_count.get(f["a"], 0), len(callees.get(f["a"], [])))
        for f in functions))
    n_graph = write_tsv(OUT_DIR / "callgraph.tsv", ["caller", "callees"], ((a, ",".join(t)) for a, t in sorted(callees.items(), key=lambda kv: int(kv[0], 16))))
    n_strings = write_tsv(OUT_DIR / "strings.tsv", ["address", "referrers", "value"], ((a, ",".join(referrers.get(a, [])), esc(v)) for a, v in strings))
    n_imports = write_tsv(OUT_DIR / "imports.tsv", ["address", "dll", "symbol"], (
        (f["a"], f["n"].split("::", 1)[0], f["n"].split("::", 1)[1] if "::" in f["n"] else f["n"]) for f in functions if f["k"] == "external"))
    keep = [(a, v) for a, v in names if not v.startswith(NOISE_PREFIXES) and "::RTTI_" not in v and not v.endswith(("::vftable", "::vftable_meta_ptr"))]
    n_names = write_tsv(OUT_DIR / "names.tsv", ["address", "name"], keep)
    n_sources = write_tsv(OUT_DIR / "sources.tsv", ["file", "functions", "first_fn", "last_fn"], (
        (path, r[2], hexa(r[0]), hexa(r[1])) for path, r in sorted(ranges.items())))
    tables = sorted(((v, a) for a, v in strings if DATA_EXT.search(v) and len(v) < 120 and "GameCode" not in v))
    n_tables = write_tsv(OUT_DIR / "data_files.tsv", ["name", "address", "referrers"], ((v, a, ",".join(referrers.get(a, []))) for v, a in tables))
    register = {f["a"] for f in functions if f["k"] == "external" and "LuaObject::Register" in f["n"]}
    lua_rows = []
    identifier = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{2,63}$")
    refs_of: dict[str, list[str]] = collections.defaultdict(list)
    for address, value in strings:
        if identifier.match(value):
            for func in referrers.get(address, []):
                refs_of[func].append(value)
    for caller, targets in callees.items():
        calls = sum(1 for t in targets if t in register)
        if calls:
            lua_rows.append((caller, func_file.get(caller, ""), calls, ",".join(sorted(set(refs_of.get(caller, []))))))
    n_lua = write_tsv(OUT_DIR / "lua_register.tsv", ["function", "source_file", "register_calls", "identifier_strings"], sorted(lua_rows, key=lambda r: int(r[0], 16)))

    # pseudo-code: nén theo khoảng địa chỉ --------------------------------------------------------------------------
    archive = OUT_DIR / "decompile.zip"
    ordered_funcs = sorted(code, key=lambda a: int(a, 16))
    per_part = 1500
    total_bytes = 0
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for part in range(0, len(ordered_funcs), per_part):
            chunk = ordered_funcs[part:part + per_part]
            lines = []
            for address in chunk:
                name, body = code[address]
                lines.append(f"// ==== {address} {name} [{func_file.get(address, '')}] {slot_of.get(address, '')}\n{body}\n")
            text = "\n".join(lines)
            total_bytes += len(text.encode("utf-8"))
            bundle.writestr(f"decompile/{chunk[0][2:]}-{chunk[-1][2:]}.c", text.encode("utf-8"))

    overview = bulk("plan_a")
    by_name = {row["name"]: row for row in overview}
    meta = {
        "overview": by_name["overview"]["result"], "segments": by_name["segments"]["result"],
        "counts": {
            "functions": len(functions), "internal": len(internal), "externals": n_imports,
            "thunks": sum(1 for f in functions if f["k"] == "thunk"), "strings": n_strings, "names_all": len(names), "names_kept": n_names,
            "decompiled": len(code), "callgraph_callers": n_graph, "classes": n_classes, "packets": n_packets,
            "source_files": n_sources, "functions_with_source_file": len(func_file), "source_range_overlaps": overlap,
            "packet_ids_duplicated": duplicates, "data_files": n_tables, "lua_register_functions": n_lua, "decompile_bytes": total_bytes,
        },
    }
    dump_json(OUT_DIR / "overview.json", meta)
    resources = bulk("plan_res")[0]
    if resources["ok"]:
        dump_json(OUT_DIR / "resources.json", resources["result"])
    else:
        print("CẢNH BÁO: inspect_pe_resources lỗi:", str(resources["result"])[:200])
    print(json.dumps(meta["counts"], ensure_ascii=False, indent=1))


# --- stage lua: tên hàm script -> hàm cài đặt ---------------------------------------------------------------------------
# Chạy offline trên chính các tệp đã ghi ở OUT_DIR (không cần REA). Bản gốc đăng ký API Lua theo ba khuôn, đo trên mã máy:
#   1. Register(bảng, "Tên", hàm_C, 0)                       hàm C trần (IAT 0x140a3b618 trong hàm nạp lớn)
#   2. *lua_newuserdata(8) = hàm; Register(bảng, "Tên", 0x140686e10, 1)   hàm thành viên bọc qua bộ điều phối 0x140686e10
#   3. 0x140686f20(bảng, "Tên", hàm, n) / 0x140686ec0 / 0x140686e60(_, "Tên", hàm)   ba hàm phụ gói khuôn 2 (hai hàm sau ghi vào
#      bảng nằm ở biến toàn cục 0x14103ad28 / 0x14103ac38)
# Tên bảng: CreateTable(globals, ra, "XxxMetaTable") gắn với ô ngăn xếp hoặc biến toàn cục nhận kết quả; tên toàn cục Lua mà
# script thấy là SetObject(globals, "Tên", hộp) với hộp đã SetMetaTable bảng đó.
LUA_DISPATCH = "0x140686e10"
LUA_HELPERS = {"0x140686f20": None, "0x140686ec0": "0x14103ad28", "0x140686e60": "0x14103ac38"}
TEXT_START, TEXT_END = 0x140001000, 0x140a3a800
REG_ALIAS = {f"{p}{s}": f"R{b}" for b in ("AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP") for p, s in (("E", ""), ("R", ""))}
REG_ALIAS.update({f"R{n}{s}": f"R{n}" for n in range(8, 16) for s in ("", "D", "W", "B")})
REG_ALIAS.update({"AX": "RAX", "CX": "RCX", "DX": "RDX", "AL": "RAX", "CL": "RCX", "DL": "RDX"})


def read_dump_tsv(name: str) -> list[list[str]]:
    with (OUT_DIR / name).open(encoding="utf-8") as handle:
        handle.readline()
        return [line.rstrip("\n").split("\t") for line in handle]


class PeImage:
    """Đọc byte của Game.exe theo địa chỉ ảo (PE32+), để lấy chuỗi ngắn Ghidra không định nghĩa và mã của các hàm nhỏ Ghidra không
    tạo hàm. Tệp nằm ngoài repo (WORK/client/Game.exe); không có thì các cột cần nó để trống."""

    def __init__(self, path: Path) -> None:
        self.data = path.read_bytes() if path.exists() else b""
        self.sections: list[tuple[int, int, int]] = []
        if not self.data:
            return
        header = struct.unpack_from("<I", self.data, 0x3C)[0]
        count = struct.unpack_from("<H", self.data, header + 6)[0]
        optional = struct.unpack_from("<H", self.data, header + 20)[0]
        self.base = struct.unpack_from("<Q", self.data, header + 24 + 24)[0]
        # thư mục ngoại lệ (.pdata) là mục dữ liệu thứ 4 của PE32+: bảng RUNTIME_FUNCTION {đầu, cuối, unwind} do trình liên kết ghi
        self.exception = struct.unpack_from("<II", self.data, header + 24 + 112 + 3 * 8)
        table = header + 24 + optional
        for index in range(count):
            _, vsize, va, rsize, rptr = struct.unpack_from("<8sIIII", self.data, table + 40 * index)
            self.sections.append((va, max(vsize, rsize), rptr))

    def runtime_functions(self) -> list[tuple[int, int]]:
        """(đầu, cuối) của mọi hàm có unwind info, địa chỉ ảo tuyệt đối. Gồm cả funclet catch/cleanup của C++ EH (mỗi cái một mục)."""
        rva, size = self.exception
        if not self.data or not size:
            return []
        start = self.read(self.base + rva, size)
        entries = (struct.unpack_from("<III", start, 12 * index) for index in range(len(start) // 12))
        return [(begin + self.base, end + self.base) for begin, end, _ in entries if begin]

    def read(self, address: int, size: int) -> bytes:
        if not self.data:
            return b""
        rva = address - self.base
        for va, length, rptr in self.sections:
            if va <= rva < va + length:
                return self.data[rptr + rva - va: rptr + rva - va + size]
        return b""

    def cstring(self, address: int) -> str | None:
        raw = self.read(address, 256)
        end = raw.find(b"\0")
        if end <= 0 or not all(0x20 <= byte < 0x7F for byte in raw[:end]):
            return None
        return raw[:end].decode("ascii")


def describe_stub(code: bytes) -> str:
    """Mã của một hàm script mà Ghidra không tạo hàm (thường rất ngắn), đọc thẳng từ byte."""
    if not code:
        return "không đọc được byte (thiếu Game.exe)"
    if code.startswith(b"\x33\xc0\xc3"):
        return "rỗng: xor eax,eax; ret (trả 0, không làm gì)"
    if code.startswith(b"\xb8\x01\x00\x00\x00\xc3"):
        return "rỗng: trả 1"
    if code.startswith(b"\xc3"):
        return "rỗng: ret"
    if code.startswith(b"\x48\x8b\x01\xff\x20"):
        return "chuyển tiếp: gọi ô ảo 0 của đối tượng"
    if code.startswith(b"\x48\x8b\x01\xff\x60"):
        return f"chuyển tiếp: gọi ô ảo {code[5] // 8} của đối tượng"
    if code.startswith(b"\x48\x8b\x01\xff\xa0"):
        return f"chuyển tiếp: gọi ô ảo {struct.unpack_from('<I', code, 5)[0] // 8} của đối tượng"
    body = code.split(b"\xcc\xcc", 1)[0]
    return "mã ngắn Ghidra chưa tạo hàm: " + body.hex()


def lua_from_disasm(path: Path, strings: dict[str, str], iat: dict[str, str], image: PeImage):
    regs: dict[str, tuple[str, str]] = {}
    slot_table: dict[str, str] = {}
    gvar_table: dict[str, str] = {}
    meta_of: dict[str, str] = {}
    bindings: dict[str, set[str]] = collections.defaultdict(set)
    created: set[str] = set()
    pending_userdata = None
    registered = []

    def table_of(value):
        if value is None:
            return "?"
        kind, key = value
        if kind == "slot":
            return slot_table.get(key, "?slot" + key)
        if kind == "gvar":
            return gvar_table.get(key, "?" + key)
        return "?"

    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
        match = re.match(r"(0x[0-9a-f]+): (\w+)\s*(.*)", line)
        if not match:
            continue
        _, op, args = match.groups()
        if op == "CALL":
            target_match = re.fullmatch(r"qword ptr \[(0x[0-9a-f]+)\]", args)
            target = iat.get(target_match.group(1), target_match.group(1)) if target_match else args
            ret = None
            rcx, rdx, r8 = regs.get("RCX"), regs.get("RDX"), regs.get("R8")
            name = rdx[1] if rdx and rdx[0] == "str" else None
            if target.startswith("PTR_GetGlobals") and rdx and rdx[0] == "slot":
                slot_table[rdx[1]] = "(globals)"
            elif target.startswith("PTR_CreateTable"):
                table = r8[1] if r8 and r8[0] == "str" else "?"
                created.add(table)
                if rdx and rdx[0] == "slot":
                    slot_table[rdx[1]] = table
                ret = ("table", table)
            elif target.startswith("PTR_operator="):
                if rdx and rdx[0] == "table" and rcx and rcx[0] in ("gvar", "slot"):
                    (gvar_table if rcx[0] == "gvar" else slot_table)[rcx[1]] = rdx[1]
            elif target.startswith("PTR_SetMetaTable"):
                if rcx and rcx[0] == "slot" and rdx:
                    meta_of[rcx[1]] = table_of(rdx)
            elif target.startswith("PTR_SetObject"):
                if name and name != "__index" and table_of(rcx) == "(globals)" and r8:
                    owner = meta_of.get(r8[1]) if r8[0] == "slot" and r8[1] in meta_of else table_of(r8)
                    bindings[owner].add(name)
            elif target.startswith("PTR_Register") and name:
                if r8 and r8[0] == "code" and r8[1] != LUA_DISPATCH:
                    registered.append((table_of(rcx), name, r8[1], "C trần"))
                elif pending_userdata:
                    registered.append((table_of(rcx), name, pending_userdata, "thành viên qua 0x140686e10"))
                pending_userdata = None
            elif target in LUA_HELPERS and name and r8 and r8[0] == "code":
                holder = LUA_HELPERS[target]
                table = table_of(rcx) if holder is None else gvar_table.get(holder, "?" + holder)
                registered.append((table, name, r8[1], f"qua {target}"))
            for reg in ("RAX", "RCX", "RDX", "R8", "R9", "R10", "R11"):
                regs.pop(reg, None)
            if ret:
                regs["RAX"] = ret
            continue
        operands = [part.strip() for part in args.split(",", 1)]
        dest = REG_ALIAS.get(operands[0], operands[0])
        if op == "MOV" and operands[0] == "qword ptr [RAX]" and len(operands) == 2:
            source = regs.get(REG_ALIAS.get(operands[1], operands[1]))
            if source and source[0] == "code":
                pending_userdata = source[1]
            continue
        if op == "MOV" and re.fullmatch(r"qword ptr \[0x[0-9a-f]+\]", operands[0]) and len(operands) == 2:
            continue
        if op in ("LEA", "MOV") and len(operands) == 2:
            source = operands[1]
            absolute = re.fullmatch(r"(?:qword ptr )?\[(0x[0-9a-f]+)\]", source)
            stack = re.fullmatch(r"\[(RBP|RSP) \+ (-?0x[0-9a-f]+)\]", source)
            if absolute and op == "LEA":
                address = absolute.group(1)
                short = None if address in strings or TEXT_START <= int(address, 16) < TEXT_END else image.cstring(int(address, 16))
                if address in strings:
                    regs[dest] = ("str", strings[address])
                elif short:
                    regs[dest] = ("str", short)
                elif TEXT_START <= int(address, 16) < TEXT_END:
                    regs[dest] = ("code", address)
                else:
                    regs[dest] = ("data", address)
                continue
            if absolute and op == "MOV" and source.startswith("qword ptr"):
                regs[dest] = ("gvar", absolute.group(1))
                continue
            if stack and op == "LEA":
                regs[dest] = ("slot", f"{stack.group(1)}{stack.group(2)}")
                continue
            alias = REG_ALIAS.get(source, source)
            if op == "MOV" and alias in regs:
                regs[dest] = regs[alias]
                continue
        regs.pop(dest, None)
    return registered, gvar_table, bindings, created


def lua_from_pseudocode(site: str, block: str, gvar_table: dict[str, str]):
    """Khuôn 1 và 2 trong pseudo-code của các hàm đăng ký nhỏ. Decompiler bẻ dòng tuỳ ý (`Register` rồi xuống dòng mới tới
    `((LuaObject *)lVar1,...`), nên gộp mọi khoảng trắng trước khi đọc.
    Bảng nhận lời gọi là một trong bốn dạng, theo thứ tự thử:
      - `lVarN = DAT_x` hoặc `(LuaObject *)DAT_x`: biến toàn cục, tên lấy từ LuaExport creator (`gvar_table`);
      - ô thành viên (`*(LuaObject **)(param_1 + 0x28)`, `param_1[7]`) hoặc kết quả `CreateTable`: bảng của một đối tượng, tên là
        tên Lua toàn cục mà chính hàm ấy `SetObject(globals, "Tên", ...)` (chỉ nhận khi đúng một tên);
      - tham số của hàm (`param_2`): bảng do nơi gọi truyền vào, tên chưa biết từ riêng hàm này."""
    flat = re.sub(r"\s+", " ", block)
    alias: dict[str, str] = {}
    for assign in re.finditer(r"(\w+) = (?:\(LuaObject \*\))?(DAT_[0-9a-f]+|\*\(LuaObject \*\*\)\(param_\d \+ 0x[0-9a-f]+\)|param_\d\[\d+\]);", flat):
        alias[assign.group(1)] = assign.group(2)
    set_globals = [name for name in re.findall(r"SetObject\(\w+,\"([A-Za-z_]\w*)\"", flat) if name != "__index"]
    unique_global = set_globals[0] if len(set(set_globals)) == 1 else None
    registered = []
    pending = None
    pattern = re.compile(r"\*\w+ = (FUN_[0-9a-f]+);|LuaPlus::LuaObject::Register ?\( ?(?:\(LuaObject \*\))?(\w+|\*\(LuaObject \*\*\)\(param_\d \+ 0x[0-9a-f]+\)) ?,(\"[^\"]+\"|&?\w+),(FUN_[0-9a-f]+|\w+),(\d+)\)")
    for item in pattern.finditer(flat):
        if item.group(1):
            pending = "0x" + item.group(1)[4:]
            continue
        holder = alias.get(item.group(2), item.group(2))
        if holder.startswith("DAT_"):
            table = gvar_table.get("0x" + holder[4:], "?" + holder)
        elif holder.startswith("param_") and "[" not in holder and "+" not in holder:
            table = f"(tham số {holder} của hàm {site})"
        else:
            table = unique_global or f"?{holder}@{site}"
        name = item.group(3).strip('"')
        if item.group(3).startswith("&") or not item.group(3).startswith('"'):
            template = re.search(r'_snprintf\([^"]*,0x100,"([^"]+)"\);\s*$', flat[:item.start()])
            name = template.group(1) if template else name
        function = item.group(4)
        function = "0x" + function[4:] if function.startswith("FUN_") else function
        if function != LUA_DISPATCH:
            registered.append((table, name, function, "C trần"))
        elif pending:
            registered.append((table, name, pending, "thành viên qua 0x140686e10"))
        pending = None
    return registered


def lua_export_tables(blocks: dict[str, str]) -> dict[str, str]:
    """LuaExport<T> (GMInterface_Lua.h): hàm tạo `creator(this, "Tên", state)` cấp một LuaObject vào biến toàn cục DAT_x rồi
    CreateTable(globals, "Tên"). Trả {địa chỉ DAT_x: "Tên"} ghép từ thân creator và mọi lời gọi creator với chuỗi hằng."""
    creator_var: dict[str, str] = {}
    for address, block in blocks.items():
        if "LuaPlus::LuaObject::CreateTable(" in block:
            assign = re.search(r"LuaPlus::LuaObject::operator=\((DAT_[0-9a-f]+),", block)
            if assign and re.search(r"CreateTable\(\w+,\(char \*\)\w+,\(int\)param_2", block):
                creator_var["FUN_" + address[2:]] = "0x" + assign.group(1)[4:]
    tables: dict[str, str] = {}
    for block in blocks.values():
        for call in re.finditer(r"(FUN_[0-9a-f]+)\([^,()]+,\"([A-Za-z_]\w*)\"", block):
            if call.group(1) in creator_var:
                tables[creator_var[call.group(1)]] = call.group(2)
    return tables


def stage_lua(_args) -> None:
    strings = {row[0]: row[2] for row in read_dump_tsv("strings.tsv")}
    names = {row[0]: row[1] for row in read_dump_tsv("names.tsv")}
    iat = {address: name for address, name in names.items() if name.startswith("PTR_")}
    functions = {row[0]: row for row in read_dump_tsv("functions.tsv")}
    register_rows = read_dump_tsv("lua_register.tsv")
    image = PeImage(WORK / "client" / "Game.exe")
    blocks: dict[str, str] = {}
    with zipfile.ZipFile(OUT_DIR / "decompile.zip") as archive:
        for member in archive.namelist():
            text = archive.read(member).decode("utf-8")
            for block in re.split(r"\n(?=// ==== )", text):
                head = re.match(r"// ==== (0x[0-9a-f]+)", block)
                if head:
                    blocks[head.group(1)] = block
    exported = lua_export_tables(blocks)
    created_tables: set[str] = set(exported.values())
    rows = []
    gvar_table: dict[str, str] = dict(exported)
    bindings: dict[str, set[str]] = collections.defaultdict(set)
    for name in exported.values():
        bindings[name].add(name)
    sites = [row[0] for row in register_rows]
    for site in sites:
        asm = OUT_DIR / "disasm" / f"{site}.asm"
        if asm.exists():
            found, gvars, binds, made = lua_from_disasm(asm, strings, iat, image)
            created_tables |= made
            for key, value in gvars.items():
                if value != "?":
                    gvar_table[key] = value
            for table, globals_ in binds.items():
                bindings[table] |= globals_
            found = [(gvar_table.get(t[1:], t) if t.startswith("?0x") else t, *rest) for t, *rest in found]
            rows.extend((site,) + tuple(item) for item in found)
    for site in sites:
        if site in blocks and not (OUT_DIR / "disasm" / f"{site}.asm").exists():
            rows.extend((site,) + item for item in lua_from_pseudocode(site, blocks[site], gvar_table))
    # Nhãn "LUA:Lớp::Hàm" mà chính hàm cài đặt ném khi tham số sai: tên lớp C++ của API, đo từ chuỗi của bản gốc.
    labels: dict[str, str] = {}
    for address, referrers, value in read_dump_tsv("strings.tsv"):
        found = re.match(r"LUA:\s*([A-Za-z_][\w]*(?:::[A-Za-z_]\w*)+)", value)
        if found:
            for func in referrers.split(","):
                labels.setdefault(func, found.group(1))
    # Gộp lần đăng ký trùng: cùng bảng, cùng tên, cùng hàm là một mục (bản gốc gọi Register hai lần); khác hàm thì lần sau đè.
    merged: dict[tuple[str, str], list] = {}
    for order, (site, table, name, impl, how) in enumerate(rows):
        key = (table, name)
        if key in merged:
            entry = merged[key]
            entry["times"] += 1
            if entry["impl"] != impl:
                entry["note"].append(f"đè hàm {entry['impl']} bằng {impl} ở lần đăng ký thứ {entry['times']}")
                entry["impl"], entry["how"] = impl, how
            continue
        merged[key] = {"site": site, "table": table, "name": name, "impl": impl, "how": how, "times": 1, "note": []}
    out = []
    for entry in merged.values():
        impl = entry["impl"]
        info = functions.get(impl)
        code = "hàm" if info else describe_stub(image.read(int(impl, 16), 32))
        note = list(entry["note"])
        if entry["times"] > 1 and not note:
            note.append(f"đăng ký {entry['times']} lần, cùng hàm")
        out.append((entry["table"], ",".join(sorted(bindings.get(entry["table"], ()))), entry["name"], impl, code, entry["how"], entry["site"],
                    labels.get(impl, ""), info[5] if info else "", "; ".join(note)))
    out.sort(key=lambda r: (r[0].lower(), r[2].lower()))
    count = write_tsv(OUT_DIR / "lua_api.tsv", ["table", "lua_globals", "name", "impl", "impl_kind", "how", "register_fn", "error_label", "source_file", "note"], out)
    per_table = collections.Counter(r[0] for r in out)
    table_names = sorted({r[0] for r in out} | created_tables, key=str.lower)
    write_tsv(OUT_DIR / "lua_tables.tsv", ["table", "lua_globals", "functions"],
              ((t, ",".join(sorted(bindings.get(t, ()))), per_table.get(t, 0)) for t in table_names))
    print(f"lua_tables.tsv: {len(table_names)} bảng, {sum(1 for t in table_names if not per_table.get(t))} bảng không có hàm đăng ký")
    unresolved = sum(1 for r in out if r[0].startswith("?"))
    print(f"lua_api.tsv: {count} hàm script ({len(rows)} lần đăng ký), {len({r[0] for r in out})} bảng, {unresolved} chưa rõ bảng, "
          f"{sum(1 for r in out if r[7])} có nhãn LUA:, {sum(1 for r in out if r[4] != 'hàm')} không phải hàm Ghidra, "
          f"{sum(1 for r in out if r[4].startswith('rỗng'))} rỗng, {sum(1 for r in out if 'đè' in r[9])} bị đè")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("stage", choices=("core", "hier", "hier2", "assemble", "lua"))
    args = parser.parse_args()
    {"core": stage_core, "hier": stage_hier, "hier2": stage_hier2, "assemble": stage_assemble, "lua": stage_lua}[args.stage](args)


if __name__ == "__main__":
    sys.exit(main())
