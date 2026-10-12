import { SectionHead } from './SectionHead';

interface Channel {
  name: string;
  glyph: string;
  handle: string;
}

const CHANNELS: Channel[] = [
  { name: 'Facebook Fanpage', glyph: 'f', handle: 'facebook.com/thienlongbatbo' },
  { name: 'YouTube', glyph: '▶', handle: 'youtube.com/@thienlongbatbo' },
  { name: 'Discord', glyph: '◈', handle: 'discord.gg/thienlongbatbo' },
  { name: 'Zalo Group', glyph: 'Z', handle: 'zalo.me/group/thienlongbatbo' },
];

export function CommunitySection() {
  return (
    <section id="cong-dong" className="section section-community">
      <div className="container">
        <SectionHead kicker="CỘNG ĐỒNG VÕ LÂM" title="Cộng Đồng" sub="Hàng triệu võ lâm đang chờ người đồng hành kế tiếp." />
        <div className="community-grid">
          {CHANNELS.map((c) => (
            <a
              className="community-card"
              key={c.name}
              href="#cong-dong"
              onClick={(e) => e.preventDefault()}
              data-reveal
            >
              <span className="community-glyph" aria-hidden="true">
                {c.glyph}
              </span>
              <span className="community-name">{c.name}</span>
              <span className="community-handle">{c.handle}</span>
              <span className="community-join">Tham gia →</span>
            </a>
          ))}
        </div>
        <div className="community-support" data-reveal>
          <div>
            <h3>Hỗ trợ người chơi</h3>
            <p>Email: hotro@thienlongbatbo.demo · Phản hồi trong 24 giờ</p>
          </div>
          <div>
            <h3>Đường dây nóng</h3>
            <p>1900 0000 (8:00 – 22:00 hằng ngày) · Chăm sóc khách hàng</p>
          </div>
        </div>
      </div>
    </section>
  );
}
