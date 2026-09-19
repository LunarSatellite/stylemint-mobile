import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/parcel_code_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_acceptance_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Verified Scan-to-Receive Handover" — a "Got your parcel?" card
/// on the order detail screen. Once a StyleMint parcel is out for delivery
/// or delivered, the buyer says what arrived (All good / Something's wrong /
/// Refuse it), whether the seal was intact when the seller sealed it, and
/// what was wrong for the issue choices. After that it shows the saved
/// answer read-only. Renders nothing while checking, before the parcel is
/// out for delivery, or when a check fails.
class DeliveryAcceptanceCard extends ConsumerStatefulWidget {
  const DeliveryAcceptanceCard({
    required this.trackingNumber,
    this.items = const <OrderDetailItem>[],
    super.key,
  });

  final String trackingNumber;
  final List<OrderDetailItem> items;

  @override
  ConsumerState<DeliveryAcceptanceCard> createState() =>
      _DeliveryAcceptanceCardState();
}

class _DeliveryAcceptanceCardState
    extends ConsumerState<DeliveryAcceptanceCard> {
  final _note = TextEditingController();
  DeliveryAcceptanceOutcome? _outcome;
  bool? _sealIntact;
  late List<DeliveryReceivedItemInput> _items;
  String? _scannedTrackingCode;

  @override
  void initState() {
    super.initState();
    _items = widget.items
        .where((item) => item.id.trim().isNotEmpty)
        .map(
          (item) => DeliveryReceivedItemInput(
            subOrderLineId: item.id,
            productTitle: item.productName,
            expectedQuantity: item.qty,
            receivedQuantity: item.qty,
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = deliveryAcceptanceNotifierProvider(widget.trackingNumber);
    final state = ref.watch(provider);

    final content = switch (state) {
      DeliveryAcceptanceChecking() || DeliveryAcceptanceHidden() => null,
      final DeliveryAcceptanceAsking asking => _question(
        asking,
        ref.read(provider.notifier),
      ),
      final DeliveryAcceptanceRecorded recorded => _RecordedAnswer(
        recorded: recorded,
      ),
    };
    if (content == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Container(
        key: const ValueKey('delivery-acceptance-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: content,
      ),
    );
  }

  Widget _question(
    DeliveryAcceptanceAsking asking,
    DeliveryAcceptanceNotifier notifier,
  ) {
    final sending = asking.sending;
    final sealBroken = asking.hasSeal && _sealIntact == false;
    final outcome = _outcome;
    final acceptanceProblem = deliveryAcceptanceProblem(
      outcome: outcome,
      hasSeal: asking.hasSeal,
      sealIntact: _sealIntact,
      issueNote: _note.text,
      receivedItems: _items,
    );
    final scanMismatch =
        _scannedTrackingCode != null &&
        _scannedTrackingCode!.toLowerCase() !=
            widget.trackingNumber.toLowerCase();
    final problem = scanMismatch
        ? 'That label belongs to another parcel. Scan this parcel again.'
        : acceptanceProblem;

    void choose(DeliveryAcceptanceOutcome value) =>
        setState(() => _outcome = value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
            SizedBox(width: DesignTokens.s8),
            Text('Got your parcel?', style: DesignTokens.sectionInnerTitle),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Tell us what arrived so we can sort out any problem quickly.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(DesignTokens.s12),
            border: Border.all(
              color: (_scannedTrackingCode == null || scanMismatch)
                  ? DesignTokens.borderDefault
                  : DesignTokens.primaryGreen.withValues(alpha: .55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              children: [
                Icon(
                  _scannedTrackingCode == null
                      ? Icons.qr_code_scanner_rounded
                      : scanMismatch
                      ? Icons.error_outline_rounded
                      : Icons.verified_rounded,
                  color: scanMismatch
                      ? DesignTokens.colorError
                      : DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    _scannedTrackingCode == null
                        ? 'Scan the parcel label to verify this handover.'
                        : scanMismatch
                        ? 'This code does not match your parcel.'
                        : 'Parcel label verified',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: sending ? null : _scanParcel,
                  child: Text(_scannedTrackingCode == null ? 'Scan' : 'Rescan'),
                ),
              ],
            ),
          ),
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          Text('Check what arrived', style: _labelStyle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Confirm quantity and condition for every order item.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          for (var index = 0; index < _items.length; index++)
            _ReceivedItemEditor(
              key: ValueKey(_items[index].subOrderLineId),
              item: _items[index],
              enabled: !sending,
              onChanged: (value) => setState(() => _items[index] = value),
              onDetails: () => _editItemDetails(index),
            ),
        ],
        if (asking.hasSeal) ...[
          const SizedBox(height: DesignTokens.s16),
          Text('Was the seal intact?', style: _labelStyle),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              _ChoicePill(
                key: const ValueKey('acceptance-seal-yes'),
                label: 'Yes, it was intact',
                selected: _sealIntact == true,
                onTap: sending
                    ? null
                    : () => setState(() => _sealIntact = true),
              ),
              _ChoicePill(
                key: const ValueKey('acceptance-seal-no'),
                label: 'No, it was broken',
                selected: _sealIntact == false,
                onTap: sending
                    ? null
                    : () => setState(() {
                        _sealIntact = false;
                        // A broken seal can't be "all good".
                        if (_outcome == DeliveryAcceptanceOutcome.accepted) {
                          _outcome = null;
                        }
                      }),
              ),
            ],
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        Text('How did it go?', style: _labelStyle),
        const SizedBox(height: DesignTokens.s4),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-accepted'),
          title: 'All good',
          description: sealBroken
              ? 'Not available when the seal was broken.'
              : 'Everything arrived as expected.',
          selected: outcome == DeliveryAcceptanceOutcome.accepted,
          onTap: sending || sealBroken
              ? null
              : () => choose(DeliveryAcceptanceOutcome.accepted),
        ),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-issue'),
          title: "Something's wrong",
          description:
              'I kept it, but something is damaged, missing or not what I '
              'ordered.',
          selected: outcome == DeliveryAcceptanceOutcome.acceptedWithIssue,
          onTap: sending
              ? null
              : () => choose(DeliveryAcceptanceOutcome.acceptedWithIssue),
        ),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-refused'),
          title: 'Refuse it',
          description: "I don't want to accept this parcel.",
          selected: outcome == DeliveryAcceptanceOutcome.refused,
          onTap: sending
              ? null
              : () => choose(DeliveryAcceptanceOutcome.refused),
        ),
        if (outcome?.needsNote ?? false) ...[
          const SizedBox(height: DesignTokens.s8),
          TextField(
            key: const ValueKey('acceptance-note'),
            controller: _note,
            enabled: !sending,
            minLines: 2,
            maxLines: 4,
            maxLength: deliveryAcceptanceMaxNoteLength,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: outcome == DeliveryAcceptanceOutcome.refused
                  ? 'Why are you refusing it?'
                  : 'What was wrong?',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (asking.errorMessage != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            asking.errorMessage!,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        if (sending)
          const Center(
            child: SmBrandLoader(
              size: 40,
              semanticLabel: 'Sending your answer',
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: problem == null && outcome != null
                  ? () => notifier.submit(
                      outcome: outcome,
                      sealIntact: _sealIntact,
                      issueNote: _note.text,
                      receivedItems: _items,
                      scannedTrackingCode: _scannedTrackingCode,
                    )
                  : null,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Send answer'),
            ),
          ),
      ],
    );
  }

  Future<void> _scanParcel() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ParcelCodeScanScreen(
          expectedTrackingNumber: widget.trackingNumber,
        ),
      ),
    );
    if (mounted && code != null) setState(() => _scannedTrackingCode = code);
  }

  Future<void> _editItemDetails(int index) async {
    final item = _items[index];
    final batch = TextEditingController(text: item.batchOrLotCode ?? '');
    var expiry = item.expiryDate;
    final saved = await showDialog<DeliveryReceivedItemInput>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.productTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: batch,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Batch or lot code (optional)',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry date (optional)'),
                subtitle: Text(
                  expiry == null
                      ? 'Not recorded'
                      : DateFormat('MMM d, yyyy').format(expiry!),
                ),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        expiry ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => expiry = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                item.copyWith(
                  batchOrLotCode: batch.text.trim(),
                  clearBatch: batch.text.trim().isEmpty,
                  expiryDate: expiry,
                  clearExpiry: expiry == null,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    batch.dispose();
    if (mounted && saved != null) setState(() => _items[index] = saved);
  }

  static final TextStyle _labelStyle = DesignTokens.mediumSemibold.copyWith(
    color: DesignTokens.textWhite,
    fontSize: 14,
  );
}

