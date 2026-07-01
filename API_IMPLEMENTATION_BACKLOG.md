# API Implementation Backlog

> Generated from a full audit of `lib/features/*` data layers (2026-06-29).
> Auth is complete. Nearly every feature is scaffolded with screens + data
> layers; the remaining work is **API wiring**, not UI. Items are grouped by
> effort/risk so we can knock out the easy wins first.

Legend — per-feature status used below:
- **WIRED** — datasource hits a real `/v1/...` endpoint and the real repository is injected.
- **PARTIAL** — mostly wired, but has a debug stub or one or two unresolved endpoints.
- **MOCK** — real impl exists but a `mock_*_repository` is currently injected.
- **STUB** — presentation-only; no data/domain layer yet.

---

## P0 — Swap mock repositories to real impls (code already exists)

These have a complete `*RepositoryImpl` + remote datasource already written.
The only change is wiring `shared/providers.dart` to the real impl and testing
against the backend. Lowest effort, highest payoff.

- [ ] **customer/orders** — wire `ordersRepositoryProvider` → `OrdersRepositoryImpl`
      (currently `MockOrdersRepository`). `lib/features/customer/orders/shared/providers.dart:17`
      Endpoints ready: `GET /v1/orders`, `GET /v1/orders/{id}`, `POST /v1/orders/{id}/cancel`, `POST /v1/orders/{id}/returns`.
- [ ] **customer/reels** — wire `reelsRepositoryProvider` → `ReelsRepositoryImpl`
      (currently `MockReelsRepository`). `lib/features/customer/reels/shared/providers.dart:24`
      Endpoints ready: feed, detail, like/unlike, wishlist, follow, comment, share.
      Also integrate the unused `ReelCommentsRemoteDataSource` for comments.
- [ ] **profile** — `FollowingNotifier` uses `MockProfileRepository`; swap to real `ProfileRepositoryImpl`.

## P0 — Remove debug-mode stubs (`if (kDebugMode) return <mock>`)

Real endpoints are wired but short-circuited in debug. Remove the stub branch
and verify against the live backend. (Marked `ponytail:` in code.)

- [ ] **customer/payment** — `getPaymentMethods()` mock branch. `lib/features/customer/payment/data/repositories/payment_repository_impl.dart:25`
- [ ] **customer/saved_items** — `getSavedItems()` mock branch. `lib/features/customer/saved_items/data/repositories/saved_items_repository_impl.dart:30`
- [ ] **customer/shipping** — `getAddresses()` mock branch. `lib/features/customer/shipping/data/repositories/shipping_repository_impl.dart:26`
- [ ] **profile** — `getProfileSummary()` mock branch. `lib/features/profile/data/datasources/profile_remote_datasource.dart` (`kMockProfileSummaryDto`).

---

## P1 — Stub features needing a full data layer

Presentation exists but there is **no datasource/repository**. Each needs
domain entities, a remote datasource, a repository impl, and `shared/providers.dart`.

- [ ] **onboarding** — pick-interests / follow-creators / follow-brands screens have no data layer.
      Needs interests + follow endpoints (coordinate with `stylemint-onboarding`).
- [ ] **social/creator_profile** — only local state notifiers (image picker, edit form).
      Needs `GET /v1/accounts/{id}` + `PATCH /v1/accounts/{id}`.
- [ ] **vendor/analytics** — presentation only. Wire to `/v1/vendor/analytics/*`.
- [ ] **vendor/creator_performance** — DTO only, no datasource/repo. Confirm endpoint (likely `/v1/vendor/.../creator-analytics`).
- [ ] **vendor/support** — presentation only. Wire to support/tickets endpoints.
- [ ] **creator/analytics** — presentation only (data sourced ad-hoc from dashboard/earnings today). Decide if a dedicated layer is needed.
- [ ] **creator/support** — presentation only. Wire to support/tickets.
- [ ] **creator/reels** — presentation + DTO only; confirm whether it should reuse customer/reels data or own a layer.

---

## P1 — Post-login / core gating

- [ ] **auth_gate `TODO(#23)`** — read backend profile-completeness signal and
      show `ProfilePromptSheet` for missing mandatory fields.
      `lib/core/auth_gate/auth_gate.dart:49`. Blocked on backend endpoint; today
      `ensureProfile()` is a pass-through and the server enforces via 4xx.
