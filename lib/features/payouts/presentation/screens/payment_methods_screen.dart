import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/notifiers/payout_destinations_controller.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Payment Methods — manage saved payout destinations.
/// Pixel-matched to Creator/Brand 'Payment Methods' / 'Add Payment Method' /
/// 'Add Bank Method' PDFs. Shared by creators and vendors via [role].
/// Backend: `/v1/payout-destinations` (list / create / {id}/default / DELETE).
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key, this.role = PayeeKind.creator});

  final PayeeKind role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = payoutDestinationsControllerProvider(role.value);
    final state = ref.watch(provider);

    ref.listen<PayoutDestinationsState>(provider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title:
            const Text('Payment Methods', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen))
          : RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: () => ref.read(provider.notifier).load(),
              child: state.items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: DesignTokens.textMuted),
                        SizedBox(height: DesignTokens.s12),
                        Center(
                          child: Text('No payment methods yet',
                              style: DesignTokens.bodyText),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(DesignTokens.s16),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DesignTokens.s12),
                      itemBuilder: (_, i) => _DestinationCard(
                        destination: state.items[i],
                        onSetDefault: () => ref
                            .read(provider.notifier)
                            .makeDefault(state.items[i].id),
                        onRemove: () =>
                            ref.read(provider.notifier).remove(state.items[i].id),
                      ),
                    ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: SmPrimaryButton(
            label: 'Add Payment Method',
            height: DesignTokens.buttonHeight,
            borderRadius: DesignTokens.buttonRadius,
            color: DesignTokens.primaryGreen,
            labelColor: DesignTokens.buttonPrimaryText,
            disabled: state.isMutating,
            onPressed: () => _showAddSheet(context, ref, provider),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    StateNotifierProvider<PayoutDestinationsController, PayoutDestinationsState>
        provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBodyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => _AddDestinationSheet(
        onSubmit: (kind, label, identifier, branch, makeDefault) async {
          final ok = await ref.read(provider.notifier).add(
                kind: kind.value,
                label: label,
                accountIdentifier: identifier,
                branchOrIfsc: branch,
                makeDefault: makeDefault,
              );
          if (ok && sheetCtx.mounted) Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.destination,
    required this.onSetDefault,
    required this.onRemove,
  });

  final PayoutDestinationDto destination;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: destination.isDefault
              ? DesignTokens.primaryGreen
              : DesignTokens.borderDefault,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_outlined,
              color: DesignTokens.primaryGreen),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.mediumSemibold),
                    ),
                    if (destination.isDefault) ...[
                      const SizedBox(width: DesignTokens.s8),
                      _DefaultBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${destination.kind.label} • ${destination.accountIdentifierMasked}',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: DesignTokens.iconLight),
            color: DesignTokens.bgAppBody,
            onSelected: (v) {
              if (v == 'default') onSetDefault();
              if (v == 'remove') onRemove();
            },
            itemBuilder: (_) => [
              if (!destination.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as default',
                      style: TextStyle(color: DesignTokens.textWhite)),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove',
                    style: TextStyle(color: DesignTokens.colorError)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.chipsSelectedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Default',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.primaryGreen)),
    );
  }
}

class _AddDestinationSheet extends StatefulWidget {
  const _AddDestinationSheet({required this.onSubmit});

  final Future<void> Function(
    PayoutDestinationKind kind,
    String label,
    String accountIdentifier,
    String? branchOrIfsc,
    bool makeDefault,
  ) onSubmit;

  @override
  State<_AddDestinationSheet> createState() => _AddDestinationSheetState();
}

class _AddDestinationSheetState extends State<_AddDestinationSheet> {
  PayoutDestinationKind _kind = PayoutDestinationKind.nimbBank;
  final _labelCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _makeDefault = false;
  bool _submitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _idCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _labelCtrl.text.trim().isNotEmpty &&
      _idCtrl.text.trim().isNotEmpty &&
      (!_kind.requiresBranch || _branchCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Payment Method', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s16),
            Wrap(
              spacing: DesignTokens.s8,
              children: [
                for (final k in PayoutDestinationKind.values)
                  ChoiceChip(
                    label: Text(k.label),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                    backgroundColor: DesignTokens.bgAppFoundation,
                    selectedColor: DesignTokens.chipsSelectedFill,
                    labelStyle: DesignTokens.smallRegular.copyWith(
                      color: _kind == k
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textLight,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            _field(_labelCtrl, 'Label (e.g. My salary account)'),
            const SizedBox(height: DesignTokens.s12),
            _field(_idCtrl, _kind.identifierHint),
            if (_kind.requiresBranch) ...[
              const SizedBox(height: DesignTokens.s12),
              _field(_branchCtrl, 'Branch / IFSC'),
            ],
            const SizedBox(height: DesignTokens.s8),
            CheckboxListTile(
              value: _makeDefault,
              onChanged: (v) => setState(() => _makeDefault = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: DesignTokens.primaryGreen,
              title: Text('Set as default', style: DesignTokens.bodyText),
            ),
            const SizedBox(height: DesignTokens.s8),
            SmPrimaryButton(
              label: 'Save',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              disabled: !_valid || _submitting,
              isLoadingInitially: _submitting,
              onPressed: () async {
                setState(() => _submitting = true);
                await widget.onSubmit(
                  _kind,
                  _labelCtrl.text.trim(),
                  _idCtrl.text.trim(),
                  _kind.requiresBranch ? _branchCtrl.text.trim() : null,
                  _makeDefault,
                );
                if (mounted) setState(() => _submitting = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      style: DesignTokens.bodyText,
      cursorColor: DesignTokens.primaryGreen,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DesignTokens.bodyText.copyWith(color: DesignTokens.textMuted),
        filled: true,
        fillColor: DesignTokens.inputFieldFill,
        contentPadding: const EdgeInsets.all(DesignTokens.s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.primaryGreen),
        ),
      ),
    );
  }
}
