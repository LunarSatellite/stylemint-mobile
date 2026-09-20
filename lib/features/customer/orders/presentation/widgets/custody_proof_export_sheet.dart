import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Handing over the custody proof — `GET /v1/deliveries/{tracking}/custody/
/// export`, capability 31, which had no caller of any kind.
///
/// ## Why this is a share action and not a screen
///
/// The export is hashes, base64 signatures and, where one exists, a DER CMS
/// timestamp token. None of that is checkable by eye, and a screen that listed
/// it would be decoration around a document the reader cannot evaluate. The
/// question a buyer actually has — "is this chain intact?" — is already
/// answered on the custody card by `custody/verify`, in three states that keep
/// "could not check" apart from "passed".
///
/// What the export adds is the one thing the card cannot: a document somebody
/// *else* can check, against the published algorithm, without calling StyleMint
/// and without trusting StyleMint. That is an act of handing over, so the app
/// gives it a hand-over control and nothing more.
///
/// ## Why the app has to do it at all
///
/// The endpoint is authenticated and scoped to the buyer, so there is no way
/// for a buyer to obtain this document except through a client that holds
/// their session. Until now there was none, which made a buyer-facing
/// capability unreachable by any buyer.
///
/// ## Two disclosure profiles, neither preselected
///
/// `full` carries every hop fact, including geohashes of where the parcel was
/// — which is where the buyer lives. `bearer` withholds all of it. Defaulting
/// to either one chooses on the buyer's behalf what they are about to reveal,
/// so this sheet makes them pick, in the same way the pickup-counter picker
/// refuses to preselect a lone counter.
///
/// ## What this never says
///
/// The word "verified" is never composed here, and neither is any short
/// rendering of the attestation level. `self_attested` means StyleMint signed
/// its own record, and every brief phrasing of that reads as independent
/// verification. Only the server's own [CustodyProofExport.attestationMeaning]
/// is shown, verbatim, with every one of its [CustodyProofExport.limitations].
/// An export that arrives with no limitations is refused rather than shown —
/// see [CustodyProofExport.isPresentable].
class CustodyProofExportSheet extends ConsumerStatefulWidget {
  const CustodyProofExportSheet({required this.trackingNumber, super.key});

  final String trackingNumber;

  /// What a failed fetch says. It is about the request and nothing else: an
  /// export we could not produce is not a handover log that is missing, and
  /// the two must not read the same.
  static const String unavailableNote =
      'We could not produce a proof for this parcel just now. That is a '
      'statement about this request, not about the handover log — nothing '
      'here says the record is missing or wrong. Try again later.';

  static const String beforeYouSend =
      'Read this before you send it. It travels with the document, so the '
      'person you send it to sees it too.';

