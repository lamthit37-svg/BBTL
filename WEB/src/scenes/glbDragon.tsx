import { useAnimations, useGLTF } from '@react-three/drei';
import { useFrame, useThree } from '@react-three/fiber';
import { useEffect, useMemo, useRef } from 'react';
import * as THREE from 'three';
import { PERCH_HEAD } from './layout';
import { usePhase } from '../app/store';

/**
 * Đường dùng model GLB rig sẵn khi có tài sản thật (public/models/dragon/dragon.glb).
 * QUAN TRỌNG: chưa kiểm với model thật — tên clip đoán theo từ khoá (fly/land/idle/roar),
 * bone đầu đoán theo /head/. Khớp tên thật theo spec trong docs/TAI-SAN-3D.md.
 */
const CLIP_BY_PHASE: Record<string, string[]> = {
  intro: ['fly', 'flight', 'glide'],
  circle: ['fly', 'flight', 'glide'],
  landing: ['land', 'descend', 'perch'],
  idle: ['idle'],
  roar: ['roar', 'fire', 'breath'],
  login: ['idle'],
};

export function GlbDragonView({ url }: { url: string }) {
  const { scene, animations } = useGLTF(url);
  const camera = useThree((s) => s.camera);
  const phase = usePhase();
  const { actions } = useAnimations(animations, scene);
  const current = useRef<string | null>(null);
  const headBone = useMemo(() => {
    let found: THREE.Object3D | null = null;
    scene.traverse((obj) => {
      if (!found && /head/i.test(obj.name) && !/top|end|tip/i.test(obj.name)) found = obj;
    });
    return found as THREE.Object3D | null;
  }, [scene]);
  const headRest = useMemo(() => headBone?.quaternion.clone() ?? null, [headBone]);

  useEffect(() => {
    const wanted = CLIP_BY_PHASE[phase] ?? ['idle'];
    const name = Object.keys(actions).find((n) => wanted.some((w) => n.toLowerCase().includes(w)));
    if (!name || name === current.current) return;
    const next = actions[name];
    if (!next) return;
    next.reset().fadeIn(0.35).play();
    const prev = current.current;
    if (prev && actions[prev]) actions[prev].fadeOut(0.35);
    current.current = name;
  }, [phase, actions]);

  const _dir = useMemo(() => new THREE.Vector3(), []);
  const _m4 = useMemo(() => new THREE.Matrix4(), []);
  const _q = useMemo(() => new THREE.Quaternion(), []);

  useFrame((_, delta) => {
    if (!headBone || !headRest) return;
    _dir.copy(camera.position).sub(headBone.getWorldPosition(_dir)).normalize();
    const parentQ = headBone.parent ? headBone.parent.getWorldQuaternion(_q).invert() : _q.identity();
    _m4.lookAt(_dir, new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 1, 0));
    const lookQ = new THREE.Quaternion().setFromRotationMatrix(_m4).premultiply(parentQ);
    headBone.quaternion.copy(headRest).slerp(lookQ, Math.min(1, 3 * delta) * 0.35);
  });

  return <primitive object={scene} position={PERCH_HEAD.toArray()} />;
}
