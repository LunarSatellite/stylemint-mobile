# API Backlog — Creator flow

**Owner:** Creator dev · **Scope:** `lib/features/creator/*` + creator-facing
social (`creator_profile`, `tips`, `follow`) + `payouts` (Creator role, shared
with Vendor).

**Legend** — Class: **FE** frontend-only · **CONFIRM** needs backend path
confirmation (depends on PM-P1), then ~1-line fix · **NEW** backend endpoint
doesn't exist yet (depends on PM-P2). Effort: **S** <1h · **M** ~half-day ·
**L** 1–2 days.

---

## Sprint 1 — FE-only (build the stub layers, no backend needed)

| ID | Task | Effort |
|----|------|--------|
| CR1 | **creator/analytics** — build data + domain layer (presentation-only today). Source from `/v1/creator/analytics/*`. | M |
| CR2 | **creator/support** — build data + domain layer (tickets). | S |
| CR3 | **social/creator_profile** — build remote layer (currently local-state-only with hardcoded data). Wire `GET /v1/accounts/{id}` + `PATCH /v1/accounts/{id}`. | M |
| CR4 | **creator/reels** — confirm it reuses `customer/reels` data (currently models + screens only); build a layer only if it needs its own. | S |

## Sprint 2 — path fixes (depends on PM-P1 Swagger reconciliation)

| ID | Task | Effort |
|----|------|--------|
| CR5 | **apply** — identity doc upload `/v1/creator/documents` not in Swagger (`creator_remote_datasource.dart:69`). | M |
| CR6 | **earnings** — payout-methods GET/POST should be `/v1/accounts/{accountId}/payout-methods*` (`earnings_remote_datasource.dart:72,106`). | M |
| CR7 | **partnerships** — `getActivePartnerships()` needs a status filter / dedicated endpoint (`partnerships_remote_datasource.dart:48`). | M |
| CR8 | **reel_studio** — `deleteDraft` path mismatch (`reel_studio_remote_datasource.dart:89`). | M |
| CR9 | **tips** — history + balance missing; likely use `/v1/earnings/*` (`tips_remote_datasource.dart:30,42`). | M |

## Sprint 3 — new backend (depends on PM-P2)

| ID | Task | Effort |
|----|------|--------|
| CR10 | **reel_import** — `search-products` + `import-history` endpoints don't exist (`reel_import_remote_datasource.dart:46,64`). Note: the core import POST `/v1/creator/reels/import` is already wired; this adds product-tagging-on-import + history. | L |

## Verify-only (already WIRED — just confirm against dev backend)
dashboard · reach · social_connect · follow · payouts (Creator role).

## Done-definition (every task)
1. `flutter analyze` clean. 2. Runs vs dev backend. 3. Creator flow walked end-to-end, real network calls + graceful failure. 4. Notifier unit test added for new data layers (CR1–CR3).
