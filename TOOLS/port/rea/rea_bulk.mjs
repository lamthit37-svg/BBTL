// node rea_bulk.mjs <plan.json>... — mỗi plan là mảng [{name, tool, args}].
// Ghi hết tệp việc của một plan một lượt rồi chờ: rea_server.mjs xử lý liên tiếp không nghỉ (1369 việc read_bytes mất 2 giây,
// gửi từng việc một thì mất ~10 phút vì mỗi việc chờ hai nhịp thăm dò). Kết quả gộp ở <REA_WORK>/out/<tên plan>.bulk.json:
// [{name, ok, ms, result, error}], result là normalized_result của bằng chứng (phong bì bằng chứng ~3 KB mỗi việc bị bỏ).
import fs from "node:fs";
import path from "node:path";

const root = process.env.REA_ROOT ?? "D:/rea";
const work = process.env.REA_WORK ?? `${root}/work`;
const jobs = `${work}/jobs`;
fs.mkdirSync(`${work}/out`, { recursive: true });

for (const planFile of process.argv.slice(2)) {
  const plan = JSON.parse(fs.readFileSync(planFile, "utf8"));
  const planName = path.basename(planFile, ".json");
  const prefix = `b_${planName}_`;
  const started = Date.now();
  plan.forEach((item, index) => {
    const id = `${prefix}${index}`;
    fs.rmSync(`${jobs}/${id}.done`, { force: true });
    fs.rmSync(`${jobs}/${id}.out.json`, { force: true });
    fs.writeFileSync(`${jobs}/${id}.job.json`, JSON.stringify({ tool: item.tool, args: item.args ?? {} }));
  });
  const results = [];
  for (let index = 0; index < plan.length; index += 1) {
    const id = `${prefix}${index}`;
    while (!fs.existsSync(`${jobs}/${id}.done`)) await new Promise((resolve) => setTimeout(resolve, 200));
    const outcome = JSON.parse(fs.readFileSync(`${jobs}/${id}.out.json`, "utf8"));
    const text = (outcome.result?.content ?? []).map((part) => part.text ?? "").join("\n");
    let payload = text;
    try {
      const doc = JSON.parse(text);
      payload = doc.normalized_result !== undefined ? doc.normalized_result : doc;
    } catch {
      payload = text;
    }
    results.push({ name: plan[index].name, ok: outcome.ok, ms: outcome.ms, result: payload, error: outcome.error });
    for (const ext of [".done", ".out.json"]) fs.rmSync(`${jobs}/${id}${ext}`, { force: true });
  }
  fs.writeFileSync(`${work}/out/${planName}.bulk.json`, JSON.stringify(results));
  const failed = results.filter((r) => !r.ok).length;
  console.log(`${planName}: ${plan.length} việc, ${failed} lỗi, ${Date.now() - started} ms`);
}
