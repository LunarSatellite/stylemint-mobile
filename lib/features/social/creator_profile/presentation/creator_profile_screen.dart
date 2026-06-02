import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Display info handed to [CreatorProfileScreen] via go_router `extra`. The
/// header renders from these (no public creator-profile endpoint exists yet);
/// live follower/following counts + follow state come from
/// `GET /v1/follows/{accountId}/stats`.
class CreatorProfileArgs {
  const CreatorProfileArgs({
    required this.accountId,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
  });

  final String accountId;
  final String displayName;
  final String handle;
  final String? avatarUrl;
}

/// A creator's public profile: avatar/name/handle header, live follower &
/// following counts, and a follow button whose initial state is seeded from the
/// stats call's `isFollowedByViewer`. The one consumer of [FollowNotifier.seed].
class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({required this.args, super.key});

  final CreatorProfileArgs args;

  @override
  ConsumerState<CreatorProfileScreen> createState() =>
      _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  late Future<FollowStats> _statsFuture;
  bool _seeded = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<FollowStats> _loadStats() async {
    final stats = await ref.read(followApiProvider).stats(widget.args.accountId);
    if (!_seeded) {
      _seeded = true;
      ref
          .read(followNotifierProvider.notifier)
          .seed(widget.args.accountId, following: stats.isFollowedByViewer);
    }
    return stats;
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref.read(followNotifierProvider.notifier).toggle(widget.args.accountId);
      // Refresh counts to reflect the change.
      setState(() => _statsFuture = ref
          .read(followApiProvider)
          .stats(widget.args.accountId));
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final following = ref.watch(followNotifierProvider).contains(args.accountId);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(args.handle.isNotEmpty ? '@${args.handle}' : 'Creator',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 96,
                height: 96,
                child: (args.avatarUrl == null || args.avatarUrl!.isEmpty)
                    ? Container(
                        color: DesignTokens.bgAppBodyLight,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person,
                            size: 40, color: DesignTokens.iconLight))
                    : Image.network(args.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: DesignTokens.bgAppBodyLight,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person,
                                  size: 40, color: DesignTokens.iconLight),
                            )),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              args.displayName.isNotEmpty ? args.displayName : '@${args.handle}',
              style: DesignTokens.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (args.handle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('@${args.handle}',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted)),
            ],
            const SizedBox(height: DesignTokens.s24),
            FutureBuilder<FollowStats>(
              future: _statsFuture,
              builder: (context, snap) {
                final stats = snap.data;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Count(
                        label: 'Followers',
                        value: stats == null ? '—' : _compact(stats.followers)),
                    const SizedBox(width: DesignTokens.s32),
                    _Count(
                        label: 'Following',
                        value: stats == null ? '—' : _compact(stats.following)),
                  ],
                );
              },
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: _FollowButton(
                following: following,
                busy: _toggling,
                onTap: _toggle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: DesignTokens.titleMedium),
        Text(label,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textMuted)),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton(
      {required this.following, required this.busy, required this.onTap});
  final bool following;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignTokens.buttonHeight,
      child: Material(
        color: following ? DesignTokens.bgAppBodyLight : DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        shape: following
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                side: const BorderSide(color: DesignTokens.borderDefault))
            : null,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: DesignTokens.primaryGreen))
                : Text(
                    following ? 'Following' : 'Follow',
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: following
                          ? DesignTokens.textLight
                          : DesignTokens.buttonPrimaryText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
