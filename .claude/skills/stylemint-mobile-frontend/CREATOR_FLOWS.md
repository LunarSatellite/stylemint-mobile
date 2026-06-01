# Creator Flows — Style Mint Mobile

Companion to `SKILL.md`. Per-feature guidance for the Creator-side
mobile surface. Style Mint Creators publish on **Instagram / TikTok
/ YouTube Shorts / Facebook** — Style Mint does not host or play
video. The Creator app coaches, attributes, and pays.

Read the backend skill named in each section for endpoint details.

**Stack:** Flutter 3.41.9 · Dart 3.7 · Feature-First Clean Architecture.
All screens live in `lib/features/creator/<feature>/presentation/`.
Business rules live in the repository (`domain/repositories/` interface +
`data/repositories/` impl); presentation `StateNotifier`s call the repository
directly — **no `domain/usecases/`**. Notifier state is a Freezed union;
side-effects (navigation, snackbars) use **`ref.listen` + `maybeWhen`**,
never await-then-read (SKILL §3.8).

## 1. Become a Creator

**Backend skill**: `stylemint-onboarding`

A customer requests the Creator role:

```
1. profile/become-creator         → CTA
2. creator_apply_page.dart form:
     - Handle (3–30 chars, lowercase, unique)
     - Display name
     - Bio (≤ 240 chars)
     - Content categories (1–3 from 15 + Other w/ free-text)
     - Primary social link (IG/TikTok/YouTube/FB URL)
     - Brief intro video URL (optional)
3. POST /v1/onboarding/creator-applications  { ... }
   → 201 { applicationId, state: "Submitted" }
4. Show "Under review — 1–3 business days" screen
5. Push notification on decision (Approved or Rejected w/ reason)
```

**The 15 content categories include "Other"** which requires a
free-text description (locked per `stylemint-onboarding` SKILL.md).
Validation: at least 1, at most 3 categories.

Once Approved, the Creator RoleProfile flips to `Approved` and the
user can activate it via the role switcher (`AUTH_FLOW.md` §5).

## 2. Connect social accounts

**Backend skill**: `stylemint-social`

The Creator must connect at least one external account to import
reels.

```
GET  /v1/social/accounts                      → list connected accounts
POST /v1/social/accounts/{provider}/begin     → returns OAuth URL
POST /v1/social/accounts/{provider}/finish    { code, state }
DELETE /v1/social/accounts/{accountId}
```

`provider` ∈ `Instagram | TikTok | YouTube | Facebook`.

Each provider's OAuth scopes are documented in `stylemint-social`
SKILL.md. The mobile flow:

```
1. profile/connect-social tab
2. Tap "Connect Instagram" → `flutter_web_browser` opens IG OAuth
3. IG redirects to stylemint://oauth/social/return?code=...&state=...
4. App posts to /finish — backend stores the access + refresh tokens
   (encrypted at rest)
5. Account appears in the connected list with handle, follower count,
   last-refreshed timestamp
```

Token refresh is **server-side** — the mobile app never sees the
external provider's tokens.

## 3. Import a reel

**Backend skill**: `stylemint-reels`

Reels are **pointer records** to external content. Import flow:

```
1. `studio_page.dart` → "Import a reel" CTA
2. Pick the source social account (must be connected)
3. The reel-picker screen lists the creator's recent posts from
   that account (`GET /v1/social/accounts/{id}/recent-posts`)
4. Tap a post → preview screen with metadata pre-filled:
     - External URL (immutable)
     - Title (editable, ≤ 100 chars)
     - Caption excerpt
     - Audio track (auto-detected; can be overridden by selecting
       from /v1/audio/tracks)
5. Tag products: search products from partner vendors only
   (see Partnerships §5)
6. Submit
```

```
POST /v1/creator/reels/import
{
  socialAccountId,
  externalUrl,
  title,
  audioTrackId?,
  taggedProductIds: [...]
}
→ 201 ReelDto
```

The reel becomes discoverable immediately. Engagement metrics
(views, likes, comments) refresh hourly via Hangfire.

