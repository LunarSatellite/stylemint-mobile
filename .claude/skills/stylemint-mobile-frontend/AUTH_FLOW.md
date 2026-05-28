# Auth Flow — Style Mint Mobile (Flutter)

Companion to `SKILL.md`. End-to-end auth lifecycle for the mobile
app: four entry paths (password, phone OTP, email magic link,
passkey), JWT shape, refresh token handling with
flutter_secure_storage, role-switching, deep-link consumers, and
edge cases. All code in Dart 3.7 / Flutter 3.41.9.

**Architecture note:** Auth follows Feature-First Clean Architecture.
`auth/domain/` is pure Dart. `auth/data/` holds the Dio datasource
and repository impl. `auth/presentation/providers/` calls UseCases
only — `Either<Failure, AuthState>` returned from every UseCase.

## 1. Token storage rules

| Token | Where | Why |
|---|---|---|
| **Access token** (15 min JWT) | Riverpod state only | Cleared on app restart; refresh handles silent reauth. |
| **Refresh token** (30 day) | `flutter_secure_storage` | Keychain / Keystore; hardware-backed where available. |
| Passkey credential id | `flutter_secure_storage` | Need across sessions to assert. |
| Account claims (id, email, displayName, locale) | Riverpod + `shared_preferences` | Survive restart for fast cold-start UI. |
| Last active role | `shared_preferences` | Pick up where the user left off. |

**Never** store either token in `shared_preferences`. **Never** log
either token. **Never** include either token in crash reports —
install a Sentry `beforeSend` scrubber.

```dart
// lib/auth/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _refreshKey = 'refreshToken';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void>   setRefresh(String t) => _storage.write(key: _refreshKey, value: t);
  static Future<String?> getRefresh()         => _storage.read(key: _refreshKey);
  static Future<void>   clearRefresh()        => _storage.delete(key: _refreshKey);
}
```

## 2. Auth state (Riverpod)

```dart
// lib/auth/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

enum Role { customer, creator, vendor }

@freezed
class AccountInfo with _$AccountInfo {
  const factory AccountInfo({
    required String id,
    String? email,
    String? phoneE164,
    required String displayName,
    required String locale,         // en-US | zh | ne | es | hi
  }) = _AccountInfo;
  factory AccountInfo.fromJson(Map<String, dynamic> json) =>
      _$AccountInfoFromJson(json);
}

@freezed
class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState({
    String? accessToken,
    AccountInfo? account,
    @Default([]) List<Role> roles,
    Role? activeRole,
  }) = _AuthState;

  bool get isAuthenticated => accessToken != null && account != null;
}
```

```dart
// lib/auth/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_state.dart';
import 'secure_storage.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState();

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    required AccountInfo account,
    required List<Role> roles,
    required Role activeRole,
  }) async {
    await SecureStore.setRefresh(refreshToken);
    state = AuthState(
      accessToken: accessToken,
      account: account,
      roles: roles,
      activeRole: activeRole,
    );
  }

  Future<void> setAccessToken(String token) async {
    state = state.copyWith(accessToken: token);
  }

  Future<void> setActiveRole(Role role) async {
    state = state.copyWith(activeRole: role);
  }

  Future<void> clear() async {
    await SecureStore.clearRefresh();
    state = const AuthState();
  }
}
```

## 3. Four sign-in paths

### 3.1 Password (existing user)

```
POST /v1/auth/login
{
  "emailOrPhone": "alice@example.com",
  "password":     "<plaintext>"
}
→ 200 AuthResponseDto
```

UI: `lib/features/shared/sign_in/sign_in_page.dart`. Form with
single field "Email or phone" + password field + "Forgot?" link.

```dart
final passwordLogin = ref.read(authMutationsProvider).passwordLogin;
final result = await passwordLogin(emailOrPhone, password);
result.when(
  data: (data) async {
    await ref.read(authProvider.notifier).setTokens(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      account: data.account,
      roles: data.roles,
      activeRole: data.activeRole,
    );
    if (mounted) context.go('/home');
  },
  error: (err, _) => showErrorSnack(context, err),
  loading: () {},
);
```

