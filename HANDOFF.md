# MadrasahApp — Handoff (2026-10-26)

এই ফাইলটি নতুন Claude Code session শুরুর সময় প্রথমেই পড়তে হবে।
Working directory: `/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro`

---

## সর্বশেষ যা হয়েছে (এই session-এ)

### ✅ Task A — Bulk Scholarship Entry (DONE)
- `mobile-app/lib/features/scholarship/bulk_scholarship_screen.dart` — নতুন screen
- সব beneficiary এক পর্দায়, শেষ মাসের data auto-fill বাটন
- `base_scaffold.dart` — `floatingActionButton` parameter যোগ হয়েছে
- `scholarship_screen.dart` — "বাল্ক প্রদান" বাটন, FundTypeDropdown ব্যবহার

### ✅ Task B — Fund Key Migration (DONE — কিন্তু একটি manual step বাকি)
**নতুন fund keys:**
| পুরনো key | নতুন key | বাংলা নাম |
|-----------|----------|-----------|
| CONSTRUCTION | SADAQAH | সাদাকাহ/দান |
| JAKAT | ZAKAT | যাকাত ফান্ড |
| SCHOLARSHIP | TALEBE_ELM | তালেবে ইলমদের খেদমত ফান্ড |
| (নতুন) | YATIM | ইয়াতিম সহায়তা |
| (নতুন) | BIA | বিয়া ফান্ড |
| (নতুন) | EID | ঈদ উপহার ফান্ড |
| (নতুন) | IFTAR | ইফতার ও সেহরি ফান্ড |
| (নতুন) | FITRA | ফিতরা ফান্ড |
| (নতুন) | LIBRARY | পাঠাগার/কিতাবখানা |
| (নতুন) | WATER | পানি ও পয়ঃনিষ্কাশন |
| GENERAL | (removed) | — |

**Flutter files changed:**
- `lib/shared/constants/fund_types.dart` — নতুন `FundTypes` class, সব 10টি fund
- `lib/shared/widgets/fund_type_dropdown.dart` — shared dropdown widget
- `lib/shared/models/dashboard_summary.dart` — legacy key fallback (`fund()` method)
- `lib/features/dashboard/dashboard_screen.dart` — নতুন fund cards
- `lib/features/donations/donation_screen.dart` — FundTypeDropdown
- `lib/features/expenses/expense_screen.dart` — FundTypeDropdown
- `lib/features/finance_control/finance_control_screen.dart` — FundTypeDropdown
- `lib/features/fees/fee_dues_screen.dart` — FundTypeDropdown
- `lib/features/scholarship/scholarship_screen.dart` — FundTypeDropdown

**Backend (Apps Script):**
- `migrateFundKeys()` function push হয়েছে (`clasp push` সম্পন্ন)

⚠️ **MANUAL STEP PENDING:**
Apps Script editor খুলে একবার `migrateFundKeys` run করতে হবে:
1. https://script.google.com → Madrasah project
2. Function dropdown → `migrateFundKeys` select
3. Run click
→ Sheet-এর পুরনো CONSTRUCTION/JAKAT/SCHOLARSHIP rows নতুন key-তে update হবে

App এখনই backward-compatible — sheet migrate না হলেও চলবে।

### ✅ Task C — Donor Portal (DONE — backend push + Flutter compile clean)

**নতুন files (সব `mobile-app/lib/features/donor/` এ):**
- `donor_session.dart` — SharedPreferences-based donor auth (staff session থেকে আলাদা)
- `donor_api.dart` — public HTTP calls, staff auth ছাড়া
- `donor_login_screen.dart` — phone + PIN login, Islamic slider সহ
- `donor_signup_screen.dart` — full signup form, পেশা dropdown, দেশ+মুদ্রা, PIN
- `donor_home_screen.dart` — welcome card + khat opportunity table + FAB donate
- `donor_donate_screen.dart` — multi-currency (foreign+BDT+rate auto-calc), method, ref
- `donor_dashboard_screen.dart` — ২ tab: summary + ledger (expense links দেখায়)
- `admin_donor_screen.dart` — ৩ tab admin panel (approve, all donors, confirm txns)
- `widgets/islamic_slider.dart` — auto-advancing Quran/Hadith carousel (৫টি slide)

