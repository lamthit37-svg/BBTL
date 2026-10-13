# Dem canh bao clang-tidy tren cac tep mot commit da doi, truoc (cha) va sau (commit).
# Cung compile_commands (build/msvc-release), cung clang-tidy, cung lenh; chi doi cay nguon (git worktree).
import json, os, re, subprocess, sys, collections, concurrent.futures as cf
TIDY = r"C:\Program Files\LLVM\bin\clang-tidy.exe"
ROOT = r"D:\THIENLONG"
WT = os.path.join(ROOT, "build", "xt")
DB = os.path.join(ROOT, "build", "msvc-release", "compile_commands.json")
HDR_TU = {"src/server/account/cap.hpp": "src/server/account/cap.cpp",
          "src/server/account/book.hpp": "src/server/account/book.cpp",
          "src/client/figure/control/char_camera.hpp": "src/client/figure/control/char_camera.cpp"}
def git(*a): return subprocess.run(["git", "-C", ROOT, *a], capture_output=True, text=True, encoding="utf-8").stdout
def norm(p): return p.replace("\\", "/").lower()
def make_db(dst):
    src = open(DB, encoding="utf-8").read()
    # D:/THIENLONG/<khong phai build/> -> D:/THIENLONG/build/xt/
    for sep in ("/", "\\\\"):
        src = re.sub(r"(?i)D:" + re.escape(sep) + r"THIENLONG" + re.escape(sep) + r"(?!build" + re.escape(sep) + r")",
                     lambda m: m.group(0) + "build" + sep + "xt" + sep, src)
    os.makedirs(dst, exist_ok=True)
    open(os.path.join(dst, "compile_commands.json"), "w", encoding="utf-8").write(src)
def run(commit, files, out):
    subprocess.run(["git", "-C", WT, "checkout", "--detach", "-q", commit], check=True)
    dbdir = os.path.join(ROOT, "build", "xt-db"); make_db(dbdir)
    tus = sorted({HDR_TU.get(f, f) for f in files if f.endswith((".cpp", ".hpp"))})
    hf = "(" + "|".join(re.escape(f.replace("/", "[\\\\/]").replace("[\\\\/]", "/")) for f in files) + ")"
    hf = "(" + "|".join(f.replace("/", "[/\\\\]").replace(".", "\\.") for f in files) + ")$"
    def one(tu):
        cmd = [TIDY, "-p", dbdir, "--quiet", "--header-filter=" + hf, os.path.join(WT, tu)]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        return tu, cmd, r.stdout + r.stderr
    counts = collections.Counter(); per = collections.Counter(); seen = set()
    with open(out, "w", encoding="utf-8") as log, cf.ThreadPoolExecutor(6) as ex:
        log.write(f"commit {commit}\nTUs {tus}\n")
        for tu, cmd, text in ex.map(one, tus):
            log.write("\n### " + " ".join(cmd) + "\n" + text)
            for m in re.finditer(r"^(.*?):(\d+):(\d+): (?:warning|error): .*\[([\w\-.]+)(?:,-warnings-as-errors)?\]$", text, re.M):
                path = norm(m.group(1)); rel = None
                for f in files:
                    if path.endswith(norm(f)): rel = f
                if rel is None: continue
                key = (rel, m.group(2), m.group(3), m.group(4))
                if key in seen: continue
                seen.add(key); counts[m.group(4)] += 1; per[rel] += 1
    return counts, per
def main():
    commit = sys.argv[1]; parent = git("rev-parse", "--short", commit + "^").strip()
    files = [f for f in git("show", "--name-only", "--format=", commit).split() if f]
    evd = os.path.join(ROOT, "docs", "AUDIT", "evidence")
    res = {}
    for tag, c in (("truoc", parent), ("sau", commit)):
        res[tag] = run(c, files, os.path.join(evd, f"tidy_{commit}_{tag}.log"))
    with open(os.path.join(evd, f"tidy_{commit}_counts.txt"), "w", encoding="utf-8") as o:
        o.write(f"commit {commit} (cha {parent}); clang-tidy: {subprocess.run([TIDY,'--version'],capture_output=True,text=True).stdout.strip()}\n")
        o.write(f"db: {DB} (duong dan nguon doi sang build/xt); lenh: python docs/AUDIT/evidence/tidy_count.py {commit}\n")
        o.write(f"tep: {files}\n")
        checks = sorted(set(res['truoc'][0]) | set(res['sau'][0]))
        o.write(f"\n{'check':60} truoc  sau\n")
        for k in checks: o.write(f"{k:60} {res['truoc'][0][k]:5} {res['sau'][0][k]:4}\n")
        o.write(f"{'TONG':60} {sum(res['truoc'][0].values()):5} {sum(res['sau'][0].values()):4}\n")
        new = [k for k in checks if res['sau'][0][k] > res['truoc'][0][k]]
        o.write(f"\ncheck tang sau commit: {new or 'khong co'}\n")
    print(open(os.path.join(evd, f"tidy_{commit}_counts.txt"), encoding="utf-8").read())
main()
