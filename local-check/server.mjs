import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';

const __dirname = path.dirname(url.fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const TXN_CSV = path.join(ROOT, 'tools/output/migrated_fund_transactions.csv');
const BEN_CSV = path.join(ROOT, 'tools/output/migrated_beneficiaries.csv');
const SCH_CSV = path.join(ROOT, 'tools/output/migrated_scholarship_payments.csv');
const PORT = Number(process.env.PORT || 4123);

function parseCsv(csvText) {
  const lines = csvText.trim().split(/\r?\n/);
  if (!lines.length) return [];
  const headers = splitCsvLine(lines[0]);
  return lines.slice(1).filter(Boolean).map((line) => {
    const cols = splitCsvLine(line);
    const obj = {};
    headers.forEach((h, i) => {
      obj[h] = cols[i] ?? '';
    });
    return obj;
  });
}

function splitCsvLine(line) {
  const out = [];
  let cur = '';
  let inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    const nx = line[i + 1];
    if (ch === '"') {
      if (inQ && nx === '"') {
        cur += '"';
        i++;
      } else {
        inQ = !inQ;
      }
      continue;
    }
    if (ch === ',' && !inQ) {
      out.push(cur);
      cur = '';
      continue;
    }
    cur += ch;
  }
  out.push(cur);
  return out;
}

function readRows(file) {
  if (!fs.existsSync(file)) return [];
  const txt = fs.readFileSync(file, 'utf8');
  if (!txt.trim()) return [];
  return parseCsv(txt);
}

function txnSummary(rows, monthKey = '') {
  const filtered = rows.filter((r) => {
    if (!monthKey) return true;
    return String(r.txn_date || '').slice(0, 7) === monthKey;
  });

  const byFund = {};
  let totalIn = 0;
  let totalOut = 0;

  filtered.forEach((r) => {
    const fund = r.fund_type || 'UNKNOWN';
    const amount = Number(r.amount || 0);
    const dir = r.direction || '';
    if (!byFund[fund]) byFund[fund] = { in: 0, out: 0, balance: 0 };

    if (dir === 'IN') {
      totalIn += amount;
      byFund[fund].in += amount;
    } else {
      totalOut += amount;
      byFund[fund].out += amount;
    }
  });

  Object.keys(byFund).forEach((k) => {
    byFund[k].balance = byFund[k].in - byFund[k].out;
  });

  return {
    totalIn,
    totalOut,
    balance: totalIn - totalOut,
    byFund,
    rows: filtered,
  };
}

function sendJson(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data));
}

function sendHtml(res, html) {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(html);
}

function page() {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Madrasah ERP Lite Local Check</title>
<style>
body{font-family:system-ui,Segoe UI,Roboto,sans-serif;background:#f8fafc;margin:0;padding:20px;color:#0f172a}
.card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:14px;margin-bottom:12px}
button{background:#0f766e;color:#fff;border:0;border-radius:8px;padding:8px 12px;font-weight:700;cursor:pointer}
input{padding:8px;border:1px solid #cbd5e1;border-radius:8px}
pre{white-space:pre-wrap;word-break:break-word;background:#0b1020;color:#e2e8f0;padding:12px;border-radius:8px;max-height:320px;overflow:auto}
</style>
</head>
<body>
  <h2>Madrasah ERP Lite - Localhost Checker</h2>
  <div class="card">
    <p><b>Purpose:</b> Verify migrated data and summary logic before full deployment.</p>
    <button onclick="loadHealth()">Health</button>
    <button onclick="loadSummary()">Dashboard Summary</button>
    <input id="month" placeholder="YYYY-MM (optional)"/>
    <button onclick="loadReport()">Monthly Report</button>
  </div>
  <div class="card"><b>Result</b><pre id="out">Click a button...</pre></div>
<script>
const out = document.getElementById('out');
async function j(u){const r=await fetch(u);return await r.json();}
function p(x){out.textContent=JSON.stringify(x,null,2)}
async function loadHealth(){p(await j('/api/health'))}
async function loadSummary(){p(await j('/api/dashboard-summary'))}
async function loadReport(){const m=document.getElementById('month').value.trim();p(await j('/api/monthly-report'+(m?('?monthKey='+encodeURIComponent(m)):'')))}
</script>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  const parsed = new URL(req.url || '/', `http://${req.headers.host}`);

  if (parsed.pathname === '/') {
    return sendHtml(res, page());
  }

  if (parsed.pathname === '/api/health') {
    return sendJson(res, { ok: true, message: 'local-check server running', ts: new Date().toISOString() });
  }

  if (parsed.pathname === '/api/dashboard-summary') {
    const txns = readRows(TXN_CSV);
    const ben = readRows(BEN_CSV);
    const sch = readRows(SCH_CSV);
    return sendJson(res, {
      ok: true,
      data: {
        ...txnSummary(txns),
        meta: {
          transactions: txns.length,
          beneficiaries: ben.length,
          scholarshipRows: sch.length,
        }
      }
    });
  }

  if (parsed.pathname === '/api/monthly-report') {
    const monthKey = parsed.searchParams.get('monthKey') || '';
    const txns = readRows(TXN_CSV);
    return sendJson(res, { ok: true, data: txnSummary(txns, monthKey) });
  }

  res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ ok: false, message: 'Not Found' }));
});

server.listen(PORT, () => {
  console.log(`Local check server running at http://localhost:${PORT}`);
});
