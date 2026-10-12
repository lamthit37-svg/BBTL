export function SectionHead({ kicker, title, sub }: { kicker: string; title: string; sub?: string }) {
  return (
    <div className="section-head" data-reveal>
      <p className="section-kicker">{kicker}</p>
      <h2 className="section-title">{title}</h2>
      <span className="section-ornament" aria-hidden="true" />
      {sub && <p className="section-sub">{sub}</p>}
    </div>
  );
}
