import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/creator_chip_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Follow Creators (customer discovery). Pixel-matched to the Customer
/// follow-creator screen. Lists suggested creators from
/// `GET /api/v1/customer/feed/creators-you-may-like`.
///
/// NOTE: the backend currently has NO follow/unfollow endpoint, so the Follow
/// toggle is local-only. TODO(follow-api): POST/DELETE follow once it exists.
final _suggestedCreatorsProvider =
    FutureProvider.autoDispose<List<CreatorChipDto>>((ref) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get(
    '/api/v1/customer/feed/creators-you-may-like',
    queryParameters: {'limit': 30},
  );
  final map = res as Map<String, dynamic>;
  final items = (map['items'] as List<dynamic>? ?? const <dynamic>[]);
  return items
      .whereType<Map<String, dynamic>>()
      .map(CreatorChipDto.fromJson)
      .toList(growable: false);
});

class FollowCreatorsDiscoveryScreen extends ConsumerStatefulWidget {
  const FollowCreatorsDiscoveryScreen({super.key});

  @override
  ConsumerState<FollowCreatorsDiscoveryScreen> createState() =>
      _FollowCreatorsDiscoveryScreenState();
}

class _FollowCreatorsDiscoveryScreenState
    extends ConsumerState<FollowCreatorsDiscoveryScreen> {
  final _followed = <String>{};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_suggestedCreatorsProvider);
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
        title: const Text('Discover Creators',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
        error: (_, __) => Center(
            child: Text("Couldn't load creators.", style: DesignTokens.bodyText)),
        data: (creators) => creators.isEmpty
            ? Center(
                child: Text('No suggestions right now.',
                    style: DesignTokens.bodyText))
            : ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: creators.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, i) {
                  final c = creators[i];
                  final following = _followed.contains(c.creatorProfileId);
                  return _CreatorRow(
                    creator: c,
                    following: following,
                    onToggle: () => setState(() {
                      if (following) {
                        _followed.remove(c.creatorProfileId);
                      } else {
                        _followed.add(c.creatorProfileId);
                      }
                    }),
                  );
                },
              ),
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({
    required this.creator,
    required this.following,
    required this.onToggle,
  });

  final CreatorChipDto creator;
  final bool following;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final avatar = creator.avatarUrl;
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: DesignTokens.avatarLarge,
            height: DesignTokens.avatarLarge,
            child: (avatar == null || avatar.isEmpty)
                ? Container(
                    color: DesignTokens.bgAppBodyLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.person,
                        color: DesignTokens.iconLight))
                : Image.network(avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: DesignTokens.bgAppBodyLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person,
                              color: DesignTokens.iconLight),
                        )),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(creator.displayName.isEmpty ? '@${creator.handle}' : creator.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold),
              const SizedBox(height: 2),
              Text(
                '${_compact(creator.followerCount)} followers • ${creator.reelCount} reels',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        _FollowButton(following: following, onTap: onToggle),
      ],
    );
  }

  String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          color: following ? DesignTokens.bgAppBodyLight : DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(999),
          border: following
              ? Border.all(color: DesignTokens.borderDefault)
              : null,
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: DesignTokens.smallRegular.copyWith(
            color: following ? DesignTokens.textLight : DesignTokens.buttonPrimaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
