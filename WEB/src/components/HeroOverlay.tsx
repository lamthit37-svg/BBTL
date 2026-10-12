import { gsap } from 'gsap';
import { useEffect, useRef } from 'react';
import { isPhotoMode, useUiFlags } from '../app/store';

export function HeroOverlay({ onLogin }: { onLogin: () => void }) {
  const flags = useUiFlags();
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (flags.reducedMotion || isPhotoMode() || !ref.current) return;
    const els = ref.current.querySelectorAll('.hero-anim');
    const tween = gsap.fromTo(
      els,
      { opacity: 0, y: 30 },
      { opacity: 1, y: 0, duration: 1.15, stagger: 0.13, ease: 'power3.out', delay: 0.5, clearProps: 'all' },
    );
    return () => {
      tween.kill();
    };
  }, [flags.reducedMotion]);

  return (
    <section id="trang-chu" className="hero" aria-label="Trang chủ">
      <div className="hero-content" ref={ref}>
        <p className="hero-kicker hero-anim">MMORPG VÕ HIỆP KINH ĐIỂN · MÙA GIẢI HỎA LONG</p>
        <h1 className="hero-title hero-anim">
          THIÊN LONG
          <span className="hero-title-accent">BÁT BỘ</span>
        </h1>
        <p className="hero-hanzi hero-anim" aria-hidden="true">
          天龍八部
        </p>
        <p className="hero-tagline hero-anim">
          Hỏa Long ngàn năm thức tỉnh giữa biển mây — một lời thề sắt đá của võ lâm.
          <br />
          Số phận thiên hạ, bắt đầu từ nơi đây.
        </p>
        <div className="hero-actions hero-anim">
          <button type="button" className="btn btn-gold btn-lg" onClick={onLogin}>
            CHƠI NGAY
          </button>
          <a className="btn btn-outline btn-lg" href="#tai-game">
            TẢI GAME
          </a>
          <a className="btn btn-ghost btn-lg" href="#the-gioi">
            KHÁM PHÁ THẾ GIỚI
          </a>
        </div>
        <ul className="hero-stats hero-anim">
          <li>
            <strong>13</strong>
            <span>Môn phái</span>
          </li>
          <li>
            <strong>19</strong>
            <span>Năm huyền thoại</span>
          </li>
          <li>
            <strong>4,2tr</strong>
            <span>Võ lâm đồng hành</span>
          </li>
        </ul>
      </div>
      <a className="hero-scrollcue" href="#tin-tuc">
        Cuộn để khám phá
        <i aria-hidden="true" />
      </a>
    </section>
  );
}
