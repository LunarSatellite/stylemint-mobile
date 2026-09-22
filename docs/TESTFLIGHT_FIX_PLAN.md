# TestFlight Failed Test Points — Fix Plan

Source: `StyleMint_Failed_Test_Points.docx` (QA pass, 22 Sep 2026, iOS/TestFlight).

Status: **implemented** on branch `fix/testflight-qa-2026-09-22` in both
`stylemint-mobile` and `stylemint-backend`, except SM-015 (not possible on
iOS) and SM-014 (TikTok portal configuration, no code involved).

**Nothing here has been compiled, analysed or run.** The authoring machine has
no Flutter SDK and no .NET SDK. Before this goes anywhere near TestFlight:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

The `build_runner` step is **required, not optional** — `FollowingUserDto`
gained a `handle` field and generated sources are gitignored, so the app will
not compile until it runs.

Two corrections to the original triage, found while implementing:

* **SM-007's cause was not the address selection.** See SM-007b below.
* **The `PageFollowingAsync` cursor is not buggy.** The first draft of this
  plan claimed `Guid.CompareTo` and PostgreSQL disagree on uuid ordering.
  They would — but the comparison is translated to SQL, so both the `WHERE`
  and the `ORDER BY` use Postgres's ordering and agree with each other. No
  change was made.

---

## Ordering

Work in this order. Later groups depend on earlier ones being out of the way.

| Group | Items | Why first |
|---|---|---|
| 0. Unblock diagnosis | SM-007a, SM-011a | Both hide the real server error. Fix the display first so the *next* TestFlight pass reports a cause instead of a Dart type name. |
| 1. Ops / third-party | SM-001, SM-014 | No app code involved; can proceed in parallel with everything else, by whoever owns DNS/Apple/TikTok. |
| 2. Cheap app fixes | SM-005, SM-013, SM-010, SM-003/004, SM-002 | Small, independent, low regression risk. |
| 3. Client state | SM-008 | Touches a provider several screens read. |
| 4. Features | SM-012, SM-006 | New surface area; SM-006 is the largest single item. |
| 5. Backend | SM-007b, SM-009, SM-011b | Needs server logs / DB access. |
| 6. Won't fix | SM-015 | Not possible on iOS as specified; needs a product decision. |

---

## Group 0 — Make the failures legible

### SM-007a · Checkout shows `Order failed: _Validation`

**Root cause (confirmed).** [`checkout_screen.dart:101`](../lib/features/customer/checkout/presentation/screens/checkout_screen.dart)
renders `failure.runtimeType` — the *Dart class name* of the freezed union
member — instead of the message. `NetworkExceptions.getMessage()` already
exists ([`network_exceptions.dart:172`](../lib/core/network/network_exceptions.dart))
and already formats RFC 7807 field errors into `field: message` lines.

**Plan.** Replace the `runtimeType` interpolation with
`NetworkExceptions.getMessage(failure)`. Grep the rest of the app for the same
pattern — `runtimeType` in user-facing strings — and fix any others found.

**Payoff.** The backend returns `ServiceResult.Required(nameof(...))` for the
most likely causes, which `_formatValidation` renders as
`Field "ShippingAddressId" is invalid (required).` That single change probably
identifies the SM-007 root cause without any further investigation.

**Verify.** Unit test asserting the snackbar text for a
`NetworkExceptions.validation(field: 'ShippingAddressId')`.

---

### SM-011a · Cart shows a bare "failed to show cart"

**Plan.** [`cart_screen.dart:197`](../lib/features/customer/cart/presentation/screens/cart_screen.dart)
already has an `SmErrorView` with a working retry, so the UX ask is met. What
is missing is the cause. Pass `NetworkExceptions.getMessage(failure)` through as
a secondary line under "Failed to load your cart.", and log the failure (status
code + `traceId` from the problem-details body) so the intermittent case is
traceable.

**Note.** Keep the friendly headline; add detail underneath, don't replace it.

---

## Group 1 — Ops and third-party (no app code)

### SM-001 · Passkey login fails

