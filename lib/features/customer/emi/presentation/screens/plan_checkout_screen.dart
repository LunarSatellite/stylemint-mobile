import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart'
    show ShippingAddress;
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Checking out an approved plan: where the item goes, how the first payment
/// is made, and Place.
///
/// The basket is the plan's one item at the plan's price — the server builds
/// it from the plan, and the cart is not involved. Placing creates the order
/// the plan pays for and sends the buyer to the plan's first payment, not the
/// whole price; with nothing due up front, the plan starts at once. Every
/// figure is the server's.
///
/// Pops with the [PlanCheckoutPlaced] result, so the plan screen can say the
/// payment is on its way.
class PlanCheckoutScreen extends ConsumerStatefulWidget {
  const PlanCheckoutScreen({
    required this.agreementId,
    this.args = const PlanDetailArgs(),
    super.key,
  });

  final String agreementId;
  final PlanDetailArgs args;

  @override
  ConsumerState<PlanCheckoutScreen> createState() => _PlanCheckoutScreenState();
}

class _PlanCheckoutScreenState extends ConsumerState<PlanCheckoutScreen> {
  CreditAgreement? _plan;
  PlanCheckout? _checkout;
  List<ShippingAddress> _addresses = const [];
  EmiFailure? _loadFailure;
  bool _loading = true;

  String? _addressId;
  PlanPaymentRail _rail = PlanPaymentRail.eSewa;
  bool _placing = false;
  String? _error;
  EmiFailure? _placeFailure;

  /// One key per order the buyer means to place. A retry after the network
  /// dropped reuses it, so the server answers with the same order rather than
  /// placing a second one.
  String _key = const Uuid().v4();

  /// The server refused the last place, which ends the session there: the
  /// next attempt starts a fresh checkout of the plan.
  bool _sessionSpent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    final repo = ref.read(creditRepositoryProvider);
    final results = await Future.wait([
      repo.getAgreement(widget.agreementId),
      repo.startCheckout(widget.agreementId),
      repo.deliveryAddresses(),
    ]);
    if (!mounted) return;

    EmiFailure? failure;
    CreditAgreement? plan;
    PlanCheckout? checkout;
    var addresses = const <ShippingAddress>[];
    results[0].fold((f) => failure ??= f, (v) => plan = v as CreditAgreement);
    results[1].fold((f) => failure ??= f, (v) => checkout = v as PlanCheckout);
    results[2].fold(
      (f) => failure ??= f,
      (v) => addresses = v as List<ShippingAddress>,
    );

