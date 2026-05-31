# Vercel Setup (Flutter Web, Zero-Cost)

এই গাইড অনুযায়ী করলে GitHub push হলেই Vercel auto deploy হবে।
manual build/deploy বারবার করতে হবে না।

## 1) Vercel Project Create
1. Vercel dashboard -> `Add New Project`
2. GitHub repository import করুন: `madrasah-erp-pro`
3. `Framework Preset` = `Other`
4. `Root Directory` = `mobile-app`

## 2) Build Settings
`Project Settings -> Build and Deployment`

Build Command:
```bash
set -e
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter config --enable-web >/dev/null
flutter pub get
URL="${APPS_SCRIPT_URL:-${API_BASE_URL:-}}"
if [ -z "$URL" ] && [ -n "${APPS_SCRIPT_DEPLOYMENT_ID:-}" ]; then
  URL="https://script.google.com/macros/s/${APPS_SCRIPT_DEPLOYMENT_ID}/exec"
fi
if [ -z "$URL" ]; then
  echo "Missing APPS_SCRIPT_URL/API_BASE_URL/APPS_SCRIPT_DEPLOYMENT_ID"
  exit 1
fi
flutter build web --release --dart-define=APPS_SCRIPT_URL="$URL"
```

Output Directory:
```text
build/web
```

Install Command:
```text
(empty রাখুন)
```

## 3) Environment Variables (Vercel)
`Project Settings -> Environment Variables`

Required (recommended):
- `APPS_SCRIPT_URL` = আপনার Apps Script web app URL (`.../exec`)

Optional fallback:
- `API_BASE_URL` = same URL (legacy support)
- `APPS_SCRIPT_DEPLOYMENT_ID` = deployment id only (URL auto-generate)

Optional:
- `BOOTSTRAP_ADMIN_EMAIL` = initial admin bootstrap email

সব variable `Production`, `Preview`, `Development` environment-এ দিন।

## 4) Production Branch + Auto Deploy
1. `Project Settings -> Git`
2. `Production Branch` = `main`
3. Auto deploy enabled আছে কিনা check করুন

Result:
- Pull Request -> Preview deployment
- `main` এ merge/push -> Production deployment
- একই push এ GitHub Actions `build-android-apk` workflow চলবে এবং latest APK auto rebuild/update হবে

## 5) Custom Subdomain Add
1. `Project Settings -> Domains`
2. Subdomain add করুন (example: `app.yourdomain.com`)
3. Vercel যেটা CNAME target দেখাবে, DNS provider-এ সেট করুন
4. Status `Valid Configuration` হলে SSL auto issue হবে

## 6) First Smoke Test
1. Vercel deployment URL open করুন
2. Login screen load হচ্ছে কিনা check করুন
3. `Settings -> Notification Controls` open করুন
4. `Check Data Connection` এ health success হচ্ছে কিনা দেখুন

## 7) Common সমস্যা ও সমাধান
1. Error: `Apps Script URL সেট করা হয়নি`
- Cause: env var missing
- Fix: `APPS_SCRIPT_URL` set করুন, redeploy দিন
- Local এর জন্য root `.env.local` এ রাখুন, তাহলে প্রতিবার command-এ URL দিতে হবে না

2. 404 on refresh (deep link)
- সাধারণত Flutter web এর routing issue; build output ঠিক হলে Vercel static fallback handle করে

3. Preview works, production fails
- Production env-এ variable missing কিনা check করুন

## তোমার করণীয় (One-time)
1. Vercel-এ project create + root directory `mobile-app` set
2. Build command/output সেট
3. Env var set
4. Domain DNS set

এরপর code push হলেই deployment auto চলবে।