- [ ] **profile/edit_profile** — wire avatar upload via `updateProfile(avatarPath:)`
      (`edit_profile_screen.dart:156`) and the `deleteAccount()` call (`:172`).

---

## P2 — Endpoint path corrections / backend coordination

These call paths that the datasource comments flag as **not in Swagger** or
the wrong path. Each needs backend confirmation, then a one-line path fix.
Grouped by domain.

### Customer
- [ ] discovery — related-products path uncertain. `discovery_remote_datasource.dart:42`
- [ ] discovery — toggle-save path uncertain. `discovery_remote_datasource.dart:70`
- [ ] reviews — no review-summary endpoint; currently re-uses reviews list. `reviews_remote_datasource.dart:26`

### Creator
- [ ] apply — identity doc upload `/v1/creator/documents` not in Swagger. `creator_remote_datasource.dart:69`
- [ ] earnings — payout-methods GET/POST should be `/v1/accounts/{accountId}/payout-methods*`. `earnings_remote_datasource.dart:72,106`
- [ ] partnerships — `getActivePartnerships()` needs status filter / dedicated endpoint. `partnerships_remote_datasource.dart:48`
- [ ] reel_import — `search-products` + `import-history` paths not in Swagger. `reel_import_remote_datasource.dart:46,64`
- [ ] reel_studio — `deleteDraft` path mismatch (`reel-studio/drafts` vs `recipes/draft`). `reel_studio_remote_datasource.dart:89`

### Vendor
- [ ] add_product — image upload `POST /v1/vendor/products/images` not in Swagger. `add_product_remote_datasource.dart:66`
- [ ] apply — KYC upload/list should use `/v1/accounts/{accountId}/verification-documents*`. `vendor_remote_datasource.dart:49,71`
- [ ] brand_studio — templates/analytics/insights endpoints all need correct paths (templates under admin scope). `brand_studio_remote_datasource.dart:9,23,33`
- [ ] earnings — ledger + payout-methods endpoints need correct paths. `vendor_earnings_remote_datasource.dart:17,32,41`
- [ ] matchmaking — compatibility-score missing; invite should be `POST /v1/vendor/matches/{id}/invite`. `matchmaking_remote_datasource.dart:23,31`
- [ ] orders — return endpoint not in Swagger. `vendor_orders_remote_datasource.dart:57`
- [ ] partnerships — 6 calls need remap to `/v1/vendor/briefs` + `/v1/vendor/partnerships/*`. `vendor_partnerships_remote_datasource.dart:10,19,35,52,72,89`
- [ ] products — product-detail / status / delete should use list-filter, `/stock` or `/archive`. `vendor_products_remote_datasource.dart:26,32,49`

### Social
- [ ] co_watch — GET `{id}`, leave→`/end`, reactions endpoints missing. `co_watch_remote_datasource.dart:18,49,60,74`
- [ ] drop_party — invite + scan/QR endpoints missing. `drop_party_remote_datasource.dart:60,73`
- [ ] feed — share-post endpoint missing. `feed_remote_datasource.dart:92`
- [ ] group_cart — item add/remove should use `/v1/cart/lines`; checkout vs `/close`. `group_cart_remote_datasource.dart:47,62,74`
- [ ] stories — delete path conflict (DELETE `/v1/stories/{id}` vs post archive). `stories_remote_datasource.dart:57`
- [ ] tips — tip history + balance missing; consider `/v1/earnings/*`. `tips_remote_datasource.dart:30,42`

### Platform
- [ ] settings — language endpoint not in Swagger (currently kept as-is). `settings_remote_datasource.dart:25,32`
- [ ] support — categories endpoint may be `/v1/help/categories`. `support_remote_datasource.dart:36`

---

## Already WIRED (no API work — verify only)

customer: cart, checkout, reviews · creator: apply, dashboard, reach, social_connect ·
vendor: dashboard, inquiries · social: friends, groups, recommendations, follow ·
platform: notifications, settings, support, payouts, qr_login

---

### Suggested order of attack
1. **P0 mock swaps + debug-stub removal** — unblocks the full customer happy path end-to-end against the real backend.
2. **P1 post-login gating + profile** — completes the first-run experience after auth.
3. **P2 backend coordination** — batch the "not in Swagger" list into one backend conversation, then apply path fixes.
4. **P1 stub feature data layers** — build out per business priority (likely vendor/analytics + onboarding first).
