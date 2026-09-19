import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_mandate_issue_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the customer decided about a proposed basket.
enum AgentProposalDecision { confirmed, rejected }

/// Opens the basket an assistant prepared, for the customer to read and
/// decide on.
///
/// **Confirming is the human act the whole boundary rests on.** It is
/// therefore only reachable from inside this sheet, after every line, the
/// seller and the total have been drawn. The list behind it offers no
/// confirm button, nothing is pre-selected, and there is no path that
/// confirms without the basket being on screen first.
Future<AgentProposalDecision?> showAgentProposalSheet(
  BuildContext context, {
  required AgentProposal proposal,
  DateTime Function()? clock,
}) => showModalBottomSheet<AgentProposalDecision>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => AgentProposalSheet(proposal: proposal, clock: clock),
);

@visibleForTesting
class AgentProposalSheet extends ConsumerStatefulWidget {
  const AgentProposalSheet({required this.proposal, super.key, this.clock});

  final AgentProposal proposal;
  final DateTime Function()? clock;

  @override
  ConsumerState<AgentProposalSheet> createState() => _AgentProposalSheetState();
}

class _AgentProposalSheetState extends ConsumerState<AgentProposalSheet> {
  bool _working = false;
  String? _failureCode;

  DateTime _now() => widget.clock?.call() ?? DateTime.now().toUtc();

  AgentProposal get _p => widget.proposal;