    setState(() {
      _loading = false;
      _loadFailure = failure;
      _plan = plan;
      _checkout = checkout;
      _sessionSpent = false;
      _key = const Uuid().v4();
      _setAddresses(addresses);
    });
  }

  void _setAddresses(List<ShippingAddress> addresses) {
    _addresses = addresses.where((a) => !a.isEmpty).toList(growable: false);
    if (_addresses.any((a) => a.id == _addressId)) return;
    final preferred = _addresses.where((a) => a.isDefault);
    _addressId = preferred.isNotEmpty
        ? preferred.first.id
        : _addresses.isNotEmpty
        ? _addresses.first.id
        : null;
  }

  Future<void> _addAddress() async {
    await context.push(RouteNames.shippingAddEdit);
    if (!mounted) return;
    final result = await ref.read(creditRepositoryProvider).deliveryAddresses();
    if (!mounted) return;
    result.fold(
      (_) {},
      (addresses) => setState(() => _setAddresses(addresses)),
    );
  }

  Future<void> _place() async {
    final addressId = _addressId;
    if (addressId == null || _placing) return;
    setState(() {
      _placing = true;
      _error = null;
      _placeFailure = null;
    });

    final repo = ref.read(creditRepositoryProvider);
    if (_sessionSpent) {
      final restarted = await repo.startCheckout(widget.agreementId);
      if (!mounted) return;
      final fresh = restarted.fold((failure) {
        setState(() {
          _placing = false;
          _error = creditFailureMessage(failure);
          _placeFailure = failure;
        });
        return null;
      }, (checkout) => checkout);
      if (fresh == null) return;
      _checkout = fresh;
      _sessionSpent = false;
      _key = const Uuid().v4();
    }

    final result = await repo.placeCheckout(
      sessionId: _checkout!.sessionId,
      addressId: addressId,
      rail: _rail,
      idempotencyKey: _key,
    );
    if (!mounted) return;
    await result.fold(
      (failure) async => setState(() {
        _placing = false;
        _error = creditFailureMessage(failure);
        _placeFailure = failure;
        // Offline or no answer: the same session and key may still go
        // through. Anything the server answered has ended this session.
        if (failure.kind != EmiFailureKind.offline &&
            failure.kind != EmiFailureKind.unknown) {
          _sessionSpent = true;
        }
      }),
      (placed) async {
        refreshPaymentPlans(ref, agreementId: widget.agreementId);
        final url = placed.redirectUrl;
        final uri = url == null ? null : Uri.tryParse(url);
        if (uri != null) await ref.read(planPaymentLauncherProvider)(uri);
        if (mounted) context.pop(placed);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      title: const Text('Check out your plan'),
    ),
    body: SafeArea(child: _content()),
  );

  Widget _content() {
    if (_loading) return const SmPageLoader();
    final failure = _loadFailure;
    if (failure != null || _plan == null || _checkout == null) {
      return SmErrorView(
        message: failure == null
            ? 'We could not open checkout for this plan.'
            : creditFailureMessage(failure),
        onRetry: failure?.code == 'credit_agreement.order_attached'
            ? () => context.pop()
            : () => unawaited(_load()),
      );
    }
    return _form(_plan!, _checkout!);
  }

  Widget _form(CreditAgreement plan, PlanCheckout checkout) {
    final dueToday = plan.downPayment;
    final nothingToday = dueToday.amount <= 0;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        PlanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                checkout.title.isNotEmpty
                    ? checkout.title
                    : widget.args.productName ?? '${plan.kind.label} plan',
                key: const Key('plan-checkout-item'),
                style: DesignTokens.mediumSemibold,
              ),
              if (checkout.option != null)
                Text(
                  checkout.option!,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              const SizedBox(height: DesignTokens.s8),
              PlanRow(label: 'Price', value: planMoney(checkout.price)),
              PlanRow(
                key: const Key('plan-checkout-due-today'),
                label: 'Due today',
                value: nothingToday ? 'Nothing' : planMoney(dueToday),
                emphasised: true,
              ),
              PlanRow(
                label: 'Then',
                value: '${plan.tenureMonths} monthly payments',
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s20),
        const Text('Deliver to', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s8),
        if (_addresses.isEmpty)
          PlanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a delivery address to place this order.',
                  style: DesignTokens.smallRegular,
                ),
                TextButton(
                  key: const Key('plan-checkout-add-address'),
                  onPressed: () => unawaited(_addAddress()),
                  child: const Text('Add an address'),
                ),
              ],
            ),
          )
        else
          RadioGroup<String>(
            groupValue: _addressId,
            onChanged: (id) {
              if (id == null || _placing) return;
              setState(() => _addressId = id);
            },
            child: Column(
              children: [
                for (final address in _addresses)
                  RadioListTile<String>(
                    key: Key('plan-checkout-address-${address.id}'),
                    value: address.id,
                    title: Text(
                      address.label.isNotEmpty ? address.label : 'Address',
                      style: DesignTokens.smallRegular,
                    ),
                    subtitle: Text(
                      address.summaryLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        const SizedBox(height: DesignTokens.s16),
        Text(
          nothingToday
              ? 'Pay your instalments with'
              : 'Pay the first amount with',
          style: DesignTokens.mediumSemibold,
        ),
        RadioGroup<PlanPaymentRail>(
          groupValue: _rail,
          onChanged: (rail) {
            if (rail == null || _placing) return;
            setState(() {
              _rail = rail;
              _key = const Uuid().v4();
            });
          },
          child: Column(
            children: [
              for (final rail in PlanPaymentRail.values)
                RadioListTile<PlanPaymentRail>(
                  key: Key('plan-checkout-rail-${rail.name}'),
                  value: rail,
                  title: Text(rail.label, style: DesignTokens.smallRegular),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Text(
          'Payment plans are paid online. Cash on delivery is not available '
          'for them.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            _error!,
            key: const Key('plan-checkout-error'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          if (_placeFailure?.code == 'credit_agreement.order_attached')
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to the plan'),
            ),
        ],
        const SizedBox(height: DesignTokens.s20),
        SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: FilledButton(
            key: const Key('plan-checkout-place'),
            onPressed: _addressId == null || _placing
                ? null
                : () => unawaited(_place()),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.buttonPrimaryFill,
              foregroundColor: DesignTokens.buttonPrimaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
            child: _placing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    nothingToday
                        ? 'Place order'
                        : 'Place order and pay ${planMoney(dueToday)}',
                  ),
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          plan.guarantor.statement,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }
}