class _ReceivedItemEditor extends StatelessWidget {
  const _ReceivedItemEditor({
    required this.item,
    required this.enabled,
    required this.onChanged,
    required this.onDetails,
    super.key,
  });

  final DeliveryReceivedItemInput item;
  final bool enabled;
  final ValueChanged<DeliveryReceivedItemInput> onChanged;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: DesignTokens.s8),
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      border: Border.all(color: DesignTokens.borderDefault),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Text(
              'Received',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: enabled && item.receivedQuantity > 0
                  ? () => onChanged(
                      item.copyWith(
                        receivedQuantity: item.receivedQuantity - 1,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${item.receivedQuantity} / ${item.expectedQuantity}',
              style: DesignTokens.mediumSemibold,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: enabled
                  ? () => onChanged(
                      item.copyWith(
                        receivedQuantity: item.receivedQuantity + 1,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              enabled: enabled,
              initialValue: item.condition,
              onSelected: (condition) =>
                  onChanged(item.copyWith(condition: condition)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Good', child: Text('Good')),
                PopupMenuItem(value: 'Damaged', child: Text('Damaged')),
                PopupMenuItem(value: 'WrongItem', child: Text('Wrong item')),
                PopupMenuItem(value: 'Missing', child: Text('Missing')),
                PopupMenuItem(value: 'Expired', child: Text('Expired')),
              ],
              child: Chip(
                label: Text(
                  item.condition == 'WrongItem' ? 'Wrong item' : item.condition,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: enabled ? onDetails : null,
            icon: const Icon(Icons.fact_check_outlined, size: 17),
            label: Text(
              item.batchOrLotCode == null && item.expiryDate == null
                  ? 'Add batch / expiry'
                  : 'Batch / expiry added',
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12,
            vertical: DesignTokens.s8,
          ),
          decoration: selected
              ? DesignTokens.chipDecorationSelected()
              : DesignTokens.chipDecorationDefault(),
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: selected
                  ? DesignTokens.textWhite
                  : DesignTokens.chipsDefaultText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeOption extends StatelessWidget {
  const _OutcomeOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: Opacity(
          opacity: enabled || selected ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? DesignTokens.radioIconChecked
                      : DesignTokens.radioIconDefault,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        description,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordedAnswer extends StatelessWidget {
  const _RecordedAnswer({required this.recorded});

  final DeliveryAcceptanceRecorded recorded;

  @override
  Widget build(BuildContext context) {
    final acceptance = recorded.acceptance;
    final (icon, color) = switch (acceptance.outcome) {
      DeliveryAcceptanceOutcome.accepted => (
        Icons.check_circle_outline,
        DesignTokens.primaryGreen,
      ),
      DeliveryAcceptanceOutcome.acceptedWithIssue => (
        Icons.report_problem_outlined,
        DesignTokens.warning500,
      ),
      DeliveryAcceptanceOutcome.refused => (
        Icons.block_rounded,
        DesignTokens.colorError,
      ),
      DeliveryAcceptanceOutcome.unknown => (
        Icons.info_outline,
        DesignTokens.textMuted,
      ),
    };
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final photoCount = acceptance.photoUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                deliveryAcceptanceSummary(acceptance),
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (acceptance.trackingCodeScanned || acceptance.itemsVerified) ...[
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              if (acceptance.trackingCodeScanned)
                const Chip(
                  avatar: Icon(Icons.qr_code_2_rounded, size: 17),
                  label: Text('Label scanned'),
                ),
              if (acceptance.itemsVerified)
                Chip(
                  avatar: const Icon(Icons.fact_check_outlined, size: 17),
                  label: Text(
                    '${acceptance.receivedItems.length} items checked',
                  ),
                ),
            ],
          ),
        ],
        if (acceptance.sealIntact != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            acceptance.sealIntact!
                ? 'The seal was intact.'
                : 'The seal was broken.',
            style: muted,
          ),
        ],
        if (acceptance.issueNote != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Your note: ${acceptance.issueNote}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
        if (photoCount > 0) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            photoCount == 1
                ? '1 photo attached'
                : '$photoCount photos attached',
            style: muted,
          ),
        ],
        if (recorded.notice != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(recorded.notice!, style: muted),
        ],
      ],
    );
  }
}

/// "You accepted this parcel on Sep 13, 2026." and friends, in local time.
String deliveryAcceptanceSummary(DeliveryAcceptance acceptance) {
  final recorded = acceptance.recordedUtc;
  final on = recorded == null
      ? ''
      : ' on ${DateFormat('MMM d, yyyy').format(recorded.toLocal())}';
  return switch (acceptance.outcome) {
    DeliveryAcceptanceOutcome.accepted => 'You accepted this parcel$on.',
    DeliveryAcceptanceOutcome.acceptedWithIssue =>
      'You kept this parcel and reported a problem$on.',
    DeliveryAcceptanceOutcome.refused => 'You refused this parcel$on.',
    DeliveryAcceptanceOutcome.unknown =>
      'Your answer for this parcel was saved$on.',
  };
}
