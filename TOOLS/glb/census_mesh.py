# Thống kê mọi tệp .mesh của kho gốc bằng ogre_mesh.read_mesh: phiên bản, kiểu thành phần đỉnh, kiểu
# dựng hình, LOD, gán xương, chỗ bộ đọc dừng. Dùng để quyết định cách ghi GLB và làm phép thử của bộ
# đọc trên toàn bộ dữ liệu. Chỉ đọc; in kết quả dạng JSON ra stdout.
# Cách dùng: python census_mesh.py <thư mục gốc đã giải>

import json
import os
import sys
from collections import Counter
from multiprocessing import Pool

import numpy as np

import ogre_mesh

POSITION = 1
WORKERS = 16


def list_meshes(root: str) -> list[str]:
    found = []
    for folder, _, names in os.walk(root):
        for name in names:
            if name.lower().endswith(".mesh"):
                found.append(os.path.join(folder, name))
    return found


def count_geometry(geometry, tally: Counter) -> None:
    tally["geometry"] += 1
    tally["vertices"] += geometry.vertex_count
    tally[f"buffers_per_geometry={len(geometry.buffers)}"] += 1
    for element in geometry.elements:
        tally[f"element semantic={element.semantic} type={element.type} index={element.index}"] += 1
    signature = sorted((e.semantic, e.index, e.type) for e in geometry.elements)
    tally[f"layout {signature}"] += 1
    count_positions(geometry, tally)


# Vị trí không hữu hạn sẽ làm min/max của accessor GLB vô nghĩa, nên đếm riêng.
def count_positions(geometry, tally: Counter) -> None:
    element = next((e for e in geometry.elements if e.semantic == POSITION), None)
    if element is None:
        tally["geometry_without_position"] += 1
        return
    buffer = next(b for b in geometry.buffers if b.bind_index == element.source)
    raw = np.frombuffer(buffer.data, np.uint8).reshape(geometry.vertex_count, buffer.vertex_size)
    floats = raw[:, element.offset : element.offset + 12].copy().view("<f4")
    if not np.isfinite(floats).all():
        tally["geometry_with_nonfinite_position"] += 1


def count_weights(weights, vertex_count: int, tally: Counter) -> None:
    if weights is None or len(weights) == 0:
        return
    tally["weighted_geometry"] += 1
    tally["weights"] += len(weights)
    vertices = weights["vertex"].astype(np.int64)
    if vertices.max() >= vertex_count:
        tally["weight_vertex_out_of_range"] += 1
        return
    per_vertex = np.bincount(vertices, minlength=vertex_count)
    tally[f"max_influences={int(per_vertex.max())}"] += 1
    tally["vertices_without_weight"] += int((per_vertex == 0).sum())
    sums = np.bincount(vertices, weights=weights["weight"].astype(np.float64), minlength=vertex_count)
    off = np.abs(sums[per_vertex > 0] - 1.0) > 1e-3
    tally["vertices_weight_sum_off"] += int(off.sum())
    tally[f"max_bone={int(weights['bone'].max()) // 64 * 64}+"] += 1
    if (weights["weight"] <= 0).any():
        tally["geometry_with_nonpositive_weight"] += 1


def count_submesh(submesh, mesh, tally: Counter) -> None:
    tally["submeshes"] += 1
    tally["indices"] += submesh.index_count
    tally[f"operation={submesh.operation} explicit={submesh.has_operation}"] += 1
    tally[f"wide_indices={submesh.is_wide}"] += 1
    tally[f"uses_shared={submesh.uses_shared}"] += 1
    if submesh.aliases:
        tally["submesh_with_alias"] += 1
    if submesh.name is not None:
        tally["submesh_with_name"] += 1
    if submesh.index_count == 0:
        tally["submesh_without_indices"] += 1
    geometry = mesh.shared if submesh.uses_shared else submesh.geometry
    if geometry is None:
        tally["submesh_without_geometry"] += 1
        return
    if not submesh.uses_shared:
        count_geometry(geometry, tally)
        count_weights(submesh.weights, geometry.vertex_count, tally)
    width = "<u4" if submesh.is_wide else "<u2"
    indices = np.frombuffer(submesh.indices, width)
    if indices.size and int(indices.max()) >= geometry.vertex_count:
        tally["submesh_index_out_of_range"] += 1


def count_mesh(mesh, tally: Counter) -> None:
    tally[f"version {mesh.version.decode()}"] += 1
    tally[f"animated={mesh.is_animated}"] += 1
    tally[f"submesh_count={min(len(mesh.submeshes), 9)}"] += 1
    if mesh.shared is not None:
        tally["mesh_with_shared_geometry"] += 1
        count_geometry(mesh.shared, tally)
        count_weights(mesh.shared_weights, mesh.shared.vertex_count, tally)
    if mesh.skeleton is not None:
        tally["mesh_with_skeleton"] += 1
    if mesh.bounds is None:
        tally["mesh_without_bounds"] += 1
    if mesh.lod_levels:
        tally[f"lod manual={mesh.is_lod_manual} levels={len(mesh.lod_levels)}"] += 1
    for chunk_id in mesh.skipped:
        tally[f"skipped {chunk_id:#06x}"] += 1
    if mesh.stopped_at is not None:
        tally[f"stopped_at {mesh.stopped_at:#06x}"] += 1
    if mesh.trailing_bytes:
        tally[f"trailing_bytes={min(mesh.trailing_bytes, 6)}"] += 1
    for submesh in mesh.submeshes:
        count_submesh(submesh, mesh, tally)


def examine(path: str):
    tally = Counter()
    try:
        with open(path, "rb") as source:
            mesh = ogre_mesh.read_mesh(source.read())
        count_mesh(mesh, tally)
    except ogre_mesh.MeshError as error:
        return tally, (path, str(error))
    stopped = mesh.stopped_at is not None or mesh.trailing_bytes
    return tally, (path, "dừng sớm") if stopped else None


def main() -> None:
    paths = list_meshes(sys.argv[1])
    total = Counter()
    problems = []
    with Pool(WORKERS) as pool:
        for tally, problem in pool.imap_unordered(examine, paths, chunksize=64):
            total.update(tally)
            if problem:
                problems.append(problem)
    report = {"files": len(paths), "problems": len(problems), "tally": dict(sorted(total.items()))}
    report["problem_examples"] = sorted(problems)[:40]
    json.dump(report, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
