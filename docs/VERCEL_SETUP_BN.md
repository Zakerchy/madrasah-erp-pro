# Vercel Setup (Flutter Web, Zero-Cost)

এই repo-তে এখন `vercel.json` + `tools/vercel-build.sh` ready আছে।
তাই GitHub push হলেই Vercel auto deploy হবে, আর manual build/deploy বারবার করতে হবে না।

## 1) Vercel Project Create
1. Vercel dashboard -> `Add New Project`
2. GitHub repository import করুন: `madrasah-erp-pro`
3. `Framework Preset` = `Other`
4. `Root Directory` = repository root
5. Vercel সাধারণত [`vercel.json`](/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro/vercel.json) থেকে build settings auto-read করবে

## 2) Build Settings
`Project Settings -> Build and Deployment`

Build Command:
```bash
./tools/vercel-build.sh
```

Output Directory:
```text
mobile-app/build/web
```

Install Command:
```text
leave empty
```

Important:
- [`vercel.json`](/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro/vercel.json) already sets SPA rewrite fallback, so browser refresh on routes like `/dashboard` বা `/reports` will keep working
- Next.js style `middleware.ts` এখানে দরকার নেই; Flutter static app-এর জন্য `rewrites + headers` safer solution

## 3) Environment Variables (Vercel)
`Project Settings -> Environment Variables`

Required (recommended):
- `APPS_SCRIPT_URL` = আপনার Apps Script web app URL (`.../exec`)

Optional fallback:
- `API_BASE_URL` = same URL (legacy support)
- `APPS_SCRIPT_DEPLOYMENT_ID` = deployment id only (URL auto-generate)

Optional:
- `BOOTSTRAP_ADMIN_EMAIL` = initial admin bootstrap email
- `APK_DOWNLOAD_URL` = GitHub latest APK direct link
  - current fallback: `https://github.com/Zakerchy/madrasah-erp-pro/releases/download/latest-apk/app-debug.apk`
  - default fallback already works; only custom URL চাইলে env দিন

সব variable `Production`, `Preview`, `Development` environment-এ দিন।

## 4) Production Branch + Auto Deploy
1. `Project Settings -> Git`
2. `Production Branch` = `main`
3. Auto deploy enabled আছে কিনা check করুন

Result:
- Pull Request -> Preview deployment
- `main` এ merge/push -> Production deployment
- একই push এ GitHub Actions `build-android-apk` workflow চলবে এবং latest APK auto rebuild/update হবে
- webapp থেকে APK download button কাজ করাতে GitHub release link valid থাকতে হবে

## 5) Custom Subdomain Add
1. `Project Settings -> Domains`
2. Subdomain add করুন (example: `app.yourdomain.com`)
3. Vercel যেটা CNAME target দেখাবে, DNS provider-এ সেট করুন
4. Status `Valid Configuration` হলে SSL auto issue হবে
5. Recommend:
   - primary app: `app.yourdomain.com`
   - optional admin preview: `erp.yourdomain.com`

## 6) First Smoke Test
1. Vercel deployment URL open করুন
2. Login screen load হচ্ছে কিনা check করুন
3. `Settings -> Notification Controls` open করুন
4. `Check Data Connection` এ health success হচ্ছে কিনা দেখুন
5. mobile browser থেকে `Add to Home Screen` / `Install App` prompt আসে কিনা check করুন
6. Dashboard থেকে APK download link open হচ্ছে কিনা check করুন

## 7) Common সমস্যা ও সমাধান
1. Error: `Apps Script URL সেট করা হয়নি`
- Cause: env var missing
- Fix: `APPS_SCRIPT_URL` set করুন, redeploy দিন
- Local এর জন্য root `.env.local` এ রাখুন, তাহলে প্রতিবার command-এ URL দিতে হবে না

2. 404 on refresh (deep link)
- repo-তে rewrite already added আছে; যদি Vercel old cache serve করে, redeploy দিন

3. Preview works, production fails
- Production env-এ variable missing কিনা check করুন

4. APK button old repo-তে চলে যাচ্ছে
- `APK_DOWNLOAD_URL` env update করুন

## তোমার করণীয় (One-time)
1. Vercel-এ project create + root directory repository root রাখুন
2. Build command/output Vercel auto-detect করেছে কি না verify করুন
3. Env var set
4. Domain DNS set

এরপর code push হলেই deployment auto চলবে।
