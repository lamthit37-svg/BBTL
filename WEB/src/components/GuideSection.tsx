import { SectionHead } from './SectionHead';

const STEPS = [
  {
    num: '01',
    title: 'Tạo nhân vật',
    desc: 'Chọn môn phái hợp vai của bạn: chống chịu, sát thương bùng nổ hay hỗ trợ đội hình. Nhân vật khởi đầu tặng bộ chân giáp và 3 trứng linh thú.',
  },
  {
    num: '02',
    title: 'Luyện cấp theo chính tuyến',
    desc: 'Theo dấu Long Hồn Lệnh qua 12 chương chính tuyến — vừa mở khóa tính năng, vừa tích luyện khí để chuẩn bị vào Vực Hỏa Long.',
  },
  {
    num: '03',
    title: 'Gia nhập bang hội',
    desc: 'Bang hội mở khóa công thành chiến, BOSS bang và thương phủ. Đây là con đường nhanh nhất để chạm tay vào thần trang.',
  },
];

export function GuideSection() {
  return (
    <section id="huong-dan" className="section section-guide">
      <div className="container">
        <SectionHead kicker="TÂN THỦ NHẬP MÔN" title="Ba Bước Vào Giang Hồ" sub="Mười phút đầu tiên quyết định cả hành trình — đi cho đúng ngay từ đầu." />
        <ol className="guide-steps">
          {STEPS.map((s) => (
            <li className="guide-step" key={s.num} data-reveal>
              <span className="guide-num" aria-hidden="true">
                {s.num}
              </span>
              <h3>{s.title}</h3>
              <p>{s.desc}</p>
            </li>
          ))}
        </ol>
        <p className="guide-tip" data-reveal>
          <strong>Mẹo:</strong> đăng nhập đủ 7 ngày liên tiếp nhận tọa kỵ Vân Thú — di chuyển nhanh 30% trên mọi bản đồ.
        </p>
      </div>
    </section>
  );
}
