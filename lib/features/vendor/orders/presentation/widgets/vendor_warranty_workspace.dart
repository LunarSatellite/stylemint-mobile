import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_claim_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorWarrantyWorkspace extends ConsumerStatefulWidget {
  const VendorWarrantyWorkspace({super.key});

  @override
  ConsumerState<VendorWarrantyWorkspace> createState() =>
      _VendorWarrantyWorkspaceState();
}

class _VendorWarrantyWorkspaceState
    extends ConsumerState<VendorWarrantyWorkspace> {
  List<WarrantyClaim> _claims = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(_load));
  }

  Options _options(String action, String id) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': 'vendor-warranty-$action-$id',
    },
  );

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ref
          .read(apiClientProvider)
          .get(
            '/v1/vendor/warranties/claims',
          );
      final rows = (raw as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WarrantyClaimDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      if (mounted) setState(() => _claims = rows);
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'Could not load warranty claims.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post(
    WarrantyClaim claim,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    if (_busyId != null) return;
    setState(() => _busyId = claim.id);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/v1/vendor/warranties/claims/${claim.id}/$action',
            data: data,
            options: _options(action, claim.id),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warranty claim updated.')),
      );
      await _load();
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the warranty claim.')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decide(WarrantyClaim claim) async {
    final choice = await showModalBottomSheet<_WarrantyDecision>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _DecisionSheet(),
    );
    if (choice == null) return;
    await _post(
      claim,
      'decision',
      data: {
        'approve': choice.approve,
        if (choice.resolutionKind != null)
          'resolutionKind': choice.resolutionKind,
        'note': choice.note,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_claims.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.verified_user_outlined, size: 44),
            SizedBox(height: 12),
            Center(child: Text('No warranty claims need attention.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final claim = _claims[index];
          final busy = _busyId == claim.id;
          final submittedLabel =
              'Submitted ${DateFormat.yMMMd().format(
                claim.submittedUtc.toLocal(),
              )}';
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          claim.claimNumber,
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                      _StateChip(state: claim.state),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(claim.issueKind.label),
                  const SizedBox(height: 4),
                  Text(
                    claim.description,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submittedLabel,
                    style: DesignTokens.smallRegular,
                  ),
                  if (claim.decisionNote case final note?) ...[
                    const SizedBox(height: 8),
                    Text('Decision note: $note'),
                  ],
                  if (claim.evidenceUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${claim.evidenceUrls.length} evidence item(s)'),
                  ],
                  const SizedBox(height: 12),
                  if (busy)
                    const LinearProgressIndicator()
                  else
                    _ClaimActions(
                      claim: claim,
                      onDecide: () => _decide(claim),
                      onStart: () => _post(claim, 'start'),
                      onResolve: () => _post(
                        claim,
                        'resolve',
                        data: {'note': 'Resolution completed by vendor.'},
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClaimActions extends StatelessWidget {
  const _ClaimActions({
    required this.claim,
    required this.onDecide,
    required this.onStart,
    required this.onResolve,
  });

  final WarrantyClaim claim;
  final VoidCallback onDecide;
  final VoidCallback onStart;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) => switch (claim.state) {
    WarrantyClaimState.submitted => FilledButton.icon(
      onPressed: onDecide,
      icon: const Icon(Icons.gavel_outlined),
      label: const Text('Review claim'),
    ),
    WarrantyClaimState.approved => FilledButton.icon(
      onPressed: onStart,
      icon: const Icon(Icons.build_outlined),
      label: const Text('Start resolution'),
    ),
    WarrantyClaimState.repairInProgress ||
    WarrantyClaimState.replacementInProgress => FilledButton.icon(
      onPressed: onResolve,
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Mark resolved'),
    ),
    _ => const SizedBox.shrink(),
  };
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final WarrantyClaimState state;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(switch (state) {
      WarrantyClaimState.submitted => 'New',
      WarrantyClaimState.approved => 'Approved',
      WarrantyClaimState.rejected => 'Rejected',
      WarrantyClaimState.repairInProgress => 'Repairing',
      WarrantyClaimState.replacementInProgress => 'Replacing',
      WarrantyClaimState.resolved => 'Resolved',
      WarrantyClaimState.cancelled => 'Cancelled',
      WarrantyClaimState.unknown => 'Updated',
    }),
  );
}

class _WarrantyDecision {
  const _WarrantyDecision({
    required this.approve,
    required this.resolutionKind,
    required this.note,
  });
  final bool approve;
  final int? resolutionKind;
  final String? note;
}

class _DecisionSheet extends StatelessWidget {
  const _DecisionSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose a resolution', style: DesignTokens.titleMedium),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Approve for repair'),
            onTap: () => Navigator.pop(
              context,
              const _WarrantyDecision(
                approve: true,
                resolutionKind: 1,
                note: 'Approved for repair.',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Approve replacement'),
            onTap: () => Navigator.pop(
              context,
              const _WarrantyDecision(
                approve: true,
                resolutionKind: 2,
                note: 'Approved for replacement.',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Reject claim'),
            onTap: () => Navigator.pop(
              context,
              const _WarrantyDecision(
                approve: false,
                resolutionKind: null,
                note: 'Claim rejected.',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
