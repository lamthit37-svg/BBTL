import { SectionHead } from './SectionHead';

interface NewsItem {
  cat: string;
  date: string;
  title: string;
  desc: string;
  hanzi: string;
}

const NEWS: NewsItem[] = [
  {
    cat: 'Sự kiện',
    date: '08/10/2026',
    title: 'Hỏa Long Giáng Thế — khai mở mùa mới',
    desc: 'Võ lâm đủ cấp 40 nhận Long Hồn Lệnh, vượt Vực Lava đổi thần trang giới hạn và danh hiệu “Kẻ Thuần Long”.',
    hanzi: '龍',
  },
  {
    cat: 'Cập nhật',
    date: '06/10/2026',
    title: 'Bản đồ mới: Vực Hỏa Long chính thức mở',
    desc: 'Núi lửa hoạt động, khe nứt dung nham và BOSS thế giới Hỏa Long xuất hiện theo khung giờ cố định mỗi ngày.',
    hanzi: '淵',
  },
  {
    cat: 'Giải đấu',
    date: '02/10/2026',
    title: 'Võ Lâm Minh Chủ mùa 1 — tổng giải thưởng 2 tỷ',
    desc: 'Vòng loại toàn máy chủ bắt đầu từ 15/10, đội hình 3 người, đăng ký tại trang bang hội.',
    hanzi: '武',
  },
  {
    cat: 'Bảo trì',
    date: '30/09/2026',
    title: 'Bảo trì máy chủ định kỳ 03:00 – 05:00',
    desc: 'Cập nhật cân bằng môn phái Tinh Tú và Đoàn Thị; bù đắp khung giờ cho mọi võ lâm trực chiến.',
    hanzi: '辰',
  },
];

export function NewsSection() {
  const [featured, ...rest] = NEWS;
  return (
    <section id="tin-tuc" className="section section-news">
      <div className="container">
        <SectionHead kicker="TRUNG TÂM TIN TỨC" title="Tin Tức & Sự Kiện" sub="Mọi biến động của giang hồ, cập nhật mỗi ngày." />
        <div className="news-grid">
          <article className="news-card news-featured" data-reveal>
            <div className="news-art" aria-hidden="true">
              <span className="news-hanzi">{featured.hanzi}</span>
            </div>
            <div className="news-body">
              <div className="news-meta">
                <span className="news-cat">{featured.cat}</span>
                <time dateTime="2026-10-08">{featured.date}</time>
              </div>
              <h3>{featured.title}</h3>
              <p>{featured.desc}</p>
              <a className="news-more" href="#tin-tuc" onClick={(e) => e.preventDefault()}>
                Đọc tiếp
                <span aria-hidden="true"> →</span>
              </a>
            </div>
          </article>
          {rest.map((item) => (
            <article className="news-card" key={item.title} data-reveal>
              <div className="news-art" aria-hidden="true">
                <span className="news-hanzi">{item.hanzi}</span>
              </div>
              <div className="news-body">
                <div className="news-meta">
                  <span className="news-cat">{item.cat}</span>
                  <time>{item.date}</time>
                </div>
                <h3>{item.title}</h3>
                <p>{item.desc}</p>
                <a className="news-more" href="#tin-tuc" onClick={(e) => e.preventDefault()}>
                  Đọc tiếp
                  <span aria-hidden="true"> →</span>
                </a>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
