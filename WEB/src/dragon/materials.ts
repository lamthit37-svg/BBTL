import * as THREE from 'three';
import { GLSL_NOISE } from '../shaders/noise';

/** Đồng hồ dùng chung cho mọi vật liệu lava — rig cập nhật một lần mỗi khung hình. */
export const lavaClock = { value: 0 };

export interface LavaOptions {
  crackScale?: number;
  heat?: number;
  base?: string;
  metalness?: number;
  roughness?: number;
  /** Biên độ loang albedo — mặt lớn (đá, sàn) để 0.1–0.2, thân rồng 0.4. */
  variation?: number;
}

/**
 * Giáp núi lửa: nền đen obsidian, khe nứt phát sáng theo nhiễu fbm,
 * viền fresnel ấm do nhiệt. Dùng được cho cả InstancedMesh lẫn mesh thường.
 */
export function makeLavaMaterial(options: LavaOptions = {}): THREE.MeshStandardMaterial {
  const crackScale = options.crackScale ?? 0.55;
  const metalness = options.metalness ?? 0.35;
  const roughness = options.roughness ?? 0.55;
  const variation = options.variation ?? 0.4;
  const uHeat = { value: options.heat ?? 1.0 };
  const mat = new THREE.MeshStandardMaterial({
    color: new THREE.Color(options.base ?? '#191009'),
    metalness,
    roughness,
  });
  mat.userData.uHeat = uHeat;
  mat.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = lavaClock;
    shader.uniforms.uHeat = uHeat;
    shader.uniforms.uCrackScale = { value: crackScale };
    shader.uniforms.uVariation = { value: variation };
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', '#include <common>\nvarying vec3 vBodyPos;')
      .replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
#ifdef USE_INSTANCING
  vBodyPos = (modelMatrix * instanceMatrix * vec4(position, 1.0)).xyz;
#else
  vBodyPos = (modelMatrix * vec4(position, 1.0)).xyz;
#endif`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace(
        '#include <common>',
        `#include <common>
varying vec3 vBodyPos;
uniform float uTime;
uniform float uHeat;
uniform float uCrackScale;
uniform float uVariation;
${GLSL_NOISE}`,
      )
      .replace(
        '#include <color_fragment>',
        `#include <color_fragment>
diffuseColor.rgb *= 1.0 - uVariation * 0.5 + uVariation * fbm(vBodyPos * uCrackScale * 0.45 + 3.7);`,
      )
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
{
  vec3 np = vBodyPos * uCrackScale;
  float n = fbm(np + vec3(0.0, -uTime * 0.1, uTime * 0.045));
  float vein = 1.0 - abs(n * 2.0 - 1.0);
  float crack = pow(smoothstep(0.8, 0.995, vein), 1.5);
  float pulse = 0.7 + 0.3 * sin(uTime * 1.8 + vBodyPos.y * 2.0 + vBodyPos.x * 1.3);
  float glow = crack * pulse * uHeat;
  vec3 lavaCol = mix(vec3(0.55, 0.09, 0.01), vec3(1.0, 0.48, 0.09), glow);
  vec3 viewDir = normalize(vViewPosition);
  // Dùng biến normal có sẵn (flat-shading tính bằng derivative) — đừng dùng vNormal vì mất khi FLAT_SHADED.
  float rim = pow(1.0 - clamp(dot(normal, viewDir), 0.0, 1.0), 3.0);
  totalEmissiveRadiance += vec3(0.38, 0.09, 0.02) * 0.24 * uHeat;
  totalEmissiveRadiance += lavaCol * glow * 1.7 + vec3(1.0, 0.32, 0.07) * rim * 0.55 * uHeat;
}`,
      );
  };
  mat.customProgramCacheKey = () => `lava-${crackScale.toFixed(3)}-${variation.toFixed(2)}`;
  return mat;
}

/** Mắt hổ phách: giá trị HDR > 1 để nở sáng qua bloom. */
export function makeEyeMaterial(): THREE.MeshBasicMaterial {
  return new THREE.MeshBasicMaterial({ color: new THREE.Color(3.4, 1.0, 0.22), toneMapped: false });
}

export function makeHornMaterial(): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({ color: '#241a12', metalness: 0.45, roughness: 0.42 });
}

export function makeFangMaterial(): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({ color: '#d8cbae', metalness: 0.1, roughness: 0.35 });
}
