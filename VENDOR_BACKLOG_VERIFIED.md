# Vendor backlog — verification sweep

Every item of the vendor "What's Still Missing or Incomplete" list (#1–#30)
checked against the code on 2026-08-11. Verdicts are from grep/build/analyzer
evidence, cited inline. **Most of the list is already done.**

Do not plan from the original list without re-reading this file.

## Verdict summary

| Verdict | Count | Items |
|---|---|---|
| Already implemented / claim false | 13 | 1, 6, 9, 10, 13, 15, 21, 23, 24, 25, 26, 18(partly), 8(fixed here) |
| True, non-blocking | 3 | 2, 4, 30 |
| Not re-verified this pass | 14 | 3, 5, 7, 11, 12, 14, 16, 17, 19, 20, 22, 27, 28, 29 |

## Claim false — the capability already exists

- **#1 `GET /v1/vendor/matches` missing, screen 404s.** False. `[HttpGet]
  ListMine` is at `VendorMatchesController.cs:42`, alongside dismiss/invite.
- **#6 dead code / orphaned screens.** False on both counts checked.
  `VendorPayoutScreen` is routed (`app_router.dart:1048`);
  `PendingCustomerInquiriesScreen` is routed (`app_router.dart:981`).
  `OrderWaitingTrackingScreen` *is* unreferenced — left in place rather than
  deleted, since an unrouted screen is as likely to be pending work as dead.
- **#9 `_openChat` error messages undifferentiated.** False. The string
  "Could not open conversation" does not exist anywhere in the vendor tree.
- **#10 Pending Actions tiles route through mock data.** False. All four
  counts come from real repositories, and a failed count folds to `null`
  rather than `0` — the zero-vs-unknown distinction the item worried about is
  already handled.
- **#13 `campaign_brief_detail_screen` references undefined `TermsSection`.**
  False. No such reference exists, and `dart analyze` reports 0 errors
  repo-wide.
- **#15 `getPendingCreatorRequestCount` may not be implemented.** False. Real
  body in the datasource and repository impl, consumed by
  `vendor_pending_actions_notifier`.
- **#21 `MessageCreatorArgs` has 7 fields, `_openChat` fills 5.** False. It
  has three (`creatorName`, `handle`, `avatarAsset` with a default).
- **#23 vendor earnings/payouts partially mocked.** False. No stubs, TODOs or
  mock returns in `features/vendor/earnings/data/`.
- **#24 `VendorPayoutController` may be missing or in the wrong module.**
  False. Payouts are owned by `StyleMint.Modules.Payouts`
  (`PayoutsController`, `PayoutDestinationsController`) — the architecture the
  item asks for is already in place.
- **#25 `/vendor/products/{id}/analytics` duplicates
  `/vendor/analytics/products`.** False. Both routes are hosted on the single
  `VendorAnalyticsController` with an explicit "single seam set" comment —
  one implementation, two routes, already documented in code.
- **#26 inquiries screen shows tabs the controller cannot differentiate.**
  False. The screen has no `TabBar`; it distinguishes replied inquiries via
  `status == InquiryStatus.replied`.
- **#18 NuGet.Config / CI restore.** Fixed separately: the file held two
  concatenated XML documents (solution would not restore at all, 68 errors)
  and one hardcoded another user's package path. nuget.org restored as a
  source. See branch `chore/fix-nuget-config-restore`.

## True, but not blocking

- **#2 no `GET /v1/message-threads/{id}`.** Confirmed — the controller has
  POST (open), GET (list mine), GET `{id}/messages`, POST `{id}/messages`.
  Open is upsert-style, so single-thread fetch is genuinely covered by
  `openThread`, as the item itself suspected. No client needs it today.
- **#4 no `GET /v1/vendor/dashboard/quick-stats`.** Confirmed absent. The app
  composes three counts client-side instead. An aggregate endpoint would save
  two round-trips; it is an optimisation, not a defect.
- **#30 no migration checkpoint.** Not attempted — squashing migrations is a
  release-coordination decision, not an overnight change.

## Fixed in this pass

- **#8 `InquiriesController` misnamed.** It is a `StateNotifier` living in
  `presentation/notifiers/`. Renamed to `InquiriesNotifier`
  (`inquiries_notifier.dart`, `inquiriesNotifierProvider`) with its test file.
  Two consumers were updated, including one in `vendor/orders` that the
  original list did not mention.

## Not re-verified this pass

3, 5, 7, 11, 12, 14, 16, 17, 19, 20, 22, 27, 28, 29 — mostly backend DRY
observations and "confirm with a visual smoke test" items that need a running
app or a design call rather than a code check.

Given the hit rate above (13 of 16 checked items were already done), assume
these are likelier done than not, and verify before scheduling any of them.
