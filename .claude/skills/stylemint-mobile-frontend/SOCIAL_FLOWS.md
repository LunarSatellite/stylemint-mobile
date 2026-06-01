# Social Flows — Style Mint Mobile

Companion to `SKILL.md`. Covers Pillar C (Gen Z mechanics) and
Pillar F (Social Commerce Layer) flows on the mobile app. These
sit on top of the v1.1 commerce foundation — many features
cross-reference Identity, Catalog, Reels, Orders.

**Stack:** Flutter 3.41.9 · Dart 3.7 · Feature-First Clean Architecture.
All screens live in `lib/features/social/<feature>/presentation/`.
Business rules live in the repository (`domain/repositories/` interface +
`data/repositories/` impl); presentation `StateNotifier`s call the repository
directly — **no `domain/usecases/`**. Notifier state is a Freezed union;
side-effects (navigation, snackbars) use **`ref.listen` + `maybeWhen`**,
never await-then-read (SKILL §3.8).

Read the backend skill named in each section for endpoint details.

## 1. Friend Feed (Pillar F)

**Backend skill**: `stylemint-social-feed` + `stylemint-networking`

### 1.1 The feed

```
GET /v1/social/feed?cursor=...&pageSize=20
→ PagedResult<FeedItemDto>
```

Feed items are mixed:

```ts
type FeedItem =
  | { kind: "post";          post: SocialPostDto }
  | { kind: "story";         story: StoryDto }       // 24h ephemeral
  | { kind: "reel-share";    reel: ReelDto; sharer: AccountCard }
  | { kind: "purchase-post"; orderId: string; sharer: AccountCard; items: [...] }
  | { kind: "recommendation"; request: RecoRequestDto }
  | { kind: "group-post";    post: GroupPostDto; group: GroupCard };
```

Feed visibility scoping:
- `public` — anyone
- `friends` — mutual friends only
- `circle` — invite-only Style Circle (max 20)

Algorithmic ranking via `stylemint-intelligence` signals.

### 1.2 Compose a post

```
POST /v1/social/posts
{
  visibility: "public" | "friends" | "circle",
  circleId?: string,
  text?: string,
  imageUrls?: string[],
  videoUrl?: string,                   // external; we don't host
  attachments?: PostAttachment[],      // linked products/reels/recos
  hashtagSlugs?: string[],
  mentionedAccountIds?: string[],
  scheduledForUtc?: string             // schedule for later
}
→ 201 SocialPostDto
```

Drafts persist to `shared_preferences` (offline-safe). Post once back online.

### 1.3 Stories (24h ephemeral)

```
POST /v1/social/stories  (multipart with image/video)
→ 201 StoryDto
```

Backend deletes from public view at 24h via Hangfire job. Personal
archive retained 30 days.

Replies to stories go via DM → Messaging hub.

### 1.4 Reactions

```
POST /v1/social/posts/{id}/reactions    { kind: "like" | "love" | "wow" | ... }
POST /v1/social/comments/{id}/reactions { kind: ... }
```

Idempotent — same kind from same user is a no-op.

## 2. Mutual Friends (Pillar F — Networking)

**Backend skill**: `stylemint-networking`

**Friendship is mutual** (different from one-way Following in
`stylemint-social-graph`).

### 2.1 Send a friend request

```
POST /v1/networking/friend-requests
{ targetAccountId, message?: string }
→ 201 FriendRequestDto
```

### 2.2 Accept / decline

```
POST /v1/networking/friend-requests/{id}/{accept,decline}
```

### 2.3 Friend list

```
GET /v1/networking/friends?cursor=...&category?=...
→ PagedResult<FriendDto>
```

Categories (Instagram-style): `CloseFriends | Acquaintances | Work
| Family`. Assign with:

```
PUT /v1/networking/friends/{accountId} { category }
```

### 2.4 People You May Know

```
GET /v1/networking/people-you-may-know?cursor=...
```

Signal-driven. Don't render a "boost my visibility" CTA — fairness.

### 2.5 Contact import

```
POST /v1/networking/contact-import  { phoneHashes: ["sha256(+9779812345678)", ...] }
→ 200 { matchedAccountIds: [...] }
```

