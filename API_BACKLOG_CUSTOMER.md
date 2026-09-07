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

**Status (2026-07-07): done**, except the avatar-upload sub-item of C6
(moved to Sprint 3 as C15 — no upload endpoint exists on the backend at
all, mobile or otherwise). The three now-orphaned mock files
(`mock_orders_repository.dart`, `mock_profile_repository.dart`,
`payment_mock_data.dart`, `saved_items_mock_data.dart`) were deleted since
nothing referenced them post-swap.

**⚠️ This list was incomplete** — `discovery` and `cart` were *also* still
wired to mock repos and were never listed here at all (`cart` was even
mis-labeled "already WIRED" in the Verify-only section below). Both found
and fixed while confirming Sprint 2/3 items — see C21/C22.

| ID | Task | Effort | Status |
|----|------|--------|--------|
| C1 | **orders → real impl.** Swap `MockOrdersRepository` for `OrdersRepositoryImpl` in `lib/features/customer/orders/shared/providers.dart:17`. | M | ✅ Done |
| C3 | **payment** — remove `if (kDebugMode) return kMockPaymentMethods;` at `lib/features/customer/payment/data/repositories/payment_repository_impl.dart:26`. | S | ✅ Done |
| C4 | **saved_items** — remove debug stub at `lib/features/customer/saved_items/data/repositories/saved_items_repository_impl.dart:30`. | S | ✅ Done |
| C5 | **shipping** — remove debug stub at `lib/features/customer/shipping/data/repositories/shipping_repository_impl.dart:26`. | S | ✅ Done |
| C6 | **profile** — remove `getProfileSummary` debug stub; swap `MockProfileRepository` in `FollowingNotifier` for the real `ProfileRepositoryImpl`; wire `deleteAccount()`. | M | ✅ Done (avatar upload split out as C15) |
| C21 | **discovery → real impl.** `discoveryRepositoryProvider` was still wired to `MockDiscoveryRepository()`; the real `DiscoveryRepositoryImpl` + datasource existed but no `discoveryRemoteDataSourceProvider` had ever been created to wire it. Added the provider, swapped it in. This means every C7 fix below was dead code until now. Also deleted the orphaned `mock_discovery_repository.dart`. | M | ✅ Done |
| C22 | **cart → real impl.** `cartRepositoryProvider` was still wired to `MockCartRepository()` despite being listed as "already WIRED" in Verify-only below. Added `cartRemoteDataSourceProvider`, swapped in the real `CartRepositoryImpl`. Deleted orphaned `mock_cart_repository.dart` + `mock_cart_store.dart`. | M | ✅ Done |

## Sprint 2 — path fixes

**Status (2026-07-07): done**, except where noted "not fixed" below —
those turned out to be missing backend surface or product decisions, not
path bugs, and were moved to Sprint 3 / flagged separately.

