# Vendor Flows — Style Mint Mobile

Companion to `SKILL.md`. Per-feature guidance for the Vendor-side
mobile surface. Vendors list products, run campaigns with creators,
fulfill orders, and withdraw earnings.

Read the backend skill named in each section for endpoint details.

**Stack:** Flutter 3.41.9 · Dart 3.7 · Feature-First Clean Architecture.
All screens live in `lib/features/vendor/<feature>/presentation/`.
All business rules live in `lib/features/vendor/<feature>/domain/usecases/`.

## 1. Become a Vendor

**Backend skill**: `stylemint-onboarding`

```
1. profile/become-vendor             → CTA
2. vendor_apply_page.dart (multi-step):
   Step 1 — Business basics
     - Business name (= brand name)
     - Business type (Individual / Sole Proprietor / LLC / etc.)
     - Primary category (from catalog taxonomy)
     - Contact email + phone (E.164)
   Step 2 — KYC documents
     - National ID or passport (front + back)
     - Business registration certificate (if not Individual)
     - PAN (Nepal-specific)
     - Bank account proof OR eSewa screenshot
   Step 3 — Brand profile
     - Logo (square, ≥ 512px)
     - Description (≤ 500 chars)
     - Banner image (optional)
     - Social links (IG / TikTok / website)
   Step 4 — Tax info
     - VAT number (if applicable)
3. POST /v1/onboarding/vendor-applications  (multipart with docs)
   → 201 { applicationId, state: "Submitted" }
4. KYC review SLA: 1–3 business days
```

Documents uploaded via the standard verification-documents endpoint
(see `stylemint-identity` SKILL.md §3). Mobile camera + file picker
via `image_picker` and `file_picker` plugins.

Once Approved, the Vendor RoleProfile flips to `Approved`. Activate
via the role switcher.

## 2. Vendor dashboard

**Backend skill**: `stylemint-catalog` + `stylemint-orders` +
`stylemint-brand-studio`

```
GET /v1/vendor/dashboard
→ {
  pendingOrders, todaysSales, weekSales, monthSales,
  inventoryAlerts: { lowStock: [...], outOfStock: [...] },
  unreadMessages: number,
  activePartnerships, activeCampaigns
}
```

Render as a card grid. Tap each card to drill into the matching
detail screen.

## 3. Products — the 5-step Add Product wizard

**Backend skill**: `stylemint-catalog`

Locked spec (per `stylemint-catalog` SKILL.md): five steps, in this
exact order.

### Step 1 — Basic

- Title (≤ 100 chars)
- Description (≤ 5000 chars, supports basic markdown)
- Brand (auto-filled from vendor profile)
- Category (single select from 65 starter categories — taxonomy is
  data; see `stylemint-catalog`)
- Tags (≤ 10)

### Step 2 — Images & Media

- 1–10 images (square preferred; backend resizes)
- Optional video URL (external — IG/TikTok/YouTube)
- Image alt text per image (accessibility + SEO)

### Step 3 — Pricing & Inventory

- **Cost / Profit** — `cost` (Money) and `price` (Money). The UI
  computes profit margin live; backend stores both.
- **Track Inventory** — toggle
- **Allow Overselling** — toggle (only relevant when TrackInventory
  is on)
- **Variants** — array of `{ name, attributes, price, stock }`. Per-
  variant price + stock.
- **Payment patterns supported** — checkboxes for FullPayment /
  Subscription / Installment / Bnpl. Per-variant.

### Step 4 — Shipping

