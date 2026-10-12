import { createRoot } from 'react-dom/client';
import App from './app/App';
import './styles/global.css';
import './styles/sections.css';
import './styles/login.css';

// Lỗi render không được bắt thì in thẳng ra màn — trang điện ảnh không có chỗ để log.
const showCrash = (title: string, detail: string): void => {
  const box = document.createElement('pre');
  box.style.cssText = 'position:fixed;inset:auto 12px 12px 12px;z-index:9999;max-height:45vh;overflow:auto;padding:14px;background:#2a0d08;color:#ffd9c9;border:1px solid #a8241c;border-radius:10px;font:12px/1.5 monospace;white-space:pre-wrap';
  box.textContent = `${title}\n\n${detail}`;
  document.body.appendChild(box);
};

window.addEventListener('error', (e) => showCrash('Lỗi chạy: ' + e.message, e.error?.stack ?? e.filename + ':' + e.lineno));
window.addEventListener('unhandledrejection', (e) => showCrash('Lỗi promise:', String(e.reason instanceof Error ? e.reason.stack : e.reason)));

createRoot(document.getElementById('root') as HTMLElement).render(<App />);
