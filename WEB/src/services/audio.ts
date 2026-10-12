import { assetExists, AUDIO_AMBIENT_URL, AUDIO_ROAR_URL } from './assets';

/** Quản lý âm thanh: chỉ phát khi người dùng bật tay (đúng chính sách autoplay). */
class AudioManager {
  private ambient: HTMLAudioElement | null = null;
  private roar: HTMLAudioElement | null = null;
  private loaded = false;
  private soundOn = false;

  async ensureLoaded(): Promise<void> {
    if (this.loaded) return;
    this.loaded = true;
    if (await assetExists(AUDIO_AMBIENT_URL)) {
      const a = new Audio(AUDIO_AMBIENT_URL);
      a.loop = true;
      a.volume = 0.32;
      a.preload = 'auto';
      this.ambient = a;
    }
    if (await assetExists(AUDIO_ROAR_URL)) {
      const r = new Audio(AUDIO_ROAR_URL);
      r.volume = 0.7;
      r.preload = 'auto';
      this.roar = r;
    }
    this.apply();
  }

  setSound(on: boolean): void {
    this.soundOn = on;
    void this.ensureLoaded();
    this.apply();
  }

  private apply(): void {
    if (!this.ambient) return;
    if (this.soundOn) void this.ambient.play().catch(() => undefined);
    else this.ambient.pause();
  }

  playRoar(): void {
    if (!this.roar || !this.soundOn) return;
    this.roar.currentTime = 0;
    void this.roar.play().catch(() => undefined);
  }
}

export const audioManager = new AudioManager();