- Weight + dimensions (for shipping calculation)
- Shipping origin (default vendor's primary address)
- Free shipping threshold (optional)
- Restricted regions (optional)

### Step 5 — Review

- Read-only summary of all four prior steps
- **CreatorsEarn preview** — what creators earn when tagging this
  product. Show the rupee amount, not just the percent.
- Publish CTA → `POST /v1/products` with full payload.

**Save as draft** is supported at every step:

```
POST /v1/products/drafts { ...currentStepData }
PUT  /v1/products/drafts/{id}/{step} { ... }
```

Drafts auto-save every 30 s. Final publish:

```
POST /v1/products/drafts/{id}/publish
→ 201 ProductDto
```

## 4. Reviews (vendor side)

Read `CUSTOMER_FLOWS.md` §8. From the vendor side:

```
GET /v1/vendor/products/{id}/reviews?cursor=...&filter=...
```

Filter by: Written / Reel, rating, has-image, has-photo,
verified-purchase-only.

**Reply to a review** (one per review, public):

```
POST /v1/vendor/products/{productId}/reviews/{reviewId}/reply
{ text: "..." }
```

**Report a review** (policy violations):

```
POST /v1/customer/reviews/{id}/report   { reasonCode }
```

(Same endpoint as customer reporting — backend determines reporter
from JWT.)

## 5. Brand profile

**Backend skill**: `stylemint-catalog`

The vendor's **Brand** is catalog metadata that customers and
creators see on the storefront.

```
GET /v1/brands/me
PUT /v1/brands/me {
  description, logoUrl, bannerUrl, socialLinks,
  commissionRangeFromPercent, commissionRangeToPercent
}
```

- **Commission range** = the band offered across all partnerships
  (e.g. 12–20%). Per-partnership rate locks to a specific value
  within this range. Changing the range does NOT affect signed
  partnerships.
- **Brand Rating** is computed from aggregated reviews — not
  vendor-controlled.

## 6. Partnerships — vendor side

**Backend skill**: `stylemint-partnerships`

### 6.1 Discover creators

```
GET /v1/partnerships/creators/discover?category=...&q=...&cursor=...
→ PagedResult<CreatorCardDto>
```

Each card shows reputation facets, recent reels, content categories,
average engagement.

### 6.2 Send an invite

```
POST /v1/partnerships/invites
{
  creatorId,
  commissionRangeFromPercent,
  commissionRangeToPercent,
  termsTemplateId,
  message?
}
→ 201 PartnershipInviteDto
```

UI: wizard "Pick creator" → "Set commission" → "Choose terms" →
"Add note" → "Review".

### 6.3 Existing partnerships

```
GET /v1/partnerships/active?cursor=...
GET /v1/partnerships/{id}                  → full detail
GET /v1/partnerships/{id}/sales            → PagedResult<AttributedSaleDto>
```

The Tag Products surface mirrors the creator side — show both
percent and rupee amount per sale.

### 6.4 Adjust commission (within range)

```
PATCH /v1/partnerships/{id}/commission { ratePercent }
```

Must be within the partnership's range. Already-sold cart items
keep their frozen rate.

### 6.5 Performance window

Default 30 days; configurable 7–90 days at brief-signing time.

## 7. Brand Studio (Pillar D)

**Authoritative frontend skill**: `stylemint-brand-studio-frontend`
— **read this for every endpoint, ViewModel, DTO, and error code**.
22 endpoints total (8 brief authoring + 7 dashboard/analytics/activity
+ 7 admin). The mobile app consumes the first 15.

**Backend strategy skill**: `stylemint-brand-studio` — the *why*
(campaign goals, brief versioning model, LLM seam, cohort
benchmarks). Read alongside.

This section is a mobile-flow overview only. Endpoint shapes,
validators, and error codes live in `stylemint-brand-studio-frontend`
SKILL.md §3–§7; do not duplicate or paraphrase them here.

### 7.1 Brief lifecycle (Draft → Locked → Retired)

The state machine has **three states**, not four — there is no
"Published" state and **no compliance-scan endpoint** in v1.1.

```
                  POST /v1/vendor/briefs           (LLM-drafts)
                          │
                          ▼
                       ┌────────┐    PATCH /v1/vendor/briefs/{id}
              ┌────────│ Draft  │◄────────────────────────────┐
              │        └────────┘                              │
              │             │                                  │
              │             │  POST /v1/vendor/briefs/{id}/lock│
              │             ▼                                  │
              │        ┌────────┐                              │
              │        │ Locked │   POST /v1/vendor/briefs/{id}/fork
              │        └────────┘──┐                           │
              │             │      └──► new Draft (version++) ─┘
              │             │
              │             │  POST /v1/vendor/briefs/{id}/retire
              ├─────────────┘
              ▼
         ┌────────┐
         │Retired │
         └────────┘
```

- **Draft → Locked**: makes the brief immutable; required before
  the brief can be attached to a partnership invite.
- **Locked → Fork**: clones to a new Draft with incremented
  `version`. To edit a Locked brief, fork it.
- **Any state → Retired**: removes from default list; still
  queryable for history.
- **Retire is idempotent**: retiring an already-Retired brief
  returns 200 with no change.

Additional brief operation:
`POST /v1/vendor/briefs/{id}/recompute-roi` re-runs the ROI projector
seam against the current contents (returns just the projection,
not the full brief).

### 7.2 Brand Intelligence — dashboard, analytics, activity

**Not a single endpoint** — six separate endpoints, each scoped to
its surface:

| Endpoint | Mobile screen |
|---|---|
| `GET /v1/vendor/dashboard?windowDays=30` | One-shot dashboard composite |
| `GET /v1/vendor/analytics/overview?fromUtc&toUtc&topProductsLimit&topCreatorsLimit` | KPI tiles + trend + traffic sources |
| `GET /v1/vendor/analytics/products?fromUtc&toUtc&limit=50` | Full top-products list |
| `GET /v1/vendor/analytics/creators?fromUtc&toUtc&limit=50` | Full top-creators list |
| `GET /v1/vendor/products/{productId}/analytics?fromUtc&toUtc&...` | Product deep-dive |
| `GET /v1/vendor/activity?cursor&pageSize=25&kinds[]=...` | Activity timeline (cursor-paginated) |

**Window cap is 365 days** across all analytics endpoints; > 365 days
returns `400 validation.out_of_range`.

**Cohort privacy floor**: the dashboard's `benchmark` field is `null`
when the cohort has < 5 members — hide the competitive-benchmark card.

### 7.3 Multi-vendor team header

If a single human is on multiple vendor teams, every vendor endpoint
takes an `X-Vendor-Account-Id: <guid>` header to select which vendor
to act as. The solo-vendor case omits the header. See
`stylemint-brand-studio-frontend` §2.3 for the exact resolver rules
and the `403 auth.forbidden` failure mode.

### 7.4 What's deliberately NOT in v1.1

Per `stylemint-brand-studio-frontend` §1.1, the following are out
of v1.1 scope — do not build UI for them:

- Multi-vendor team-switcher UX (the header is wired but no UI
  picker yet).
- Brief sharing / collaboration between teammates.
- Real-time co-editing.
- "Regenerate this hook" LLM buttons — the flow is **Draft → PATCH
  → Lock** only.
- Compliance / disclosure scanning (no endpoint exists). Disclosure
  tagging happens server-side at partnership-sign time, not in the
  Brief Builder.
- Boost ROI bidding (that lives in `stylemint-reach`).
- Cohort opt-out from the policy form.

### 7.5 Admin policies (NOT a mobile concern)

The 7 admin endpoints under `/v1/admin/brand-studio/*` (policies +
goal templates) are consumed by `stylemint-admin-frontend`, not the
mobile app. The mobile dev should ignore them.

## 8. Orders — vendor fulfillment

**Backend skill**: `stylemint-orders`

Each customer Order produces one SubOrder per vendor.

```
GET /v1/vendor/sub-orders?state=...&cursor=...
→ PagedResult<SubOrderDto>
```

States: `Pending → Confirmed → Picked → Shipped → Delivered`.

```
POST /v1/vendor/sub-orders/{id}/confirm
POST /v1/vendor/sub-orders/{id}/pick
POST /v1/vendor/sub-orders/{id}/ship      { trackingNumber, carrier }
```

`trackingNumber` is vendor-provided unless Pillar B is wired — then
auto-assigned `SM-D-{8 digits}`.

### 8.1 Return requests (incoming)

```
GET  /v1/vendor/returns?state=...&cursor=...
POST /v1/vendor/returns/{id}/{accept,reject} { reason? }
```

7-day return window with photo evidence.

## 9. Earnings + Payouts

**Backend skill**: `stylemint-payouts`

Same shape as `CREATOR_FLOWS.md` §8 — earnings ledger is shared.
Differences:

- Vendors typically higher volume → On-Demand mode is more common.
- Source = `Order → SubOrder` (not `Reel → Order`).
- VAT line shown separately if collected at checkout.

Four destinations: NIMB, Laxmi, PayPal, eSewa.

## 10. Matchmaking — "Creators who fit you" (Pillar E)

**Backend skill**: `stylemint-matchmaking`

```
GET /v1/matchmaking/vendor/me/inbound-matches?cursor=...
→ PagedResult<MatchSnapshotDto>
```

Each match has an **explained score**. One-tap invite from match:

```
POST /v1/matchmaking/matches/{snapshotId}/invite-creator
→ 201 PartnershipInviteDto
```

### 10.1 Featured matches

Weekly platform-curated nudges via push:

```
GET /v1/matchmaking/vendor/me/featured?cursor=...
```

Fairness invariants: no pay-to-rank, no protected-class attributes
in embeddings.

## 11. Reach — vendor reels + boost (Pillar E)

**Backend skill**: `stylemint-reach`

```
POST /v1/reach/vendor/boost     { reelId, dailyBudget, platforms, durationDays }
```

Mirrors creator-side boost. Analytics:

```
GET /v1/reach/vendor/analytics/reels/{reelId}
```

## 12. Reputation (vendor side)

**Backend skill**: `stylemint-reputation`

Facets:

- `VendorFulfillment` — ship times, return rate, photo accuracy
- `ReviewerCredibility` (if vendor also reviews products as a customer)

Rendered on storefront + on partnership invites (creator sees
vendor's reputation).

## 13. Subscriptions, Installments, BNPL

**Backend skill**: `stylemint-catalog` + `stylemint-payments`

Per CLAUDE.md §3, products support up to four payment patterns:

| Pattern | Backend value | Vendor UI considerations |
|---|---|---|
| Full payment | `FullPayment` | Default. Single charge at checkout. |
| Subscription | `Subscription` | Billing interval (monthly/quarterly/annual) + trial period. Cancellation graceful (current period stays paid). |
| Installment | `Installment` | Plan: N payments over M months. Platform-financed. Immutable once selected by customer. |
| BNPL | `Bnpl` | Third-party only (Klarna / LazyPay / Simpl). Style Mint does NOT extend credit. |

Add Product Step 3 has a checkbox per pattern per variant.
Pre-filter the option based on `productKind` (e.g. no Subscription
on Digital one-shot download).

## 14. Vendor team members

**Backend skill**: `stylemint-identity`

```
GET    /v1/vendor/team
POST   /v1/vendor/team       { accountEmail, role: "Manager" | "Staff" | "Viewer" }
DELETE /v1/vendor/team/{accountId}
```

Roles:

- `Manager` — everything except team management + bank details
- `Staff`   — fulfill orders, reply to reviews
- `Viewer`  — read-only

JWT carries `vendor_team_role` claim — backend authorizes per
endpoint. Mobile UI gates accordingly.

## 15. Tax information

**Backend skill**: `stylemint-identity`

```
GET /v1/tax-information/me
PUT /v1/tax-information/me { vatNumber?, taxResidency, ... }
```

Required before withdrawals exceed Rs 100,000 cumulative (backend
gates the withdrawal endpoint).

## 16. Edge cases + UX rules

- **Vendor not yet Approved** — wizard editable but Publish disabled
  with banner "Listings unlock after KYC approval."
- **KYC docs rejected** — surface the reason code, allow re-submit
  (same applicationId until terminal rejection).
- **Stock countdown** — products with `trackInventory: true` show
  remaining stock; stock-field validates against current orders.
- **Brand Studio brief validation** — backend FluentValidation
  rejects invalid Draft/PATCH payloads with the standard
  `validation.*` codes (see `stylemint-brand-studio-frontend` §7).
  Surface inline per the multi-field error contract.
- **Brand Studio brief Locked** — PATCH on a Locked brief returns
  `409 state.invalid_transition`. UX: prompt the user to Fork (which
  produces a new Draft with incremented version).
- **Performance window expiry** — surface 7 days before with a
  "Renew?" CTA (renewal = new partnership with fresh window).
