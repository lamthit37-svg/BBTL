import { useFrame, useThree } from '@react-three/fiber';
import { useMemo, useRef } from 'react';
import * as THREE from 'three';
import { pointerNdc } from '../app/pointer';
import { CAMERA_DESKTOP, CAMERA_PORTRAIT } from './layout';

const _tgt = new THREE.Vector3();
const _lk = new THREE.Vector3();

/** Camera điện ảnh: lùi xa lúc mở màn rồi tiến lại, vi chuyển nhẹ theo con trỏ, bố cục dọc riêng cho mobile. */
export function CameraRig() {
  const camera = useThree((s) => s.camera);
  const size = useThree((s) => s.size);
  const look = useRef(new THREE.Vector3().copy(CAMERA_DESKTOP.look));
  const coarse = useMemo(() => window.matchMedia('(pointer: coarse)').matches, []);

  useFrame((state, dt) => {
    const portrait = size.height > size.width * 1.05;
    const base = portrait ? CAMERA_PORTRAIT : CAMERA_DESKTOP;
    const t = state.clock.elapsedTime;
    const dolly = Math.max(0, 1 - t / 10) * 4.2;
    const px = coarse ? 0 : pointerNdc.x * 0.9;
    const py = coarse ? 0 : pointerNdc.y * 0.45;
    const k = 1 - Math.exp(-1.8 * Math.min(dt, 0.05));
    _tgt.set(base.pos.x + px, base.pos.y + py, base.pos.z + dolly);
    camera.position.lerp(_tgt, k);
    _lk.set(base.look.x + px * 0.5, base.look.y + py * 0.5, base.look.z);
    look.current.lerp(_lk, k);
    camera.lookAt(look.current);
  });
  return null;
}
