# Creator backlog — verification sweep

Items from the "Creator Part — Remaining Work Audit" checked against both
repos on 2026-08-11, alongside the work done the same night. Companion to
`VENDOR_BACKLOG_VERIFIED.md`.

**Headline: the audit's two highest-priority frontend items were not work at
all, and its "missing" backend endpoints already exist.** Verify before
scheduling anything from the original document.

## Claim false — the capability already exists

- **CR5 / §2.3.4 `POST /v1/creator/documents` missing.** False, and it should
  not be added. The Identity module already owns the entire KYC pipeline under
  the account scope, shared with vendors:
  `GET/POST /v1/accounts/{id}/kyc-sessions`,
  `POST /v1/accounts/{id}/verification-documents/upload-blob`,
  `POST /v1/accounts/{id}/verification-documents`,
  `POST /v1/accounts/{id}/kyc-sessions/{sessionId}/submit`.
  This was frontend-only work; it is now wired (data layer + apply-flow UI).
- **§9 item 1 / §2.3.1 `creator/support` needs a full data layer.** False, and
  building one would duplicate a working module. The creator screen already
  consumes the shared `features/support/` layer (datasource, DTOs, repository,
  entities, notifier, providers) — a creator-branded screen on a shared
  support module, which is the correct design.
- **CR10 part 1 `GET /v1/creator/products/search` needed so import does not
  require a customer-role token.** False — there is no role gate.
  `GET /api/v1/customer/search` is `[Authorize]` only, and uses the customer
  profile id purely for personalisation. There is also an `[AllowAnonymous]`
  `GET /api/v1/public/search`. A creator token works today.
- **CR10 part 2 `GET /v1/creator/reels/import-history` missing.** False in
  effect. `GET /v1/creator/reels` ("paged list of caller's reels") exists and
  is exactly what the feature needs — the app's `getImportHistory` already
  calls it. A dedicated route would be a rename, not a capability.
- **CR8 `deleteDraft` path mismatch.** Already fixed in code; the datasource
  hits `/v1/creator/studio/drafts/{id}`.
- **§7.2 `creatorActivateNotifierProvider` may be missing.** False. It is
  exported from `apply/shared/providers.dart`.

## True, and done this pass

- **§2.3.2 `creator/search` has no repository or DTOs.** True. Added freezed
  DTOs, `CreatorSearchRepository` + impl, wired the provider, and injected the
  repo into the notifier so failures surface the real message.
- **§7.9 `creator/reels` write methods are datasource-only.** True. Added
  publish/unpublish/tag/untag/listTaggedProducts to the repository, plus a
  `ReelProductTag` entity carrying the tag id that untagging needs, an actions
  notifier, and the reel-detail UI.
- **§7.13 bypassed FutureProviders.** True — eleven of them. All now go
  through repositories for the connectivity guard and typed failures. Domain
  entities were added where only wire models existed, so the domain interfaces
  do not import `data/models`. `brands` had no repository at all.
- **§7.8 / §7.9 unconsumed providers.** True. Import history and creator reel
  summaries now have UI.
- **§2.2 notifier tests.** True. Suites added for search, reel actions,
  social_connect, earnings, partnerships, reach, dashboard, reel_import and
  the new documents notifier. Repo went 68 → 118 tests.

## Defects found that the audit does not mention

These were the real bugs. Three share one shape: error handling that reads
correctly but structurally cannot fire.

1. **Every reel in the customer feed was treated as Instagram.** The Discovery
   feed sends `sourcePlatform` as `.ToString()` of the C# enum — PascalCase,
   and `"YouTubeShorts"` not `"YouTube"` — while the parser compared it to the
   lowercase Dart enum name. Every comparison failed and `orElse` caught it, so
   YouTube reels went to the mp4 player with a null URL (a dead play button)
   and TikTok/Facebook never offered "Watch on ...". Five divergent parsers
   replaced with one tolerant `SocialPlatform.tryParseWire`, locked by tests.
2. **Offscreen YouTube reels played themselves.** `autoPlay: true` plus an
   IFrame player that silently drops `play()`/`pause()` until its WebView is
   ready, plus `allowImplicitScrolling` keeping both neighbours alive — up to
   three videos streaming at once, splitting the connection.
3. **Partnership accept/decline could not fail.** Both awaited the repository
   and discarded the `Either`; the screen caught an exception that never came,
   so a refused accept still showed "Partnership accepted!".
4. **`ReelImportNotifier.importReel`** folded both branches to `null` and had
   no caller. Removed.

## Genuinely outstanding

- **The AI seams** (`IHookScorer`, `IAiBriefingComposer`, `IStoryArcDetector`
  and the analytics lookups) are still `NoOp*`. Real implementations need the
  intelligence module and credentials — out of scope for unattended work, and
  the single biggest functional gap in the creator slice.
- **Nepali / Hindi localisation** needs real translations, not codegen.
- **Device verification.** Nothing shipped tonight has run on a device. The
  platform-routing fix in particular changes behaviour for every reel in the
  customer feed and should be smoke-tested first.
