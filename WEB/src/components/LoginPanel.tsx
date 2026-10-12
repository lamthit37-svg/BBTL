import { gsap } from 'gsap';
import { FormEvent, useEffect, useRef, useState } from 'react';
import { isPhotoMode, phaseStore, uiStore } from '../app/store';
import { AuthResult, login, register } from '../services/auth';

/** Bảng đăng nhập / đăng ký — mở sau chuyển cảnh lửa, long vẫn đậu phía sau. */
export function LoginPanel() {
  const panelRef = useRef<HTMLDivElement>(null);
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [account, setAccount] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [remember, setRemember] = useState(true);
  const [busy, setBusy] = useState(false);
  const [feedback, setFeedback] = useState<AuthResult | null>(null);
  const reduced = uiStore.get().reducedMotion;
  const photo = isPhotoMode();

  useEffect(() => {
    const panel = panelRef.current;
    if (panel && !reduced && !photo) {
      gsap.fromTo(panel, { opacity: 0, y: 30, scale: 0.94 }, { opacity: 1, y: 0, scale: 1, duration: 0.75, ease: 'power3.out', delay: 0.35 });
    }
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') phaseStore.closeLogin();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [reduced, photo]);

  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  const close = (): void => {
    const panel = panelRef.current;
    if (panel && !reduced) {
      gsap.to(panel, { opacity: 0, y: 18, duration: 0.32, ease: 'power2.in', onComplete: () => phaseStore.closeLogin() });
    } else {
      phaseStore.closeLogin();
    }
  };

  const submit = async (e: FormEvent): Promise<void> => {
    e.preventDefault();
    if (busy) return;
    setBusy(true);
    setFeedback(null);
    const result = mode === 'login' ? await login(account, password) : await register(account, password, confirm);
    setFeedback(result);
    setBusy(false);
  };

  return (
    <div className="login-overlay" role="dialog" aria-modal="true" aria-label={mode === 'login' ? 'Đăng nhập' : 'Đăng ký tài khoản'}>
      <div className="login-backdrop" onClick={close} />
      <div className="login-panel" ref={panelRef}>
        <button type="button" className="login-close" onClick={close} aria-label="Đóng">
          ×
        </button>
        <div className="login-head">
          <span className="login-seal" aria-hidden="true">
            龍
          </span>
          <h2>{mode === 'login' ? 'Đăng Nhập' : 'Tạo Tài Khoản'}</h2>
          <p>Vào thế giới võ lâm — Hỏa Long đang canh giữ</p>
        </div>
        <form onSubmit={(e) => void submit(e)}>
          <label className="field">
            <span>Tài khoản</span>
            <input
              value={account}
              onChange={(e) => setAccount(e.target.value)}
              placeholder="Tên tài khoản hoặc email"
              autoComplete="username"
              autoFocus
            />
          </label>
          <label className="field">
            <span>Mật khẩu</span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nhập mật khẩu"
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
            />
          </label>
          {mode === 'register' && (
            <label className="field">
              <span>Nhập lại mật khẩu</span>
              <input type="password" value={confirm} onChange={(e) => setConfirm(e.target.value)} placeholder="Gõ lại mật khẩu" autoComplete="new-password" />
            </label>
          )}
          {mode === 'login' && (
            <div className="login-row">
              <label className="check">
                <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} />
                <span>Ghi nhớ đăng nhập</span>
              </label>
              <a
                className="login-link"
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  setFeedback({ ok: false, message: 'Chức năng khôi phục cần máy chủ — chưa khả dụng trong bản trình diễn.' });
                }}
              >
                Quên mật khẩu?
              </a>
            </div>
          )}
          {feedback && <p className={`login-feedback ${feedback.ok ? 'is-ok' : 'is-err'}`}>{feedback.message}</p>}
          <button type="submit" className="btn btn-gold btn-block" disabled={busy}>
            {busy ? 'Đang kết nối…' : mode === 'login' ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ'}
          </button>
        </form>
        <p className="login-swap">
          {mode === 'login' ? (
            <>
              Chưa có tài khoản?
              <button
                type="button"
                onClick={() => {
                  setMode('register');
                  setFeedback(null);
                }}
              >
                Đăng ký ngay
              </button>
            </>
          ) : (
            <>
              Đã có tài khoản?
              <button
                type="button"
                onClick={() => {
                  setMode('login');
                  setFeedback(null);
                }}
              >
                Đăng nhập
              </button>
            </>
          )}
        </p>
        <p className="login-demo-note">Bản trình diễn web — chưa kết nối máy chủ thật.</p>
      </div>
    </div>
  );
}