| ID | Task | Status |
|----|------|--------|
| C7 | **discovery related-products** — was calling `/v1/public/categories/{productId}/products` (product id where a category slug belongs — always 404/empty). Added `GetRelatedAsync` to `IProductService`/`ProductService` (reuses existing `PageActiveByCategoryAsync`) + `GET /v1/public/products/{id}/related` on `PublicCatalogController`. Mobile now calls the new route and parses the real nested `ProductDto` shape (variants/images), not a flat card shape. | ✅ Fixed (BE: new endpoint, reusing existing repo method — no entity/migration) |
| C7 | **discovery toggle-save** — `toggleSaved` posted to `/v1/cart/saved-for-later` with a bare `productId`, which doesn't exist. Decision: silently add-then-save (no new backend endpoint). Rewrote `toggleSaved` to: check `GET /v1/cart/saved-for-later` for an existing entry for this product → if found, `DELETE` it (unsave); if not, `POST /v1/cart/lines` (qty 1, default variant) then `POST /v1/cart/saved-for-later/from-cart/{lineId}` (save). Along the way, also found and fixed: both `addToCart` implementations (discovery's and cart's) sent `variantId`/`qty` where the backend requires `productVariantId`/`quantity` — would have 400'd on every real add-to-cart call. | ✅ Fixed |
| C8 | **reviews — read side.** Fixed the GET route (public, not the write-only customer controller), fixed field names (`text`/`createdUtc` → `comment`/`createdAt`), and fixed reviewer identity: found `IAccountService.GetSummaryByIdAsync` — Identity's purpose-built cross-module facade "for comment authorship" etc. — already existed and Catalog already had a direct project reference to Identity. Wired it into `ProductReviewService.PageForProductAsync` (hydrates `ReviewerDisplayName`/`ReviewerAvatarUrl` per review, N+1 but pages are small) and added those fields to `ProductReviewDto`. Review summary now derived from the product detail's `averageRating`/`reviewCount` instead of a fabricated summary endpoint. | ✅ Fixed (read side) |
| C8 | **reviews — write side.** Decision: "Write a Review" now lives on a **delivered order's** items (Order Detail screen — new `_ReviewableItemsSection`, shown only when `order.status == delivered`), not the PDP — so `orderId` is available for free. `RateReviewSheet.orderId` is now a param (optional, so the two pre-existing PDP/product-reviews-screen call sites still compile — they just show "open this from a delivered order" instead of a doomed request). Fixed `submitReview`'s body to `{orderId, kind: 0, rating, text}` matching `CreateReviewVm`. Reel-review submission was already a known, separately-flagged stub (fake success, no network call) — untouched. Images aren't sent (no upload endpoint — C15) but still pickable for local preview. Review-likes (`helpfulCount`) still has zero backend support — defaults to 0, not fixed (would be a real new feature, not touched). | ✅ Fixed (written reviews only) |
| C9 | **settings language** — `/v1/settings/language` doesn't exist; locale lives on the account record. Repointed `getCurrentLanguage`/`setLanguage` to `GET`/`PATCH /v1/accounts/{id}` (same endpoint profile-edit already uses), carrying forward the required `displayName`+`rowVersion`. Also fixed English's language code (mobile used `'en'`, backend's allow-list requires exactly `'en-US'` — every other code already matched). | ✅ Fixed (FE only) |
| C10 | **support categories + tickets** — `getSupportCategories` hit a route that never existed; repointed to `/v1/help/categories` (now reachable after the route-prefix fix, see below) and fixed the DTO shape (`id:int`/`name`, not `id:string`/`title`). `createTicket` was sending `{subject, message, categoryId}`; backend needs `{category:<int enum, required>, subject, body}` — fixed field names/types. The create-ticket sheet's category picker was a **hardcoded label list that doesn't map onto the backend's fixed 8-value enum** (no "Other" catch-all exists server-side) — rewired the picker to the already-built-but-unused `CategoriesNotifier` (fetches real categories) instead of inventing a label→enum mapping. | ✅ Fixed |
| C11 | **notifications inbox** — was masked by the same route-prefix bug (mobile had hardcoded `/api/v1/...` to compensate); real bug found underneath: `NotificationInboxController` has no `[Authorize]`, so an expired/missing token doesn't 401 — `GetUserId()` silently returns `Guid.Empty` and the query returns an empty list. This *is* the "empty inbox" bug. Added `[Authorize]` (matches every sibling controller) and dropped the mobile's compensating `/api/` prefix. | ✅ Fixed |
| C12 | **social post-share** — `PostShare` entity, table, and repository method (`AddPostShareAsync`) already existed, fully wired, completely unused. Added `RecordShareAsync` to `IPostService`/`PostService` (reuses `Post.IncrementShareCount` + the existing repo method) and `POST /v1/posts/{id}/share` on `PostController`. Mobile's call already matched — just removed the stale TODO. | ✅ Fixed |
| C12 | **social story-delete** — no delete/soft-delete concept existed on `Story` at all (only automatic 24h expiry). Added `Story.Delete()` (forces `IsExpired = true` immediately, same visibility effect as natural expiry, idempotent) + `IStoryService.DeleteAsync` (ownership-checked) + `DELETE /v1/stories/{id}`. Mobile's call already matched — removed the stale TODO. | ✅ Fixed |
| C12 | **social drop-party list** — `IDropPartyRepository.ListLiveAsync` already existed, unused at the service/controller layer (same pattern as post-share). Added `ListLiveAsync` to `IDropPartyService`/`DropPartyService` + `GET /v1/drop-parties` on `DropPartiesController`. Mobile's `getActiveDropParties()` already called this exact route — no mobile change needed. Only returns **Live** parties, not Scheduled/upcoming — no cross-creator "upcoming" query exists to reuse; flagged if the discover screen needs that too. | ✅ Fixed (live only) |
| C12 | **social drop-party invite + QR-scan.** Decision: mirror CoWatch's `JoinCode` pattern exactly. Added `JoinCode` to `DropParty` (generated at `ScheduleAsync` via the same `OpaqueTokenGenerator.GenerateJoinCode()` + retry-on-collision loop CoWatch uses), migration `20260708_SocialGraph_DropPartyJoinCode` (with a backfill step for any pre-existing rows, since the length-6 check constraint would reject the EF-default `""`), `IDropPartyRepository.GetEntityByJoinCodeAsync`/`JoinCodeExistsAsync`, `IDropPartyService.JoinByCodeAsync` (resolves by code, RSVPs or joins live depending on state, via `.As<T>()` composition — no logic duplication) + `POST /v1/drop-parties/join-by-code`. On mobile: found the **entire "Share Invite" UI already existed** in `drop_party_detail_screen.dart` (code display, copy-to-clipboard, an empty share icon, an empty "Invite Friends" button) — just needed `share_plus` (new dependency, no existing one covered native OS share) wired to the two empty `onPressed`. Removed the dead `inviteToParty`/`invite()` methods (userIds-based, never called from any UI, didn't match the backend at all) from every layer. Fixed a field-name mismatch: backend sends `joinCode`, mobile's domain entity already used `inviteCode` — bridged with `@JsonKey(name: 'joinCode')` rather than renaming the whole mobile feature. `scan_invite_screen.dart` already existed too (manual code entry + dev-simulate button) — repointed its `scanInviteQr` call to the new endpoint. Real camera-based scanning (`mobile_scanner` is installed but unused there) is a nice-to-have left for later — manual entry already fulfills the join function. | ✅ Fixed |
| C13 | **social group_cart/co_watch** — `checkoutGroupCart`/`leaveSession` were blocked on the security issue below (both target endpoints required a client-supplied account id). Now that the security fix removed that requirement, repointed `checkoutGroupCart` to `POST /v1/cart-shares/{id}/close` and `leaveSession` to `POST /v1/co-watch/{id}/end` (both now take no body at all). Also fixed `joinGroupCart`'s field name (`inviteCode` → `token`, matching `AcceptCartShareInvitationVm`). | ✅ Fixed |