Error codes to surface inline:
- `auth.invalid_credentials` → "We couldn't find that account."
- `auth.account_locked`     → "Account locked. Try again in N minutes."
- `auth.mfa_required`       → trigger MFA flow (see §7)

### 3.2 Phone OTP (passwordless or new-account)

```
POST /v1/auth/login-otp/request  { "phoneE164": "+9779812345678" }
→ 200 { "otpId": "...", "expiresUtc": "...", "devPlaintextCode": "12345"? }   // devPlaintextCode is dev-only
```

**SMS arrives with a 5-digit code** (NOT 6 — locked spec).

UI: `lib/features/shared/otp/otp_page.dart` — five separate
`TextField`s with FocusNode auto-advance, auto-submit when all
five filled.

```
POST /v1/auth/login-otp/verify   { "otpId": "...", "code": "12345" }
→ 200 AuthResponseDto
```

Error codes:
- `otp.invalid_code`    → "That code is wrong. Try again."
- `otp.expired`         → "Code expired. Resend?"
- `otp.too_many_attempts` → 429 with `Retry-After` header — disable resend, show countdown.

**Resend** uses the same `request` endpoint with a fresh
`Idempotency-Key`. Backend rate-limits (typically 1/min/phone) —
disable the "Resend" button for 60 s after each request.

### 3.3 Email magic link

```
POST /v1/auth/login-magic/request  { "email": "alice@example.com" }
→ 200 { "tokenId": "...", "expiresUtc": "..." }
```

Backend sends email with a deep link of the form:

```
stylemint://auth/magic?tokenId=abc123&token=xyz...
```

(Universal link variant also configured: `https://stylemint.app/auth/magic?...`)

UI: `lib/features/shared/sign_in/magic_link_sent_page.dart` shows
"Check your email" with "Open mail app" shortcut and a "Wrong
email?" link.

**Deep-link consumer** lives in `routes/app_router.dart` as a
`GoRoute` redirect:

```dart
// lib/routes/app_router.dart (excerpt)
GoRoute(
  path: '/auth/magic',
  redirect: (ctx, state) async {
    final tokenId = state.uri.queryParameters['tokenId'];
    final token   = state.uri.queryParameters['token'];
    if (tokenId == null || token == null) return '/sign-in?error=magic_invalid';

    final container = ProviderScope.containerOf(ctx);
    final mutations = container.read(authMutationsProvider);
    final result    = await mutations.magicLinkVerify(tokenId: tokenId, token: token);

    return result.when(
      data: (data) async {
        await container.read(authProvider.notifier).setTokens(...);
        return '/home';
      },
      error: (_, __) => '/sign-in?error=magic_failed',
      loading: () => null,        // shouldn't happen — verify is await-ed
    );
  },
),
```

The verify endpoint:

```
POST /v1/auth/login-magic/verify  { "tokenId": "...", "token": "..." }
→ 200 AuthResponseDto
```

### 3.4 Passkey (WebAuthn)

For returning users with a registered platform passkey. Uses
biometrics (Face ID / Touch ID / Android biometric) via `local_auth`
+ a custom WebAuthn exchange against `/v1/passkeys/{begin,finish}`.

```
1. POST /v1/passkeys/begin/assert  { "accountHint": "<emailOrPhone>"? }
   → 200 { challenge, allowCredentials, rpId, timeoutMs }

2. (Dart) await PasskeyClient.assert(...)
   → { credentialId, authenticatorData, clientDataJSON, signature, userHandle }

3. POST /v1/passkeys/finish/assert  { ...credential... }
   → 200 AuthResponseDto
```

There is no first-party Flutter WebAuthn package yet. Two options:

- **MethodChannel bridge** — write a small platform plugin
  (`ASAuthorizationPlatformPublicKeyCredentialProvider` on iOS,
  `CredentialManager` on Android API 28+).
- **Defer to v1.2** — ship OTP + magic link at launch; add passkey
  as a 30-day post-launch follow-up.

OTP + magic link cover the v1.1 launch surface; passkey is the
30-day post-launch follow-up. Document the placeholder route in
the router but don't wire it on day one.

## 4. JWT shape (decode on client; do not verify — server already did)

