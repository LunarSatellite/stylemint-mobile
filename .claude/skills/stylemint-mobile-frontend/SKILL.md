---
name: stylemint-mobile-frontend
description: |
  Frontend skill for the Style Mint mobile app (iOS + Android) built
  with Flutter 3.41.9 + Dart 3.7 + Riverpod 2 + Feature-First Clean
  Architecture. Covers stack, full lib/ folder layout (data / domain
  / presentation per feature), three-role account model (Customer +
  Creator + Vendor in one app), auth flow (phone OTP + magic link +
  passkey + 15-min JWT + 30-day refresh in flutter_secure_storage),
  API conventions (PagedResult cursor pagination, Idempotency-Key,
  RFC 7807 errors keyed on errorCode, Money DTO, Either<Failure,T>
  via fpdart), deep linking via go_router, push notifications via
  firebase_messaging, Quiet Hours, 5 supported languages, and
  per-domain functional guides (Customer commerce, Creator
  publishing, Vendor management, Social commerce v2.0). Covers v1.1
  commerce foundation + Pillar C (Gen Z mechanics) + Pillar D
  (Creator/Brand studio) + Pillar F (Social commerce). References
  Pillars B (delivery) + E (reach) at surface depth only.
  Architecture: Feature-First Clean Architecture — domain layer is
  pure Dart with no Flutter/Dio deps; data layer implements domain
  repositories; presentation (Riverpod StateNotifier + Freezed union
  state) calls domain Repositories directly — there is NO UseCase
  layer. Dependency rule enforced strictly:
  Presentation → Domain ← Data.
  Use when scaffolding the stylemint-mobile-frontend repo, adding a
  new mobile screen, debugging an auth/OTP failure, wiring an API
  call, or producing example widgets. Read FIRST before writing any
  Dart in stylemint-mobile-frontend; then read the relevant backend
  SKILL.md (e.g. stylemint-cart-checkout, stylemint-reels) for
  module-specific endpoint details.
---

# stylemint-mobile-frontend

This skill briefs the Flutter developer building the **Style Mint
mobile app** — the customer/creator/vendor-facing iOS + Android
surface that ships against 233 Figma screens.

This is the frontend twin of ~25 backend modules, not just one. You
will not find every endpoint documented here — there are too many.
Instead this skill locks the stack, folder layout, and cross-cutting
patterns, then **points at the per-module backend SKILL.md files** in
`stylemint-backend/.claude/skills/` for endpoint specifics. Read this
file first; then read the backend skill that owns the feature you're
building.

> **Note**: this skill replaced an earlier React Native + Expo version
> in commit history. If you find any RN-style code samples (`.tsx`,
> `TanStack Query`, `expo-*` packages) in any file under this folder
> — that's stale and should be ignored / reported. The current target
> is **Flutter only**.

## 1. The product

Style Mint is a **general-purpose social commerce platform** — sells
anything (electronics, fashion, services, digital, food, etc.). Not
fashion-only.

**One human account, three optional role profiles**: Customer, Creator,
Vendor. A single user can hold all three. Each role unlocks a
different surface in the same app:

- **Customer** — browse, search, watch reels, buy, post in friend
  feed, recommend, join groups.
- **Creator** — apply (1–3 biz-day review), connect Instagram /
  TikTok / YouTube / Facebook, import reels, tag products from
  partner vendors, earn commission. Reel Studio (Pillar D) gives
  pre-publish coaching.
- **Vendor** — apply (KYC), list products, run partnership campaigns
  with creators, manage orders, withdraw earnings. Brand Studio
  (Pillar D) is the campaign authoring + intelligence surface — read
  `stylemint-brand-studio-frontend` skill for that surface
  specifically; it is the authoritative API contract for BrandStudio.

The app **never hosts video or audio** — reels are pointer records to
external platforms, audio is reference-only with deep links into
YouTube / Spotify / TikTok native apps via `url_launcher`.

## 2. Stack (locked)

| Concern | Choice | Why |
|---|---|---|
| Runtime | **Flutter 3.41.9 stable** | Single codebase iOS + Android, mature widget tree. |
| Language | **Dart 3.7+** | Sound null safety, sealed classes, pattern matching, records, exhaustive switch. |
| Architecture | **Feature-First Clean Architecture** | Presentation → Domain ← Data. Domain is pure Dart — no Flutter, no Dio. |
| Error handling | **fpdart `Either<Failure, T>`** | Explicit error paths returned by every repository method. No hidden throws across layer boundaries. |
| Routing | **go_router 15+** | Declarative, deep-link native, recommended by the Flutter team, plays nicely with Riverpod redirects. |
| State (server + client) | **riverpod 2.6+** + **riverpod_generator** | Compile-safe, codegen reduces boilerplate, async caching matches our needs. **No Provider, no BLoC, no GetX.** |
| HTTP | **dio 5.7+** + interceptors | Best interceptor ecosystem (auth, refresh, idempotency, logging). Lives in data layer only. |
| DTOs / models | **freezed** + **json_serializable** + **build_runner** | Immutable data classes, sealed unions, copyWith for free. DTOs live in `data/models/` only — domain entities are plain Dart. |
| OpenAPI codegen | **openapi_generator** (template `dart-dio-next`) | Generates dio-flavored typed clients from the backend Swagger doc. |
| Forms / validation | **flutter Form + TextFormField** + **formz** | formz models field states (pure / dirty / valid / invalid) for testable Riverpod forms. |
| Storage (secure) | **flutter_secure_storage 10+** | iOS Keychain / Android Keystore. Refresh token + passkey credentials. |
| Storage (regular) | **shared_preferences** | Last-active-role, language, cached cursor. |
| Push | **firebase_messaging** + **flutter_local_notifications** | FCM works for both iOS (via APNs bridge) + Android. Backend already publishes Expo-compatible payloads but FCM is the canonical channel. |
| Realtime | **signalr_netcore** | Dart SignalR client; works against `/hubs/notifications`. |
| Camera / media | **camera**, **image_picker**, **file_picker** | First-party Flutter plugins. KYC docs, return evidence, avatar. |
| QR / scanner | **mobile_scanner** | Drop-party invite codes, courier handoff QR (Pillar B). |
| Maps | **google_maps_flutter** | Delivery tracking (Pillar B), vendor location. (Use `flutter_map` only if you specifically need OSS tiles.) |
| URL launch | **url_launcher** | Open external apps (IG, TikTok, YouTube, Spotify). |
| i18n | **flutter_localizations** + **intl** + ARB files | 5 languages: en-US, zh, ne, es, hi. |
| Date/time | **intl** + **timezone** | Asia/Kathmandu (NPT, UTC+5:45) for ops display. |
| Logging | **logger** | Console + file; pluggable formatter. |
| Linter | **very_good_analysis 7+** | Stricter than `flutter_lints`; catches more bugs. |
| Tests (unit + widget) | **flutter_test** + **mocktail** | Built-in test runner + null-safe mocking. Notifiers: unit-test with a mocked repository; domain entities are pure Dart. |
| Tests (integration) | **patrol** | Better than `integration_test` for cross-platform e2e; native UI interaction support. |
| Crash reporting | **sentry_flutter** | Pluggable; install PII scrubber in `beforeSend`. |
| UUID | **uuid** package | For Idempotency-Key generation. |
| Analytics | NoOp by default; pluggable adapter | Privacy-first. |

