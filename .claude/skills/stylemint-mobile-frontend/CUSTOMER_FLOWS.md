# Customer Flows — Style Mint Mobile

Companion to `SKILL.md`. Per-feature guidance for the Customer-side
mobile surface. Each section names the backend skill to read for
endpoint details — this doc covers the **mobile flow + UX rules**,
not every DTO.

**Stack:** Flutter 3.41.9 · Dart 3.7 · Feature-First Clean Architecture.
All screens live in `lib/features/customer/<feature>/presentation/`.
Business rules live in the repository (`domain/repositories/` interface +
`data/repositories/` impl); presentation `StateNotifier`s call the repository
directly — **no `domain/usecases/`**. Notifier state is a Freezed union;
side-effects (navigation, snackbars) use **`ref.listen` + `maybeWhen`**,
never await-then-read (SKILL §3.8).

## 1. Onboarding

**Backend skill**: `stylemint-onboarding`

### 1.1 New account

```
1. (auth)/welcome  →  user taps "Sign up"
2. (auth)/sign-in is a single field "Email or phone"
3. Identify input:
     - phone (E.164) → OTP path
     - email          → magic-link path (or password if existing)
4. Verify → AuthResponseVm → tokens stored
5. New account? backend returns no roles yet → redirect to onboarding/role-picker
6. Customer is the default role for new accounts (auto-Approved + Active)
7. → onboarding/interests
```

### 1.2 Pick Your Interests

**Locked spec**: 15 categories, **minimum 3 required**.

The 15 customer interest categories include Beauty (per `stylemint-
onboarding` SKILL.md). Render as a 3-column grid of category cards
with icons; tap to toggle. Submit button disabled until ≥ 3
selected.

```
POST /v1/onboarding/customer-interests
{ categoryIds: ["uuid", "uuid", "uuid"] }
→ 204
```

On success, navigate to `(tabs)/home`. The discovery feed is now
seeded with these interests (`stylemint-discovery` reads
`account_interests` to personalize).

The user can edit later: `lib/features/settings/interests/interests_page.dart`.

## 2. Home + Discovery

**Backend skill**: `stylemint-discovery`

### 2.1 Home tab

One round-trip per Figma spec. The home endpoint returns:

```
GET /v1/discovery/home?cursor=...&pageSize=20
→ PagedResult<HomeFeedItemDto>
```

Items are heterogeneous — each carries a `kind`:

```ts
type HomeFeedItem =
  | { kind: "reel";    reel: ReelDto }
  | { kind: "product"; product: ProductCardDto }
  | { kind: "creator"; creator: CreatorCardDto }
  | { kind: "brand";   brand: BrandCardDto }
  | { kind: "post";    post: SocialPostDto };       // Pillar F
```

Use a sealed-class union in Dart + a `switch` in the `ListView.builder` item builder.

### 2.2 Search

```
GET /v1/discovery/search?q=...&kind=...&cursor=...
```

`kind` filters to one of: `reel | product | creator | brand | post`.
Debounce input (300 ms) before firing the query. Show recent
searches from `shared_preferences` when input is empty.

### 2.3 Category landing

```
GET /v1/discovery/category/{categoryId}/page?cursor=...
```

## 3. Reels feed

**Backend skill**: `stylemint-reels` + `stylemint-discovery`

The reels tab is a vertical infinite feed (TikTok-style). Each
ReelDto is a **pointer record** — the reel was authored on
Instagram / TikTok / YouTube / Facebook. Style Mint does not host or
play video.

```ts
type ReelDto = {
  id: string;
  sourcePlatform: "Instagram" | "TikTok" | "YouTubeShorts" | "Facebook";
  externalUrl: string;                  // tap → open native app
  thumbnailUrl: string;                 // for preview only
  durationSeconds: number;
  creator: { id, handle, avatarUrl, displayName };
  taggedProducts: TaggedProductCardDto[];
  audioTrack?: { name, artist, externalListenUrl };
  likeCount: number; commentCount: number; viewCount: number;
  engagementSnapshotUtc: string;
  isLikedByMe: boolean;
};
```

**Rendering rule**: show the thumbnail + a "Play on Instagram"
(/TikTok/etc.) overlay button. **Never embed a video element**. Tap
opens the external app:

```dart
import 'package:url_launcher/url_launcher.dart';
await launchUrl(Uri.parse(reel.externalUrl), mode: LaunchMode.externalApplication);
```