### ✅ Security issue found AND fixed (was flagged while confirming C13)

`CartSharesController`, `CoWatchController`, `DropPartiesController`, `StitchesController`, `TipsController`, `StyleCirclesController` (SocialGraph module, Pillar C) had **no `[Authorize]`** and took the acting account id as a **client-supplied body field** (`ActorAccountVm.AccountId`, `EndCoWatchVm.CallerAccountId`, etc.) instead of resolving it from the JWT via `IAuthenticationHelper` — the pattern every other authenticated controller in the codebase uses (e.g. `GroupBuyController` in this same module already does it correctly). As shipped, any caller could act as any account on these six controllers (vote in someone else's cart share, end someone else's co-watch session, etc.) by just changing the id in the request body. **Fixed**: added `[Authorize]` + `IAuthenticationHelper` to all 6 controllers, removed the id fields from 8 ViewModels (deleting 3 that became empty), updated every call site. `dotnet build` clean on `StyleMint.Modules.SocialGraph` and `StyleMint.Core.Api`. Deliberately left alone: `BlockStitchVm`/`ScheduleDropPartyVm`/etc.'s creator/vendor-profile-id fields — those need a deeper "does the caller actually own this profile" service-layer check, not a JWT substitution, and weren't invented here.

### 🔴 Systemic route-prefix bug found while confirming C10/C11

