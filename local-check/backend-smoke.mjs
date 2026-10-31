// Headless smoke test against the LIVE Apps Script backend — no Flutter build,
// no browser, no screenshots. Run this first after any Code.gs change to catch
// obvious breakage in seconds instead of clicking through the whole UI.
//
// Usage:
//   node local-check/backend-smoke.mjs
//   APPS_SCRIPT_URL=https://script.google.com/macros/s/XXX/exec node local-check/backend-smoke.mjs
//
// Uses the same dev test-admin account and demo donors the chief keeps around
// for testing (see CLAUDE.md). It only calls read/idempotent actions plus the
// donor login flow — it does not create or mutate data, so it's safe to run
// repeatedly against the real sheet.

const BASE_URL = process.env.APPS_SCRIPT_URL ||
  'https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec';

const TEST_ADMIN_EMAIL = 'dev.test.admin@local.test';
const TEST_ADMIN_PIN_HASH = await sha256('0000');
const TEST_DONOR_PHONE = '01911000222';
const TEST_DONOR_PIN_HASH = await sha256('1234');

async function sha256(text) {
  const data = new TextEncoder().encode(text.trim());
  const hash = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function call(action, payload = {}) {
  const res = await fetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain;charset=utf-8' },
    body: JSON.stringify({ action, payload }),
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for action "${action}"`);
  return res.json();
}

// A few legacy actions (e.g. `login`) read fields off the top-level request
// object instead of `payload` — this sends both so the same `call()` works
// for either convention without having to special-case per action.
async function callFlat(action, fields = {}) {
  const res = await fetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain;charset=utf-8' },
    body: JSON.stringify({ action, payload: fields, ...fields }),
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for action "${action}"`);
  return res.json();
}

const checks = [];
function check(name, fn) {
  checks.push({ name, fn });
}

check('getOrgSettings (public)', async () => {
  const r = await call('getOrgSettings');
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('listDonationOpportunities (public)', async () => {
  const r = await call('listDonationOpportunities');
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('staff login (dev test admin)', async () => {
  const r = await callFlat('login', { email: TEST_ADMIN_EMAIL, pin_hash: TEST_ADMIN_PIN_HASH });
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('donor login (demo donor 222)', async () => {
  const r = await call('donorLogin', { phone: TEST_DONOR_PHONE, pin_hash: TEST_DONOR_PIN_HASH });
  if (r.ok !== true) throw new Error(JSON.stringify(r));
  if (!r.donor_token) throw new Error('donor login ok but no donor_token returned');
  globalThis.__donorToken = r.donor_token;
  globalThis.__donorId = r.donor_id;
});

check('donorMyDashboard (authenticated)', async () => {
  const r = await call('donorMyDashboard', {
    donor_id: globalThis.__donorId,
    donor_token: globalThis.__donorToken,
  });
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('donorMyTransactions (authenticated)', async () => {
  const r = await call('donorMyTransactions', {
    donor_id: globalThis.__donorId,
    donor_token: globalThis.__donorToken,
  });
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('donorMyNotifications (authenticated)', async () => {
  const r = await call('donorMyNotifications', {
    donor_id: globalThis.__donorId,
    donor_token: globalThis.__donorToken,
  });
  if (r.ok !== true) throw new Error(JSON.stringify(r));
});

check('donor auth rejects a bad token', async () => {
  const r = await call('donorMyDashboard', { donor_id: globalThis.__donorId, donor_token: 'not-a-real-token' });
  if (r.ok === true) throw new Error('bad token was accepted — auth check is broken');
});

console.log(`Backend smoke test against: ${BASE_URL}\n`);

let failed = 0;
for (const { name, fn } of checks) {
  try {
    await fn();
    console.log(`  OK   ${name}`);
  } catch (e) {
    failed++;
    console.log(`  FAIL ${name} — ${e.message}`);
  }
}

console.log(`\n${checks.length - failed}/${checks.length} passed`);
if (failed > 0) process.exit(1);
