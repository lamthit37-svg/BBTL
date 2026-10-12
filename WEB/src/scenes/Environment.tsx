import { useFrame } from '@react-three/fiber';
import { useEffect, useMemo } from 'react';
import * as THREE from 'three';
import { mulberry32 } from '../app/mathx';
import { makeLavaMaterial } from '../dragon/materials';
import { Embers } from '../particles/embers';
import { SPIRE_CENTER, SPIRE_TOP } from './layout';

function SkyDome() {
  const mat = useMemo(
    () =>
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        fog: false,
        vertexShader: /* glsl */ `
varying vec3 vDir;
void main() {
  vDir = position;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`,
        fragmentShader: /* glsl */ `
varying vec3 vDir;
void main() {
  vec3 d = normalize(vDir);
  float h = d.y;
  vec3 top = vec3(0.045, 0.018, 0.038);
  vec3 mid = vec3(0.19, 0.05, 0.028);
  vec3 bot = vec3(0.012, 0.008, 0.012);
  vec3 col = h > 0.0 ? mix(mid, top, pow(h, 0.42)) : mix(mid, bot, pow(min(-h, 1.0), 0.5));
  vec3 sp = floor(d * 320.0);
  float star = step(0.9997, fract(sin(dot(sp, vec3(12.98, 78.23, 37.7))) * 43758.5));
  col += vec3(0.9, 0.85, 0.8) * star * smoothstep(0.12, 0.55, h) * 0.55;
  gl_FragColor = vec4(col, 1.0);
}
`,
      }),
    [],
  );
  useEffect(() => () => mat.dispose(), [mat]);
  return (
    <mesh material={mat} renderOrder={-10}>
      <sphereGeometry args={[430, 24, 16]} />
    </mesh>
  );
}

function Mountains() {
  const { group, dispose } = useMemo(() => {
    const g = new THREE.Group();
    const rng = mulberry32(7);
    const nearMat = new THREE.MeshStandardMaterial({ color: '#181119', roughness: 1, flatShading: true });
    const farMat = new THREE.MeshStandardMaterial({ color: '#231823', roughness: 1, flatShading: true });
    const geos: THREE.BufferGeometry[] = [];
    const mats = [nearMat, farMat];

    const addPeak = (angle: number, dist: number, height: number, rBase: number, far: boolean): void => {
      const geo = new THREE.ConeGeometry(rBase, height, 5 + Math.floor(rng() * 3), 4);
      const pos = geo.attributes.position as THREE.BufferAttribute;
      for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        const z = pos.getZ(i);
        const n = Math.sin(x * 12.9898 + z * 78.233) * 43758.5453;
        const jitter = (n - Math.floor(n)) - 0.5;
        pos.setX(i, x + jitter * 3.6);
        pos.setZ(i, z + jitter * 3.6);
        pos.setY(i, pos.getY(i) + jitter * 1.6);
      }
      geos.push(geo);
      const mesh = new THREE.Mesh(geo, far ? farMat : nearMat);
      mesh.position.set(Math.cos(angle) * dist, height / 2 - 4, Math.sin(angle) * dist);
      mesh.rotation.y = rng() * Math.PI;
      g.add(mesh);
    };

    // Hai đỉnh có bàn đá để dựng điện cổ.
    addPeak(3.75, 58, 24, 15, false);
    addPeak(5.35, 76, 17, 12, false);
    // Chừa quang cảnh phía cột đá (góc ~0.07 rad) để long nổi trên trời cháy.
    for (let i = 0; i < 11; i++) {
      const angle = (i / 11) * Math.PI * 2 + rng() * 0.3;
      const offset = Math.abs(Math.atan2(Math.sin(angle - 0.07), Math.cos(angle - 0.07)));
      if (offset < 0.55) continue;
      addPeak(angle, 64 + rng() * 46, 15 + rng() * 17, 13 + rng() * 14, false);
    }
    for (let i = 0; i < 7; i++) {
      const angle = (i / 7) * Math.PI * 2 + 0.22;
      addPeak(angle, 132 + rng() * 30, 44 + rng() * 26, 26 + rng() * 14, true);
    }
    return {
      group: g,
      dispose: () => {
        geos.forEach((geo) => geo.dispose());
        mats.forEach((m) => m.dispose());
      },
    };
  }, []);
  useEffect(() => () => dispose(), [dispose]);
  return <primitive object={group} />;
}

