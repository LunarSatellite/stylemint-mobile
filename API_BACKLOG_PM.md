# API Backlog — PM tracker

**Owner:** PM. This is your coordination workstream + the rollup across all three
role flows. Per-task detail lives in `API_BACKLOG_CUSTOMER.md`,
`API_BACKLOG_CREATOR.md`, `API_BACKLOG_VENDOR.md`.

---

## Rollup (verified audit)

| Flow | FE-only (Sprint 1) | CONFIRM (Sprint 2, needs P1) | NEW (Sprint 3, needs P2) | Rough load |
|------|--------------------|------------------------------|--------------------------|-----------|
| Customer | C1, C3, C4, C5, C6 | C7–C13 (~10 items) | C14 (auth_gate) | ~3 dev-days |
| Creator | CR1–CR4 | CR5–CR9 (5) | CR10 (reel_import) | ~3.5 dev-days |
| Vendor | V1–V4 | V5–V11 (20 items) | V12 (brand_studio) | ~5 dev-days |

**Decision:** customer reels (C2) parked — stays on mock this cycle.

---

## Your tasks

| ID | Task | Effort | Notes |
|----|------|--------|-------|
| P1 | **Swagger reconciliation** — one pass with backend confirming every CONFIRM path. Unblocks C7–C13, CR5–CR9, V5–V11 (~22 items). | M | Your single biggest lever. Use the checklist below. |
| P2 | **File the 3 NEW-backend tickets** day 1 (longest lead time): brand_studio (V12), reel_import (CR10), auth_gate profile-completeness signal (C14). | S | |
| P3 | Stand up tracking board; assign C/CR/V/P task IDs to people. | S | |
| P4 | **Verification gates** — `flutter analyze` + dev-backend walkthrough sign-off per flow before merge. | M | See each role doc's done-definition. |
| P5 | Chase the **notifications empty-inbox auth bug** with backend (blocks C11). | S | Known backend-side bug per code comment. |
| P6 | Daily blocker triage during Sprint 2 (the path-fix wave). | — | |

---

## P1 — Swagger reconciliation checklist (take this to backend, grouped by module)

For each: does the endpoint exist, and what is the canonical path/shape?

**Identity / accounts**
- [ ] Creator identity doc upload — code uses `/v1/creator/documents`; expected `/v1/accounts/{accountId}/verification-documents`? (CR5)
- [ ] Vendor KYC upload + list — `/v1/accounts/{accountId}/verification-documents*`? (V8)
- [ ] Payout methods (creator + vendor) — `/v1/accounts/{accountId}/payout-methods*`? (CR6, V7)

**Catalog / products**
- [ ] Related products for a product (C7)
- [ ] Vendor product detail / status change / delete — list-filter, `/stock`, `/archive`? (V6)
- [ ] Vendor product image upload path (V10)
- [ ] Review summary — dedicated endpoint or client aggregate? (C8)

**Cart / saved**
- [ ] Toggle-save canonical path (`/v1/cart/saved-for-later`) (C7)
- [ ] Group-cart item add/remove via `/v1/cart/lines`; checkout vs `/close` (C13)

**Orders**
- [ ] Vendor order return endpoint (V11)

**Partnerships / matchmaking**
- [ ] Vendor partnerships: briefs vs partnerships vs campaigns namespace — 6 calls (V5)
- [ ] Creator active-partnerships filter (CR7)
- [ ] Vendor matchmaking compatibility-score + invite path (V9)

**Reels / studio**
- [ ] Reel studio delete-draft canonical path (CR8)

**Social**
- [ ] Post share endpoint (C12)
- [ ] Story delete (DELETE vs post-archive) (C12)
- [ ] Drop-party invite + QR scan (C12)
- [ ] Co-watch detail / leave→end / reactions (C13)
- [ ] Tips history + balance — separate or via `/v1/earnings/*`? (CR9)

**Settings / support / notifications**
- [ ] Settings language GET/PUT (C9)
- [ ] Support categories — `/v1/help/categories`? (C10)
- [ ] Notifications inbox prefix `/api/v1/...` + empty-inbox bug (C11, P5)

**NEW endpoints to request (P2 — don't exist yet)**
- [ ] Brand Studio: templates, campaign analytics, market insights (V12)
- [ ] Reel import: product search + import history (CR10)
- [ ] Profile-completeness signal for post-login gating (C14)

---

## Sprint plan
- **Sprint 1:** all 3 devs do FE-only work in parallel; you do P1 + P2 + P3.
- **Sprint 2:** path-fix wave lands once P1 confirms paths; you do P4/P5/P6.
- **Sprint 3:** integrate the 3 NEW endpoints as backend ships them.
