import { SectionHead } from './SectionHead';

interface Platform {
  name: string;
  hanzi: string;
  detail: string;
  req: string;
}

const PLATFORMS: Platform[] = [
  { name: 'Windows', hanzi: '窗', detail: 'Windows 10 / 11 64-bit · bản cài đầy đủ', req: 'CPU 4 nhân · RAM 8 GB · GPU GTX 1050 · SSD trống 20 GB' },
  { name: 'Android', hanzi: '機', detail: 'Android 9.0 trở lên · APK & Cửa hàng Play', req: 'RAM 4 GB · ARM64 · dung lượng trống 6 GB' },
  { name: 'iOS', hanzi: '蘋', detail: 'iOS 14 trở lên · App Store', req: 'iPhone 8 trở lên · dung lượng trống 6 GB' },
];

export function DownloadSection() {
  return (
    <section id="tai-game" className="section section-download">
      <div className="container">
        <SectionHead kicker="TẢI & CÀI ĐẶT" title="Tải Game" sub="Một tài khoản — chơi trên cả ba nền tảng, tiến trình đồng bộ tức thì." />
        <div className="download-grid">
          {PLATFORMS.map((p) => (
            <article className="download-card" key={p.name} data-reveal>
              <span className="download-hanzi" aria-hidden="true">
                {p.hanzi}
              </span>
              <h3>{p.name}</h3>
              <p className="download-detail">{p.detail}</p>
              <p className="download-req">{p.req}</p>
              <button type="button" className="btn btn-outline btn-block" disabled title="Chưa kích hoạt trong bản trình diễn">
                Sắp ra mắt
              </button>
            </article>
          ))}
        </div>
        <p className="download-note" data-reveal>
          Đường dẫn tải sẽ kích hoạt khi mở thử nghiệm — website đang ở giai đoạn trình diễn công nghệ.
        </p>
      </div>
    </section>
  );
}
