import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/notifiers/groups_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/widgets/group_card.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:go_router/go_router.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'All',
    'Streetwear',
    'Vintage',
    'Minimalist',
    'Luxury',
    'Y2K',
    'Gorpcore',
    'K-pop',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(groupsNotifierProvider);
    final listState = viewState.listState;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Groups', style: DesignTokens.sectionInnerTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.buttonHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: TextField(
              controller: _searchController,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.textMuted,
                  size: DesignTokens.iconMedium,
                ),
              ),
              onSubmitted: (value) {
                ref
                    .read(groupsNotifierProvider.notifier)
                    .loadGroups(
                      search: value.isEmpty ? null : value,
                      category:
                          _selectedCategory == 'All' ? null : _selectedCategory,
                    );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s8,
              ),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: DesignTokens.s8),
              itemBuilder: (_, index) {
                final cat = _categories[index];
                final isSelected =
                    _selectedCategory == cat ||
                    (_selectedCategory == null && cat == 'All');
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    ref.read(groupsNotifierProvider.notifier).loadGroups(
                      category: cat == 'All' ? null : cat,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s8,
                    ),
                    decoration: isSelected
                        ? DesignTokens.chipDecorationSelected()
                        : DesignTokens.chipDecorationDefault(),
                    child: Text(
                      cat,
                      style: DesignTokens.smallRegular.copyWith(
                        color: isSelected
                            ? DesignTokens.primaryGreen
                            : DesignTokens.chipsDefaultText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: listState.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (groups) {
                if (groups.isEmpty) {
                  return const SmEmptyState(
                    message: 'No groups found.',
                    icon: Icons.group_outlined,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: DesignTokens.s12,
                    mainAxisSpacing: DesignTokens.s12,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (_, index) => GroupCard(
                    group: groups[index],
                    onTap: () => context.pushNamed(
                      RouteNames.groups,
                      pathParameters: {'groupId': groups[index].id},
                    ),
                    onJoin: () =>
                        ref
                            .read(groupsNotifierProvider.notifier)
                            .join(groups[index].id),
                  ),
                );
              },
              loadFailure:
                  (failure) => SmErrorView(
                    message: 'Failed to load groups.',
                    onRetry: () =>
                        ref
                            .read(groupsNotifierProvider.notifier)
                            .loadGroups(),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
