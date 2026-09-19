import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Surface 1 — **provisioning**. Mints a print run of per-unit tags for one
/// variant and shows their secrets **once**.
///
/// The whole screen is built around that "once". The platform stored only a
/// SHA-256 digest of each secret, so the reveal below is the only moment the
/// cleartext will ever exist outside the tag itself. The screen therefore
/// says so before the seller mints, says so again while the secrets are on
/// screen, and gives them two ways to get the values out of the app — export
/// and copy — before they are gone.
///
/// §5.9: minting prices nothing, reserves nothing and moves no money. The
/// quantity is a print run, and the screen says that rather than letting a
/// seller read it as stock.
class UnitMarkerProvisionScreen extends ConsumerStatefulWidget {
  const UnitMarkerProvisionScreen({
    required this.productVariantId,
    this.productName,
    super.key,
  });

  /// The variant these tags will belong to. A marker minted for the Medium
  /// can never become the identity of a Large.
  final String productVariantId;

  /// Shown when the caller knew it. Absent renders as absent.
  final String? productName;

  static const String title = 'Unit tags';
  static const String printRunNote =
      'Tags are labels to print, not stock. Minting them does not change '
      'your inventory, your price or anything about the listing.';
  static const String oneTimeWarning =
      'These codes are shown once and cannot be shown again. StyleMint keeps '
      'only a one-way fingerprint of each one, so nobody — not you, not '
      'support — can look them up later. Export or copy them before you '
      'leave this screen. A tag whose code is lost has to be revoked and '
      'replaced.';
  static const String revealHeading = 'Print these now';
  static const String savedLabel = 'Tags saved';
  static const String savedPrompt =
      'Press this once the codes are printed or exported. It clears them from '
      'the app.';
  static const String exportLabel = 'Export tags';
  static const String copyLabel = 'Copy code';
  static const String mintLabel = 'Mint tags';
  static const String discardedHeading = 'Codes are gone';
  static const String discardedBody =
      'The codes have been cleared from this app. These are the tag '
      'references, which are not secret and are what support will ask for.';
  static const String noVariantBody =
      'This listing has no variant yet, so there is nothing to tag. Finish '
      'the pricing and inventory step first.';

  @override
  ConsumerState<UnitMarkerProvisionScreen> createState() =>
      _UnitMarkerProvisionScreenState();
}

class _UnitMarkerProvisionScreenState
    extends ConsumerState<UnitMarkerProvisionScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unitMarkerProvisionNotifierProvider);
    final hasVariant = widget.productVariantId.isNotEmpty;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitMarkerProvisionScreen.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.productName case final name?
                  when name.trim().isNotEmpty) ...[
                Text(name, style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s12),
              ],
              if (!hasVariant)
                const _Notice(
                  icon: Icons.info_outline_rounded,
                  body: UnitMarkerProvisionScreen.noVariantBody,
                )
              else
                switch (state) {
                  UnitMarkerProvisionIdle() ||
                  UnitMarkerProvisionFailed() => _MintForm(
                    quantity: _quantity,
                    onQuantity: (value) => setState(() => _quantity = value),
                    onMint: _mint,
                    failure: state is UnitMarkerProvisionFailed
                        ? state.failure
                        : null,
                  ),
                  UnitMarkerProvisioning() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.s48),
                    child: Center(
                      child: SmBrandLoader(semanticLabel: 'Minting tags'),
                    ),
                  ),
                  UnitMarkersRevealed(:final markers) => _Reveal(
                    markers: markers,
                    onExport: () => unawaited(_export(markers)),
                    onSaved: () => ref
                        .read(unitMarkerProvisionNotifierProvider.notifier)
                        .discardSecrets(),
                  ),
                  UnitMarkerSecretsDiscarded(:final markers) => _Discarded(
                    markers: markers,
                  ),
                },
            ],
          ),
        ),
      ),
    );
  }

  void _mint() => unawaited(
    ref
        .read(unitMarkerProvisionNotifierProvider.notifier)
        .provision(
          productVariantId: widget.productVariantId,
          quantity: _quantity,
        ),
  );

  /// Hands the sheet to the OS share sheet — a printer app, a notes app, a
  /// file. This is the seller's way of getting the codes out before they are
  /// gone; the app itself writes nothing to disk.
  Future<void> _export(List<ProvisionedUnitMarker> markers) async {
    final sheet = markers
        .map((marker) => '${marker.reference}\t${marker.secret}')
        .join('\n');
    await SharePlus.instance.share(
      ShareParams(text: sheet, subject: 'StyleMint unit tags'),
    );
  }
}

class _MintForm extends StatelessWidget {
  const _MintForm({
    required this.quantity,
    required this.onQuantity,
    required this.onMint,
    this.failure,
  });

