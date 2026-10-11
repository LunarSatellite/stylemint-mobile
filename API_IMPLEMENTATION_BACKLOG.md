# API Implementation Backlog

> Generated from a full audit of `lib/features/*` data layers (2026-06-29).
> Auth is complete. Nearly every feature is scaffolded with screens + data
> layers; the remaining work is **API wiring**, not UI. Items are grouped by
> effort/risk so we can knock out the easy wins first.
>
> **Re-verified against the code 2026-10-11.** Both P0 sections are done, and
> most of P1 with them — the boxes below were never ticked as the work landed,
> so the file had been overstating what is left. P2 is untouched: every item
> there needs the backend to confirm a path, and `swagger-spec.json` is itself
> four months old (11 Jun 2026), so it cannot settle them either. Re-generate
> the spec from a running backend before working that section.

Legend — per-feature status used below:
- **WIRED** — datasource hits a real `/v1/...` endpoint and the real repository is injected.
- **PARTIAL** — mostly wired, but has a debug stub or one or two unresolved endpoints.
- **MOCK** — real impl exists but a `mock_*_repository` is currently injected.
- **STUB** — presentation-only; no data/domain layer yet.

---

## P0 — Swap mock repositories to real impls — **DONE (verified 2026-10-11)**

No `Mock*Repository` is injected anywhere in `lib/` any more; the only
remaining matches are two commented-out lines in `main.dart`. The mock
scaffolding those swaps left behind (`profile_mock_data.dart`,
`reels_mock_data.dart`, `mock_reels_repository.dart`,
`orders_mock_data.dart`) was dead and has been deleted.

- [x] **customer/orders** — `OrdersRepositoryImpl` injected.
- [x] **customer/reels** — `ReelsRepositoryImpl` injected.
- [x] **profile** — `FollowingNotifier` on the real repository.

## P0 — Remove debug-mode stubs — **DONE (verified 2026-10-11)**

No `if (kDebugMode) return <mock>` branch survives. The eight remaining
`kDebugMode` references in `lib/` are all ordinary debug logging.

- [x] customer/payment · [x] customer/saved_items · [x] customer/shipping · [x] profile

## P1 — Stub features needing a full data layer — **5 of 8 done**

Checked 2026-10-11 by looking for a remote datasource + repository impl under
each feature.

- [x] **social/creator_profile** — 2 datasources, 3 repository files.
- [x] **vendor/analytics**
- [x] **vendor/creator_performance**
- [x] **creator/analytics**
- [x] **creator/reels**
- [ ] **onboarding** — still presentation-only. Needs interests + follow
      endpoints (coordinate with `stylemint-onboarding`).
- [ ] **vendor/support** — still presentation-only. Wire to support/tickets.
- [ ] **creator/support** — still presentation-only. Wire to support/tickets.

The two support stubs are the same job twice; do them together.

## P1 — Post-login / core gating — **DONE (verified 2026-10-11)**

- [x] **auth_gate `TODO(#23)`** — `ensureProfile` is a real implementation now
      (`_missingProfileFields`), not the pass-through described here.
- [x] **profile/edit_profile** — avatar upload is wired (`_avatarUploading`,
      `edit_profile_screen.dart:174`) and `deleteAccount()` goes through
      `deleteAccountNotifierProvider`.

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
1. ~~P0 mock swaps + debug-stub removal~~ — done.
2. ~~P1 post-login gating + profile~~ — done.
3. **P2 backend coordination** — the whole section still stands, but it cannot
   be worked from the checked-in `swagger-spec.json` (4 months stale). Bring the
   backend up, regenerate the spec, then batch the "not in Swagger" list into one
   conversation and apply the path fixes.
4. **P1 stub data layers** — onboarding, then the two support stubs together.
