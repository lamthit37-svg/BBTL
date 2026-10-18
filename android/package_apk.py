#===============================================================================
#  THIENLONG  |  ANDROID SHELL
#-------------------------------------------------------------------------------
#  TỆP       : android/package_apk.py
#  PHÂN HỆ   : Package Apk
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Đóng APK native (NativeActivity, không Gradle) từ libthienlong.so và dựng
#    thư mục bundle iOS (--stage) từ cùng một danh sách tệp.
#  - Danh sách tệp là bao đóng Table/mobile.files.tsv (trace_assets.py): texture
#    đã nấu (bake_mobile_textures.py) thay DDS gốc; thiếu tệp là lỗi.
#  - --gate-host thay địa chỉ máy chủ trong Table/gates.tsv cho thiết bị.
#  - --delta chỉ đóng assets khác sổ của máy đang cắm, --install cài luôn: vòng
#    thử trên máy thật không phải đóng và cài lại 1,25 GB dữ liệu không đổi.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Cả cây data vượt 4 GB, zipalign không mở được ZIP64. --shaders đóng gói .f2s vào assets/shaders. --stage chép cùng
# tập cảnh ra một thư mục (bundle iOS). Thiết bị giải nén hai thư mục này ra bộ nhớ nội bộ ở lần chạy đầu. --depfile
# ghi mọi tệp và thư mục đã đọc theo cú pháp depfile của Ninja: thiếu nó thì hệ dựng không biết dữ liệu đổi và giữ APK
# cũ (đã gặp: thêm tệp vào danh sách cảnh mà APK không đóng lại).

from __future__ import annotations

import argparse
import ipaddress
import os
import re
import shutil
import subprocess
import zlib
import zipfile
from pathlib import Path


# Mọi tệp và thư mục lần chạy này đã đọc, cho --depfile.
read_inputs: list[Path] = []


class DeltaBook:
    # --delta: sổ assets mà máy đang giữ (files/data/assets.book, vỏ ghi sau mỗi lần chép đủ) và dấu
    # đã tính của tệp nguồn. Tệp có dấu trùng sổ của máy thì không đóng vào APK, chỉ ghi dòng sổ:
    # vỏ chỉ chép tệp có dấu khác sổ nó giữ (client/assets.hpp), nên mọi tệp nó cần đều có trong gói.
    # Đo 2026-10-17 (TB-X306F, USB): APK đủ 1,25 GB đóng 35 giây và cài 120 giây; chỉ mã 8 MB dưới 1 giây.

    def __init__(self, device_book: str, cache: Path) -> None:
        self.kept: dict[tuple[str, str], str] = {}
        for line in device_book.splitlines():
            parts = line.rstrip("\r").split(" ", 2)
            if len(parts) == 3:
                self.kept[(parts[0], parts[2])] = parts[1]
        self.cache_path = cache
        self.cache: dict[str, tuple[int, int, str]] = {}
        self.skipped = 0
        self.packed = 0
        self.load_cache()

    def load_cache(self) -> None:
        # Dấu nhớ theo đường dẫn, cỡ và mtime: lần đóng sau không phải đọc lại cả cây dữ liệu.
        if not self.cache_path.is_file():
            return
        for line in self.cache_path.read_text(encoding="utf-8").splitlines():
            parts = line.split("\t", 3)
            if len(parts) == 4:
                self.cache[parts[3]] = (int(parts[0]), int(parts[1]), parts[2])

    def save_cache(self) -> None:
        rows = [f"{size}\t{mtime}\t{stamp}\t{path}" for path, (size, mtime, stamp) in self.cache.items()]
        self.cache_path.write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")

    def stamp_of(self, source: Path) -> str:
        # Cùng dạng dòng sổ của add_asset: CRC-32 của nội dung (như ZipInfo.CRC) và cỡ tệp.
        status = source.stat()
        key = str(source.resolve())
        known = self.cache.get(key)
        if known and known[0] == status.st_size and known[1] == status.st_mtime_ns:
            return known[2]
        crc = 0
        with source.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1 << 20), b""):
                crc = zlib.crc32(chunk, crc)
        stamp = f"{crc & 0xFFFFFFFF:08x}-{status.st_size}"
        self.cache[key] = (status.st_size, status.st_mtime_ns, stamp)
        return stamp

    def kept_stamp(self, group: str, relative: str, source: Path) -> str | None:
        # Dấu của tệp khi máy đã giữ đúng bản này; None khi phải đóng vào gói.
        stamp = self.stamp_of(source)
        if self.kept.get((group, relative)) != stamp:
            self.packed += 1
            return None
        self.skipped += 1
        return stamp