15 controllers across 5 modules were built with a stray `api/` prefix (`[Route("api/v{version:apiVersion}/...")]`) while the rest of the backend (and the mobile app's `baseUrl`) uses `v{version:apiVersion}/...` with no `api/` segment — `docs/ARCHITECTURE.md` §6 documents `/api/v1/...` as canonical, but that contradicts CLAUDE.md and everything actually working today. **Fixed the 6 customer-flow-relevant ones this session** (`SupportTicketsController`, `NotificationPreferencesController`, `LanguagesController`, `HelpController`, `ContactChannelsController`, `NotificationInboxController`). **Still broken** (out of today's scope, confirmed present, not yet fixed):
- `StyleMint.Modules.SocialGraph.Api.Controllers.V1.GroupBuyController` (`api/v1/group-buys`)
- `StyleMint.Modules.Recommendations` — `VoteController`, `ThreadController`, `RequestController`, `ReplyController`, `EndorsementController` (the whole "ask friends" feature)
- `StyleMint.Modules.Discovery.Api.Controllers.V1.DiscoverController` (`api/v1/customer/discover`)
- `StyleMint.Modules.Messaging.Api.Controllers.V1.DeviceController` (`api/v1/devices`)
- `StyleMint.Modules.Messaging.Api.Controllers.V1.WebhookController` (admin-only, lower priority)
- `StyleMint.Modules.Catalog.Api.Controllers.V1.SearchController` (AI search endpoints, method-level `api/` prefix)

## Sprint 3 — new backend

| ID | Task | Effort | Status |
|----|------|--------|--------|
| C14 | **auth_gate** — profile-completeness gating. Turned out not to need a new endpoint: composed existing ones instead. `ensureProfile` now checks `GET /v1/accounts/{id}` (email/phone via `primaryEmail`/`primaryPhone`), `GET /v1/addresses` (shipping, non-empty check), and `GET /v1/accounts/{id}/kyc-sessions` (kyc, any `Approved` session) — no dedicated customer KYC repository existed yet so that one's a direct ad-hoc API call. Built the `ProfilePromptSheet` widget (didn't exist) listing missing fields with a CTA that routes to the real screen (`profileEdit`/`shippingAddEdit`); kyc has no customer-facing verification screen yet so its row isn't actionable. Only real call site (`product_detail_screen.dart`, shipping address before Buy Now) now works end-to-end. | M | ✅ Fixed |
| C15 | **profile** — avatar upload. `edit_profile_screen.dart:162` (`_pickImage`) picks a local file but has no endpoint to upload it to; no presigned-URL or blob-storage upload endpoint exists anywhere in the backend yet (checked: no `UploadsController`, no `/v1/uploads` route). Needs a new backend upload surface before this can wire up. | M | ❌ Skipped per decision — needs an infra choice (storage provider), not a code change. |
| ~~C16~~ | ~~social drop-party invite + QR-scan~~ | ~~M~~ | ✅ Fixed — moved back into C12 above (JoinCode pattern, not a new invitation entity). |
| ~~C17~~ | ~~reviews — write side~~ | ~~L~~ | ✅ Fixed — moved back into C8 above (Order-Detail entry point). Review-likes remains genuinely unbuilt (no table, not touched). |
| C19 | **social group_cart/co_watch** — item-add/remove on group carts, co-watch get-session/reactions have no backend endpoints. No longer blocked on the security issue (fixed) — this is now pure new-endpoint work. | L | ❌ Not fixed |
| C20 | **social group_cart/co_watch create-flow** — `createGroupCart(name, ...)` sends a `name` but `OpenCartShareVm` needs an existing `CartId` (share *an existing personal cart*, no "name" concept exists); `createSession(contentType, contentId, ...)` sends generic content fields but `StartCoWatchVm` only supports `ReelId`. Needs a UI decision: where does the mobile screen get the cart id / reel id from before calling create? | M | ❌ Not fixed |

## Backlog (parked)

| ID | Task |
|----|------|
| C2 | reels mock→real swap. Parked — keep on `MockReelsRepository`. Revisit when creator import seeds real reels. |

## Verify-only (already WIRED — just confirm against dev backend)
checkout · friends · groups · recommendations · qr_login · onboarding (UI scaffold; no data layer needed).
(`cart` and `discovery` were removed from this list — both were actually still on mock repos; see C21/C22 above. Re-checked friends/groups/recommendations/qr_login's provider files directly — none reference a Mock repo.)

## Done-definition (every task)
1. `flutter analyze` clean. 2. Runs vs dev backend (`--dart-define=API_BASE_URL=<dev>`). 3. Flow walked end-to-end, real network calls + graceful failure. 4. Notifier unit test updated where a swap changes behavior (esp. C1).
