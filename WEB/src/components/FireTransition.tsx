import { useEffect, useRef } from 'react';
import { isPhotoMode, usePhase } from '../app/store';

interface Flame {
  x: number;
  y: number;
  vx: number;
  vy: number;
  r: number;
  life: number;
  max: number;
}

/**
 * Chuyển cảnh lửa che toàn màn khi long gầm: canvas 2D vệt lửa bốc từ dưới lên,
 * rồi tan ra nhường chỗ cho bảng đăng nhập. Không chạy khi bật giảm chuyển động.
 */
export function FireTransition() {
  const phase = usePhase();
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const burning = phase === 'roar';

  useEffect(() => {
    if (!burning) return;
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;

    const dpr = Math.min(window.devicePixelRatio, 2);
    const resize = () => {
      canvas.width = Math.floor(window.innerWidth * dpr);
      canvas.height = Math.floor(window.innerHeight * dpr);
    };
    resize();
    window.addEventListener('resize', resize);

    const flames: Flame[] = [];
    let raf = 0;
    let running = true;
    let last = performance.now();
    let elapsed = 0;

    const spawnBottom = (n: number): void => {
      const w = canvas.width;
      const h = canvas.height;
      for (let i = 0; i < n; i++) {
        flames.push({
          x: Math.random() * w,
          y: h + 24 * dpr,
          vx: (Math.random() - 0.5) * 26 * dpr,
          vy: -h * (0.3 + Math.random() * 0.42),
          r: (26 + Math.random() * 58) * dpr,
          life: 0,
          max: 1.25 + Math.random() * 0.8,
        });
      }
    };
    const spawnBurst = (): void => {
      const w = canvas.width;
      const h = canvas.height;
      flames.push({
        x: w * (0.42 + Math.random() * 0.16),
        y: h * 0.6,
        vx: (Math.random() - 0.5) * w * 0.3,
        vy: -h * (0.3 + Math.random() * 0.45),
        r: (34 + Math.random() * 70) * dpr,
        life: 0,
        max: 1.1 + Math.random() * 0.7,
      });
    };

    const stepFrame = (dt: number): void => {
      elapsed += dt;
      if (flames.length < 240) {
        spawnBottom(2);
        if (elapsed < 1.5 && Math.random() < 0.55) spawnBurst();
      }
      ctx.globalCompositeOperation = 'source-over';
      ctx.fillStyle = 'rgba(22, 5, 2, 0.16)';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.globalCompositeOperation = 'lighter';
      for (let i = flames.length - 1; i >= 0; i--) {
        const f = flames[i];
        f.life += dt;
        if (f.life >= f.max) {
          flames.splice(i, 1);
          continue;
        }
        f.x += f.vx * dt;
        f.y += f.vy * dt;
        f.vx *= 1 - 0.7 * dt;
        f.vy *= 1 - 0.5 * dt;
        const t = f.life / f.max;
        const r = f.r * (0.55 + t * 0.95);
        const alpha = (1 - t) * 0.5;
        const grad = ctx.createRadialGradient(f.x, f.y, 0, f.x, f.y, r);
        grad.addColorStop(0, `rgba(255, ${Math.max(70, 170 - Math.floor(t * 110))}, 42, ${alpha})`);
        grad.addColorStop(0.55, `rgba(215, 62, 12, ${alpha * 0.55})`);
        grad.addColorStop(1, 'rgba(58, 8, 4, 0)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(f.x, f.y, r, 0, Math.PI * 2);
        ctx.fill();
      }
    };

    const tick = (now: number): void => {
      if (!running) return;
      const dt = Math.min((now - last) / 1000, 0.05);
      last = now;
      stepFrame(dt);
      raf = requestAnimationFrame(tick);
    };
    // Chế độ ảnh: dựng sẵn vài chục khung lửa đồng bộ để máy chụp tĩnh vẫn thấy đốm lửa.
    if (isPhotoMode()) {
      for (let k = 0; k < 55; k++) stepFrame(0.035);
    }
    raf = requestAnimationFrame(tick);
    return () => {
      running = false;
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
    };
  }, [burning]);

  const cls = burning ? ' is-burning' : phase === 'login' ? ' is-fading' : '';
  return <canvas ref={canvasRef} className={`fire-canvas${cls}`} aria-hidden="true" />;
}