**Critical**: hash phone numbers client-side before sending. Backend
deletes hashes after match. **Never send raw phone numbers.**

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPhone(String e164) =>
    sha256.convert(utf8.encode(e164)).toString();
```

The `crypto` package is part of the Dart standard ecosystem — add
to `pubspec.yaml` as `crypto: ^3.0.0`.

User consent screen required before contact access.

## 3. One-way Following (Pillar C — Social Graph)

**Backend skill**: `stylemint-social-graph`

Following ≠ friendship. A customer can follow a creator without
mutual consent — same as Instagram.

```
POST /v1/social/follow/{creatorId}
DELETE /v1/social/follow/{creatorId}
GET /v1/social/{accountId}/followers?cursor=...
GET /v1/social/{accountId}/following?cursor=...
```

## 4. Recommendation Threads — "Ask friends what to buy" (Pillar F)

**Backend skill**: `stylemint-recommendations`

The killer feature designed to move products fast.

### 4.1 Ask a question

```
POST /v1/recommendations/requests
{
  text: "Looking for a good laptop for video editing under Rs 80k",
  categoryId?: string,            // from catalog taxonomy
  budget?: Money,
  visibility: "public" | "friends" | "circle" | "group",
  groupId?: string,               // when visibility = "group"
  professionContext?: string      // e.g. "video editor"
}
→ 201 RecoRequestDto
```

### 4.2 Reply with a product

```
POST /v1/recommendations/requests/{id}/replies
{
  text: "Try this — I've been using it for 8 months",
  productId: string,
  imageUrls?: string[]
}
→ 201 ReplyDto
```

### 4.3 Vote

```
POST /v1/recommendations/replies/{id}/votes  { value: 1 | -1 }
```

One vote per user per reply. Re-voting changes the value; same
value is a no-op.

### 4.4 Accept best answer

```
POST /v1/recommendations/requests/{id}/accept-reply/{replyId}
```

**Asker cannot accept their own reply** (anti-self-affiliate-fraud).
Backend enforces; UI hides the Accept button on own replies.

### 4.5 Affiliate share

When the asker eventually purchases the recommended product, the
**replier earns the affiliate commission** (default 2%; vendor opt-
in required). This is automatic from the backend's append-only
`recommendation_signals` table.

Surface this on the reply UI:
- "You'll earn an affiliate share if {asker} buys" — for the replier
- "{Replier} will get a share if you buy" — for the asker

### 4.6 Expertise endorsements

```
POST /v1/recommendations/endorsements
{ accountId: string, topicSlug: "tech-recs" | "fashion-recs" | ... }
```

Public "Sarah is great at tech recs" badge. Earned over time.

## 5. Groups + Professional Circles (Pillar F)

**Backend skill**: `stylemint-community`

Interest groups (Reddit-style) and professional circles
(profession-gated).

### 5.1 Discover groups

```
GET /v1/community/groups/discover?category=...&q=...&cursor=...
→ PagedResult<GroupCard>
```

### 5.2 Group types

```ts
type GroupVisibility = "Public" | "Private" | "Secret";
// Public: anyone sees content + joins freely
// Private: anyone sees the listing but must request to join
// Secret: invisible; invite-only
```

### 5.3 Join

```
POST /v1/community/groups/{id}/join              { message? }
→ 201 { state: "Member" | "PendingApproval" }
```

For Private groups, `state: "PendingApproval"` and an owner /
moderator must approve.

### 5.4 Group posts (separate from main feed)

**Invariant**: group posts live in `stylemint-community.group_posts`,
NOT in `stylemint-social-feed.posts`. Cross-posting creates linked
rows in both — backend handles it; mobile just calls the right
endpoint.

```
POST /v1/community/groups/{id}/posts
{ text, imageUrls?, attachments?, alsoPostToFeed?: boolean }
```

`alsoPostToFeed: true` mirrors to the main feed with proper
attribution and respects the user's feed visibility setting.

### 5.5 Professional circles

Profession-gated. Requires KYC-verified profession (see
`stylemint-identity` AccountProfession).

```
GET /v1/community/circles?profession=...
POST /v1/community/circles/{id}/join
```

**Cannot bypass with self-declaration** — backend rejects unless
the user has a verified profession matching the circle's
requirement.

### 5.6 Group recommendations

A recommendation request scoped to a group:

```
POST /v1/recommendations/requests
{ ..., visibility: "group", groupId: "<community.groupId>" }
```

Only group members see and reply.

### 5.7 Group events

```
GET /v1/community/groups/{id}/events
POST /v1/community/groups/{id}/events
{ title, type: "Meetup" | "Sale" | "Drop", startUtc, endUtc, ... }
```

## 6. Group Carts (Pillar C — Social Graph)

**Backend skill**: `stylemint-social-graph`

Shared cart between friends. Items can be voted on.

### 6.1 Create

```
POST /v1/social/group-carts
{
  name: "Party shopping",
  invitedAccountIds?: [...]
}
→ 201 GroupCartDto + shareUrl: "stylemint://group-cart/{id}"
```

### 6.2 Add / vote

```
POST /v1/social/group-carts/{id}/items   { productId, variantId, quantity, addedByAccountId }
POST /v1/social/group-carts/{id}/items/{itemId}/vote  { value: 1 | -1 }
```

### 6.3 Checkout split

The group cart can check out as **one Order** with vendor sub-orders,
or as **per-member Orders** (each pays for their items). UI: a
toggle on the checkout-start screen.

## 7. Style Circles (Pillar C)

**Backend skill**: `stylemint-social-graph`

Invite-only taste groups, **max 20 members**.

```
POST /v1/social/circles { name, description }
POST /v1/social/circles/{id}/members { accountId }
GET  /v1/social/circles/{id}
```

A circle gates feed visibility (see §1.1 — `visibility: "circle"`).

## 8. Co-Watch (Pillar C)

**Backend skill**: `stylemint-social-graph`

Two friends watching a reel together with live reactions.

```
POST /v1/social/co-watch/sessions    { reelId, inviteeAccountId }
→ 201 { sessionId, inviteUrl: "stylemint://co-watch/{sessionId}" }
```

Realtime via SignalR — both clients connect to a session-scoped
group on `/hubs/notifications` (or a dedicated co-watch hub —
check backend skill).

Reactions are emoji bursts overlaid on the reel preview. Use
Flutter's built-in `AnimationController` + `Tween` (or the `flutter_animate` package) for the bounce animation.

## 9. Drop Parties (Pillar C)

**Backend skill**: `stylemint-social-graph`

Customer-facing flow. Creator-side host UI is in `CREATOR_FLOWS.md`
§10.

### 9.1 Discover

```
GET /v1/social/drop-parties?state=upcoming|live|past&cursor=...
```

### 9.2 Join

Tap the deep link `stylemint://drop/{id}` or browse from the
discover screen.

