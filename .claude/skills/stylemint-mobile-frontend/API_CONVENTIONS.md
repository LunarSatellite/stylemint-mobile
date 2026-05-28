# API Conventions — Style Mint Mobile (Flutter)

Companion to `SKILL.md`. Cross-cutting API patterns the mobile app
must follow. Every endpoint under `/v1/*` is shaped by these
conventions — learn them once, apply everywhere.

**Architecture context (Flutter 3.41.9 + Feature-First Clean Architecture):**
The call chain for every API call is:

```
Presentation (Riverpod provider)
  → domain/usecases/         # Either<Failure, T>; pure Dart
    → domain/repositories/   # abstract interface
      ← data/repositories/   # impl — converts Failure; calls datasource
        → data/datasources/  # raw Dio call; throws DioException
          → Dio client       # interceptors: auth, idempotency, correlation, retry
            → backend /v1/*
```

Dio and freezed DTOs are **data-layer only**. The domain and
presentation layers never import `package:dio`. The Failure sealed
class in `core/error/failure.dart` is the only error type that
crosses layer boundaries.

## 1. Dio client

```dart
// lib/api/client.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'client.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(ApiClientRef ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5020',
  );

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout:    const Duration(seconds: 20),
    headers: { 'Accept': 'application/json' },
  ));

  dio.interceptors.addAll([
    AuthHeaderInterceptor(ref),
    CorrelationInterceptor(),
    LocaleInterceptor(ref),
    RefreshInterceptor(dio, ref),    // see AUTH_FLOW §5
    LoggingInterceptor(),            // wrapped to scrub PII
  ]);

  return dio;
}

class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._ref);
  final Ref _ref;
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    final token = _ref.read(authProvider).accessToken;
    final isAuthEndpoint = opts.path.contains('/auth/login')
                        || opts.path.contains('/auth/refresh')
                        || opts.path.contains('/registration');
    if (token != null && !isAuthEndpoint) {
      opts.headers['Authorization'] = 'Bearer $token';
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

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._ref);
  final Ref _ref;
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    final locale = _ref.read(authProvider).account?.locale ?? 'en-US';
    opts.headers['Accept-Language'] = locale;
    handler.next(opts);
  }
}
```

## 2. ServiceResult / Problem Details

Every non-2xx response is RFC 7807 Problem Details. Model:

```dart
// lib/api/errors.dart
@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String type,
    required String title,
    required int status,
    required String errorCode,
    String? field,
    required String correlationId,
    List<FieldError>? errors,
  }) = _ApiError;
  factory ApiError.fromJson(Map<String, dynamic> json) => _$ApiErrorFromJson(json);
}

@freezed
class FieldError with _$FieldError {
  const factory FieldError({
    required String field,
    required String code,
    required String message,
  }) = _FieldError;
  factory FieldError.fromJson(Map<String, dynamic> json) => _$FieldErrorFromJson(json);
}

ApiError? apiErrorFrom(Object err) {
  if (err is DioException && err.response?.data is Map) {
    return ApiError.fromJson(Map<String, dynamic>.from(err.response!.data as Map));
  }
  return null;
}
```

**Always key on `errorCode`**, never on HTTP status or English
title. Map to i18n message keys:

```dart
// lib/api/errors.dart
String errorToI18nKey(Object err) {
  final api = apiErrorFrom(err);
  if (api == null) return 'errors.network';
  return 'errors.${api.errorCode}';
}

String errorToMessage(BuildContext ctx, Object err) {
  final key = errorToI18nKey(err);
  return AppLocalizations.of(ctx)!.translate(key, fallback: 'errors.unknown');
}
```

i18n ARB file (excerpt):

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en-US",
  "errors.network":                     "Check your connection and try again.",
  "errors.unknown":                     "Something went wrong.",
  "errors.auth.invalid_credentials":    "We couldn't find that account.",
  "errors.auth.token_expired":          "Please sign in again.",
  "errors.otp.invalid_code":            "That code is wrong.",
  "errors.otp.expired":                 "Code expired. Resend?",
  "errors.checkout.session_expired":    "Your checkout expired. Start over.",
  "errors.checkout.inventory_held":     "Items in your cart are reserved by someone else.",
  "errors.payment.insufficient_funds":  "Your payment was declined.",
  "errors.ratelimit.exceeded":          "Too many requests. Try again in a moment.",
  "errors.concurrency.conflict":        "Someone else updated this. Refresh.",
  "errors.validation.failed":           "Please check the highlighted fields."
}
```

## 3. Idempotency-Key

**Every mutation includes `Idempotency-Key: <uuid v4>`.** The backend
enforces this — missing key on a mutating endpoint causes a 400.

```dart
// lib/api/idempotency.dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newIdempotencyKey() => _uuid.v4();

