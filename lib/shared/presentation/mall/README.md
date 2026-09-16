# Mall component kit

Presentational building blocks for the StyleMint 360° Digital Mall (Home "Mall | Reels").
Import everything with:

```dart
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
```

The widgets hold no state from Riverpod, repositories or DTOs. Each one takes a small immutable
view model defined in `mall_view_models.dart`. Feature screens map their own domain entities into
those view models and pass callbacks in. Copy defaults to English through `MallStrings`. To
localise, wrap the page in a `MallStringsScope`.

## Components

| Component | Purpose | Input |
|---|---|---|
| `MallSectionHeader` | Section title in the display face. Optional eyebrow, subtitle and "See all" (44dp target, spoken as "See all, {title}"). | `title`, `eyebrow?`, `subtitle?`, `onSeeAll?` |
| `MallRail<T>` | Horizontal, lazily built rail that snaps item by item. Shows skeletons while loading and an empty-state slot when empty. `stagger` drops every second item so a shopping rail reads as a composed row, not a filmstrip — size it with `heightForStaggered`. | `items`, `itemBuilder`, `itemWidth`, `height`, `semanticLabel`, `isLoading`, `skeletonBuilder?`, `emptyState?`, `stagger` |
| `MallProductTile` | **The Mall's product tile.** Picks `MallReelTile` when the product has a reel and `MallTypeTile` when it does not. Never builds a product photo — the Mall is video-first and photos belong to the product details page (owner directive, 2026-09-16). Pass `onQuickAdd` to put the buy control on the price line, and size the rail with `heightFor(withAction: true)`. | `MallProductVm`, `onTap?`, `onReelTap?`, `onSaveTap?`, `onQuickAdd?` |
| `MallQuickAdd` | **The buy affordance.** One tap adds to the bag without leaving the page: idle → in-flight → tick, then it resets itself. Owns its own state, ignores a second tap in flight, and takes `Future<bool> Function()` so the caller keeps the cart write and the message. A 44dp target around a 34dp disc; pass `label` for the pill used on the spotlight. | `onAdd`, `semanticLabel`, `label?` |
| `MallSpotlight` | **The Mall's counter.** One product given a whole block: the name at hero size, the price as a display numeral, the saving as a green slab, a live countdown, and both actions. The media panel runs past the trailing edge and drifts; below 360 dp the panel and copy stack. A product with no saving, rating or deadline simply shows its name and price, large. | `MallProductVm`, `eyebrow?`, `signal?`, `endsUtc?`, `onTap?`, `onReelTap?`, `onSaveTap?`, `onQuickAdd?` |
| `MallTicker` | **The signage band.** A slow, continuous line of the page's own brands, edits and categories, set in tracked capitals edge to edge. The one element that moves without being scrolled. Names only, never counts. Holds still under reduced motion and stops with `TickerMode`. | `words`, `semanticLabel` |
| `MallReelTile` | 4:5 reel poster with the play affordance, the reel's length, its hook and — whenever flagged — the **AI-generated** disclosure, which wraps and is never truncated. Brand, name and price sit underneath. Tapping opens the reel. Holds the screen's single play slot when it is the most visible reel, and its play mark then fills with brand green. | `MallProductVm`, `MallReelRef`, `onTap?`, `onSaveTap?` |
| `MallTypeTile` | The no-photo tile for the majority of the catalogue: a tonal ground picked deterministically from the product id, the brand as a tracked eyebrow, the name set large in Instrument Serif, a hairline and the price. Same footprint as `MallReelTile`, so a row mixes the two. | `MallProductVm`, `onTap?`, `onSaveTap?` |
| `MallReelPlaySlot` / `MallReelPlaySlotController` | Grants one tile on screen the single play slot — the most visible one, over half in view. Never grants one under `MediaQuery.disableAnimations`. Nothing plays inline in the Mall today (see below); the slot decides which tile is "the one on screen". | `id`, `builder(context, holdsSlot)` |
| `MallProductCard` | 4:5 **photo** with badges (discount, New, Low stock), rating and a save heart. Below it: brand, a two-line name, and the price with a struck-through original. For the product details page and the surfaces that belong to it — not for Mall surfaces. Sizes: `compact` and `regular`. | `MallProductVm`, `onTap?`, `onSaveTap?` |
| `MallProductGrid` / `MallSliverProductGrid` | Responsive grid: 2 columns under 600dp, 3 from 600dp, 4 from 900dp of available width. Box and sliver versions. | `List<MallProductVm>`, `onProductTap?`, `onSaveTap?`, `isLoading`, `emptyState?` |
| `MallReelCard` | 9:16 poster with a play mark, creator, tagged-product count and like count. Always shows the **AI-generated** label when flagged; the label wraps and is never truncated. | `MallReelVm`, `onTap?`, `onTaggedProductsTap?` (makes the product pill its own 44dp button) |
| `MallCreatorCard` | Cover strip, overlapping avatar, name and verified tick, style tags on one line, follower count, and a follow-button slot. | `MallCreatorVm`, `onTap?`, `followAction?` |
| `MallBrandCard` | 16:9 cover, overlapping logo tile, name and verified tick, two-line tagline. | `MallBrandVm`, `onTap?` |
| `MallCategoryTile` | Image tile with a scrim and label. Shapes: `square` (1:1) and `tall` (3:4). | `MallCategoryVm`, `shape`, `onTap?` |
| `MallCollectionCard` | Editorial cover card: eyebrow, title, up to three preview thumbnails and an item count. | `MallCollectionVm`, `aspectRatio`, `onTap?` |
| `MallCampaignHero` | Full-width carousel with scrim, eyebrow, display title, subtitle, up to 3 CTAs (first filled, the rest glass) and a page indicator. Auto-advances every 6 s, pauses while touched, and stays still when animations are disabled. Height is 62% of the screen, clamped to 360–640. | `List<MallCampaignVm>`, `onAction(campaign, action)` |
| `MallCinematicHero` | **The Mall's stage.** Full-bleed carousel that drifts (`MallKenBurns`), lags the page (`MallParallax`) and fades its copy out as you scroll. Display title closes on an italic word; segmented progress bars; secondary CTAs are translucent, never blurred. `heroTagFor` opts the campaign on screen into a shared-element flight. Height is 72% of the screen, clamped to 420–720. | `List<MallCampaignVm>`, `onAction`, `topInset`, `overline?`, `heroTagFor?` |
| `MallDealBand` | **Bold-retail plate.** Colour-blocked sheet with an angled cut, an oversized discount numeral, a live countdown and an inverted CTA, with the block's products running underneath. Every figure is optional: pass null and it is not drawn. | `title`, `child`, `eyebrow?`, `topDiscountPercent?`, `endsUtc?`, `ctaLabel?`+`onCta?`, `now?` |
| `MallEditorialSpread` | **Magazine block.** A 4:5 lead holding 62% of the width with two tiles stacked beside it; anything past the third runs on as a rail. Stacks below 360 dp. Tiles get exact boxes, so the block cannot overflow at any text scale. | `List<MallCollectionVm>`, `semanticLabel`, `onOpen?` |
| `MallCategoryMosaic` | **Graphic block.** Uneven tiles in a repeating 58/42, 42/58, thirds rhythm, typographic by default because Catalog categories carry no artwork; uses an image with a scrim when one ever arrives. | `List<MallCategoryVm>`, `semanticLabel`, `onOpen?` |
| `MallSignalChip` / `MallSignalLine` | One live fact — as a pill for section headers, as a bare line for cards. Tone is meaning: `urgent` is reserved for a real deadline or genuinely low stock. Numerals are tabular. | `MallSignal` |
| `MallCountdown` | Live countdown to a real deadline. Ticks per second inside the last hour and per minute before it, stops at zero and whenever `TickerMode` mutes the subtree. Builder gets a `MallRemaining` (display + spoken) or null. | `endsUtc`, `builder`, `now?` |
| `MallTrustStrip` | Authentic products from verified sellers, secure checkout, easy returns, live tracking. Tiles share the row when they fit and scroll horizontally otherwise. | `List<MallTrustItem>` (English defaults) |
| `SmSkeleton.box/line/circle` | Loading primitives on `SmShimmer`. The sweep follows text direction and is static under reduced motion. Hidden from semantics. | sizes |
| `SmSkeletonProductCard` / `SmSkeletonReelCard` / `SmSkeletonRail` | Skeletons with the same footprint as the real cards and rail. | widths |
| `MallEmptyState` | Illustration-free empty state: optional icon disc, eyebrow, display title, body and one primary action. | `title`, `body?`, `icon?`, `actionLabel?` + `onAction?` |

