# Thống kê mọi tệp .skeleton của kho gốc bằng ogre_skeleton.read_skeleton: số xương, handle có liền
# mạch không, scale, cha con, animation, kiểu khoá, cờ, liên kết. Dùng để quyết định cách ghi GLB và
# làm phép thử của bộ đọc trên toàn bộ dữ liệu. Chỉ đọc; in JSON ra stdout.
# Cách dùng: python census_skeleton.py <thư mục gốc đã giải>

import json
import os
import sys
from collections import Counter
from multiprocessing import Pool

import numpy as np

import ogre_skeleton
from ogre_mesh import MeshError

WORKERS = 16


def list_skeletons(root: str) -> list[str]:
    found = []
    for folder, _, names in os.walk(root):
        for name in names:
            if name.lower().endswith(".skeleton"):
                found.append(os.path.join(folder, name))
    return found


def count_bones(skeleton, tally: Counter) -> None:
    handles = [bone.handle for bone in skeleton.bones]
    tally["bones"] += len(handles)
    tally[f"bone_count<={(len(handles) + 31) // 32 * 32}"] += 1
    tally[f"handles_dense_in_order={handles == list(range(len(handles)))}"] += 1
    tally[f"handles_unique={len(set(handles)) == len(handles)}"] += 1
    names = [bone.name for bone in skeleton.bones]
    tally[f"names_unique={len(set(names)) == len(names)}"] += 1
    for bone in skeleton.bones:
        if bone.scale is not None:
            tally["bone_with_scale_field"] += 1
        if bone.scale is not None and bone.scale != (1.0, 1.0, 1.0):
            tally["bone_scale_not_one"] += 1
        norm = float(np.sqrt(np.sum(np.float64(bone.orientation) ** 2)))
        if abs(norm - 1.0) > 1e-4:
            tally["bone_orientation_not_unit"] += 1


def count_parents(skeleton, tally: Counter) -> None:
    handles = {bone.handle for bone in skeleton.bones}
    children = [child for child, _ in skeleton.parents]
    tally[f"each_child_once={len(set(children)) == len(children)}"] += 1
    known = all(child in handles and parent in handles for child, parent in skeleton.parents)
    tally[f"parents_known={known}"] += 1
    tally[f"root_count={min(len(handles) - len(set(children)), 4)}"] += 1


def count_track(track, handles: set, tally: Counter) -> None:
    tally["tracks"] += 1
    tally["keys"] += len(track.times)
    tally[f"track_flags={track.flags}"] += 1
    if track.bone not in handles:
        tally["track_bone_unknown"] += 1
    if len(track.times) == 0:
        tally["track_without_keys"] += 1
        return
    if (np.diff(track.times) <= 0).any():
        tally["track_times_not_increasing"] += 1
    norms = np.sqrt((track.rotations.astype(np.float64) ** 2).sum(axis=1))
    if (np.abs(norms - 1.0) > 1e-4).any():
        tally["track_rotation_not_unit"] += 1
    values = (track.times, track.rotations, track.translations, track.scales)
    if not all(np.isfinite(value).all() for value in values):
        tally["track_nonfinite"] += 1


def count_animations(skeleton, tally: Counter) -> None:
    handles = {bone.handle for bone in skeleton.bones}
    tally["animations"] += len(skeleton.animations)
    tally[f"animation_count={min(len(skeleton.animations), 5)}"] += 1
    names = [animation.name for animation in skeleton.animations]
    tally[f"animation_names_unique={len(set(names)) == len(names)}"] += 1
    for animation in skeleton.animations:
        bones = [track.bone for track in animation.tracks]
        tally[f"one_track_per_bone={len(set(bones)) == len(bones)}"] += 1
        last = max((float(t.times[-1]) for t in animation.tracks if len(t.times)), default=0.0)
        tally[f"keys_beyond_length={last > animation.length + 1e-4}"] += 1
        for track in animation.tracks:
            count_track(track, handles, tally)


def examine(path: str):
    tally = Counter()
    try:
        with open(path, "rb") as source:
            skeleton = ogre_skeleton.read_skeleton(source.read())
    except MeshError as error:
        return tally, (path, str(error))
    count_bones(skeleton, tally)
    count_parents(skeleton, tally)
    count_animations(skeleton, tally)
    if skeleton.link_name is not None:
        tally[f"link scale={skeleton.link_scale}"] += 1
    if skeleton.stopped_at is not None:
        tally[f"stopped_at {skeleton.stopped_at:#06x}"] += 1
    if skeleton.trailing_bytes:
        tally[f"trailing_bytes={min(skeleton.trailing_bytes, 6)}"] += 1
    stopped = skeleton.stopped_at is not None or skeleton.trailing_bytes
    return tally, (path, "dừng sớm") if stopped else None


def main() -> None:
    paths = list_skeletons(sys.argv[1])
    total = Counter()
    problems = []
    with Pool(WORKERS) as pool:
        for tally, problem in pool.imap_unordered(examine, paths, chunksize=32):
            total.update(tally)
            if problem:
                problems.append(problem)
    report = {"files": len(paths), "problems": len(problems), "tally": dict(sorted(total.items()))}
    report["problem_examples"] = sorted(problems)[:40]
    json.dump(report, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