// extension for convenience
extension IdempotentDio on Dio {
  Future<Response<T>> postIdempotent<T>(
    String path, {
    Object? data,
    Options? options,
  }) {
    final merged = (options ?? Options()).copyWith(headers: {
      ...?options?.headers,
      'Idempotency-Key': newIdempotencyKey(),
    });
    return post<T>(path, data: data, options: merged);
  }
}
```

Rule: **one key per user intent**, not per retry. If the Dio
interceptor re-sends the same request (refresh-then-retry path),
it re-uses the same headers — that's fine. If a network error and
the user re-taps, generate a new key.

```dart
// inside a Riverpod mutation:
@riverpod
class KycDecide extends _$KycDecide {
  @override
  AsyncValue<KycReviewItemDto> build() => const AsyncValue.data(null as dynamic);

  Future<void> call(String kycItemId, DecideKycVm body) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiClientProvider);
      final res = await dio.postIdempotent<Map<String, dynamic>>(
        '/v1/admin/kyc/$kycItemId/decide',
        data: body.toJson(),
      );
      // Invalidate dependent providers
      ref.invalidate(kycQueueProvider);
      ref.invalidate(kycDetailProvider(kycItemId));
      return KycReviewItemDto.fromJson(res.data!);
    });
  }
}
```

## 4. Pagination

Two shapes — pick based on the endpoint's documented shape (read
the backend skill for the module):

### 4.1 Cursor (`PagedResult<T>`) — feeds, infinite scroll

```dart
@freezed
class PagedResult<T> with _$PagedResult<T> {
  const factory PagedResult({
    required List<T> items,
    required int totalCount,
    required int pageSize,
    String? nextCursor,           // null = no more pages
    String? previousCursor,       // null on the first page
    required bool hasMore,        // hasMore == nextCursor != null
  }) = _PagedResult<T>;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PagedResultFromJson(json, fromJsonT);
}
```

`nextCursor` / `previousCursor` are opaque base64 — do not parse,
modify, or persist as anything other than an opaque string. Send
them back as the `cursor` query param on the next request.

Used for: reels feed, friend feed, comment threads, search results,
notification inbox, vendor briefs list, vendor activity, etc.

Riverpod pattern for an infinite feed:

```dart
// lib/api/queries/reels_feed_provider.dart
@riverpod
class ReelsFeed extends _$ReelsFeed {
  String? _nextCursor;
  final List<ReelDto> _accumulated = [];

  @override
  Future<List<ReelDto>> build() async {
    final page = await _fetchPage(null);
    _nextCursor = page.nextCursor;
    _accumulated
      ..clear()
      ..addAll(page.items);
    return List.unmodifiable(_accumulated);
  }

  Future<void> loadMore() async {
    if (_nextCursor == null) return;     // exhausted
    final page = await _fetchPage(_nextCursor);
    _nextCursor = page.nextCursor;
    _accumulated.addAll(page.items);
    state = AsyncValue.data(List.unmodifiable(_accumulated));
  }

  Future<PagedResult<ReelDto>> _fetchPage(String? cursor) async {
    final dio = ref.read(apiClientProvider);
    final res = await dio.get<Map<String, dynamic>>(
      '/v1/discovery/reels',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'pageSize': 20,
      },
    );
    return PagedResult<ReelDto>.fromJson(res.data!, (j) => ReelDto.fromJson(j as Map<String, dynamic>));
  }
}
```

Render with a `ListView.builder` + `NotificationListener` for
infinite scroll:

```dart
class ReelsFeedView extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final feed = ref.watch(reelsFeedProvider);
    return feed.when(
      data: (reels) => NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 500) {
            ref.read(reelsFeedProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: reels.length,
          itemBuilder: (_, i) => ReelCard(reel: reels[i]),
        ),
      ),
      error: (e, _) => ErrorView(error: e),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
```

### 4.2 Page (`PagedList<T>`) — admin-style lists

```dart
@freezed
class PagedList<T> with _$PagedList<T> {
  const factory PagedList({
    required List<T> items,
    required int totalCount,
    required int pageNumber,         // 1-based
    required int pageSize,
    required int totalPages,
    required bool hasPrevious,
    required bool hasNext,
  }) = _PagedList<T>;

  factory PagedList.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PagedListFromJson(json, fromJsonT);
}
```

Used for: order history, partnership list, settings, audit-style
screens.

## 5. Money

```dart
@freezed
class Money with _$Money {
  const factory Money({
    required double amount,         // decimal NPR; e.g. 1234.56 = Rs 1,234.56
    required String currency,       // ISO 4217, e.g. "NPR"
  }) = _Money;
  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);
}
```

Format in UI:

```dart
// lib/core/format_money.dart
import 'package:intl/intl.dart';