function makeCloudTexture(): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 128;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    for (let i = 0; i < 46; i++) {
      const x = Math.random() * 256;
      const y = 30 + Math.random() * 68;
      const r = 12 + Math.random() * 30;
      const grad = ctx.createRadialGradient(x, y, 0, x, y, r);
      grad.addColorStop(0, 'rgba(255,255,255,0.10)');
      grad.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(x, y, r, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  return new THREE.CanvasTexture(canvas);
}

function CloudSea({ count }: { count: number }) {
  const { group, dispose } = useMemo(() => {
    const g = new THREE.Group();
    const tex = makeCloudTexture();
    const geo = new THREE.PlaneGeometry(1, 1);
    const clouds: { mesh: THREE.Mesh; speed: number }[] = [];
    for (let i = 0; i < count; i++) {
      const mat = new THREE.MeshBasicMaterial({
        map: tex,
        transparent: true,
        opacity: 0.55 + Math.random() * 0.25,
        depthWrite: false,
        color: '#6a5158',
      });
      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      const s = 26 + Math.random() * 46;
      mesh.scale.set(s, s * 0.5, 1);
      mesh.position.set((Math.random() - 0.5) * 150, 0.5 + Math.random() * 4.5, -60 + Math.random() * 55);
      clouds.push({ mesh, speed: 0.25 + Math.random() * 0.7 });
      g.add(mesh);
    }
    return {
      group: g,
      dispose: () => {
        tex.dispose();
        geo.dispose();
        clouds.forEach((c) => (c.mesh.material as THREE.Material).dispose());
      },
    };
  }, [count]);
  useFrame((_, dt) => {
    group.children.forEach((child) => {
      child.position.x += dt * 0.4;
      if (child.position.x > 90) child.position.x = -90;
    });
  });
  useEffect(() => () => dispose(), [dispose]);
  return <primitive object={group} />;
}

function buildTemple(scale: number): { group: THREE.Group; disposables: { dispose(): void }[] } {
  const group = new THREE.Group();
  const disposables: { dispose(): void }[] = [];
  const dark = new THREE.MeshStandardMaterial({ color: '#0c0808', roughness: 0.9 });
  const glow = new THREE.MeshBasicMaterial({ color: new THREE.Color(2.4, 1.15, 0.38), toneMapped: false });
  disposables.push(dark, glow);
  const box = new THREE.BoxGeometry(1, 1, 1);
  const roof = new THREE.ConeGeometry(0.78, 0.5, 4);
  const win = new THREE.PlaneGeometry(0.34, 0.5);
  disposables.push(box, roof, win);
  let y = 0;
  const widths = [3.4, 2.55, 1.75];
  for (const w of widths) {
    const tier = new THREE.Mesh(box, dark);
    tier.scale.set(w, 1.05, w * 0.85);
    tier.position.y = y + 0.52;
    group.add(tier);
    const window1 = new THREE.Mesh(win, glow);
    window1.position.set(-w * 0.22, y + 0.55, w * 0.43);
    const window2 = new THREE.Mesh(win, glow);
    window2.position.set(w * 0.22, y + 0.55, w * 0.43);
    group.add(window1, window2);
    y += 1.05;
    const cap = new THREE.Mesh(roof, dark);
    cap.scale.set(w * 1.25, 1, w * 1.1);
    cap.rotation.y = Math.PI / 4;
    cap.position.y = y + 0.24;
    group.add(cap);
    y += 0.48;
  }
  const finial = new THREE.Mesh(roof, dark);
  finial.scale.set(0.5, 1.4, 0.5);
  finial.rotation.y = Math.PI / 4;
  finial.position.y = y + 0.32;
  group.add(finial);
  group.scale.setScalar(scale);
  return { group, disposables };
}

function Temples() {
  const { group, dispose } = useMemo(() => {
    const g = new THREE.Group();
    const all: { dispose(): void }[] = [];
    const a = buildTemple(2.3);
    a.group.position.set(-34, 21.5, -44);
    a.group.rotation.y = 0.55;
    const b = buildTemple(1.5);
    b.group.position.set(44, 14.5, -58);
    b.group.rotation.y = -0.4;
    g.add(a.group, b.group);
    all.push(...a.disposables, ...b.disposables);
    return { group: g, dispose: () => all.forEach((d) => d.dispose()) };
  }, []);
  useEffect(() => () => dispose(), [dispose]);
  return <primitive object={group} />;
}

function Spire() {
  const { group, dispose } = useMemo(() => {
    const g = new THREE.Group();
    const geos: THREE.BufferGeometry[] = [];
    const mats: THREE.Material[] = [];
    const rockMat = makeLavaMaterial({ crackScale: 0.22, heat: 0.3, base: '#1a1216', roughness: 0.8, metalness: 0.15, variation: 0.12 });
    rockMat.flatShading = true;
    mats.push(rockMat);

    const h = SPIRE_TOP + 3;
    const body = new THREE.CylinderGeometry(2.1, 4.6, h, 9, 7);
    const pos = body.attributes.position as THREE.BufferAttribute;
    for (let i = 0; i < pos.count; i++) {
      if (pos.getY(i) > h / 2 - 1.1) continue; // giữ miệng đỉnh tròn để long đậu
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const n = Math.sin(x * 1.7 + pos.getY(i) * 0.9) * Math.cos(z * 1.9 - pos.getY(i) * 0.7);
      const k = 1 + n * 0.24;
      pos.setX(i, x * k);
      pos.setZ(i, z * k);
    }
    body.computeVertexNormals();
    geos.push(body);
    const bodyMesh = new THREE.Mesh(body, rockMat);
    bodyMesh.position.set(SPIRE_CENTER.x, h / 2 - 3, SPIRE_CENTER.z);
    g.add(bodyMesh);

    const slab = new THREE.CylinderGeometry(2.6, 2.1, 0.9, 9);
    geos.push(slab);
    const slabMesh = new THREE.Mesh(slab, rockMat);
    slabMesh.position.set(SPIRE_CENTER.x, SPIRE_TOP - 0.42, SPIRE_CENTER.z);
    g.add(slabMesh);

    // Vài tảng đá bay lơ lửng quanh cột — đá núi lửa phát sáng
    const rng = mulberry32(21);
    for (let i = 0; i < 4; i++) {
      const geo = new THREE.DodecahedronGeometry(0.5 + rng() * 0.7);
      geos.push(geo);
      const rock = new THREE.Mesh(geo, rockMat);
      rock.position.set(SPIRE_CENTER.x + (rng() - 0.5) * 9, 5 + rng() * 6, SPIRE_CENTER.z + (rng() - 0.5) * 9);
      rock.userData.baseY = rock.position.y;
      rock.userData.phase = rng() * Math.PI * 2;
      g.add(rock);
    }

    const light = new THREE.PointLight('#ff5a1e', 90, 30, 2);
    light.position.set(SPIRE_CENTER.x, SPIRE_TOP + 0.4, SPIRE_CENTER.z);
    g.add(light);
    return {
      group: g,
      dispose: () => {
        geos.forEach((geo) => geo.dispose());
        mats.forEach((m) => m.dispose());
      },
    };
  }, []);
  useFrame((state) => {
    const t = state.clock.elapsedTime;
    group.children.forEach((child) => {
      if (child instanceof THREE.Mesh && child.userData.baseY !== undefined) {
        child.position.y = child.userData.baseY + Math.sin(t * 0.5 + child.userData.phase) * 0.4;
        child.rotation.y += 0.0015;
      }
    });
  });
  useEffect(() => () => dispose(), [dispose]);
  return <primitive object={group} />;
}

function LavaSea() {
  const { mesh, dispose } = useMemo(() => {
    const mat = makeLavaMaterial({ crackScale: 0.045, heat: 0.3, base: '#0d0709', roughness: 0.9, metalness: 0.1, variation: 0.3 });
    const geo = new THREE.PlaneGeometry(700, 700);
    const m = new THREE.Mesh(geo, mat);
    m.rotation.x = -Math.PI / 2;
    m.position.y = -46;
    return { mesh: m, dispose: () => { geo.dispose(); mat.dispose(); } };
  }, []);
  useEffect(() => () => dispose(), [dispose]);
  return <primitive object={mesh} />;
}

function EmberField({ count }: { count: number }) {
  const embers = useMemo(() => new Embers(count), [count]);
  useEffect(() => () => embers.dispose(), [embers]);
  useFrame((state) => embers.update(state.clock.elapsedTime));
  return <primitive object={embers.points} />;
}

export function Environment({ quality }: { quality: 'high' | 'low' }) {
  const high = quality === 'high';
  return (
    <group>
      <SkyDome />
      <Mountains />
      <CloudSea count={high ? 18 : 10} />
      <Temples />
      <Spire />
      <LavaSea />
      <EmberField count={high ? 420 : 150} />
      <ambientLight intensity={0.8} color="#4a3020" />
      <directionalLight position={[-28, 46, 22]} intensity={2.2} color="#a9bede" />
      <directionalLight position={[6, 18, -42]} intensity={0.7} color="#ff8a4a" />
    </group>
  );
}
