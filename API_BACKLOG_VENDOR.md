# API Backlog — Vendor flow

**Owner:** Vendor dev · **Scope:** `lib/features/vendor/*` + `payouts` (Vendor
role, shared with Creator). **This is the heaviest backend-coordination load** —
20 CONFIRM items across 7 features.

**Legend** — Class: **FE** frontend-only · **CONFIRM** needs backend path
confirmation (depends on PM-P1), then ~1-line fix · **NEW** backend endpoint
doesn't exist yet (depends on PM-P2). Effort: **S** <1h · **M** ~half-day ·
**L** 1–2 days.

---

## Sprint 1 — FE-only (build missing layers, no backend needed)

| ID | Task | Effort |
|----|------|--------|
| V1 | **inquiries** — datasource + DTO exist; add the repository + domain layer to complete the feature. | M |
| V2 | **vendor/analytics** — build data + domain layer (presentation-only today). Source from `/v1/vendor/analytics/*`. | M |
| V3 | **vendor/creator_performance** — DTO exists; build datasource + repository + domain layer. | M |
| V4 | **vendor/support** — build data + domain layer (contact/tickets). | S |

## Sprint 2 — path fixes (depends on PM-P1 Swagger reconciliation)

| ID | Task | Effort |
|----|------|--------|
| V5 | **partnerships** — remap 6 calls to `/v1/vendor/briefs` + `/v1/vendor/partnerships/*` (`vendor_partnerships_remote_datasource.dart:10,19,35,52,72,89`). | L |
| V6 | **products** — detail/status/delete → list-filter, `/stock`, `/archive` (`vendor_products_remote_datasource.dart:26,32,49`). | M |
| V7 | **earnings** — ledger + payout-methods paths (`vendor_earnings_remote_datasource.dart:17,32,41`). | L |
| V8 | **apply** — KYC upload/list → `/v1/accounts/{accountId}/verification-documents*` (`vendor_remote_datasource.dart:49,71`). | M |
| V9 | **matchmaking** — compatibility-score missing; invite → `/v1/vendor/matches/{id}/invite` (`matchmaking_remote_datasource.dart:23,31`). | M |
| V10 | **add_product** — image upload `/v1/vendor/products/images` not in Swagger (`add_product_remote_datasource.dart:66`). | M |
| V11 | **orders** — return endpoint not in Swagger (`vendor_orders_remote_datasource.dart:57`). | S |

## Sprint 3 — new backend (depends on PM-P2)

| ID | Task | Effort |
|----|------|--------|
| V12 | **brand_studio** — templates (admin scope?), analytics, insights — all 3 endpoints missing (`brand_studio_remote_datasource.dart:9,23,33`). | L |

## Verify-only (already WIRED — just confirm against dev backend)
dashboard · payouts (Vendor role).

## Done-definition (every task)
1. `flutter analyze` clean. 2. Runs vs dev backend. 3. Vendor flow walked end-to-end, real network calls + graceful failure. 4. Notifier unit test added for new data layers (V1–V3).
