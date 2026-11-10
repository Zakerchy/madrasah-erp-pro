# MadrasahApp — Project Guide for Claude

Read [HANDOFF.md](HANDOFF.md) first for the latest session's work log. This file is
the stable environment/workflow reference that doesn't change session to session.

## Stack
- **Frontend**: Flutter Web (PWA) — `mobile-app/`
- **Backend**: Google Apps Script — `backend-apps-script/Code.gs` (single file, ~4000+ lines)
- **Database**: Google Sheets
- **Hosting**: Vercel, static export (`vercel.json` → `buildCommand: ./tools/vercel-build.sh`,
  `outputDirectory: mobile-app/build/web`). No server runs in production — it's a pure
  static SPA hitting the Apps Script web app URL directly from the browser.
- **Repo**: `github.com/Zakerchy/madrasah-erp-pro`, branch `main`.

## Environment setup (don't rediscover this — it costs tokens every time)
- Flutter SDK is **not** on PATH by default. It lives at:
  `/Users/zakerchy/Desktop/MadrasahApp/.local-tools/flutter`
  Always do: `export PATH="/Users/zakerchy/Desktop/MadrasahApp/.local-tools/flutter/bin:$PATH"`
  before any `flutter`/`dart` command.
- `mobile-app/.claude/launch.json` already defines a `flutter-web` config
  (`flutter run -d web-server --web-port 8765`) for the Browser tool's `preview_start`.
  Try that first. It has previously failed in this sandbox with
  `getcwd: cannot access parent directories: Operation not permitted` — if it fails again,
  fall back to the manual build+serve flow below.
- **Manual fallback build+serve** — use `./tools/test-web-fresh.sh`. It builds the web
  release and serves it on a brand-new random port every time, printing the URL and PID.
  **Why a new port every time, not the same one**: `python3 -m http.server` sends no
  cache-control headers, and the Browser tool's Chromium caches `main.dart.js` aggressively
  across reloads/navigations — rebuilding and reloading the *same* URL can silently keep
  serving the *old* bundle with no error. A fresh port is a fresh origin, so there's nothing
  to be stale. If you ever build by hand instead, verify the right bundle loaded with
  `fetch('/main.dart.js').then(r=>r.text()).then(t=>t.includes('<a string unique to your new code>'))`
  before clicking through any UI. This is a local-serving artifact only — production Vercel
  already sends `no-cache, no-store, must-revalidate` on `main.dart.js` (see `vercel.json`),
  so it never affects real users.
- Also available: `tools/run-local-web.sh` (hot-reload `flutter run`, port 7357) and
  `docs/LOCALHOST_COMMANDS.md` for the Node-based admin/CSV preview mode.

## Live-testing credentials
- Staff/admin test login: `dev.test.admin@local.test` / PIN `0000`
  (created by the manually-run, non-HTTP-exposed `createDevTestAdminAccount` Apps Script
  function — see Code.gs). **Do not remove** until the chief explicitly says to
  (`removeDevTestAdminAccount` exists for that).
- Demo donors: phone `01911000111` and `01911000222` (PINs get reset ad hoc during testing
  via Settings → দানকারী ব্যবস্থাপনা → দানকারী tab → PIN-reset icon).

## Navigation map (admin web app)
Hamburger menu (top-right) → সেটিংস → scroll down → "প্রতিষ্ঠানের তথ্য" (org branding) /
"দানকারী ব্যবস্থাপনা" (donor approvals / donors / transactions / targets tabs).
Donor portal is a separate login at the same app (`দানকারী পোর্টাল` link on the staff
login screen) — donor auth is `donor_token`-based, fully separate from staff `user_role` auth.

## Deploy discipline (critical — ask before doing, chief currently does these manually)
- **Backend**: `clasp push`, then in the Apps Script editor UI: Deploy → Manage deployments
  → pencil icon on the *existing* deployment → Version: New version → Deploy.
  **Never** use "New Deployment" — it changes the URL and breaks the live app.
- **Frontend**: `git push origin main` → Vercel auto-builds via `vercel.json`.
- One-off Apps Script setup/migration functions (e.g. `migrateFundKeys`,
  `setupDonorNotificationsSheet`) are run manually, once, from the Apps Script editor —
  never wired to an HTTP action (that was tried once for a dev-seed helper and correctly
  blocked by the safety classifier as a security weakening).
- Claude cannot run `clasp push`/`clasp deploy` itself (blocked as "Production Deploy")
  — always hand these back to the chief.

## Google Sheets gotcha
Numeric-looking strings (phone numbers with leading zeros) get silently coerced to
`Number` on write unless the cell's `NumberFormat` is explicitly forced to `'@'`
(plain text) — and this must happen on *every* write path that can rewrite the row
(`appendRow_` and `updateById_`), not just once, or a later full-row rewrite re-triggers
the auto-detection and corrupts the value again.

## Fast backend check (do this before any browser-based verification)
`npm run check:backend` (or `node local-check/backend-smoke.mjs`) hits the **live** Apps
Script backend directly over HTTP — no Flutter build, no browser — and checks public
endpoints, staff login, donor login, and a few authenticated donor reads. It's read-only
against real data, safe to run anytime, and catches a broken deploy or payload-shape bug
in seconds instead of a full UI click-through. Still do the real end-to-end browser
verification afterwards per the rule below — this only replaces the "did the deploy even
work" first pass.

## Verification standard (per chief's rule)
Never report a fix/feature done from passing analyzer/tests alone — confirm it against
the real running app with real data (live Apps Script backend, not mocked), end to end
(e.g. admin resets a donor PIN → actually log in as that donor with the new PIN).

## Global brand standard — set once, apply everywhere, don't re-ask (per chief's rule)
- **Theme**: `mobile-app/lib/core/theme.dart` is the single source of truth for colors
  (`AppBrand` class: deep green + gold + cream). `buildTheme()`/`buildDarkTheme()` both
  derive from it. **Default `themeMode` is `ThemeMode.light`** (`app_shell.dart`) — the
  whole portal (not just the public landing page) should look like the light/cream/gold/
  green landing page. Any new screen just uses `Theme.of(context).colorScheme` and
  inherits this automatically — don't hardcode colors per screen.
- **Logo**: `mobile-app/lib/shared/widgets/org_logo.dart` (`OrgLogo` widget) is the single
  source of truth for the org logo everywhere (bundled asset fallback + live
  `OrgSettings.logoUrl` override). Never use a generic `Icon` as a logo placeholder — use
  `OrgLogo`.
- **Bilingual (Bangla + English)**: `mobile-app/lib/core/app_lang.dart` (`AppLang`) is the
  global i18n switch — `AppLang.t('বাংলা', 'English')` wraps every user-facing string, a
  `ValueNotifier<bool> isEnglish` drives live switching with no rebuild wiring needed
  beyond listening to it (see `app_shell.dart`), and the toggle lives in Settings. This
  pattern is already used 800+ times across the app. **Any new screen or new string must
  use `AppLang.t(bn, en)` from the start** — don't ship Bangla-only UI and leave English
  for later; it just has to be redone.
- These three are already set up project-wide — don't rediscover or re-decide them, just
  use the existing `AppBrand`/`OrgLogo`/`AppLang` primitives for all new work.
