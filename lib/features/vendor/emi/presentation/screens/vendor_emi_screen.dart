import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/vendor_emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_credit_program_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_plan_requests_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

String _money(Money money) => formatMoney(money, decimalDigits: 0);

EmiFailure? _failureOf(Object error) =>
    error is EmiLoadException ? error.failure : null;

/// The vendor's EMI page: how much buyers may owe them in total, and the
/// listings offering EMI. Each listing's terms are set on the listing itself.
class VendorEmiScreen extends ConsumerWidget {
  const VendorEmiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(vendorEmiSettingsProvider);
    // A 404 means the backend is not deployed yet: say so instead of an error.
    final loadError = settings.error;
    final unavailable =
        loadError != null && (_failureOf(loadError)?.isNotFound ?? false);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('EMI and payment plans'),
      ),
      body: SafeArea(
        child: unavailable
            ? const _Unavailable()
            : RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(vendorEmiSettingsProvider)
                    ..invalidate(vendorEmiProductsProvider)
                    ..invalidate(vendorPaymentPlansProvider)
                    ..invalidate(vendorCreditProgramProvider);
                  await ref.read(vendorEmiSettingsProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    Text(
                      'Let buyers pay for your products over 3 to 12 months. '
                      'You fund the instalments and carry what goes unpaid; '
                      'StyleMint verifies and scores each buyer and collects '
                      'every payment online. Products set to review requests '
                      'send them to you to decide.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    const VendorPlanRequestsCard(),
                    const SizedBox(height: DesignTokens.s16),
                    settings.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => _Retry(
                        message: _loadMessage(error),
                        onRetry: () =>
                            ref.invalidate(vendorEmiSettingsProvider),
                      ),
                      data: (value) => _ExposureLimitCard(settings: value),
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    Text('Products offering EMI', style: DesignTokens.h3),
                    const SizedBox(height: DesignTokens.s8),
                    const _EmiProducts(),
                    const SizedBox(height: DesignTokens.s24),
                    Text(
                      'Pay later and pay now, buy later',
                      style: DesignTokens.h3,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    const VendorCreditProgramCard(),
                  ],
                ),
              ),
      ),
    );
  }
}

String _loadMessage(Object error) {
  final failure = _failureOf(error);
  if (failure == null) return 'Could not load your EMI settings.';
  return emiCommonMessage(failure) ??
      serverMessageOr(failure, 'Could not load your EMI settings.');
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Text(
        'EMI is not available yet. You will be able to offer instalments '
        'here soon.',
        style: DesignTokens.smallRegular,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message, style: DesignTokens.smallRegular),
      TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

/// The total buyers may owe this vendor across EMI orders. Stored now,
/// enforced from phase 2.
class _ExposureLimitCard extends ConsumerStatefulWidget {
  const _ExposureLimitCard({required this.settings});

  final VendorEmiSettings settings;

  @override
  ConsumerState<_ExposureLimitCard> createState() => _ExposureLimitCardState();
}

class _ExposureLimitCardState extends ConsumerState<_ExposureLimitCard> {
  late final TextEditingController _limit = TextEditingController(
    text: widget.settings.exposureLimit?.amount.round().toString() ?? '',
  );
  late VendorEmiSettings _settings = widget.settings;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _limit.text.trim();
    final amount = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && (amount == null || amount < 0)) {
      setState(() => _error = 'Enter an amount in rupees, or leave it empty.');
      return;
    }
    final max = _settings.maxExposureLimit;
    if (amount != null && amount > max.amount) {
      setState(
        () => _error = vendorEmiErrorMessage(
          const EmiFailure.local(VendorEmiErrorCode.exposureAboveMaximum),
          maxExposureLimit: max,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(vendorEmiRepositoryProvider)
        .saveSettings(
          amount == null ? null : Money(amount: amount, currency: max.currency),
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = vendorEmiErrorMessage(failure, maxExposureLimit: max);
      }),
      (saved) {
        setState(() {
          _saving = false;
          _settings = saved;
        });
        SmSnackbar.success(context, 'Exposure limit saved.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final max = _settings.maxExposureLimit;
    final current = _settings.exposureLimit;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exposure limit', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'The most buyers may owe you in total across EMI orders. Up to '
            '${_money(max)}. '
            '${current == null ? 'Not set yet.' : 'Now ${_money(current)}.'}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            key: const Key('vendor-emi-exposure'),
            controller: _limit,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Limit (${max.currency})',
              errorText: _error,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
              ),
              child: Text(_saving ? 'Saving…' : 'Save limit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmiProducts extends ConsumerWidget {
  const _EmiProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(vendorEmiProductsProvider);
    return products.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _Retry(
        message: _loadMessage(error),
        onRetry: () => ref.invalidate(vendorEmiProductsProvider),
      ),
      data: (items) => items.isEmpty
          ? Text(
              'None yet. Open a product priced at Rs 20,000 or more and '
              'switch on "Offer EMI".',
              style: DesignTokens.smallRegular,
            )
          : Column(
              children: [
                for (final terms in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      terms.productName.isEmpty ? 'Product' : terms.productName,
                      style: DesignTokens.mediumSemibold,
                    ),
                    subtitle: Text(
                      '${terms.effectiveMinDownPaymentPercent}% down · '
                      '${terms.tenures.join(', ')} months',
                      style: DesignTokens.tiny,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await context.push<void>(
                        RouteNames.vendorProductEmiPath(terms.productId),
                        extra: terms.productName,
                      );
                      if (context.mounted) {
                        ref.invalidate(vendorEmiProductsProvider);
                      }
                    },
                  ),
              ],
            ),
    );
  }
}
