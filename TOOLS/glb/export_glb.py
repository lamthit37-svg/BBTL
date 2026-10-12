# Xuất toàn bộ model của kho gốc đã giải (thư mục _raw) sang GLB trong một lượt:
# - mọi ảnh trong Material/ thành PNG (DDS, TGA) hoặc chép nguyên (PNG, JPEG), dùng chung cho mọi GLB;
# - mọi .skeleton và .frame thành <tên gốc>.glb chứa xương và animation;
# - mọi .mesh thành <tên gốc>.glb chứa hình học, skin và material, ảnh tham chiếu bằng URI tương đối.
# Cây xuất giữ nguyên đường dẫn và tên gốc, chỉ thêm đuôi. Không đổi đơn vị, hướng hay giá trị
# (chi tiết ở convert.py, rig.py, texture.py).
# Quyết định: đích phải trống trừ khi có --resume (bỏ qua tệp đã có); tệp ghi qua tên tạm rồi đổi
# tên nên không để lại tệp dở; mỗi tệp nguồn một dòng trong <đích>.manifest.tsv, tổng hợp ở
# <đích>.report.json.
# Cách dùng: python export_glb.py <kho gốc> <đích> [--resume] [--only texture|skeleton|mesh]
#            [--match <chuỗi con của đường dẫn>] [--workers N]

import argparse
import functools
import json
import os
import shutil
import sys
import time
from collections import Counter
from multiprocessing import Pool

import convert
import ogre_material
import ogre_mesh
import ogre_skeleton
import rig
import texture

IMAGE_EXTENSIONS = (".dds", ".tga", ".png", ".jpg", ".jpeg", ".bmp")
SKELETON_EXTENSIONS = (".skeleton", ".frame")
MATERIAL_FOLDER = "Material"
MATERIAL_SCRIPTS = ("MaterialTemplates", "Material", "Scene", "OgreCore")

state = {}


def scan(root: str) -> dict:
    found = {"texture": [], "skeleton": [], "mesh": [], "material": []}
    for folder, _, names in os.walk(root):
        relative_folder = os.path.relpath(folder, root)
        top = relative_folder.split(os.sep)[0]
        for name in names:
            relative = os.path.normpath(os.path.join(relative_folder, name))
            extension = os.path.splitext(name)[1].lower()
            if extension == ".mesh":
                found["mesh"].append(relative)
            elif extension in SKELETON_EXTENSIONS:
                found["skeleton"].append(relative)
            elif extension in IMAGE_EXTENSIONS and top == MATERIAL_FOLDER:
                found["texture"].append(relative)
            elif extension == ".material" and top in MATERIAL_SCRIPTS:
                found["material"].append(relative)
    for paths in found.values():
        paths.sort()
    return found


# Thứ tự nạp script: mẫu trước (nhóm Bootstrap của client), rồi Material, Scene, OgreCore.
def load_library(root: str, scripts: list) -> ogre_material.MaterialLibrary:
    library = ogre_material.MaterialLibrary()
    order = {top: index for index, top in enumerate(MATERIAL_SCRIPTS)}
    for relative in sorted(scripts, key=lambda path: (order[path.split(os.sep)[0]], path)):
        with open(os.path.join(root, relative), "rb") as stream:
            library.load(stream.read())
    return library


def start_worker(root: str, target: str, skeletons: list, scripts: list, is_resuming: bool) -> None:
    index = {}
    for relative in skeletons:
        index.setdefault(os.path.basename(relative).lower(), []).append(relative)
    state.update(root=root, target=target, skeleton_index=index, is_resuming=is_resuming)
    state["library"] = load_library(root, scripts)


def write_atomic(path: str, data: bytes) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pending = path + ".part"
    with open(pending, "wb") as stream:
        stream.write(data)
    os.replace(pending, path)


def export_texture(relative: str, output: str) -> dict:
    source = os.path.join(state["root"], relative)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    extension = os.path.splitext(relative)[1].lower()
    if extension not in convert.PNG_SOURCES:
        shutil.copyfile(source, output + ".part")
        os.replace(output + ".part", output)
        return {"format": "chép nguyên"}
    kind, mode, width, height, note = texture.convert_to_png(source, output + ".part")
    os.replace(output + ".part", output)
    info = {"format": kind, "mode": mode, "width": width, "height": height}
    if note:
        info["warnings"] = [note]
    return info