**Root cause (confirmed, high confidence).** Apple Team ID mismatch.

- Live AASA at `https://stylemint.voyageritnepal.com/.well-known/apple-app-site-association` returns:
  `{ "webcredentials": { "apps": ["AA25Q882AV.app.stylemint.stylemintMobileFrontend"] } }`
- The app signs with `DEVELOPMENT_TEAM = YBSBPFR23X` (`ios/Runner.xcodeproj/project.pbxproj`).

iOS refuses the `webcredentials:` association when the team prefix doesn't
match the installed app, so every WebAuthn ceremony fails before it reaches the
backend — which is exactly the generic fallback message the user saw at
[`sign_in_method_selection_screen.dart:94`](../lib/features/auth/presentation/screens/sign_in_method_selection_screen.dart).

**Second defect in the same file.** `Runner.entitlements` declares
`applinks:stylemint.voyageritnepal.com`, but the AASA has **no `applinks`
section at all**. Universal links (magic-link sign-in, shared reel/product
links) cannot work either. Not in the QA doc, but it will be the next bug filed.

**Plan.** Replace the served file with both sections:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YBSBPFR23X.app.stylemint.stylemintMobileFrontend",
        "paths": ["*"]
      }
    ]
  },
  "webcredentials": {
    "apps": ["YBSBPFR23X.app.stylemint.stylemintMobileFrontend"]
  }
}
```

Serve at `/.well-known/apple-app-site-association`, `Content-Type:
application/json`, no redirect, no auth.

**Caveats.**
- Confirm `YBSBPFR23X` is the team the TestFlight build was actually signed
  with, not just the Xcode project value — check the distribution provisioning
  profile.
- The file is **not in any repo.** It is placed on the server by hand, and
  `nginx/default.conf.template` only handles `/.well-known/acme-challenge/`.
  Add it to source control and to the deploy so it can't drift again.
- iOS caches AASA. After fixing, delete and reinstall the TestFlight build
  before retesting.
- Tighten `paths` from `["*"]` to the real deep-link prefixes once verified.

**Verify.** `curl` the file and confirm the team prefix; reinstall; passkey
sign-in on a clean device and on a returning account (per the QA retest list).

---

### SM-014 · TikTok `non_sandbox_target`

**Root cause.** TikTok returns `non_sandbox_target` when the app is still in
**Sandbox** in the TikTok Developer Portal and the account attempting to log in
is not a registered sandbox target user. It is a portal state, not a code path
— nothing in `lib/` can change it.

**Plan.** Either add the QA tester's TikTok account as a sandbox target user on
the app's sandbox, or complete TikTok's app review and move the client key to
production. Then confirm the redirect URI registered with TikTok matches what
the app sends.

**Keep.** The request ID from the screenshot,
`202609221614316EF77B6FA4C0B74EA53A`, for TikTok support if the portal state
looks correct.

---

## Group 2 — Cheap app fixes

### SM-005 · App opens Mall instead of Reels

**Root cause (confirmed).**
[`providers.dart:140`](../lib/features/customer/mall_home/shared/providers.dart):
`final homeModeProvider = StateProvider<HomeMode>((ref) => HomeMode.mall);`

**Plan.** Default to `HomeMode.reels`.

**Check before shipping — this one has real side effects.**
- `HomeScreen` builds `ReelsFeedScreen` lazily and keeps it (`_reelsBuilt`).
  Defaulting to reels makes the feed part of cold start: network fetch and
  video init on launch. Measure launch time.
- Video autoplay on launch — confirm it starts **muted** so the app doesn't make
  noise the instant it opens.
- Guests: confirm the reels feed degrades sanely when unauthenticated.
- `customer_shell_screen.dart:66` branches on `homeModeProvider` for
  tap-to-refresh; behaviour flips but stays correct.
- Decide whether the choice should persist across launches, or always reset to
  Reels. QA says "first/default page after app launch" — always reset is the
  literal reading.

**Verify.** Widget test asserting a fresh `HomeScreen` shows the reels branch;
manual cold launch and relaunch.

---

### SM-013 · Keyboard won't dismiss in Become Creator

**Root cause (confirmed).**
[`creator_activate_screen.dart:162`](../lib/features/creator/apply/presentation/screens/creator_activate_screen.dart)
is a `maxLines: 4` bio field. iOS gives a multiline field a Return key, not a
Done key, so there is no way to dismiss it — and the screen has no
tap-outside-to-unfocus and no keyboard toolbar.

**Plan.**
1. Wrap the body in a `GestureDetector(onTap: () => FocusScope.of(context).unfocus(), behavior: HitTestBehavior.opaque)`,
   or set `onTapOutside` on both fields.
2. Give the single-line "What do you create?" field
   `textInputAction: TextInputAction.next`.
3. For the multiline bio, add a keyboard accessory / Done affordance, or accept
   tap-outside as the dismissal.
4. Confirm the `bottomNavigationBar` "Become a Creator" button stays reachable
   above the keyboard (`resizeToAvoidBottomInset` defaults true, so it should —
   verify on a small device, e.g. iPhone SE).

**Sweep.** Same pattern likely exists on other multiline forms — creator edit
profile, vendor add-product. Grep for `maxLines:` with no dismissal and fix
together.

---

### SM-010 · Can't open a creator from the Following list

**Root cause (confirmed).** `_FollowingCard`
([`following_screen.dart:110`](../lib/features/profile/presentation/screens/following_screen.dart))
has no tap handler at all — only the Follow/Following toggle is interactive.

**Good news.** The id is already the right one:
`FollowingUserDto.toDomain()` maps `id: accountId`
([`user_profile_dto.dart:69`](../lib/features/profile/data/models/user_profile_dto.dart)),
and the route is `creatorProfile = '/creator-profile/:accountId'`
([`route_names.dart:321`](../lib/routes/route_names.dart)). So this is a
wire-up, not a data problem.

**Plan.** Wrap the card in an `InkWell` that pushes
`RouteNames.creatorProfile.replaceAll(':accountId', user.id)`. Keep the follow
button's own tap target separate so it doesn't also navigate.

**Edge case to handle.** Not every followed account is a creator — a followed
customer has no creator profile and the screen will 404. Decide: hide the tap
for non-creators (needs a flag the DTO doesn't currently carry), or let the
profile screen show a graceful not-found. Simplest correct answer is the
latter, plus adding an `isCreator` flag to `FollowingListItemDto` later.

---

### SM-003 / SM-004 · No Back on the onboarding steps

**Root cause (confirmed).** Neither screen has an AppBar or any back control,
**and** the whole chain navigates with `context.go`, which replaces the stack —
so even iOS edge-swipe has nothing to pop back to.

Chain today: `pickInterests` → `go` → `followCreators` → `go` → `followBrands`.

**Reading the two test points.** SM-003 ("after selecting interests… no Back")
and SM-004 ("after following creators… similarly no Back") both describe being
one step *past* a screen with no way back to it. One fix covers both.

**Plan.**
1. Change the forward navigation in the chain from `context.go` to
   `context.push`, so a stack exists:
   - `pick_interests_screen.dart` Proceed → `push(followCreators)`
   - `follow_creators_screen.dart` Proceed **and** Skip → `push(followBrands)`
   - `follow_brands_screen.dart` final step → keep `go(home)` so onboarding is
     not left on the stack behind the app.
2. Add a leading back `IconButton` to `followCreators` and `followBrands`,
   matching the AppBar style already used in `following_screen.dart`.
3. `pickInterests` is the first post-auth step — it has no meaningful previous
   screen (going "back" would land on sign-in while already authenticated).
   Either omit its back button or, if QA insists, route it to the user-type
   selection. **Needs a product call.**

**Watch out.** `_routeAfterAuth` in `sign_in_method_selection_screen.dart`
`go`s to `pickInterests`; leave that as `go`. Confirm the router `redirect`
doesn't bounce pushed onboarding routes — they aren't in `_authOnlyPaths`, so
they should be fine, but test it.

---

### SM-002 · Backspace doesn't move to the previous OTP box

**Root cause (confirmed).** Two separate bugs in
[`auth_code_field.dart`](../lib/features/auth/presentation/widgets/auth_code_field.dart):

1. `_handleBackspace` is only ever reached from `onChanged`. When a box is
   **already empty**, pressing Backspace does not change the text, so
   `onChanged` never fires and focus never moves. This is the reported bug.
2. `_handleInput` calls `focusNodes[index].unfocus()` on the last digit
   (line 68). After auto-submit *no box is focused at all*, so Backspace does
   nothing anywhere — which is why the tester had to "manually position the
   cursor."

**Plan — preferred: replace the 5 controllers with one hidden field.** Keep a
single `TextEditingController` of up to 5 digits and render 5 read-only boxes
from its value. Deletion always mutates one string, so backspace works at every
position by construction, including from a full code.

This also gets, for free:
- **iOS OTP autofill** via `autofillHints: [AutofillHints.oneTimeCode]` — the
  "From Messages" suggestion above the keyboard. Cannot work with 5 separate
  one-character fields.
- Paste of a whole code.
- No more unfocus-after-submit dead end.

**Fallback if the rewrite is judged too risky:** keep the 5 fields but seed each
controller with a zero-width space (`​`) sentinel so a backspace on a
"visually empty" box still changes the text and fires `onChanged`. This is the
common Flutter workaround; it is uglier (every read must strip the sentinel)
and does not give autofill.

**Do not** rely on `KeyboardListener` / `LogicalKeyboardKey.backspace` — iOS
soft keyboards don't deliver that reliably.

**Verify.** Widget test per the QA retest list: backspace at every position
including the first and last box, and immediately after the code auto-submits.

**Blast radius.** `AuthCodeField` is used by `otp_screen.dart` and possibly
other auth screens — grep before changing the public API. `AuthCodeFieldState`
is reached through a `GlobalKey` for `getCode()` / `clearCode()`; keep both
method signatures.

---

## Group 3 — Client state

### SM-008 · Follows are lost on app restart

**Root cause (very likely: client-side hydration, not server persistence).**
[`follow_notifier.dart`](../lib/features/social/follow/presentation/follow_notifier.dart)
is a `StateNotifier<Set<String>>` that starts at `const <String>{}` every
launch. It is only ever populated by `seed()` from a per-item server flag or by
the user's own `toggle()` this session. Nothing loads the follow graph at
startup, so after a restart every Follow button renders as "not following".

**Supporting evidence this is display-only.** SM-009 reports the Following list
showing creators *repeatedly*, which means the server did persist the follows.

**Verify this hypothesis first — it changes the fix entirely.**
`GET /v1/follows/me` as the test account after a restart. If the creators are
there, this is purely hydration. If not, it's a write-path bug and the plan
below is wrong.

**Plan (assuming hydration).**
1. On session bootstrap, page `GET /v1/follows/me` and hydrate
   `FollowNotifier` with the followee account ids. The endpoint already exists
   and is already wired in
   [`profile_remote_datasource.dart:120`](../lib/features/profile/data/datasources/profile_remote_datasource.dart).
2. Clear the set on logout / account switch — `CartNotifier.reset()` is the
   existing precedent for this and shows why it matters (stale state leaking
   across accounts on one device).
3. Optionally cache the id set locally for instant first paint, then reconcile
   with the server response.
4. Respect the existing `_seeded` guard so hydration cannot clobber a live
   toggle mid-flight.

**Careful.** The follow graph can be large. Page it, or add a lightweight
"ids only" endpoint rather than pulling full account summaries at startup.

---

## Group 4 — Features

### SM-012 · No Gallery option when scanning

**Current state.** [`style_mint_scan_screen.dart`](../lib/features/scan/presentation/screens/style_mint_scan_screen.dart)
is camera-only via `MobileScanner`.

**Everything needed is already present.**
- `image_picker: ^1.1.2` and `mobile_scanner: ^7.2.0` are both in `pubspec.yaml`.
- `MobileScannerController.analyzeImage(path)` decodes a still image.
- `NSPhotoLibraryUsageDescription` is already in `ios/Runner/Info.plist:13`.

**Plan.** Add a gallery button to the scanner chrome →
`ImagePicker().pickImage(source: ImageSource.gallery)` → `analyzeImage` → feed
the result into the **same** handler the live camera path uses, so a scanned
`StyleMintCode` behaves identically however it arrived.

**Handle:** user cancels the picker; image contains no detectable code (needs a
clear "no code found in that image" message, not silence); permission denied.

---

### SM-006 · Shipping "Add New Location" has no map picker

**Current state.** The map exists —
[`address_pin_map.dart`](../lib/features/customer/shipping/presentation/widgets/address_pin_map.dart)
is a complete OSM/`flutter_map` surface with a draggable, tap-to-move pin. Two
gaps against the test point:

1. It renders only inside `if (_hasPoint)`
   ([`add_edit_address_screen.dart:915`](../lib/features/customer/shipping/presentation/screens/add_edit_address_screen.dart)),
   i.e. **after** the user has already captured a point via "use current
   location" or a pasted Maps link. A user who wants to pin a spot on a map
   never sees a map.
2. There is **no location search anywhere** in the flow.

**Plan.**
1. **Map first.** Render `AddressPinMap` unconditionally, centred on a sensible
   default (last known location → account's city/country → country centroid),
   with an explicit "pin not set yet" state so an un-dragged default centre is
   never silently saved as the user's address.
2. **Search box.** Add a debounced place search above the map; selecting a
   result recentres the map and moves the pin. `AddressPinMap` will need a
   `MapController` or a way to accept an externally-driven centre — it is
   currently deliberately minimal and drives its own camera.
3. Keep drag + tap-to-move; keep "use my current location" as one input among
   several rather than the gateway to the map.
4. Optionally reverse-geocode on pin drop to prefill the address text fields.

**Decision needed: which geocoder.**
- **Nominatim** — no key, matches the existing OSM tiles. But its usage policy
  caps you at ~1 req/sec and *discourages autocomplete-style querying*. Viable
  only with aggressive debounce and search-on-submit rather than per-keystroke,
  and it needs the same identifying `User-Agent` the tile layer already sets.
- **Photon** (Komoot) — designed for autocomplete, no key, OSM data.
- **LocationIQ / MapTiler / Google Places** — key + billing, best quality,
  terms may require using their map tiles too.

Recommend Photon for autocomplete, or Nominatim with search-on-submit if no new
third-party dependency is acceptable. **This is the one item that needs a call
before implementation starts.**

**Also verify.** `geolocator: ^14.0.1` is present and
`NSLocationWhenInUseUsageDescription` is set (`Info.plist:113`) — so the
existing "use current location" path should already work; confirm whether QA hit
a permission problem there too.

**Size.** Largest item on the list. Consider splitting: (a) map-first, (b)
search — ship (a) into the next TestFlight build and (b) after.

---

## Group 5 — Backend

### SM-007b · Why a valid checkout fails validation — **fixed**

The original hypothesis (address selected in the UI but never PATCHed onto the
session) turned out to be **wrong**. `placeOrder` in
`checkout_remote_datasource.dart` PATCHes the address and the payment method
onto the session immediately before posting `/place`, so both are set.

The real cause was the last candidate on the original list: **a session left
in a non-`Draft` status by an earlier attempt.**

`_sessionId` is a field on the datasource, cleared only on *success*. A place
that reaches the server moves the session out of `Draft` — to `Placing`, and
to `Failed` once the saga unwinds — and `PlaceAsync` refuses anything that
isn't a `Draft`. So the first failure poisoned the session: every retry
re-posted the same dead id, got `state.invalid_transition` back, and rendered
it through `failure.runtimeType` as `Order failed: _Validation`. There was no
way out short of restarting the app, which is why it looked like a checkout
that simply could not succeed.

`_sessionId` is now dropped on failure too, so the next attempt opens a fresh
session against the live cart.

Scoped deliberately to the place call: the address, payment-method and
delivery-option calls also resolve `_sessionId`, but none of them move the
session out of `Draft`, and clearing it there would silently discard a
delivery choice the customer had already made.

**Still worth doing.** This is the likeliest cause, not a proven one — no
failing request was captured. SM-007a ships alongside it, so if something else
is going on, the next TestFlight pass will name it. Capturing the `traceId`
from the problem-details body in the client log is still not done, and would
let a failed order be joined to the server log.

---

### SM-009 · Duplicate creators in the Following list

**The client cannot be causing this.** `FollowingNotifier.load()` replaces state
wholesale — there is no append path — and the repository maps one DTO per
response item.

**The database probably cannot be causing it either.**
`FollowConfiguration.cs` declares `ux_follows_edge` unique on
`(FollowerAccountId, FolloweeAccountId)`, and migration
`20260602122303_20260602_SocialGraph_Follows` does create it as
`unique: true`. `PageFollowingAsync` is a clean single-table query with no join
fan-out, and `ListFollowingAsync` enriches row-by-row without multiplying.

**Leading hypothesis: they are not duplicates — they are two different accounts
with the same display name.** `FollowingListItemDto` carries **no handle**, and
`FollowingUserDto.toDomain()` hardcodes `handle: ''`. `following_screen.dart`
then hides the handle row entirely ("showing a bare `@` reads as broken"). With
nothing but a display name and an avatar on screen, two distinct creators called
e.g. "Sarah" are indistinguishable from one creator listed twice.

**Done.** `AccountSummaryDto` now carries the account's `@handle` (the
Creator-role handle where there is one, else any active handle),
`FollowingListItemDto` passes it through, `FollowingUserDto` parses it
(defaulting to `''`, so an older backend still parses), and the list renders
it. The stale "backend doesn't carry a handle yet" comment is gone.

**Still verify before closing this one.** The fix assumes these are distinct
accounts that merely look alike. Confirm that:

1. `SELECT follower_account_id, followee_account_id, COUNT(*) FROM follows GROUP BY 1,2 HAVING COUNT(*) > 1;`
   If this returns rows, `ux_follows_edge` is missing from the deployed
   database — check the migration history table. That is a different bug and
   the handle does not fix it.
2. If it returns nothing, compare the `accountId`s in the `GET /v1/follows/me`
   response for the rows that looked duplicated. Different ids confirm the
   name collision.

**Correction.** An earlier draft of this plan called the `PageFollowingAsync`
cursor buggy, on the grounds that .NET `Guid.CompareTo` and PostgreSQL `uuid`
order differently. That is true of the two orderings, but irrelevant here: the
comparison is translated into SQL, so the `WHERE` and the `ORDER BY` both use
Postgres's ordering and agree. No change was made.

---

### SM-011b · Intermittent cart load failure

**Plan.** Server-side. After SM-011a is shipping the real message and traceId,
pull the API logs for `GET` cart around a reproduction and look for timeouts,
a slow dependency, or a 5xx under concurrency. Also exercise the QA retest note
— "poor-network conditions" — with iOS Network Link Conditioner, since an
intermittent failure that only appears on a real device often turns out to be a
client timeout that is too aggressive rather than a server fault.

---

## Group 6 — Needs a product decision

### SM-015 · NFC profile sharing between two iPhones

**This cannot be built as specified.** iOS gives third-party apps NFC tag
*reading* (`NFCTagReaderSession`, `NFCNDEFReaderSession`) and tag writing. It
does **not** expose peer-to-peer NFC or card emulation to third-party apps, so
one iPhone cannot present the StyleMint profile to another iPhone over NFC.
Apple removed the peer-to-peer NFC mode years ago; the NFC slot on iPhone is
reserved for Apple Pay and system features.

The app's existing NFC code matches that reality: `nfc_link_writer.dart` and
`flutter_nfc_kit_session.dart` write NDEF link records to **physical tags** for
vendor in-store codes. `Runner.entitlements` requests only
`com.apple.developer.nfc.readersession.formats: [TAG]` — and a recent commit
deliberately dropped NDEF from it. There is no profile-sharing feature to fix.

**Options to put to product.**
1. **Reframe the test point.** Profile sharing over AirDrop / share sheet /
   universal link / QR — the QR path largely exists already via
   `features/codes`. Requires SM-001's `applinks` fix to land first.
2. **Physical NFC tag.** A creator taps their phone to a StyleMint-provisioned
   tag; the tag carries the profile link. This *is* supported and close to the
   existing writer code — but it is a different product, not "two iPhones".
3. **Drop the test point.**

Recommend (1), with the QA doc's retest line rewritten accordingly.

---

## Decisions taken while implementing

These were the open questions. Each was resolved the way this plan
recommended; reverse any of them if you disagree.

1. **SM-006 geocoder → Photon (Komoot).** No key, no billing, OSM data to
   match the tiles, and built for autocomplete, which Nominatim's usage policy
   discourages. It is a free public endpoint with no uptime guarantee —
   `PlaceSearchService` is the interface to move off it. It is reached through
   its own `Dio`, never the app's `ApiClient`, so StyleMint's bearer token
   cannot leak to a third-party host.
2. **SM-003 first step → no Back button.** `OnboardingBackButton` renders
   nothing when there is nothing to pop, so Interests (the first post-auth
   step) shows no control rather than a dead one or a link back to sign-in
   while already signed in. Steps 2 and 3 get a working Back.
3. **SM-005 → always resets to Reels.** `homeModeProvider` is not persisted,
   so the choice holds for the session and every cold start returns to Reels.
   This is the literal reading of "the first/default page after app launch".
4. **SM-015 → not implemented.** No code can satisfy it; see below.
5. **SM-002 → single hidden field.** The zero-width-space fallback was not
   taken. The rewrite also buys iOS one-time-code autofill and paste.

## Still open

1. **SM-001** — confirm `YBSBPFR23X` is the team the TestFlight build was
   actually signed with (the value is from the Xcode project; check the
   distribution provisioning profile). If release signing uses a different
   team, the file is wrong again in the same way.
2. **SM-014** — someone with TikTok Developer Portal access has to either add
   the tester as a sandbox target user or move the app to production.
3. **SM-015** — which alternative to offer, if any.
4. **SM-009** — run the duplicate-row query above before closing it.
5. **SM-006** — `paths: ["*"]` in the AASA accepts every path on the domain
   into the app; narrow it once universal links are confirmed working.

---

## Retest checklist

The QA doc's own checklist (§5) stands. Add to it:

- **Run `build_runner` first.** The app will not compile without it.
- Passkey retest requires **delete + reinstall**, not just a new build — iOS
  caches the AASA. Confirm the AASA is actually deployed first:
  `curl -sD - https://stylemint.voyageritnepal.com/.well-known/apple-app-site-association`
  should show `200`, `application/json` and the `YBSBPFR23X` prefix in both
  sections.
- **Cold-launch cost of SM-005.** Landing on Reels puts the feed's network
  fetch and video init on the launch path. Time a cold start before and after.
- **Launch audio.** Playback starts muted and asks for sound once frames are
  moving, which is existing Reels behaviour — but it now happens on launch
  rather than when someone chooses Reels. Confirm that is wanted; it was not
  changed, because muting Reels generally is a different decision.
- Following list retest should compare **account ids**, not names, when
  judging SM-009 — and the handle should now be visible on each row.
- SM-007 is fixed on a strong hypothesis, not a captured failure. Re-run
  checkout and, if it still fails, record the new error message verbatim: it
  will now name the actual server error instead of `_Validation`.
- Address map: check that a pin left on the **default** Kathmandu view cannot
  be saved as an address, that search results move both the pin and the
  camera, and that a failed search still leaves the pin draggable.
- Gallery scanning: a valid code, a picture with no code, and a non-StyleMint
  QR code should each say something different.
