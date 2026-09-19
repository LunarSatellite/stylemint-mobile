import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/notifiers/evidence_answer_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/widgets/evidence_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// An answer that carries its evidence, or no answer at all.
///
/// Five rules hold this widget together:
///
/// 1. The evidence is the body of the reply, drawn in full and never folded
///    behind a chevron. The backend's prose summary sits *after* it, so the
///    claim cannot be read without what it rests on.
/// 2. Nothing is drawn that the backend did not send. There is no confidence
///    this file computes, no star, no "verified" badge, no freshness guess.
///    Every number on screen came off the wire.
/// 3. The as-of moment is said in plain words, including when it is in the
///    past.
/// 4. An answer with no evidence is not presented as an answer. The prose is
///    suppressed entirely and only the backend's own limitations are shown.
/// 5. Nothing here mutates. There is no add-to-bag, no reserve, no price.
///    The only navigation is a plain push to a product page the customer
///    chooses to open — §5.9's "explicit customer action through existing
///    guarded paths".
class EvidenceAnswerPanel extends ConsumerStatefulWidget {
  const EvidenceAnswerPanel({
    required this.familyKey,
    super.key,
    this.seedQuery = '',
    this.currentProductId,
    this.now,
    this.autoAsk = false,
  });

  /// Scopes the answer state to this surface.
  final String familyKey;

  /// Pre-filled question, e.g. a product name on its own page.
  final String seedQuery;

  /// Product whose page this panel sits on, so a fact about it does not
  /// offer a link back to where the reader already is.
  final String? currentProductId;

  /// Injectable clock. Tests pass a fixed instant; production passes null.
  final DateTime? now;

  /// Ask [seedQuery] as soon as the panel mounts.
  final bool autoAsk;

  static const Key askKey = Key('evidence-ask');
  static const Key fieldKey = Key('evidence-question');
  static const Key listKey = Key('evidence-facts');

  @override
  ConsumerState<EvidenceAnswerPanel> createState() =>
      _EvidenceAnswerPanelState();
}

class _EvidenceAnswerPanelState extends ConsumerState<EvidenceAnswerPanel> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.seedQuery,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoAsk && widget.seedQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_ask());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(evidenceAnswerProvider(widget.familyKey).notifier).ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceAnswerProvider(widget.familyKey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MallSectionHeader(
          title: 'Ask, and see the evidence',
          eyebrow: 'Evidence-backed',
          subtitle:
              'Answers here are built only from records that were true at '
              'the moment they were read. Every one is shown.',
          padding: EdgeInsets.only(bottom: DesignTokens.s12),
        ),
        _Composer(
          controller: _controller,
          asking: state.asking,
          onAsk: _ask,
        ),
        const SizedBox(height: DesignTokens.s12),
        _Result(
          state: state,
          now: widget.now,
          currentProductId: widget.currentProductId,
          onRetry: _ask,
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.asking,
    required this.onAsk,
  });

  final TextEditingController controller;
  final bool asking;
  final Future<void> Function() onAsk;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            textField: true,
            label: 'Ask a question about this product',
            child: TextField(
              key: EvidenceAnswerPanel.fieldKey,
              controller: controller,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.textWhite,
              ),
              decoration: const InputDecoration(
                hintText: 'What would you like to know?',
                counterText: '',
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Semantics(
          button: true,
          enabled: !asking,
          label: 'Ask and show the evidence',
          excludeSemantics: true,
          child: IconButton(
            key: EvidenceAnswerPanel.askKey,
            onPressed: asking ? null : () => unawaited(onAsk()),
            icon: asking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            style: IconButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreenDark,
              foregroundColor: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.state,
    required this.now,
    required this.currentProductId,
    required this.onRetry,
  });

  final EvidenceAnswerState state;
  final DateTime? now;
  final String? currentProductId;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.asking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = state.error;
    if (error != null) {
      return MallErrorState(
        title: 'That question could not be answered',
        body: 'Nothing was shown because nothing could be checked.',
        detail: error,
        onRetry: () => unawaited(onRetry()),
        icon: Icons.fact_check_outlined,
      );
    }
    final answer = state.answer;
    if (answer == null) return const SizedBox.shrink();

    // Rule 4. Evidence is what makes this an answer; without it there is
    // nothing to show but the backend's own account of why.
    if (!answer.hasEvidence) {
      return _NoEvidence(answer: answer, now: now);
    }
    return _Answered(
      answer: answer,
      now: now,
      currentProductId: currentProductId,
    );
  }
}