  Future<void> _decide({required bool confirm}) async {
    setState(() {
      _working = true;
      _failureCode = null;
    });
    final notifier = ref.read(agentCommerceNotifierProvider.notifier);
    final ok = confirm ? await notifier.confirm(_p) : await notifier.reject(_p);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(
        confirm
            ? AgentProposalDecision.confirmed
            : AgentProposalDecision.rejected,
      );
      return;
    }
    setState(() {
      _working = false;
      _failureCode = ref.read(agentCommerceNotifierProvider).failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final actionable = _p.actionableAt(now);
    final statusLabel = AgentCommerceCopy.proposalStatusLabel(
      _p.status,
      rawStatus: _p.rawStatus,
    );
    final total = AgentCommerceCopy.money(_p.quotedTotal, _p.currency);
    final prepared = AgentCommerceCopy.dateTime(_p.createdUtc);
    final expires = AgentCommerceCopy.dateTime(_p.expiresUtc);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              Semantics(
                header: true,
                child: const Text(
                  'The basket it prepared',
                  style: DesignTokens.h3,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              MallStatusPill(
                label: statusLabel,
                tone: AgentCommerceCopy.proposalStatusTone(_p.status),
                icon: AgentCommerceCopy.proposalStatusIcon(_p.status),
                semanticLabel: 'Status: $statusLabel',
                dense: true,
              ),
              const SizedBox(height: DesignTokens.s12),
              const Text(
                'Nothing has been bought. Read every line below — what it '
                'is, who it is from and what it costs — and then decide.',
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s16),

              // ── The basket itself ──
              if (_p.lines.isEmpty)
                const _EmptyBasketNotice()
              else
                for (final line in _p.lines) ...[
                  _ProposalLineRow(line: line),
                  const SizedBox(height: DesignTokens.s12),
                ],

              const Divider(height: DesignTokens.s24),
              _TotalRow(label: 'Total it would charge', value: total),
              const SizedBox(height: DesignTokens.s8),
              Text(
                '${_p.itemCount} item${_p.itemCount == 1 ? '' : 's'} '
                '· quoted in ${_p.currency} · prepared $prepared',
                key: const ValueKey('agent-proposal-summary-line'),
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                _p.expiredAt(now)
                    ? 'This basket expired $expires.'
                    : 'You have until $expires to decide.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s16),

              if (_failureCode != null) ...[
                AgentActionFailureNotice(
                  errorCode: _failureCode!,
                  onDismiss: () => setState(() => _failureCode = null),
                ),
                const SizedBox(height: DesignTokens.s16),
              ],

              if (actionable) ...[
                Container(
                  padding: const EdgeInsets.all(DesignTokens.s12),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.cardRadius,
                    ),
                  ),
                  child: const Text(
                    'Confirming is what lets the assistant place this order. '
                    'Until you do, it cannot — there is no permission, '
                    'header or setting that stands in for this tap.',
                    style: DesignTokens.smallDescription,
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Semantics(
                  container: true,
                  button: true,
                  enabled: !_working,
                  label:
                      'Confirm this basket of ${_p.itemCount} items '
                      'for $total',
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const ValueKey('agent-proposal-confirm-button'),
                      onPressed: _working ? null : () => _decide(confirm: true),
                      child: _working
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Confirm — $total'),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Semantics(
                  container: true,
                  button: true,
                  enabled: !_working,
                  label: 'Reject this basket. Nothing is bought.',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const ValueKey('agent-proposal-reject-button'),
                      onPressed: _working
                          ? null
                          : () => _decide(confirm: false),
                      child: const Text('Reject this basket'),
                    ),
                  ),
                ),
              ] else if (_p.status == AgentProposalStatus.unknown) ...[
                const _Notice(
                  key: ValueKey('agent-proposal-unknown-status'),
                  icon: Icons.help_outline_rounded,
                  text: AgentCommerceCopy.unknownStatusExplainer,
                ),
              ] else if (_p.expiredAt(now) && _p.status.awaitsCustomer) ...[
                const _Notice(
                  key: ValueKey('agent-proposal-expired'),
                  icon: Icons.hourglass_disabled_outlined,
                  text:
                      'This basket ran out of time, so there is nothing left '
                      'to confirm. Ask the assistant to prepare a fresh one.',
                ),
              ],
              const SizedBox(height: DesignTokens.s8),
              Semantics(
                container: true,
                button: true,
                label: 'Close without deciding',
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const ValueKey('agent-proposal-close-button'),
                    onPressed: _working
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Close without deciding'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line: what it is, who it is from, how many and what it costs.
///
/// No photograph. Product imagery lives on product detail; here the customer
/// is being asked to agree to a charge, and every pixel belongs to the facts
/// of that charge.
class _ProposalLineRow extends StatelessWidget {
  const _ProposalLineRow({required this.line});

  final AgentProposalLine line;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (line.optionLabel != null) line.optionLabel!,
      if (line.sellerHandle != null) 'from ${line.sellerHandle}',
    ];
    return Semantics(
      label:
          '${line.title}. '
          '${subtitleParts.isEmpty ? '' : '${subtitleParts.join(', ')}. '}'
          'Quantity ${line.quantity}, '
          '${AgentCommerceCopy.money(line.lineSubtotalAmount, line.currency)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.title.isEmpty ? 'Untitled product' : line.title,
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Flexible(
                child: Text(
                  AgentCommerceCopy.money(
                    line.lineSubtotalAmount,
                    line.currency,
                  ),
                  textAlign: TextAlign.end,
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitleParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitleParts.join(' · '),
                style: DesignTokens.smallDescription,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${line.quantity} × '
              '${AgentCommerceCopy.money(line.unitPriceAmount, line.currency)}',
              style: DesignTokens.smallDescription,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasketNotice extends StatelessWidget {
  const _EmptyBasketNotice();

  @override
  Widget build(BuildContext context) => const _Notice(
    key: ValueKey('agent-proposal-empty-basket'),
    icon: Icons.production_quantity_limits_outlined,
    text:
        'This basket has no readable lines. Nothing is shown because nothing '
        'came back — do not confirm a charge you cannot see. Reject it and '
        'ask the assistant to prepare it again.',
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: DesignTokens.mediumRegular.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        // Flexible, not fixed: at 320dp and 1.3x a four-figure total in a
        // three-letter currency is wider than the room left over.
        Flexible(
          child: Text(
            value,
            key: const ValueKey('agent-proposal-total'),
            textAlign: TextAlign.end,
            style: DesignTokens.h3,
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(text, style: DesignTokens.smallDescription)),
      ],
    ),
  );
}
