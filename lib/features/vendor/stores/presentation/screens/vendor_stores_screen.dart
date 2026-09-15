import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/widgets/vendor_store_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor More menu → "Stores & shelf codes": the vendor's physical stores.
class VendorStoresScreen extends ConsumerWidget {
  const VendorStoresScreen({super.key});

  static const String title = 'Stores & shelf codes';
  static const String emptyTitle = 'Add your first store';
  static const String emptyBody =
      'Add each shop or branch where your products are on the shelf. Then '
      'print StyleMint shelf cards and write NFC tags for them.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorStoresNotifierProvider);
    final notifier = ref.read(vendorStoresNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(title, style: DesignTokens.sectionInnerTitle),
      ),
      body: switch (state) {
        VendorStoresLoading() => const SmPageLoader(),
        VendorStoresFailed() => SmErrorView(
          message: "Couldn't load your stores.",
          onRetry: () => unawaited(notifier.load()),
        ),
        VendorStoresLoaded(:final stores) when stores.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 56,
                  color: DesignTokens.iconLight,
                ),
                const SizedBox(height: DesignTokens.s16),
                const Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  emptyBody,
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        VendorStoresLoaded(:final stores) => RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: notifier.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              96,
            ),
            itemCount: stores.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: DesignTokens.s12),
            itemBuilder: (context, index) {
              final store = stores[index];
              return VendorStoreTile(
                store: store,
                onTap: () => unawaited(
                  context.push(
                    RouteNames.vendorStoreDetail.replaceFirst(
                      ':storeId',
                      store.id,
                    ),
                    extra: store,
                  ),
                ),
              );
            },
          ),
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(context.push(RouteNames.vendorStoreNew)),
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.buttonPrimaryText,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add store'),
      ),
    );
  }
}