def export_skeleton(relative: str, output: str) -> dict:
    with open(os.path.join(state["root"], relative), "rb") as stream:
        skeleton = ogre_skeleton.read_skeleton(stream.read())
    if skeleton.stopped_at is not None or skeleton.trailing_bytes:
        raise ogre_skeleton.SkeletonError("bộ đọc dừng trước cuối tệp")
    data, info = convert.skeleton_to_glb(skeleton, os.path.basename(relative))
    write_atomic(output, data)
    warnings = []
    if info["moved_keys"]:
        warnings.append(f"dời {info['moved_keys']} khoá trùng thời điểm")
    if info["empty_animations"]:
        warnings.append(f"{info['empty_animations']} animation không có kênh")
    info["warnings"] = warnings
    return info


@functools.lru_cache(maxsize=128)
def load_bones(relative: str) -> ogre_skeleton.Skeleton:
    with open(os.path.join(state["root"], relative), "rb") as stream:
        return ogre_skeleton.read_skeleton(stream.read(), is_bones_only=True)


# Skeleton mà mesh liên kết: cùng thư mục với mesh trước, rồi theo tên tệp trong cả kho.
def find_skeleton(mesh_relative: str, link: bytes) -> tuple[str | None, str]:
    name = rig.decode_name(link).replace("/", os.sep)
    beside = os.path.normpath(os.path.join(os.path.dirname(mesh_relative), name))
    if os.path.isfile(os.path.join(state["root"], beside)):
        return beside, ""
    matches = state["skeleton_index"].get(os.path.basename(name).lower(), [])
    if not matches:
        return None, f"không thấy skeleton {name}"
    note = f"skeleton {name} có {len(matches)} tệp trùng tên" if len(matches) > 1 else ""
    return matches[0], note


def export_mesh(relative: str, output: str) -> dict:
    with open(os.path.join(state["root"], relative), "rb") as stream:
        mesh = ogre_mesh.read_mesh(stream.read())
    if mesh.stopped_at is not None or mesh.trailing_bytes:
        raise ogre_mesh.MeshError("bộ đọc dừng trước cuối tệp")
    warnings = []
    skeleton = None
    if mesh.skeleton is not None:
        skeleton_path, note = find_skeleton(relative, mesh.skeleton)
        skeleton = load_bones(skeleton_path) if skeleton_path else None
        if note:
            warnings.append(note)
    material_root = os.path.join(state["root"], MATERIAL_FOLDER)
    texture_folder = os.path.join(state["target"], MATERIAL_FOLDER)
    context = convert.Context(material_root, state["library"], os.path.dirname(output), texture_folder)
    name = os.path.splitext(os.path.basename(relative))[0]
    data, info = convert.mesh_to_glb(mesh, name, skeleton, context)
    write_atomic(output, data)
    if info.pop("missing_materials"):
        warnings.append("material không có định nghĩa")
    if info.get("placeholder_bones"):
        warnings.append(f"{info['placeholder_bones']} xương giữ chỗ")
    if info.get("skipped_submeshes"):
        warnings.append(f"bỏ {info['skipped_submeshes']} submesh rỗng")
    if not info.pop("images"):
        warnings.append("không có texture nào")
    info["warnings"] = warnings
    return info


EXPORTERS = {"texture": export_texture, "skeleton": export_skeleton, "mesh": export_mesh}


def output_path(kind: str, relative: str) -> str:
    if kind == "texture":
        inside = os.path.relpath(relative, MATERIAL_FOLDER)
        return os.path.join(state["target"], MATERIAL_FOLDER, convert.texture_output(inside))
    return os.path.join(state["target"], relative + ".glb")


