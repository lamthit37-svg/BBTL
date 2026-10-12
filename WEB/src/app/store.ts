import { useSyncExternalStore } from 'react';

export type Phase = 'intro' | 'circle' | 'landing' | 'idle' | 'roar' | 'login';

type Listener = () => void;

/**
 * Máy pha của Hỏa Long — nguồn sự thật duy nhất nối bối cảnh 3D với UI.
 * Bối cảnh 3D đọc `get()` mỗi khung hình và tự chuyển pha; UI gửi lệnh qua request*.
 */
class PhaseStore {
  private phase: Phase = 'intro';
  private listeners = new Set<Listener>();
  /** Cờ lệnh: bối cảnh 3D đọc rồi tự xoá. */
  skipRequested = false;
  loginRequested = false;

  get(): Phase {
    return this.phase;
  }

  set(next: Phase): void {
    if (next === this.phase) return;
    this.phase = next;
    this.listeners.forEach((fn) => fn());
  }

  subscribe = (fn: Listener): (() => void) => {
    this.listeners.add(fn);
    return () => {
      this.listeners.delete(fn);
    };
  };

  getSnapshot = (): Phase => this.phase;

  /** Bỏ qua hoạt cảnh mở màn — nhảy thẳng tới tư thế đậu. */
  requestSkip(): void {
    this.skipRequested = true;
  }

  /** Đăng nhập: từ tư thế đậu đi qua pha gầm rồi mở bảng; pha khác thì mở bảng ngay. */
  requestLogin(): void {
    if (this.phase === 'idle') {
      this.loginRequested = true;
    } else {
      this.set('login');
    }
  }

  closeLogin(): void {
    this.set('idle');
  }
}

export const phaseStore = new PhaseStore();

export function usePhase(): Phase {
  return useSyncExternalStore(phaseStore.subscribe, phaseStore.getSnapshot);
}

/** Chế độ ảnh (?anh=intro|circle|landing|idle|fire|login): chụp kiểm định và deep-link QA. */
export function photoPreset(): { phase: Phase; time: number } | null {
  const raw = new URLSearchParams(window.location.search).get('anh');
  if (!raw) return null;
  const phases: Record<string, { phase: Phase; time: number }> = {
    intro: { phase: 'intro', time: 5.2 },
    circle: { phase: 'circle', time: 3.5 },
    landing: { phase: 'landing', time: 3.2 },
    idle: { phase: 'idle', time: 2 },
    fire: { phase: 'roar', time: 1.9 },
    login: { phase: 'login', time: 1 },
  };
  return phases[raw] ?? null;
}

export function isPhotoMode(): boolean {
  return photoPreset() !== null;
}

export type Quality = 'high' | 'low';

export interface UiFlags {
  quality: Quality;
  reducedMotion: boolean;
  soundOn: boolean;
}

function detectQuality(): Quality {
  const nav = navigator as Navigator & { deviceMemory?: number };
  const isMobile =
    /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) ||
    (navigator.maxTouchPoints > 1 && window.innerWidth < 900);
  const weakCpu = (navigator.hardwareConcurrency ?? 8) <= 4;
  const lowMem = (nav.deviceMemory ?? 8) <= 4;
  return isMobile || weakCpu || lowMem ? 'low' : 'high';
}

function prefersReducedMotion(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/** Cờ UI toàn cục: chất lượng đo một lần lúc mở trang, còn lại người dùng đổi tay. */
class UiStore {
  private flags: UiFlags = {
    quality: detectQuality(),
    reducedMotion: prefersReducedMotion(),
    soundOn: false,
  };
  private listeners = new Set<Listener>();

  get(): UiFlags {
    return this.flags;
  }

  private emit(): void {
    this.listeners.forEach((fn) => fn());
  }

  setReducedMotion(on: boolean): void {
    this.flags = { ...this.flags, reducedMotion: on };
    this.emit();
  }

  toggleSound(): void {
    this.flags = { ...this.flags, soundOn: !this.flags.soundOn };
    this.emit();
  }

  subscribe = (fn: Listener): (() => void) => {
    this.listeners.add(fn);
    return () => {
      this.listeners.delete(fn);
    };
  };

  getSnapshot = (): UiFlags => this.flags;
}

export const uiStore = new UiStore();

export function useUiFlags(): UiFlags {
  return useSyncExternalStore(uiStore.subscribe, uiStore.getSnapshot);
}
