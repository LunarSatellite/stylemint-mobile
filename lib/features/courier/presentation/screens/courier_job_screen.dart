import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_delivery_qr_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_hop_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_job_map.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/live_refresh.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// One delivery, start to finish: the map, the parcel, the people at each
/// end, and the one thing to do next.
///
/// Opened from the dashboard's active job, from an offer the rider has just
/// been chosen for, and from the `delivery.selected` notification
/// (`/courier/jobs/{hopId}`).
///
/// The primary action follows the job: "Picked up" at the shop, "Complete
/// ride" at the door (which shows the recipient a QR to scan), "Show QR
/// again" while that is pending, and a summary once delivered.
class CourierJobScreen extends ConsumerWidget {
  const CourierJobScreen({
    required this.hopId,
    this.hop,
    this.courierProfileId,
    super.key,
  });

  final String hopId;

  /// The custody hop behind this job, when the dashboard opened it. Only
  /// used to keep the signed-handover and problem-report screen one tap away.
  final DeliveryHop? hop;
  final String? courierProfileId;

  static const primaryActionKey = ValueKey<String>('courier-job-primary');
  static const copyPackageKey = ValueKey<String>('courier-job-copy-package');

  /// How much of the screen the sheet covers at rest — enough for the
  /// package number, the status and the action, with the map above.
  static const double _sheetRest = 0.42;

  /// Polled every 10 s until delivered or cancelled — the recipient's
  /// confirmation, or a vendor's handover, can land at any moment.
  static Duration? pollIntervalFor(CourierJob? job) =>
      job == null || job.status.isFinished
      ? null
      : const Duration(seconds: 10);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(courierJobProvider(hopId));
    final hop = this.hop;
    final profileId = courierProfileId;

    // Updates by itself until the job is finished: a push or live event
    // about this hop re-reads it, and it is polled every 10 s as the
    // backstop. The re-read is silent (the map and sheet stay).
    final current = job.value;
    return LiveRefresh(
      scopes: const {LiveScope.courierJobs},
      interval: CourierJobScreen.pollIntervalFor(current),
      accepts: (signal) => signal.hopId == null || signal.hopId == hopId,
      onRefresh: () async {
        ref.invalidate(courierJobProvider(hopId));
        await ref.read(courierJobProvider(hopId).future);
      },
      child: Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Delivery'),
        actions: [
          if (hop != null && profileId != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (_) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CourierHopScreen(hop: hop, courierProfileId: profileId),
                ),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'custody',
                  child: Text('Signed handover or report a problem'),
                ),
              ],
            ),
        ],
      ),
      // After "Picked up" (and on every live refresh) the job is re-read. A
      // failed or slow re-read must not swap the map — markers, route and
      // "Open in Google Maps" — for an error page or a loader: the last good
      // job stays on screen. The error page is only for a first load.
      body: job.when(
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const Center(child: SmBrandLoader()),
        error: (error, _) => _LoadFailed(
          message: error is NetworkExceptions
              ? NetworkExceptions.getMessage(error)
              : "Couldn't load this delivery.",
          onRetry: () => ref.invalidate(courierJobProvider(hopId)),
        ),
        data: (job) => LayoutBuilder(
          builder: (context, constraints) {
            final sheetRest = constraints.maxHeight * _sheetRest;
            return Stack(
              children: [
                Positioned.fill(
                  child: CourierJobMap(
                    // Keyed by the hop, so the rider's dot, the planned
                    // route and the camera survive the job being re-read.
                    key: ValueKey<String>('courier-job-map-${job.hopId}'),
                    job: job,
                    topInset: MediaQuery.paddingOf(context).top + kToolbarHeight,
                    bottomInset: sheetRest,
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: _sheetRest,
                  minChildSize: 0.18,
                  maxChildSize: 0.9,
                  builder: (context, controller) =>
                      _JobSheet(job: job, controller: controller),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

/// Everything about the parcel, under the map. The primary action sits near
/// the top so it is visible with the sheet at rest.
class _JobSheet extends ConsumerWidget {
  const _JobSheet({required this.job, required this.controller});

  final CourierJob job;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cash = job.cashToCollect;
    final declared = job.declaredValue;
    final notes = job.notes;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 18)],
      ),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(courierJobProvider(job.hopId)),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            DesignTokens.s20,
            DesignTokens.s8,
            DesignTokens.s20,
            DesignTokens.s24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _PackageHeader(job: job),
            const SizedBox(height: DesignTokens.s12),
            if (cash != null) ...[
              _CashBanner(amount: formatMoney(cash)),
              const SizedBox(height: DesignTokens.s12),
            ],
            _PrimaryAction(job: job),
            const SizedBox(height: DesignTokens.s20),
            _StopCard(
              title: 'Pick-up',
              icon: Icons.storefront_rounded,
              color: DesignTokens.primaryGreen,
              stop: job.pickup,
            ),
            const SizedBox(height: DesignTokens.s12),
            _StopCard(
              title: 'Drop-off',
              icon: Icons.home_rounded,
              color: DesignTokens.colorError,
              stop: job.dropoff,
            ),
            const SizedBox(height: DesignTokens.s20),
            Text(
              job.itemCount == 1
                  ? 'In the parcel · 1 item'
                  : 'In the parcel · ${job.itemCount} items',
              style: DesignTokens.mediumSemibold,
            ),
            const SizedBox(height: DesignTokens.s8),
            if (job.items.isEmpty)
              Text(
                'No item details were sent for this parcel.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              )
            else
              ...job.items.map((item) => _ItemRow(item: item)),
            if (declared != null) ...[
              const SizedBox(height: DesignTokens.s8),
              _InfoRow(label: 'Declared value', value: formatMoney(declared)),
            ],
            if (notes != null) ...[
              const SizedBox(height: DesignTokens.s12),
              _Notes(notes: notes),
            ],
          ],
        ),
      ),
    );
  }
}

