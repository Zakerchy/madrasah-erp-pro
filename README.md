# Madrasah ERP Lite

A zero-cost, Google-Sheet-connected, Android-first native app plan and implementation scaffold for madrasah management.

## Goals
- Unified donation, expense, salary, scholarship, and beneficiary management
- Live sync with Google Sheets using Google Apps Script API
- Print/share-ready monthly reports
- Role-based access with audit trail

## Project Structure
- `docs/` architecture, schema, API, migration and roadmap docs
- `phase-tracker/` implementation phases with completion tracking
- `sheets/` spreadsheet templates and headers
- `backend-apps-script/` Google Apps Script backend (REST-like)
- `mobile-app/` Flutter app scaffold and feature modules
- `tools/` Excel migration and normalization scripts

## First Execution Order
1. Prepare Google Sheet using templates from `sheets/`
2. Deploy `backend-apps-script/` as Web App
3. Configure endpoint + sheet ID in mobile app config
4. Run migration tools on existing Excel files
5. Start pilot data entry and verification

## Current Status
- Phase 1-4 implementation completed (see `phase-tracker/IMPLEMENTATION_PHASES.md`)
- End-to-end testing instructions: `docs/PHASE4_TEST_GUIDE.md`