```
POST /v1/social/drop-parties/{id}/join     { invitationCode? }
```

`invitationCode` required for private drops.

### 9.3 Live view

During the live window:
- Vertical reel-like player (still pointer — opens external)
- Featured product card (driven by host)
- Push "drop alert" arrives at scheduledStartUtc
- Limited-stock countdown per product

### 9.4 Buy from drop

Standard Add to Cart → checkout. The cart item carries
`dropPartyId` for attribution and the limited-stock reservation.

## 10. Tips (Pillar C)

**Backend skill**: `stylemint-social-graph`

Send a small transfer (Rs 50 / 100 / 500 / custom) to a creator.

### 10.1 Send

```
POST /v1/social/tips
{ creatorId, amount: { amount: 100, currency: "NPR" }, message? }
→ 201 TipDto
```

Platform fee 3% flat — display "Rs 3 to Style Mint, Rs 97 to
{creator}" before confirm.

### 10.2 History

```
GET /v1/social/tips/sent     → PagedResult<TipDto>
```

(Creator-side received list is in `CREATOR_FLOWS.md` §11.)

## 11. Stitched Reels (Pillar C)

**Backend skill**: `stylemint-reels` (via social-graph link)

Reply-style threading between reels:

```
POST /v1/social/stitches    { parentReelId, replyReelId }
GET  /v1/reels/{id}/stitches → PagedResult<StitchDto>
```

