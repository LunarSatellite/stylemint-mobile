# API Implementation Backlog

> Generated from a full audit of `lib/features/*` data layers (2026-06-29).
> Auth is complete. Nearly every feature is scaffolded with screens + data
> layers; the remaining work is **API wiring**, not UI. Items are grouped by
> effort/risk so we can knock out the easy wins first.
>
> **Re-verified against the code 2026-10-11 — this backlog is finished.**
> Every section below is done; the boxes were simply never ticked as the work
> landed, so the file had been describing a much earlier state of the app.
> Paths were checked against a route table built from the `[Http*]` attributes
> of all 276 backend controllers (1,115 routes), not `swagger-spec.json`, which
> is four months old (11 Jun 2026) and no longer authoritative.
>
> What is genuinely left for the mobile app is **not API wiring**. It is the
> live page-by-page sweep tracked in `dev/HANDOVER_CODEX.md`, and a short list
> of features that are plumbed end-to-end but unreachable from the UI (group
> cart's add/remove, `/co-watch`, `StoriesScreen`) — product decisions, not
> endpoints.

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

## P1 — Stub features needing a full data layer — **DONE (verified 2026-10-11)**

All eight are wired. Three of them look like stubs if you go by directory
shape — `onboarding`, `vendor/support` and `creator/support` have no `data/`
folder of their own — but that is because they **reuse** an existing layer
rather than duplicate it, which is what you want:

- [x] **social/creator_profile** · **vendor/analytics** ·
      **vendor/creator_performance** · **creator/analytics** ·
      **creator/reels** — each has its own datasource + repository.
- [x] **vendor/support** (1,273 lines) and **creator/support** (1,453 lines) —
      both drive `supportNotifierProvider` / `createTicketNotifierProvider`
      from the platform `support` feature: load tickets, create tickets,
      ticket detail, contact channels. Giving either its own support data
      layer would be a third copy of one that already works.
- [x] **onboarding** — `pick_interests_screen` → `interestsProvider` →
      `auth_remote_datasource`, which covers
      `GET /v1/public/interests` and
      `GET`/`POST`/`DELETE /v1/accounts/{accountId}/interests`.
      `follow_creators_screen` and `follow_brands_screen` run off
      `suggestedCreatorsProvider` / `brandsListProvider` / `followNotifierProvider`.

## P1 — Post-login / core gating — **DONE (verified 2026-10-11)**

- [x] **auth_gate `TODO(#23)`** — `ensureProfile` is a real implementation now
      (`_missingProfileFields`), not the pass-through described here.
- [x] **profile/edit_profile** — avatar upload is wired (`_avatarUploading`,
      `edit_profile_screen.dart:174`) and `deleteAccount()` goes through
      `deleteAccountNotifierProvider`.

## P2 — Endpoint path corrections — **DONE (verified 2026-10-11)**

This section listed ~25 datasource calls whose comments flagged a path as
"not in Swagger" or wrong. Re-checked by grepping every
`*_remote_datasource.dart` for those markers and reading the surviving ones:
**the list is stale**. Its line numbers no longer match the files, and almost
every call has since been corrected — what is left are comments that *explain
a resolved decision* rather than flag an open question (no dedicated
review-summary endpoint, locale lives on the account rather than a language
endpoint, SocialFeed has no media endpoint of its own, there is no
`PUT /status` on vendor products, and so on). Those read as open items only if
you grep for the word "no".

Checked against the controller source rather than `swagger-spec.json` — a
route table built from the `[Http*]` attributes across 276 controllers
(1,115 routes), which is current in a way the June spec is not.

- [x] **social/group_cart** — the two `TODO(swagger)` markers were the last
      genuinely open ones, and they are out of date:
      `POST /v1/cart-shares/{id}/items` and
      `DELETE /v1/cart-shares/{id}/items/{itemId}` both exist
      (`CartSharesController`), and the datasource already calls them with the
      right body. Comments replaced with the verified contract.

**Still worth doing, but it is a UI gap, not an API one:** nothing in
`group_cart/presentation/` calls `GroupCartNotifier.addItem` or `removeItem`.
The feature is plumbed from notifier to endpoint and unreachable from the app
— the same "orphaned route" category as `/co-watch` and `StoriesScreen` in
`dev/HANDOVER_CODEX.md`. Needs a product decision, not a path fix.

## Already WIRED (no API work — verify only)

customer: cart, checkout, reviews · creator: apply, dashboard, reach, social_connect ·
vendor: dashboard, inquiries · social: friends, groups, recommendations, follow ·
platform: notifications, settings, support, payouts, qr_login

---

### Suggested order of attack — all four cleared
1. ~~P0 mock swaps + debug-stub removal~~
2. ~~P1 post-login gating + profile~~
3. ~~P2 backend coordination~~
4. ~~P1 stub data layers~~

Keep this file only as the record of how the wiring was finished. New API work
should be tracked against the live sweep in `dev/HANDOVER_CODEX.md`.