Do not introduce: BLoC / Cubit / GetX / Provider (Riverpod owns
state), http (use dio), hive (use shared_preferences + secure_storage),
flutter_riverpod 1.x (must be 2.x with generator), direct Dio calls
from presentation layer (always go through Notifier → Repository).

## 3. Folder layout — Feature-First Clean Architecture

Every feature contains three layers: **data / domain / presentation**.
The dependency rule is hard: `Presentation → Domain ← Data`.
Domain is pure Dart — zero Flutter, zero Dio imports.

### 3.1 Clean Architecture layer rules

```
┌─────────────────────────────────────────────────────┐
│  PRESENTATION (Flutter + Riverpod)                  │
│  screens/, widgets/, notifiers/, shared/providers   │
│  — StateNotifier calls the Repository DIRECTLY       │
│  — state is a Freezed union                          │
│    (initial / loadInProgress / loadSuccess /         │
│     loadFailure(Failure)) consumed via when()        │
└────────────────────┬────────────────────────────────┘
                     │ depends on
                     ▼
┌─────────────────────────────────────────────────────┐
│  DOMAIN (pure Dart — no Flutter, no Dio)            │
│  entities/, repositories/ (abstract interface)      │
│  — NO usecases/ layer                                │
│  — defines Failure sealed class                     │
│  — repository returns Either<Failure, T>            │
└──────────┬──────────────────────────────────────────┘
           │ implements
           ▼
┌─────────────────────────────────────────────────────┐
│  DATA (Dio + freezed DTOs + repository impls)       │
│  datasources/, models/, repositories/               │
│  — converts API DTOs → domain Entities              │
│  — maps DioException → Failure                      │
└─────────────────────────────────────────────────────┘
```

### 3.2 Full folder tree

> **⚠️ Architecture note (read before trusting the tree below):** there is
> **NO `domain/usecases/` layer**. Presentation `StateNotifier`s call the
> repository directly, and per-feature DI lives in `shared/providers.dart`.
> Some feature subtrees below still show a `usecases/` folder and a
> `presentation/providers/` file — that is **obsolete**; ignore it. The
> canonical, current layout is the **auth** and **customer/reels** subtrees
> (`presentation/notifiers/` + `shared/providers.dart`, no `usecases/`).

