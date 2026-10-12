import * as THREE from 'three';
import { clamp01, smoothstep } from '../app/mathx';

export const CHAIN_LEN = 34;
export const SEG_LEN = 0.62;
/** Từ đốt này trở đi, thân được kéo về xoắn ốc quanh cột đá khi đậu. */
export const COIL_START = 6;

const _dir = new THREE.Vector3();
const _prevDir = new THREE.Vector3();

/** Bề rộng thân theo chỉ số đốt: cổ chắc, giữa khỏe, đuôi nhọn dần. */
export function widthAt(i: number, count: number): number {
  const t = clamp01((i + 3) / (count + 4));
  const bulge = 0.28 + 0.58 * Math.pow(Math.max(Math.sin(Math.PI * t), 0), 0.85);
  const taper = 1 - smoothstep(0.72, 1.0, t) * 0.88;
  return bulge * taper;
}

/**
 * Giữ khoảng cách giữa các đốt và uốn mượt theo hướng đoạn trước —
 * thân rắn chạy theo đầu trễ một nhịp, không giật khúc.
 */
export function relaxChain(pts: THREE.Vector3[], segLen: number, stiffness = 0.14): void {
  _prevDir.subVectors(pts[0], pts[1]).normalize();
  for (let i = 1; i < pts.length; i++) {
    _dir.subVectors(pts[i], pts[i - 1]);
    const d = _dir.length() || 1e-6;
    _dir.divideScalar(d).lerp(_prevDir, stiffness).normalize();
    pts[i].copy(pts[i - 1]).addScaledVector(_dir, segLen);
    _prevDir.copy(_dir);
  }
}

export function initialChain(head: THREE.Vector3, back: THREE.Vector3): THREE.Vector3[] {
  const pts: THREE.Vector3[] = [];
  const dir = back.clone().normalize();
  for (let i = 0; i < CHAIN_LEN; i++) pts.push(head.clone().addScaledVector(dir, i * SEG_LEN));
  return pts;
}
