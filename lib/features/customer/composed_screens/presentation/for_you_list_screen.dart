import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/composed_sections_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Creators for you", "Shops for you" and "Brands for you": composer-only
/// lists. When the composer is off or has nothing, the screen says so and
/// points back to the Mall instead of inventing a list.
class ForYouListScreen extends ConsumerWidget {
  const ForYouListScreen({required this.screen, super.key});

  final ComposedScreenName screen;

  static String titleFor(ComposedScreenName screen) => switch (screen) {
    ComposedScreenName.creatorsForYou => 'Creators for you',
    ComposedScreenName.shopsForYou => 'Shops for you',
    ComposedScreenName.brandsForYou => 'Brands for you',
    _ => 'For you',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ComposedScreenRequest(screen, limit: 20);
    final async = ref.watch(composedScreenProvider(request));
    return Scaffold(
      appBar: AppBar(title: Text(titleFor(screen))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _empty(context),
        data: (composed) => composed == null || composed.sections.isEmpty
            ? _empty(context)
            : RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(composedScreenProvider(request).future),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s32),
                  children: [
                    ComposedSectionsColumn(screen: screen, composed: composed),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
    key: const ValueKey('for-you-empty'),
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Personal picks are not available right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.s12),
          TextButton(
            onPressed: () => context.go(RouteNames.home),
            child: const Text('Back to the Mall'),
          ),
        ],
      ),
    ),
  );
}