# Có khi chạy --delta; None là đóng đủ.
delta_book: DeltaBook | None = None
# Mọi mục assets đã ghi sổ, kể cả mục --delta không đóng: chặn một tệp được kê hai lần.
listed_names: set[str] = set()


AVATAR_TABLES = ("player_bodies", "faces", "hairs", "outfits", "anim_sets")


def listed_paths(listing: Path) -> list[str]:
    # Danh sách "kind<TAB>đường dẫn" do collect_map / collect_avatar ghi.
    paths: list[str] = []
    read_inputs.append(listing)
    for line in listing.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("kind\t"):
            continue
        cells = line.split("\t")
        if len(cells) < 2 or cells[1] == "":
            continue
        relative = cells[1].replace("\\", "/")
        if relative.startswith("/") or ".." in Path(relative).parts:
            raise SystemExit(f"đóng gói: đường dẫn thoát data: {relative}")
        paths.append(relative)
    return paths


def creature_paths(data: Path) -> list[str]:
    # Quái và NPC (TOOLS/content/export_creatures.py rồi collect_creatures.py): bốn bảng nằm trong Table (thư mục mang
    # nguyên), lưới, xương, clip và ảnh do Table/creature.files.tsv liệt kê. Không có danh sách thì APK không vẽ quái, NPC
    # (client ghi log), không phải lỗi đóng gói.
    listing = data / "Table" / "creature.files.tsv"
    if not listing.is_file():
        return []
    return listed_paths(listing)


# Thư mục mang nguyên: nhỏ, nhiều nơi đọc theo bảng nên vết của trace_assets.py khó phủ hết. Quét lúc đóng gói, không theo
# ảnh chụp lúc trace: bảng mới thêm (như bảng quái) vào gói ngay.
WHOLE_FOLDERS = ("Table", "Config", "Script", "effect", "Web")
# Layout giao diện (3,6 MB, 2 071 tệp): HUD nạp cố định 34 layout nhưng host Lua nạp thêm theo sổ cửa sổ, và danh sách
# layout của HUD đổi theo phiên bản (Quest.layout.xml thêm sau lượt trace làm HUD không mở được trên điện thoại).
WHOLE_PATTERNS = ("Interface/**/*.layout.xml",)
# Bảng chương trình chất liệu (export_material_programs.py): resource/ogre_mesh.cpp đọc nó cho mọi
# lưới OGRE, nên lượt trace cũ không có nó vẫn phải mang. Thiếu thì chất liệu mất luồng sáng, viền.
# Ảnh chùm sáng hướng nhìn của minimap (export_map_light.py): hud.cpp nạp thẳng tệp này, không qua imageset nên vết
# của trace_assets.py không phủ tới nó; thiếu thì APK mất chùm sáng mà PC vẫn có. Tấm mũi tên người chơi của
# minimap (export_map_arrow.py) cùng lý do: client ghép nó với chùm sáng thành texture lớp phủ; thiếu thì mũi tên
# quay về dùng tấm DDS đã nấu (thêm một lệnh vẽ), không mất hình.
WHOLE_FILES = (
    "Material/programs.tsv",
    "Interface/Common/MapSearchLight.png",
    "Interface/Common/MiniMap_Arrow.png",
)


def folder_paths(data: Path) -> list[str]:
    found: list[str] = []
    for relative in WHOLE_FILES:
        if (data / relative).is_file():
            read_inputs.append(data / relative)
            found.append(relative)
    for pattern in WHOLE_PATTERNS:
        found.extend(path.relative_to(data).as_posix() for path in sorted(data.glob(pattern)) if path.is_file())
    for folder in WHOLE_FOLDERS:
        root = data / folder
        if not root.is_dir():
            continue
        read_inputs.append(root)
        for path in sorted(root.rglob("*")):
            if path.is_file():
                found.append(path.relative_to(data).as_posix())
            else:
                read_inputs.append(path)
    return found


