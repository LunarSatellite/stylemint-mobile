# Wiring Creator Social-Connect OAuth (Instagram / Facebook / TikTok / YouTube)

How to make the "Connect Instagram/Facebook/…" button actually complete the OAuth
round-trip and return to the app. **No code is committed by this doc — it's the
implementation plan.** Feature lives in `lib/features/creator/social_connect/`.

> Backend is live and verified: `POST /v1/social/connect/{provider}/begin` returns a real
> authorize URL; the backend exchanges the code server-side on its `/callback` and then
> **302-redirects to `stylemint://social-connected?provider=…&status=ok|error`** (backend
> `Social:AppReturnUrl`). The app's job is: open the authorize URL in an in-app browser,
> catch that `stylemint://social-connected` redirect, close the browser, refresh accounts.

---

## 1. Why the current code doesn't work

The existing `social_connect` flow was built against an **imagined** contract and is wrong on
three counts:

| Current (wrong) | Reality |
|---|---|
| `connectPlatform(platform, authCode, redirectUri)` posts `{platform, authCode, redirectUri}` to `/begin` | `/begin` takes **no `authCode`** and **no body fields**; the app never sees the auth code — the **backend** exchanges it server-side |
| Expects `/begin` to return a `SocialAccountDto` | `/begin` returns **`{ url, state, expiresUtc, provider }`** (the authorize URL) |
| `social_connect_screen.dart` calls `notifier.connect(platform, 'auth_code')` with a literal placeholder | There is no client-side auth code at all |
| No step that opens the authorize URL or handles the return | The OAuth browser step + deep-link return are entirely missing |

So the connect button currently posts garbage to `/begin` and never opens a browser.

## 2. The correct flow

```
[Connect tapped]
  → POST /v1/social/connect/{provider}/begin   (auth header, Idempotency-Key, body {})
  → 200 { url, state, ... }
  → open `url` in an IN-APP browser tab (Custom Tab / SFSafariViewController)
  → user approves on Meta
  → Meta → backend /callback (https)         [backend exchanges code, stores encrypted token]
  → backend 302 → stylemint://social-connected?provider=instagram&status=ok
  → app_links deep-link listener catches it
  → close the in-app browser + refresh GET /v1/social/accounts
```

The app **never** handles `code`/`client_secret`. It only: (a) opens the URL, (b) reacts to the
`stylemint://social-connected` return.

## 3. Approach decision — reuse `app_links`, NOT `flutter_web_auth_2`

This app already has:
- `app_links: ^7.0.0` (deep-link listener) + go_router,
- the **`stylemint://` custom scheme registered** in `AndroidManifest.xml` (MainActivity
  intent-filter) and iOS `Info.plist` (`CFBundleURLSchemes`),
- `url_launcher: ^6.3.1`.

`flutter_web_auth_2` would want to **own the `stylemint://` scheme** with its own
`CallbackActivity`, which **conflicts** with MainActivity already claiming it. So the
conflict-free, no-new-dependency approach is:

- **Open** the authorize URL with `url_launcher` using **`LaunchMode.inAppBrowserView`**
  (Chrome Custom Tab on Android, `SFSafariViewController` on iOS) → the auth window opens
  **on the device, over the app** (the in-app UX you want).
- **Return** is handled by the **existing `app_links`** listener catching
  `stylemint://social-connected`, then `closeInAppWebView()` + refresh.

No scheme registration changes needed — `stylemint://` is already wired.

## 4. File-by-file changes

### 4.1 `data/datasources/social_connect_remote_datasource.dart`
- **Replace** `connectPlatform(...)` (the one posting `authCode`) with a `beginConnect`:
  ```
  Future<SocialAuthorizeUrlDto> beginConnect({
    required String platform,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/social/connect/$platform/begin',
      data: const <String, dynamic>{},                 // empty body — NO authCode/redirectUri
      options: _idempotent(idempotencyKey),
    );
    return SocialAuthorizeUrlDto.fromJson(response as Map<String, dynamic>);
  }
  ```
- Keep `getConnectedAccounts()` and `disconnectPlatform()` as-is.
- **Note:** `disconnectPlatform` currently calls `DELETE /v1/social/accounts/{accountId}`.
  Verify against backend — the documented disconnect is `DELETE /v1/social/accounts/{provider}`
  (by provider slug), not account id. Confirm before shipping.

