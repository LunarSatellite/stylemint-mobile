// Negotiation terms and proof labels intentionally remain explicit for trust.
// ignore_for_file: lines_longer_than_80_chars, sort_constructors_first

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final FutureProvider<List<AgentNegotiation>> agentNegotiationsProvider =
    FutureProvider.autoDispose<List<AgentNegotiation>>((ref) async {
      final response = await ref
          .watch(apiClientProvider)
          .get('/v1/agent-negotiations');
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AgentNegotiation.fromJson)
          .toList(growable: false);
    });

class AgentNegotiationTurn {
  const AgentNegotiationTurn({
    required this.sequence,
    required this.party,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.terms,
    required this.proofBundle,
    required this.expiresUtc,
  });

  final int sequence;
  final int party;
  final int kind;
  final double amount;
  final String currency;
  final String terms;
  final Map<String, dynamic> proofBundle;
  final DateTime expiresUtc;

  factory AgentNegotiationTurn.fromJson(Map<String, dynamic> json) =>
      AgentNegotiationTurn(
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        party: _enumValue(json['party'], const {
          'shopperagent': 1,
          'retaileragent': 2,
        }),
        kind: _enumValue(json['kind'], const {
          'proposal': 1,
          'counterproposal': 2,
          'acceptance': 3,
        }),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'NPR',
        terms: json['terms'] as String? ?? '',
        proofBundle: _proof(json['proofBundleJson']),
        expiresUtc:
            DateTime.tryParse(json['expiresUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  static Map<String, dynamic> _proof(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is! String || raw.isEmpty) return const {};
    try {
      return raw.startsWith('{') ? _decodeProof(raw) : const {};
    } on Object {
      return const {};
    }
  }

  static Map<String, dynamic> _decodeProof(String raw) {
    // Dio already ships in this feature for idempotent headers; its
    // Transformer exposes JSON decoding without a second network client.
    final decoded = const JsonDecoder().convert(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}

class AgentNegotiation {
  const AgentNegotiation({
    required this.id,
    required this.status,
    required this.expiresUtc,
    required this.authorityLimit,
    required this.currency,
    required this.turns,
  });

  final String id;
  final int status;
  final DateTime expiresUtc;
  final double authorityLimit;
  final String currency;
  final List<AgentNegotiationTurn> turns;

  factory AgentNegotiation.fromJson(Map<String, dynamic> json) =>
      AgentNegotiation(
        id: json['id'] as String? ?? '',
        status: _enumValue(json['status'], const {
          'open': 1,
          'agreementpendingcustomer': 2,
          'confirmed': 3,
          'rejected': 4,
          'expired': 5,
        }),
        expiresUtc:
            DateTime.tryParse(json['expiresUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        authorityLimit: (json['authorityLimit'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'NPR',
        turns: (json['turns'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AgentNegotiationTurn.fromJson)
            .toList(growable: false),
      );
}

int _enumValue(dynamic raw, Map<String, int> names) {
  if (raw is num) return raw.toInt();
  return names[raw?.toString().toLowerCase()] ?? 0;
}

class AgentNegotiationsScreen extends ConsumerWidget {
  const AgentNegotiationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final negotiations = ref.watch(agentNegotiationsProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Agent negotiations'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: negotiations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Empty(
          icon: Icons.cloud_off_outlined,
          title: 'Negotiations unavailable',
          body: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(agentNegotiationsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(agentNegotiationsProvider.future),
          child: items.isEmpty
              ? const _Empty(
                  icon: Icons.handshake_outlined,
                  title: 'No negotiations yet',
                  body:
                      'Offers prepared by an agent will appear here before anything can be confirmed.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    const _TrustHeader(),
                    const SizedBox(height: 16),
                    for (final item in items) ...[
                      _NegotiationCard(item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrustHeader extends StatelessWidget {
  const _TrustHeader();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF263A31), Color(0xFF101311)],
      ),
      border: Border.all(color: const Color(0x5532D477)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.gavel_rounded, color: DesignTokens.primaryGreen, size: 30),
        SizedBox(height: 12),
        Text(
          'Agents can negotiate. You decide.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Every turn carries evidence, stays inside your mandate and expires automatically. No agreement is final without you.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.45),
        ),
      ],
    ),
  );
}

class _NegotiationCard extends ConsumerStatefulWidget {
  const _NegotiationCard(this.negotiation);
  final AgentNegotiation negotiation;
  @override
  ConsumerState<_NegotiationCard> createState() => _NegotiationCardState();
}

class _NegotiationCardState extends ConsumerState<_NegotiationCard> {
  bool expanded = false;
  bool saving = false;

  String get status => switch (widget.negotiation.status) {
    1 => 'NEGOTIATING',
    2 => 'YOUR DECISION',
    3 => 'CONFIRMED',
    4 => 'REJECTED',
    5 => 'EXPIRED',
    _ => 'UNKNOWN',
  };

  Future<void> decide({required bool confirm}) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final action = confirm ? 'confirm' : 'reject';
      await ref
          .read(apiClientProvider)
          .post(
            '/v1/agent-negotiations/${widget.negotiation.id}/$action',
            options: Options(
              headers: {
                'requiresToken': true,
                'Idempotency-Key':
                    'negotiation-$action-${widget.negotiation.id}',
              },
            ),
          );
      ref.invalidate(agentNegotiationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirm ? 'Agreement confirmed.' : 'Agreement rejected.',
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your decision.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final turns = widget.negotiation.turns;
    final latest = turns.isEmpty ? null : turns.last;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171A18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.negotiation.status == 2
              ? const Color(0x8832D477)
              : const Color(0xFF303630),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2632D477),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: DesignTokens.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${turns.length}/${12} turns',
                style: const TextStyle(color: DesignTokens.textMuted),
              ),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: 14),
            Text(
              '${latest.currency} ${latest.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              latest.terms,
              style: const TextStyle(
                color: DesignTokens.textLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _ProofChips(latest.proofBundle),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            key: ValueKey('negotiation-history-${widget.negotiation.id}'),
            onPressed: () => setState(() => expanded = !expanded),
            icon: Icon(expanded ? Icons.expand_less : Icons.history_rounded),
            label: Text(
              expanded
                  ? 'Hide negotiation history'
                  : 'View negotiation history',
            ),
          ),
          if (expanded)
            for (final turn in turns) _TurnTile(turn),
          if (widget.negotiation.status == 2) ...[
            const Divider(height: 28, color: Color(0xFF303630)),
            const Text(
              'The agents agree. Nothing happens until you choose.',
              style: TextStyle(
                color: DesignTokens.textLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey(
                      'negotiation-reject-${widget.negotiation.id}',
                    ),
                    onPressed: saving ? null : () => decide(confirm: false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: ValueKey(
                      'negotiation-confirm-${widget.negotiation.id}',
                    ),
                    onPressed: saving ? null : () => decide(confirm: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      foregroundColor: const Color(0xFF07170D),
                    ),
                    child: Text(saving ? 'Saving…' : 'Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  const _TurnTile(this.turn);
  final AgentNegotiationTurn turn;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: turn.party == 1
              ? const Color(0x2632D477)
              : const Color(0x263F86FF),
          child: Icon(
            turn.party == 1 ? Icons.smart_toy_outlined : Icons.store_outlined,
            size: 16,
            color: turn.party == 1
                ? DesignTokens.primaryGreen
                : const Color(0xFF77A9FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${turn.party == 1 ? 'Your agent' : 'Retailer agent'} · ${turn.kind == 3 ? 'accepted' : 'offered'} ${turn.currency} ${turn.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                turn.terms,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProofChips extends StatelessWidget {
  const _ProofChips(this.proof);
  final Map<String, dynamic> proof;
  @override
  Widget build(BuildContext context) => proof.isEmpty
      ? const SizedBox.shrink()
      : Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in proof.entries.take(4))
              Chip(
                avatar: const Icon(Icons.verified_outlined, size: 15),
                label: Text('${entry.key}: ${entry.value}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * .22),
      Icon(icon, color: DesignTokens.primaryGreen, size: 50),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DesignTokens.textMuted, height: 1.4),
        ),
      ),
      if (onRetry != null)
        TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