```
stylemint-mobile-frontend/
├── lib/
│   ├── main.dart                        # entry — WidgetsFlutterBinding + Firebase + Sentry + runApp
│   ├── app.dart                         # MaterialApp.router + ProviderScope + theme + l10n
│   │
│   ├── core/                            # Zero Flutter deps where possible
│   │   ├── error/
│   │   │   ├── failure.dart             # sealed class Failure { network, auth, validation, server, unknown }
│   │   │   └── exceptions.dart          # raw exceptions thrown before mapping to Failure
│   │   ├── network/
│   │   │   ├── dio_client.dart          # Dio instance — lives in core; injected into data datasources
│   │   │   ├── auth_interceptor.dart    # attach Bearer token
│   │   │   ├── refresh_interceptor.dart # 401 → refresh → retry once
│   │   │   ├── idempotency_interceptor.dart  # attach Idempotency-Key to mutations
│   │   │   └── logging_interceptor.dart # PII-safe request/response logging
│   │   └── utils/
│   │       ├── format_money.dart        # "Rs 1,234.56"
│   │       ├── format_date.dart         # NPT for ops, locale-aware for users
│   │       ├── quiet_hours.dart
│   │       └── pii_redactor.dart        # mask phone/email before logs/Sentry
│   │
│   ├── shared/                          # Cross-feature reusables
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── money.dart           # Money { amount, currency } — pure Dart
│   │   │   │   ├── address.dart
│   │   │   │   ├── pagination.dart      # PagedResult<T>, PagedList<T>
│   │   │   │   └── role.dart            # enum Role { customer, creator, vendor }
│   │   │   └── failures/
│   │   │       └── common_failures.dart # NetworkFailure, AuthFailure, etc.
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── money_dto.freezed.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── paged_list.dart      # generic infinite scroll widget
│   │           ├── product_card.dart
│   │           ├── money_text.dart
│   │           ├── error_view.dart
│   │           ├── empty_state.dart
│   │           └── tagged_product_chip.dart
│   │
│   ├── api/
│   │   └── schema.dart                  # GENERATED — openapi_generator output (dart-dio-next)
│   │
│   ├── routes/
│   │   ├── app_router.dart              # GoRouter root + redirects per active role
│   │   ├── route_names.dart             # constants — never hardcode path strings
│   │   └── deep_links.dart              # stylemint:// + universal links
│   │
│   ├── theme/
│   │   ├── app_theme.dart               # ThemeData light + dark
│   │   ├── colors.dart                  # design tokens shared with admin web
│   │   └── typography.dart
│   │
│   ├── l10n/
│   │   ├── app_en.arb                   # source of truth
│   │   ├── app_zh.arb
│   │   ├── app_ne.arb
│   │   ├── app_es.arb
│   │   └── app_hi.arb
│   │
│   ├── services/                        # App-wide singleton services (Riverpod keepAlive)
│   │   ├── signalr_service.dart         # /hubs/notifications — best-effort realtime
│   │   ├── push_service.dart            # FCM registration + onMessageOpenedApp handler
│   │   └── analytics_service.dart       # NoOp adapter by default
│   │
│   └── features/
│       │
│       ├── auth/                        # ── AUTH ──────────────────────────────────────
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── auth_remote_datasource.dart      # raw Dio; throws AuthException
│       │   │   ├── models/
│       │   │   │   ├── auth_response_dto.freezed.dart   # JSON ↔ DTO
│       │   │   │   └── token_dto.freezed.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart        # implements AuthRepository
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── auth_state.dart                  # pure Dart, no JSON
│       │   │   │   └── account.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository.dart             # abstract interface — NO usecases/
│       │   ├── presentation/
│       │   │   ├── notifiers/                           # StateNotifier + Freezed union state
│       │   │   │   └── auth_state_provider.dart         # Otp{Request,Verification}Notifier → AuthRepository
│       │   │   ├── screens/
│       │   │   │   ├── login_screen.dart
│       │   │   │   ├── otp_screen.dart                  # 5-digit input; no 6-digit ever
│       │   │   │   ├── magic_link_screen.dart
│       │   │   │   └── role_picker_screen.dart
│       │   │   └── widgets/
│       │   │       ├── otp_input.dart
│       │   │       └── social_login_buttons.dart
│       │   └── shared/
│       │       └── providers.dart                       # DI: datasource → repository → StateNotifierProviders
│       │
│       ├── customer/                    # ── CUSTOMER ──────────────────────────────────
│       │   │
│       │   ├── onboarding/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── onboarding_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   └── interest_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── onboarding_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   └── interest.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── onboarding_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── get_interests.dart           # Either<Failure, List<Interest>>
│       │   │   │       └── save_interests.dart          # min 3 required — rule lives here
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── onboarding_provider.dart
│       │   │       ├── screens/
│       │   │       │   └── pick_interests_screen.dart
│       │   │       └── widgets/
│       │   │           └── interest_chip.dart
│       │   │
│       │   ├── discovery/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── discovery_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   ├── product_summary_dto.freezed.dart
│       │   │   │   │   └── search_result_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── discovery_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── product_summary.dart
│       │   │   │   │   └── search_result.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── discovery_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── search_products.dart
│       │   │   │       ├── get_trending.dart
│       │   │   │       └── get_feed.dart
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   ├── search_provider.dart
│       │   │       │   └── feed_provider.dart
│       │   │       ├── screens/
│       │   │       │   ├── home_screen.dart
│       │   │       │   └── search_screen.dart
│       │   │       └── widgets/
│       │   │           └── trending_chip.dart
│       │   │
│       │   ├── reels/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── reels_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   └── reel_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── reels_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   └── reel.dart                   # pointer only — no media bytes ever
│       │   │   │   ├── repositories/
│       │   │   │   │   └── reels_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── get_reels_feed.dart
│       │   │   │       ├── get_reel_detail.dart
│       │   │   │       ├── like_reel.dart
│       │   │   │       ├── comment_reel.dart
│       │   │   │       └── open_reel_external.dart      # url_launcher call lives here
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── reels_provider.dart
│       │   │       ├── screens/
│       │   │       │   ├── reels_feed_screen.dart
│       │   │       │   └── reel_detail_screen.dart
│       │   │       └── widgets/
│       │   │           ├── reel_card.dart
│       │   │           └── reel_player.dart             # tap → url_launcher; never embed
│       │   │
│       │   ├── cart/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── cart_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   └── cart_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── cart_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── cart.dart
│       │   │   │   │   └── cart_item.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── cart_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── get_cart.dart
│       │   │   │       ├── add_to_cart.dart             # idempotency key generated here
│       │   │   │       ├── update_cart_item.dart
│       │   │   │       └── remove_from_cart.dart
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── cart_provider.dart
│       │   │       ├── screens/
│       │   │       │   └── cart_screen.dart
│       │   │       └── widgets/
│       │   │           └── cart_item_tile.dart
│       │   │
│       │   ├── checkout/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── checkout_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   └── checkout_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── checkout_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── checkout_summary.dart
│       │   │   │   │   └── payment_method.dart         # sealed: card | paypal | esewa | cod
│       │   │   │   ├── repositories/
│       │   │   │   │   └── checkout_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── get_checkout_summary.dart
│       │   │   │       ├── select_payment_method.dart
│       │   │   │       ├── place_order.dart
│       │   │   │       └── initiate_payment.dart        # returns redirect URL for browser
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── checkout_provider.dart
│       │   │       ├── screens/
│       │   │       │   ├── checkout_screen.dart
│       │   │       │   ├── payment_method_screen.dart
│       │   │       │   └── payment_webview_screen.dart  # in-app browser (card/paypal/esewa)
│       │   │       └── widgets/
│       │   │           └── order_summary_tile.dart
│       │   │
│       │   ├── orders/
│       │   │   ├── data/
│       │   │   │   ├── datasources/
│       │   │   │   │   └── orders_remote_datasource.dart
│       │   │   │   ├── models/
│       │   │   │   │   └── order_dto.freezed.dart
│       │   │   │   └── repositories/
│       │   │   │       └── orders_repository_impl.dart
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── order.dart                  # number format: NK{year}-{5 digits}
│       │   │   │   │   └── sub_order.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   └── orders_repository.dart
│       │   │   │   └── usecases/
│       │   │   │       ├── get_orders.dart
│       │   │   │       ├── get_order_detail.dart
│       │   │   │       ├── track_delivery.dart
│       │   │   │       └── request_return.dart
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── orders_provider.dart
│       │   │       ├── screens/
│       │   │       │   ├── orders_list_screen.dart
│       │   │       │   ├── order_detail_screen.dart
│       │   │       │   └── return_screen.dart
│       │   │       └── widgets/
│       │   │           └── order_status_badge.dart
│       │   │
│       │   └── reviews/
│       │       ├── data/ ...
│       │       ├── domain/
│       │       │   └── usecases/
│       │       │       ├── get_product_reviews.dart
│       │       │       └── submit_review.dart
│       │       └── presentation/ ...
│       │
│       ├── creator/                     # ── CREATOR ───────────────────────────────────
│       │   │
│       │   ├── apply/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── submit_creator_application.dart
│       │   │   │       └── get_application_status.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── creator_apply_screen.dart
│       │   │
│       │   ├── social_connect/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── connect_instagram.dart
│       │   │   │       ├── connect_tiktok.dart
│       │   │   │       ├── connect_youtube.dart
│       │   │   │       └── connect_facebook.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── social_connect_screen.dart
│       │   │
│       │   ├── reel_import/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── import_reel.dart
│       │   │   │       └── tag_product_on_reel.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           ├── import_reel_screen.dart
│       │   │           └── tag_products_screen.dart
│       │   │
│       │   ├── partnerships/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── get_partnership_invites.dart
│       │   │   │       ├── accept_partnership.dart
│       │   │   │       └── decline_partnership.dart
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── reel_studio/             # Pillar D — creator coaching before publish
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── get_coaching_feedback.dart
│       │   │   │       └── get_reel_recipe.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── reel_studio_screen.dart
│       │   │
│       │   ├── reach/                   # Pillar E — cross-platform publish + paid boost
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── publish_cross_platform.dart
│       │   │   │       └── boost_reel.dart
│       │   │   └── presentation/ ...
│       │   │
│       │   └── earnings/
│       │       ├── data/ ...
│       │       ├── domain/
│       │       │   └── usecases/
│       │       │       ├── get_earnings_ledger.dart
│       │       │       └── request_payout.dart          # NIMB/Laxmi/PayPal/eSewa
│       │       └── presentation/
│       │           └── screens/
│       │               ├── earnings_screen.dart
│       │               └── payout_screen.dart
│       │
│       ├── vendor/                      # ── VENDOR ────────────────────────────────────
│       │   │
│       │   ├── apply/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── submit_vendor_application.dart
│       │   │   │       └── upload_kyc_document.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── vendor_apply_screen.dart
│       │   │
│       │   ├── dashboard/
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── vendor_dashboard_screen.dart
│       │   │
│       │   ├── add_product/             # 5-step wizard
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── create_product_draft.dart
│       │   │   │       ├── upload_product_images.dart
│       │   │   │       ├── set_product_pricing.dart     # Money validated here
│       │   │   │       ├── set_product_shipping.dart
│       │   │   │       └── publish_product.dart
│       │   │   └── presentation/
│       │   │       ├── providers/
│       │   │       │   └── add_product_provider.dart    # wizard step state machine
│       │   │       └── screens/
│       │   │           ├── step1_basic_info_screen.dart
│       │   │           ├── step2_images_screen.dart
│       │   │           ├── step3_pricing_screen.dart
│       │   │           ├── step4_shipping_screen.dart
│       │   │           └── step5_review_screen.dart
│       │   │
│       │   ├── products/
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── partnerships/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── create_campaign_brief.dart
│       │   │   │       └── invite_creator.dart
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── brand_studio/            # Pillar D — defers to stylemint-brand-studio-frontend
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── brand_studio_screen.dart
│       │   │
│       │   ├── matchmaking/             # Pillar E
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── orders/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── get_vendor_orders.dart
│       │   │   │       ├── fulfill_order.dart
│       │   │   │       └── handle_return.dart
│       │   │   └── presentation/ ...
│       │   │
│       │   └── earnings/
│       │       ├── data/ ...
│       │       ├── domain/ ...
│       │       └── presentation/ ...
│       │
│       ├── social/                      # ── SOCIAL (Pillars C + F) ────────────────────
│       │   │
│       │   ├── feed/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── get_friend_feed.dart
│       │   │   │       ├── post_to_feed.dart
│       │   │   │       └── react_to_post.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           └── friend_feed_screen.dart
│       │   │
│       │   ├── stories/
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── recommendations/         # Pillar F — "ask friends what to buy"
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── create_recommendation_request.dart
│       │   │   │       ├── get_recommendation_thread.dart
│       │   │   │       └── reply_to_recommendation.dart
│       │   │   └── presentation/
│       │   │       └── screens/
│       │   │           ├── recommendation_list_screen.dart
│       │   │           └── recommendation_thread_screen.dart
│       │   │
│       │   ├── groups/                  # Pillar F
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── friends/
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── get_friends.dart
│       │   │   │       ├── send_friend_request.dart
│       │   │   │       └── import_contacts.dart
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── drop_party/              # Pillar C
│       │   │   ├── data/ ...
│       │   │   ├── domain/
│       │   │   │   └── usecases/
│       │   │   │       ├── create_drop_party.dart
│       │   │   │       ├── join_drop_party.dart
│       │   │   │       └── scan_invite_qr.dart          # mobile_scanner
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── group_cart/              # Pillar C
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   ├── co_watch/                # Pillar C
│       │   │   ├── data/ ...
│       │   │   ├── domain/ ...
│       │   │   └── presentation/ ...
│       │   │
│       │   └── tips/                    # Pillar C
│       │       ├── data/ ...
│       │       ├── domain/ ...
│       │       └── presentation/ ...
│       │
│       ├── settings/
│       │   ├── data/ ...
│       │   ├── domain/
│       │   │   └── usecases/
│       │   │       ├── get_notification_preferences.dart
│       │   │       ├── update_notification_preferences.dart
│       │   │       ├── change_language.dart
│       │   │       └── delete_account.dart              # Apple App Store required
│       │   └── presentation/
│       │       └── screens/
│       │           ├── settings_screen.dart
│       │           └── notification_prefs_screen.dart
│       │
│       └── support/
│           ├── data/ ...
│           ├── domain/
│           │   └── usecases/
│           │       ├── create_ticket.dart               # ticket: #ST{6 digits}
│           │       └── get_tickets.dart
│           └── presentation/
│               └── screens/
│                   ├── help_center_screen.dart
│                   └── ticket_screen.dart
│
├── test/
│   ├── features/
│   │   ├── auth/
│   │   │   └── domain/
│   │   │       └── usecases/                            # pure Dart — no mocks needed for domain
│   │   │           ├── verify_otp_test.dart
│   │   │           └── switch_role_test.dart
│   │   └── customer/
│   │       └── cart/
│   │           └── domain/
│   │               └── usecases/
│   │                   └── add_to_cart_test.dart
│   └── shared/
│       └── domain/
│           └── entities/
│               └── money_test.dart
├── integration_test/                                    # patrol e2e
│   └── auth_flow_test.dart
├── ios/                                                 # Xcode 26 project
├── android/                                             # Gradle project (SDK 36)
├── assets/
│   ├── images/
│   └── fonts/
├── pubspec.yaml
├── analysis_options.yaml                                # very_good_analysis 7+
├── l10n.yaml
├── build.yaml
└── README.md
```