### 3.1 Update tagged products

```
PUT /v1/creator/reels/{id}/tagged-products  { productIds: [...] }
```

Existing tags' commission rates are **frozen at original tag time**
— changing the tag set doesn't retroactively change rates on
already-sold cart items.

## 4. Reel Studio (Pillar D — pre-publish coaching)

**Backend skill**: `stylemint-creator-studio` + `stylemint-audio` +
`stylemint-reel-recipes`

The Reel Studio is the creator's coaching surface. It runs BEFORE
the creator records — the actual recording happens in IG / TikTok /
YouTube / FB native editors. Style Mint suggests:

### 4.1 Pre-publish analysis

```
POST /v1/creator/studio/analyze
{
  draftTitle: string,
  productIds: [...],         // products you plan to tag
  contentCategory: string,
  targetPlatform: "Instagram" | "TikTok" | "YouTubeShorts" | "Facebook"
}
→ 200 {
  hookScore: 0..100,
  hookSuggestions: [string],
  audioRecommendations: AudioRecDto[],     // see §4.2
  captionVariants: [string],                // 3 variants, locale-aware
  hashtagSet: [string],
  recommendedPostTimeUtc: string,
  predictedAudience: { ... },
  shelfLifeDays: number,
  explanation: string                       // plain-language why
}
```

Render as a card stack — one section per dimension. Each carries a
short explanation ("Audio: This track is trending in your category
this week — used in 18 of the top 50 reels.").

### 4.2 Audio picker

```
GET /v1/audio/tracks?q=...&category=...&cursor=...
GET /v1/audio/tracks/{id}
```

Tracks are **reference-only** — Style Mint does not host audio. Each
track carries:

```ts
type AudioTrackDto = {
  id: string;
  name: string;
  artist: string;
  durationSeconds: number;
  externalLinks: {
    youtube?: string;
    spotify?: string;
    soundcloud?: string;
    tiktok?: string;
  };
  hotSegments?: { startSec: number; endSec: number }[];  // recipe usage
  trendScore?: number;
};
```

Tap "Listen on YouTube/Spotify/etc." opens the external app:

```ts
await launchUrl(Uri.parse(track.externalLinks.spotify ?? track.externalLinks.youtube!),
  mode: LaunchMode.externalApplication);
```

**Never embed an audio player.**

### 4.3 Reel Recipes

```
GET /v1/reel-recipes?productId=...&audienceCategory=...&cursor=...
GET /v1/reel-recipes/{id}
```

A Reel Recipe is a structured production guide: hook line, scene
list, song with start/end timestamps, suggested captions, per-
platform notes on where to find the song. Renders as a step-by-step
card.

### 4.4 Story Arcs

Series detection grants +10% commission boost (additive, capped at
effective 0.50). Backend identifies series automatically; the
Studio surfaces:

```
GET /v1/creator/studio/story-arcs
→ [{ arcId, reelIds, status: "Active" | "Eligible", commissionBoost }]
```

### 4.5 Post-Publish Coach

24 hours after publication, the Coach drops a structured report:

```
GET /v1/creator/studio/reports/{reelId}
→ {
  views, likes, comments, shares,
  conversionsThroughTaggedProducts,
  audienceMix,
  whatWorked: [string],
  whatToTryNext: [string],
  comparableToPeers: { ... }
}
```

Push notification "Your reel's 24-hour report is ready" with deep
link `stylemint://creator/report/{reelId}`.

## 5. Partnerships

**Backend skill**: `stylemint-partnerships`

A Creator earns commission by tagging products from **partner
vendors** — vendors who have invited or accepted the creator.

### 5.1 Inbox: partnership invites

```
GET /v1/partnerships/invites?cursor=...
→ PagedResult<PartnershipInviteDto>
```

Each invite carries:

```ts
type PartnershipInviteDto = {
  id: string;
  vendor: { id, brandName, logoUrl };
  commissionRange: { fromPercent: number; toPercent: number };  // e.g. 12–20
  termsVersion: { id, summaryMarkdown };
  potentialEarningsAt50Sales: Money;     // projection
  expiresUtc: string;
};
```

### 5.2 Terms screen

Structured sections (NOT free-text):

- **Who Can Join** — bullets
- **Reel Content Rules** — bullets with InlineLink anchors
- **Compliance** — must-mention scan threshold
- **Disclosure** — auto-tagged "Sponsored" / "Paid Partnership"

Render via the structured DTO; never dump markdown blindly.

### 5.3 Accept / decline

```
POST /v1/partnerships/invites/{id}/accept
POST /v1/partnerships/invites/{id}/decline { reason? }
```

Accept transitions to an active Partnership. The Creator can now
search the vendor's catalog for products to tag.

### 5.4 Active partnerships

```
GET /v1/partnerships/active?cursor=...
→ PagedResult<PartnershipSummaryDto>

GET /v1/partnerships/{id}
→ PartnershipDetailDto (terms, commission tiers, tagged products,
   earnings to date, performance window)
```

### 5.5 Tag products from a partnership

```
GET /v1/partnerships/{id}/eligible-products?q=...&cursor=...
```

Shows the catalog scoped to the partnership's vendor. Use this
during reel import (§3) — the picker should be partnership-scoped,
not the full catalog.

## 6. Reach — cross-platform publish + boost (Pillar E)

**Backend skill**: `stylemint-reach`

The Creator can publish a single reel to **multiple platforms**
simultaneously with platform-optimized captions / hashtags / post
times.

```
POST /v1/reach/publish
{
  draftReelId: string,
  platforms: ["Instagram", "TikTok", "YouTubeShorts", "Facebook"],
  captionsByPlatform: { Instagram: "...", TikTok: "...", ... },
  scheduledForUtc?: string
}
→ 200 { publishId, perPlatformStatus: { ... } }
```

### 6.1 Boost decisions

With explicit consent, Style Mint runs AI-driven paid boost across
Meta Marketing / TikTok Ads / Google Ads APIs:

```
POST /v1/reach/boost/consent     { dailyBudget: Money, platformsOptIn: [...] }
GET  /v1/reach/boost/decisions   → recent allocation moves
```

UI: a "Boost" toggle per reel, a budget slider, a consent flow
that's **NOT bundled with publish consent** (must be a separate
opt-in screen). Display the platform-wide safety cap (Rs 50,000/mo
launch) so the creator can't think they're spending more than they
are.

