import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// What your memory is used for: four separate, revocable decisions.
//
// Rules this section is built to, in order of how easily they are lost:
//
//  1. The explanation on screen is the string that is submitted. Both read
//     `MemoryPurposeCopy.explanationOf`, never a rewrite of it, because the
//     backend stores that text as the thing the customer agreed to.
//  2. Nothing is pre-granted, and the permissive option gets no extra
//     weight — Allow and Refuse are the same widget with the same style.
//     There is no "recommended" and no default selection.
//  3. Undecided is its own standing, with its own glyph and its own word.
//     It is not drawn as off, because "nobody asked you" is not "you said
//     no", and it is not drawn as on.
//  4. Withdrawing is one visible button on the row itself. Never a
//     sub-page, never behind a menu.
//  5. Every purpose states what stops working if it is refused.
//  6. The global pause above wins over all four, and says so in one place
//     rather than leaving two controls to contradict each other on screen.

/// State vocabulary for one purpose: a word, a glyph and a tone. Colour is
/// never the only carrier — the Mall kit's pill always draws the glyph.
({String label, IconData icon, MallStatusTone tone}) _standingStyle(
  ConsentStanding standing,
) => switch (standing) {
  ConsentStanding.granted => (
    label: 'Allowed',
    icon: Icons.check_circle_outline_rounded,
    tone: MallStatusTone.success,
  ),
  ConsentStanding.legacyBasis => (
    label: 'Needs your answer',
    icon: Icons.priority_high_rounded,
    tone: MallStatusTone.caution,
  ),
  ConsentStanding.undecided => (
    label: 'Not answered',
    icon: Icons.help_outline_rounded,
    tone: MallStatusTone.neutral,
  ),
  ConsentStanding.refused => (
    label: 'Refused',
    icon: Icons.block_rounded,
    tone: MallStatusTone.danger,
  ),
  ConsentStanding.expired => (
    label: 'Lapsed',
    icon: Icons.schedule_rounded,
    tone: MallStatusTone.caution,
  ),
  ConsentStanding.pausedGlobally => (
    label: 'Paused',
    icon: Icons.pause_circle_outline_rounded,
    tone: MallStatusTone.neutral,
  ),
  ConsentStanding.unreadable => (
    label: 'Unknown',
    icon: Icons.error_outline_rounded,
    tone: MallStatusTone.caution,
  ),
};

/// The sentence under the pill. Says which of the three kinds of "off" this
/// is, in the customer's own terms.
String _standingDetail(ConsentStanding standing) => switch (standing) {
  ConsentStanding.granted => 'You said yes. You can withdraw at any time.',
  ConsentStanding.legacyBasis =>
    'This is still running on your old single setting — nobody has asked '
        'you about it on its own yet. Please tell us what you want.',
  ConsentStanding.undecided =>
    'Nobody has asked you about this yet, so it is off. Undecided is not '
        'a no — it is just not a yes.',
  ConsentStanding.refused => 'You said no, so this is off.',
  ConsentStanding.expired =>
    'Your earlier agreement has lapsed, so this is off again.',
  ConsentStanding.pausedGlobally =>
    'Paused by the switch above, so this is off whatever you choose here.',
  ConsentStanding.unreadable =>
    "We couldn't read your answer for this, so it is off. Nothing runs on "
        'a setting we are unsure about.',
};

/// The four purposes, plus anything the backend reports that this build
/// cannot name.
class MemoryConsentSection extends ConsumerWidget {
  const MemoryConsentSection({
    required this.vault,
    required this.busy,
    super.key,
  });

