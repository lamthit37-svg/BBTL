import * as THREE from 'three';
import { lerp } from '../app/mathx';
import { makeHornMaterial, makeLavaMaterial } from './materials';

export interface Leg {
  root: THREE.Group;
  side: number;
  front: boolean;
}

export interface LegsRig {
  group: THREE.Group;
  legs: Leg[];
  mats: { body: THREE.MeshStandardMaterial; claw: THREE.MeshStandardMaterial };
  /** tuck = 0: duỗi chân bám đá; tuck = 1: thu chân khi bay. */
  pose(tuck: number, elapsed: number): void;
  dispose(): void;
}

function buildOne(side: number, front: boolean, mats: { body: THREE.Material; claw: THREE.Material }): Leg {
  const root = new THREE.Group();
  const hip = new THREE.Group();
  root.add(hip);

  const upper = new THREE.Mesh(new THREE.CylinderGeometry(0.115, 0.09, 0.72, 8), mats.body);
  upper.position.y = -0.36;
  hip.add(upper);

  const knee = new THREE.Group();
  knee.position.y = -0.72;
  hip.add(knee);
  const lower = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.062, 0.6, 8), mats.body);
  lower.position.y = -0.3;
  knee.add(lower);

  const ankle = new THREE.Group();
  ankle.position.y = -0.6;
  knee.add(ankle);
  const paw = new THREE.Mesh(new THREE.SphereGeometry(0.13, 8, 6), mats.body);
  paw.scale.set(1.15, 0.62, 1.3);
  ankle.add(paw);
  const clawGeo = new THREE.ConeGeometry(0.032, 0.17, 5);
  for (const off of [-0.075, 0, 0.075]) {
    const claw = new THREE.Mesh(clawGeo, mats.claw);
    claw.position.set(off, 0.01, 0.13);
    claw.rotation.x = 1.85;
    ankle.add(claw);
  }

  const scale = front ? 1.0 : 0.92;
  root.scale.setScalar(scale);
  return { root, side, front };
}

/** Bốn chân vuốt: hai trước hai sau, gắn vào hai đốt thân. */
export function buildLegs(): LegsRig {
  const group = new THREE.Group();
  const bodyMat = makeLavaMaterial({ crackScale: 0.7, heat: 1.0 });
  const clawMat = makeHornMaterial();
  const legs = [
    buildOne(-1, true, { body: bodyMat, claw: clawMat }),
    buildOne(1, true, { body: bodyMat, claw: clawMat }),
    buildOne(-1, false, { body: bodyMat, claw: clawMat }),
    buildOne(1, false, { body: bodyMat, claw: clawMat }),
  ];
  for (const leg of legs) group.add(leg.root);

  return {
    group,
    legs,
    mats: { body: bodyMat, claw: clawMat },
    pose(tuck, elapsed): void {
      const k = Math.max(0, Math.min(1, tuck));
      legs.forEach((leg, i) => {
        const phase = i * 1.7;
        leg.root.children[0].rotation.x = lerp(-0.3, -1.15, k);
        const hip = leg.root.children[0];
        const knee = hip.children[1];
        knee.rotation.x = lerp(0.5, 2.05, k);
        const ankle = knee.children[1];
        ankle.rotation.x = lerp(-0.3, -1.45, k);
        hip.rotation.z = leg.side * Math.sin(elapsed * 1.9 + phase) * 0.08 * k;
      });
    },
    dispose(): void {
      bodyMat.dispose();
      clawMat.dispose();
      group.traverse((obj) => {
        if (obj instanceof THREE.Mesh) obj.geometry.dispose();
      });
    },
  };
}
