const BASE = import.meta.env.BASE_URL;

/** Tài sản bắt buộc của bản production — spec đầy đủ ở docs/TAI-SAN-3D.md. */
export const DRAGON_MODEL_URL = `${BASE}models/dragon/dragon.glb`;
export const INTRO_VIDEO_URL = `${BASE}videos/dragon_intro.webm`;
export const AUDIO_AMBIENT_URL = `${BASE}audio/ambient.webm`;
export const AUDIO_ROAR_URL = `${BASE}audio/roar.webm`;

const cache = new Map<string, Promise<boolean>>();

/**
 * Kiểm HEAD một lần rồi nhớ — dùng để bật/tắt đường dùng asset thật.
 * Máy chủ SPA fallback trả index.html (200, text/html) cho đường không có:
 * phải loại trừ text/html thì mới coi là asset thật.
 */
export function assetExists(url: string): Promise<boolean> {
  const hit = cache.get(url);
  if (hit) return hit;
  const p = fetch(url, { method: 'HEAD' })
    .then((r) => {
      if (!r.ok) return false;
      const type = r.headers.get('content-type') ?? '';
      return !type.includes('text/html');
    })
    .catch(() => false);
  cache.set(url, p);
  return p;
}
