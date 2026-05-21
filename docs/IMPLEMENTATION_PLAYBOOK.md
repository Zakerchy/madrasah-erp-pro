# Coding Implementation Playbook

## Objective
Deliver a fully usable, no-cost Madrasah management native app integrated with Google Sheets.

## Milestone Plan

### Milestone A (Current)
- Scaffold complete
- Schema and API drafts complete
- Core backend endpoints created
- Mobile module placeholders created

### Milestone B
- Finalize columns based on real Excel mapping
- Add strict backend validation and permission checks
- Add master data screens (beneficiary/staff)

### Milestone C
- Complete transactions + expense + salary workflows
- Scholarship monthly distribution fully functional
- Reconciliation view (fund-wise)

### Milestone D
- Reports, PDF export, share text
- Pilot rollout + feedback patch

## Developer Checklist
1. Configure Sheet and endpoint
2. Verify headers exactly match template
3. Seed users_roles with at least one ADMIN
4. Test donation IN and expense OUT
5. Verify dashboard balance consistency
6. Test scholarship payment + linked transaction

## Non-Negotiable Controls
- No hard delete in production
- Every update writes audit_log
- Balance always derived from transactions
- Role check before write actions

## Suggested Cadence
- Daily: 1 feature + 1 verification
- Weekly: one reconciliation review with stakeholders