  final MemoryVault vault;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = [
      for (final purpose in MemoryPurpose.values)
        if (!vault.paused && vault.consentFor(purpose).needsDecision) purpose,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What your memory is used for',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.primaryGreen,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Four separate decisions. Say yes to one without saying yes to '
          'the rest, and change any of them whenever you like.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (vault.paused) const _PauseOverrideNotice(),
        if (pending.isNotEmpty) _PendingDecisionsNotice(purposes: pending),
        for (final purpose in MemoryPurpose.values)
          _PurposeCard(
            consent: vault.consentFor(purpose),
            purpose: purpose,
            paused: vault.paused,
            busy: busy,
          ),
        for (final consent in vault.unknownConsents)
          _PurposeCard(
            consent: consent,
            purpose: null,
            paused: vault.paused,
            busy: busy,
          ),
      ],
    );
  }
}

/// The pause's relationship to the four, stated once, above them.
///
/// The alternative — a pause switch and four live per-purpose switches that
/// it silently overrules — is two controls that contradict each other. So
/// while the pause is on, the rows below say "Paused", no Allow is offered,
/// and this card points at the one control that changes that.
class _PauseOverrideNotice extends StatelessWidget {
  const _PauseOverrideNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s12),
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.pause_circle_outline_rounded,
              size: 20,
              color: DesignTokens.textLight,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                'Remembering is paused, so none of these four run — '
                'whatever you choose here. Your answers are kept and apply '
                'again the moment you switch remembering back on above.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says that some purposes are unanswered, and why that happened. It sits
/// in the flow rather than over it: no modal, no dimmed screen, nothing
/// blocked behind it, because a consent wall is a way of collecting a yes
/// rather than a way of asking for one.
class _PendingDecisionsNotice extends StatelessWidget {
  const _PendingDecisionsNotice({required this.purposes});

  final List<MemoryPurpose> purposes;

