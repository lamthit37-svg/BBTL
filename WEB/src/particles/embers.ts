import * as THREE from 'three';

const VERT = /* glsl */ `
attribute float aSpeed;
attribute float aPhase;
attribute float aAmp;
uniform float uTime;
uniform float uHeight;
varying float vFade;
void main() {
  float y = mod(uTime * aSpeed + aPhase * 7.0, uHeight);
  vec3 p = vec3(
    position.x + sin(uTime * 0.4 + aPhase) * aAmp,
    y - uHeight * 0.32,
    position.z + cos(uTime * 0.33 + aPhase * 1.37) * aAmp);
  vFade = smoothstep(0.0, 5.0, y) * smoothstep(uHeight, uHeight - 7.0, y);
  vec4 mv = modelViewMatrix * vec4(p, 1.0);
  gl_PointSize = (1.6 + fract(aPhase) * 2.6) * uPixelRatio * (11.0 / max(-mv.z, 1.0));
  gl_Position = projectionMatrix * mv;
}
`;

const FRAG = /* glsl */ `
varying float vFade;
void main() {
  vec2 q = gl_PointCoord - 0.5;
  float d = length(q) * 2.0;
  float a = smoothstep(1.0, 0.1, d) * vFade * 0.75;
  gl_FragColor = vec4(vec3(1.0, 0.5, 0.14), a);
}
`;

/** Than hồng bay trong không khí — mô phỏng trọn trong vertex shader, không tốn CPU. */
export class Embers {
  readonly points: THREE.Points;

  constructor(count: number) {
    const pos = new Float32Array(count * 3);
    const speed = new Float32Array(count);
    const phase = new Float32Array(count);
    const amp = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 95;
      pos[i * 3 + 1] = 0;
      pos[i * 3 + 2] = -60 + Math.random() * 90;
      speed[i] = 0.55 + Math.random() * 1.25;
      phase[i] = Math.random() * Math.PI * 2;
      amp[i] = 0.5 + Math.random() * 1.6;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSpeed', new THREE.BufferAttribute(speed, 1));
    geo.setAttribute('aPhase', new THREE.BufferAttribute(phase, 1));
    geo.setAttribute('aAmp', new THREE.BufferAttribute(amp, 1));
    const mat = new THREE.ShaderMaterial({
      vertexShader: VERT,
      fragmentShader: FRAG,
      uniforms: { uTime: { value: 0 }, uHeight: { value: 42 }, uPixelRatio: { value: Math.min(window.devicePixelRatio, 2) } },
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
    });
    this.points = new THREE.Points(geo, mat);
    this.points.frustumCulled = false;
  }

  update(elapsed: number): void {
    (this.points.material as THREE.ShaderMaterial).uniforms.uTime.value = elapsed;
  }

  dispose(): void {
    this.points.geometry.dispose();
    (this.points.material as THREE.Material).dispose();
  }
}