  /// Opens the sheet. The only entry point; the custody card's "Hand this
  /// proof to someone" button calls it.
  static Future<void> open(
    BuildContext context, {
    required String trackingNumber,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CustodyProofExportSheet(trackingNumber: trackingNumber),
  );

  @override
  ConsumerState<CustodyProofExportSheet> createState() =>
      _CustodyProofExportSheetState();
}

class _CustodyProofExportSheetState
    extends ConsumerState<CustodyProofExportSheet> {
  /// The fetched document, held only long enough for the buyer to read what
  /// travels with it and confirm. Never fetched speculatively.
  CustodyProofExport? _export;

  /// What could not be produced, in the words of the thing that failed. Null
  /// until a fetch has been attempted and has come back with nothing.
  String? _unavailable;
  bool _busy = false;

  Future<void> _fetch({required bool bearer}) async {
    setState(() {
      _busy = true;
      _unavailable = null;
    });
    final export = await ref
        .read(custodyDataSourceProvider)
        .export(widget.trackingNumber, bearer: bearer);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _export = export;
      // An export that could not be produced, or that arrived without the
      // caveats that stop it reading as an independent guarantee, is not
      // offered at all. See [CustodyProofExport.isPresentable].
      _unavailable = export == null
          ? CustodyProofExportSheet.unavailableNote
          : null;
    });
  }

  /// Hands the document over. The caveats go with it: a proof that arrives
  /// somewhere without its limitations is a proof being overstated, so they
  /// are part of the same payload rather than something the buyer read once
  /// on a screen and left behind.
  Future<void> _handOver(CustodyProofExport export) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'StyleMint custody proof — ${widget.trackingNumber}',
        text:
            'Custody proof for ${widget.trackingNumber} '
            '(${export.disclosureProfile} disclosure).\n\n'
            '${export.attestationMeaning}\n\n'
            'Limitations:\n'
            '${export.limitations.map((line) => '- $line').join('\n')}\n\n'
            '${export.json}',
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final export = _export;
    final error = _unavailable;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hand this proof to someone',
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'This gives you the handover log as a document another person '
              'can check for themselves, against the published rules, without '
              'asking StyleMint and without taking StyleMint’s word for it. '
              'It is not a new check — it is the record, sealed, so someone '
              'else can test the seal.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            if (export == null) ...[
              const Text(
                'Choose what it includes',
                style: TextStyle(
                  color: DesignTokens.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              _DisclosureOption(
                title: 'Everything, including where it went',
                // Said plainly and without euphemism. "Location data" would
                // not tell a buyer that the parcel's last hop is their
                // doorstep.
                detail:
                    'Includes every handover fact: where the parcel was at '
                    'each step, which couriers carried it, and anyone who '
                    'took it on your behalf. The places include your delivery '
                    'address. Send this only to someone you would give your '
                    'address to.',
                enabled: !_busy,
                onTap: () => _fetch(bearer: false),
              ),
              const SizedBox(height: DesignTokens.s8),
              _DisclosureOption(
                title: 'Sealed record only, safe for a stranger',
                detail:
                    'Withholds every handover fact — no places, no courier '
                    'names, no notes. The seal can still be checked. Use this '
                    'for anyone holding the parcel, or anyone you do not want '
                    'to give your address to.',
                enabled: !_busy,
                onTap: () => _fetch(bearer: true),
              ),
            ] else
              _ReviewBeforeSending(
                export: export,
                onSend: () => _handOver(export),
              ),
            if (_busy) ...[
              const SizedBox(height: DesignTokens.s16),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: DesignTokens.s16),
              Text(
                error,
                style: const TextStyle(
                  color: DesignTokens.warning500,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What the buyer reads before the document leaves the phone.
///
/// Both blocks are the server's own words. Nothing here is composed, ranked,
/// shortened or given a badge: a two-word rendering of `self_attested` is
/// exactly how a seal from the party being audited starts reading as
/// independent verification.
class _ReviewBeforeSending extends StatelessWidget {
  const _ReviewBeforeSending({required this.export, required this.onSend});

  final CustodyProofExport export;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        CustodyProofExportSheet.beforeYouSend,
        style: TextStyle(
          color: DesignTokens.textWhite,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      // The attestation, in the server's sentence and in no other form.
      Text(
        export.attestationMeaning,
        style: const TextStyle(
          color: DesignTokens.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
      ),
      const SizedBox(height: DesignTokens.s12),
      const Text(
        'What this proof does not show',
        style: TextStyle(
          color: DesignTokens.textWhite,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      for (final limitation in export.limitations) ...[
        const SizedBox(height: DesignTokens.s4),
        Text(
          '• $limitation',
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
      const SizedBox(height: DesignTokens.s16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onSend,
          style: DesignTokens.outlinedButtonStyle(),
          child: const Text('Send it'),
        ),
      ),
    ],
  );
}

class _DisclosureOption extends StatelessWidget {
  const _DisclosureOption({
    required this.title,
    required this.detail,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $detail',
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: DesignTokens.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              detail,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