### 6.2 Unified analytics

```
GET /v1/reach/analytics/reels/{reelId}
→ { perPlatform: { ... }, combined: { ... }, attributedSales: Money }
```

One dashboard, four platforms — replaces logging into each Ads
Manager separately.

## 7. Creator Studio — Brand-side intelligence (cross-link to Pillar D)

When viewing a partnership detail, the Creator can also see:

- The vendor's `BrandStudio` campaign brief (read-only)
- Reference reels for the campaign
- Audio themes the brand recommends

These are sourced from a Locked `BrandBriefDto` attached to the
partnership — the creator's side is read-only. The authoritative
API contract lives in `stylemint-brand-studio-frontend` SKILL.md;
the authoring (vendor) side is covered in `VENDOR_FLOWS.md` §7.

## 8. Earnings + Payouts

**Backend skill**: `stylemint-payouts`

The earnings ledger is append-only. Creator's screen:

```
GET /v1/payouts/earnings/me      → PagedResult<EarningEntryDto>
GET /v1/payouts/balance/me       → { pendingBalance, availableBalance }
```

Each entry shows:

- Source: which reel → which order → which sub-order line
- Commission rate (frozen at tag time)
- Amount (Money)
- State: `Pending` (until delivery) | `Available` (post-delivery) |
  `Settled` (paid out) | `Reversed` (refund undid it)

### 8.1 Payout modes

| Mode | Cost | Window |
|---|---|---|
| **Automatic Weekly** | Free | Every Friday batch |
| **On-Demand** | 2% fee | Rs 10,000–70,000 per request; 3-day pending |

