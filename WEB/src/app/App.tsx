import { useEffect, useState } from 'react';
import { audioManager } from '../services/audio';
import { ClassesSection } from '../components/ClassesSection';
import { CommunitySection } from '../components/CommunitySection';
import { DownloadSection } from '../components/DownloadSection';
import { FeaturesSection } from '../components/FeaturesSection';
import { FireTransition } from '../components/FireTransition';
import { GuideSection } from '../components/GuideSection';
import { HeroOverlay } from '../components/HeroOverlay';
import { LoginPanel } from '../components/LoginPanel';
import { NewsSection } from '../components/NewsSection';
import { SiteFooter } from '../components/SiteFooter';
import { SiteHeader } from '../components/SiteHeader';
import { VideoGate } from '../components/VideoGate';
import { WorldSection } from '../components/WorldSection';
import { installPointerTracking } from './pointer';
import { isPhotoMode, phaseStore, usePhase, useUiFlags } from './store';
import { useReveals } from './useReveals';
import { DragonScene } from '../scenes/DragonScene';

export default function App() {
  const phase = usePhase();
  const flags = useUiFlags();
  const [booted, setBooted] = useState(isPhotoMode());
  const [videoDone, setVideoDone] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [scrolledPast, setScrolledPast] = useState(false);
  const photo = isPhotoMode();

  useEffect(() => installPointerTracking(), []);

  useEffect(() => {
    const onScroll = () => setScrolledPast(window.scrollY > window.innerHeight * 1.25);
    const onVis = () => setHidden(document.hidden);
    onScroll();
    onVis();
    window.addEventListener('scroll', onScroll, { passive: true });
    document.addEventListener('visibilitychange', onVis);
    return () => {
      window.removeEventListener('scroll', onScroll);
      document.removeEventListener('visibilitychange', onVis);
    };
  }, []);

  // Màn che khởi động: tả nội dung khi khung đầu tiên đã vẽ.
  useEffect(() => {
    const id = window.setTimeout(() => setBooted(true), photo ? 0 : flags.reducedMotion ? 350 : 1400);
    return () => window.clearTimeout(id);
  }, [flags.reducedMotion, photo]);

  // Chế độ ảnh + #hash: cuộn thẳng tới section để chụp kiểm định từng khối nội dung.
  useEffect(() => {
    if (!photo || !booted) return;
    const id = window.location.hash.slice(1);
    if (!id) return;
    // Cuộn tức thời sau hai khung (chờ layout chốt); bỏ qua smooth-scroll của html.
    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        const el = document.getElementById(id);
        if (!el) return;
        window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY, behavior: 'instant' as ScrollBehavior });
      }),
    );
  }, [photo, booted]);

  // Gầm thì rống (nếu người dùng đã bật âm thanh); đăng nhập thì khoá cuộn về đầu trang.
  useEffect(() => {
    if (phase === 'roar') {
      audioManager.playRoar();
      window.scrollTo({ top: 0 });
    }
  }, [phase]);

  const cinematic = phase === 'intro' || phase === 'circle' || phase === 'landing';
  const sceneActive =
    !hidden && (!scrolledPast || phase === 'roar' || phase === 'login') && (videoDone || phase !== 'intro');
  const onLogin = (): void => {
    window.scrollTo({ top: 0 });
    phaseStore.requestLogin();
  };

  useReveals(booted && !flags.reducedMotion && !photo);

  return (
    <>
      <a className="skip-link" href="#tin-tuc">
        Nhảy tới nội dung chính
      </a>
      <div className={`scene-holder${booted ? ' is-ready' : ''}`} aria-hidden="true">
        <DragonScene active={sceneActive} quality={flags.quality} reducedMotion={flags.reducedMotion} />
      </div>
      <div className="grain" aria-hidden="true" />
      <SiteHeader onLogin={onLogin} />
      <main>
        <HeroOverlay onLogin={onLogin} />
        <NewsSection />
        <ClassesSection />
        <WorldSection />
        <FeaturesSection />
        <GuideSection />
        <DownloadSection />
        <CommunitySection />
      </main>
      <SiteFooter />
      {cinematic && !photo && (
        <button type="button" className="skip-cine" onClick={() => phaseStore.requestSkip()}>
          Bỏ qua hoạt cảnh <span aria-hidden="true">»</span>
        </button>
      )}
      {flags.reducedMotion === false && <FireTransition />}
      <VideoGate onResolved={() => setVideoDone(true)} />
      {phase === 'login' && <LoginPanel />}
      <div className={`boot-veil${booted ? ' is-gone' : ''}`} aria-hidden="true">
        <span className="boot-seal">龍</span>
        <span className="boot-title">THIÊN LONG BÁT BỘ</span>
        <span className="boot-sub">Hỏa Long Bất Tử đang thức tỉnh…</span>
      </div>
    </>
  );
}
