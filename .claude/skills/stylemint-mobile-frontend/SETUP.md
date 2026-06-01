# Setup — Style Mint Mobile (Flutter)

One-time bootstrap for a new `stylemint-mobile-frontend` repo.

## 1. Prerequisites

- **Flutter SDK 3.41.9 stable** (`flutter --version` to verify — pin this exact version)
- **Dart 3.7+** (ships with Flutter 3.41.9)
- **Xcode 26+** + iOS Simulator (Mac only; required for iOS 26 SDK support)
- **Android Studio** with SDK 36 + Android Emulator
- **Java 21** (`java --version`) — required by Gradle 8+ / AGP 8+
- **CocoaPods** (`pod --version`) — for iOS native deps
- **Firebase CLI** (`firebase --version`) — for FCM setup

```powershell
flutter doctor -v       # confirm everything is green before you start
```

## 2. Create the project

```powershell
flutter create stylemint_mobile_frontend `
  --org app.stylemint `
  --platforms=ios,android `
  --description "Style Mint mobile app — Customer + Creator + Vendor."
cd stylemint_mobile_frontend
```

Note: the folder name uses underscores per Dart package conventions
(`pubspec.yaml`'s `name:` must be `lower_snake_case`). The git repo
can still be named `stylemint-mobile-frontend`.

## 3. `pubspec.yaml`

```yaml
name: stylemint_mobile_frontend
description: Style Mint mobile app — Customer + Creator + Vendor.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.7.0 <4.0.0'
  flutter: '>=3.41.9'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Routing
  go_router: ^15.1.2

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.4.1

  # Functional programming (Either<Failure, T> for Clean Architecture)
  fpdart: ^1.1.0

  # HTTP + interceptors (data layer only — never import Dio in domain/)
  dio: ^5.7.0
  dio_smart_retry: ^6.0.0

  # Models / DTOs (data layer only — domain entities are plain Dart)
  freezed_annotation: ^2.5.0
  json_annotation: ^4.9.0

  # Forms
  formz: ^0.8.0

  # Storage
  flutter_secure_storage: ^10.0.0
  shared_preferences: ^2.3.5

  # Push + realtime
  firebase_core: ^3.8.0
  firebase_messaging: ^15.3.0
  flutter_local_notifications: ^18.0.0
  signalr_netcore: ^2.0.0

  # Media + camera
  camera: ^0.11.0
  image_picker: ^1.1.2
  file_picker: ^8.1.0
  mobile_scanner: ^6.0.0
  url_launcher: ^6.3.1
  flutter_web_browser: ^0.18.0     # in-app browser for payment redirects

  # Maps (Pillar B)
  google_maps_flutter: ^2.9.0
  geolocator: ^13.0.0

  # i18n
  intl: any                         # locked by flutter_localizations
  timezone: ^0.10.0

  # Auth helpers
  local_auth: ^2.3.0                # biometric for step-up
  app_links: ^6.3.0                 # deep link handler

  # Network awareness
  connectivity_plus: ^6.1.0

  # Crash + logging
  sentry_flutter: ^8.10.0
  logger: ^2.4.0

  # Misc
  uuid: ^4.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  very_good_analysis: ^7.0.0

  build_runner: ^2.5.0
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.6.2
  custom_lint: ^0.7.0
  riverpod_lint: ^2.6.2
  openapi_generator: ^6.0.0         # generates the dio client from Swagger

  mocktail: ^1.0.4
  patrol: ^3.10.0                   # e2e

flutter:
  uses-material-design: true
  generate: true                    # turns on flutter_localizations codegen

  assets:
    - assets/images/
    - assets/fonts/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf  weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf weight: 600
        - asset: assets/fonts/Inter-Bold.ttf    weight: 700
