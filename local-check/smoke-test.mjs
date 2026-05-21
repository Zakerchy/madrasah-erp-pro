import http from 'node:http';

const HOST = 'localhost';
const PORT = Number(process.env.PORT || 4123);

function fetchJson(path) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: HOST, port: PORT, path, method: 'GET' }, (res) => {
      let body = '';
      res.on('data', (d) => body += d);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          reject(new Error(`Invalid JSON from ${path}: ${body}`));
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

const health = await fetchJson('/api/health');
if (!health.ok) throw new Error('health failed');

const summary = await fetchJson('/api/dashboard-summary');
if (!summary.ok) throw new Error('summary failed');

console.log('Smoke OK');
console.log('Transactions:', summary.data?.meta?.transactions ?? 0);
console.log('Balance:', summary.data?.balance ?? 0);
