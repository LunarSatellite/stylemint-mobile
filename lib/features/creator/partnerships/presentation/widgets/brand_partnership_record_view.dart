import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_partnership_record_dto.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The brand's recorded partnership conduct, rendered for a creator who is
/// deciding whether to work with it.
///
/// ## What this will not do
///
/// This screen used to show every brand a **0.0 star rating** and
/// **"Success Rate with Creators: 0%"**, because the server blended five
/// hardcoded constants into a score nothing ever recalculated. A false
/// number about a business, shown to the people it trades with, is worse
/// than no number. So:
///
/// * There is **no score, no tier and no star rating** — nothing here
///   blends unlike things into one figure whose meaning nobody could state.
/// * **A percentage is never drawn.** Every rate appears as its fraction and
///   the server's own sentence, which names the denominator and the window.
///   A missing rate therefore cannot degrade into "0%" — the glyph, the
///   dash and the count are the only things this view can draw.
/// * **No verdict.** A low count is a fact a creator weighs, not an
///   accusation this app makes. No red, no flags, no cautionary tone, no
///   badge ranking one brand above another.
/// * State is carried by a **glyph and a word** — `MallStatusPill` always
///   draws both — never by colour, which a colour-blind reader or a phone in
///   sunlight would lose.
class BrandPartnershipRecordView extends StatefulWidget {
  const BrandPartnershipRecordView({required this.record, super.key});

  final BrandPartnershipRecordDto record;

  @override
  State<BrandPartnershipRecordView> createState() =>
      _BrandPartnershipRecordViewState();
}

class _BrandPartnershipRecordViewState
    extends State<BrandPartnershipRecordView> {
  bool _methodShown = false;

  void _toggleMethod() => setState(() => _methodShown = !_methodShown);

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    if (record.hasNoRecord) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
        children: const [
          MallEmptyState(
            icon: Icons.fact_check_outlined,
            eyebrow: 'Partnership record',
            title: 'Nothing recorded yet',
            body:
                'StyleMint holds no partnership rows for this brand. A brand '
                'that is new here, and a brand whose partnerships happen '
                'somewhere else, both read this way.',
          ),
        ],
      );
    }

    final windowDays = record.windowDays;
    final window = windowDays > 0 ? 'the last $windowDays days' : 'this window';

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        const MallEyebrow('Partnership record', maxLines: 2),
        const SizedBox(height: DesignTokens.s8),
        Semantics(
          header: true,
          child: const Text(
            "What we've recorded",
            style: DesignTokens.displaySection,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        const Text(
          'Counted from partnership rows on StyleMint. There is no score and '
          'no rating here — these are the figures and the window they cover.',
          style: _bodyStyle,
        ),
        const SizedBox(height: DesignTokens.s24),

        _RateBlock(
          icon: Icons.forum_outlined,
          label: 'Replies in partnership chats',
          rate: record.creatorChatsReplied,
          unavailable: !record.messagingRecordAvailable,
          unavailableNote:
              'StyleMint could not read the messaging record for this brand, '
              'so this is unknown rather than zero.',
          observationsNoun: 'partnership chats a creator wrote in',
          observations: record.counts.creatorChatsOpenedInWindow,
          minimumObservations: record.minimumObservations,
          window: window,
        ),
        const SizedBox(height: DesignTokens.s20),
        _RateBlock(
          icon: Icons.mark_email_read_outlined,
          label: 'Answers to creator requests',
          rate: record.creatorRequestsAnswered,
          unavailable: false,
          observationsNoun: 'requests from creators',
          observations: record.counts.creatorRequestsReceivedInWindow,
          minimumObservations: record.minimumObservations,
          window: window,
        ),

        const SizedBox(height: DesignTokens.s24),
        const Divider(height: 1, color: DesignTokens.borderDefault),
        const SizedBox(height: DesignTokens.s16),

        const MallEyebrow('Partnerships', maxLines: 2),
        const SizedBox(height: DesignTokens.s12),
        _CountRow(label: 'Active now', value: record.counts.activeNow),
        _CountRow(
          label: 'Started in $window',
          value: record.counts.startedInWindow,
        ),
        _CountRow(
          label: 'Ended in $window',
          value: record.counts.endedInWindow,
        ),
        _CountRow(
          label: 'Ended by the brand',
          value: record.counts.endedByBrandInWindow,
          indented: true,
        ),
        _CountRow(
          label: 'Ended by the creator',
          value: record.counts.endedByCreatorInWindow,
          indented: true,
        ),
        _CountRow(
          label: 'All time',
          value: record.counts.partnershipsAllTime,
        ),

        const SizedBox(height: DesignTokens.s20),
        _MethodDisclosure(
          shown: _methodShown,
          onToggle: _toggleMethod,
          record: record,
        ),
      ],
    );
  }
}

// ── One measured rate ────────────────────────────────────────────────────────

/// A rate, or the honest absence of one.
///
/// Three states, each with its own glyph and its own word:
/// * **measured** — the fraction, then the server's sentence verbatim.
/// * **too few to rate** — a dash and the count on its own. The server
///   withholds a rate below its minimum, and this must not fill that gap in.
/// * **not recorded** — the record could not be read at all, which is
///   unknown and not zero.
///
/// No branch of this widget can produce a percent sign.
class _RateBlock extends StatelessWidget {
  const _RateBlock({
    required this.icon,
    required this.label,
    required this.rate,
    required this.unavailable,
    required this.observationsNoun,
    required this.observations,
    required this.minimumObservations,
    required this.window,
    this.unavailableNote,
  });