def avatar_paths(data: Path) -> list[str]:
    # Người chơi mặc định của hai giới (export_look.py rồi collect_avatar.py): năm bảng Table/*.tsv
    # và mọi GLB, ảnh mà Table/avatar.files.tsv liệt kê. Không có danh sách thì APK không có người
    # chơi (client vẫn chạy, ghi log), nên không phải lỗi đóng gói.
    listing = data / "Table" / "avatar.files.tsv"
    if not listing.is_file():
        return []
    tables = [f"Table/{name}.tsv" for name in AVATAR_TABLES]
    return tables + listed_paths(listing)


def audio_paths(data: Path, has_cooked_sound: bool) -> list[str]:
    # Nhạc và hiệu ứng nhỏ hơn một cảnh. Chỉ thêm khi thư mục đã được chép vào data. Có cây
    # sound đã cook (--sound) thì sound/ gốc ở lại máy dựng.
    found = []
    folders = ("music",) if has_cooked_sound else ("music", "sound")
    for folder in folders:
        root = data / folder
        if not root.is_dir():
            continue
        read_inputs.append(root)
        for path in sorted(root.rglob("*")):
            if path.is_file():
                found.append(path.relative_to(data).as_posix())
            else:
                read_inputs.append(path)
    return found


def extend_unique(paths: list[str], seen: set[str], more: list[str]) -> None:
    for relative in more:
        if relative in seen:
            continue
        seen.add(relative)
        paths.append(relative)


def closure_paths(data: Path) -> list[str]:
    # Bao đóng của gói: những tệp dữ liệu client PC thật sự mở khi chạy đăng nhập và màn chơi (TOOLS/run/trace_assets.py).
    # Không có danh sách thì không biết đóng gì: dừng, không đóng một APK thiếu tệp.
    listing = data / "Table" / "mobile.files.tsv"
    if not listing.is_file():
        raise SystemExit(f"đóng gói: thiếu {listing}. Chạy python -B TOOLS/run/trace_assets.py trước.")
    return listed_paths(listing)


def baked_files(baked: Path | None, tiers: tuple[str, ...]) -> list[tuple[str, Path]]:
    # Texture đã nấu (TOOLS/content/bake_mobile_textures.py): mobile/<tier>/<đường dẫn> dưới thư mục nấu. Trả cặp (đường
    # dẫn trong gói, tệp nguồn).
    if baked is None:
        return []
    found: list[tuple[str, Path]] = []
    for tier in tiers:
        root = baked / "mobile" / tier
        if not root.is_dir():
            raise SystemExit(f"đóng gói: thiếu {root}. Chạy python -B TOOLS/content/bake_mobile_textures.py trước.")
        read_inputs.append(root)
        for path in sorted(root.rglob("*")):
            if path.is_file():
                found.append((path.relative_to(baked).as_posix(), path))
            else:
                read_inputs.append(path)
    return found


def baked_sources(baked: list[tuple[str, Path]]) -> set[str]:
    # DDS gốc của texture đã nấu thì không cần mang: tier có tệp riêng và engine/resource/tier.cpp chỉ rơi về tệp gốc khi
    # thiếu bản nấu. tier_relative thêm tiền tố mobile/<tier>/ vào đường dẫn gốc.
    return {name.split("/", 2)[2] for name, _ in baked}


def scene_files(data: Path, has_cooked_sound: bool, baked: Path | None = None,
                tiers: tuple[str, ...] = ("astc", "etc2")) -> list[tuple[str, Path]]:
    # Cả thư mục data là mọi map (hàng GB). APK và bundle mang đúng bao đóng của client (closure_paths), người chơi mặc
    # định (avatar.files.tsv) và âm thanh; texture đã nấu thay DDS gốc. Trả cặp (đường dẫn trong gói, tệp nguồn).
    paths: list[str] = []
    seen: set[str] = set()
    extend_unique(paths, seen, closure_paths(data))
    extend_unique(paths, seen, folder_paths(data))
    extend_unique(paths, seen, avatar_paths(data))
    extend_unique(paths, seen, creature_paths(data))
    extend_unique(paths, seen, audio_paths(data, has_cooked_sound))
    if has_cooked_sound:
        # Cây đã cook (cooked_sound_files) thay cả thư mục sound/ gốc: bao đóng có tệp gốc đã mở lúc trace (sound_table.xml,
        # tiếng bấm), đóng cả hai là trùng tên trong gói.
        paths = [relative for relative in paths if not relative.startswith("sound/")]
    cooked = baked_files(baked, tiers)
    replaced = baked_sources(cooked)
    files = [(relative, data / relative) for relative in paths if relative not in replaced]
    files.extend(cooked)
    return files


