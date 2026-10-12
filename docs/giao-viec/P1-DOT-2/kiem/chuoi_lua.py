"""Đếm lời gọi LuaFnSetSceneLoad nằm sau dấu nháy chưa đóng trên cùng dòng."""
from pathlib import Path

ROOT = Path(r"C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb\Public\Data\Script")
inside = 0
samples: list[str] = []
for path in ROOT.rglob("*.lua"):
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if "LuaFnSetSceneLoad_" not in line:
            continue
        code = line.split("--", 1)[0]
        at = code.find("LuaFnSetSceneLoad_")
        if at < 0:
            continue
        prefix = code[:at]
        if prefix.count('"') % 2 == 1 or prefix.count("'") % 2 == 1:
            inside += 1
            if len(samples) < 8:
                samples.append(f"{path.name}:{number}:{code.strip()[:140]}")
print(f"sau nháy lẻ: {inside}")
for line in samples:
    print(line)
