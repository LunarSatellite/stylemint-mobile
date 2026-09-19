import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/clienteling_labels.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The shopper's own side of clienteling — `v1/clienteling/me/*`.
///
/// Two things live here: everything an associate has done on this account, and
/// the only control that turns an associate's claim into credit.
class MyClientelingScreen extends ConsumerWidget {
  const MyClientelingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myClientelingNotifierProvider);
    final notifier = ref.read(myClientelingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'In-store assistance',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          MyClientelingInitial() ||
          MyClientelingLoadInProgress() => const Center(child: SmBrandLoader()),
          MyClientelingLoadFailure(:final failure) => SmErrorView(
            message: NetworkExceptions.getMessage(failure),
            onRetry: notifier.load,
          ),
          final MyClientelingLoadSuccess loaded => RefreshIndicator(
            onRefresh: notifier.load,
            child: _Body(loaded: loaded, notifier: notifier),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.loaded, required this.notifier});

  final MyClientelingLoadSuccess loaded;
  final MyClientelingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final awaiting = loaded.claims
        .where((c) => c.awaitsCustomerAnswer)
        .toList();
    final answered = loaded.claims
        .where((c) => !c.awaitsCustomerAnswer)
        .toList();
    final failure = loaded.actionFailure;

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        if (failure != null) ...[
          Text(
            NetworkExceptions.getMessage(failure),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
        ],
        const Text(
          'Claims awaiting your answer',
          style: DesignTokens.sectionInnerTitle,
        ),
        const SizedBox(height: DesignTokens.s4),
        const Text(
          'A store associate can say they helped with an order. Only your '
          'answer decides whether they are credited.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        if (awaiting.isEmpty)
          const _EmptyNote('No claims are waiting for your answer.')
        else
          ...awaiting.map(
            (c) => _ClaimCard(
              outcome: c,
              busy: loaded.busyOutcomeId == c.outcomeId,
              onConfirm: () => notifier.confirm(c.outcomeId),
              onReject: () => notifier.reject(c.outcomeId),
            ),
          ),
        if (answered.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s24),
          const Text('Answered', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),
          ...answered.map((c) => _ClaimCard(outcome: c, busy: false)),
        ],
        const SizedBox(height: DesignTokens.s24),
        const Text(
          'Who acted on your account',
          style: DesignTokens.sectionInnerTitle,
        ),
        const SizedBox(height: DesignTokens.s4),
        const Text(
          'Every clienteling action is recorded here, including the times an '
          'associate only opened your file.',
          style: DesignTokens.smallDescription,
        ),
        const SizedBox(height: DesignTokens.s12),
        if (loaded.history == null)
          const _EmptyNote('Your record could not be loaded.')
        else if (loaded.history!.isEmpty)
          const _EmptyNote('No associate has acted on your account.')
        else
          ...loaded.history!.map((a) => _HistoryRow(activity: a)),
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
    child: Text(message, style: DesignTokens.smallDescription),
  );
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.outcome,
    required this.busy,
    this.onConfirm,
    this.onReject,
  });

  final AssistedOutcome outcome;
  final bool busy;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outcome.orderNumber ?? 'An order',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            assistedOutcomeStatusLabel(outcome.status),
            style: DesignTokens.smallRegular.copyWith(
              color: outcome.isCredited
                  ? DesignTokens.colorSuccess
                  : DesignTokens.textMuted,
            ),
          ),
          if (outcome.note != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(outcome.note!, style: DesignTokens.smallRegular),
          ],
          if (outcome.claimedUtc != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Claimed ${formatRelative(outcome.claimedUtc!)}',
              style: DesignTokens.smallDescription,
            ),
          ],
          if (onConfirm != null && onReject != null) ...[
            const SizedBox(height: DesignTokens.s12),
            if (busy)
              const Center(child: SmBrandLoader())
            else
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text('Yes, they helped'),
                  ),
                  OutlinedButton(
                    onPressed: onReject,
                    child: const Text('No, they did not'),
                  ),
                ],
              ),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'Rejecting is final — no credit is ever granted for this claim.',
              style: DesignTokens.smallDescription,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.activity});

  final ClientelingActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customerActivityLabel(activity.type),
            style: DesignTokens.smallRegular,
          ),
          if (activity.detail != null)
            Text(activity.detail!, style: DesignTokens.smallDescription),
          if (activity.occurredUtc != null)
            Text(
              formatRelative(activity.occurredUtc!),
              style: DesignTokens.smallDescription,
            ),
        ],
      ),
    );
  }
}