/// What silence looks like: the question, the caveats the backend wrote, and
/// no claim of any kind.
class _NoEvidence extends StatelessWidget {
  const _NoEvidence({required this.answer, required this.now});

  final EvidenceAnswer answer;
  final DateTime? now;

  static const Key rootKey = Key('evidence-none');

  @override
  Widget build(BuildContext context) {
    final asOf = answer.asOfUtc;
    return Column(
      key: rootKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MallEmptyState(
          icon: Icons.search_off_rounded,
          eyebrow: 'Nothing to stand on',
          title: 'No evidence answers this yet',
          body:
              'There are no records this answer could rest on, so no answer '
              'is shown. Nothing has been guessed in its place.',
        ),
        if (asOf != null) ...[
          const SizedBox(height: DesignTokens.s12),
          _AsOfLine(asOfUtc: asOf, now: now),
        ],
        if (answer.limitations.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          _Limitations(limitations: answer.limitations),
        ],
      ],
    );
  }
}

class _Answered extends StatelessWidget {
  const _Answered({
    required this.answer,
    required this.now,
    required this.currentProductId,
  });

  final EvidenceAnswer answer;
  final DateTime? now;
  final String? currentProductId;

  @override
  Widget build(BuildContext context) {
    final asOf = answer.asOfUtc;
    final facts = answer.evidence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (asOf != null) _AsOfLine(asOfUtc: asOf, now: now),
        const SizedBox(height: DesignTokens.s12),
        MallSectionHeader(
          title: 'What this rests on',
          subtitle: facts.length == 1
              ? 'One record, shown in full.'
              : '${facts.length} records, each shown in full.',
          padding: const EdgeInsets.only(bottom: DesignTokens.s8),
        ),
        Column(
          key: EvidenceAnswerPanel.listKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final fact in facts)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: _FactCard(
                  fact: fact,
                  currentProductId: currentProductId,
                ),
              ),
          ],
        ),
        // The prose comes after the records on purpose: it is a summary of
        // what is above, not a standalone claim.
        if (answer.answer.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          _Summary(text: answer.answer),
        ],
        if (answer.consequences.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          const MallSectionHeader(
            title: 'What may follow',
            subtitle: 'Forecasts from the records above, not guarantees.',
            padding: EdgeInsets.only(bottom: DesignTokens.s8),
          ),
          for (final forecast in answer.consequences)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: _ConsequenceCard(forecast: forecast, answer: answer),
            ),
        ],
        if (answer.limitations.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          _Limitations(limitations: answer.limitations),
        ],
        if (answer.evidenceDigestSha256.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          _Digest(digest: answer.evidenceDigestSha256),
        ],
      ],
    );
  }
}

class _AsOfLine extends StatelessWidget {
  const _AsOfLine({required this.asOfUtc, required this.now});

  final DateTime asOfUtc;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final sentence = EvidenceTime.asOfSentence(asOfUtc, now: now);
    final historical =
        (now ?? DateTime.now()).toUtc().difference(asOfUtc.toUtc()) >=
        EvidenceTime.historicalAfter;
    return Semantics(
      label: sentence,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            historical ? Icons.history_rounded : Icons.schedule_rounded,
            size: 16,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(sentence, style: DesignTokens.smallRegular),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact, required this.currentProductId});

  final TemporalFact fact;
  final String? currentProductId;

  /// Presentation of the backend's own token, not a new fact: `-` and `:`
  /// become spaces so `vendor-verification` reads as words. No token is
  /// translated into a different word, and an unknown kind survives.
  static String humanKind(String kind) {
    final spaced = kind.replaceAll(RegExp('[-:_]'), ' ').trim();
    if (spaced.isEmpty) return '';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final validity = EvidenceTime.validity(
      validFromUtc: fact.validFromUtc,
      validToUtc: fact.validToUtc,
    );
    final observed = EvidenceTime.observed(fact.observedUtc);
    final confidence = fact.confidence;
    final kind = humanKind(fact.kind);
    final productId = fact.productId;
    final linkable =
        productId != null &&
        productId.isNotEmpty &&
        productId != currentProductId;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border.all(color: DesignTokens.borderDefault),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kind.isNotEmpty) ...[
              MallEyebrow(kind),
              const SizedBox(height: DesignTokens.s8),
            ],
            Text(fact.statement, style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            if (validity != null)
              _MetaLine(icon: Icons.event_rounded, text: validity),
            if (observed != null)
              _MetaLine(icon: Icons.fact_check_outlined, text: observed),
            if (fact.source.isNotEmpty)
              _MetaLine(icon: Icons.source_outlined, text: fact.source),
            if (fact.sourceReference.isNotEmpty)
              _MetaLine(
                icon: Icons.link_rounded,
                text: fact.sourceReference,
              ),
            // The backend's number, spoken as the backend's number. Nothing
            // here computes, rounds up, or turns it into a star.
            if (confidence != null)
              _MetaLine(
                icon: Icons.percent_rounded,
                text:
                    'Source confidence ${(confidence * 100).round()}%, '
                    'reported by '
                    '${fact.source.isEmpty ? 'the source' : fact.source}',
              ),
            if (linkable) ...[
              const SizedBox(height: DesignTokens.s8),
              _OpenProductLink(productId: productId),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: DesignTokens.textMuted),
          const SizedBox(width: DesignTokens.s8),
          Expanded(child: Text(text, style: DesignTokens.smallRegular)),
        ],
      ),
    );
  }
}