### 3.3 Canonical file template — StateNotifier + Freezed union state

There is **no UseCase layer**. A presentation `StateNotifier` holds a Freezed
union state and calls the repository directly.

```dart
// lib/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart
import 'dart:async';

import 'package:flutter_riverpod/legacy.dart'; // StateNotifier (Riverpod 3 legacy)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

part 'reels_feed_notifier.freezed.dart';

/// State = Freezed union. Declare it `abstract` (NOT `sealed`) so Freezed
/// generates when()/maybeWhen()/map() for the UI to consume.
@freezed
abstract class ReelsFeedState with _$ReelsFeedState {
  const ReelsFeedState._();

  const factory ReelsFeedState.initial() = _Initial;
  const factory ReelsFeedState.loadInProgress() = _LoadInProgress;
  const factory ReelsFeedState.loadSuccess(List<Reel> reels) = _LoadSuccess;
  const factory ReelsFeedState.loadFailure(Failure failure) = _LoadFailure;
}

/// Notifier talks to the repository DIRECTLY — no UseCase, no Params class.
class ReelsFeedNotifier extends StateNotifier<ReelsFeedState> {
  ReelsFeedNotifier(this._repository)
      : super(const ReelsFeedState.initial()) {
    unawaited(fetchFeed());
  }

  final ReelsRepository _repository;

  Future<void> fetchFeed({int limit = 20, String? cursor}) async {
    state = const ReelsFeedState.loadInProgress();
    final either = await _repository.getReelsFeed(limit: limit, cursor: cursor);
    state = either.fold(
      ReelsFeedState.loadFailure,   // (Failure) → loadFailure
      ReelsFeedState.loadSuccess,   // (List<Reel>) → loadSuccess
    );
  }
}
```

