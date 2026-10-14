import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Profile → "My try-on plan": where access comes from, until when, and
/// every subscription/trial/grant.
class MyTryOnPlanScreen extends ConsumerStatefulWidget {
  const MyTryOnPlanScreen({super.key});

  @override
  ConsumerState<MyTryOnPlanScreen> createState() => _MyTryOnPlanScreenState();
}

class _MyTryOnPlanScreenState extends ConsumerState<MyTryOnPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        unawaited(ref.read(tryOnAccessNotifierProvider.notifier).refresh());
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(myTryOnSubscriptionsProvider);
    await ref.read(tryOnAccessNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(tryOnAccessNotifierProvider).accessOrNull;
    final subs = ref.watch(myTryOnSubscriptionsProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'My try-on plan',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            _AccessCard(access: access),
            const SizedBox(height: DesignTokens.s16),
            if (access != null && access.serviceEnabled)
              ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: () async {
                  await context.push<bool>(RouteNames.tryOnPaywall);
                  if (mounted) unawaited(_refresh());
                },
                child: Text(access.hasAccess ? 'Extend my plan' : 'See plans'),
              ),
            const SizedBox(height: DesignTokens.s24),
            Text(
              'History',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            subs.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              error: (e, _) => Text(
                e is TryOnLoadException
                    ? e.failure.displayMessage
                    : 'Could not load your plans.',
                style: const TextStyle(color: DesignTokens.textMuted),
              ),
              data: (list) => list.isEmpty
                  ? const Text(
                      'Nothing yet.',
                      style: TextStyle(color: DesignTokens.textMuted),
                    )
                  : Column(
                      children: [
                        for (final s in list) _SubscriptionTile(sub: s),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.access});

  final TryOnAccess? access;

  @override
  Widget build(BuildContext context) {
    final a = access;
    final (title, subtitle) = switch (a) {
      null => ('Loading…', ''),
      TryOnAccess(serviceEnabled: false) => (
        'Virtual try-on is switched off',
        'It is not available to anyone right now.',
      ),
      TryOnAccess(hasAccess: true) => (
        'Active — ${a.source?.label ?? 'premium'}',
        a.expiresUtc == null ? 'No end date' : 'Until ${_date(a.expiresUtc)}',
      ),
      _ => (
        'No active plan',
        a.trialAvailable
            ? 'A ${a.freeTrialDays}-day free trial is available.'
            : 'Pick a plan to use virtual try-on.',
      ),
    };
    return Card(
      color: DesignTokens.bgAppBodyLight,
      child: ListTile(
        leading: Icon(
          a?.hasAccess ?? false
              ? Icons.verified_rounded
              : Icons.lock_outline_rounded,
          color: a?.hasAccess ?? false
              ? DesignTokens.primaryGreen
              : DesignTokens.textMuted,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: DesignTokens.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: DesignTokens.textMuted),
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.sub});

  final MyTryOnSubscription sub;

  @override
  Widget build(BuildContext context) {
    final active = sub.state == TryOnSubscriptionState.active;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        sub.planName ?? sub.source.label,
        style: const TextStyle(color: DesignTokens.textWhite),
      ),
      subtitle: Text(
        '${sub.source.label} · ${_date(sub.startsUtc)} → ${_date(sub.expiresUtc)}',
        style: const TextStyle(color: DesignTokens.textMuted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            sub.state.label,
            style: TextStyle(
              color: active
                  ? DesignTokens.colorSuccess
                  : DesignTokens.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sub.priceAmount > 0)
            Text(
              formatMoney(sub.price),
              style: const TextStyle(color: DesignTokens.textMuted),
            ),
        ],
      ),
    );
  }
}
