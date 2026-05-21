# Localhost Check Commands

Run from:
`/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite`

## 1) Regenerate normalized data from Excel
```bash
npm run migrate
```

## 2) Start local check server
```bash
npm run check:server
```
Open browser:
- `http://localhost:4123`

## 3) Run smoke test (in another terminal while server is running)
```bash
npm run check:smoke
```

Expected output includes:
- `Smoke OK`
- `Transactions: ...`
- `Balance: ...`

## 4) Stop server
Press `Ctrl + C` in server terminal.
