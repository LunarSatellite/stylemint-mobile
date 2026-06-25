import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/notifiers/payment_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentNotifierProvider);
    final notifier = ref.read(paymentNotifierProvider.notifier);

    final count = state.maybeWhen(
      loadSuccess: (methods) => methods.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: Text(
          'Payment Methods ($count)',
          style: DesignTokens.sectionInnerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: state.when(
          initial: () => const _Loader(),
          loadInProgress: () => const _Loader(),
          loadSuccess: (methods) {
            final cards = methods
                .where((m) => m.type == PaymentType.card)
                .toList(growable: false);
            return ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                _SecureBanner(),
                const SizedBox(height: DesignTokens.s24),
                _CardsSection(
                  cards: cards,
                  onAddCard: () async {
                    final result = await context.push<bool>(RouteNames.paymentAddCard);
                    if (result == true) notifier.load();
                  },
                  onOptions: (card) => _showOptions(context, card, notifier),
                ),
                const SizedBox(height: DesignTokens.s24),
                const _WalletsSection(),
                const SizedBox(height: DesignTokens.s16),
              ],
            );
          },
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load payment methods.',
            onRetry: () => notifier.load(),
          ),
        ),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    PaymentMethod card,
    PaymentNotifier notifier,
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Card Details',
              onTap: () {
                Navigator.pop(sheetCtx);
                context
                    .push<bool>(RouteNames.paymentEditCard, extra: card)
                    .then((result) {
                  if (result == true) notifier.load();
                });
              },
            ),
            const Divider(height: 1, color: DesignTokens.borderDefault),
            _OptionTile(
              icon: Icons.star_outline_rounded,
              label: 'Set as Default',
              onTap: () {
                Navigator.pop(sheetCtx);
                notifier.setDefault(card.id);
              },
            ),
            const Divider(height: 1, color: DesignTokens.borderDefault),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Remove',
              onTap: () {
                Navigator.pop(sheetCtx);
                _showRemoveConfirm(context, () => notifier.delete(card.id));
              },
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        );
      },
    );
  }

  void _showRemoveConfirm(BuildContext context, VoidCallback onConfirm) {
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
                child: const Icon(Icons.info_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: DesignTokens.s16),
              const Text('Confirm Remove', style: DesignTokens.sectionInnerTitle),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Are your sure you want to remove this payment method?',
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
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                    ),
                    minimumSize: const Size(0, DesignTokens.buttonHeight),
                  ),
                  child: const Text('Cancel', style: DesignTokens.mediumSemibold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SecureBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/icons/SecureIcon.svg', width: 40, height: 40),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure & Encrypted', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  "Don't worry about your payment details, they are protected with high level encryption",
                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardsSection extends StatelessWidget {
  const _CardsSection({
    required this.cards,
    required this.onAddCard,
    required this.onOptions,
  });

  final List<PaymentMethod> cards;
  final VoidCallback onAddCard;
  final void Function(PaymentMethod) onOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cards',
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
            ),
            GestureDetector(
              onTap: onAddCard,
              child: Text(
                'Add Card +',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        if (cards.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s24),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Text(
              'No cards saved yet',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textMuted),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: DesignTokens.s16,
                      endIndent: DesignTokens.s16,
                      color: DesignTokens.borderDefault,
                    ),
                  _CardTile(card: cards[i], onOptionsTap: () => onOptions(cards[i])),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onOptionsTap});

  final PaymentMethod card;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final brand = card.label.isNotEmpty ? card.label : 'Card';
    final isVisa = brand.toLowerCase().contains('visa');
    final isMc = brand.toLowerCase().contains('master');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          // Brand logo container
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: Center(
              child: isVisa
                  ? Text(
                      'VISA',
                      style: const TextStyle(
                        color: Color(0xFF1A1F71),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : isMc
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 12,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEB001B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF79E1B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          brand.substring(0, brand.length.clamp(0, 2)).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(brand, style: DesignTokens.mediumSemibold),
                    if (card.isDefault) ...[
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
                if (card.cardholderName != null || card.expiryDate != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    [
                      if (card.cardholderName != null && card.cardholderName!.isNotEmpty)
                        card.cardholderName!,
                      if (card.expiryDate != null) 'Expires ${card.expiryDate}',
                    ].join(' • '),
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                  ),
                ],
                if (card.lastFour != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '$brand ending in ${card.lastFour}',
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onOptionsTap,
            icon: const Icon(Icons.more_vert, color: DesignTokens.textMuted, size: DesignTokens.iconMedium),
          ),
        ],
      ),
    );
  }
}

// ── Static Digital Wallets section ─────────────────────────────────────────

class _WalletsSection extends StatelessWidget {
  const _WalletsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Digital Wallets',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Column(
            children: [
              _WalletTile(
                logoWidget: _PaypalLogo(),
                name: 'Paypal',
                subtitle: 'Link your paypal wallet',
                linked: false,
              ),
              const Divider(
                height: 1,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
                color: DesignTokens.borderDefault,
              ),
              _WalletTile(
                logoWidget: SvgPicture.asset('assets/icons/google.svg', width: 28, height: 28),
                name: 'Google Pay',
                subtitle: 'shreeteen@nimb',
                linked: true,
              ),
              const Divider(
                height: 1,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
                color: DesignTokens.borderDefault,
              ),
              _WalletTile(
                logoWidget: SvgPicture.asset('assets/icons/apple.svg', width: 28, height: 28),
                name: 'Apple Pay',
                subtitle: 'Visa ending in 3499',
                linked: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaypalLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF003087),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.logoWidget,
    required this.name,
    required this.subtitle,
    required this.linked,
  });

  final Widget logoWidget;
  final String name;
  final String subtitle;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: Center(child: logoWidget),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    if (linked) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DesignTokens.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        'Linked',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                      Text(
                        ' • $subtitle',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ] else
                      Text(
                        subtitle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!linked)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s8,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              child: Text(
                'Link',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Icon(Icons.more_vert, color: DesignTokens.textMuted, size: DesignTokens.iconMedium),
        ],
      ),
    );
  }
}

// ── Shared bottom sheet widgets ─────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
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
      leading: Icon(icon, color: DesignTokens.textLight, size: DesignTokens.iconMedium),
      title: Text(label, style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite)),
      trailing: const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
    );
  }
}
