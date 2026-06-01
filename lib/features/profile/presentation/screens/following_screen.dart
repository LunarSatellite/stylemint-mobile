import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';

class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(followingNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Following', style: DesignTokens.sectionInnerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
            child: TextFormField(
              controller: _searchCtrl,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Search following...',
                prefixIcon: const Icon(Icons.search, color: DesignTokens.inputFieldPlaceholder, size: 20),
              ),
              onChanged: (value) {
                ref.read(followingNotifierProvider.notifier).load(search: value);
              },
            ),
          ),
          Expanded(
            child: state.when(
              initial: _loadingBody,
              loadInProgress: _loadingBody,
              loadFailure: (failure) => Center(
                child: Text('Failed: ${failure.toString()}', style: DesignTokens.smallRegular),
              ),
              loadSuccess: (users) {
                if (users.isEmpty) {
                  return const SmEmptyState(
                    message: 'You are not following anyone yet.',
                    icon: Icons.group_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
                  itemBuilder: (_, i) => _UserTile(user: users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBody() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final FollowingUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: DesignTokens.bgAppBodyLight,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: DesignTokens.iconLight, size: 24)
                : null,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '@${user.handle} · ${user.followerCount} followers',
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(followingNotifierProvider.notifier).unfollow(user.id),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            ),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }
}