```json
{
  "sub":          "<accountId-guid>",
  "iss":          "stylemint",
  "aud":          "stylemint-clients",
  "exp":          1735680000,
  "iat":          1735679100,
  "session_id":   "<guid>",
  "jti":          "<guid>",
  "roles":        ["Customer", "Creator"],
  "active_role":  "Customer",
  "email":        "alice@example.com",
  "phone_verified": true,
  "email_verified": true,
  "device_id":    "<guid>"
}
```

```dart
// lib/auth/jwt.dart
import 'dart:convert';

class JwtClaims {
  JwtClaims._(this.raw);
  final Map<String, dynamic> raw;

  String get sub                => raw['sub']           as String;
  int    get exp                => raw['exp']           as int;
  List<String> get roles        => (raw['roles'] as List).cast<String>();
  String get activeRole         => raw['active_role']   as String;
  String? get email             => raw['email']         as String?;
  String  get sessionId         => raw['session_id']    as String;
  String  get jti               => raw['jti']           as String;

  static JwtClaims decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Not a JWT');
    final payload = parts[1].padRight((parts[1].length + 3) & ~3, '=');
    final json = utf8.decode(base64Url.decode(payload));
    return JwtClaims._(jsonDecode(json) as Map<String, dynamic>);
  }
}
```

## 5. Refresh on 401

Dio interceptor handles silent refresh, with dedupe so 5 parallel
401s only refresh once:

```dart
// lib/api/refresh.dart
import 'dart:async';
import 'package:dio/dio.dart';

class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._dio, this._ref);
  final Dio _dio;
  final Ref _ref;
  Completer<String>? _inFlight;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final code = (response?.data is Map) ? response!.data['errorCode'] as String? : null;

    final isUnauthorized = response?.statusCode == 401;
    final isRetry        = err.requestOptions.extra['_retried'] == true;
    final isRefreshCall  = err.requestOptions.path.endsWith('/v1/auth/refresh');

    if (!isUnauthorized || isRetry || isRefreshCall) {
      return handler.next(err);
    }

    try {
      final fresh = await _refreshAccess();
      final req   = err.requestOptions;
      req.headers['Authorization'] = 'Bearer $fresh';
      req.extra['_retried'] = true;
      final retry = await _dio.fetch(req);
      return handler.resolve(retry);
    } catch (_) {
      await _ref.read(authProvider.notifier).clear();
      // GoRouter listenable on auth state will redirect to /welcome
      return handler.next(err);
    }
  }

  Future<String> _refreshAccess() {
    if (_inFlight != null) return _inFlight!.future;
    final c = _inFlight = Completer<String>();
    _doRefresh().then(c.complete).catchError(c.completeError)
      .whenComplete(() => _inFlight = null);
    return c.future;
  }

  Future<String> _doRefresh() async {
    final refresh = await SecureStore.getRefresh();
    if (refresh == null) throw StateError('no_refresh');
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: { 'refreshToken': refresh },
      options: Options(headers: { 'Idempotency-Key': const Uuid().v4() }),
    );
    final data = res.data!;
    await SecureStore.setRefresh(data['refreshToken'] as String);
    await _ref.read(authProvider.notifier)
      .setAccessToken(data['accessToken'] as String);
    return data['accessToken'] as String;
  }
}
```

**Refresh rotates** — every refresh returns a new refresh token; the
old one is server-side revoked. Write the new one to secure storage
before returning.

If refresh itself returns 401 (`auth.refresh_revoked` — admin
force-logout, or token theft detected), force re-login:

```dart
catch (err) {
  final code = (err is DioException && err.response?.data is Map)
      ? err.response!.data['errorCode'] as String?
      : null;
  if (code == 'auth.refresh_revoked') {
    await ref.read(authProvider.notifier).clear();
    if (mounted) context.go('/welcome?reason=revoked');
  }
}
```

## 6. Role switching

The same JWT carries `roles: ["Customer", "Creator"]` and
`active_role: "Customer"`. Switching the active role re-mints the
JWT with a new `active_role` claim — necessary because many
endpoints require the active role (e.g.
`POST /v1/creator/reels/import` rejects if `active_role != Creator`).

