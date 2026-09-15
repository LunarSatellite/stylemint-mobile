import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Plain-words copy for saved posts and provider problems, shared by the
/// banner, the Import Reel error states and refresh snackbars.
abstract final class ContentFreshnessCopy {
  static const savedReels = 'Showing saved reels';
  static const reconnectLabel = 'Reconnect';

  /// "Showing saved reels · updated 12 min ago".
  static String savedHeadline(DateTime? fetchedUtc, DateTime now) =>
      fetchedUtc == null
      ? savedReels
      : '$savedReels · updated ${ago(fetchedUtc, now)}';

  /// "just now", "12 min ago", "3 hr ago", "2 days ago".
  static String ago(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
  }

  /// "3:25 PM" today, otherwise "Sep 15, 3:25 PM" — in the device timezone.
  static String clockTime(DateTime utc, DateTime now) {
    final local = utc.toLocal();
    final today = now.toLocal();
    final sameDay =
        local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
    return sameDay
        ? DateFormat.jm().format(local)
        : DateFormat('MMM d, h:mm a').format(local);
  }

  /// Short reason for the banner, without the retry time.
  static String reason(ContentProviderIssue? issue, SocialPlatform platform) {
    final name = platform.displayName;
    return switch (issue) {
      ContentProviderIssue.rateLimited =>
        '$name is limiting requests right now',
      ContentProviderIssue.unavailable => "$name isn't responding",
      ContentProviderIssue.reconnect => 'Reconnect $name to refresh',
      ContentProviderIssue.permissionMissing => '$name needs permission again',
      ContentProviderIssue.notConnected => '$name is not connected',
      null => "$name couldn't be refreshed",
    };
  }

  /// "Try again at 3:25 PM" when [retryAfterUtc] is still ahead, else null.
  static String? retryHint(DateTime? retryAfterUtc, DateTime now) =>
      retryAfterUtc != null && retryAfterUtc.isAfter(now)
      ? 'Try again at ${clockTime(retryAfterUtc, now)}'
      : null;

  /// Snackbar text when a pull to refresh was skipped until [retryAfterUtc].
  static String refreshBlocked(
    ContentProviderIssue? issue,
    SocialPlatform platform,
    DateTime retryAfterUtc,
    DateTime now,
  ) {
    final hint = 'Try again at ${clockTime(retryAfterUtc, now)}.';
    return switch (issue) {
      ContentProviderIssue.rateLimited ||
      ContentProviderIssue.unavailable => '${reason(issue, platform)}. $hint',
      _ => hint,
    };
  }

  /// Snackbar text when a refresh failed and the current list was kept.
  static String refreshFailed(
    NetworkExceptions failure,
    SocialPlatform platform,
  ) {
    final issue = ContentProviderIssue.fromCode(failure.validationCode);
    if (issue != null) return '${reason(issue, platform)}.';
    if (failure.isNoInternet) {
      return 'No internet connection. Showing what is saved.';
    }
    return "Couldn't refresh your ${platform.displayName} posts. "
        'Try again later.';
  }
}

/// Slim notice above the Import Reel grid explaining that the reels are the
/// saved copy and, when the provider reported a problem, why — with a
/// reconnect action when that is the fix. Renders nothing for a live page.
class ContentFreshnessBanner extends StatelessWidget {
  const ContentFreshnessBanner({
    required this.freshness,
    required this.platform,
    this.onReconnect,
    this.clock,
    super.key,
  });

  static const ValueKey<String> reconnectKey = ValueKey(
    'content_freshness_banner_reconnect',
  );

  final ContentFreshness freshness;
  final SocialPlatform platform;
  final VoidCallback? onReconnect;

  /// Injectable for tests; defaults to [DateTime.now].
  final DateTime Function()? clock;

  static bool isVisibleFor(ContentFreshness freshness) =>
      freshness.servedFromCache || freshness.providerStatus != null;

  @override
  Widget build(BuildContext context) {
    if (!isVisibleFor(freshness)) return const SizedBox.shrink();

    final now = (clock ?? DateTime.now)();
    final status = freshness.providerStatus;
    final issue = status?.issue;
    final hasProblem = status != null;
    final showReconnect =
        onReconnect != null && (issue?.needsReconnect ?? false);

    final lines = <String>[
      if (freshness.servedFromCache)
        ContentFreshnessCopy.savedHeadline(freshness.fetchedUtc, now),
      if (hasProblem) ContentFreshnessCopy.reason(issue, platform),
      if (hasProblem)
        ?ContentFreshnessCopy.retryHint(status.retryAfterUtc, now),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: hasProblem
            ? DesignTokens.warningFillDark
            : DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        border: Border.all(
          color: hasProblem
              ? DesignTokens.warning500.withValues(alpha: 0.35)
              : DesignTokens.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _icon(issue, hasProblem: hasProblem),
            size: 18,
            color: hasProblem
                ? DesignTokens.warning300
                : DesignTokens.textMuted,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Text(
                    lines[i],
                    style: DesignTokens.smallRegular.copyWith(
                      color: i == 0
                          ? (hasProblem
                                ? DesignTokens.warningTextLight
                                : DesignTokens.textLight)
                          : DesignTokens.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (showReconnect)
            TextButton(
              key: reconnectKey,
              onPressed: onReconnect,
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                ContentFreshnessCopy.reconnectLabel,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _icon(
    ContentProviderIssue? issue, {
    required bool hasProblem,
  }) {
    if (!hasProblem) return Icons.history_rounded;
    return switch (issue) {
      ContentProviderIssue.reconnect ||
      ContentProviderIssue.permissionMissing ||
      ContentProviderIssue.notConnected => Icons.link_off_rounded,
      ContentProviderIssue.unavailable => Icons.cloud_off_rounded,
      _ => Icons.schedule_rounded,
    };
  }
}