### 3.1 Tagged Product Cards

The glassmorphic overlay cards rendered on top of the reel preview.
Each carries:

```ts
type TaggedProductCardDto = {
  productId: string;
  title: string;
  imageUrl: string;
  priceFrom: Money;             // "from Rs 1,234.56"
  inStock: boolean;
  attribution: {
    creatorId: string;
    commissionRatePercent: number;
    perSaleAmount: Money;       // shown on the creator side, not customer
  };
};
```

Tap → `/product/:id` route (in `lib/features/customer/catalog/product_page.dart`). The "Add to Cart" button on the card
fires `POST /v1/cart/items` with `attributionReelId = reel.id` so
commission is snapshotted (per `stylemint-cart-checkout` invariant
"Commission snapshotted at reel-tag time").

### 3.2 Comments

```
GET  /v1/reels/{reelId}/comments?cursor=...
POST /v1/reels/{reelId}/comments         { text }
POST /v1/reels/{reelId}/comments/{id}/like
```

Comment likes are per-comment (separate aggregate from reel likes).

### 3.3 Report a reel

```
POST /v1/customer/reels/{reelId}/report
{ reasonCode: "SPAM" | "NUDITY_OR_SEXUAL" | "HATE_OR_HARASSMENT" |
              "VIOLENCE" | "MISLEADING" | "COUNTERFEIT_PRODUCT" | "OTHER" }
→ 200 (or 200 if self-report — silently dropped server-side)
```

Same closed-set codes as the admin moderation queue (per
`stylemint-admin` SKILL.md §5).

## 4. Product detail

**Backend skill**: `stylemint-catalog`

```
GET /v1/products/{id}
→ ProductDetailDto (includes variants, images, reviews summary,
  vendor card, related products, recent reels tagging this product)
```

Product **kind** drives flow:

- `Physical`     → Add to Cart → standard checkout
- `Digital`      → Add to Cart → checkout → instant download link in order
- `Service`      → "Book Now" CTA → booking flow (subset of checkout)
- `Subscription` → "Subscribe" CTA → checkout with recurring payment

Each variant flags which of the four payment patterns it supports
(FullPayment / Subscription / Installment / Bnpl). Render the CTA
based on the selected variant's flags.

## 5. Cart

**Backend skill**: `stylemint-cart-checkout`

Cart is Redis-primary, Postgres-durable. Backend returns:

```ts
type CartDto = {
  id: string;
  items: CartItemDto[];
  subtotal: Money;
  estimatedShipping?: Money;
  estimatedTotal: Money;
  appreciatedCreatorCount: number;   // for "You are appreciated" summary
};

type CartItemDto = {
  id: string;
  productId: string;
  variantId: string;
  title: string;
  imageUrl: string;
  unitPrice: Money;
  quantity: number;
  lineTotal: Money;
  attribution?: {
    reelId: string;
    creatorId: string;
    creatorHandle: string;
  };
};
```

Endpoints:

```
GET    /v1/cart
POST   /v1/cart/items              { productId, variantId, quantity, attributionReelId? }
PATCH  /v1/cart/items/{id}         { quantity }
DELETE /v1/cart/items/{id}
POST   /v1/cart/save-for-later/{id}
```

**"You are appreciated" card** appears once at the top of cart when
`appreciatedCreatorCount > 0`. Copy: "You're supporting {N}
{N==1 ? 'creator' : 'creators'} with this order." (Locked phrasing —
see `stylemint-cart-checkout` SKILL.md.)

### 5.1 Cart line attribution

