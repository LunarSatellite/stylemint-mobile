import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/widgets/creator_invite_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class InviteCreatorsScreen extends ConsumerStatefulWidget {
  const InviteCreatorsScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  ConsumerState<InviteCreatorsScreen> createState() =>
      _InviteCreatorsScreenState();
}

class _InviteCreatorsScreenState extends ConsumerState<InviteCreatorsScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  final _invitedIds = <String>{};

  static const _categories = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Food',
    'Tech',
    'Travel',
    'Home',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creatorSearchNotifierProvider.notifier).searchCreators();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(creatorSearchNotifierProvider);
    final inviteState = ref.watch(inviteCreatorNotifierProvider);
    final isInviting = inviteState.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    ref.listen<InviteState>(inviteCreatorNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creator invited!')),
          );
          ref.read(inviteCreatorNotifierProvider.notifier).reset();
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to invite creator')),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Invite Creators', style: DesignTokens.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: TextField(
              controller: _searchCtrl,
              style: DesignTokens.oneLinerRegular,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Search creators...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.inputFieldPlaceholder,
                ),
              ),
              onChanged: (val) {
                ref.read(creatorSearchNotifierProvider.notifier).searchCreators(
                  query: val,
                  categories:
                      _selectedCategory != null ? [_selectedCategory!] : null,
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    ref
                        .read(creatorSearchNotifierProvider.notifier)
                        .searchCreators(query: _searchCtrl.text);
                  },
                ),
                ..._categories.map(
                  (cat) => _FilterChip(
                    label: cat,
                    selected: _selectedCategory == cat,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      ref
                          .read(creatorSearchNotifierProvider.notifier)
                          .searchCreators(
                            query: _searchCtrl.text,
                            categories: [cat],
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Expanded(
            child: searchState.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (creators) {
                if (creators.isEmpty) {
                  return const SmEmptyState(
                    message: 'No creators found.',
                    icon: Icons.person_search_outlined,
                  );
                }
                final available = creators
                    .where((c) => !_invitedIds.contains(c.creatorId))
                    .toList();
                final invited = creators
                    .where((c) => _invitedIds.contains(c.creatorId))
                    .toList();
                return ListView(
                  children: [
                    if (invited.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s16,
                          vertical: DesignTokens.s8,
                        ),
                        child: Text(
                          'Already Invited',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ),
                      ...invited.map(
                        (c) => CreatorInviteTile(
                          invite: c,
                          isInviting: isInviting,
                          onInvite: null,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                    ],
                    ...available.map(
                      (c) => CreatorInviteTile(
                        invite: c,
                        isInviting: isInviting,
                        onInvite: () {
                          ref
                              .read(inviteCreatorNotifierProvider.notifier)
                              .invite(widget.campaignId, c.creatorId);
                          setState(() => _invitedIds.add(c.creatorId));
                        },
                      ),
                    ),
                  ],
                );
              },
              loadFailure: (failure) => SmErrorView(
                message: 'Failed to search creators.',
                onRetry: () => ref
                    .read(creatorSearchNotifierProvider.notifier)
                    .searchCreators(query: _searchCtrl.text),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.s8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s6,
          ),
          decoration: selected
              ? DesignTokens.chipDecorationSelected()
              : DesignTokens.chipDecorationDefault(),
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
