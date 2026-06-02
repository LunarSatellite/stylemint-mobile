# Build & Test — StyleMint Mobile

How to set up, run, build, and test the app. **Read the Codegen section — skipping
it is the #1 cause of "No such file or directory: *.freezed.dart / *.g.dart" errors.**

---

## 1. Prerequisites

- **Flutter is pinned to 3.44.0 via fvm** (see `.fvmrc`). Do **not** use a global
  Flutter that differs — `pubspec.yaml` requires `flutter >= 3.44.0`.
- Android SDK + a JDK 17 (for APK builds). iOS needs Xcode on macOS.

```bash
# one-time, if you don't have fvm
dart pub global activate fvm
```

---

## 2. First-time setup (or after every `git pull`)

```bash
cd stylemint-mobile
git pull                       # if this errors with "local changes would be
                               # overwritten", run `git stash` (or commit) first

fvm install                    # fetches Flutter 3.44.0 per .fvmrc
fvm use 3.44.0                 # creates the per-project .fvm/ symlink

fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # ← REQUIRED, see below
```

> In your IDE, point the Flutter SDK path at `.fvm/flutter_sdk`.

---

## 3. Codegen (do NOT skip)

This project uses **freezed**, **json_serializable**, and **riverpod_generator**.
The generated files (`*.freezed.dart`, `*.g.dart`) are **git-ignored**, so they do
**not** exist on a fresh clone or after a pull. You must generate them:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

If you see errors like:

```
Error when reading 'lib/routes/app_router.g.dart': No such file or directory
Error when reading 'lib/.../xxx_dto.freezed.dart': No such file or directory
```

…it means codegen hasn't run. Run the command above. Re-run it any time you
pull or edit a freezed/json/riverpod-annotated file. (For live editing:
`fvm dart run build_runner watch --delete-conflicting-outputs`.)

---

## 4. Run on a device/emulator

The backend base URL is a **compile-time define**. Without it the app defaults to
`http://localhost:5020`, which a phone can't reach.

```bash
# UAT
fvm flutter run --dart-define=API_BASE_URL=https://stylemint.voyageritnepal.com
```

---

## 5. Build an APK

```bash
fvm flutter clean              # clears the stale AndroidManifest after manifest/native changes
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

# Release APK (shareable; debug-signed is fine for internal testing)
fvm flutter build apk --release --dart-define=API_BASE_URL=https://stylemint.voyageritnepal.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk` → sideload to a device
with USB debugging enabled.

> `flutter clean` matters after any Android manifest / `MainActivity` change
> (e.g. the INTERNET permission + `FlutterFragmentActivity` for biometrics) — a
> stale build silently keeps the old manifest.

---

## 6. Static checks & tests

```bash
fvm flutter analyze            # expect 0 errors (infos/warnings are the
                               # very_good_analysis baseline)
fvm flutter test               # widget smoke tests live in test/smoke/
```

---

## 7. Full onboarding smoke test (on-device)

1. App launches cleanly.
2. Sign-in screen shows **"New to Style Mint? Create account"** → tap it.
3. **Onboarding (4 steps, no password):** name/email/phone → enter **email OTP**
   → enter **phone OTP** → accept terms. *(Confirm the OTP email/SMS actually
   arrive — that's a backend delivery check.)*
4. On finishing you should **land directly in the app** (auto-login), not bounce
   to a login screen.
5. **Close & relaunch** → **biometric / device-PIN unlock** prompt → unlock → in.
   Also test the **Sign out** fallback on that screen.
6. Spot-check that API-backed screens load (feed / dashboards) — confirms the
   `INTERNET` permission is present in the build.

**Expected / known:** a password is generated and stored **silently** (the user
never sees it) because the backend still mandates one. True passkey-only / true
WebAuthn passkey login is pending backend issues #20–#22.

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `*.freezed.dart` / `*.g.dart` "No such file or directory" | codegen not run | `fvm dart run build_runner build --delete-conflicting-outputs` |
| `git pull` → "local changes would be overwritten by merge" | uncommitted local edits | `git stash` (or commit), then `git pull` |
| `pub get` fails: "requires Flutter SDK version >= 3.44.0" | wrong/old SDK | `fvm install && fvm use 3.44.0`, build via `fvm flutter ...` |
| Installed APK: every API call fails / "no network" | release build missing INTERNET perm, or stale build | ensure on latest `main`, then `flutter clean` + rebuild |
| "Unable to send OTP" on the sign-in screen | login-OTP only works for existing accounts | use **Create account** (registration) for new users |
| Biometric prompt crashes / nothing happens | needs `FlutterFragmentActivity` (on `main`) + a device with biometrics/PIN enrolled | ensure latest `main` + `flutter clean` rebuild |
