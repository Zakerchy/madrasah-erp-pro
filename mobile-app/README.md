# Mobile App (Flutter)

## Setup
1. Install Flutter SDK
2. Run:
   - `flutter pub get`
   - `flutter run`

## Offline + Auto Sync
- Write operations are queued in offline mode when network is unavailable.
- Auto sync triggers:
  - app startup
  - periodic background timer
  - connectivity reconnect
- Manual sync is available from the app bar sync icon.

## Run As PC Web App (Admin)
```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec
```

## Current Status
- Login + role session
- Dashboard summary cards
- Donation/Expense/Salary/Scholarship/Beneficiaries modules
- Reports screen
- Offline queue + auto sync orchestrator