```

```powershell
flutter pub get
```

## 4. `analysis_options.yaml`

```yaml
include: package:very_good_analysis/analysis_options.7.0.0.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated/**"

linter:
  rules:
    public_member_api_docs: false   # not a library; we don't doc every public member
    flutter_style_todos:  false
```

## 5. Code generation setup

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          field_rename: none        # the backend uses camelCase already
          checked: true
      freezed:
        options:
          json_serializable: true
```

```yaml
# l10n.yaml — translates lib/l10n/app_*.arb into Dart
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/l10n/generated
```

Run codegen once after every model / Riverpod / openapi change:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Or watch mode during dev:

```powershell
dart run build_runner watch --delete-conflicting-outputs
```

## 6. Clean Architecture base files

Create these once at project bootstrap — every feature depends on them.

### `lib/core/error/failure.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network()                          = NetworkFailure;
  const factory Failure.auth()                             = AuthFailure;
  const factory Failure.validation({required String code}) = ValidationFailure;
  const factory Failure.conflict()                         = ConflictFailure;
  const factory Failure.server()                           = ServerFailure;
  const factory Failure.unknown()                          = UnknownFailure;
}
```

> **No `lib/core/usecase/` file.** This project has **no UseCase layer** —
> presentation `StateNotifier`s call repositories directly. Do not scaffold
> a `UseCase` base class.

### `lib/core/network/dio_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(DioClientRef ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5020',
  );

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    IdempotencyInterceptor(),
    CorrelationInterceptor(),
    LocaleInterceptor(ref),
    RefreshInterceptor(dio, ref),
    LoggingInterceptor(),
  ]);

  return dio;
}

class IdempotencyInterceptor extends Interceptor {
  static const _safeMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    if (!_safeMethods.contains(opts.method.toUpperCase())) {
      opts.headers['Idempotency-Key'] ??= const Uuid().v4();
    }
    handler.next(opts);
  }
}

class CorrelationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    opts.headers['X-Correlation-Id'] ??= const Uuid().v4();
    handler.next(opts);
  }
}
```

## 7. OpenAPI codegen (from backend Swagger)

Two paths — pick one:

### 6a. CI / one-shot

Run `openapi_generator` against the backend's live Swagger doc to
produce `lib/api/schema.dart` + dio-flavored client:

```yaml
# openapi_config.yaml (project root)
spec:
  remote: 'http://localhost:5020/swagger/v1/swagger.json'
generator: 'dart-dio-next'
output: 'lib/api/generated'
options:
  pubName: 'stylemint_api'
  pubVersion: '1.0.0'
```

```powershell
dart run openapi_generator
```

This produces a typed `StyleMintApi` class with one method per
endpoint, wrapping the existing Dio instance. Commit
`lib/api/generated/` to the repo so CI builds don't need the
backend running.

### 6b. Hand-written DTOs via freezed (alternative)

If the codegen output is too verbose, hand-write the DTOs you
actually use as freezed classes. Pragmatically, most apps end up
doing a hybrid: codegen for the schema, hand-written wrappers for
ergonomics.

## 8. `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/format_date.dart';
import 'core/push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezone();
  await Firebase.initializeApp();
  await setupPushBackgroundHandler();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 0.2;
      options.beforeSend = piiScrubber;
    },
    appRunner: () => runApp(
      const ProviderScope(child: StyleMintApp()),
    ),
  );
}
```

## 9. `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class StyleMintApp extends ConsumerWidget {
  const StyleMintApp({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Style Mint',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh'),
        Locale('ne'),
        Locale('es'),
        Locale('hi'),
      ],
      routerConfig: router,
    );
  }
}
```

## 10. iOS configuration

`ios/Runner/Info.plist` additions:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>      <string>app.stylemint</string>
    <key>CFBundleURLSchemes</key>   <array><string>stylemint</string></array>
  </dict>
</array>

<key>NSCameraUsageDescription</key>
<string>Style Mint uses the camera for product photos, return evidence, and KYC.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Style Mint reads your photo library for product photos and avatars.</string>
<key>NSContactsUsageDescription</key>
<string>Style Mint can match your contacts to friends already on Style Mint (we never store raw phone numbers).</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used for delivery tracking and address autofill.</string>
<key>NSFaceIDUsageDescription</key>
<string>Style Mint uses Face ID for step-up verification on sensitive actions.</string>

<key>FirebaseAppDelegateProxyEnabled</key><false/>
```

Universal links: add the apple-app-site-association file at
`https://stylemint.app/.well-known/apple-app-site-association`
(coordinate with the backend team or your CDN config).

Then add the Associated Domains capability in Xcode:
`applinks:stylemint.app`.

## 11. Android configuration

`android/app/build.gradle` minSdkVersion:

```gradle
defaultConfig {
    applicationId "app.stylemint.mobile"
    minSdkVersion 24           // required for biometric + Keystore + flutter_secure_storage 10+
    targetSdkVersion 36        // Android 16 (2026 requirement)
    compileSdkVersion 36
    multiDexEnabled true
}
```

`android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
  <!-- Deep links: custom scheme -->
  <activity android:name=".MainActivity" ...>
    <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="stylemint" />
    </intent-filter>

    <!-- Universal links -->
    <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="https" android:host="stylemint.app"
            android:pathPrefix="/auth/magic" />
    </intent-filter>
  </activity>
</application>
```

Universal links: also add `assetlinks.json` at
`https://stylemint.app/.well-known/assetlinks.json` with your SHA-256
signing key fingerprint.

## 12. Firebase (FCM) setup

```powershell
# Install the FlutterFire CLI if you haven't
dart pub global activate flutterfire_cli

# Wires google-services.json + GoogleService-Info.plist into the project
flutterfire configure --project=<your-firebase-project-id>
```

This generates `lib/firebase_options.dart`. Pass to
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

For iOS APNs: upload your APNs auth key to the Firebase console
(Project Settings → Cloud Messaging). The backend's
`stylemint-messaging` module receives the FCM token via
`POST /v1/devices` and routes pushes through FCM (which bridges to
APNs on iOS).

## 13. Push registration

```dart
// lib/core/push.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> setupPushBackgroundHandler() async {
  FirebaseMessaging.onBackgroundMessage(_onBackground);
}

@pragma('vm:entry-point')
Future<void> _onBackground(RemoteMessage msg) async {
  // background isolate — minimal work; backend handles delivery accounting
}

Future<String?> registerForPush(WidgetRef ref) async {
  final perm = await FirebaseMessaging.instance.requestPermission();
  if (perm.authorizationStatus == AuthorizationStatus.denied) return null;
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return null;
  // Register with backend
  await ref.read(apiClientProvider).postIdempotent('/v1/devices', data: {
    'pushToken': token,
    'platform': Platform.isIOS ? 'ios' : 'android',
  });
  // Foreground tap handler
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    final url = msg.data['url'] as String?;
    if (url != null) ref.read(appRouterProvider).go(url);
  });
  return token;
}
```

## 14. Localization

Source-of-truth file `lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en-US",
  "appName": "Style Mint",
  "signIn": "Sign in",
  "emailOrPhone": "Email or phone",
  "continueCta": "Continue",
  "otpInstructions": "We sent a 5-digit code to {target}",
  "@otpInstructions": {
    "placeholders": { "target": { "type": "String" } }
  }
}
```

Four sibling files: `app_zh.arb`, `app_ne.arb`, `app_es.arb`,
`app_hi.arb`. Run `flutter gen-l10n` (or it generates automatically
via `pubspec.yaml`'s `generate: true`).

In a widget:

```dart
Text(AppLocalizations.of(ctx)!.signIn)
```

## 15. Smoke test the wiring

```powershell
# Backend running on localhost:5020 with all dev services up
dart run build_runner build --delete-conflicting-outputs
dart run openapi_generator
flutter run -d <device|simulator>
```

Open the app on the device:

1. Welcome screen renders
2. Tap "Sign in" → phone number screen
3. Enter `+9779812345678` → "Send code"
4. Backend in dev mode returns `devPlaintextCode` — copy it from
   the response (or check the backend log)
5. Enter the 5-digit code → home screen renders

If any step fails, check:
- Flutter logs (`flutter run` terminal output)
- iOS console (Xcode > Window > Devices and Simulators > device logs)
- Android `adb logcat`
- Backend logs (Core.Api terminal)

## 16. Environment management

| Variant | API base URL | Flavor |
|---|---|---|
| Local | `http://localhost:5020` (or LAN IP for device testing) | `dev` |
| Staging | `https://api-staging.stylemint.app` | `staging` |
| Prod | `https://api.stylemint.app` | `prod` |

Pass via `--dart-define` at build time:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5020
```

For multi-flavor builds, set up flavor configs (iOS schemes +
Android product flavors). The Flutter docs cover this in detail:
https://docs.flutter.dev/deployment/flavors

## 17. Deep linking smoke test

```powershell
# iOS Simulator
xcrun simctl openurl booted "stylemint://reel/abc-123"

# Android
adb shell am start -W -a android.intent.action.VIEW -d "stylemint://reel/abc-123" app.stylemint.mobile
```

Should land on `/reel/abc-123` route.

## 18. CI

Minimal `.github/workflows/ci.yml`:

```yaml
name: ci
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: stable
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release --dart-define=API_BASE_URL=https://api-staging.stylemint.app
```

Trigger native builds via Codemagic, Bitrise, or GitHub Actions
runners with Xcode for iOS.

## 19. Release checklist

Before submitting to App Store / Play Store:

- [ ] App icons + launcher icons finalized (`flutter_launcher_icons`)
- [ ] All 5 i18n locale files have full translations
- [ ] Privacy policy URL + Terms URL configured
- [ ] Account deletion flow accessible from settings (Apple
      requirement)
- [ ] OAuth provider redirect URIs include production deep link
- [ ] Apple Developer team ID + signing certs in Xcode
- [ ] Play Console upload key configured + signed APK/AAB
- [ ] App Store Review questionnaire answered (encryption: yes,
      uses HTTPS only)
- [ ] Backend prod URL passed via `--dart-define` in release builds
- [ ] Sentry DSN configured + PII scrubber installed
- [ ] Analytics opted-out by default
- [ ] Smoke test on a fresh device: OTP signup, browse reels, add
      to cart, check out with CashOnDelivery

## 20. Common pitfalls

- **Domain importing Dio/Flutter** — the linter won't catch this for
  you; run `grep -r "package:dio" lib/features/*/domain/` in CI and
  fail the build if it finds anything.
- **Adding a UseCase layer** — don't. The `StateNotifier` calls the
  repository directly. There is no `domain/usecases/`.
- **Forgetting to fold `Either` in the notifier** — unhandled `Left`
  means a silent no-op. Always
  `state = either.fold(MyState.loadFailure, MyState.loadSuccess)`.
- **Idempotency-Key inside the datasource as a constant** — it must be
  minted per user action (one per tap), passed to the repository method
  or minted inside the repository per call — never reused across the
  retry logic in the datasource.
- **`build_runner` stale output** — if your codegen seems out of
  sync, always pass `--delete-conflicting-outputs`. The error
  messages can be misleading.
- **`riverpod_generator` requires part directive** — every file
  using `@riverpod` must declare `part 'file_name.g.dart';`.
- **Riverpod widgets need `ConsumerWidget`** (not `StatelessWidget`)
  or use `Consumer` inside the build method.
- **Hot reload doesn't apply to native config changes** — `Info.plist`,
  `AndroidManifest.xml`, `pubspec.yaml` changes need
  `flutter run` from scratch.
- **iOS Simulator's keychain is volatile** —
  `flutter_secure_storage` reads may fail across simulator restarts.
  Test on a real device or persistent simulator.
- **`firebase_messaging` on iOS requires the
  `FirebaseAppDelegateProxyEnabled = false`** entry in `Info.plist`
  + manual APNs token forwarding via swizzling — follow the
  FlutterFire docs exactly.
- **`go_router` redirect runs on every navigation** — don't put
  expensive synchronous work there; use async `.then()` patterns or
  pre-load via `refreshListenable`.
- **Deep links on Android cold start** — `app_links` package's
  `getInitialAppLink()` is needed; `onAppLink` only fires for warm
  starts.
- **`flutter_secure_storage` on Android** uses
  EncryptedSharedPreferences when configured — pass
  `aOptions: AndroidOptions(encryptedSharedPreferences: true)`.
- **`openapi_generator` regenerates the whole client** — review the
  diff before commit; sometimes naming heuristics produce odd
  method names that you'll want to alias.

## 21. Useful packages we did NOT pick (and why)

| Skipped | Why |
|---|---|
| `flutter_bloc` | Riverpod is the chosen state lib; don't mix. |
| `get` / `getx` | Discouraged; Riverpod + go_router is the idiomatic combo. |
| `http` | Use `dio` — better interceptor ecosystem. |
| `hive` | `shared_preferences` + `flutter_secure_storage` covers our needs. |
| `provider` | Riverpod is its successor. |
| `chopper` | Use `dio` + openapi-generator. |
| `auto_route` | `go_router` is the recommended router. |
| `flutter_lints` (default) | `very_good_analysis` is stricter. |
| `mockito` | `mocktail` is null-safe and ergonomic. |
| `freezed_lints` | Not needed; freezed's own analyzer is enough. |
| `dartz` | Use `fpdart` instead — same Either semantics, better Dart 3 null-safety support and active maintenance. |
| Direct Dio in providers | Violates Clean Architecture dependency rule. Always DataSource → Repository → Notifier. |
