import * as THREE from 'three';

const VERT = /* glsl */ `
attribute float aLife;
attribute float aSeed;
varying float vLife;
uniform float uPixelRatio;
void main() {
  vLife = aLife;
  vec4 mv = modelViewMatrix * vec4(position, 1.0);
  float size = (10.0 + 48.0 * (1.0 - aLife)) * (1.0 + aSeed * 0.7);
  gl_PointSize = size * uPixelRatio * (13.0 / max(-mv.z, 1.0));
  gl_Position = projectionMatrix * mv;
}
`;

const FRAG = /* glsl */ `
varying float vLife;
void main() {
  if (vLife <= 0.0) discard;
  vec2 q = gl_PointCoord - 0.5;
  float d = length(q) * 2.0;
  float a = smoothstep(1.0, 0.08, d) * smoothstep(0.0, 0.16, vLife);
  float t = 1.0 - vLife;
  vec3 col = t < 0.32
    ? mix(vec3(1.0, 0.92, 0.6), vec3(1.0, 0.45, 0.07), t / 0.32)
    : mix(vec3(1.0, 0.45, 0.07), vec3(0.42, 0.05, 0.02), (t - 0.32) / 0.68);
  gl_FragColor = vec4(col * (0.9 + 1.5 * vLife), a);
}
`;

/** Hơi thở lửa: hạt sinh từ mõm theo hướng nhìn, loãng ra và bốc lên. */
export class FireBreath {
  readonly points: THREE.Points;
  private readonly cap: number;
  private readonly pos: Float32Array;
  private readonly vel: Float32Array;
  private readonly life: Float32Array;
  private readonly seed: Float32Array;
  private cursor = 0;
  private acc = 0;
  private alive = 0;
  active = false;

  constructor(cap = 560) {
    this.cap = cap;
    this.pos = new Float32Array(cap * 3);
    this.vel = new Float32Array(cap * 3);
    this.life = new Float32Array(cap);
    this.seed = new Float32Array(cap);
    for (let i = 0; i < cap; i++) this.pos[i * 3 + 1] = -9999;

    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aLife', new THREE.BufferAttribute(this.life, 1).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(this.seed, 1));
    const mat = new THREE.ShaderMaterial({
      vertexShader: VERT,
      fragmentShader: FRAG,
      uniforms: { uPixelRatio: { value: Math.min(window.devicePixelRatio, 2) } },
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    this.points = new THREE.Points(geo, mat);
    this.points.frustumCulled = false;
  }

  emit(origin: THREE.Vector3, dir: THREE.Vector3, dt: number): void {
    if (!this.active) return;
    this.acc += dt * 330;
    let n = Math.floor(this.acc);
    this.acc -= n;
    n = Math.min(n, 40);
    for (let k = 0; k < n; k++) {
      const i = this.cursor;
      this.cursor = (this.cursor + 1) % this.cap;
      if (this.life[i] <= 0) this.alive++;
      const speed = 15 + Math.random() * 9;
      this.pos[i * 3] = origin.x + (Math.random() - 0.5) * 0.14;
      this.pos[i * 3 + 1] = origin.y + (Math.random() - 0.5) * 0.14;
      this.pos[i * 3 + 2] = origin.z + (Math.random() - 0.5) * 0.14;
      this.vel[i * 3] = dir.x * speed + (Math.random() - 0.5) * 3.2;
      this.vel[i * 3 + 1] = dir.y * speed + (Math.random() - 0.5) * 3.2 + 1.4;
      this.vel[i * 3 + 2] = dir.z * speed + (Math.random() - 0.5) * 3.2;
      this.life[i] = 1;
      this.seed[i] = Math.random();
    }
  }

  update(dt: number): void {
    if (this.alive === 0) return;
    const drag = Math.max(0, 1 - 1.7 * dt);
    let alive = 0;
    for (let i = 0; i < this.cap; i++) {
      if (this.life[i] <= 0) continue;
      this.life[i] -= dt * 1.12;
      if (this.life[i] <= 0) {
        this.pos[i * 3 + 1] = -9999;
        continue;
      }
      alive++;
      this.vel[i * 3] *= drag;
      this.vel[i * 3 + 1] = this.vel[i * 3 + 1] * drag + 2.6 * dt;
      this.vel[i * 3 + 2] *= drag;
      this.pos[i * 3] += this.vel[i * 3] * dt;
      this.pos[i * 3 + 1] += this.vel[i * 3 + 1] * dt;
      this.pos[i * 3 + 2] += this.vel[i * 3 + 2] * dt;
    }
    this.alive = alive;
    const geo = this.points.geometry;
    (geo.getAttribute('position') as THREE.BufferAttribute).needsUpdate = true;
    (geo.getAttribute('aLife') as THREE.BufferAttribute).needsUpdate = true;
  }

  dispose(): void {
    this.points.geometry.dispose();
    (this.points.material as THREE.Material).dispose();
  }
}