# Định dạng đã nén sẵn: deflate thêm không bớt được gì mà tốn thời gian giải ở lần chạy đầu.
PRECOMPRESSED = frozenset({".png", ".jpg", ".jpeg", ".mp3", ".ogg", ".tla", ".opus"})


def compression_of(source: Path) -> int:
    # Vỏ Android giải mọi tệp ra bộ nhớ trong ở lần chạy đầu (AAsset đọc được tệp nén), nên tệp không cần nằm STORED để
    # mmap. Bảng, script, XML, mesh và khối texture nén deflate thì APK nhỏ hẳn (đo ở báo cáo 2026-10-15).
    return zipfile.ZIP_STORED if source.suffix.lower() in PRECOMPRESSED else zipfile.ZIP_DEFLATED


def add_asset(archive: zipfile.ZipFile, source: Path, folder: str, group: str,
              relative: str) -> str:
    # Đưa một tệp vào assets/<folder>/ và trả dòng sổ "<nhóm> <dấu> <đường dẫn>". Dấu là CRC và
    # cỡ tệp: vỏ Android chỉ chép lại tệp có dấu khác sổ nó đã giữ (client/assets.hpp).
    name = f"assets/{folder}/{relative}"
    if name in listed_names:
        # zipfile chỉ cảnh báo; apksigner từ chối gói có hai mục cùng tên.
        raise SystemExit(f"đóng gói: {name} được đóng hai lần")
    listed_names.add(name)
    read_inputs.append(source)
    kept = delta_book.kept_stamp(group, relative, source) if delta_book else None
    if kept is not None:
        return f"{group} {kept} {relative}"
    archive.write(source, name, compress_type=compression_of(source))
    info = archive.getinfo(name)
    return f"{group} {info.CRC:08x}-{info.file_size} {relative}"


def cooked_sound_files(cooked: Path) -> list[tuple[str, Path]]:
    # Cây sound do thienlong_audio cook (.tla 48 kHz và bảng id). Trên thiết bị nó nằm đúng chỗ
    # của sound/ gốc: bộ âm thanh thử tệp .tla cùng tên trước tệp gốc. Trả cặp (đường dẫn trong gói, tệp nguồn).
    if not (cooked / "sound_table.xml").is_file():
        raise SystemExit(f"đóng gói: {cooked} chưa có bản cook. Chạy thienlong_audio cook trước.")
    found: list[tuple[str, Path]] = []
    read_inputs.append(cooked)
    for path in sorted(cooked.rglob("*")):
        if not path.is_file():
            read_inputs.append(path)
            continue
        found.append(("sound/" + path.relative_to(cooked).as_posix(), path))
    return found


def add_cooked_sound(archive: zipfile.ZipFile, cooked: Path, manifest: list[str]) -> int:
    files = cooked_sound_files(cooked)
    for relative, path in files:
        manifest.append(add_asset(archive, path, "data", "D", relative))
    return len(files)


def require_files(files: list[tuple[str, Path]]) -> None:
    missing = [str(source) for _, source in files if not source.is_file()]
    if missing:
        shown = "\n  ".join(missing[:20])
        raise SystemExit(f"đóng gói: thiếu {len(missing)} tệp trong danh sách:\n  {shown}")


def add_listed(archive: zipfile.ZipFile, files: list[tuple[str, Path]], manifest: list[str]) -> int:
    require_files(files)
    for relative, source in files:
        manifest.append(add_asset(archive, source, "data", "D", relative))
    return len(files)


def stage_scene(files: list[tuple[str, Path]], dest: Path) -> None:
    require_files(files)
    for relative, source in files:
        target = dest / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    print(f"đóng gói: đã dựng {len(files)} tệp cảnh vào {dest}")


