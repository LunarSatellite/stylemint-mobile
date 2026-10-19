import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/services_home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// One bank: who they are, their products, their branches and a way to
/// book a branch appointment.
class BankDetailScreen extends ConsumerWidget {
  const BankDetailScreen({required this.bankId, super.key});

  final String bankId;

  static const Key appointmentKey = Key('bank-book-appointment');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(bankDetailProvider(bankId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(bank.asData?.value.name ?? 'Bank'),
      ),
      body: SafeArea(
        child: bank.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this bank',
                onRetry: () => ref.invalidate(bankDetailProvider(bankId)),
              ),
            ],
          ),
          data: (b) => _body(context, ref, b),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, BankDetail b) {
    final bookable = b.branches.any((br) => br.appointmentsEnabled);
    final pins = [
      for (final br in b.branches)
        if (br.latitude != null && br.longitude != null)
          ServiceMapPin(
            id: br.id,
            latitude: br.latitude!,
            longitude: br.longitude!,
            label: br.name,
          ),
    ];
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            ServicePhoto(
              url: b.summary.logoUrl,
              height: 56,
              width: 56,
              radius: DesignTokens.radiusMedium,
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name, style: DesignTokens.h3),
                  if (b.summary.tagline != null)
                    Text(
                      b.summary.tagline!,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  if (b.licenceNumber != null)
                    Text(
                      'NRB licence ${b.licenceNumber}',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (b.description != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(b.description!, style: DesignTokens.smallRegular),
        ],
        if (bookable) ...[
          const SizedBox(height: DesignTokens.s16),
          ServicePrimaryButton(
            key: appointmentKey,
            label: 'Book a branch appointment',
            onPressed: () async {
              if (await servicesEnsureAuth(context, ref) && context.mounted) {
                unawaited(
                  context.push(RouteNames.bankAppointmentFormPath(b.id)),
                );
              }
            },
          ),
        ],
        const ServiceSectionTitle('Products'),
        if (b.products.isEmpty)
          Text(
            'No products listed yet.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          for (final p in b.products) ...[
            BankProductTile(product: p, showBank: false),
            const SizedBox(height: DesignTokens.s8),
          ],
        if (b.branches.isNotEmpty) ...[
          const ServiceSectionTitle('Branches'),
          if (pins.isNotEmpty) ...[
            ServiceMapBox(pins: pins),
            const SizedBox(height: DesignTokens.s8),
          ],
          for (final br in b.branches) ...[
            BranchCard(branch: br),
            const SizedBox(height: DesignTokens.s8),
          ],
        ],
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

/// A branch: address, phone (the branch's own), opening hours.
class BranchCard extends StatelessWidget {
  const BranchCard({required this.branch, super.key});

  final BankBranch branch;

  @override
  Widget build(BuildContext context) {
    final hours = {for (final h in branch.openingHours) h.dayOfWeek: h};
    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(branch.name, style: DesignTokens.mediumSemibold),
          if (branch.address.isNotEmpty)
            Text(
              branch.address,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          if (branch.phone != null)
            Text(
              branch.phone!,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              [
                for (var d = 0; d < 7; d++)
                  switch (hours[d]) {
                    final h? when !h.closed && h.opens != null =>
                      '${_dayNames[d]} ${h.opens}–${h.closes ?? ''}',
                    _ => '${_dayNames[d]} closed',
                  },
              ].join(' · '),
              style: DesignTokens.tiny,
            ),
          ],
        ],
      ),
    );
  }
}

/// One bank product: rates, fees, eligibility, documents; Enquire and Book
/// a branch appointment.
class BankProductScreen extends ConsumerWidget {
  const BankProductScreen({required this.productId, super.key});

  final String productId;

  static const Key enquireKey = Key('bank-product-enquire');
  static const Key appointmentKey = Key('bank-product-appointment');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(bankProductProvider(productId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(product.asData?.value.name ?? 'Product'),
      ),
      body: SafeArea(
        child: product.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this product',
                onRetry: () => ref.invalidate(bankProductProvider(productId)),
              ),
            ],
          ),
          data: (p) => _body(context, ref, p),
        ),
      ),
      bottomNavigationBar: product.asData == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: appointmentKey,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            DesignTokens.buttonHeight,
                          ),
                        ),
                        onPressed: () async {
                          final p = product.asData!.value;
                          if (await servicesEnsureAuth(context, ref) &&
                              context.mounted) {
                            unawaited(
                              context.push(
                                RouteNames.bankAppointmentFormPath(
                                  p.bankId,
                                  productId: p.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Book appointment'),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: ServicePrimaryButton(
                        key: enquireKey,
                        label: 'Enquire',
                        onPressed: () async {
                          final p = product.asData!.value;
                          if (await servicesEnsureAuth(context, ref) &&
                              context.mounted) {
                            unawaited(
                              context.push(
                                RouteNames.bankEnquiryFormPath(p.id),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, BankProduct p) {
    final rate = p.rateLabel;
    final min = p.minAmount;
    final max = p.maxAmount;
    final lo = p.minTenureMonths;
    final hi = p.maxTenureMonths;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        if (p.photoUrls.isNotEmpty) ...[
          ServicePhoto(url: p.photoUrls.first, height: 160),
          const SizedBox(height: DesignTokens.s12),
        ],
        Row(
          children: [
            Expanded(child: Text(p.name, style: DesignTokens.h2)),
            ServiceChip(label: p.type.label),
          ],
        ),
        InkWell(
          onTap: () => context.push(RouteNames.serviceBankDetailPath(p.bankId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
            child: Text(
              p.bankName,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ),
        if (p.summary != null)
          Text(p.summary!, style: DesignTokens.smallRegular),
        const ServiceSectionTitle('Rates'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceRow(
                label: 'Interest',
                value: rate ?? 'Ask the bank',
                valueKey: const Key('bank-product-rate'),
                emphasised: rate != null,
              ),
              if (p.rateNote != null)
                Text(
                  p.rateNote!,
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              if (min != null || max != null)
                ServiceRow(
                  label: 'Amount',
                  value: [
                    if (min != null) 'from ${serviceMoney(min)}',
                    if (max != null) 'up to ${serviceMoney(max)}',
                  ].join(' '),
                ),
              if (lo != null || hi != null)
                ServiceRow(
                  label: 'Term',
                  value: lo != null && hi != null
                      ? '$lo–$hi months'
                      : '${lo ?? hi} months',
                ),
            ],
          ),
        ),
        if (p.feesText != null) ...[
          const ServiceSectionTitle('Fees'),
          Text(p.feesText!, style: DesignTokens.smallRegular),
        ],
        if (p.eligibilityText != null) ...[
          const ServiceSectionTitle('Who can apply'),
          Text(
            p.eligibilityText!,
            key: const Key('bank-product-eligibility'),
            style: DesignTokens.smallRegular,
          ),
        ],
        if (p.documentsRequired.isNotEmpty) ...[
          const ServiceSectionTitle('Documents you will need'),
          for (final d in p.documentsRequired)
            ServiceBullet(d, icon: Icons.description_outlined),
        ],
        if (p.description != null) ...[
          const ServiceSectionTitle('About'),
          Text(p.description!, style: DesignTokens.smallRegular),
        ],
        const SizedBox(height: DesignTokens.s16),
        Text(
          'StyleMint shows what the bank publishes. Rates and terms are the '
          'bank\'s; the bank decides on any application.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}