Supporting pieces:
- `MallNetworkImage`: cached, decoded near display size, fades in over `MallImagePlaceholder` (a tonal gradient with the StyleMint mark).
- `MallBadge`, `MallEyebrow`, `MallVerifiedBadge`, `MallSaveButton`, `MallAvatar`.
- `MallPrimaryCta`, `MallGlassCta`, `MallTapOverlay`.
- `MallMetrics`.

### View models

```
MallProductVm     id, name, price: Money, brandName?, imageUrl?, compareAtPrice?: Money,
                  rating?, reviewCount, saleEndsUtc?, isNew, isLowStock, isSaved,
                  reel?: MallReelRef
                  → isOnSale, discountPercent (floored), withSaved(saved:)
MallReelRef       reelId, posterUrl?, hook?, isAiGenerated, durationSeconds
                  → hasDuration. Null on most products (24 of 106 in production).
MallReelVm        id, creatorName, posterUrl?, creatorAvatarUrl?, caption?,
                  taggedProductCount, isAiGenerated, likeCount?
MallCreatorVm     id, name, handle?, avatarUrl?, coverUrl?, isVerified, styleTags, followerCount?
MallBrandVm       id, name, logoUrl?, coverUrl?, isVerified, tagline?
MallCategoryVm    id, label, imageUrl?
MallCollectionVm  id, title, eyebrow?, coverUrl?, itemCount?, previewImageUrls
MallCampaignVm    id, title, eyebrow?, subtitle?, imageUrl?, actions: List<MallCampaignAction(id, label)>
MallTrustItem     icon, title, body?
```

