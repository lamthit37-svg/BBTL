# Ghi danh mục thử của test_gen_protocol.py vào build/p2-c/probe/catalog (bản nháp, không nộp).
import sys
from pathlib import Path
sys.path.insert(0, "TOOLS/server")
import test_gen_protocol as t
t.write_catalog(Path("build/p2-c/probe/catalog"), t.copy_rows())