String formatMoney(Money m, {String? locale}) {
  if (m.currency == 'NPR') {
    final fmt = NumberFormat.currency(
      locale: locale ?? 'en_US', symbol: 'Rs ', decimalDigits: 2,
    );
    return fmt.format(m.amount);
  }
  return NumberFormat.currency(
    locale: locale ?? 'en_US', name: m.currency, decimalDigits: 2,
  ).format(m.amount);
}
```

**Never multiply by 100**. Backend's `Money` is decimal-typed
(`Postgres NUMERIC(18, 4)`), not minor-unit integer. Mismatched
currency arithmetic is a backend-side throw — the mobile app should
never construct Money from numbers; always read from the API.

## 6. Time

All API timestamps are UTC ISO 8601 (`"2026-05-26T08:42:31.123Z"`).
Dart parses them via `DateTime.parse(...)`.

```dart
// lib/core/format_date.dart
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void initTimezone() {
  tz_data.initializeTimeZones();
}

String formatRelative(DateTime iso) {
  // Use timeago or roll your own — Flutter doesn't have formatDistanceToNow
  final diff = DateTime.now().difference(iso);
  if (diff.inMinutes < 1)  return 'just now';
  if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
  if (diff.inDays < 1)     return '${diff.inHours}h ago';
  if (diff.inDays < 7)     return '${diff.inDays}d ago';
  return DateFormat.yMMMd().format(iso.toLocal());
}

String formatDateTime(DateTime iso, {String? localeTag}) {
  return DateFormat.yMd(localeTag).add_jm().format(iso.toLocal());
}

String formatInNpt(DateTime iso) {
  // For ops-context strings ("payout will be processed Friday 09:00 NPT")
  final npt = tz.getLocation('Asia/Kathmandu');
  final zoned = tz.TZDateTime.from(iso, npt);
  return '${DateFormat.yMd().add_jm().format(zoned)} NPT';
}
```

**Quiet Hours** (22:00–08:00 NPT default) are server-enforced for
push. The mobile app does not also suppress.

## 7. Retry

Riverpod retries failed providers if you wrap with `AsyncValue.guard`
and add explicit retry. Tune per route. The Dio refresh interceptor
handles 401 silently (see `AUTH_FLOW.md` §5).

For other transient errors, configure `dio_smart_retry`:

```dart
dio.interceptors.add(RetryInterceptor(
  dio: dio,
  retries: 2,
  retryDelays: const [
    Duration(milliseconds: 500),
    Duration(seconds:      2),
  ],
  retryEvaluator: (err, attempt) {
    final status = err.response?.statusCode;
    final code   = (err.response?.data is Map)
        ? err.response!.data['errorCode'] as String?
        : null;
    // Don't retry: auth failures, validation, not-found, rate limit
    if (status == 401 || status == 403 || status == 404) return false;
    if (status == 400 && (code?.startsWith('validation.') ?? false)) return false;
    if (status == 429) return false;     // honor Retry-After manually
    if (err.type == DioExceptionType.connectionError) return true;
    if ((status ?? 0) >= 500) return true;
    return false;
  },
));
```

**Mutations** do NOT retry automatically — they're user-driven; don't
silently retry.

On 429, read `Retry-After` header (seconds), surface a SnackBar, and
disable the trigger button for that duration. **Never auto-retry**
429 — backend rate-limiting is deliberate.

## 8. Offline

The mobile app must degrade gracefully when offline:

- **Reads**: Riverpod with `keepAlive: true` retains cached state
  across screens. Augment critical providers
  (`me`, `notification preferences`, `recent orders`) with manual
  persistence to `shared_preferences` on success.
- **Writes**: Block mutations with a clear "you're offline" banner.
  Do NOT queue mutations locally for replay — the order of writes
  matters (cart updates, checkout state) and silent replay can lead
  to surprising results. Exception: the **friend-feed compose
  draft** persists to `shared_preferences` and the user can post it
  when back online.
- **NetInfo**: `connectivity_plus` exposes online state — gate
  mutation buttons on it.

```dart
@Riverpod(keepAlive: true)
Stream<ConnectivityResult> connectivity(ConnectivityRef ref) =>
  Connectivity().onConnectivityChanged.map((list) => list.first);

// in a widget
final isOnline = ref.watch(connectivityProvider).valueOrNull
    .let((r) => r != null && r != ConnectivityResult.none);
