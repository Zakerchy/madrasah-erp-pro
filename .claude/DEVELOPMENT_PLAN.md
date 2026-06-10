# Madrasah ERP Pro — Development Plan

Last updated: 2026-06-08

---

## Data Status (Confirmed)

| Fund | IN | OUT | Balance | Status |
|------|----|-----|---------|--------|
| নির্মাণ ও সাদাকাহ (CONSTRUCTION) | 10,75,625 | 9,70,807 | 1,04,818 | ✅ 97টি expense সহ সব import হয়েছে |
| যাকাত (JAKAT) | 3,98,595 | 2,43,800 | 1,54,795 | ✅ Import হয়েছে |
| শিক্ষাবৃত্তি (SCHOLARSHIP) | 2,25,000 | 1,95,000 | 30,000 | ✅ Import হয়েছে |
| **মোট** | **16,99,220** | **14,09,607** | **2,89,613** | ✅ |

**Known data issue:** যেসব row-এ Excel-এ date ছিল না সেগুলো fallback date `2022-04-10` পেয়েছে।
Scholarship Jan–Apr 2026 entries-এর date fixed করা হয়েছে।

---

## Phase 1 — Critical Validation (এখনই করতে হবে)

> লক্ষ্য: ডেটা integrity নিশ্চিত করা — ভুল data ঢোকার পথ বন্ধ করা

| # | Task | File | Done? |
|---|------|------|-------|
| 1.1 | Future date reject — সব entry form-এ ভবিষ্যৎ তারিখ block | dashboard, donations, expenses, salary | ✅ |
| 1.2 | Amount bounds — ০ এর নিচে ও unreasonable amount reject | সব entry form | ✅ |
| 1.3 | Salary cross-validation — paid ≤ payable, due = payable − paid auto | `salary_screen.dart` | ✅ |
| 1.4 | Scholarship auto-sum — components যোগ = total_paid auto-calculate | `scholarship_screen.dart` | ✅ |
| 1.5 | Beneficiary age bounds validation (৫–৩০) | `beneficiaries_screen.dart` | ✅ |
| 1.6 | Duplicate transaction warning (same amount+source ২৪ঘণ্টায়) | donations, expenses | ✅ |

---

## Phase 2 — Dashboard Automation (High Priority)

> লক্ষ্য: Real-time alerts ও auto-calculation

| # | Task | File | Done? |
|---|------|------|-------|
| 2.1 | Balance alert — কোনো fund negative হলে dashboard-এ লাল warning | `dashboard_screen.dart` | ✅ |
| 2.2 | Budget overspend indicator — planned vs actual comparison | `finance_control_screen.dart` | ☐ |
| 2.3 | Offline confirmation dialog — offline-এ transaction-এ warning | `dashboard_screen.dart` | ✅ |
| 2.4 | Quick entry duplicate detection (২৪ঘণ্টায় same amount+fund) | `dashboard_screen.dart` _quickEntry() | ✅ |
| 2.5 | Fund summary export button (CSV/share) from dashboard | `dashboard_screen.dart` | ☐ |

---

## Phase 3 — Scholarship Automation (High Priority)

> লক্ষ্য: মাসিক scholarship process automated করা

| # | Task | File | Done? |
|---|------|------|-------|
| 3.1 | Bulk scholarship entry — এক screen-এ সব beneficiary-র payment | `scholarship_screen.dart` | ☐ |
| 3.2 | Monthly auto-generate — বিগত মাসের pattern থেকে new month pre-fill | `scholarship_screen.dart` | ☐ |
| 3.3 | Over-payment warning — monthly_need_amount-এর বেশি হলে alert | `scholarship_screen.dart` | ✅ (Phase 1.4) |
| 3.4 | Scholarship fund balance check — পেমেন্টের আগে fund sufficient কিনা | `scholarship_screen.dart` | ✅ |
| 3.5 | Remaining amount auto-calculate — monthly_need − paid | `scholarship_screen.dart` | ✅ (Phase 1.4) |

---

## Phase 4 — Academic Automation (Medium Priority)

> লক্ষ্য: Attendance ও exam workflow automate করা

| # | Task | File | Done? |
|---|------|------|-------|
| 4.1 | Bulk attendance entry — teacher একসাথে পুরো class mark করবে | `academic_core_screen.dart` | ✅ (already existed) |
| 4.2 | Absence threshold alert — N দিন অনুপস্থিত হলে dashboard-এ flag | `academic_foundation_screen.dart` | ☐ |
| 4.3 | Grade auto-calculate — marks থেকে GPA/grade/position automatic | `academic_core_screen.dart` | ✅ (backend returns grades) |
| 4.4 | Result sheet generation — term-wise printable report | `academic_core_screen.dart` | ✅ Share button added |
| 4.5 | Student promotion logic — grade threshold পূরণ হলে auto next class | `academic_core_screen.dart` | ☐ |
| 4.6 | Duplicate student detection (same name+class) | `academic_foundation_screen.dart` | ✅ |

---

## Phase 5 — Fee Management Automation (Medium Priority)

> লক্ষ্য: Fee collection process automated করা

