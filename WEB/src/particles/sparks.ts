import * as THREE from 'three';

const VERT = /* glsl */ `
attribute float aLife;
attribute float aSize;
attribute float aGrav;
attribute vec3 aColor;
varying float vLife;
varying vec3 vColor;
uniform float uPixelRatio;
void main() {
  vLife = aLife;
  vColor = aColor;
  vec4 mv = modelViewMatrix * vec4(position, 1.0);
  gl_PointSize = aSize * aLife * uPixelRatio * (12.0 / max(-mv.z, 1.0));
  gl_Position = projectionMatrix * mv;
}
`;

const FRAG = /* glsl */ `
varying float vLife;
varying vec3 vColor;
void main() {
  if (vLife <= 0.0) discard;
  vec2 q = gl_PointCoord - 0.5;
  float d = length(q) * 2.0;
  float a = smoothstep(1.0, 0.15, d) * vLife;
  gl_FragColor = vec4(vColor, a);
}
`;

export interface SparkSpawn {
  origin: THREE.Vector3;
  vel: THREE.Vector3;
  life: number;
  size: number;
  gravity: number;
  color: THREE.Color;
}

/** Tia lửa bắn khỏi thân, khói mũi — hạt nhỏ với trọng lực riêng mỗi hạt. */
export class SparkField {
  readonly points: THREE.Points;
  private readonly cap: number;
  private readonly pos: Float32Array;
  private readonly vel: Float32Array;
  private readonly life: Float32Array;
  private readonly maxLife: Float32Array;
  private readonly size: Float32Array;
  private readonly grav: Float32Array;
  private readonly color: Float32Array;
  private cursor = 0;

  constructor(cap = 260) {
    this.cap = cap;
    this.pos = new Float32Array(cap * 3);
    this.vel = new Float32Array(cap * 3);
    this.life = new Float32Array(cap);
    this.maxLife = new Float32Array(cap);
    this.size = new Float32Array(cap);
    this.grav = new Float32Array(cap);
    this.color = new Float32Array(cap * 3);
    for (let i = 0; i < cap; i++) this.pos[i * 3 + 1] = -9999;

    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aLife', new THREE.BufferAttribute(this.life, 1).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aSize', new THREE.BufferAttribute(this.size, 1));
    geo.setAttribute('aGrav', new THREE.BufferAttribute(this.grav, 1));
    geo.setAttribute('aColor', new THREE.BufferAttribute(this.color, 3));
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

  spawn(s: SparkSpawn): void {
    const i = this.cursor;
    this.cursor = (this.cursor + 1) % this.cap;
    this.pos[i * 3] = s.origin.x;
    this.pos[i * 3 + 1] = s.origin.y;
    this.pos[i * 3 + 2] = s.origin.z;
    this.vel[i * 3] = s.vel.x;
    this.vel[i * 3 + 1] = s.vel.y;
    this.vel[i * 3 + 2] = s.vel.z;
    this.life[i] = 1;
    this.maxLife[i] = s.life;
    this.size[i] = s.size;
    this.grav[i] = s.gravity;
    this.color[i * 3] = s.color.r;
    this.color[i * 3 + 1] = s.color.g;
    this.color[i * 3 + 2] = s.color.b;
  }

  update(dt: number): void {
    let dirty = false;
    for (let i = 0; i < this.cap; i++) {
      if (this.life[i] <= 0) continue;
      dirty = true;
      this.life[i] -= dt / this.maxLife[i];
      if (this.life[i] <= 0) {
        this.pos[i * 3 + 1] = -9999;
        continue;
      }
      this.vel[i * 3 + 1] += this.grav[i] * dt;
      this.vel[i * 3] *= 1 - 0.6 * dt;
      this.vel[i * 3 + 2] *= 1 - 0.6 * dt;
      this.pos[i * 3] += this.vel[i * 3] * dt;
      this.pos[i * 3 + 1] += this.vel[i * 3 + 1] * dt;
      this.pos[i * 3 + 2] += this.vel[i * 3 + 2] * dt;
    }
    if (!dirty) return;
    const geo = this.points.geometry;
    (geo.getAttribute('position') as THREE.BufferAttribute).needsUpdate = true;
    (geo.getAttribute('aLife') as THREE.BufferAttribute).needsUpdate = true;
  }

  dispose(): void {
    this.points.geometry.dispose();
    (this.points.material as THREE.Material).dispose();
  }
}