UI consumes the union with `when` (see §3.6).

### 3.4 Canonical file template — Repository impl

```dart
// lib/features/customer/cart/data/repositories/cart_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../../core/error/failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';
import '../models/cart_dto.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this._datasource);
  final CartRemoteDatasource _datasource;

  @override
  Future<Either<Failure, Cart>> addItem({
    required String productId,
    required int qty,
    required String idempotencyKey,
  }) async {
    try {
      final dto = await _datasource.addItem(productId, qty, idempotencyKey);
      return right(dto.toDomain());       // DTO → Entity conversion
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  Failure _mapError(DioException e) {
    final status = e.response?.statusCode;
    final code = e.response?.data?['errorCode'] as String?;
    if (status == 401) return const AuthFailure();
    if (status == 409 && code == 'concurrency.conflict') return const ConflictFailure();
    if (status != null && status >= 500) return const ServerFailure();
    return const NetworkFailure();
  }
}
```

### 3.5 Canonical file template — feature DI (`shared/providers.dart`)

All wiring for a feature lives in one `shared/providers.dart`: datasource →
repository → `StateNotifierProvider`(s). Manual providers (no `@riverpod`
codegen for the feature layer).

```dart
// lib/features/customer/reels/shared/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateNotifierProvider
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/repositories/reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5020',
);

final reelsRemoteDataSourceProvider = Provider<ReelsRemoteDataSource>(
  (ref) => ReelsRemoteDataSource(
    apiClient: ApiClient(baseUrl: _baseUrl, dio: ref.watch(dioClientProvider)),
  ),
);

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => ReelsRepositoryImpl(
    remoteDataSource: ref.watch(reelsRemoteDataSourceProvider),
  ),
);

/// The screen watches this. Notifier → repository directly (no UseCase).
final reelsFeedNotifierProvider =
    StateNotifierProvider<ReelsFeedNotifier, ReelsFeedState>(
  (ref) => ReelsFeedNotifier(ref.watch(reelsRepositoryProvider)),
);
```

### 3.6 Canonical file template — screen consuming the union

```dart
// lib/features/customer/reels/presentation/screens/reels_feed_screen.dart
class ReelsFeedScreen extends ConsumerWidget {
  const ReelsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reelsFeedNotifierProvider);
    return Scaffold(
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (reels) => /* list / PageView */ ...,
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load reels.',
          onRetry: () =>
              ref.read(reelsFeedNotifierProvider.notifier).fetchFeed(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
```

### 3.7 Freezed 3 conventions (DTOs, models, union state)

We are on **freezed `^3.2.3`** + **freezed_annotation `^3.1.0`** +
**json_serializable `^6.8.0`**. Freezed 3 changed the class syntax — get it
right or codegen silently does the wrong thing.

**The rules that bite (memorize):**

1. **Always declare the class `abstract` (or `sealed`).** Freezed 3 requires
   the `abstract`/`sealed` keyword on the class — `@freezed class X` (the
   Freezed-2 style) **does not work**.
2. **Use `abstract`, NOT `sealed`, for state unions** if you want
   `when`/`map`/`maybeWhen`. With `abstract`, Freezed generates those as an
   `extension … on X`. With `sealed`, it only generates the subclasses and
   you must use a native Dart `switch` instead. We standardize on
   **`abstract` + `.when()`**.