### Sizing rails

A horizontal rail needs a fixed height. Every card exposes an exact `heightFor` that accounts for
the ambient text scale, so pass that to the rail:

```dart
MallRail<MallProductVm>(
  items: products,
  itemWidth: MallProductCard.compactWidth,
  height: MallProductCard.heightFor(context, width: MallProductCard.compactWidth, size: MallCardSize.compact),
  semanticLabel: 'Trending products',
  isLoading: loading,
  skeletonBuilder: (_, _) => const SmSkeletonProductCard(width: MallProductCard.compactWidth, size: MallCardSize.compact),
  itemBuilder: (context, product, _) => MallProductCard(product: product, size: MallCardSize.compact, onTap: () => …),
)
```

## Zones

The Mall page is one system worn four ways. Zones differ in **density and dress, never in
identity** — one palette, one type scale, one motion language runs through all four. Which zone a
section gets is decided from the section's own data in
`features/customer/mall_home/presentation/mall_zones.dart`, not from its id.

| Zone | Blocks | Reads as |
|---|---|---|
| **Cinematic** | `MallCinematicHero`, the reel marquee, `MallTicker` | Full-bleed, moving, one thing at a time |
| **Editorial** | `MallEditorialSpread`, brand plates | Asymmetric, image-led, generous whitespace, rails flush |
| **Dense discovery** | `MallSpotlight`, staggered signal rails of `MallProductTile`, creator rails | Compact, scannable, buyable; every tile carries a live fact and a price you can act on |
| **Bold retail** | `MallDealBand`, `MallCategoryMosaic` | Colour-blocked, hard shapes, punchy CTAs |

### Page composition

Three things are decided once for the page, from the page's own data, in
`mall_zones.dart`:

- `spotlightSectionIndex` — the **one** block that leads with a `MallSpotlight`.
  The first discovery products block that yields a pick; the drop plate is
  skipped because it is already the loud one.
- `spotlightPickOf` — which product that block leads with, and why: biggest real
  saving, then soonest real deadline, then most reviewed with a rating behind
  it, then flagged new. A block with none of those still leads with its first
  item and makes **no** claim about it.
- `tickerSectionIndex` / `mallTickerWords` — where the signage band hangs, and
  the real names it carries.

### Buying from the Mall

Every product tile on the home page carries `MallQuickAdd`, and so does the
spotlight. The control is presentational: the cart write lives in
`features/customer/mall_home/presentation/mall_cart_actions.dart`, which is the
same `CartNotifier.addItem` path the product details page and Buy It Again use
— sign-in gate, one unit, a fresh idempotency key per attempt, the notifier's
own return value. There is no second cart path.