When an item was added from a reel, the cart item carries
`attribution.reelId`. Display the creator badge ("from @handle's
reel"). On checkout, the commission is paid to that creator with
the rate snapshotted at the time of Add to Cart — backend already
froze it.

## 6. Checkout saga

**Backend skill**: `stylemint-cart-checkout`

The checkout is a **server-driven state machine**. The mobile app
doesn't decide the order of steps — it submits each step and the
server tells you what's next via the returned `CheckoutSessionDto`'s
`state` field.

```ts
type CheckoutSessionDto = {
  id: string;
  accountId: string;
  state: "Started" | "AddressSet" | "MethodSet" | "Placing" | "Placed" | "Failed";
  items: CartItemSnapshot[];
  selectedAddressId?: string;
  selectedPaymentMethod?: "Visa" | "Mastercard" | "PayPal" | "Esewa" | "CashOnDelivery";
  amounts: { subtotal: Money; shipping: Money; total: Money };
  rowVersion: string;
};
```

Steps:

```
1. POST   /v1/checkout/sessions                              → state: Started
2. POST   /v1/checkout/sessions/{id}/address  { addressId }  → state: AddressSet
3. POST   /v1/checkout/sessions/{id}/payment-method { method } → state: MethodSet
4. POST   /v1/checkout/sessions/{id}/place                   → state: Placing → Placed | Failed
```

Idempotency-Key per step. The session **expires after 30 minutes**
of inactivity — surface a countdown if you want, or just handle
`checkout.session_expired` on the next step.

### 6.1 Shipping address

Backend pre-loads the user's saved addresses (see
`stylemint-identity`'s address book). Render a list with "Use this
address" / "Add new". New address form fields are locked per Figma:

```
- Full name
- Phone (E.164)
- Country (default Nepal)
- Province
- District
- City / municipality
- Street address (line 1, 2)
- Landmark (optional)
- Postal code
```

Submit creates an address row + selects it for the session:

```
POST /v1/addresses             { ...fields }
POST /v1/checkout/sessions/{id}/address { addressId }
```

### 6.2 Payment method (4 only, locked)

Render exactly four options (per `DESIGN_VERIFIED_CORRECTIONS.md`):

| Label | Backend value | Visual |
|---|---|---|
| Visa / Mastercard | `Card` | Card logos |
| PayPal            | `PayPal` | PayPal logo |
| eSewa             | `Esewa`  | eSewa green |
| Cash on Delivery  | `CashOnDelivery` | Cash icon |

After selection, `place` returns a `PaymentInitiationDto` (from
`stylemint-payments`) carrying:

```ts
type PaymentInitiationDto = {
  intentId: string;
  method: "Card" | "PayPal" | "Esewa" | "CashOnDelivery";
  // For Card: redirect URL for 3DS challenge (in-app browser)
  redirectUrl?: string;
  // For PayPal: redirect URL to PayPal approval (in-app browser)
  approvalUrl?: string;
  // For eSewa: form fields + POST URL (open in-app browser, submit)
  esewaForm?: { actionUrl: string; fields: Record<string, string> };
  // For CashOnDelivery: nothing — order is placed immediately
};
```

Use `flutter_web_browser` (or `url_launcher` with `LaunchMode.inAppBrowserView`) for
redirect-based methods. The return URL is a deep link
`stylemint://payment/return?intentId=...` — the app polls
`GET /v1/payments/intents/{id}` until status is `Captured` or
`Failed`.

### 6.3 Place the order

```
POST /v1/checkout/sessions/{id}/place
→ 200 { orderId, orderNumber: "NK2024-89126", subOrders: [...] }
```

Navigate to `/order/:id` route (in `lib/features/customer/orders/order_detail_page.dart`). Show the order number prominently
— format is locked (`NK{year}-{5 digits}`).

## 7. Orders

**Backend skill**: `stylemint-orders`

```
GET /v1/orders?cursor=...&state=...
→ PagedResult<OrderSummaryDto>

GET /v1/orders/{id}
→ OrderDetailDto (includes sub-orders per vendor)
```

The customer-facing Order has 1..N **SubOrders** — one per vendor.
Each sub-order has its own state machine (Pending → Confirmed →
Shipped → Delivered) and tracking number.

### 7.1 Track Order

Show one card per sub-order with:
- Vendor name + logo
- Items
- Status pill
- Tracking number (`SM-D-{8 digits}` if Pillar B is on; otherwise
  the vendor's own tracking)
- "Track package" button → if SM-D format, open
  `/delivery/:trackingNumber` route (Story Mode if Pillar B);
  otherwise external link

### 7.2 Cancel order

3-step cancel flow (per `stylemint-orders` SKILL.md):

```
1. Choose reason — 6 fixed codes:
   "CHANGED_MIND" | "FOUND_BETTER_PRICE" | "ORDER_DELAYED" |
   "WRONG_ITEM" | "BUYER_REMORSE" | "OTHER"
2. Confirm — "Refund will be acknowledged in 5–7 business days"
3. Submit
```

```
POST /v1/orders/{id}/cancel { reasonCode, note? }
```

### 7.3 Return

Within 7 days of delivery, with photo evidence:

```
POST /v1/orders/{orderId}/sub-orders/{subId}/return
{
  itemIds: [...],
  reasonCode: "DAMAGED" | "WRONG_ITEM" | "NOT_AS_DESCRIBED" | "DEFECTIVE" | "OTHER",
  photoUrls: ["https://..."],
  note: "..."
}
```

Photos uploaded first via `POST /v1/uploads/return-evidence` (a
presigned URL flow — see `stylemint-orders` SKILL.md).

## 8. Reviews

**Backend skill**: `stylemint-catalog`

Two review types:

- **Written** — stars (1–5) + text + optional images
- **Reel** — external URL + platform picker (the customer's own
  reel about the product)

```
POST /v1/products/{id}/reviews
{
  kind: "Written" | "Reel",
  rating: 1..5,
  text?: string,
  imageUrls?: string[],
  reelExternalUrl?: string,
  reelPlatform?: "Instagram" | "TikTok" | "YouTubeShorts" | "Facebook"
}
```

A customer can only review a product they purchased (server enforces
via order link). Proof-of-buy verification feeds the Reputation
module's `ReviewerCredibility` facet.

## 9. Wallet

**Backend skill**: `stylemint-identity` (wallet lives under Identity)

Customers have an in-platform wallet balance + ledger:

```
GET /v1/wallet/balance      → { balance: Money }
GET /v1/wallet/transactions → PagedResult<WalletTxDto>
```

Wallet is **credit-only in v1** — credited from refunds (CoD
returns, goodwill), spent at checkout as a partial payment. Cannot
top up externally.

## 10. Support

**Backend skill**: `stylemint-support`

### 10.1 Help Center

7 fixed categories (locked):

```
ORDERS_AND_RETURNS, PAYMENTS_AND_REFUNDS, SHIPPING_AND_DELIVERY,
ACCOUNT_AND_SECURITY, CREATORS_AND_VENDORS, APP_ISSUES, OTHER
```

```
GET /v1/help/articles?category=...&cursor=...
GET /v1/help/articles/{slug}
```

### 10.2 Submit a ticket

```
POST /v1/support/tickets
{
  category: <one of 7>,
  subject: string,
  body: string,
  attachments?: string[],   // uploaded URLs
  orderId?: string          // optional context
}
→ 201 { ticketId, ticketNumber: "#ST123456" }
```

Ticket number format is locked: `#ST{6 digits}`.

### 10.3 Ticket states

3 user-visible states (mapped from 5 internal):

| User sees | Internal |
|---|---|
| `Submitted` | `Open` |
| `In Progress` | `Assigned` or `AwaitingCustomer` |
| `Resolved` | `Resolved` or `Closed` |

Display the user-visible state only; never expose the 5-state
internal.

### 10.4 Notification preferences

```
GET /v1/notification-preferences
PUT /v1/notification-preferences { ... }
```

8 categories (see `stylemint-support` SKILL.md §6), ~20 toggles
total. **Quiet Hours** default 22:00–08:00 NPT — show as toggle +
time range picker; backend enforces.

### 10.5 Language

5 supported: `en-US`, `zh`, `ne`, `es`, `hi`. Update via:

```
PATCH /v1/accounts/me { locale: "ne" }
```

i18next switches client-side; backend uses the value for email/SMS
template language.

## 11. Settings

Standard settings stack with:

- Profile (`PATCH /v1/accounts/me`)
- Addresses (`/v1/addresses`)
- Payment methods (`/v1/payment-instruments` — tokens only, never raw PAN)
- Notification preferences (§10.4)
- Language (§10.5)
- Privacy (`/v1/privacy-settings`)
- Devices (`/v1/devices` — list + revoke sessions)
- Blocked accounts (`/v1/blocked-accounts`)
- Delete account (`POST /v1/account-deletion-requests` — 30-day
  cool-down with cancel option)
- About / legal / version

## 12. Performance budgets

- **Cold start** to interactive home: ≤ 2 s on a mid-range Android.
- **Reels feed** scroll: 60 fps. `ListView.builder` (already virtualized) + `CachedNetworkImage` for lazy thumbnails.
- **Discovery home**: one round-trip; backend pre-denormalizes.
- **Image policy**: thumbnails ≤ 200 KB, full-screen ≤ 600 KB.
  Backend serves resized variants — request the right size.
- **Bundle size**: target ≤ 30 MB for the JS bundle.
