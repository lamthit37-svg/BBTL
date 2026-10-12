import { useEffect, useState } from 'react';
import { phaseStore } from '../app/store';
import { assetExists, INTRO_VIDEO_URL } from '../services/assets';

/**
 * Nếu có video mở màn thật (public/videos/dragon_intro.webm) thì chiếu trước khi 3D vào pha intro.
 * Không có asset thì tự nhả ngay để cảnh 3D chạy từ đầu — không bao giờ chặn trang.
 */
export function VideoGate({ onResolved }: { onResolved: () => void }) {
  const [url, setUrl] = useState<string | null>(null);
  const [gone, setGone] = useState(false);

  useEffect(() => {
    let live = true;
    void assetExists(INTRO_VIDEO_URL).then((ok) => {
      if (!live) return;
      if (ok) setUrl(INTRO_VIDEO_URL);
      else onResolved();
    });
    return () => {
      live = false;
    };
  }, [onResolved]);

  if (!url || gone) return null;

  const finish = (): void => {
    setGone(true);
    phaseStore.requestSkip();
    onResolved();
  };

  return (
    <div className="video-gate">
      <video src={url} autoPlay muted playsInline onEnded={finish} />
      <button type="button" className="btn btn-ghost video-gate-skip" onClick={finish}>
        Bỏ qua ›
      </button>
    </div>
  );
}
