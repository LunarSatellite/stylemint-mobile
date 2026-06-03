import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/notifiers/shipping_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ShippingAddressesScreen extends ConsumerWidget {
  const ShippingAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressNotifierProvider);

    final notifier = ref.read(addressNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Shipping Addresses',
            style: DesignTokens.sectionInnerTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>('/shipping/addresses/add');
          if (result == true) {
            notifier.load();
          }
        },
        backgroundColor: DesignTokens.primaryGreen,
        label: const Text('Add New Shipping Address'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: state.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (addresses) {
          if (addresses.isEmpty) {
            return const Center(
              child: Text(
                'No addresses yet',
                style: DesignTokens.bodyText,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: addresses.length,
            itemBuilder: (_, i) => _AddressCard(
              address: addresses[i],
              onEdit: () async {
                final result = await context.push<bool>(
                  '/shipping/addresses/edit',
                  extra: addresses[i],
                );
                if (result == true) {
                  notifier.load();
                }
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: DesignTokens.bgAppBody,
                    title: const Text('Delete Address'),
                    content: const Text(
                      'Are you sure you want to delete this address?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => ctx.pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => ctx.pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: DesignTokens.colorError),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.delete(addresses[i].id);
                }
              },
              onSetDefault: () => notifier.setDefault(addresses[i].id),
            ),
          );
        },
        loadFailure:
            (failure) => SmErrorView(
              message: 'Failed to load addresses.',
              onRetry: () => notifier.load(),
            ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final ShippingAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(
        borderColor:
            address.isDefault ? DesignTokens.primaryGreen : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.label,
                  style: DesignTokens.mediumSemibold,
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.tagInfoFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.tagInfoText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: DesignTokens.textMuted),
                padding: const EdgeInsets.all(DesignTokens.s4),
                color: DesignTokens.bgAppBodyLight,
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                    case 'default':
                      onSetDefault();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            '${address.fullName}  •  ${address.phone}',
            style: DesignTokens.bodyText.copyWith(color: DesignTokens.textWhite),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            [
              address.addressLine1,
              address.addressLine2,
              address.city,
              address.state,
              address.zipCode,
            ].where((e) => e != null && e.isNotEmpty).join(', '),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
