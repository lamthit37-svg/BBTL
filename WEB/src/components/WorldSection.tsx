import { SectionHead } from './SectionHead';

interface Region {
  name: string;
  hanzi: string;
  tag?: string;
  desc: string;
  art: string;
}

const REGIONS: Region[] = [
  {
    name: 'Nhạn Môn Quan',
    hanzi: '雁門關',
    desc: 'Ải quan vạn dặm nơi gió biên ải thổi qua xương kiếm — binh lửa chưa bao giờ nguôi.',
    art: 'world-art-pass',
  },
  {
    name: 'Tần Hoàng Đảo',
    hanzi: '秦皇島',
    desc: 'Hòn đảo ngọc giữa biển Đông, dấu tích đế vương còn vương đầy sương mù.',
    art: 'world-art-island',
  },
  {
    name: 'Tương Dương',
    hanzi: '襄陽',
    desc: 'Thành lũy sầm uất bên dòng Hán Thủy — chốn thương hồ và giang hồ giao nhau.',
    art: 'world-art-city',
  },
  {
    name: 'Vực Hỏa Long',
    hanzi: '火龍淵',
    tag: 'MỚI',
    desc: 'Lãnh địa của Hỏa Long bất tử — dung nham sôi dưới chân núi, ai dám bước tới?',
    art: 'world-art-volcano',
  },
];

export function WorldSection() {
  return (
    <section id="the-gioi" className="section section-world">
      <div className="container">
        <SectionHead kicker="BẢN ĐỒ THIÊN HẠ" title="Thế Giới Võ Lâm" sub="Từ biên ải tuyết giá đến vực lửa nghìn trượng — thiên hạ rộng, chân kiếm hẹp." />
        <div className="world-grid">
          {REGIONS.map((r) => (
            <article className={`world-card ${r.art}`} key={r.name} data-reveal>
              <span className="world-hanzi" aria-hidden="true">
                {r.hanzi}
              </span>
              <div className="world-info">
                {r.tag && <span className="world-tag">{r.tag}</span>}
                <h3>{r.name}</h3>
                <p>{r.desc}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