3. **Add a private constructor `const X._();`** whenever the class has any
   method or getter you wrote by hand (e.g. a DTO's `toDomain()`). Without
   it the generated code won't compile.
4. **`part` directives:** every freezed file needs `part 'x.freezed.dart';`.
   Add `part 'x.g.dart';` **only** when the class also does JSON
   (`fromJson`/`toJson`).

**DTO with JSON (data layer — `data/models/`):**

```dart
// lib/features/customer/reels/data/models/reel_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

part 'reel_dto.freezed.dart';
part 'reel_dto.g.dart';            // because we have fromJson

@freezed
abstract class ReelDto with _$ReelDto {        // <-- `abstract` is mandatory
  const factory ReelDto({
    required String id,
    required String caption,
    required DateTime createdAt,             // required params come first
    @Default('') String musicTitle,          // @Default for optional fields
    @JsonKey(name: 'is_liked') bool? isLiked, // @JsonKey to map server names
  }) = _ReelDto;

  const ReelDto._();                          // <-- needed for toDomain()

  factory ReelDto.fromJson(Map<String, dynamic> json) =>
      _$ReelDtoFromJson(json);

  /// DTO → pure-Dart domain entity (mapping lives here, in the data layer).
  Reel toDomain() => Reel(id: id, caption: caption, createdAt: createdAt /*…*/);
}
```

**Union / state (presentation — see §3.3):** same `@freezed abstract class`
shape, multiple `const factory` redirects, a `const X._();`, and **no**
`part '*.g.dart'` (no JSON).

**Domain entities are NOT freezed.** `domain/entities/` are hand-written
plain Dart classes (own constructor + `copyWith`) — no `@freezed`, no
`fromJson`, no JSON annotations. JSON belongs to DTOs only.

**`@JsonKey` warning:** json_serializable emits
`invalid_annotation_target` when `@JsonKey` sits on a factory parameter
(harmless — codegen still works). To silence it repo-wide, add to
`analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

**Run codegen:** `dart run build_runner build`. In this repo's build_runner
the `--delete-conflicting-outputs` flag has been **removed** (it's ignored
with a warning) — don't pass it; the build overwrites outputs anyway. Use
`dart run build_runner watch` while iterating.

### 3.8 Side-effects (navigate / snackbar) — use `ref.listen`, never await-then-read

One-shot side-effects (navigation, snackbars, dialogs) **react to a state
transition** via `ref.listen` inside `build`. The button/action handler only
**validates + fires** the notifier — it does **not** await and then read the
state back.

**❌ Don't** (fragile — couples the handler to one call, ignores any other
source of the state change, and races with `mounted`):

```dart
Future<void> _handleSubmit() async {
  await ref.read(otpRequestProvider.notifier).requestOtp(/*…*/);
  if (!mounted) return;
  final s = ref.read(otpRequestProvider);     // <-- imperative read-after-await
  s.maybeWhen(loadSuccess: (otp) => context.push(...), orElse: () {});
}
```

**✅ Do** — handler just fires; a `ref.listen` pattern-matches the union and
reacts to the outcome:

```dart
@override
Widget build(BuildContext context) {
  // Fires only when the state CHANGES → runs once per outcome, never on a
  // plain rebuild. Place it at the top of build(), unconditionally.
  ref.listen<OtpRequestState>(otpRequestProvider, (previous, next) {
    next.maybeWhen(
      loadSuccess: (otp) => context.push(RouteNames.otp, extra: {
        'phone': _submittedPhone,           // stash inputs you need on a field
        'otpId': otp.otpId,
      }),
      loadFailure: (_) =>
          SmSnackbar.error(context, 'Failed to send OTP. Please try again'),
      orElse: () {},
    );
  });
  // …
}

Future<void> _handleSubmit() async {
  // validate, stash inputs, then fire — NO read-after-await here
  _submittedPhone = _phoneFieldKey.currentState?.getFullPhoneNumber() ?? '';
  await ref.read(otpRequestProvider.notifier)
      .requestOtp(identifierType: 'phone', identifier: _submittedPhone);
}
```

Notes:
- `ref.listen` lives in `build` (it's a no-op until the state changes); never
  call it inside a callback or conditionally.
- `ref.watch` is still used for **rendering** (e.g. `isLoading`, the union
  itself); `ref.listen` is only for **side-effects**.
- Stash any handler-local input the listener needs (e.g. the phone number) on
  a `State` field, since the listener only receives `(previous, next)` state.

## 4. Account + role model

Critical: the mobile app must understand the three-tier identity
shape that backend `stylemint-identity` enforces.

```
┌─ Account ───────────────────────────────────────────────┐
│  - one row per human                                    │
│  - has 0..N AuthCredentials (password, passkey, OTP-only)│
│  - has 1..3 RoleProfiles                                 │
│  - has 0..N Sessions                                     │
└─────────────────────────────────────────────────────────┘
        │
        │ has 1..3
        ▼
┌─ RoleProfile (Customer | Creator | Vendor) ─────────────┐
│  - one row per (account, role)                          │
│  - state: Requested → Approved → Active                 │
│  - role-specific data lives on its own table            │
│    (creator: handle, content categories;                │
│     vendor: business name, KYC docs)                    │
└─────────────────────────────────────────────────────────┘
```

The JWT carries the **active** role in its `active_role` claim and
the full set of approved roles in `roles`. The mobile app can switch
active role with no re-login by calling
`POST /v1/accounts/{accountId}/roles/{role}/activate` and refreshing
the token. The Riverpod auth provider keeps `activeRole` and the
GoRouter redirect picks the right tab tree based on it (different
tabs visible per role).

```dart
// lib/auth/auth_state.dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    String? accessToken,
    String? refreshToken,         // also persisted to flutter_secure_storage
    AccountInfo? account,
    @Default([]) List<Role> roles,
    Role? activeRole,
  }) = _AuthState;

  factory AuthState.fromJson(Map<String, dynamic> json) =>
      _$AuthStateFromJson(json);
}

enum Role { customer, creator, vendor }
```

## 5. Auth (read `AUTH_FLOW.md` for the full sequence)

Four entry paths:

1. **Password** — `POST /v1/auth/login { emailOrPhone, password }`
2. **Phone OTP** — `POST /v1/auth/login-otp/request { phoneE164 }` → SMS with **5-digit** code → `POST /v1/auth/login-otp/verify { otpId, code }` (the 5-digit format is locked per `DESIGN_VERIFIED_CORRECTIONS.md`)
3. **Email magic link** — `POST /v1/auth/login-magic/request { email }` → email with deep link `stylemint://auth/magic?token=...` → consumed by the app, redeemed via `POST /v1/auth/login-magic/verify { tokenId, token }`
4. **Passkey** — platform authenticator via `local_auth` + a custom WebAuthn dance against `/v1/passkeys/{begin,finish}`. Defer behind v1.1 if needed.