  final IconData icon;
  final String label;
  final MeasuredRateDto? rate;

  /// The record behind this rate could not be read at all.
  final bool unavailable;
  final String? unavailableNote;

  /// Plural noun for what was counted, e.g. "requests from creators".
  final String observationsNoun;

  /// The denominator that exists even when it is too small to divide by.
  final int observations;

  final int minimumObservations;
  final String window;

  @override
  Widget build(BuildContext context) {
    final measured = rate;

    final String figure;
    final String note;
    final String pillLabel;
    final IconData pillIcon;

    if (measured != null) {
      figure = measured.fraction;
      // Verbatim. The server wrote this sentence to be exact; rephrasing it
      // is how a number becomes a verdict.
      note = measured.statement ?? _fallbackStatement(measured);
      pillLabel = 'Measured';
      pillIcon = Icons.straighten_rounded;
    } else if (unavailable) {
      figure = '--';
      note =
          unavailableNote ??
          'StyleMint could not read this record, so it is unknown rather '
              'than zero.';
      pillLabel = 'Not recorded';
      pillIcon = Icons.help_outline_rounded;
    } else {
      figure = '--';
      note = minimumObservations > 0
          ? '$observations $observationsNoun, in $window. A rate needs at '
                'least $minimumObservations, so only the count is shown.'
          : '$observations $observationsNoun, in $window. There is not enough '
                'recorded to work out a rate, so only the count is shown.';
      pillLabel = 'Too few to rate';
      pillIcon = Icons.more_horiz_rounded;
    }

    return Semantics(
      label: '$label. $figure. $pillLabel. $note',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(icon, size: 18, color: DesignTokens.textMuted),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle),
                const SizedBox(height: DesignTokens.s6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s6,
                  children: [
                    Text(figure, style: _figureStyle),
                    MallStatusPill(
                      label: pillLabel,
                      tone: MallStatusTone.neutral,
                      icon: pillIcon,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s6),
                Text(note, style: _bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Used only if the contract ever ships a rate without its sentence. It
  /// says the same three things the server's sentence says — numerator,
  /// denominator, window — and never a percentage.
  static String _fallbackStatement(MeasuredRateDto rate) {
    final days = rate.windowDays;
    return days > 0
        ? '${rate.fraction}, in the last $days days.'
        : '${rate.fraction}.';
  }
}

// ── One count ────────────────────────────────────────────────────────────────

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.label,
    required this.value,
    this.indented = false,
  });

  final String label;
  final int value;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          indented ? DesignTokens.s16 : 0,
          DesignTokens.s6,
          0,
          DesignTokens.s6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (indented) ...[
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  top: 7,
                  end: DesignTokens.s8,
                ),
                child: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            Expanded(
              child: Text(
                label,
                style: indented ? _bodyStyle : _labelStyle,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Text('$value', style: _figureStyle),
          ],
        ),
      ),
    );
  }
}

// ── How the figures were counted ─────────────────────────────────────────────

/// The method note, folded away by default so the figures lead.
///
/// The one control on this view: a 44dp target that is a button to a screen
/// reader, carries its own label and expanded state, and answers a semantics
/// tap as well as a real one.
class _MethodDisclosure extends StatelessWidget {
  const _MethodDisclosure({
    required this.shown,
    required this.onToggle,
    required this.record,
  });

  final bool shown;
  final VoidCallback onToggle;
  final BrandPartnershipRecordDto record;

  static const String _label = 'How these figures are counted';

  @override
  Widget build(BuildContext context) {
    const counted =
        'Every figure is a count of rows StyleMint wrote when a '
        'partnership was invited, requested, answered or ended. Nothing is '
        'estimated.';
    final minimum =
        'A rate is shown only where there are at least '
        '${record.minimumObservations} observations to divide by. Below '
        'that you see the count on its own.';
    const admin =
        'An ending an administrator made is counted in the total '
        'and attributed to neither side, so the two lines beneath it need '
        'not add up to it.';
    final windowEnd = record.windowEndUtc;
    final observed = record.observedUtc;
    final windowLine = windowEnd == null
        ? null
        : 'The window is the ${record.windowDays} days to '
              '${_isoDay(windowEnd)}.';

    final lines = <String>[
      counted,
      if (record.minimumObservations > 0) minimum,
      admin,
      if (record.windowDays > 0 && windowLine != null) windowLine,
      if (observed != null) 'Read from the record on ${_isoDay(observed)}.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: shown,
          label: _label,
          onTap: onToggle,
          excludeSemantics: true,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: DesignTokens.minTouchTarget,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text(_label, style: _labelStyle)),
                  const SizedBox(width: DesignTokens.s8),
                  Icon(
                    shown
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: DesignTokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (shown)
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Text(line, style: _bodyStyle),
            ),
      ],
    );
  }
}

/// The same `yyyy-MM-dd` the server's own statements use, in UTC, so a date
/// on this view never disagrees with a date inside a verbatim sentence.
String _isoDay(DateTime utc) {
  final d = utc.toUtc();
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

const TextStyle _labelStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 1.4,
  color: DesignTokens.textWhite,
);

const TextStyle _figureStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w700,
  height: 1.3,
  color: DesignTokens.textWhite,
  fontFeatures: mallTabularFigures,
);

const TextStyle _bodyStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 12.5,
  fontWeight: FontWeight.w400,
  height: 1.45,
  color: DesignTokens.textMuted,
);