```
GET  /v1/payouts/methods/me       → list 4 destinations
POST /v1/payouts/methods/me       { kind, accountDetails }
POST /v1/payouts/withdraw
{ amount: Money, payoutMethodId, mode: "Auto" | "OnDemand" }
→ 200 { payoutId, expectedSettlementUtc }
```

**Four payout destinations**: NIMB Bank, Laxmi Bank, PayPal, eSewa.
No others in v1.

### 8.2 Earnings screen layout (per Figma)

- Big "Available" balance card with "Withdraw" CTA
- Pending balance below ("Releases after delivery")
- Tabs: All / Pending / Available / Settled / Reversed
- Filter by month
- Per-item drill-down

## 9. Reputation (Pillar C facet)

**Backend skill**: `stylemint-reputation`

The Creator carries a **multi-facet reputation** (no single score):

- `CreatorEngagement` — content quality / consistency
- `ReviewerCredibility` (if they also review products)
- `CourierReliability` (if also a Pillar B courier)

```
GET /v1/reputation/accounts/{accountId}
→ { facets: { CreatorEngagement: {...}, ... }, badges: [...] }
```

Badges are **earned-only** ("First sold-out drop", "100 verified
reviews"). Render on the public creator profile and on partnership
acceptance screens (vendor sees creator's reputation).

## 10. Drop Parties (Pillar C — creator-hosted)

**Backend skill**: `stylemint-social-graph`

A Drop Party is a scheduled live creator event with exclusive
limited-stock products.

```
POST /v1/social/drop-parties
{
  title,
  scheduledStartUtc,
  scheduledEndUtc,
  invitedAccountIds?: [...],   // private; omit for public
  productIds: [...],            // limited-stock; backend enforces
  pinId?: string                // see SKILL.md note (v2.0 pin field)
}
→ 201 DropPartyDto
```

Customer flow for joining is in `SOCIAL_FLOWS.md`. The Creator's
host UI:

- Drop list (upcoming / live / past)
- Live console — viewer count, current featured product, push
  "drop alert" to invited list
- Post-drop summary

## 11. Tips (Pillar C — receive from viewers)

**Backend skill**: `stylemint-social-graph`

Viewers send small transfers (Rs 50 / 100 / 500 / custom) to
creators. Platform fee 3% flat.

```
GET /v1/social/tips/received  → PagedResult<TipDto>
```

Tips land in the creator's wallet as an "Available" earning. Same
withdraw flow as commission.

## 12. Stitched Reels (Pillar C)

```
POST /v1/social/stitches      { parentReelId, replyReelId }
```

A reply-style threading. The "stitch" is metadata only — both reels
still live on their respective external platforms. Display as a
nested thread on the parent reel detail.

## 13. Matchmaking (Pillar E — "Brands looking for you")

**Backend skill**: `stylemint-matchmaking`

```
GET /v1/matchmaking/creator/me/inbound-matches?cursor=...
→ PagedResult<MatchSnapshotDto>
```

Each match carries an **explained score** (which signals drove it).
One-tap accept pre-fills a partnership invite from the match —
the partnership's commission range is initialized from the match
score's commission band.

```
POST /v1/matchmaking/matches/{snapshotId}/accept-to-partnership
→ 200 PartnershipInviteDto
```

**No pay-to-rank** — score reflects fit, not budget. The mobile UI
should never show a "boost my rank" CTA on this screen.

## 14. Edge cases + UX rules

- **Creator without a connected social account** — Studio shows
  an empty state with a "Connect Instagram" CTA. Cannot import
  reels until at least one account is connected.
- **Reel imported from a now-disconnected account** — backend keeps
  the reel; engagement metrics stop refreshing. Surface a banner
  on the reel detail: "Reconnect Instagram to keep stats fresh."
- **Commission rate dispute** — read-only; rates are frozen at
  tag time. Direct to support if the creator questions a settlement.
- **Underage creator** — backend rejects creator-apply with
  `kyc.underage`. Surface as terminal rejection with no retry path.
- **Currency** — all earnings in NPR. PayPal payouts are FX-
  converted at withdrawal time (rate displayed at the time of
  request).
