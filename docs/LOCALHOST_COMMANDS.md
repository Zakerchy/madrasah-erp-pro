# Localhost Check Commands

Run from:
`/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite`

## 1) Regenerate normalized data from Excel
```bash
npm run migrate
```

## 2) Start admin local web (CSV + Live API mode)
```bash
npm run admin:web
```
Open browser:
- `http://localhost:4123`

## 3) Enable Live Google Sheet mode (optional)
```bash
API_BASE_URL="https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec" npm run admin:web
```
তারপর browser UI থেকে `Live (Google Sheet API)` mode select করুন।

## 4) Run smoke test (local mode)
(server running থাকা অবস্থায়)
```bash
npm run check:smoke
```

Expected output includes:
- `Smoke OK`
- `Transactions: ...`
- `Balance: ...`

## 5) Run Flutter app as local webapp from PC (Admin use)
```bash
./tools/run-local-web.sh
```
তারপর browser এ খুলুন:
- `http://localhost:7357`

Default mode `chrome` (hot reload friendly).
Headless server mode চাইলে:
```bash
./tools/run-local-web.sh web-server
```
এতে একই app PC browser এ webapp এর মতো চলবে এবং update দেখা যাবে।

`pub get` এখন auto-skip করবে যদি dependency আগে থেকেই resolve থাকে।
Force করতে চাইলে:
```bash
FORCE_PUB_GET=1 ./tools/run-local-web.sh
```

Terminal command টাইপ করতে না চাইলে Finder থেকে double-click করুন:
- `tools/start-local-web.command`

## 6) First-time local Flutter install (one-time)
```bash
./tools/setup-local-flutter.sh
```
ইনস্টল হলে Flutter SDK থাকবে:
- `./.local-tools/flutter`

Update ছাড়া fast mode default।
Flutter update করতে চাইলে:
```bash
FLUTTER_UPDATE=1 ./tools/setup-local-flutter.sh
```

## 7) Stop server
Press `Ctrl + C` in terminal.