def add_tree(archive: zipfile.ZipFile, source: Path, in_assets: str, prefix: str,
             manifest: list[str]) -> int:
    count = 0
    read_inputs.append(source)
    for path in sorted(source.rglob("*")):
        if path.is_file():
            relative = path.relative_to(source).as_posix()
            manifest.append(add_asset(archive, path, in_assets, prefix, relative))
            count += 1
        else:
            read_inputs.append(path)
    return count


def depfile_name(path: Path) -> str:
    # Đường dẫn tuyệt đối, gạch xuôi; dấu cách, # và $ thoát theo cú pháp depfile.
    text = path.resolve().as_posix()
    return text.replace(" ", "\\ ").replace("#", "\\#").replace("$", "$$")


def write_depfile(depfile: Path, target: Path) -> None:
    names = sorted({depfile_name(path) for path in read_inputs})
    body = " \\\n  ".join(names)
    depfile.write_text(f"{depfile_name(target)}: {body}\n", encoding="utf-8", newline="\n")


def sdk_root() -> Path:
    env = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if env:
        return Path(env)
    local = os.environ.get("LOCALAPPDATA")
    if not local:
        raise SystemExit("android: không thấy ANDROID_HOME")
    return Path(local) / "Android" / "Sdk"


def newest(folder: Path) -> Path:
    picks = sorted(path for path in folder.iterdir() if path.is_dir())
    if not picks:
        raise SystemExit(f"android: thư mục trống {folder}")
    return picks[-1]


def run(command: list[str]) -> None:
    result = subprocess.run(command, check=False, text=True, capture_output=True)
    if result.returncode == 0:
        return
    raise SystemExit(result.stdout + result.stderr + f"\nandroid: lệnh thoát {result.returncode}")


def compile_resources(build_tools: Path, res: Path, work: Path) -> Path:
    # Icon của ứng dụng: aapt2 gom thư mục res thành một gói .flata để link đưa vào resources.arsc.
    if not res.is_dir():
        raise SystemExit(f"android: không thấy thư mục res {res}")
    read_inputs.append(res)
    read_inputs.extend(path for path in sorted(res.rglob("*")))
    compiled = work / "res.flata"
    run([str(build_tools / "aapt2.exe"), "compile", "--dir", str(res), "-o", str(compiled)])
    return compiled


def package_of(manifest: Path) -> str:
    found = re.search(r'package="([^"]+)"', manifest.read_text(encoding="utf-8"))
    if not found:
        raise SystemExit(f"android: {manifest} không có package")
    return found.group(1)


def device_book(package: str) -> str | None:
    # Sổ assets vỏ đã ghi trên máy (bản dev debuggable nên run-as đọc được). None khi không đọc được:
    # chưa cài, đã gỡ, không có máy, hay nhiều máy mà không đặt ANDROID_SERIAL.
    command = ["adb", "exec-out", "run-as", package, "cat", "files/data/assets.book"]
    result = subprocess.run(command, check=False, capture_output=True)
    text = result.stdout.decode("utf-8", errors="replace")
    is_book = result.returncode == 0 and text.startswith(("D ", "S "))
    if is_book:
        return text
    reason = (result.stderr.decode("utf-8", errors="replace") + text).strip().splitlines()
    print(f"android: adb không đọc được sổ: {reason[0] if reason else result.returncode}")
    return None


def debug_keystore(work: Path) -> Path:
    # Khoá ký bản dev nằm ngoài cây dựng, chung mọi preset Android: khoá đổi thì APK mới không cập nhật được bản đã cài
    # (INSTALL_FAILED_UPDATE_INCOMPATIBLE) và người thử phải gỡ ứng dụng, mất dữ liệu trong máy. Trước đây mỗi cây
    # build/<preset>/apk-work tự sinh một khoá, xoá cây là đổi khoá; khoá cũ của cây (nếu có) được chuyển sang chỗ chung.
    store = Path.home() / ".android" / "thienlong-debug.keystore"
    if store.exists():
        return store
    store.parent.mkdir(parents=True, exist_ok=True)
    legacy = work / "debug.keystore"
    if legacy.is_file():
        shutil.copyfile(legacy, store)
        return store
    run(
        [
            "keytool",
            "-genkeypair",
            "-keystore",
            str(store),
            "-storepass",
            "thienlong",
            "-keypass",
            "thienlong",
            "-alias",
            "thienlong",
            "-keyalg",
            "RSA",
            "-keysize",
            "2048",
            "-validity",
            "10000",
            "-dname",
            "CN=THIENLONG Debug,O=THIENLONG,C=VN",
        ]
    )
    return store


