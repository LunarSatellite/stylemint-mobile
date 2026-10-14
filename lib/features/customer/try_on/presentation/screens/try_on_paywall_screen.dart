import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_access_notifier.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_paywall_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Premium paywall for virtual try-on: the admin's plans, the free trial
/// when one is available, and the disclaimer. Pops `true` once unlocked.
///
/// Paying hands off to the provider's page exactly like checkout; when the
/// buyer comes back (app resumed) the subscription is confirmed. An
/// "I have paid" button covers a return the app did not notice.
class TryOnPaywallScreen extends ConsumerStatefulWidget {
  const TryOnPaywallScreen({super.key});

  @override
  ConsumerState<TryOnPaywallScreen> createState() => _TryOnPaywallScreenState();
}

class _TryOnPaywallScreenState extends ConsumerState<TryOnPaywallScreen>
    with WidgetsBindingObserver {
  String? _planId;
  TryOnPaymentRail _rail = TryOnPaymentRail.eSewa;
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        unawaited(ref.read(tryOnAccessNotifierProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_handedOff) return;
    // Back from the provider's page: confirm once.
    _handedOff = false;
    ref
        .read(tryOnPaywallNotifierProvider)
        .maybeWhen(awaitingPayment: (sub, _) => _confirm(sub), orElse: () {});
  }

  void _confirm(MyTryOnSubscription sub) =>
      unawaited(ref.read(tryOnPaywallNotifierProvider.notifier).confirm(sub));

  @override
  Widget build(BuildContext context) {
    ref.listen<TryOnPaywallState>(tryOnPaywallNotifierProvider, (prev, next) {
      next.maybeWhen(
        awaitingPayment: (sub, url) async {
          final uri = url == null ? null : Uri.tryParse(url);
          if (uri == null) {
            // Nothing to complete off-app (e.g. a zero-step rail): confirm.
            _confirm(sub);
            return;
          }
          _handedOff = true;
          await ref.read(tryOnPaymentLauncherProvider)(uri);
        },
        unlocked: (access) {
          SmSnackbar.success(context, 'Virtual try-on unlocked');
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop(true);
        },
        failure: (f, _) => SmSnackbar.error(context, f.displayMessage),
        orElse: () {},
      );
    });

    final accessState = ref.watch(tryOnAccessNotifierProvider);
    final flow = ref.watch(tryOnPaywallNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'Virtual try-on',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: accessState.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (f) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                f.displayMessage,
                style: const TextStyle(color: DesignTokens.textLight),
              ),
              TextButton(
                onPressed: () => unawaited(
                  ref.read(tryOnAccessNotifierProvider.notifier).refresh(),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loadSuccess: (access) => _body(access, flow),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _body(TryOnAccess access, TryOnPaywallState flow) {
    if (!access.serviceEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.s24),
          child: Text(
            'Virtual try-on is not available right now.',
            style: TextStyle(color: DesignTokens.textLight),
          ),
        ),
      );
    }
    final plans = access.plans;
    final selectedId = _planId ?? (plans.isEmpty ? null : plans.first.id);
    final selected = plans.where((p) => p.id == selectedId).firstOrNull;
    final busy = flow.isBusy;
    final pending = flow.maybeWhen(
      awaitingPayment: (sub, _) => sub,
      failure: (_, pending) => pending,
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        const Icon(
          Icons.checkroom_rounded,
          size: 56,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'See it on you before you buy',
          textAlign: TextAlign.center,
          style: DesignTokens.titleMedium.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Live camera and photo try-on, plus a size recommendation from '
          'your measurements.',
          textAlign: TextAlign.center,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (access.hasAccess) ...[
          const SizedBox(height: DesignTokens.s16),
          Text(
            'You already have access'
            '${access.expiresUtc == null ? '' : ' until ${_date(access.expiresUtc!)}'}'
            '. Buying a plan now extends it.',
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorSuccess,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        if (access.trialAvailable && !access.hasAccess) ...[
          OutlinedButton(
            key: const Key('try-on-trial'),
            onPressed: busy
                ? null
                : () => unawaited(
                    ref
                        .read(tryOnPaywallNotifierProvider.notifier)
                        .startTrial(),
                  ),
            child: Text(
              'Start ${access.freeTrialDays}-day free trial',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
        if (plans.isEmpty)
          Text(
            'No plans are on sale right now.',
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else ...[
          for (final plan in plans)
            _PlanTile(
              plan: plan,
              selected: plan.id == selectedId,
              onTap: busy ? null : () => setState(() => _planId = plan.id),
            ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Pay with',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            children: [
              for (final rail in TryOnPaymentRail.values)
                ChoiceChip(
                  label: Text(rail.label),
                  selected: rail == _rail,
                  onSelected: busy ? null : (_) => setState(() => _rail = rail),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          ElevatedButton(
            key: const Key('try-on-subscribe'),
            style: DesignTokens.primaryButtonStyle(),
            onPressed: busy || selected == null
                ? null
                : () => unawaited(
                    ref
                        .read(tryOnPaywallNotifierProvider.notifier)
                        .subscribe(selected, _rail),
                  ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    selected == null
                        ? 'Choose a plan'
                        : 'Subscribe — ${formatMoney(selected.price)}',
                  ),
          ),
        ],
        if (pending != null) ...[
          const SizedBox(height: DesignTokens.s12),
          TextButton(
            key: const Key('try-on-confirm'),
            onPressed: busy ? null : () => _confirm(pending),
            child: const Text('I have paid — activate'),
          ),
        ],
        if (access.disclaimer.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s24),
          Text(
            access.disclaimer,
            key: const Key('try-on-disclaimer'),
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
      ],
    );
  }
}

String _date(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, this.onTap});

  final TryOnPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? DesignTokens.chipsSelectedFill
          : DesignTokens.bgAppBodyLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(
          color: selected
              ? DesignTokens.chipsSelectedBorder
              : DesignTokens.borderDefault,
        ),
      ),
      child: ListTile(
        key: Key('try-on-plan-${plan.id}'),
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
        ),
        title: Text(
          plan.name,
          style: const TextStyle(
            color: DesignTokens.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            '${plan.durationDays} days',
            if (plan.description case final String d) d,
          ].join(' · '),
          style: const TextStyle(color: DesignTokens.textMuted),
        ),
        trailing: Text(
          formatMoney(plan.price),
          style: const TextStyle(
            color: DesignTokens.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