| # | Task | File | Done? |
|---|------|------|-------|
| 5.1 | Auto fee plan assign — নতুন student যোগে fee plan auto-assign | `fee_dues_screen.dart` | ☐ |
| 5.2 | Overdue fee indicator — due date পার হলে highlight | `fee_dues_screen.dart` | ✅ Red/green color on due_amount |
| 5.3 | Bulk fee payment entry — multiple students এক screen-এ | `fee_dues_screen.dart` | ☐ |
| 5.4 | Waiver amount validation — waiver ≤ total due | `fee_dues_screen.dart` | ✅ |
| 5.5 | Fee collection report — class-wise monthly summary | `fee_dues_screen.dart` | ☐ |

---

## Phase 6 — Salary & HR Automation (Medium Priority)

| # | Task | File | Done? |
|---|------|------|-------|
| 6.1 | Salary auto-calculate — staff master থেকে monthly amount pull | `salary_screen.dart` | ✅ Auto-fill from monthly_salary |
| 6.2 | Due amount auto = payable − paid | `salary_screen.dart` | ✅ (Phase 1.3) |
| 6.3 | Salary slip generation (sharable text/PDF) | `salary_screen.dart` | ✅ Share button per payment |
| 6.4 | Arrears summary — কোন মাসের salary বাকি তার list | `salary_screen.dart` | ☐ |
| 6.5 | High salary approval workflow (threshold-এর উপরে) | `salary_screen.dart` | ☐ |

---

## Phase 7 — Reports & Export (Medium Priority)

| # | Task | File | Done? |
|---|------|------|-------|
| 7.1 | PDF export — reports screen থেকে | `reports_screen.dart` | ☐ (requires pdf package) |
| 7.2 | Excel export — fund transactions | `reports_screen.dart` | ✅ (CSV share already exists) |
| 7.3 | YoY/MoM comparison — বছর/মাস তুলনা | `reports_screen.dart` | ✅ (monthly/range/yearly modes) |
| 7.4 | Drill-down from summary to transaction list | `reports_screen.dart` | ✅ (transaction list view) |
| 7.5 | Scheduled monthly report (auto-generate on 1st of month) | backend (Apps Script) | ☐ |
| 7.6 | Anomaly detection — unusual transaction highlight | `reports_screen.dart` | ✅ Orange highlight ≥ 3× avg |

---

## Phase 8 — Communication & Notifications (Lower Priority)

| # | Task | File | Done? |
|---|------|------|-------|
| 8.1 | Push notification when notice published | `communication_documents_screen.dart` | ☐ |
| 8.2 | Approval request auto-escalation (N দিনের মধ্যে decision না হলে) | `finance_control_screen.dart` | ☐ |
| 8.3 | Document expiry tracking | `communication_documents_screen.dart` | ☐ |

---

## Completed Tasks Log

| Date | Task | Details |
|------|------|---------|
| 2026-06-08 | Data import | Excel থেকে 302 fund transactions, 10 beneficiaries, 60 scholarship payments import |
| 2026-06-08 | Number format fix | লাখ/কোটি abbreviation সরিয়ে full digit format (৳1,07,5625) |
| 2026-06-08 | Fund detail page | Default "সকল সময়" (all-time) — শুধু monthly না |
| 2026-06-08 | Separation card | নির্মাণ ও সাদাকাহ ফান্ড clearly labeled, clickable |
| 2026-06-08 | CONSTRUCTION label | "নির্মাণ ও সাদাকাহ" rename (Excel column হুবহু) |
| 2026-06-08 | Scholarship date fix | Jan–Apr 2026 entries-এর wrong fallback date corrected |
| 2026-06-09 | Phase 1 complete | Future date block, amount bounds, salary auto-due, scholarship auto-sum+overpay warning, beneficiary age 5-30, duplicate detection (24h) |
| 2026-06-09 | Phase 2 (2.1,2.3,2.4) | Dashboard: negative balance red alert, offline dialog, quick-entry 24h duplicate detection |
| 2026-06-09 | Phase 4 (4.4,4.6) | Result sheet share button, duplicate student detection |
| 2026-06-09 | Phase 5 (5.2,5.4) | Overdue fee red/green color, waiver ≤ planned validation |
| 2026-06-09 | Phase 6 (6.1,6.3) | Salary auto-fill from staff monthly_salary, salary slip share |
| 2026-06-09 | Phase 3.4 | Scholarship fund balance check before payment |
| 2026-06-09 | Phase 7.6 | Anomaly detection — orange highlight for transactions ≥ 3× average |

---

## Architecture Notes

- **Backend:** Google Apps Script → Google Sheets (spreadsheetId: `14TC8APxdseH-UGiHgVNhbEjT2Bzy3EJHBidHoEpGZbI`)
- **Frontend:** Flutter Web (port 7357)
- **Local test server:** Node.js (port 4123) reads from `tools/output/migrated_*.csv`
- **Fund types in data:** CONSTRUCTION (নির্মাণ+সাদাকাহ combined), JAKAT, SCHOLARSHIP
- **GENERAL fund:** Empty — Excel-এ সাদাকাহ আলাদা column ছিল না, CONSTRUCTION-এ merged
- **Admin login:** phone `01700000000`, PIN `1234`
- **App run command:** `npm run app:web:chrome` (from madrasah-erp-pro/)