### 4.2 New model `data/models/social_authorize_url_dto.dart`
```
class SocialAuthorizeUrlDto {
  final String url;
  final String state;
  final String? expiresUtc;
  SocialAuthorizeUrlDto({required this.url, required this.state, this.expiresUtc});
  factory SocialAuthorizeUrlDto.fromJson(Map<String, dynamic> j) => SocialAuthorizeUrlDto(
    url: j['url'] as String,
    state: j['state'] as String,
    expiresUtc: j['expiresUtc'] as String?,
  );
}
```

### 4.3 `domain/repositories/social_connect_repository.dart`
- Replace `connectPlatform(platform, authCode, redirectUri)` with:
  ```
  Future<Either<NetworkExceptions, String>> beginConnect(SocialPlatform platform); // returns authorize url
  ```

### 4.4 `data/repositories/social_connect_repository_impl.dart`
- Implement `beginConnect` → call `remoteDataSource.beginConnect(platform: platform.name, idempotencyKey: const Uuid().v4())`, return `right(dto.url)`. Same DioException→NetworkExceptions mapping as the other methods.
- **`platform.name`** yields `instagram`/`facebook`/`tiktok`/`youtube` (matches the enum + backend slugs). Good.

### 4.5 `presentation/notifiers/social_connect_notifier.dart`
Replace `connect(platform, authCode)` with an orchestration method:
```
Future<void> connect(SocialPlatform platform) async {
  final urlEither = await _repository.beginConnect(platform);
  await urlEither.fold(
    (f) async => state = SocialConnectState.loadFailure(f),
    (url) async {
      // open in-app browser; the app_links listener handles the return
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      // do NOT await a result here — completion arrives via the deep link (4.7)
    },
  );
}

// called by the deep-link handler when stylemint://social-connected arrives
Future<void> onConnectReturn({required bool ok}) async {
  await closeInAppWebView();   // url_launcher: dismiss the Custom Tab / Safari sheet
  if (ok) await load();        // refresh GET /v1/social/accounts
}
```
Imports: `package:url_launcher/url_launcher.dart`.

### 4.6 `presentation/screens/social_connect_screen.dart`
- The screen currently only lists already-connected `accounts` and the connect button passes
  `'auth_code'`. You need a **list of all four platforms** with connect/disconnect state, and:
  ```
  onConnect: () => notifier.connect(platform),   // no authCode
  ```
- Drop the literal `'auth_code'`.

### 4.7 Deep-link return handler (reuse existing `app_links`)
Wherever the app already inits `app_links` / go_router deep-link handling, add a branch for the
OAuth return URI:
```
appLinks.uriLinkStream.listen((uri) {
  if (uri.scheme == 'stylemint' && uri.host == 'social-connected') {
    final ok = uri.queryParameters['status'] == 'ok';
    ref.read(socialConnectNotifierProvider.notifier).onConnectReturn(ok: ok);
    // optionally surface uri.queryParameters['error'] when !ok
  }
});
```
If go_router already routes `stylemint://` deep links, add a route/redirect for host
`social-connected` that calls `onConnectReturn` instead of navigating to a page.

## 5. No native changes required
`stylemint://` is already registered:
- Android: `android/app/src/main/AndroidManifest.xml` — MainActivity intent-filter `<data android:scheme="stylemint"/>` (already present).
- iOS: `ios/Runner/Info.plist` — `CFBundleURLSchemes` includes `stylemint` (already present).

Nothing to add. (This is exactly why we avoid `flutter_web_auth_2` — it would fight MainActivity for the scheme.)

## 6. Test checklist (on a device, against UAT)
1. Log in as a creator; open Social Connect.
2. Tap Connect Instagram → an in-app browser sheet opens **over the app** with the Instagram authorize page.
3. Approve as your **Meta roled/test user** (app is in Development mode until App Review).
4. Sheet auto-dismisses (or is closed by `onConnectReturn`) and you're back in the app.
5. The platform shows **Connected**; `GET /v1/social/accounts` lists it.
6. Repeat for Facebook. (TikTok/YouTube once their apps are registered.)

## 7. Gotchas
- **`flutter analyze` lies if codegen is stale** — run `dart run build_runner build --delete-conflicting-outputs` first (freezed notifier state).
- The connecting **Instagram** account must be Business/Creator linked to a Page; otherwise Meta errors in the browser before returning.
- In-app browser may not always auto-close on the deep link across OS versions — `closeInAppWebView()` in `onConnectReturn` forces it.
- Backend return is `stylemint://social-connected` (host = `social-connected`); make sure the existing deep-link handler doesn't swallow it as an unknown route.