GATE_FILE = "Table/gates.tsv"


def rewritten_gates(source: Path, address: ipaddress.IPv4Address, work: Path) -> Path:
    lines = source.read_text(encoding="utf-8").splitlines()
    rows = [line for line in lines if line and not line.startswith("#")]
    if not rows:
        raise SystemExit(f"đóng gói: {source} trống")
    columns = rows[0].split("\t")
    if "host" not in columns:
        raise SystemExit(f"đóng gói: {source} không có cột host")
    column = columns.index("host")
    rewritten: list[str] = []
    seen_header = False
    for line in lines:
        cells = line.split("\t")
        is_data = bool(line) and not line.startswith("#")
        if is_data and seen_header and len(cells) > column:
            cells[column] = str(address)
        seen_header = seen_header or is_data
        rewritten.append("\t".join(cells))
    work.mkdir(parents=True, exist_ok=True)
    target = work / "gates.tsv"
    target.write_text("\n".join(rewritten) + "\n", encoding="utf-8", newline="\n")
    return target


def with_gate_host(files: list[tuple[str, Path]], host: str, work: Path) -> list[tuple[str, Path]]:
    # Thiết bị không thấy 127.0.0.1 của máy chủ thử: --gate-host thay cột host của bảng cổng (client/session/gates.hpp)
    # bằng địa chỉ mà thiết bị tới được (LAN của máy dựng, hoặc cổng NAT của giả lập). Không nêu thì giữ nguyên bảng.
    if not host:
        return files
    try:
        address = ipaddress.IPv4Address(host)
    except ValueError as error:
        raise SystemExit(f"đóng gói: --gate-host không phải IPv4: {host}") from error
    return [
        (relative, rewritten_gates(source, address, work) if relative == GATE_FILE else source)
        for relative, source in files
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", default="")
    parser.add_argument("--abi", default="")
    parser.add_argument("--out", default="")
    parser.add_argument("--manifest", default="")
    parser.add_argument("--data", default="")
    parser.add_argument("--shaders", default="")
    parser.add_argument("--sound", default="",
                        help="cây sound đã cook bằng thienlong_audio, đóng thay cho data/sound")
    parser.add_argument("--stage", default="",
                        help="chép cảnh startup.id và hai cảnh đăng nhập ra thư mục này")
    parser.add_argument("--baked", default="",
                        help="thư mục texture đã nấu (bake_mobile_textures.py), thay DDS gốc bằng ASTC và ETC2")
    parser.add_argument("--gate-host", default="",
                        help="địa chỉ IPv4 máy chủ mà thiết bị thấy, thay cột host của Table/gates.tsv")
    parser.add_argument("--strip", default="",
                        help="llvm-strip của NDK: APK mang bản .so đã bỏ ký hiệu gỡ lỗi, bản đủ ở lại cây dựng")
    parser.add_argument("--res", default="",
                        help="thư mục res của APK (mipmap/ic_launcher.png), biên dịch bằng aapt2 vào resources.arsc")
    parser.add_argument("--depfile", default="", help="ghi depfile của --out cho Ninja")
    parser.add_argument("--delta", action="store_true",
                        help="chỉ đóng assets khác sổ của máy đang cắm (adb); không đọc được sổ thì đóng đủ")
    parser.add_argument("--install", action="store_true", help="adb install -r gói vừa đóng")
    args = parser.parse_args()
    baked = Path(args.baked) if args.baked else None
    if args.stage:
        if not args.data:
            raise SystemExit("đóng gói: --stage cần --data")
        # iOS: mọi máy có ASTC, không mang ETC2. Sound đã cook như APK.
        staged = scene_files(Path(args.data), bool(args.sound), baked, ("astc",))
        if args.sound:
            staged.extend(cooked_sound_files(Path(args.sound)))
        stage_scene(with_gate_host(staged, args.gate_host, Path(args.stage).parent / "gates-work"), Path(args.stage))
        return
    if not args.library or not args.abi or not args.out or not args.manifest:
        raise SystemExit("đóng gói: thiếu --library, --abi, --out hoặc --manifest")
    library = Path(args.library)
    if not library.is_file():
        raise SystemExit(f"android: không thấy {library}")
    root = sdk_root()
    build_tools = newest(root / "build-tools")
    platform = newest(root / "platforms")
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    work = out.parent / ("apk-delta" if args.delta else "apk-work")
    work.mkdir(parents=True, exist_ok=True)
    global delta_book
    book = device_book(package_of(Path(args.manifest))) if args.delta else None
    if args.delta and book is None:
        print("android: không đọc được sổ assets của máy, đóng đủ")
    if book is not None:
        delta_book = DeltaBook(book, work / "stamps.tsv")
    unsigned = work / "unsigned.apk"
    aligned = work / "aligned.apk"
    link = [
        str(build_tools / "aapt2.exe"),
        "link",
        "-o",
        str(unsigned),
        "--manifest",
        args.manifest,
        "-I",
        str(platform / "android.jar"),
    ]
    if args.res:
        link += ["-R", str(compile_resources(build_tools, Path(args.res), work))]
    run(link)
    shipped = library
    if args.strip:
        # Bản RelWithDebInfo mang DWARF (đo 2026-10-15: 122 MiB). Thiết bị không cần; ndk-stack và llvm-symbolizer đọc
        # bản đủ ở cây dựng, cùng build id.
        shipped = work / "libthienlong.so"
        run([args.strip, "--strip-unneeded", "-o", str(shipped), str(library)])
    files = 0
    manifest: list[str] = []
    with zipfile.ZipFile(unsigned, "a") as archive:
        archive.write(
            shipped,
            f"lib/{args.abi}/libthienlong.so",
            compress_type=zipfile.ZIP_STORED,
        )
        if args.data:
            listed = scene_files(Path(args.data), bool(args.sound), baked)
            listed = with_gate_host(listed, args.gate_host, work / "gates")
            files += add_listed(archive, listed, manifest)
        if args.sound:
            files += add_cooked_sound(archive, Path(args.sound), manifest)
        if args.shaders:
            shader_dir = Path(args.shaders)
            vertex = shader_dir / "model.vs.f2s"
            pixel = shader_dir / "model.ps.f2s"
            if not vertex.is_file() or not pixel.is_file():
                raise SystemExit(
                    "android: thiếu gói shader của bản PC "
                    f"({vertex} và {pixel}). Dựng preset clang-asan trước."
                )
            files += add_tree(archive, shader_dir, "shaders", "S", manifest)
        if manifest:
            # Sổ tay assets: AAssetDir của NDK không liệt kê thư mục con, thiết bị cần danh sách
            # tệp để chép đúng cây. D = assets/data, S = assets/shaders.
            archive.writestr("assets/manifest.txt", "\n".join(manifest) + "\n",
                             compress_type=zipfile.ZIP_STORED)
    if args.data or args.shaders:
        print(f"android: đóng {files} tệp assets")
    if delta_book:
        delta_book.save_cache()
        print(f"android: delta đóng {delta_book.packed} tệp, {delta_book.skipped} tệp máy đã có")
    # zipalign đọc thẳng bản chưa ký: chép qua một tệp trung gian là thêm một lượt đọc và ghi cả gói (hơn 1 GB) vào RAM.
    run([str(build_tools / "zipalign.exe"), "-p", "-f", "4", str(unsigned), str(aligned)])
    store = debug_keystore(work)
    if out.exists():
        out.unlink()
    run(
        [
            "cmd",
            "/c",
            str(build_tools / "apksigner.bat"),
            "sign",
            "--ks",
            str(store),
            "--ks-pass",
            "pass:thienlong",
            "--key-pass",
            "pass:thienlong",
            "--out",
            str(out),
            str(aligned),
        ]
    )
    if args.depfile:
        read_inputs.append(library)
        write_depfile(Path(args.depfile), out)
    print(f"android: {out} ({out.stat().st_size} byte)")
    if args.install:
        run(["adb", "install", "-r", str(out)])
        print(f"android: đã cài {out.name}")


if __name__ == "__main__":
    main()
