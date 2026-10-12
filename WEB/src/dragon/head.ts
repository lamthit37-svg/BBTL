import * as THREE from 'three';
import { makeEyeMaterial, makeFangMaterial, makeHornMaterial, makeLavaMaterial } from './materials';

export interface HeadRig {
  group: THREE.Group;
  jaw: THREE.Group;
  eyes: THREE.Mesh[];
  headMat: THREE.MeshStandardMaterial;
  eyeMat: THREE.MeshBasicMaterial;
  /** Toạ độ cục bộ: gốc phun lửa và lỗ mũi (xả khói). */
  mouth: THREE.Vector3;
  nose: THREE.Vector3;
  whiskerAnchors: THREE.Vector3[];
  dispose(): void;
}

const SPHERE = { width: 12, height: 10 } as const;

function addSkullPart(parent: THREE.Object3D, mat: THREE.Material, sx: number, sy: number, sz: number, x: number, y: number, z: number): THREE.Mesh {
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(0.5, SPHERE.width, SPHERE.height), mat);
  mesh.scale.set(sx, sy, sz);
  mesh.position.set(x, y, z);
  parent.add(mesh);
  return mesh;
}

function buildAntler(mat: THREE.Material, side: number): THREE.Group {
  const group = new THREE.Group();
  const main = new THREE.CatmullRomCurve3([
    new THREE.Vector3(0, 0, 0),
    new THREE.Vector3(0.12 * side, 0.5, -0.3),
    new THREE.Vector3(0.05 * side, 1.0, -0.52),
    new THREE.Vector3(0.22 * side, 1.42, -0.46),
  ]);
  group.add(new THREE.Mesh(new THREE.TubeGeometry(main, 12, 0.075, 6, false), mat));
  const branch1 = new THREE.CatmullRomCurve3([
    new THREE.Vector3(0.02 * side, 0.48, -0.14),
    new THREE.Vector3(0.34 * side, 0.78, -0.16),
    new THREE.Vector3(0.5 * side, 1.05, -0.1),
  ]);
  group.add(new THREE.Mesh(new THREE.TubeGeometry(branch1, 10, 0.048, 5, false), mat));
  const branch2 = new THREE.CatmullRomCurve3([
    new THREE.Vector3(0.04 * side, 0.95, -0.4),
    new THREE.Vector3(-0.18 * side, 1.2, -0.52),
    new THREE.Vector3(-0.3 * side, 1.38, -0.5),
  ]);
  group.add(new THREE.Mesh(new THREE.TubeGeometry(branch2, 10, 0.04, 5, false), mat));
  return group;
}

/** Lắp đầu rồng từ khối cơ bản: hộp sọ, mõm, hàm, mắt, sừng nhánh, nanh. Hướng nhìn +Z. */
export function buildHead(): HeadRig {
  const group = new THREE.Group();
  const disposables: { dispose(): void }[] = [];
  const track = <T extends { dispose(): void }>(res: T): T => {
    disposables.push(res);
    return res;
  };

  const headMat = track(makeLavaMaterial({ crackScale: 0.8, heat: 0.8, base: '#1b110a' }));
  const hornMat = track(makeHornMaterial());
  const fangMat = track(makeFangMaterial());
  const eyeMat = track(makeEyeMaterial());
  const darkMat = track(new THREE.MeshStandardMaterial({ color: '#0c0806', roughness: 0.7, metalness: 0.2 }));

  addSkullPart(group, headMat, 1.0, 0.84, 1.3, 0, 0.05, 0.15);
  addSkullPart(group, headMat, 0.64, 0.46, 1.05, 0, -0.02, 0.92);
  addSkullPart(group, headMat, 0.34, 0.24, 0.34, 0, 0.04, 1.36);
  addSkullPart(group, darkMat, 0.09, 0.06, 0.09, -0.1, 0.12, 1.46);
  addSkullPart(group, darkMat, 0.09, 0.06, 0.09, 0.1, 0.12, 1.46);

  const browGeo = track(new THREE.BoxGeometry(0.3, 0.09, 0.34));
  const browL = new THREE.Mesh(browGeo, hornMat);
  browL.position.set(-0.29, 0.33, 0.62);
  browL.rotation.z = 0.28;
  group.add(browL);
  const browR = new THREE.Mesh(browGeo, hornMat);
  browR.position.set(0.29, 0.33, 0.62);
  browR.rotation.z = -0.28;
  group.add(browR);

  const eyeGeo = track(new THREE.SphereGeometry(0.098, 10, 8));
  const eyeL = new THREE.Mesh(eyeGeo, eyeMat);
  eyeL.position.set(-0.31, 0.21, 0.7);
  const eyeR = new THREE.Mesh(eyeGeo, eyeMat);
  eyeR.position.set(0.31, 0.21, 0.7);
  group.add(eyeL, eyeR);

  const fangGeo = track(new THREE.ConeGeometry(0.05, 0.24, 6));
  for (const side of [-1, 1]) {
    const upper = new THREE.Mesh(fangGeo, fangMat);
    upper.position.set(0.17 * side, -0.16, 1.06);
    upper.rotation.x = Math.PI;
    group.add(upper);
  }

  const jaw = new THREE.Group();
  jaw.position.set(0, -0.24, 0.42);
  group.add(jaw);
  addSkullPart(jaw, headMat, 0.68, 0.3, 1.05, 0, -0.06, 0.4);
  const lowerFangGeo = track(new THREE.ConeGeometry(0.045, 0.2, 6));
  for (const side of [-1, 1]) {
    const fang = new THREE.Mesh(lowerFangGeo, fangMat);
    fang.position.set(0.16 * side, 0.08, 0.72);
    jaw.add(fang);
  }

  const antlerL = buildAntler(hornMat, -1);
  antlerL.position.set(-0.24, 0.4, -0.05);
  const antlerR = buildAntler(hornMat, 1);
  antlerR.position.set(0.24, 0.4, -0.05);
  group.add(antlerL, antlerR);

  group.scale.setScalar(1.8);

  return {
    group,
    jaw,
    eyes: [eyeL, eyeR],
    headMat,
    eyeMat,
    mouth: new THREE.Vector3(0, -0.2, 1.5),
    nose: new THREE.Vector3(0, 0.12, 1.46),
    whiskerAnchors: [new THREE.Vector3(-0.22, -0.02, 1.28), new THREE.Vector3(0.22, -0.02, 1.28)],
    dispose(): void {
      for (const res of disposables) res.dispose();
      group.traverse((obj) => {
        if (obj instanceof THREE.Mesh) obj.geometry.dispose();
      });
    },
  };
}
