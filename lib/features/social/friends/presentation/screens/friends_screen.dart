import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/notifiers/friends_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/widgets/friend_request_tile.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/widgets/friend_tile.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          ref.read(friendsNotifierProvider.notifier).loadRequests();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(friendsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Friends', style: DesignTokens.sectionInnerTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.inputHeight + 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s8,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: DesignTokens.bodyText,
                  decoration: DesignTokens.inputDecoration(
                    hintText: 'Search friends...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: DesignTokens.textMuted,
                      size: DesignTokens.iconMedium,
                    ),
                  ),
                  onSubmitted: (value) {
                    ref.read(friendsNotifierProvider.notifier).loadFriends(
                      search: value.isEmpty ? null : value,
                    );
                  },
                ),
                const SizedBox(height: DesignTokens.s8),
                TabBar(
                  controller: _tabController,
                  indicatorColor: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.primaryGreen,
                  unselectedLabelColor: DesignTokens.textMuted,
                  labelStyle: DesignTokens.mediumSemibold,
                  unselectedLabelStyle: DesignTokens.mediumRegular,
                  tabs: const [
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(viewState),
          _buildRequestsTab(viewState),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(FriendsViewState viewState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s8,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: integrate with device contacts
                ref
                    .read(friendsNotifierProvider.notifier)
                    .importContacts(const []);
              },
              style: DesignTokens.outlinedButtonStyle(),
              icon: const Icon(
                Icons.contacts_outlined,
                color: DesignTokens.textWhite,
              ),
              label: const Text('Import Contacts'),
            ),
          ),
        ),
        Expanded(
          child: viewState.friendsState.when(
            initial: _loader,
            loadInProgress: _loader,
            loadSuccess: (friends, _, __) {
              if (friends.isEmpty) {
                return const SmEmptyState(
                  message: 'No friends yet. Invite your contacts!',
                  icon: Icons.people_outline,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const Divider(
                  color: DesignTokens.borderDefault,
                  height: 1,
                ),
                itemBuilder: (_, index) {
                  final friend = friends[index];
                  return FriendTile(
                    friend: friend,
                    onUnfriend: () => ref
                        .read(friendsNotifierProvider.notifier)
                        .unfriend(friend.userId),
                  );
                },
              );
            },
            loadFailure:
                (failure) => SmErrorView(
                  message: 'Failed to load friends.',
                  onRetry: () =>
                      ref
                          .read(friendsNotifierProvider.notifier)
                          .loadFriends(),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(FriendsViewState viewState) {
    return viewState.requestsState.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (requests) {
        final pending = requests.where((r) => r.status == 'pending').toList();
        if (pending.isEmpty) {
          return const SmEmptyState(
            message: 'No pending friend requests.',
            icon: Icons.person_add_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const Divider(
            color: DesignTokens.borderDefault,
            height: 1,
          ),
          itemBuilder: (_, index) {
            final request = pending[index];
            return FriendRequestTile(
              request: request,
              onAccept:
                  () =>
                      ref
                          .read(friendsNotifierProvider.notifier)
                          .accept(request.id),
              onDecline:
                  () =>
                      ref
                          .read(friendsNotifierProvider.notifier)
                          .decline(request.id),
            );
          },
        );
      },
      loadFailure:
          (failure) => SmErrorView(
            message: 'Failed to load requests.',
            onRetry: () =>
                ref.read(friendsNotifierProvider.notifier).loadRequests(),
          ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
