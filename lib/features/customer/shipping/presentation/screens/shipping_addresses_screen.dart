import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/notifiers/shipping_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ShippingAddressesScreen extends ConsumerWidget {
  const ShippingAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressNotifierProvider);
    final notifier = ref.read(addressNotifierProvider.notifier);

    final count = state.maybeWhen(
      loadSuccess: (addresses) => addresses.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: Text(
          'Shipping Address ($count)',
          style: DesignTokens.sectionInnerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.when(
                initial: () => const _Loader(),
                loadInProgress: () => const _Loader(),
                loadSuccess: (addresses) {
                  if (addresses.isEmpty) {
                    return Center(
                      child: Text(
                        'No addresses yet.\nAdd one below.',
                        textAlign: TextAlign.center,
                        style: DesignTokens.mediumRegular,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16,
                      DesignTokens.s16,
                      DesignTokens.s16,
                      0,
                    ),
                    itemCount: addresses.length,
                    itemBuilder: (_, i) => _AddressTile(
                      address: addresses[i],
                      onOptionsTap: () => _showOptions(
                        context,
                        addresses[i],
                        notifier,
                      ),
                    ),
                  );
                },
                loadFailure: (failure) => SmErrorView(
                  message: 'Failed to load addresses.',
                  onRetry: notifier.load,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.cardRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pro Tip — slightly grey
                  Container(
                    width: double.infinity,
                    color: DesignTokens.bgAppBodyLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s12,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/Ideaicon.svg',
                          width: 28,
                          height: 35,
                        ),
                        const SizedBox(width: DesignTokens.s12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Pro Tip', style: DesignTokens.mediumSemibold),
                            Text(
                              'You can save upto 10 shipping addresses',
                              style: DesignTokens.smallRegular,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Button — dark
                  Container(
                    width: double.infinity,
                    color: DesignTokens.bgAppFoundation,
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await context.push<bool>(
                          RouteNames.shippingAddEdit,
                        );
                        if (result == true) notifier.load();
                      },
                      style: DesignTokens.primaryButtonStyle(),
                      child: Text(
                        'Add New Shipping Address',
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.buttonPrimaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    ShippingAddress address,
    AddressNotifier notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) {
        // Without SafeArea the bottom-most row (Delete Address) renders
        // under the system gesture nav area, so a tap there hits the OS
        // home gesture instead of the button — the app backgrounds
        // instead of showing the delete confirmation.
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Address Details',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context
                      .push<bool>(RouteNames.shippingAddEdit, extra: address)
                      .then((result) {
                        if (result == true) notifier.load();
                      });
                },
              ),
              _OptionTile(
                icon: Icons.remove_red_eye_outlined,
                label: 'View Address Details',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push(RouteNames.shippingView, extra: address);
                },
              ),
              _OptionTile(
                icon: Icons.star_outline_rounded,
                label: 'Set as Default',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  notifier.setDefault(address.id);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Address',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirm(
                    context,
                    () => notifier.delete(address.id),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, VoidCallback onConfirm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s24,
            0,
            DesignTokens.s24,
            DesignTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: DesignTokens.s20),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: DesignTokens.colorInfo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              const Text(
                'Confirm Delete',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Are you sure you want to delete this shipping address?',
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    onConfirm();
                  },
                  style: DesignTokens.primaryButtonStyle(),
                  child: Text(
                    'Confirm',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.buttonGrayFill,
                    foregroundColor: DesignTokens.buttonGrayText,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.buttonRadius,
                      ),
                    ),
                    minimumSize: const Size(0, DesignTokens.buttonHeight),
                  ),
                  child: const Text(
                    'Cancel',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onOptionsTap,
  });

  final ShippingAddress address;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final summary =
        '${address.addressLine1}, ${address.city}, ${address.country}';

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: DesignTokens.textWhite,
              size: DesignTokens.iconMedium,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label, style: DesignTokens.mediumSemibold),
                    if (address.isDefault) ...[
                      const SizedBox(width: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: 2,
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
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  summary,
                  style: DesignTokens.smallRegular,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOptionsTap,
            icon: const Icon(
              Icons.more_vert,
              color: DesignTokens.textMuted,
              size: DesignTokens.iconMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DesignTokens.borderDefault,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: DesignTokens.textLight,
        size: DesignTokens.iconMedium,
      ),
      title: Text(
        label,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
    );
  }
}
