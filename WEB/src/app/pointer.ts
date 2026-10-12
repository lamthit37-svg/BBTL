import { Vector2 } from 'three';

/** Vị trí con trỏ theo NDC, chia sẻ giữa React và vòng vẽ 3D. */
export const pointerNdc = new Vector2(0, 0.05);

/** Cài bộ theo dõi con trỏ toàn cửa sổ; trả hàm gỡ. */
export function installPointerTracking(): () => void {
  const onMove = (e: PointerEvent): void => {
    pointerNdc.set((e.clientX / window.innerWidth) * 2 - 1, -(e.clientY / window.innerHeight) * 2 + 1);
  };
  window.addEventListener('pointermove', onMove, { passive: true });
  return () => window.removeEventListener('pointermove', onMove);
}
