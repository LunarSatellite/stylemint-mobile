import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/help_center_data.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Help Center categories come exclusively from `/v1/help/categories`.
/// The local Figma examples are not used as an offline substitute for staff
/// authored help content.
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  String _query = '';

  List<HelpCenterCategory> _filtered(List<HelpCenterCategory> categories) {
    if (_query.trim().isEmpty) return categories;
    final query = _query.toLowerCase();
    return categories
        .where(
          (category) =>
              category.name.toLowerCase().contains(query) ||
              category.code.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(helpCategoriesProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
        title: const Text('Help Center', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Text(
            'How can we help you?',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
            decoration: InputDecoration(
              hintText: 'Search help categories',
              hintStyle: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: DesignTokens.textMuted,
              ),
              filled: true,
              fillColor: DesignTokens.bgAppBody,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          Text(
            'Help Topics',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          categories.when(
            loading: () => const _LoadingCard(),
            error: (_, _) => _RetryCard(
              label: 'Could not load help topics.',
              onRetry: () => ref.invalidate(helpCategoriesProvider),
            ),
            data: (items) {
              final filtered = _filtered(items);
              if (filtered.isEmpty) {
                return const _MessageCard('No help topics match your search.');
              }
              return _Card(
                children: [
                  for (final category in filtered)
                    _CategoryTile(
                      category: category,
                      onTap: () => context.push(
                        RouteNames.supportTopic,
                        extra: category,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: DesignTokens.s24),
          Text(
            'Still need help?',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _Card(
            children: [
              for (final option in kContactOptions)
                _ContactTile(
                  option: option,
                  onTap: () => context.push(RouteNames.supportContact),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Column(children: children),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final HelpCenterCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: Icon(_iconFor(category.code), color: DesignTokens.textWhite),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: DesignTokens.mediumSemibold),
                const SizedBox(height: 2),
                Text(
                  '${category.publishedArticleCount} article${category.publishedArticleCount == 1 ? '' : 's'}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
        ],
      ),
    ),
  );

  IconData _iconFor(String code) => switch (code) {
    'orders-and-shipping' => Icons.inventory_2_outlined,
    'returns-and-refunds' => Icons.assignment_return_outlined,
    'account-and-settings' => Icons.person_outline,
    'payment-and-billing' => Icons.credit_card_outlined,
    'safety-and-privacy' => Icons.shield_outlined,
    'for-creators' => Icons.movie_creation_outlined,
    'for-vendors' => Icons.storefront_outlined,
    'delivery-and-couriers' => Icons.local_shipping_outlined,
    _ => Icons.help_outline,
  };
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.option, required this.onTap});
  final ContactOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(option.icon, color: DesignTokens.textWhite),
    title: Text(option.title, style: DesignTokens.mediumSemibold),
    subtitle: Text(option.subtitle, style: DesignTokens.smallRegular),
    trailing: const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const _Card(
    children: [
      Padding(
        padding: EdgeInsets.all(DesignTokens.s24),
        child: Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
      ),
    ],
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => _Card(
    children: [
      Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Text(message, style: DesignTokens.smallRegular),
      ),
    ],
  );
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Card(
    children: [
      Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          children: [
            Text(label, style: DesignTokens.smallRegular),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ],
  );
}