class _PackageHeader extends StatelessWidget {
  const _PackageHeader({required this.job});

  final CourierJob job;

  @override
  Widget build(BuildContext context) {
    final payout = job.payout;
    final distance = job.distanceKm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  SelectableText(
                    job.packageNumber.isEmpty ? '—' : job.packageNumber,
                    style: DesignTokens.h3,
                  ),
                ],
              ),
            ),
            if (job.packageNumber.isNotEmpty)
              IconButton(
                key: CourierJobScreen.copyPackageKey,
                tooltip: 'Copy package number',
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: job.packageNumber),
                  );
                  if (context.mounted) {
                    SmSnackbar.success(context, 'Package number copied');
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(status: job.status),
            if (payout != null)
              Text(
                'You earn ${formatMoney(payout)}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (distance != null)
              Text(
                '${distance.toStringAsFixed(1)} km run',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final CourierJobStatus status;

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = switch (status) {
      CourierJobStatus.delivered => (
        DesignTokens.statusCompletedBg,
        DesignTokens.statusCompletedIcon,
      ),
      CourierJobStatus.cancelled => (
        DesignTokens.statusRemainingBg,
        DesignTokens.statusRemainingIcon,
      ),
      CourierJobStatus.awaitingConfirmation => (
        DesignTokens.warningFillDark,
        DesignTokens.colorWarning,
      ),
      _ => (DesignTokens.statusOngoingBg, DesignTokens.statusOngoingIcon),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s4,
        ),
        child: Text(
          status.label,
          style: DesignTokens.tiny.copyWith(
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Cash on delivery: impossible to miss, because collecting it is part of
/// completing the run.
class _CashBanner extends StatelessWidget {
  const _CashBanner({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.warningFillDark,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(color: DesignTokens.colorWarning),
    ),
    child: Row(
      children: [
        const Icon(Icons.payments_rounded, color: DesignTokens.colorWarning),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Text(
            'Collect $amount in cash',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.warningTextLight,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The one thing to do next, by status.
class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.job});

  final CourierJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(courierJobActionsNotifierProvider);

    switch (job.status) {
      case CourierJobStatus.assigned:
        return _ActionButton(
          label: 'Picked up',
          icon: Icons.inventory_2_rounded,
          busy: busy,
          onPressed: () => _pickUp(context, ref),
        );
      case CourierJobStatus.pickedUp:
        return _ActionButton(
          label: 'Complete ride',
          icon: Icons.qr_code_2_rounded,
          busy: busy,
          onPressed: () => _complete(context, ref),
        );
      case CourierJobStatus.awaitingConfirmation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The recipient has not scanned your QR yet.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s8),
            _ActionButton(
              label: 'Show QR again',
              icon: Icons.qr_code_2_rounded,
              busy: busy,
              onPressed: () => _complete(context, ref),
            ),
          ],
        );
      case CourierJobStatus.delivered:
        final at = job.deliveredUtc;
        return Container(
          key: CourierJobScreen.primaryActionKey,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.statusCompletedBg,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivered ✓', style: DesignTokens.mediumSemibold),
                    if (at != null)
                      Text(
                        DateFormat('d MMM, h:mm a').format(at.toLocal()),
                        style: DesignTokens.tiny,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case CourierJobStatus.cancelled:
        return Text(
          key: CourierJobScreen.primaryActionKey,
          'This delivery was cancelled. Nothing more to do.',
          style: DesignTokens.smallRegular,
        );
    }
  }

  Future<void> _pickUp(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: const Text('Picked up the parcel?'),
        content: Text(
          'Confirm you have ${job.packageNumber.isEmpty ? 'the parcel' : job.packageNumber} '
          'from ${job.pickup.label ?? 'the shop'}. The recipient is told it '
          'is on the way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, picked up'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(courierJobActionsNotifierProvider.notifier)
        .markPickedUp(job.hopId);
    if (!context.mounted) return;
    result.fold(
      (failure) =>
          SmSnackbar.error(context, NetworkExceptions.getMessage(failure)),
      (_) {
        ref
          ..invalidate(courierJobProvider(job.hopId))
          ..invalidate(courierHopsProvider);
        SmSnackbar.success(context, 'Picked up. Head to the drop-off.');
      },
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(courierJobActionsNotifierProvider.notifier)
        .complete(job.hopId);
    if (!context.mounted) return;
    await result.fold(
      (failure) async =>
          SmSnackbar.error(context, NetworkExceptions.getMessage(failure)),
      (proof) async {
        // Awaiting confirmation from here on, whatever happens on the QR
        // screen.
        ref.invalidate(courierJobProvider(job.hopId));
        final delivered = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                CourierDeliveryQrScreen(hopId: job.hopId, initialProof: proof),
          ),
        );
        if (!context.mounted) return;
        ref.invalidate(courierJobProvider(job.hopId));
        if (delivered != true) return;
        ref
          ..invalidate(courierHopsProvider)
          ..invalidate(courierJobsProvider)
          ..invalidate(courierEarningsProvider);
        // Back to the dashboard: this job is done.
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          GoRouter.maybeOf(context)?.go(RouteNames.courier);
        }
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: DesignTokens.buttonHeight,
    child: FilledButton.icon(
      key: CourierJobScreen.primaryActionKey,
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(
        label,
        style: DesignTokens.mediumSemibold.copyWith(
          color: DesignTokens.textDark,
        ),
      ),
    ),
  );
}

/// The shop or the door: who, where, and a call button when there is a
/// number.
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stop,
  });

  final String title;
  final IconData icon;
  final Color color;
  final CourierJobStop stop;

  @override
  Widget build(BuildContext context) {
    final phone = stop.contactPhone;
    final contact = stop.contactName;
    final address = stop.addressLine;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                Text(
                  stop.label ?? contact ?? '—',
                  style: DesignTokens.mediumSemibold,
                ),
                if (address != null)
                  Text(address, style: DesignTokens.smallRegular),
                if (contact != null && contact != stop.label)
                  Text(
                    contact,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null)
            IconButton.filledTonal(
              tooltip: 'Call ${stop.label ?? contact ?? title}',
              icon: const Icon(Icons.call_rounded),
              onPressed: () => callPhone(context, phone),
            ),
        ],
      ),
    );
  }
}

/// Starts a phone call, or says why it could not — a tablet or an emulator
/// has no dialler, and a silent tap reads as a broken button.
Future<void> callPhone(BuildContext context, String phone) async {
  final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  var launched = false;
  try {
    launched = await launchUrl(Uri(scheme: 'tel', path: number));
  } on Object {
    launched = false;
  }
  if (!launched && context.mounted) {
    SmSnackbar.error(context, "Couldn't start a call. The number is $phone.");
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final CourierJobItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: SizedBox.square(
              dimension: 44,
              child: image == null
                  ? const _ThumbPlaceholder()
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular,
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Text('× ${item.quantity}', style: DesignTokens.mediumSemibold),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: DesignTokens.bgAppBodyLight,
    child: Icon(
      Icons.inventory_2_outlined,
      size: 20,
      color: DesignTokens.textMuted,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ),
      Text(value, style: DesignTokens.mediumSemibold),
    ],
  );
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.infoFillDark,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.infoTextLight),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(notes, style: DesignTokens.smallRegular),
      ],
    ),
  );
}
