// Giữ MỘT phiên REA MCP (một lần nạp Ghidra, ~5 phút với Game.exe) và nhận việc qua thư mục "jobs".
//   <id>.job.json = {"tool": "...", "args": {...}}
//   -> <id>.running (đang chạy) -> <id>.out.json + <id>.done (xong)
// Tạo tệp jobs/stop để đóng phiên. Biến môi trường: REA_ROOT (bản clone của REA, mặc định D:/rea), REA_WORK (thư mục làm việc,
// mặc định <REA_ROOT>/work). GHIDRA_INSTALL_DIR, JAVA_HOME, REA_ANALYSIS_PROVIDER=ghidra và REA_GHIDRA_STARTUP_TIMEOUT_MS
// (>= 1800000: mặc định 330000 sát mốc nạp Game.exe) phải đặt sẵn — xem start_server.cmd.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const root = process.env.REA_ROOT ?? "D:/rea";
const work = process.env.REA_WORK ?? `${root}/work`;
// ESM tìm gói theo vị trí tệp này (TOOLS/port/rea), không theo thư mục chạy, nên nạp thẳng từ node_modules của REA.
const mcp = `${root}/node_modules/@modelcontextprotocol/client/dist`;
const { Client } = await import(pathToFileURL(`${mcp}/index.mjs`).href);
const { StdioClientTransport } = await import(pathToFileURL(`${mcp}/stdio.mjs`).href);
const jobs = `${work}/jobs`;
fs.mkdirSync(jobs, { recursive: true });
const log = (text) => fs.appendFileSync(`${work}/server.log`, `${new Date().toISOString()} ${text}\n`);

// REA cần được chạy từ thư mục của nó để thấy node_modules của @modelcontextprotocol.
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [`${root}/scripts/rea.mjs`, "mcp"],
  env: { ...process.env },
});
const client = new Client({ name: "thienlong-rea-driver", version: "1.0.0" });
await client.connect(transport);
log("connected");

// Tham số thứ hai của callTool là options; tham số thứ ba bị bỏ qua và rơi về mốc 60 giây của SDK.
const call = async (tool, args) => {
  const started = Date.now();
  try {
    const result = await client.callTool({ name: tool, arguments: args ?? {} }, { timeout: 3_600_000, resetTimeoutOnProgress: true });
    return { ok: !result.isError, ms: Date.now() - started, result };
  } catch (cause) {
    return { ok: false, ms: Date.now() - started, error: String(cause?.stack ?? cause) };
  }
};

while (!fs.existsSync(path.join(jobs, "stop"))) {
  const pending = fs.readdirSync(jobs).filter((name) => name.endsWith(".job.json")).sort();
  for (const name of pending) {
    const id = name.slice(0, -".job.json".length);
    const file = path.join(jobs, name);
    let job;
    try {
      job = JSON.parse(fs.readFileSync(file, "utf8"));
    } catch {
      continue; // tệp đang được ghi dở, vòng sau đọc lại
    }
    fs.renameSync(file, path.join(jobs, `${id}.running`));
    log(`start ${id} ${job.tool}`);
    const outcome = await call(job.tool, job.args);
    fs.writeFileSync(path.join(jobs, `${id}.out.json`), JSON.stringify(outcome));
    fs.renameSync(path.join(jobs, `${id}.running`), path.join(jobs, `${id}.done`));
    log(`done ${id} ok=${outcome.ok} ms=${outcome.ms}`);
  }
  await new Promise((resolve) => setTimeout(resolve, 300));
}
await client.close();
log("closed");
