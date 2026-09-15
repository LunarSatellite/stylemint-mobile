import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/widgets/nfc_write_sheet.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/widgets/style_mint_qr.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_output.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_pdf.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What a vendor code is for, as printed on its shelf card.
class VendorCodeSubject {
  const VendorCodeSubject({
    required this.title,
    required this.storeName,
    this.storeCity,
    this.price,
  });

  /// The product's name, or the store's for a store code.
  final String title;
  final String storeName;
  final String? storeCity;

  /// Already formatted, e.g. `Rs 1,200.00`.
  final String? price;

  ShelfCardData cardFor(StyleMintCodeInfo code) => ShelfCardData(
    title: title,
    url: code.url,
    code: code.code,
    storeName: storeName,
    storeCity: storeCity,
    price: price,
  );
}

/// Opens the code for [target] — a product in a store, or the store — with
/// its QR and actions.
Future<void> showVendorCodeSheet(
  BuildContext context, {
  required VendorCodeTarget target,
  required VendorCodeSubject subject,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppBodyLight,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => VendorCodeSheet(target: target, subject: subject),
);

/// A branded QR for a product's or store's StyleMint code, with Share link,
/// Print or share shelf card, Write to NFC tag, Revoke and scan counts.
class VendorCodeSheet extends ConsumerWidget {
  const VendorCodeSheet({
    required this.target,
    required this.subject,
    super.key,
  });

  static const String revokeLabel = 'Revoke code';
  static const String revokeTitle = 'Revoke this code?';
  static const String revokeBody =
      'Printed shelf cards and NFC tags with this code stop working straight '
      'away. You can make a new code afterwards.';
  static const String revokedTitle = 'This code is switched off';
  static const String revokedBody =
      'Cards and tags with it no longer open anything. Make a new code, then '
      'print new cards and write new tags.';

  final VendorCodeTarget target;
  final VendorCodeSubject subject;

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(revokeTitle, style: DesignTokens.sectionInnerTitle),
        content: Text(
          revokeBody,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-revoke-code'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Revoke',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await ref
        .read(vendorCodeNotifierProvider(target).notifier)
        .revoke();
    if (!context.mounted) return;
    if (failure == null) {
      SmSnackbar.success(context, 'Code revoked');
    } else {
      SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = vendorCodeNotifierProvider(target);
    final state = ref.watch(provider);
    final isStore = target.productId == null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s20,
            DesignTokens.s12,
            DesignTokens.s20,
            DesignTokens.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              Text(
                subject.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                isStore ? 'Store code' : 'In ${subject.storeName}',
                textAlign: TextAlign.center,
                style: DesignTokens.smallRegular,
              ),
              const SizedBox(height: DesignTokens.s16),
              switch (state) {
                VendorCodeLoading() => const SizedBox(
                  height: 240,
                  child: SmPageLoader(),
                ),
                VendorCodeFailed(:final failure) => _LoadFailed(
                  message: NetworkExceptions.getMessage(failure),
                  onRetry: () => unawaited(ref.read(provider.notifier).load()),
                ),
                VendorCodeReady(:final code, :final revoking)
                    when code.isActive =>
                  _ActiveCode(
                    code: code,
                    subject: subject,
                    revoking: revoking,
                    onRevoke: () => unawaited(_confirmRevoke(context, ref)),
                  ),
                VendorCodeReady(:final code) => _RevokedCode(
                  code: code,
                  onNewCode: () =>
                      unawaited(ref.read(provider.notifier).load()),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCode extends StatelessWidget {
  const _ActiveCode({
    required this.code,
    required this.subject,
    required this.revoking,
    required this.onRevoke,
  });

  final StyleMintCodeInfo code;
  final VendorCodeSubject subject;
  final bool revoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StyleMintQr(
          key: const ValueKey('vendor-code-qr'),
          data: code.url,
          size: 200,
          semanticLabel: 'StyleMint QR code for ${subject.title}',
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          StyleMintCodeFormat.display(code.code),
          style: DesignTokens.sectionInnerTitle.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: DesignTokens.s4),
        SelectableText(
          code.url,
          textAlign: TextAlign.center,
          style: DesignTokens.smallRegular,
        ),
        const SizedBox(height: DesignTokens.s12),
        _CodeStatsLine(code: code.code),
        const SizedBox(height: DesignTokens.s12),
        _SheetAction(
          icon: Icons.ios_share_rounded,
          label: 'Share link',
          onTap: () => unawaited(
            SharePlus.instance.share(
              ShareParams(text: '${subject.title} on StyleMint: ${code.url}'),
            ),
          ),
        ),
        _SheetAction(
          icon: Icons.print_outlined,
          label: 'Print or share shelf card',
          onTap: () => unawaited(
            showShelfCardOutputSheet(
              context,
              documentName: 'StyleMint shelf card ${code.code}',
              fileName: 'stylemint-shelf-card-${code.code}.pdf',
              format: PdfPageFormat.a6,
              build: (mark) =>
                  ShelfCardPdf.single(subject.cardFor(code), markPng: mark),
            ),
          ),
        ),
        _SheetAction(
          icon: Icons.nfc_rounded,
          label: 'Write to NFC tag',
          onTap: () => unawaited(
            showNfcWriteSheet(
              context,
              link: StyleMintCodeLinks.nfcUrl(code.url),
            ),
          ),
        ),
        _SheetAction(
          icon: Icons.block_rounded,
          label: revoking ? 'Revoking…' : VendorCodeSheet.revokeLabel,
          destructive: true,
          onTap: revoking ? null : onRevoke,
        ),
      ],
    );
  }
}

class _RevokedCode extends StatelessWidget {
  const _RevokedCode({required this.code, required this.onNewCode});

  final StyleMintCodeInfo code;
  final VoidCallback onNewCode;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(
        Icons.link_off_rounded,
        size: 48,
        color: DesignTokens.colorError,
      ),
      const SizedBox(height: DesignTokens.s12),
      const Text(
        VendorCodeSheet.revokedTitle,
        textAlign: TextAlign.center,
        style: DesignTokens.sectionInnerTitle,
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(
        VendorCodeSheet.revokedBody,
        textAlign: TextAlign.center,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(
        'Code ${StyleMintCodeFormat.display(code.code)}',
        style: DesignTokens.smallRegular,
      ),
      const SizedBox(height: DesignTokens.s20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNewCode,
          style: DesignTokens.primaryButtonStyle(),
          child: const Text('Make a new code'),
        ),
      ),
    ],
  );
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s24),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        ElevatedButton(
          onPressed: onRetry,
          style: DesignTokens.primaryButtonStyle(),
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _CodeStatsLine extends ConsumerWidget {
  const _CodeStatsLine({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(vendorCodeStatsProvider(code))
        .when(
          loading: () =>
              const Text('Counting scans…', style: DesignTokens.smallRegular),
          error: (_, _) => const SizedBox.shrink(),
          data: (result) => result.fold(
            (_) => const Text(
              "Scan counts aren't available right now.",
              style: DesignTokens.smallRegular,
            ),
            (stats) => _StatsView(stats: stats),
          ),
        );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats});

  final CodeStats stats;

  @override
  Widget build(BuildContext context) {
    final last = stats.lastScannedUtc;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            _StatChip(value: stats.totalScans, label: 'scans'),
            _StatChip(value: stats.scansLast7Days, label: 'last 7 days'),
            _StatChip(value: stats.scansLast30Days, label: 'last 30 days'),
            _StatChip(value: stats.uniqueScanners, label: 'people'),
          ],
        ),
        const SizedBox(height: DesignTokens.s6),
        Text(
          last == null
              ? 'Not scanned yet'
              : 'Last scan ${DateFormat.yMMMd().format(last.toLocal())}',
          style: DesignTokens.smallRegular,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s12,
      vertical: DesignTokens.s6,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$value ', style: DesignTokens.mediumSemibold),
          TextSpan(text: label, style: DesignTokens.smallRegular),
        ],
      ),
    ),
  );
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? DesignTokens.colorError
        : onTap == null
        ? DesignTokens.textMuted
        : DesignTokens.textWhite;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s4,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(color: color),
              ),
            ),
            if (!destructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
              ),
          ],
        ),
      ),
    );
  }
}
