# Đóng APK native (NativeActivity, không Gradle) từ libthienlong.so.
# --data là thư mục dev/client/assets: đóng Config, cảnh Config/startup.id, hai cảnh của thủ tục
# đăng nhập (erengu_DL, tl3chuangjian — tên đọc từ header C++), giao diện Interface/ui.files.tsv
# và Web/coming_soon.html khi tệp đó có.
# Cả cây data vượt 4 GB, zipalign không mở được ZIP64.
# --shaders đóng gói .f2s vào assets/shaders. --stage chép cùng tập cảnh ra một thư mục (bundle iOS).
# Thiết bị giải nén hai thư mục này ra bộ nhớ nội bộ ở lần chạy đầu.
# --depfile ghi mọi tệp và thư mục đã đọc theo cú pháp depfile của Ninja: thiếu nó thì hệ dựng không
# biết dữ liệu đổi và giữ APK cũ (đã gặp: thêm tệp vào danh sách cảnh mà APK không đóng lại).
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import zipfile
from pathlib import Path


# Mọi tệp và thư mục lần chạy này đã đọc, cho --depfile.
read_inputs: list[Path] = []


def read_resid(data: Path) -> str:
    path = data / "Config" / "startup.id"
    if not path.is_file():
        raise SystemExit(f"đóng gói: không có {path}")
    text = path.read_text(encoding="utf-8").strip()
    if not text.isdigit():
        raise SystemExit(f"đóng gói: Config/startup.id không phải resid ({text})")
    return text


def scene_file_of(data: Path, resid: str) -> str:
    table = data / "Config" / "SceneDefineEx.txt"
    if not table.is_file():
        raise SystemExit(f"đóng gói: không có {table}")
    for raw in table.read_bytes().splitlines():
        if not raw or raw.startswith(b"#"):
            continue
        cells = raw.split(b"\t")
        if len(cells) < 5:
            continue
        if cells[0] in (b"INT", b"STRING"):
            continue
        try:
            label = cells[0].decode("ascii")
        except UnicodeDecodeError:
            continue
        if label != resid:
            continue
        try:
            return cells[4].decode("ascii")
        except UnicodeDecodeError as error:
            raise SystemExit("đóng gói: tên file cảnh không phải ASCII") from error
    raise SystemExit(f"đóng gói: bảng cảnh không có resid {resid}")


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


def quoted_constant(path: Path, symbol: str) -> str:
    # inline constexpr std::string_view <symbol> = "..."; trong header C++. Đọc ở đây để APK
    # không lệch tên cảnh mà client nạp.
    read_inputs.append(path)
    marker = f"constexpr std::string_view {symbol} = \""
    name = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line == "" or line.startswith("//"):
            continue
        at = line.find(marker)
        if at < 0:
            continue
        start = at + len(marker)
        end = line.find("\"", start)
        if end < 0:
            raise SystemExit(f"đóng gói: {symbol} không có chuỗi đóng")
        name = line[start:end]
        break
    if name == "" and marker not in path.read_text(encoding="utf-8"):
        raise SystemExit(f"đóng gói: không thấy {symbol} trong {path}")
    if name == "" or "/" in name or "\\" in name or ":" in name or name in (".", ".."):
        raise SystemExit(f"đóng gói: {symbol} không phải tên cảnh ({name})")
    return name


def login_scene_stems() -> list[str]:
    # Tệp này nằm ở android/, một cấp dưới gốc repo.
    root = Path(__file__).resolve().parents[1]
    control = root / "src" / "client" / "figure" / "control"
    login = quoted_constant(control / "login_view.hpp", "kLoginScene")
    role = quoted_constant(control / "char_camera.hpp", "kRoleScene")
    return [login, role]


def scene_listing(data: Path, stem: str) -> list[str]:
    listing = data / "Scene" / f"{stem}.files.tsv"
    if not listing.is_file():
        raise SystemExit(f"đóng gói: thiếu {listing}. Chạy collect_map cho cảnh {stem} trước.")
    return listed_paths(listing)


def extend_unique(paths: list[str], seen: set[str], more: list[str]) -> None:
    for relative in more:
        if relative in seen:
            continue
        seen.add(relative)
        paths.append(relative)


def web_paths(data: Path) -> list[str]:
    relative = "Web/coming_soon.html"
    path = data / relative
    if not path.is_file():
        return []
    read_inputs.append(path)
    return [relative]


def ui_paths(data: Path) -> list[str]:
    # Giao diện HUD (collect_ui.py). Không có danh sách thì APK không có bảng, client vẫn chạy.
    listing = data / "Interface" / "ui.files.tsv"
    if not listing.is_file():
        return []
    paths = listed_paths(listing)
    font = "Interface/Schema/VTNAM14.bin"
    if font not in paths and (data / font).is_file():
        paths.append(font)
    return paths


def config_paths(data: Path) -> list[str]:
    # Bảng của client 2026 mà client đọc lúc chạy ngoài bảng cảnh: trần kinh nghiệm theo cấp (HUD).
    # Do TOOLS/content/collect_sound.py chép vào. Thiếu thì client giữ trần cấp 1 và in lỗi.
    found = []
    for relative in ("Config/PlayerExpLevel.txt",):
        path = data / relative
        if path.is_file():
            read_inputs.append(path)
            found.append(relative)
    return found


def scene_paths(data: Path, has_cooked_sound: bool) -> list[str]:
    # Cả thư mục data là mọi map (hàng GB). APK và bundle mang cảnh startup.id cộng hai cảnh
    # thủ tục đăng nhập. Danh sách mỗi cảnh là Scene/<tên>.files.tsv do collect_map ghi.
    resid = read_resid(data)
    scene_file = scene_file_of(data, resid)
    stems = [Path(scene_file).stem]
    for stem in login_scene_stems():
        if stem not in stems:
            stems.append(stem)
    paths = ["Config/startup.id", "Config/SceneDefineEx.txt"]
    seen = set(paths)
    for stem in stems:
        extend_unique(paths, seen, scene_listing(data, stem))
    extend_unique(paths, seen, avatar_paths(data))
    extend_unique(paths, seen, audio_paths(data, has_cooked_sound))
    extend_unique(paths, seen, ui_paths(data))
    extend_unique(paths, seen, web_paths(data))
    extend_unique(paths, seen, config_paths(data))
    return paths


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


def add_listed(archive: zipfile.ZipFile, data: Path, manifest: list[str],
               has_cooked_sound: bool) -> int:
    count = 0
    for relative in scene_paths(data, has_cooked_sound):
        source = data / relative
        if not source.is_file():
            raise SystemExit(f"đóng gói: thiếu tệp cảnh {source}")
        manifest.append(add_asset(archive, source, "data", "D", relative))
        count += 1
    return count


def stage_scene(data: Path, dest: Path) -> None:
    count = 0
    for relative in scene_paths(data, False):
        source = data / relative
        if not source.is_file():
            raise SystemExit(f"đóng gói: thiếu tệp cảnh {source}")
        target = dest / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        count += 1
    print(f"đóng gói: đã dựng {count} tệp cảnh vào {dest}")


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
    parser.add_argument("--depfile", default="", help="ghi depfile của --out cho Ninja")
    args = parser.parse_args()
    if args.stage:
        if not args.data:
            raise SystemExit("đóng gói: --stage cần --data")
        stage_scene(Path(args.data), Path(args.stage))
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
            files += add_listed(archive, Path(args.data), manifest, bool(args.sound))
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