**Entry points:**
- Login screen → "দানকারী পোর্টাল" OutlinedButton → DonorLoginScreen
- Settings screen → "দানকারী ব্যবস্থাপনা" card → AdminDonorScreen (usersManage permission)

**Backend (Apps Script — `backend-apps-script/Code.gs`):**
নতুন sheets: `donors`, `donor_transactions`, `donation_targets`, `expense_donor_links`

Public API (no staff auth):
- `donorRegister` — self-signup, status=PENDING
- `donorLogin` — phone+pin_hash → token (stateless HMAC-MD5)
- `listDonationOpportunities` — active targets + confirmed totals
- `donorDonate` — donor token verify → append donor_transactions
- `donorMyDashboard` — summary + fund-wise breakdown + linked expenses
- `donorMyTransactions` — full ledger with expense links

Admin API (staff auth required):
- `adminListPendingDonors` — users.manage
- `adminListAllDonors` — users.manage
- `approveDonor` — ACTIVE or REJECTED
- `adminListDonorTransactions` — donations.view
- `confirmDonation` — donations.write, auto-creates fund_transaction IN entry
- `setDonationTarget` — donations.write
- `linkExpenseToDonor` — expenses.write

**`clasp push` status:** ✅ Done (2026-10-26)
**`flutter analyze`:** ✅ No issues

---

## Google Sheet info
- Sheet ID: `1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y`
- Apps Script ID: `1xXhVeDUX0ba7xFvlEaEnINgEX3gmTn7Fnxptaz1tVLoACP0xUBC65fD-`
- clasp project: `backend-apps-script/.clasp.json`

---

## এখন যা বাকি আছে (priority order)

### 1. migrateFundKeys() manual run (উপরে বলা হয়েছে)
### 2. নতুন Sheets তৈরি করা
Donor portal কাজ করতে হলে Sheet-এ নতুন tabs থাকতে হবে:
- `donors` — columns: id, name_bn, name_en, phone, email, profession, address, city, country, currency_pref, pin_hash, status, created_at, notes
- `donor_transactions` — columns: id, donor_id, donor_name_bn, fund_type, amount_foreign, currency, exchange_rate, amount_bdt, payment_method, txn_reference, slip_url, status, confirmed_by, confirmed_at, notes, created_at
- `donation_targets` — columns: id, fund_type, title_bn, title_en, target_amount, description_bn, start_date, end_date, is_active, created_at
- `expense_donor_links` — columns: id, expense_id, donor_txn_id, amount_used, notes, created_at

**অথবা** Apps Script-এ একটা `setupDonorSheets()` function লেখা যায় যা automatically এই sheets তৈরি করবে — তারপর একবার run করলেই হবে।

### 3. Donation Target set করা (Admin কাজ)
Admin Settings → দানকারী ব্যবস্থাপনা → কিন্তু `setDonationTarget` এর জন্য UI নেই এখনো।
AdminDonorScreen-এ একটা চতুর্থ tab বা floating button যোগ করতে হবে।

### 4. Expense → Donor Link UI
AdminDonorScreen-এ expense-donor link করার UI নেই।
Expense details screen থেকে একটা "দানকারীর তহবিল থেকে ব্যয়" option যোগ করা যায়।

### 5. Donor Portal testing
- Register → admin approve → login → donate → admin confirm → dashboard দেখা
- Multi-currency flow test

---

## Stack reminder
- Flutter Web (PWA), Google Apps Script backend, Google Sheets as DB
- `AppLang.t(bn, en)` — সব string bilingual
- Dark+light mode সব design-এ
- `BaseScaffold` — সব screen এটা use করে
- `FundTypeDropdown` — সব fund dropdown এটা use করে
- `FundTypes.byKey(key)` — legacy key normalize করে

## clasp push করতে
```bash
cd /Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro/backend-apps-script
npx clasp push
```

## Flutter analyze
```bash
/Users/zakerchy/Desktop/MadrasahApp/.local-tools/flutter/bin/flutter analyze --no-fatal-infos
```
(working dir: `mobile-app/`)