All paths return:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresAtUtc": "2026-05-26T12:42:31Z",
  "account": { "id": "...", "email": "...", "displayName": "...", "locale": "en-US" },
  "roles": ["Customer"],
  "activeRole": "Customer"
}
```

**Store `refreshToken` in flutter_secure_storage. Keep `accessToken`
in Riverpod state only (in-memory).** On 401 (`auth.token_expired`),
the Dio interceptor silently calls `/v1/auth/refresh`, swaps the
access token, and retries the original request once. If refresh
fails, force re-login.

**Social login** (Google / Apple / Facebook) supported via
`/v1/oauth/*` endpoints — see `stylemint-identity` SKILL.md §9.

## 6. Cross-cutting conventions (read `API_CONVENTIONS.md` for the full spec)

| Concern | Pattern |
|---|---|
| Base URL | `https://api.stylemint.app` (prod), `http://localhost:5020` (dev). Set via `--dart-define=API_BASE_URL=...` at build time. |
| API version | URL segment: `/v1/...`. v2 ships alongside v1 — never break v1 once a mobile build is in the field. |
| Auth header | `Authorization: Bearer <accessToken>` on every request except auth endpoints. |
| Idempotency | Every mutation includes `Idempotency-Key: <uuid v4>`. Generate per-tap, NOT per-retry. |
| Errors | RFC 7807 Problem Details with `errorCode`. App keys on `errorCode`, maps to i18n message keys. |
| Pagination | **Cursor-based `PagedResult<T>`** for feeds (reels, friend feed, products, briefs), page-based `PagedList<T>` for admin-style lists. The shape comes from the backend; codegen produces matching Dart types. |
| Money | All amounts are `{ amount: double, currency: "NPR" }`. Never bare numbers. |
| Time | All API timestamps UTC ISO 8601. **Display in user's locale timezone** (auto-detected). Quiet Hours enforced server-side in `Asia/Kathmandu`. |
| Mobile-first | Backend pre-denormalizes — a screen should be one round-trip. If you need 3 GETs to render one screen, the backend has the wrong DTO shape — flag to backend team. |
| Concurrency | `rowVersion` opaque. On 409 `concurrency.conflict`, refetch and prompt user. |
| Multi-vendor team | `X-Vendor-Account-Id: <guid>` header on vendor endpoints when caller is on multiple vendor teams. |

## 7. The four payment methods (locked, do not add)

Per `DESIGN_VERIFIED_CORRECTIONS.md` in the backend repo, v1.1
supports **exactly four payment methods**:

1. **Visa / Mastercard** (PSP-agnostic card adapter with 3DS, in-app browser via `flutter_web_browser`)
2. **PayPal** (Orders v2 redirect, in-app browser)
3. **eSewa** (Epay v2 redirect + server verification, in-app browser)
4. **Cash on Delivery** (no redirect)

**No Stripe, no Khalti, no Razorpay, no Apple Pay, no Google Pay** in
v1. If a Figma screen disagrees, the spec wins. The Payment Method
selector at checkout shows these four; UI per provider is in
`stylemint-payments` SKILL.md.

**Four payout destinations** (creator/vendor withdrawal): NIMB Bank,
Laxmi Bank, PayPal, eSewa. Two modes: Automatic Weekly (free, Friday
batch) and On-Demand (2% fee, Rs 10,000–70,000 bounds, 3-day pending).

## 8. Spec-locked formats (memorize)

| Format | Example | Source |
|---|---|---|
| OTP | `12345` (5 digits, NOT 6) | `DESIGN_VERIFIED_CORRECTIONS.md` |
| Order number | `NK2024-89126` (`NK{year}-{5 digits}`) | same |
| Delivery tracking | `SM-D-12345678` (`SM-D-{8 digits}`) | same |
| Support ticket | `#ST123456` (`#ST{6 digits}`) | same |
| Currency | `NPR` (`Rs` prefix in UI) | platform default |
| Phone | E.164: `+9779812345678` | backend canonical |
| Timezone for ops | `Asia/Kathmandu` (`NPT`, UTC+5:45) | platform default |
| Quiet Hours default | 22:00–08:00 NPT | `stylemint-support` SKILL.md |
| Languages | en-US, zh, ne, es, hi | spec |

## 9. Deep linking

Custom scheme: `stylemint://`. Universal links also handled via
Apple App Site Association (`apple-app-site-association`) +
Android `assetlinks.json`.

Routes:

| URL pattern | Target |
|---|---|
| `stylemint://auth/magic?token=...&tokenId=...` | Magic-link consumer |
| `stylemint://reel/{reelId}` | Reel detail |
| `stylemint://product/{productId}` | Product detail |
| `stylemint://order/{orderId}` | Order tracking |
| `stylemint://drop/{dropPartyId}` | Drop Party invite (Pillar C) |
| `stylemint://group-cart/{groupCartId}` | Group cart invite (Pillar C) |
| `stylemint://friend/{accountId}` | Friend profile (Pillar F) |
| `stylemint://reco/{requestId}` | Recommendation request (Pillar F) |

Wire via `go_router`'s `redirect` + URI parsing. The magic-link
consumer is the only one needing custom logic (parse token, verify
with backend, redirect to home on success).

Reels and audio deep-link OUT to Instagram / TikTok / YouTube /
Facebook / Spotify via `url_launcher`. Never embed a player.

## 10. Push notifications

Backend uses **FCM** for Android, **APNs** (via FCM) for iOS:

- Configure both platforms via the `firebase_messaging` plugin per
  the Flutter Fire docs.
- Register device token via `POST /v1/devices` (see
  `stylemint-identity` §5).
- Notification preferences live on
  `GET/PUT /v1/notification-preferences` (8 categories, ~20 toggles
  — see `stylemint-support` SKILL.md §6).
- Quiet Hours are enforced **server-side** — the backend batches push
  during 22:00–08:00 NPT. The mobile app does NOT also suppress;
  trust the backend.
- Deep link via the `data` payload's `url` field — handle in
  `FirebaseMessaging.onMessageOpenedApp` and route via go_router.

`flutter_local_notifications` handles foreground display (FCM
foreground messages don't auto-render a system notification on iOS).

## 11. Realtime (SignalR)

`/hubs/notifications` is the in-app realtime channel. Two events:

```dart
hub.on('notification', (args) {
  final msg = args![0] as Map;
  // refresh inbox; show toast if app is foreground
});
hub.on('unread-count-changed', (args) {
  final unread = args![0]['unreadCount'] as int;
  // update badge
});
```

Token passes via query string per the backend's JWT bearer event
handler (browser/native WebSocket can't set custom headers):

```dart
final hub = HubConnectionBuilder()
  .withUrl('${baseUrl}/hubs/notifications?access_token=$token')
  .withAutomaticReconnect()
  .build();
await hub.start();
```

This is **best-effort** — the durable read surface is
`GET /v1/notifications/inbox`. Offline users miss the realtime push
but pick up the same dispatch row when they next call the inbox.

## 12. The 31 backend modules — where to read for module specifics

| Domain | Backend skill to read | Mobile flow doc |
|---|---|---|
| Auth, accounts, roles, sessions, KYC, addresses, payment methods | `stylemint-identity` | `AUTH_FLOW.md` |
| Onboarding (Pick Interests, Creator/Vendor apply) | `stylemint-onboarding` | `CUSTOMER_FLOWS.md`, `CREATOR_FLOWS.md`, `VENDOR_FLOWS.md` |
| Products, brands, categories, reviews | `stylemint-catalog` | `CUSTOMER_FLOWS.md`, `VENDOR_FLOWS.md` |
| Imported reels, tagged products, reel comments | `stylemint-reels` | `CUSTOMER_FLOWS.md`, `CREATOR_FLOWS.md` |
| Search, trending, feed read API | `stylemint-discovery` | `CUSTOMER_FLOWS.md` |
| Connect IG/TikTok/YouTube/FB, reel import | `stylemint-social` | `CREATOR_FLOWS.md` |
| Partnership invites, terms, commission ranges | `stylemint-partnerships` | `CREATOR_FLOWS.md`, `VENDOR_FLOWS.md` |
| Cart, checkout saga, shipping | `stylemint-cart-checkout` | `CUSTOMER_FLOWS.md` |
| Orders, sub-orders, returns, fulfillment | `stylemint-orders` | `CUSTOMER_FLOWS.md`, `VENDOR_FLOWS.md` |
| Payment intent lifecycle (4 methods) | `stylemint-payments` | `CUSTOMER_FLOWS.md` |
| Earnings ledger, payouts, NIMB/Laxmi/PayPal/eSewa | `stylemint-payouts` | `CREATOR_FLOWS.md`, `VENDOR_FLOWS.md` |
| Tickets, Help Center, prefs, languages | `stylemint-support` | (settings + support stack) |
| Push/email/in-app/SignalR | `stylemint-messaging` | §10 + §11 above |
| Group Carts, Style Circles, Co-Watch, Drop Parties, Tips, Stitched Reels | `stylemint-social-graph` | `SOCIAL_FLOWS.md` |
| Multi-facet reputation | `stylemint-reputation` | `SOCIAL_FLOWS.md` |
| Reel Studio (creator coaching) | `stylemint-creator-studio` | `CREATOR_FLOWS.md` |
| Brand Brief Builder, Brand Intelligence | `stylemint-brand-studio-frontend` (API contract — read first) + `stylemint-brand-studio` (strategy) | `VENDOR_FLOWS.md` §7 |
| Audio reference catalog (no hosting) | `stylemint-audio` | `CREATOR_FLOWS.md` |
| Pre-production reel recipes | `stylemint-reel-recipes` | `CREATOR_FLOWS.md` |
| Cross-platform publish + paid boost | `stylemint-reach` | `CREATOR_FLOWS.md` |
| Brand↔creator matchmaking | `stylemint-matchmaking` | `CREATOR_FLOWS.md`, `VENDOR_FLOWS.md` |
| Friend feed, stories, comments, reactions | `stylemint-social-feed` | `SOCIAL_FLOWS.md` |
| Recommendation threads ("ask friends what to buy") | `stylemint-recommendations` | `SOCIAL_FLOWS.md` |
| Mutual friendships, contacts import | `stylemint-networking` | `SOCIAL_FLOWS.md` |
| Groups, professional circles | `stylemint-community` | `SOCIAL_FLOWS.md` |
| Package, tracking, Story Mode | `stylemint-delivery` | (customer-facing tracking only) |

## 13. Hard invariants — do not violate

**Clean Architecture:**
- **Dependency rule is absolute.** Presentation → Domain ← Data.
  Domain never imports from data or presentation. Presentation never
  imports from data (no direct Dio calls from a provider or widget).
- **Domain is pure Dart.** No `import 'package:flutter/...';`, no
  `import 'package:dio/...';` in any `domain/` file.
- **No UseCase layer — ever.** Do NOT create `domain/usecases/` or a
  `core/usecase/` base. A presentation `StateNotifier` calls the
  repository **directly**. (This replaced an earlier UseCase-based
  design; if you see a `usecases/` folder, it is legacy — delete it.)
- **Presentation state is a Freezed union** (`initial` /
  `loadInProgress` / `loadSuccess(data)` / `loadFailure(Failure)`),
  declared `abstract` (not `sealed`) so `when`/`map` generate. The UI
  consumes it via `when`/`maybeWhen`. **Never** hand-roll a state class
  with `isLoading`/`error`/`data` fields + `copyWith` + `isSuccess`/
  `hasError` getters — that pattern is banned. (A small convenience
  getter like `bool get isLoading => maybeWhen(...)` on the union is fine.)
- **Side-effects (navigate/snackbar/dialog) go through `ref.listen`** in
  `build`, pattern-matching the union with `maybeWhen` — never
  `await notifier.x()` then `ref.read(provider)` to branch (see §3.8).
- **Per-feature DI lives in `shared/providers.dart`**: a `Provider` for
  the datasource, a `Provider` for the repository impl (typed as the
  interface), and a `StateNotifierProvider` per notifier.
- **DTOs live in `data/models/` only.** Domain entities are plain
  Dart classes — no `fromJson`, no freezed JSON annotation.
- **Every repository method returns `Either<Failure, T>`** (fpdart).
  No raw exceptions crossing layer boundaries; the repository maps
  `DioException` → `Failure`.
- **Idempotency-Key is minted per user action** (one per tap) — pass it
  to the repository method, or mint it inside the repository per call;
  never reuse one across retries, and never bake it into the datasource.

**Auth + security:**
- **Refresh token in flutter_secure_storage. Access token in
  Riverpod memory only.** Never shared_preferences, never plaintext.
- **Every mutation has an Idempotency-Key.**
- **Active role gating in UI is UX only**; the server enforces. Hide
  irrelevant tabs/buttons but never assume the server will let it
  through.

**Media:**
- **Reels are pointer records.** Never embed a player. Tap on a reel
  opens it in IG/TikTok/YouTube/FB via their URL schemes through
  `url_launcher`.
- **Audio is reference-only.** No playback in app. Tap → open
  external app.
- **No video hosting, ever.** No audio hosting, ever.

**Business rules:**
- **Order number format is `NK{year}-{5 digits}`** — do NOT pad with
  zeros from the client; the server emits it.
- **OTP is 5 digits**, not 6. The input must enforce this.
- **Four payment methods only.** If Figma shows Khalti / Stripe /
  Apple Pay, the spec wins.
- **Money is `{ amount, currency }`.** Never bare numbers; never
  multiply by 100 (the backend stores decimal NPR, not paisa).
- **Quiet Hours enforced server-side.** Client doesn't suppress push.

**Quality:**
- **PII never logged.** Mask phone/email in `core/pii_redactor.dart`;
  install in Sentry `beforeSend`.
- **Display localized text via i18n keys**, never hardcoded English
  strings in widgets.
- **Error codes drive UI**, not HTTP statuses or English titles.
- **One round-trip per screen.** If you need three GETs to render one
  screen, flag the backend.
- **No global state outside Riverpod.** No singletons, no top-level
  `late` mutables.
- **No `dynamic` in DTOs.** All API responses parsed through freezed
  classes via `json_serializable` + the openapi codegen schema.

## 14. Companion files

- `AUTH_FLOW.md` — full sequence for password / OTP / magic-link /
  passkey + refresh + role-switching + flutter_secure_storage +
  go_router deep-link consumer.
- `API_CONVENTIONS.md` — Dio setup, error mapping, Idempotency,
  pagination, money, retry/offline, correlation id, logging.
- `CUSTOMER_FLOWS.md` — onboarding → discovery → reels → cart →
  checkout → orders → returns → reviews.
- `CREATOR_FLOWS.md` — apply → social-connect → reel import →
  partnerships → Reel Studio (Pillar D) → Reach (Pillar E) →
  payouts.
- `VENDOR_FLOWS.md` — apply → brand setup → 5-step Add Product →
  partnerships → Brand Studio (Pillar D — defers to
  `stylemint-brand-studio-frontend`) → Matchmaking (Pillar E) →
  orders/fulfillment → payouts.
- `SOCIAL_FLOWS.md` — friend feed, stories, recommendation threads,
  groups, drop parties, group carts, co-watch, tips, reputation
  (Pillars C + F).
- `SETUP.md` — flutter create, pubspec, codegen, FCM/APNs,
  deep-link config, EAS-equivalent flavors, release checklist.

Read this SKILL.md first. Then read the relevant flow doc + the
backend SKILL.md for the module you're building.