```
POST /v1/accounts/{accountId}/roles/{role}/activate
→ 204
```

Then **immediately refresh** to get a JWT with the new
`active_role`:

```dart
Future<void> switchRole(WidgetRef ref, Role role) async {
  final auth = ref.read(authProvider);
  final accountId = auth.account!.id;
  final api = ref.read(apiClientProvider);

  await api.post(
    '/v1/accounts/$accountId/roles/${role.name}/activate',
    options: Options(headers: { 'Idempotency-Key': const Uuid().v4() }),
  );

  // Force-refresh to pick up the new active_role claim
  final fresh = await ref.read(refreshInterceptorProvider).refreshAccess();
  await ref.read(authProvider.notifier).setActiveRole(role);
}
```

**Tabs are role-aware** — `lib/features/shared/scaffold/main_scaffold.dart`
watches `activeRole` and renders the right set:

```dart
class MainScaffold extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final role = ref.watch(authProvider.select((s) => s.activeRole));
    final tabs = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home),     label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.search),   label: 'Discover'),
      if (role == Role.customer)
        const NavigationDestination(icon: Icon(Icons.movie),  label: 'Reels'),
      if (role == Role.customer || role == Role.creator)
        const NavigationDestination(icon: Icon(Icons.shop),   label: 'Cart'),
      if (role == Role.creator)
        const NavigationDestination(icon: Icon(Icons.brush),  label: 'Studio'),
      if (role == Role.vendor)
        const NavigationDestination(icon: Icon(Icons.store),  label: 'Vendor'),
      const NavigationDestination(icon: Icon(Icons.person),   label: 'Profile'),
    ];
    return Scaffold(/* ... */);
  }
}
```

## 7. MFA (post-login step-up — distinct from admin step-up)

Some sensitive end-user mutations (delete account, change email,
add payout method) trigger an MFA challenge. The pattern is a
modal `showDialog` that the mutation `await`s:

```
POST /v1/auth/mfa/challenge   { "intent": "delete-account" }
→ 200 { "mfaSessionId": "...", "methods": ["totp", "sms-otp"] }

POST /v1/auth/mfa/verify      { "mfaSessionId": "...", "method": "...", "code": "..." }
→ 204 (session stamped fresh for ~5 min)
```

Wrap sensitive mutations with a `runWithMfaStepUp` helper:

```dart
Future<T> runWithMfaStepUp<T>(
  WidgetRef ref,
  BuildContext ctx, {
  required String intent,
  required Future<T> Function() action,
}) async {
  try {
    return await action();
  } on DioException catch (e) {
    final code = (e.response?.data is Map) ? e.response!.data['errorCode'] : null;
    if (code != 'auth.mfa.step_up_required') rethrow;
    final challenge = await ref.read(apiClientProvider).post(
      '/v1/auth/mfa/challenge', data: { 'intent': intent });
    final verified = await showMfaDialog(ctx, mfaSessionId: challenge.data['mfaSessionId']);
    if (!verified) throw const _CancelledByUser();
    return await action();   // retry once
  }
}
```

## 8. Logout

```
POST /v1/auth/logout         → revoke current session
POST /v1/auth/logout-all     → revoke every session for this account
```

Always also:

```dart
Future<void> logout(WidgetRef ref, BuildContext ctx) async {
  await ref.read(apiClientProvider).post(
    '/v1/auth/logout',
    options: Options(headers: { 'Idempotency-Key': const Uuid().v4() }),
  );
  await ref.read(authProvider.notifier).clear();
  await SharedPreferences.getInstance()
    ..remove('activeRole');
  if (ctx.mounted) ctx.go('/welcome');
}
```

## 9. Cold-start sequence

```
1. main() runs → ProviderScope → MaterialApp.router(go_router)
2. GoRouter `refreshListenable` watches authProvider
3. authBootstrapProvider FutureProvider runs once at startup:
     - reads SecureStore for refreshToken
     - if present: POST /v1/auth/refresh once
       - on success: populate auth state, GoRouter redirects to /home
       - on failure: clear SecureStore, GoRouter redirects to /welcome
     - if absent: GoRouter redirects to /welcome
4. While bootstrap is running, show a Splash screen (≤ 500 ms target)
```

