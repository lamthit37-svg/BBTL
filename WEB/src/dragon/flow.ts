import * as THREE from 'three';
import { makeHornMaterial } from './materials';

const MANE_VERT = /* glsl */ `
varying float vT;
void main() {
  vT = uv.y;
#ifdef USE_INSTANCING
  vec4 wp = modelMatrix * instanceMatrix * vec4(position, 1.0);
#else
  vec4 wp = modelMatrix * vec4(position, 1.0);
#endif
  gl_Position = projectionMatrix * viewMatrix * wp;
}
`;

const MANE_FRAG = /* glsl */ `
varying float vT;
uniform float uTime;
uniform float uFlow;
void main() {
  vec3 col = mix(vec3(0.05, 0.02, 0.02), vec3(1.0, 0.4, 0.07), pow(vT, 1.7));
  col += vec3(1.0, 0.72, 0.3) * pow(vT, 5.0) * (0.45 + 0.45 * sin(uTime * 3.2 + vT * 9.0));
  float alpha = pow(vT, 1.5) * uFlow * 0.85;
  gl_FragColor = vec4(col * (0.55 + 0.75 * uFlow), alpha);
}
`;

export interface FlowRig {
  /** Nhóm gắn vào đầu rồng: bờm gáy + râu ngựa + râu dười cằm. */
  headGroup: THREE.Group;
  mane: THREE.InstancedMesh;
  whiskers: THREE.Mesh[];
  /** Ngọn lửa đuôi — rig đặt theo đốt cuối mỗi khung hình. */
  tailFlame: THREE.Mesh;
  update(elapsed: number, angularVel: number, flow: number): void;
  dispose(): void;
}

const BLADE_COUNT = 28;
const UP = new THREE.Vector3(0, 1, 0);

/** Bờm lửa (quạt sau gáy), râu hai bên mõm, ngọn lửa đuôi — đều lay theo thời gian và độ ngoặt đầu. */
export function buildFlow(): FlowRig {
  const headGroup = new THREE.Group();

  const maneMat = new THREE.ShaderMaterial({
    vertexShader: MANE_VERT,
    fragmentShader: MANE_FRAG,
    uniforms: { uTime: { value: 0 }, uFlow: { value: 1 } },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    side: THREE.DoubleSide,
  });
  const bladeGeo = new THREE.ConeGeometry(0.075, 1.25, 4, 1, true);
  bladeGeo.translate(0, 0.62, 0); // gốc quay quanh chân lưỡi lưỡi liềm
  const mane = new THREE.InstancedMesh(bladeGeo, maneMat, BLADE_COUNT);
  mane.frustumCulled = false;
  headGroup.add(mane);

  const hornMat = makeHornMaterial();
  const whiskerGeo = new THREE.TubeGeometry(new THREE.CatmullRomCurve3([new THREE.Vector3(), new THREE.Vector3(0, 0, 0.1)]), 4, 0.02, 4);
  const whiskers: THREE.Mesh[] = [];
  for (let i = 0; i < 2; i++) {
    const mesh = new THREE.Mesh(whiskerGeo, hornMat);
    mesh.frustumCulled = false;
    whiskers.push(mesh);
    headGroup.add(mesh);
  }

  const tailMat = maneMat.clone();
  const tailFlame = new THREE.Mesh(new THREE.ConeGeometry(0.16, 1.15, 8, 1, true), tailMat);
  tailFlame.geometry.translate(0, 0.55, 0);
  tailFlame.frustumCulled = false;

  const dummy = new THREE.Object3D();
  const _dir = new THREE.Vector3();

  // Vị trí gốc bờm: quạt quanh gáy hướng ra sau, thêm 5 lưỡi râu dưới cằm.
  const bases: { pos: THREE.Vector3; dir: THREE.Vector3 }[] = [];
  for (let i = 0; i < BLADE_COUNT - 5; i++) {
    const a = (-1.15 + (2.3 * i) / (BLADE_COUNT - 6)) + Math.PI / 2;
    const x = Math.cos(a) * 0.44;
    const y = Math.sin(a) * 0.4 + 0.08;
    bases.push({ pos: new THREE.Vector3(x, y, -0.18), dir: new THREE.Vector3(x * 0.9, y * 0.7, -1.05).normalize() });
  }
  for (let i = 0; i < 5; i++) {
    const x = (-0.24 + (0.48 * i) / 4) * 1.0;
    bases.push({ pos: new THREE.Vector3(x, -0.34, 0.55), dir: new THREE.Vector3(x * 1.4, -1.1, -0.35).normalize() });
  }

  const whiskerCurves = [new THREE.CatmullRomCurve3([]), new THREE.CatmullRomCurve3([])];
  const tmpPts: THREE.Vector3[] = [];
  for (let k = 0; k < 5; k++) tmpPts.push(new THREE.Vector3());

  return {
    headGroup,
    mane,
    whiskers,
    tailFlame,
    update(elapsed, angularVel, flow): void {
      maneMat.uniforms.uTime.value = elapsed;
      maneMat.uniforms.uFlow.value = flow;
      tailMat.uniforms.uTime.value = elapsed;
      tailMat.uniforms.uFlow.value = flow * 1.25;

      const trail = Math.max(-0.5, Math.min(0.5, -angularVel * 0.35));
      for (let i = 0; i < BLADE_COUNT; i++) {
        const base = bases[i];
        const sway = Math.sin(elapsed * 2.5 + i * 0.71) * 0.16 + trail;
        _dir.copy(base.dir);
        dummy.position.copy(base.pos);
        // lưỡi lửa dựng dọc trục +Y: quay trục +Y về hướng mọc của lưỡi
        dummy.quaternion.setFromUnitVectors(UP, _dir.normalize());
        dummy.rotateY(i * 2.4);
        dummy.rotateX(sway);
        const len = 0.85 + 0.3 * Math.sin(elapsed * 1.7 + i * 1.3);
        dummy.scale.set(1, len, 1);
        dummy.updateMatrix();
        mane.setMatrixAt(i, dummy.matrix);
      }
      mane.instanceMatrix.needsUpdate = true;

      // Râu: đường cong mềm theo sóng + vệt trễ theo chiều quay đầu.
      for (let s = 0; s < 2; s++) {
        const side = s === 0 ? -1 : 1;
        const anchor = tmpPts[0].set(0.2 * side, -0.02, 1.3);
        for (let k = 1; k < 5; k++) {
          const t = k / 4;
          tmpPts[k].set(
            anchor.x + side * t * 1.05,
            anchor.y - 0.28 * t * t + Math.sin(elapsed * 3.1 + t * 2.6 + s * 2.1) * 0.12 * t,
            anchor.z + t * 0.75 - trail * 0.9 * t * t,
          );
        }
        whiskerCurves[s].points = [...tmpPts.map((p) => p.clone())];
        const old = whiskers[s].geometry;
        whiskers[s].geometry = new THREE.TubeGeometry(whiskerCurves[s], 16, 0.024, 5, false);
        old.dispose();
      }

      const flick = 1 + 0.22 * Math.sin(elapsed * 13.0) + 0.1 * Math.sin(elapsed * 29.0);
      tailFlame.scale.set(flick, 1 + 0.3 * (flick - 1), flick);
    },
    dispose(): void {
      maneMat.dispose();
      tailMat.dispose();
      hornMat.dispose();
      bladeGeo.dispose();
      tailFlame.geometry.dispose();
      for (const w of whiskers) w.geometry.dispose();
    },
  };
}
