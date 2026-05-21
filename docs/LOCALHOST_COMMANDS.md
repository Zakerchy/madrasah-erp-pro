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
cd mobile-app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL="https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec"
```
এতে একই app PC browser এ webapp এর মতো চলবে এবং live update দেখা যাবে।

## 6) Stop server
Press `Ctrl + C` in terminal.