  @override
  Widget build(BuildContext context) {
    final count = purposes.length;
    final noun = count == 1 ? 'one of these' : '$count of these';
    return Semantics(
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s12),
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.priority_high_rounded,
                  size: 20,
                  color: DesignTokens.warning300,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    'We still need your answer',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s6),
            Text(
              'We used to ask about all of this with one switch. It has '
              'become four, and $noun is still running on your old answer '
              'or on no answer at all. Each one below is yours to allow or '
              'refuse.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One purpose: what it is, what it costs to refuse, where it stands, and
/// the controls to change it.
class _PurposeCard extends ConsumerWidget {
  const _PurposeCard({
    required this.consent,
    required this.purpose,
    required this.paused,
    required this.busy,
  });

  final MemoryConsent consent;

  /// Null for a purpose this build cannot name. It is still listed and
  /// still refusable; it just cannot be agreed to, because we have no
  /// explanation to show and an unexplained yes is not consent.
  final MemoryPurpose? purpose;

  final bool paused;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = consent.standingWhilePaused(paused: paused);
    final style = _standingStyle(standing);
    final named = purpose;
    final title = named == null
        ? 'A newer use of your memory'
        : MemoryPurposeCopy.titleOf(named);
    final explanation = named == null
        ? 'This app build does not recognise this use yet, so it cannot '
              'describe it to you. You can still refuse it here, and '
              'updating the app will explain it.'
        : MemoryPurposeCopy.explanationOf(named);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MallStatusPill(
              label: style.label,
              tone: style.tone,
              icon: style.icon,
              semanticLabel: named == null
                  ? '$title: ${style.label}'
                  : '${MemoryPurposeCopy.titleOf(named)}: ${style.label}',
              dense: true,
            ),
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            _standingDetail(standing),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          // The text the customer is being asked to agree to. It is always
          // on screen beside the choice, never folded away behind a "learn
          // more", and it is the exact string submitted with a grant.
          Text(
            explanation,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          if (consent.expiresUtc != null) ...[
            const SizedBox(height: DesignTokens.s6),
            Text(
              'Your agreement lapses on ${_formatDate(consent.expiresUtc!)}.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          _PurposeActions(
            consent: consent,
            purpose: named,
            standing: standing,
            explanation: explanation,
            busy: busy,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Allow and Refuse, drawn identically.
///
/// Both are the same widget with the same border, the same text style and
/// the same size. Neither is filled, neither is first by default, and there
/// is no badge on either. The only difference is the glyph and the word,
/// which is what the choice actually is.
class _PurposeActions extends ConsumerWidget {
  const _PurposeActions({
    required this.consent,
    required this.purpose,
    required this.standing,
    required this.explanation,
    required this.busy,
  });

  final MemoryConsent consent;
  final MemoryPurpose? purpose;
  final ConsentStanding standing;
  final String explanation;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: the vault notifier is auto-disposing, and these
    // buttons must keep it alive on their own rather than relying on some
    // ancestor happening to be listening.
    final notifier = ref.watch(memoryVaultNotifierProvider.notifier);
    final named = purpose;
    final spoken = named == null
        ? 'this newer use of your memory'
        : MemoryPurposeCopy.spokenNameOf(named);

    void allow() {
      if (named == null) return;
      unawaited(notifier.grantPurpose(named, explanation));
      _tellStorefront(ref, named);
    }

    void refuse() {
      unawaited(notifier.revokePurpose(consent.purposeCode));
      if (named != null) _tellStorefront(ref, named);
    }

    final canAllow = named != null && standing != ConsentStanding.granted;
    final withdrawOnly = standing == ConsentStanding.granted;

    if (standing == ConsentStanding.pausedGlobally) {
      // No Allow while paused: it would be a control that does nothing,
      // sitting next to the switch that overrules it. Withdrawing still
      // works, and still means something, so it stays one tap away.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Switch remembering back on above to choose this one.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _ConsentButton(
            label: 'Withdraw',
            icon: Icons.block_rounded,
            semanticLabel: 'Withdraw $spoken',
            onPressed: busy ? null : refuse,
            danger: true,
          ),
        ],
      );
    }

    if (withdrawOnly) {
      return _ConsentButton(
        label: 'Withdraw',
        icon: Icons.block_rounded,
        semanticLabel: 'Withdraw $spoken',
        onPressed: busy ? null : refuse,
        danger: true,
      );
    }

    if (standing == ConsentStanding.refused) {
      return _ConsentButton(
        label: 'Allow',
        icon: Icons.check_rounded,
        semanticLabel: 'Allow $spoken',
        onPressed: busy || !canAllow ? null : allow,
      );
    }

    // Undecided, legacy basis, lapsed or unreadable: a real question, asked
    // with both answers offered and neither one preselected.
    //
    // They stack rather than sit side by side so that both are exactly the
    // same width at every text size. Two halves of a 320dp row cannot hold
    // "Refuse" at 1.3x without clipping, and the fix for that — shrinking
    // one of them — is the thumb on the scale this screen exists to avoid.
    return Column(
      children: [
        if (canAllow) ...[
          _ConsentButton(
            label: 'Allow',
            icon: Icons.check_rounded,
            semanticLabel: 'Allow $spoken',
            onPressed: busy ? null : allow,
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        _ConsentButton(
          label: 'Refuse',
          icon: Icons.block_rounded,
          semanticLabel: 'Refuse $spoken',
          onPressed: busy ? null : refuse,
          danger: true,
        ),
      ],
    );
  }

  /// The Mall caches its personalisation answer for a few minutes. A
  /// decision here should take effect on the next screen, not in five.
  void _tellStorefront(WidgetRef ref, MemoryPurpose purpose) {
    if (purpose != MemoryPurpose.storefrontPersonalisation) return;
    ref.read(storefrontPersonalizerProvider).forgetConsent();
  }
}

/// One choice. Semantics carry the purpose's name as well as the verb, so
/// "Allow" does not arrive four times in a row with nothing to tell the
/// four apart, and the tap action rides on the same node as the label.
class _ConsentButton extends StatelessWidget {
  const _ConsentButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Tints the ink for a refusal. It does not change the weight, the size
  /// or the shape: the two answers stay equally reachable.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ink = danger ? DesignTokens.colorError : DesignTokens.textWhite;
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: ink.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }
}
