import { useEffect, useState } from 'react';
import { uiStore, useUiFlags } from '../app/store';
import { audioManager } from '../services/audio';

const NAV: [string, string][] = [
  ['trang-chu', 'Trang chủ'],
  ['tin-tuc', 'Tin tức'],
  ['mon-phai', 'Môn phái'],
  ['the-gioi', 'Thế giới'],
  ['huong-dan', 'Hướng dẫn'],
  ['tai-game', 'Tải game'],
  ['cong-dong', 'Cộng đồng'],
];

function SoundIcon({ on }: { on: boolean }) {
  return (
    <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M4 9v6h4l5 4V5L8 9H4z" />
      {on ? <path d="M16.5 9a4.5 4.5 0 0 1 0 6" /> : <path d="M17 9.5l4.5 5M21.5 9.5l-4.5 5" />}
    </svg>
  );
}

function MotionIcon({ reduced }: { reduced: boolean }) {
  return (
    <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true">
      <path d="M3 12c3-6.5 6 6.5 9 0s6 6.5 9 0" />
      {reduced && <path d="M4 20L20 4" />}
    </svg>
  );
}

export function SiteHeader({ onLogin }: { onLogin: () => void }) {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const flags = useUiFlags();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const toggleSound = () => {
    uiStore.toggleSound();
    audioManager.setSound(uiStore.get().soundOn);
  };

  return (
    <header className={`site-header${scrolled ? ' is-scrolled' : ''}${open ? ' is-open' : ''}`}>
      <div className="header-inner">
        <a className="brand" href="#trang-chu" onClick={() => setOpen(false)}>
          <span className="brand-seal" aria-hidden="true">
            龍
          </span>
          <span className="brand-text">
            <strong>THIÊN LONG BÁT BỘ</strong>
            <small>IMMORTAL LAVA DRAGON</small>
          </span>
        </a>
        <nav className="main-nav" aria-label="Điều hướng chính">
          {NAV.map(([id, label]) => (
            <a key={id} href={`#${id}`} onClick={() => setOpen(false)}>
              {label}
            </a>
          ))}
        </nav>
        <div className="header-actions">
          <button
            type="button"
            className={`icon-btn${flags.soundOn ? ' is-on' : ''}`}
            onClick={toggleSound}
            title={flags.soundOn ? 'Tắt âm thanh' : 'Bật âm thanh'}
            aria-label={flags.soundOn ? 'Tắt âm thanh' : 'Bật âm thanh'}
          >
            <SoundIcon on={flags.soundOn} />
          </button>
          <button
            type="button"
            className={`icon-btn${flags.reducedMotion ? ' is-on' : ''}`}
            onClick={() => uiStore.setReducedMotion(!flags.reducedMotion)}
            title={flags.reducedMotion ? 'Bật hiệu ứng chuyển động' : 'Giảm chuyển động'}
            aria-label={flags.reducedMotion ? 'Bật hiệu ứng chuyển động' : 'Giảm chuyển động'}
          >
            <MotionIcon reduced={flags.reducedMotion} />
          </button>
          <button
            type="button"
            className="btn btn-gold btn-sm"
            onClick={() => {
              setOpen(false);
              onLogin();
            }}
          >
            Đăng nhập
          </button>
          <button type="button" className="burger" onClick={() => setOpen(!open)} aria-label="Mở menu" aria-expanded={open}>
            <span />
            <span />
            <span />
          </button>
        </div>
      </div>
    </header>
  );
}
