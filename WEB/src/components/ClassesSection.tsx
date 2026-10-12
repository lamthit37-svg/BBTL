import { gsap } from 'gsap';
import { useEffect, useRef, useState } from 'react';
import { SectionHead } from './SectionHead';
import { uiStore } from '../app/store';

interface Sect {
  name: string;
  hanzi: string;
  role: string;
  desc: string;
}

const SECTS: Sect[] = [
  { name: 'Thiếu Lâm', hanzi: '少林', role: 'Cận chiến · Chống chịu', desc: 'Bảy mươi hai tuyệt kỹ của Thiếu Lâm tự — Kim Chung Bất Hoại biến thân thành tường thành sống của đội hình.' },
  { name: 'Minh Giáo', hanzi: '明教', role: 'Cận chiến · Bùng nổ', desc: 'Thánh Hỏa Thần Công thiêu đốt chiến trường, dồn toàn bộ sát thương vào vài nhịp thở.' },
  { name: 'Cái Bang', hanzi: '丐幫', role: 'Cận chiến · Quần chiến', desc: 'Hàng Long Thập Bát Chưởng vang trời — giữa vòng vây nghìn quân, càng đông càng mạnh.' },
  { name: 'Võ Đang', hanzi: '武當', role: 'Viễn chiến · Khống chế', desc: 'Thái cực nhu trung đới cương, kiếm khí như tơ không hình trói chân địch từ xa.' },
  { name: 'Nga Mi', hanzi: '峨眉', role: 'Phụ trợ · Hồi phục', desc: 'Y thuật Nga Mi thiên hạ vô song — cánh tay phải giữ sinh lực cho cả đội xuất chinh.' },
  { name: 'Thiên Long', hanzi: '天龍', role: 'Viễn chiến · Vạn năng', desc: 'Cung thủ của hoàng tộc Đại Lý, nội công thâm hậu, linh hoạt trên mọi trận địa.' },
  { name: 'Thiên Sơn', hanzi: '天山', role: 'Cận chiến · Sát thủ', desc: 'Ẩn thân trong băng tuyết, một kích chí mạng phóng ra từ bóng tối.' },
  { name: 'Tinh Tú', hanzi: '星宿', role: 'Viễn chiến · Độc công', desc: 'Học phái dùng độc lừng danh — kẻ trúng chiêu chết chậm trong đau đớn và suy yếu.' },
  { name: 'Đoàn Thị', hanzi: '段氏', role: 'Viễn chiến · Bùng nổ', desc: 'Lục Mạch Thần Kiếm nhất chỉ xuất ra, lục lộ kiếm khí thấu giáp kinh thiên.' },
];

export function ClassesSection() {
  const [selected, setSelected] = useState(0);
  const detailRef = useRef<HTMLDivElement>(null);
  const sect = SECTS[selected];
  const reduced = uiStore.get().reducedMotion;

  useEffect(() => {
    if (reduced || !detailRef.current) return;
    gsap.fromTo(detailRef.current, { opacity: 0, x: 26 }, { opacity: 1, x: 0, duration: 0.5, ease: 'power3.out' });
  }, [selected, reduced]);

  return (
    <section id="mon-phai" className="section section-sects">
      <div className="container">
        <SectionHead kicker="CỬU ĐẠI MÔN PHÁI" title="Chọn Con Đường Võ Học" sub="Mỗi môn phái một triết lý — giang hồ chờ người viết tiếp huyền thoại." />
        <div className="sects-layout">
          <div className="sects-list" role="tablist" aria-label="Danh sách môn phái">
            {SECTS.map((s, i) => (
              <button
                type="button"
                key={s.name}
                role="tab"
                aria-selected={i === selected}
                className={`sect-tab${i === selected ? ' is-active' : ''}`}
                onClick={() => setSelected(i)}
              >
                <span className="sect-hanzi" aria-hidden="true">
                  {s.hanzi}
                </span>
                <span className="sect-name">{s.name}</span>
              </button>
            ))}
          </div>
          <div className="sects-detail" ref={detailRef}>
            <span className="sects-watermark" aria-hidden="true">
              {sect.hanzi}
            </span>
            <p className="sects-role">{sect.role}</p>
            <h3 className="sects-name">{sect.name}</h3>
            <p className="sects-desc">{sect.desc}</p>
            <a className="btn btn-outline btn-sm" href="#mon-phai" onClick={(e) => e.preventDefault()}>
              Khám phá chi tiết
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
