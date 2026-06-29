# API Backlog — Customer flow

**Owner:** Customer dev · **Scope:** `lib/features/customer/*` + customer-facing
`social/*` + platform features (profile, settings, notifications, support,
onboarding, qr_login, auth_gate).

**Legend** — Class: **FE** frontend-only · **CONFIRM** needs backend path
confirmation (depends on PM-P1), then ~1-line fix · **NEW** backend endpoint
doesn't exist yet (depends on PM-P2). Effort: **S** <1h · **M** ~half-day ·
**L** 1–2 days.

> ⚠️ **Decision:** customer **reels stays on `MockReelsRepository`** this cycle
> (the reel upload/import pipeline can't seed real data yet). The swap is parked
> in the backlog (was task C2) — do not flip it to the real impl now.

---

## Sprint 1 — FE-only quick wins (no backend needed)

| ID | Task | Effort |
|----|------|--------|
| C1 | **orders → real impl.** Swap `MockOrdersRepository` for `OrdersRepositoryImpl` in `lib/features/customer/orders/shared/providers.dart:17` (replacement code is in the comment, lines 11–15). Endpoints already wired: `GET /v1/orders`, `GET /v1/orders/{id}`, `POST /v1/orders/{id}/cancel`, `POST /v1/orders/{id}/returns`. | M |
| C3 | **payment** — remove `if (kDebugMode) return kMockPaymentMethods;` at `lib/features/customer/payment/data/repositories/payment_repository_impl.dart:26`. | S |
| C4 | **saved_items** — remove debug stub at `lib/features/customer/saved_items/data/repositories/saved_items_repository_impl.dart:30`. | S |
| C5 | **shipping** — remove debug stub at `lib/features/customer/shipping/data/repositories/shipping_repository_impl.dart:26`. | S |
| C6 | **profile** — remove `getProfileSummary` debug stub (`lib/features/profile/data/datasources/profile_remote_datasource.dart:35`); swap `MockProfileRepository` in `FollowingNotifier` for the real `ProfileRepositoryImpl`; wire avatar upload (`edit_profile_screen.dart:156`) + `deleteAccount()` (`edit_profile_screen.dart:172`). | M |

## Sprint 2 — path fixes (depends on PM-P1 Swagger reconciliation)

| ID | Task | Effort |
|----|------|--------|
| C7 | **discovery** — confirm related-products path (`discovery_remote_datasource.dart:42`) + toggle-save path (`:70`). | M |
| C8 | **reviews** — review-summary aggregation: client-side or dedicated endpoint? (`reviews_remote_datasource.dart:26`). | S |
| C9 | **settings** — language GET/PUT not in Swagger (`settings_remote_datasource.dart:25,32`). | S |
| C10 | **support** — categories path, maybe `/v1/help/categories` (`support_remote_datasource.dart:36`). | S |
| C11 | **notifications** — confirm `/api/v1/notifications/inbox` prefix + the known empty-inbox auth bug (see PM-P5). | S |
| C12 | **social** — feed share-post (`feed_remote_datasource.dart:92`), stories delete (`stories_remote_datasource.dart:57`), drop_party invite+scan (`drop_party_remote_datasource.dart:60,73`). | M |
| C13 | **social** — group_cart item ops via `/v1/cart/lines` + checkout/close (`group_cart_remote_datasource.dart:47,62,74`); co_watch detail/leave/reactions (`co_watch_remote_datasource.dart:18,50,60,74`). | M |

## Sprint 3 — new backend (depends on PM-P2)

| ID | Task | Effort |
|----|------|--------|
| C14 | **auth_gate** — profile-completeness gating: read backend signal, show `ProfilePromptSheet` (`lib/core/auth_gate/auth_gate.dart:49`). Blocked on a new backend endpoint. | M |

## Backlog (parked)

| ID | Task |
|----|------|
| C2 | reels mock→real swap. Parked — keep on `MockReelsRepository`. Revisit when creator import seeds real reels. |

## Verify-only (already WIRED — just confirm against dev backend)
cart · checkout · friends · groups · recommendations · qr_login · onboarding (UI scaffold; no data layer needed).

## Done-definition (every task)
1. `flutter analyze` clean. 2. Runs vs dev backend (`--dart-define=API_BASE_URL=<dev>`). 3. Flow walked end-to-end, real network calls + graceful failure. 4. Notifier unit test updated where a swap changes behavior (esp. C1).