  final int quantity;
  final ValueChanged<int> onQuantity;
  final VoidCallback onMint;
  final NetworkExceptions? failure;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Notice(
        icon: Icons.inventory_2_outlined,
        body: UnitMarkerProvisionScreen.printRunNote,
      ),
      const SizedBox(height: DesignTokens.s16),
      const _Notice(
        icon: Icons.warning_amber_rounded,
        tone: _NoticeTone.warning,
        body: UnitMarkerProvisionScreen.oneTimeWarning,
      ),
      const SizedBox(height: DesignTokens.s24),
      const Text(
        'How many tags to print',
        style: DesignTokens.mediumSemibold,
      ),
      const SizedBox(height: DesignTokens.s8),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DesignTokens.s12,
        runSpacing: DesignTokens.s8,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'One fewer tag',
            onPressed: quantity > UnitMarkerProvisionNotifier.minQuantity
                ? () => onQuantity(quantity - 1)
                : null,
          ),
          Text('$quantity', style: DesignTokens.h2),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'One more tag',
            onPressed: quantity < UnitMarkerProvisionNotifier.maxQuantity
                ? () => onQuantity(quantity + 1)
                : null,
          ),
          Text(
            'up to ${UnitMarkerProvisionNotifier.maxQuantity} at a time',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
      if (failure case final problem?) ...[
        const SizedBox(height: DesignTokens.s16),
        _Notice(
          icon: Icons.error_outline_rounded,
          tone: _NoticeTone.error,
          body: NetworkExceptions.getMessage(problem),
        ),
      ],
      const SizedBox(height: DesignTokens.s24),
      SmPrimaryButton(
        label: UnitMarkerProvisionScreen.mintLabel,
        onPressed: () async => onMint(),
      ),
    ],
  );
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.markers,
    required this.onExport,
    required this.onSaved,
  });

  final List<ProvisionedUnitMarker> markers;
  final VoidCallback onExport;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        UnitMarkerProvisionScreen.revealHeading,
        style: DesignTokens.h2,
      ),
      const SizedBox(height: DesignTokens.s12),
      const _Notice(
        icon: Icons.warning_amber_rounded,
        tone: _NoticeTone.warning,
        body: UnitMarkerProvisionScreen.oneTimeWarning,
      ),
      const SizedBox(height: DesignTokens.s16),
      SmOutlinedButton(
        label: UnitMarkerProvisionScreen.exportLabel,
        onPressed: onExport,
        prefixIcon: const Icon(
          Icons.ios_share_rounded,
          size: DesignTokens.s20,
          color: DesignTokens.textWhite,
        ),
      ),
      const SizedBox(height: DesignTokens.s16),
      for (final marker in markers) ...[
        _SecretCard(marker: marker),
        const SizedBox(height: DesignTokens.s12),
      ],
      const SizedBox(height: DesignTokens.s8),
      Text(
        UnitMarkerProvisionScreen.savedPrompt,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      SmPrimaryButton(
        label: UnitMarkerProvisionScreen.savedLabel,
        onPressed: () async => onSaved(),
      ),
      const SizedBox(height: DesignTokens.s24),
    ],
  );
}

/// The only widget in the app that renders a marker secret.
///
/// It is reachable from exactly one state ([UnitMarkersRevealed]) on exactly
/// one screen, and nothing it renders is written anywhere by the app. The
/// clipboard copy is the seller's own deliberate act.
class _SecretCard extends StatelessWidget {
  const _SecretCard({required this.marker});

  final ProvisionedUnitMarker marker;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(color: DesignTokens.borderDefault),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          marker.reference,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        SelectableText(
          marker.secret,
          style: DesignTokens.oneLinerSemibold.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        SmOutlinedButton(
          label: UnitMarkerProvisionScreen.copyLabel,
          prefixIcon: const Icon(
            Icons.copy_rounded,
            size: DesignTokens.s20,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => unawaited(
            Clipboard.setData(ClipboardData(text: marker.secret)),
          ),
        ),
      ],
    ),
  );
}

class _Discarded extends StatelessWidget {
  const _Discarded({required this.markers});

  final List<UnitMarker> markers;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        UnitMarkerProvisionScreen.discardedHeading,
        style: DesignTokens.h2,
      ),
      const SizedBox(height: DesignTokens.s12),
      Text(
        UnitMarkerProvisionScreen.discardedBody,
        style: DesignTokens.body.copyWith(color: DesignTokens.textLight),
      ),
      const SizedBox(height: DesignTokens.s16),
      for (final marker in markers)
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s8),
          child: Text(marker.reference, style: DesignTokens.mediumRegular),
        ),
    ],
  );
}

enum _NoticeTone { neutral, warning, error }

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.body,
    this.tone = _NoticeTone.neutral,
  });

  final IconData icon;
  final String body;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _NoticeTone.neutral => DesignTokens.textLight,
      _NoticeTone.warning => DesignTokens.warning300,
      _NoticeTone.error => DesignTokens.colorError,
    };
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: DesignTokens.s20, color: color),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              body,
              style: DesignTokens.mediumRegular.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, color: DesignTokens.textWhite),
    style: IconButton.styleFrom(
      minimumSize: const Size(
        DesignTokens.minTouchTarget,
        DesignTokens.minTouchTarget,
      ),
      backgroundColor: DesignTokens.bgAppBodyLight,
    ),
  );
}