## Video first, photos on the details page

The Mall shows reels, never product photos (owner directive, 2026-09-16). Every Mall surface —
home (all zones), the product listing and its filter results, the brand storefront including Shop
All, and the creator storefront — builds `MallProductTile`. `MallProductCard` and its photo stay
for the product details page and the rails that belong to it.

**One reel plays at a time, and today none plays inline.** Mall tiles are posters that open the
reel on tap, because a rail tile is 148–184 dp wide and YouTube's Required Minimum Functionality
needs a player of at least 200 × 200 px, the contract's `reel` carries no permalink (so Facebook
and Instagram sources cannot resolve to an embed at all), and re-attaching a WebView to whichever
tile is most visible would thrash the 3.8 GB test phone, which has room for about two players in
total. `MallReelPlaySlotController` still enforces the one-tile rule and is the seam an inline
player plugs into.

## Honest signals

A signal is built from a field the API populated, or it is not built. Nothing on this page
estimates, extrapolates, or rounds a number up to look busier than the data is.

- **Allowed:** `reviewCount` behind a rating, a real `saleEndsUtc` (as a live countdown on the
  plate, or a Kathmandu-day bucket on a card), the floored discount from `compareAtPrice`,
  `taggedProductCount`, `followerCount`, `itemCount`, `isVerified`, rail lengths.
- **Not allowed:** anything the contract does not carry — units sold, stock counts, live viewers,
  trending deltas. `isLowStock` is a boolean meaning 1–5 units, so the card says "Only a few left"
  and never a number.
- A block whose data supports no claim simply shows no chips, and a products block only earns the
  drop plate when it really carries a deadline or several genuine discounts.

## Motion

`MallScrollLink` publishes the page's scroll offset; `MallParallax`, `MallScrollFade`,
`MallKenBurns` and `MallEnter` consume it. Each sits in its own `RepaintBoundary` and listens to a
notifier rather than rebuilding its parent, so scrolling never repaints the page, and `MallEnter`
drops out of the tree once its entrance finishes. All of it collapses to nothing under
`MediaQuery.disableAnimations`.

## Design rules

- **Palette:** a refined neutral base (`bgAppFoundation`, `bgAppBody`, `surfaceRaised`) with **one controlled accent**, StyleMint green. Green is reserved for primary CTAs, discount pills, verified ticks, the saved heart and the active page indicator. The only other tones are semantic status (`warningFillDark` for Low stock). Don't add colours.
- **Type:** Poppins for all UI text. **Instrument Serif** (`DesignTokens.displayHero` / `displayTitle` / `displaySection` / `displayAccent`) is for campaign-hero and section titles only; the empty-state title counts as a section title. Eyebrows use `DesignTokens.eyebrow`, set uppercase.
- **Depth:** imagery first. Layered cards use tone plus `DesignTokens.shadowCard` (`shadowLifted` for floating layers) instead of borders. Put `DesignTokens.imageScrim` / `imageScrimTop` under any copy on photos.
- **Glass:** use a real blur (`MallGlassCta`) only where it adds depth, such as hero CTAs. Never use it in repeated list items; the reel play mark is translucent without blur.
- **Motion:** restrained (`motionFast` 150ms, `motionMedium` 280ms, `motionSlow` 450ms, `motionCurve`). Whenever `MediaQuery.disableAnimations` is set, use `Duration.zero`, stop shimmer and stop hero auto-advance.
- **Text scale:** every component is tested at 320/390/768dp widths × text scale 1.0 and 1.3 with no overflow. Cards reserve fixed-height text slots, so prices align across grid rows. Prices scale down rather than truncate.
- **RTL:** use `EdgeInsetsDirectional`, `PositionedDirectional` and `AlignmentDirectional` only. Arrows mirror automatically.
- **Touch targets:** at least 44×44dp (`DesignTokens.minTouchTarget`); the tests check `iOSTapTargetGuideline`.
- **Semantics:** each card is one labelled button whose label reads brand, name, price, original price, discount and badges. Nested controls (save, follow, CTAs) stay separate nodes. Decorative imagery and skeletons are excluded; loading rails announce "Loading".
- **Constructors:** use `const` wherever inputs allow.
- **Avoid:** Bootstrap-style bordered boxes, plain white catalogue pages, oversized empty cards, borders as the main way of separating things, random colours, and template-looking UI.
