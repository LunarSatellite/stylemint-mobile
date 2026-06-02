# StyleMint Mobile — Developer Onboarding

Get productive on the **StyleMint** Flutter app fast. StyleMint is a three-sided
reel-commerce marketplace (Customer / Creator / Vendor) backed by a .NET 10
modular-monolith API.

- **Mobile repo:** `stylemint-mobile` (Flutter, package `stylemint_mobile_frontend`)
- **Backend:** .NET 10, live UAT at `https://stylemint.voyageritnepal.com`
- **In-repo build guide:** `BUILD_AND_TEST.md` (exact commands — start there)

---

## 1. Get it running (5 steps)

> Flutter is **pinned to 3.44.0 via fvm** (`.fvmrc`). Don't use a mismatched
> global SDK — `pubspec.yaml` requires `flutter >= 3.44.0`.

```bash
dart pub global activate fvm          # once
cd stylemint-mobile
git pull                              # if it errors on local changes: git stash first
fvm install && fvm use 3.44.0
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # ← REQUIRED
fvm flutter run --dart-define=API_BASE_URL=https://stylemint.voyageritnepal.com
```

**The #1 gotcha:** generated files (`*.freezed.dart`, `*.g.dart`) are git-ignored.
A fresh clone or any pull **won't compile** until you run `build_runner`. If you
see `No such file or directory: *.freezed.dart`, that's this. Use
`build_runner watch` while editing freezed/json/riverpod files.

**The #2 gotcha:** the API base URL is a compile-time define. Without
`--dart-define=API_BASE_URL=...` the app hits `localhost:5020` (unreachable from
a phone).

---

## 2. Architecture & conventions

Clean architecture, one folder per feature area:

```
lib/features/<area>/<feature>/
  data/{datasources,models,repositories}    # DTOs (fromJson), remote datasources, repo impls
  domain/{entities,repositories}            # entities + repo interfaces
  presentation/{screens,widgets,notifiers}  # UI + StateNotifiers
  shared/providers.dart                     # Riverpod DI wiring for the feature
```

- **State:** Riverpod 3 + `StateNotifier`; state classes are **freezed** unions
  (`initial / loadInProgress / loadSuccess / loadFailure`). Errors flow as
  `Either<NetworkExceptions, T>` (fpdart) from repos.
- **Networking:** one shared `ApiClient` over Dio (`apiClientProvider`); a Dio
  interceptor attaches the bearer token and does 401→refresh→retry. `TokenStorage`
  (flutter_secure_storage) persists the session.
- **Routing:** `go_router`, flat routes in `lib/routes/app_router.dart` +
  `RouteNames`; a redirect guard gates auth (`_publicPaths` / `_authOnlyPaths`).
- **Design system:** `lib/theme/design_tokens.dart` (`DesignTokens.*` — colors,
  spacing `s4..s48`, text styles) and reusable `Sm*` widgets in
  `lib/shared/presentation/widgets/` (`SmPrimaryButton`, `SmAppBar`,
  `SmSnackbar`, `SmTextField`, …). Use these; don't hardcode colors/sizes.
- **Lints:** `very_good_analysis` (strict). `flutter analyze` should be 0 errors;
  the large info/warning baseline is pre-existing.
- **Design source of truth:** the 201 design-spec PDFs under
  `Stylemint Design Spec Docs/` (Brand/Creator/Customer). Build screens from the
  matching PDF.

---

## 3. Backend contract (what the app talks to)

- camelCase JSON, **integer enums**, flattened money pairs (`amountValue` +
  `amountCurrency`), cursor pagination (`{items, nextCursor/cursor, hasMore}`),
  RFC 7807 error bodies keyed on `errorCode`, `Idempotency-Key` on mutations.
- Note one inconsistency: the discovery feed is `GET /api/v1/customer/feed`
  (with `api/` prefix) while most routes are `/v1/...`.
- The `/integration` page on the backend host documents the mobile API surface.

---

## 4. Auth model (important — it's not password-based)

**Target = passkey/device-first:** the device is the identity; email + phone are
collected and OTP-verified during onboarding **for communication, not auth**.

What's shipped today (device-auth on the existing backend):
- **Onboarding = Create account** (4 steps: info → email OTP → phone OTP → terms),
  **no password UI** — a strong password is generated and stored silently.
- After onboarding the app **auto-logs in** and lands you in the app.
- Returning users get a **biometric/device-PIN unlock** on launch.
- Login-OTP only works for **existing** accounts (new users must "Create account").

Pending **backend** work for true WebAuthn passkeys (tracked as backend issues
#20 passkey→tokens, #21 usernameless passkey, #22 optional password). No mobile
change needed until those land.

---

## 5. Testing

```bash
fvm flutter analyze            # 0 errors expected
fvm flutter test               # widget smoke tests in test/smoke/
```

On-device smoke test: Create account → land in app → relaunch → biometric unlock →
confirm API-backed screens load. Full checklist in `BUILD_AND_TEST.md` §7.

---

## 6. Workflow

- Branch from `main`, open a PR, squash-merge. Keep `flutter analyze` at 0 errors.
- After pulling, **always** re-run `build_runner` before running the app.
- Building an APK for testers: `BUILD_AND_TEST.md` §5 (needs Android SDK + JDK 17;
  `flutter clean` after any Android manifest / native change).

When stuck, the **`BUILD_AND_TEST.md` troubleshooting table** maps common errors
(missing codegen, blocked pull, wrong SDK, no-network APK, "unable to send OTP",
biometric crash) to fixes.
