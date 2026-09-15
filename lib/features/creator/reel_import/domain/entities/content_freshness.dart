// Pure-Dart `immutable` (re-exported from package:meta); no Flutter import.
import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

/// Why a connected account's posts could not be read live, grouped by what
/// the creator can do about it.
enum ContentProviderIssue {
  /// The provider is throttling calls — retry later.
  rateLimited,

  /// The provider could not be reached — retry later.
  unavailable,

  /// The stored connection no longer works — reconnect the account.
  reconnect,

  /// The provider refused because a permission was not granted — reconnect
  /// and allow access again.
  permissionMissing,

  /// No connected account for this platform.
  notConnected;

  /// Maps a backend error code (the `errorCode` of an error body, or
  /// `providerStatus.code` of a page) to an issue. Returns null for codes that
  /// are not provider problems (e.g. `validation.*`).
  static ContentProviderIssue? fromCode(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return switch (normalized) {
      'RATE_LIMITED' || 'SYSTEM.RATE_LIMITED' => rateLimited,
      'PROVIDER_UNAVAILABLE' => unavailable,
      'TOKEN_INVALID' ||
      'TOKEN_EXPIRED' ||
      'TOKEN_REVOKED' ||
      'INVALID_GRANT' ||
      'SCOPE_NARROWED' ||
      'PROVIDER_ACCOUNT_DELETED' => reconnect,
      'PERMISSION_MISSING' => permissionMissing,
      'RESOURCE.NOT_FOUND' => notConnected,
      _ => null,
    };
  }

  /// True when the fix is sending the creator back to the connect screen.
  bool get needsReconnect => this == reconnect || this == permissionMissing;
}

/// Provider problem reported alongside a page of posts.
@immutable
class ContentProviderStatus {
  const ContentProviderStatus({
    required this.code,
    this.message = '',
    this.retryAfterUtc,
  });

  /// Backend code such as `RATE_LIMITED` or `TOKEN_EXPIRED`.
  final String code;

  /// Backend's own sentence. The UI prefers its own copy keyed on [issue].
  final String message;

  /// Earliest time a live refresh will be attempted; null when the creator
  /// has to reconnect instead.
  final DateTime? retryAfterUtc;

  ContentProviderIssue? get issue => ContentProviderIssue.fromCode(code);

  @override
  bool operator ==(Object other) =>
      other is ContentProviderStatus &&
      other.code == code &&
      other.message == message &&
      other.retryAfterUtc == retryAfterUtc;

  @override
  int get hashCode => Object.hash(code, message, retryAfterUtc);
}

/// Where a page of posts came from. The default value describes a live read
/// from a server that does not report freshness at all.
@immutable
class ContentFreshness {
  const ContentFreshness({
    this.servedFromCache = false,
    this.fetchedUtc,
    this.staleSinceUtc,
    this.providerStatus,
  });

  /// True when the posts are the saved copy rather than a live provider call.
  final bool servedFromCache;

  /// When the provider was last read successfully for this account.
  final DateTime? fetchedUtc;

  /// When the saved posts stopped being fresh; null while fresh or live.
  final DateTime? staleSinceUtc;

  /// Why the provider was not (or could not be) read live.
  final ContentProviderStatus? providerStatus;

  /// True when a live refresh should not be attempted before
  /// [ContentProviderStatus.retryAfterUtc].
  bool isRefreshBlockedAt(DateTime now) {
    final retryAfter = providerStatus?.retryAfterUtc;
    return retryAfter != null && retryAfter.isAfter(now);
  }

  ContentFreshness withProviderStatus(ContentProviderStatus? status) =>
      ContentFreshness(
        servedFromCache: servedFromCache,
        fetchedUtc: fetchedUtc,
        staleSinceUtc: staleSinceUtc,
        providerStatus: status,
      );

  @override
  bool operator ==(Object other) =>
      other is ContentFreshness &&
      other.servedFromCache == servedFromCache &&
      other.fetchedUtc == fetchedUtc &&
      other.staleSinceUtc == staleSinceUtc &&
      other.providerStatus == providerStatus;

  @override
  int get hashCode =>
      Object.hash(servedFromCache, fetchedUtc, staleSinceUtc, providerStatus);
}
