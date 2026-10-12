import { SectionHead } from './SectionHead';

interface Feature {
  hanzi: string;
  title: string;
  desc: string;
}

const FEATURES: Feature[] = [
  { hanzi: '戰', title: 'Đại chiến bang hội', desc: 'Công thành chiếm địa, tranh đoạt Long Mạch mỗi cuối tuần — bang nào chiếm thành, bang ấy hiệu lệnh thị trường.' },
  { hanzi: '幫', title: 'Bang hội & xã giao', desc: 'Kết nghĩa huynh đệ, dựng bang phái, mở bang nhiệm vụ và thương phủ riêng.' },
  { hanzi: '鍛', title: 'Rèn giáp & thăng tinh', desc: 'Chế tấu thần khí, cường hóa thăng sao — mỗi lần rèn là một canh bạc với trời.' },
  { hanzi: '騎', title: 'Tọa kỵ thần thú', desc: 'Thuần phục tọa kỵ hiếm từ Vực Hỏa Long, phi nước đại khắp thiên hạ.' },
  { hanzi: '靈', title: 'Linh thú đồng hành', desc: 'Ưấp trứng linh thú theo thời gian, chúng trưởng thành và chiến đấu cùng chủ nhân.' },
  { hanzi: '魔', title: 'BOSS thế giới', desc: 'Hỏa Long, Huyết Ma xuất hiện theo giờ — toàn máy chủ hội binh, phần thưởng rơi chung.' },
];

export function FeaturesSection() {
  return (
    <section id="tinh-nang" className="section section-features">
      <div className="container">
        <SectionHead kicker="GIANG HỒ ĐẠI CHIẾN" title="Tính Năng Trò Chơi" sub="Một thế giới sống động — đánh nhau, rèn giáp, nuôi thú và viết tên mình lên bảng vàng." />
        <div className="features-grid">
          {FEATURES.map((f) => (
            <article className="feature-card" key={f.title} data-reveal>
              <span className="feature-hanzi" aria-hidden="true">
                {f.hanzi}
              </span>
              <h3>{f.title}</h3>
              <p>{f.desc}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