Both reels live on their respective external platforms; the
stitch is metadata only. Display as a nested thread on parent
reel detail.

## 12. Multi-facet Reputation (Pillar C)

**Backend skill**: `stylemint-reputation`

**No single aggregate score.** Each account has multiple facets:

- `BuyerReliability` — on-time payment, low cancel rate
- `ReviewerCredibility` — review quality + proof-of-buy
- `CreatorEngagement` — content performance
- `CourierReliability` — Pillar B couriers
- `VendorFulfillment` — ship times, return rate

```
GET /v1/reputation/accounts/{accountId}
→ {
  facets: {
    BuyerReliability:    { value, lastComputedUtc, ... },
    ReviewerCredibility: { value, ... },
    // ...
  },
  badges: [
    { slug: "first-sold-out-drop", earnedUtc, ... },
    ...
  ]
}
```

**Visibility is per-consumer.** A vendor viewing a creator sees the
creator's `CreatorEngagement` facet; a customer viewing the same
creator might see `ReviewerCredibility` instead. The backend
returns the appropriate subset per request — don't try to filter
client-side.

Badges are **earned-only** ("First sold-out drop", "100 verified
reviews", "Neighborhood top courier this month"). No purchasable
badges.

## 13. Reporting + blocking

**Backend skills**: `stylemint-admin` (moderation queue),
`stylemint-identity` (blocks)

Customers can report any social content:

```
POST /v1/customer/posts/{id}/report        { reasonCode }
POST /v1/customer/comments/{id}/report     { reasonCode }
POST /v1/customer/stories/{id}/report      { reasonCode }
POST /v1/customer/reels/{id}/report        { reasonCode }
```

Closed reason-code set (matching admin moderation):

```
SPAM | NUDITY_OR_SEXUAL | HATE_OR_HARASSMENT | VIOLENCE |
MISLEADING | COUNTERFEIT_PRODUCT | OTHER
```

Block another account:

```
POST   /v1/blocked-accounts        { targetAccountId, reason? }
DELETE /v1/blocked-accounts/{id}
GET    /v1/blocked-accounts
```

Blocked accounts disappear from feed, search, recommendations.
Mutual-friendship is auto-severed.

## 14. Push notifications for social

Per `stylemint-messaging` template keys, the social notification
types include:

| templateKey | Trigger |
|---|---|
| `social.friend_request_received` | Someone sent you a friend request |
| `social.friend_request_accepted` | They accepted yours |
| `social.mention_in_post` | Tagged in a post |
| `social.mention_in_comment` | Tagged in a comment |
| `social.reply_to_your_post` | Someone replied to your post |
| `social.reply_to_recommendation` | New reply on your reco request |
| `social.reply_accepted` | Your reply was accepted (affiliate eligible!) |
| `social.story_reply` | DM reply to your story |
| `social.drop_party_starting` | A drop you joined is about to go live |
| `social.tip_received` | Someone tipped you |
| `social.group_invite` | Invited to join a group |
| `social.endorsement_received` | Someone endorsed your expertise |

Each push carries a `data.url` deep link to the right screen.

## 15. UX rules + invariants

- **Friendship requires mutual consent.** Never display a one-way
  friendship state.
- **Group posts are NOT main feed posts.** Cross-posting is opt-in.
- **Stories expire at 24h exactly.** Hangfire enforces; mobile
  doesn't need to compute.
- **Professional circles require KYC.** No self-declaration bypass.
- **Contact import never sends raw phone numbers.** Hash client-
  side; backend deletes hashes after matching.
- **Asker cannot accept own reply.** No self-affiliate fraud.
- **Recommendation_signals is append-only.** The mobile app never
  edits or deletes a signal — only writes new ones via the
  appropriate endpoints.
- **No buyable reputation, no buyable matches, no buyable rank.**
  Don't render any "boost my profile" CTAs in social surfaces.
- **Quiet Hours enforced server-side** for push (also applies to
  social pushes).
- **Tips: 3% platform fee, displayed before confirm.** Don't hide
  the fee.