ElevatedButton(
  onPressed: isOnline ? _placeOrder : null,
  child: const Text('Place Order'),
);
```

## 9. Correlation id

Every request carries `X-Correlation-Id` (uuid). The backend tags
every log line with it. Surface the correlation id in user-facing
error dialogs so support can trace:

```dart
showDialog(
  context: ctx,
  builder: (_) => AlertDialog(
    title: Text(AppLocalizations.of(ctx)!.checkoutSessionExpired),
    content: Text(AppLocalizations.of(ctx)!.supportWithId(error.correlationId)),
    actions: [
      TextButton(onPressed: () {/* copy id to clipboard */}, child: const Text('Copy ID')),
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
    ],
  ),
);
```

i18n: `"errors.supportWithId": "If this keeps happening, share this with support: {id}"`

## 10. Logging — PII redaction

Don't log:
- Raw passwords, OTP codes, magic-link tokens
- Full phone numbers (mask: `+977981****678`)
- Full email (mask: `a***e@example.com`)
- Card PAN, CVV (you'll never see these — backend never returns them)
- JWT contents (log only `jti` or first 8 chars of `sub`)

Sentry — install a `beforeSend` hook that scrubs URL query strings
(`token=...`) and request/response bodies for auth endpoints:

```dart
// lib/core/sentry_setup.dart
await SentryFlutter.init((options) {
  options.dsn = const String.fromEnvironment('SENTRY_DSN');
  options.beforeSend = (event, hint) {
    return event.copyWith(
      request: event.request?.copyWith(
        cookies: null,
        headers: _scrubHeaders(event.request?.headers ?? const {}),
        data:    _scrubBody(event.request?.data),
        url:     _scrubUrl(event.request?.url),
      ),
    );
  };
});
```

## 11. Headers cheat sheet

| Header | Direction | Purpose |
|---|---|---|
| `Authorization: Bearer <jwt>` | client → server | All authenticated endpoints |
| `Idempotency-Key: <uuid>` | client → server | All mutations |
| `X-Correlation-Id: <uuid>` | client → server | Per-request trace id |
| `Accept-Language: <locale>` | client → server | Hints localized text in responses (e.g. email/SMS templates) |
| `X-Vendor-Account-Id: <guid>` | client → server | Vendor-scoped endpoints when the caller is on multiple vendor teams. Solo-vendor case omits. See `stylemint-brand-studio-frontend` §2.3 for resolver rules. |
| `X-Correlation-Id: <uuid>` | server → client | Echoed back for surface display |
| `Retry-After: <seconds>` | server → client | 429 responses |
| `ETag`, `If-Match` | both | Reserved for future optimistic concurrency on specific endpoints — not used today |

## 12. Response shape consistency

The backend pattern is `result.ToActionResult()` — controllers
return either:

- `200 + DTO` on a successful read or mutation that produced data
- `204 No Content` on a successful mutation with no data to return
- `RFC 7807 Problem Details` on any failure

Mobile-side expectation: **never** assume a 200 means "success" —
the `data` field shape varies by endpoint, and a 200 always carries
a body (the DTO). 204 carries no body. Anything else is an error.

In Dio, declare the response type to enforce parsing:

```dart
final res = await dio.get<Map<String, dynamic>>('/v1/products/$id');
final product = ProductDetailDto.fromJson(res.data!);
```

For 204 returns, leave the response untyped and check status:

```dart
final res = await dio.post<void>('/v1/customer/reels/$id/like');
// res.statusCode == 204
```

## 13. Backend skills to read for endpoint specifics

When wiring an API call, read the matching backend skill:

- Identity / auth → `stylemint-identity`
- Onboarding / interests → `stylemint-onboarding`
- Catalog / products / brands / reviews → `stylemint-catalog`
- Reels / tagged products / comments → `stylemint-reels`
- Discovery / search / feed / trending → `stylemint-discovery`
- Cart / checkout → `stylemint-cart-checkout`
- Orders / sub-orders / returns → `stylemint-orders`
- Payments / refunds → `stylemint-payments`
- Payouts / earnings → `stylemint-payouts`
- Partnerships → `stylemint-partnerships`
- Support / tickets / notifications prefs → `stylemint-support`
- Messaging / push / SignalR → `stylemint-messaging`
- Social graph / drop parties / tips / group carts → `stylemint-social-graph`
- Reputation → `stylemint-reputation`
- Creator Studio (Pillar D) → `stylemint-creator-studio`
- Brand Studio (Pillar D) → `stylemint-brand-studio-frontend` (frontend API contract — read first) + `stylemint-brand-studio` (backend strategy)
- Audio (Pillar D) → `stylemint-audio`
- Reel Recipes (Pillar D) → `stylemint-reel-recipes`
- Reach / cross-platform publish (Pillar E) → `stylemint-reach`
- Matchmaking (Pillar E) → `stylemint-matchmaking`
- Social feed / stories (Pillar F) → `stylemint-social-feed`
- Recommendations (Pillar F) → `stylemint-recommendations`
- Networking / friends (Pillar F) → `stylemint-networking`
- Community / groups (Pillar F) → `stylemint-community`
- Delivery tracking (Pillar B) → `stylemint-delivery`
- Intelligence / signals (Pillar A) → `stylemint-intelligence` (mostly server-side)
