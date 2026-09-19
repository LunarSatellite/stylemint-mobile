import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/clienteling_labels.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/claim_outcome_sheet.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/outreach_sheet.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/widgets/start_serving_sheet.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One permitted customer's workspace.
///
/// Everything on this screen comes from `GET
/// /v1/clienteling/associate/clients/{id}/brief`. The brief is deliberately
/// thin — no contact details, no money, no memory — and it names what it is
/// withholding, which this screen shows rather than hides.
class ClientBriefScreen extends ConsumerWidget {
  const ClientBriefScreen({required this.customerAccountId, super.key});

  final String customerAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = clientBriefNotifierProvider(customerAccountId);
    final state = ref.watch(provider);

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
        title: const Text('Client', style: DesignTokens.oneLinerSemibold),
      ),
      body: SafeArea(
        child: switch (state) {
          ClientBriefInitial() || ClientBriefLoadInProgress() => const Center(
            child: SmBrandLoader(),
          ),
          ClientBriefLoadFailure(:final failure) => SmErrorView(
            message: NetworkExceptions.getMessage(failure),
            onRetry: () => ref.read(provider.notifier).load(),
          ),
          final ClientBriefLoadSuccess loaded => _BriefBody(
            loaded: loaded,
            notifier: ref.read(provider.notifier),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _BriefBody extends StatelessWidget {
  const _BriefBody({required this.loaded, required this.notifier});

  final ClientBriefLoadSuccess loaded;
  final ClientBriefNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final brief = loaded.brief;
    final session = loaded.session;
    final isServing = session != null && session.isOpen;

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        _IdentityCard(brief: brief),
        const SizedBox(height: DesignTokens.s16),
        _SessionCard(
          loaded: loaded,
          notifier: notifier,
          isServing: isServing,
        ),
        const SizedBox(height: DesignTokens.s16),
        _ContactabilityCard(
          brief: brief,
          loaded: loaded,
          notifier: notifier,
          canSend: isServing,
        ),
        const SizedBox(height: DesignTokens.s16),
        _OrdersCard(
          brief: brief,
          loaded: loaded,
          notifier: notifier,
          canClaim: isServing,
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActivityCard(activity: loaded.activity),
        const SizedBox(height: DesignTokens.s16),
        _WithheldCard(withheld: brief.withheld),
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DesignTokens.sectionInnerTitle),
          if (trailing != null) ...[
            const SizedBox(height: DesignTokens.s8),
            trailing!,
          ],
          const SizedBox(height: DesignTokens.s12),
          ...children,
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.brief});

  final ClientBrief brief;

  @override
  Widget build(BuildContext context) {
    final label = clientLabel(
      displayName: brief.customerDisplayName,
      handle: brief.customerHandle,
      accountId: brief.customerAccountId,
    );
    return _Section(
      title: label,
      children: [
        if (brief.customerDisplayName != null && brief.customerHandle != null)
          Text(
            '@${brief.customerHandle}',
            style: DesignTokens.smallDescription,
          ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          brief.customerAccountActive ? 'Account active' : 'Account not active',
          style: DesignTokens.smallRegular.copyWith(
            color: brief.customerAccountActive
                ? DesignTokens.colorSuccess
                : DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.loaded,
    required this.notifier,
    required this.isServing,
  });

  final ClientBriefLoadSuccess loaded;
  final ClientBriefNotifier notifier;
  final bool isServing;

  @override
  Widget build(BuildContext context) {
    final session = loaded.session;
    final busy = loaded.actionInProgress;
    final failure = loaded.actionFailure;

    return _Section(
      title: 'Serving',
      children: [
        if (session == null)
          const Text(
            'Not serving this client from this device. Starting attaches to '
            'the open session if there already is one.',
            style: DesignTokens.smallDescription,
          )
        else ...[
          Text(
            isServing ? 'Serving now' : 'Session finished',
            style: DesignTokens.mediumSemibold,
          ),
          if (session.purpose != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(session.purpose!, style: DesignTokens.smallRegular),
          ],
          if (session.openedUtc != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Started ${formatRelative(session.openedUtc!)}',
              style: DesignTokens.smallDescription,
            ),
          ],
        ],
        const SizedBox(height: DesignTokens.s12),
        if (failure != null) ...[
          Text(
            NetworkExceptions.getMessage(failure),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: isServing
              ? OutlinedButton(
                  onPressed: busy ? null : notifier.stopServing,
                  child: const Text('Finish serving'),
                )
              : ElevatedButton(
                  onPressed: busy
                      ? null
                      : () => showStartServingSheet(context, notifier),
                  child: const Text('Start serving'),
                ),
        ),
      ],
    );
  }
}

/// The consent gate. The backend decides per channel whether it would carry a
/// message at all; this card shows that decision in the backend's own words
/// and only offers to send on a channel it said was allowed.
class _ContactabilityCard extends StatelessWidget {
  const _ContactabilityCard({
    required this.brief,
    required this.loaded,
    required this.notifier,
    required this.canSend,
  });

  final ClientBrief brief;
  final ClientBriefLoadSuccess loaded;
  final ClientBriefNotifier notifier;
  final bool canSend;

  @override
  Widget build(BuildContext context) {
    final allowed = brief.contactability.where((c) => c.allowed).toList();
    final attempt = loaded.lastOutreach;

    return _Section(
      title: 'Contacting this client',
      trailing: const Text(
        'The platform carries the message. You are never shown an email '
        'address or a phone number.',
        style: DesignTokens.smallDescription,
      ),
      children: [
        if (brief.contactability.isEmpty)
          const Text(
            'No channels were reported for this client.',
            style: DesignTokens.smallDescription,
          )
        else
          ...brief.contactability.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        c.allowed ? Icons.check_circle_outline : Icons.block,
                        size: DesignTokens.iconSmall,
                        color: c.allowed
                            ? DesignTokens.colorSuccess
                            : DesignTokens.textMuted,
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(
                        child: Text(
                          outreachChannelLabel(c.channel),
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: DesignTokens.s24,
                      top: DesignTokens.s4,
                    ),
                    child: Text(
                      c.reason ?? outreachDecisionLabel(c.decision),
                      style: DesignTokens.smallDescription,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (attempt != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last request: ${outreachDecisionLabel(attempt.decision)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: attempt.sent
                        ? DesignTokens.colorSuccess
                        : DesignTokens.warning300,
                  ),
                ),
                if (attempt.decisionReason != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    attempt.decisionReason!,
                    style: DesignTokens.smallDescription,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s12),
        if (allowed.isEmpty)
          const Text(
            'No channel is open, so there is nothing to send on.',
            style: DesignTokens.smallDescription,
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: canSend && !loaded.actionInProgress
                  ? () => showOutreachSheet(
                      context,
                      notifier: notifier,
                      allowedChannels: allowed.map((c) => c.channel).toList(),
                    )
                  : null,
              child: const Text('Send a message'),
            ),
          ),
        if (allowed.isNotEmpty && !canSend) ...[
          const SizedBox(height: DesignTokens.s4),
          const Text(
            'Start serving to send.',
            style: DesignTokens.smallDescription,
          ),
        ],
      ],
    );
  }
}

/// Orders this vendor is part of. The backend sends status and shape only —
/// no totals, no prices, no discounts — so none are shown.
class _OrdersCard extends StatelessWidget {
  const _OrdersCard({
    required this.brief,
    required this.loaded,
    required this.notifier,
    required this.canClaim,
  });

  final ClientBrief brief;
  final ClientBriefLoadSuccess loaded;
  final ClientBriefNotifier notifier;
  final bool canClaim;

  @override
  Widget build(BuildContext context) {
    final orders = brief.recentOrdersWithThisVendor;
    final claim = loaded.lastClaim;

    return _Section(
      title: 'Recent orders with your shop',
      children: [
        if (orders.isEmpty)
          const Text(
            'No orders with your shop were returned for this client.',
            style: DesignTokens.smallDescription,
          )
        else
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.orderNumber ?? 'Order',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Wrap(
                    spacing: DesignTokens.s8,
                    runSpacing: DesignTokens.s4,
                    children: [
                      if (o.vendorSubOrderStatus != null)
                        Text(
                          o.vendorSubOrderStatus!,
                          style: DesignTokens.smallDescription,
                        ),
                      if (o.itemCount != null)
                        Text(
                          o.itemCount == 1 ? '1 item' : '${o.itemCount} items',
                          style: DesignTokens.smallDescription,
                        ),
                      if (o.placedUtc != null)
                        Text(
                          formatRelative(o.placedUtc!),
                          style: DesignTokens.smallDescription,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (claim != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim on ${claim.orderNumber ?? 'this order'}: '
                  '${assistedOutcomeStatusLabel(claim.status)}',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s4),
                const Text(
                  'A claim only becomes credit when the customer confirms it.',
                  style: DesignTokens.smallDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
        ],
        if (orders.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: canClaim && !loaded.actionInProgress
                  ? () => showClaimOutcomeSheet(
                      context,
                      notifier: notifier,
                      orders: orders,
                    )
                  : null,
              child: const Text('Claim you assisted an order'),
            ),
          ),
        if (orders.isNotEmpty && !canClaim) ...[
          const SizedBox(height: DesignTokens.s4),
          const Text(
            'Start serving to claim.',
            style: DesignTokens.smallDescription,
          ),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  /// Null means the trail could not be read. Empty means nothing is recorded.
  final List<ClientelingActivity>? activity;

  @override
  Widget build(BuildContext context) {
    final rows = activity;
    return _Section(
      title: 'Your actions on this client',
      trailing: const Text(
        'The customer sees this same record.',
        style: DesignTokens.smallDescription,
      ),
      children: [
        if (rows == null)
          const Text(
            'Your trail could not be loaded.',
            style: DesignTokens.smallDescription,
          )
        else if (rows.isEmpty)
          const Text(
            'Nothing recorded yet.',
            style: DesignTokens.smallDescription,
          )
        else
          ...rows.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityTypeLabel(a.type),
                    style: DesignTokens.smallRegular,
                  ),
                  if (a.detail != null)
                    Text(a.detail!, style: DesignTokens.smallDescription),
                  if (a.occurredUtc != null)
                    Text(
                      formatRelative(a.occurredUtc!),
                      style: DesignTokens.smallDescription,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WithheldCard extends StatelessWidget {
  const _WithheldCard({required this.withheld});

  final List<String> withheld;

  @override
  Widget build(BuildContext context) {
    if (withheld.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Not shown to you',
      trailing: const Text(
        'The platform names what it holds back, so a gap here is a rule and '
        'not missing data.',
        style: DesignTokens.smallDescription,
      ),
      children: withheld
          .map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: DesignTokens.s4),
                    child: Icon(
                      Icons.remove,
                      size: DesignTokens.iconSmall,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(w, style: DesignTokens.smallDescription),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
