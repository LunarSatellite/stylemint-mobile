# Style Mint — Mobile Frontend

> **Flutter 3.41.9 · Dart 3.7 · Riverpod 3 · Feature-First Clean Architecture**
>
> iOS + Android app for the Style Mint social commerce platform.
> One app, three role profiles: **Customer · Creator · Vendor**

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Folder Structure](#4-folder-structure)
5. [Getting Started](#5-getting-started)
6. [Running the App](#6-running-the-app)
7. [Code Generation](#7-code-generation)
8. [Environment Variables](#8-environment-variables)
9. [Project Conventions](#9-project-conventions)
10. [Feature Modules](#10-feature-modules)
11. [Team & Claude AI Context](#11-team--claude-ai-context)

---

## 1. Product Overview

Style Mint is a **general-purpose social commerce platform** — customers browse and buy, creators import reels and earn commission, vendors list products and run creator campaigns.

A single user account can hold up to three role profiles. Each role unlocks a different surface in the same app:

| Role | What they do |
|---|---|
| **Customer** | Browse, search, watch reels, buy, post in friend feed, join groups |
| **Creator** | Connect IG/TikTok/YouTube/FB, import reels, tag products, earn commission |
| **Vendor** | Apply with KYC, list products, run creator partnerships, manage orders, withdraw earnings |

---

## 2. Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.41.9 stable |
| Language | Dart 3.7+ (sound null safety, sealed classes, pattern matching) |
| Architecture | Feature-First Clean Architecture |
| State management | Riverpod 3 + riverpod_generator |
| Error handling | fpdart `Either<Failure, T>` — explicit error paths, no hidden throws |
| Routing | go_router (declarative, deep-link native) |
| HTTP | Dio 5 + interceptors (idempotency, correlation, auth, refresh) |
| Models / DTOs | freezed + json_serializable (data layer only) |
| Secure storage | flutter_secure_storage (refresh token + passkey) |
| Push | firebase_messaging + flutter_local_notifications |
| Realtime | signalr_netcore (`/hubs/notifications`) |
| i18n | flutter_localizations + intl (en-US, zh, ne, es, hi) |
| Linter | very_good_analysis |
| Tests | flutter_test + mocktail + patrol (e2e) |
| Crash reporting | sentry_flutter |

---

## 3. Architecture

This project follows **Feature-First Clean Architecture**. Every feature contains three layers with a strict dependency rule:

```
┌─────────────────────────────────────────┐
│  PRESENTATION  (Flutter + Riverpod)     │
│  screens/ · widgets/ · providers/       │
│  — calls UseCases only                  │
└──────────────┬──────────────────────────┘
               │ depends on
               ▼
┌─────────────────────────────────────────┐
│  DOMAIN  (pure Dart — no Flutter/Dio)   │
│  entities/ · repositories/ · usecases/ │
│  — returns Either<Failure, T>           │
└──────────┬──────────────────────────────┘
           │ implements
           ▼
┌─────────────────────────────────────────┐
│  DATA  (Dio + freezed DTOs)             │
│  datasources/ · models/ · repositories/│
│  — converts DTOs → domain entities      │
│  — maps DioException → Failure          │
└─────────────────────────────────────────┘
```

**Key rules:**
- Domain never imports Flutter or Dio
- Presentation never calls repositories directly — always through a UseCase
- DTOs (with `fromJson`) live in `data/models/` only
- Every UseCase returns `Either<Failure, T>` — never throws across layer boundaries
- `Idempotency-Key` is generated in the presentation layer (one per user tap)

---

## 4. Folder Structure

```
lib/
├── main.dart                   # Entry point
├── app.dart                    # MaterialApp.router + ProviderScope
├── core/
│   ├── error/
│   │   └── failure.dart        # Sealed Failure class (network/auth/server/...)
│   ├── usecase/
│   │   └── usecase.dart        # Abstract UseCase<Type, Params> interface
│   ├── network/
│   │   └── dio_client.dart     # Dio Riverpod provider + interceptors
│   └── utils/
│       ├── size_config.dart    # Tablet-responsive sizing
│       ├── format_money.dart   # "Rs 1,234.56"
│       └── format_date.dart    # NPT timezone helpers
├── shared/
│   ├── domain/entities/        # Money, Role, Pagination — pure Dart
│   └── presentation/widgets/  # SmTextField, SmButton, SmSnackbar, etc.
├── theme/
│   ├── colors.dart             # Brand design tokens
│   ├── typography.dart         # Inter font, tablet-responsive scale
│   └── app_theme.dart          # Material 3 ThemeData light + dark
├── routes/
│   ├── route_names.dart        # All route path constants
│   └── app_router.dart         # GoRouter Riverpod provider + auth redirect
└── features/
    ├── auth/                   # Login, OTP, magic-link, passkey, role switch
    ├── customer/
    │   ├── onboarding/
    │   ├── discovery/          # Home feed, search, trending
    │   ├── reels/              # Reel feed + external player (url_launcher)
    │   ├── cart/
    │   ├── checkout/           # 4 payment methods: Card, PayPal, eSewa, COD
    │   ├── orders/
    │   └── reviews/
    ├── creator/
    │   ├── apply/
    │   ├── social_connect/     # IG / TikTok / YouTube / Facebook OAuth
    │   ├── reel_import/
    │   ├── partnerships/
    │   ├── reel_studio/        # Pre-publish coaching (Pillar D)
    │   ├── reach/              # Cross-platform publish + paid boost (Pillar E)
    │   └── earnings/
    ├── vendor/
    │   ├── apply/              # KYC document upload
    │   ├── dashboard/
    │   ├── add_product/        # 5-step product wizard
    │   ├── products/
    │   ├── partnerships/
    │   ├── brand_studio/       # Campaign authoring (Pillar D)
    │   ├── matchmaking/        # Creator matchmaking (Pillar E)
    │   ├── orders/
    │   └── earnings/
    ├── social/
    │   ├── feed/               # Friend feed, stories, reactions
    │   ├── recommendations/    # "Ask friends what to buy" (Pillar F)
    │   ├── groups/
    │   ├── friends/
    │   ├── drop_party/         # QR-invite group shopping (Pillar C)
    │   ├── group_cart/
    │   ├── co_watch/
    │   └── tips/
    ├── settings/
    └── support/
```

---

## 5. Getting Started

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.41.9 stable |
| Dart | 3.7+ |
| Xcode | 26+ (iOS builds) |
| Android SDK | 36, Java 21 |

### Setup

```bash
# 1. Clone
git clone git@lunar:LunarSatellite/stylemint-mobile.git
cd stylemint-mobile

# 2. Install dependencies
flutter pub get

# 3. Run code generation (Riverpod providers, freezed models)
dart run build_runner build

# 4. Run the app
flutter run --dart-define=API_BASE_URL=http://localhost:5020
```

---

## 6. Running the App

```bash
# Debug on a connected device
flutter run --dart-define=API_BASE_URL=http://localhost:5020

# Debug on a specific device
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:5020

# Release build (Android)
flutter build apk --dart-define=API_BASE_URL=https://api.stylemint.app

# Release build (iOS)
flutter build ios --dart-define=API_BASE_URL=https://api.stylemint.app
```

---

## 7. Code Generation

This project uses `build_runner` for:
- **Riverpod providers** — `@riverpod` → generates `*Provider`, `Ref`
- **Freezed models** — `@freezed` → generates immutable DTOs with `copyWith`
- **JSON serialization** — `@JsonSerializable` → generates `fromJson` / `toJson`

```bash
# One-time build
dart run build_runner build

# Watch mode (auto-rebuilds on file save during development)
dart run build_runner watch
```

> ⚠️ Generated files (`*.g.dart`, `*.freezed.dart`) are **gitignored** — never commit them. Run codegen after every pull.

---

## 8. Environment Variables

Passed via `--dart-define` at build/run time. Never hardcoded.

| Variable | Default | Description |
|---|---|---|
| `API_BASE_URL` | `http://localhost:5020` | Backend API base URL |

Production:
```bash
flutter run --dart-define=API_BASE_URL=https://api.stylemint.app
```

---

## 9. Project Conventions

### Routing
All route paths are constants in `lib/routes/route_names.dart` — never hardcode a path string.

### Money
Always `{ amount: double, currency: "NPR" }` — never a bare number. Use the `MoneyText` widget and `formatMoney()` utility.

### OTP
**5 digits, not 6.** The input widget enforces this.

### Order numbers
Format `NK{year}-{5 digits}` (e.g. `NK2026-00123`) — emitted by the server, never constructed on the client.

### Auth tokens
- **Refresh token** → `flutter_secure_storage` (persisted)
- **Access token** → Riverpod state only (in-memory, never written to disk)

### Error handling
All UseCases return `Either<Failure, T>`. In the presentation layer, fold on the result:
```dart
result.fold(
  (failure) => state = AsyncError(failure, StackTrace.current),
  (data)    => state = AsyncData(data),
);
```

### Linting
```bash
flutter analyze
```

The project uses `very_good_analysis` — stricter than default Flutter lints.

---

## 10. Feature Modules

Each feature maps to one or more backend modules. Read the corresponding doc in `.claude/skills/stylemint-mobile-frontend/` before building:

| Feature | Flow doc | Backend module |
|---|---|---|
| Auth, roles, sessions | `AUTH_FLOW.md` | `stylemint-identity` |
| Customer commerce | `CUSTOMER_FLOWS.md` | `stylemint-cart-checkout`, `stylemint-orders` |
| Creator publishing | `CREATOR_FLOWS.md` | `stylemint-reels`, `stylemint-partnerships` |
| Vendor management | `VENDOR_FLOWS.md` | `stylemint-catalog`, `stylemint-payouts` |
| Social commerce | `SOCIAL_FLOWS.md` | `stylemint-social-graph`, `stylemint-community` |
| API conventions | `API_CONVENTIONS.md` | All modules |

---

## 11. Team & Claude AI Context

Project-level Claude context lives in `.claude/skills/stylemint-mobile-frontend/`. When a developer opens this project in **Claude Code**, Claude automatically reads these files and follows the project's architecture rules and conventions.

| File | What it covers |
|---|---|
| `SKILL.md` | Full stack reference, folder layout, CA rules, hard invariants |
| `SETUP.md` | Bootstrap guide, pubspec, codegen, FCM, release checklist |
| `AUTH_FLOW.md` | Auth sequences (OTP / magic-link / passkey / refresh / role-switch) |
| `API_CONVENTIONS.md` | Dio setup, error mapping, pagination, idempotency, money |
| `CUSTOMER_FLOWS.md` | Onboarding → discovery → reels → cart → checkout → orders |
| `CREATOR_FLOWS.md` | Apply → social-connect → reel import → partnerships → earnings |
| `VENDOR_FLOWS.md` | Apply → products → partnerships → brand studio → orders → earnings |
| `SOCIAL_FLOWS.md` | Friend feed → recommendations → groups → drop parties → tips |

---

*Built with Flutter · Style Mint Platform v1.1 · © 2026 [Voyager IT Nepal](https://voyageritnepal.com)*