def export_one(task: tuple) -> dict:
    kind, relative = task
    output = output_path(kind, relative)
    row = {"kind": kind, "source": relative, "output": os.path.relpath(output, state["target"])}
    if state["is_resuming"] and os.path.isfile(output):
        row.update(status="có sẵn", bytes=os.path.getsize(output))
        return row
    try:
        row["info"] = EXPORTERS[kind](relative, output)
        row.update(status="xong", bytes=os.path.getsize(output))
    # Bắt mọi lỗi để một tệp hỏng không làm dừng cả lượt; lỗi được ghi kèm kiểu vào manifest.
    except Exception as error:  # noqa: BLE001
        row.update(status="lỗi", bytes=0, error=f"{type(error).__name__}: {error}")
    return row


def manifest_line(row: dict) -> str:
    info = row.get("info", {})
    warnings = "; ".join(info.get("warnings", []))
    fields = [row["kind"], row["source"], row["output"], row["status"], str(row["bytes"])]
    fields += [warnings, row.get("error", "")]
    return "\t".join(fields) + "\n"


def summarize(rows: list, library, seconds: float) -> dict:
    counts = Counter((row["kind"], row["status"]) for row in rows)
    sizes = Counter()
    warnings = Counter()
    for row in rows:
        sizes[row["kind"]] += row["bytes"]
        for warning in row.get("info", {}).get("warnings", []):
            warnings[(row["kind"], warning.lstrip("0123456789 "))] += 1
    summary = {"seconds": round(seconds, 1)}
    summary["counts"] = {f"{kind} {status}": count for (kind, status), count in sorted(counts.items())}
    summary["bytes"] = dict(sorted(sizes.items()))
    summary["warnings"] = {f"{kind}: {text}": count for (kind, text), count in sorted(warnings.items())}
    summary["errors"] = [[row["source"], row["error"]] for row in rows if row["status"] == "lỗi"][:200]
    summary["material_definitions"] = len(library.definitions)
    summary["material_duplicates"] = library.duplicate_count
    conflicts = [rig.decode_name(name) for name in library.conflicting_duplicates]
    summary["material_conflicting_duplicates"] = conflicts
    return summary


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Xuất model của kho gốc sang GLB")
    parser.add_argument("root")
    parser.add_argument("target")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--only", choices=sorted(EXPORTERS))
    parser.add_argument("--match")
    parser.add_argument("--workers", type=int, default=16)
    return parser.parse_args()


def is_target_usable(target: str, is_resuming: bool) -> bool:
    if is_resuming or not os.path.exists(target):
        return True
    return os.path.isdir(target) and not os.listdir(target)


def main() -> int:
    arguments = parse_arguments()
    root = os.path.abspath(arguments.root)
    target = os.path.abspath(arguments.target)
    if not is_target_usable(target, arguments.resume):
        print("Lỗi: đích đã có dữ liệu; dùng --resume để chạy tiếp", file=sys.stderr)
        return 2
    started = time.time()
    found = scan(root)
    tasks = []
    for kind in ("texture", "skeleton", "mesh"):
        if arguments.only in (None, kind):
            tasks += [(kind, path) for path in found[kind] if not arguments.match or arguments.match in path]
    print(f"Nguồn: {root}: {len(found['texture'])} ảnh, {len(found['skeleton'])} skeleton, "
          f"{len(found['mesh'])} mesh; việc cần làm: {len(tasks)}", flush=True)
    setup = (root, target, found["skeleton"], found["material"], arguments.resume)
    rows = []
    with Pool(arguments.workers, start_worker, setup) as pool:
        for row in pool.imap_unordered(export_one, tasks, chunksize=16):
            rows.append(row)
            if len(rows) % 10000 == 0:
                print(f"  {len(rows)}/{len(tasks)} sau {time.time() - started:.0f} s", flush=True)
    rows.sort(key=lambda row: (row["kind"], row["source"]))
    with open(target + ".manifest.tsv", "w", encoding="utf-8", newline="\n") as stream:
        stream.write("kind\tsource\toutput\tstatus\tbytes\twarnings\terror\n")
        stream.writelines(manifest_line(row) for row in rows)
    summary = summarize(rows, load_library(root, found["material"]), time.time() - started)
    with open(target + ".report.json", "w", encoding="utf-8", newline="\n") as stream:
        json.dump(summary, stream, ensure_ascii=False, indent=1)
    print(json.dumps({key: summary[key] for key in ("seconds", "counts", "bytes")}, ensure_ascii=False, indent=1))
    return 1 if summary["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