```dart
// lib/auth/bootstrap.dart
@Riverpod(keepAlive: true)
Future<void> authBootstrap(AuthBootstrapRef ref) async {
  final refresh = await SecureStore.getRefresh();
  if (refresh == null) return;
  try {
    final api = ref.read(apiClientProvider);
    final res = await api.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: { 'refreshToken': refresh },
      options: Options(headers: { 'Idempotency-Key': const Uuid().v4() }),
    );
    final data = res.data!;
    await ref.read(authProvider.notifier).setTokens(
      accessToken:  data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      account:      AccountInfo.fromJson(data['account']),
      roles:        (data['roles'] as List).cast<String>().map(_parseRole).toList(),
      activeRole:   _parseRole(data['activeRole'] as String),
    );
  } catch (_) {
    await SecureStore.clearRefresh();
  }
}
```

GoRouter wired with `redirect`:

```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(/* listen to auth provider stream */),
  redirect: (ctx, state) {
    final container = ProviderScope.containerOf(ctx);
    final isAuthed  = container.read(authProvider).isAuthenticated;
    final isAuthRoute = state.uri.path.startsWith('/welcome')
                     || state.uri.path.startsWith('/sign-in')
                     || state.uri.path.startsWith('/otp')
                     || state.uri.path.startsWith('/auth/');
    if (!isAuthed && !isAuthRoute) return '/welcome';
    if ( isAuthed &&  isAuthRoute && !state.uri.path.startsWith('/auth/magic')) return '/home';
    return null;
  },
  // ... routes
)
```

## 10. Edge cases

- **App backgrounded for >15 min** — access token expires. Next API
  call returns 401; interceptor refreshes silently. User never
  notices unless refresh itself fails.
- **No network at cold start** — refresh fails with network error
  (not 401). Show "offline" banner, allow viewing cached screens
  (Riverpod cache persists per `keepAlive: true`), block mutations.
- **User changes phone/email mid-session** — backend revokes all
  sessions. Mobile sees `auth.refresh_revoked` on next refresh,
  kicks to welcome.
- **Multiple devices** — each device gets its own session row. The
  "Devices" screen (`stylemint-identity` §5) lists active sessions
  and lets the user revoke individual ones.
- **Magic link tapped on a device where the app isn't installed** —
  universal link opens the App Store / Play Store; on next install
  the magic-link consumer redirects post-launch via the
  `uni_links` / `app_links` package's pending URL.
- **Deep link tapped while logged out** — store the intended URL in
  `shared_preferences`, complete auth, redirect to the stored URL
  post-login.

  ```dart
  final pending = (await SharedPreferences.getInstance()).getString('pendingDeepLink');
  if (isAuthed && pending != null) {
    context.go(pending);
    (await SharedPreferences.getInstance()).remove('pendingDeepLink');
  }
  ```

## 11. Required Identity endpoints (cheat sheet)

Full set in `stylemint-identity` SKILL.md. Mobile needs:

| Endpoint | Use |
|---|---|
| `POST /v1/registration` | New account (email or phone) |
| `POST /v1/auth/login` | Password sign-in |
| `POST /v1/auth/login-otp/{request,verify}` | Phone OTP sign-in |
| `POST /v1/auth/login-magic/{request,verify}` | Email magic link |
| `POST /v1/passkeys/begin/{register,assert}` + `/finish/{register,assert}` | Passkey |
| `POST /v1/auth/refresh` | Token refresh |
| `POST /v1/auth/logout` / `/logout-all` | Logout |
| `POST /v1/auth/mfa/{challenge,verify}` | Step-up MFA |
| `GET  /v1/accounts/me` | Bootstrap profile |
| `GET  /v1/accounts/{id}/roles` | List role profiles |
| `POST /v1/accounts/{id}/roles` | Request a new role (Creator/Vendor) |
| `POST /v1/accounts/{id}/roles/{role}/activate` | Switch active role |
| `POST /v1/devices` | Register FCM token |
| `POST /v1/oauth/{google,apple,facebook}/begin` + `/finish` | Social login |
