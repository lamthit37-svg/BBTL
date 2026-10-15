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
import shutil
import subprocess
import zipfile
from pathlib import Path


# Mọi tệp và thư mục lần chạy này đã đọc, cho --depfile.
read_inputs: list[Path] = []


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
    # Bao đóng của gói: những tệp dữ liệu client PC thật sự mở khi chạy đăng nhập và màn chơi, cộng cả thư mục Table, Config,
    # Script, effect, Web (TOOLS/run/trace_assets.py). Không có danh sách thì không biết đóng gì: dừng, không đóng một APK
    # thiếu tệp.
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
    extend_unique(paths, seen, avatar_paths(data))
    extend_unique(paths, seen, audio_paths(data, has_cooked_sound))
    cooked = baked_files(baked, tiers)
    replaced = baked_sources(cooked)
    files = [(relative, data / relative) for relative in paths if relative not in replaced]
    files.extend(cooked)
    return files


def add_asset(archive: zipfile.ZipFile, source: Path, folder: str, group: str,
              relative: str) -> str:
    # Đưa một tệp vào assets/<folder>/ và trả dòng sổ "<nhóm> <dấu> <đường dẫn>". Dấu là CRC và
    # cỡ tệp: vỏ Android chỉ chép lại tệp có dấu khác sổ nó đã giữ (client/assets.hpp).
    name = f"assets/{folder}/{relative}"
    read_inputs.append(source)
    archive.write(source, name, compress_type=zipfile.ZIP_STORED)
    info = archive.getinfo(name)
    return f"{group} {info.CRC:08x}-{info.file_size} {relative}"


def add_cooked_sound(archive: zipfile.ZipFile, cooked: Path, manifest: list[str]) -> int:
    # Cây sound do thienlong_audio cook (.tla 48 kHz và bảng id). Trên thiết bị nó nằm đúng chỗ
    # của sound/ gốc: bộ âm thanh thử tệp .tla cùng tên trước tệp gốc.
    if not (cooked / "sound_table.xml").is_file():
        raise SystemExit(f"đóng gói: {cooked} chưa có bản cook. Chạy thienlong_audio cook trước.")
    count = 0
    read_inputs.append(cooked)
    for path in sorted(cooked.rglob("*")):
        if not path.is_file():
            read_inputs.append(path)
            continue
        relative = "sound/" + path.relative_to(cooked).as_posix()
        manifest.append(add_asset(archive, path, "data", "D", relative))
        count += 1
    return count


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


def debug_keystore(folder: Path) -> Path:
    store = folder / "debug.keystore"
    if store.exists():
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
    parser.add_argument("--depfile", default="", help="ghi depfile của --out cho Ninja")
    args = parser.parse_args()
    baked = Path(args.baked) if args.baked else None
    if args.stage:
        if not args.data:
            raise SystemExit("đóng gói: --stage cần --data")
        # iOS: mọi máy có ASTC, không mang ETC2.
        staged = scene_files(Path(args.data), False, baked, ("astc",))
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
    work = out.parent / "apk-work"
    work.mkdir(parents=True, exist_ok=True)
    unsigned = work / "unsigned.apk"
    packed = work / "packed.apk"
    aligned = work / "aligned.apk"
    run(
        [
            str(build_tools / "aapt2.exe"),
            "link",
            "-o",
            str(unsigned),
            "--manifest",
            args.manifest,
            "-I",
            str(platform / "android.jar"),
        ]
    )
    files = 0
    manifest: list[str] = []
    with zipfile.ZipFile(unsigned, "a") as archive:
        archive.write(
            library,
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
    packed.write_bytes(unsigned.read_bytes())
    run([str(build_tools / "zipalign.exe"), "-p", "-f", "4", str(packed), str(aligned)])
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


if __name__ == "__main__":
    main()