/// The only navigation this subsystem offers, and it mutates nothing: it
/// opens the ordinary, guarded product page.
class _OpenProductLink extends StatelessWidget {
  const _OpenProductLink({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Open the product this record is about',
        excludeSemantics: true,
        child: TextButton.icon(
          onPressed: () => unawaited(
            context.push(
              RouteNames.productDetail.replaceFirst(':productId', productId),
            ),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Open this product'),
        ),
      ),
    );
  }
}

class _ConsequenceCard extends StatelessWidget {
  const _ConsequenceCard({required this.forecast, required this.answer});

  final EvidenceConsequence forecast;
  final EvidenceAnswer answer;

  /// Tone carries the backend's own `direction`; an unrecognised direction
  /// falls back to neutral rather than guessing at severity.
  static MallStatusTone toneFor(String direction) => switch (direction) {
    'risk-increase' => MallStatusTone.caution,
    'risk-decrease' => MallStatusTone.success,
    'stable' => MallStatusTone.info,
    _ => MallStatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final horizon = EvidenceTime.horizon(forecast.horizonDays);
    final probability = forecast.probability;
    final rests = answer.factsById(forecast.evidenceFactIds);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border.all(color: DesignTokens.borderDefault),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (forecast.direction.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: MallStatusPill(
                  label: _FactCard.humanKind(forecast.direction),
                  tone: toneFor(forecast.direction),
                  dense: true,
                  semanticLabel:
                      'Forecast direction: '
                      '${_FactCard.humanKind(forecast.direction)}',
                ),
              ),
            const SizedBox(height: DesignTokens.s8),
            Text(forecast.outcome, style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            if (probability != null)
              _MetaLine(
                icon: Icons.percent_rounded,
                text:
                    'Probability the backend gave: '
                    '${(probability * 100).round()}%',
              ),
            if (horizon != null)
              _MetaLine(icon: Icons.schedule_rounded, text: horizon),
            if (forecast.basis.isNotEmpty)
              _MetaLine(icon: Icons.rule_rounded, text: forecast.basis),
            if (rests.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s8),
              const Text('Rests on', style: DesignTokens.smallRegular),
              for (final fact in rests)
                _MetaLine(
                  icon: Icons.subdirectory_arrow_right_rounded,
                  text: fact.statement,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.text});

  final String text;

  static const Key rootKey = Key('evidence-summary');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: rootKey,
      label: 'Summary of the records above: $text',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MallEyebrow('In short, from the records above'),
          const SizedBox(height: DesignTokens.s8),
          Text(text, style: DesignTokens.smallRegular),
        ],
      ),
    );
  }
}

/// The backend's caveats, verbatim. Nothing is added and nothing is softened.
class _Limitations extends StatelessWidget {
  const _Limitations({required this.limitations});

  final List<String> limitations;

  static const Key rootKey = Key('evidence-limitations');

  @override
  Widget build(BuildContext context) {
    return Column(
      key: rootKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MallEyebrow('What this does not tell you'),
        const SizedBox(height: DesignTokens.s8),
        for (final limitation in limitations)
          _MetaLine(icon: Icons.info_outline_rounded, text: limitation),
      ],
    );
  }
}

/// The integrity digest, shortened for the eye and spoken in full for anyone
/// who needs to quote it to support.
class _Digest extends StatelessWidget {
  const _Digest({required this.digest});

  final String digest;

  @override
  Widget build(BuildContext context) {
    final short = digest.length > 12 ? digest.substring(0, 12) : digest;
    return Semantics(
      label: 'Evidence digest $digest',
      excludeSemantics: true,
      child: Text(
        'Evidence digest $short…',
        style: DesignTokens.smallRegular.copyWith(
          letterSpacing: 0.4,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}
