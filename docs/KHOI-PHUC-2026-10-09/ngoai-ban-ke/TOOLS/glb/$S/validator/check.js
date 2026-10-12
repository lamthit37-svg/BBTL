const fs = require("fs"), path = require("path"), validator = require("gltf-validator");
const files = process.argv.slice(2);
(async () => {
  const totals = {};
  for (const file of files) {
    const data = new Uint8Array(fs.readFileSync(file));
    const report = await validator.validateBytes(data, {
      uri: path.basename(file), maxIssues: 0,
      externalResourceFunction: (uri) => new Promise((resolve, reject) => {
        fs.readFile(path.resolve(path.dirname(file), decodeURIComponent(uri)), (e, d) => e ? reject(e.toString()) : resolve(new Uint8Array(d)));
      }),
    });
    const i = report.issues;
    const codes = {};
    for (const m of i.messages) { const k = ["E","W","I","H"][m.severity] + " " + m.code; codes[k] = (codes[k] || 0) + 1; totals[k] = (totals[k] || 0) + 1; }
    console.log(path.basename(file), "errors", i.numErrors, "warnings", i.numWarnings, "infos", i.numInfos, "hints", i.numHints, JSON.stringify(codes));
    if (i.numErrors) for (const m of i.messages.filter(m => m.severity === 0).slice(0, 4)) console.log("   ", m.code, m.pointer, m.message);
  }
  console.log("TỔNG", JSON.stringify(totals));
})();
