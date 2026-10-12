const LINK_COLS: { title: string; links: string[] }[] = [
  { title: 'Về game', links: ['Giới thiệu', 'Tin tức', 'Tân thủ hướng dẫn', 'Bản đồ thế giới'] },
  { title: 'Hỗ trợ', links: ['Trung tâm trợ giúp', 'Bảo mật tài khoản', 'Báo lỗi', 'Chính sách nạp thẻ'] },
  { title: 'Pháp lý', links: ['Điều khoản dịch vụ', 'Quyền riêng tư', 'Quy định tên nhân vật', 'An toàn thanh toán'] },
];

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div className="footer-brand">
          <span className="brand-seal" aria-hidden="true">
            龍
          </span>
          <strong>THIÊN LONG BÁT BỘ</strong>
          <p>
            Website trình diễn công nghệ cho MMORPG võ hiệp Thiên Long Bát Bộ — Hỏa Long Bất Tử. Không phát hành thương mại.
          </p>
        </div>
        {LINK_COLS.map((col) => (
          <nav className="footer-col" key={col.title} aria-label={col.title}>
            <h3>{col.title}</h3>
            {col.links.map((label) => (
              <a key={label} href="#" onClick={(e) => e.preventDefault()}>
                {label}
              </a>
            ))}
          </nav>
        ))}
      </div>
      <div className="container footer-legal">
        <p>© 2026 Thiên Long Bát Bộ. Mọi thương hiệu thuộc về chủ sở hữu tương ứng.</p>
        <span className="footer-age" title="Phù hợp từ 12 tuổi trở lên">
          12+
        </span>
      </div>
    </footer>
  );
}
