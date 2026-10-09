import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/rider_rating_messages.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/widgets/rider_rating_views.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "How was your rider?" (buyer) / "Rate the rider" (vendor): five stars,
/// tags that fit the stars, an optional comment — then the rating as given,
/// with "Edit" while the 7-day window is open.
///
/// Draws only what the order says is possible: nothing at all when
/// [eligibility] is null (a backend without ratings) or says there is
/// neither a rating to give nor one given. Not a modal and never blocking —
/// a parcel is delivered whether or not its rider is rated.
class RiderRatingCard extends ConsumerStatefulWidget {
  const RiderRatingCard({
    required this.role,
    required this.subOrderId,
    required this.eligibility,
    this.riderName,
    this.onSaved,
    super.key,
  });

  final RiderRaterRole role;
  final String subOrderId;
  final RiderRatingEligibility? eligibility;
  final String? riderName;

  /// After a rating is saved — the screen re-reads its order with it.
  final Future<void> Function()? onSaved;

  static const commentLimit = 300;

  static const commentKey = ValueKey<String>('rider-rating-comment');
  static const submitKey = ValueKey<String>('rider-rating-submit');
  static const editKey = ValueKey<String>('rider-rating-edit');
  static const cancelKey = ValueKey<String>('rider-rating-cancel');
  static Key starKey(int stars) => ValueKey<String>('rider-rating-star-$stars');
  static Key tagKey(RiderRatingTag tag) =>
      ValueKey<String>('rider-rating-tag-${tag.wire}');

  /// Whether the card has anything to draw for this order.
  static bool isShownFor(RiderRatingEligibility? eligibility, String? subOrder) =>
      eligibility != null &&
      eligibility.isShown &&
      subOrder != null &&
      subOrder.isNotEmpty;

  static String titleFor(RiderRaterRole role) => switch (role) {
    RiderRaterRole.buyer => 'How was your rider?',
    RiderRaterRole.vendor => 'Rate the rider',
  };

  @override
  ConsumerState<RiderRatingCard> createState() => _RiderRatingCardState();
}

class _RiderRatingCardState extends ConsumerState<RiderRatingCard> {
  final TextEditingController _comment = TextEditingController();

  /// The form is open over a rating already given.
  bool _editing = false;
  int _stars = 0;
  final Set<RiderRatingTag> _tags = {};
  bool _saving = false;
  String? _error;

  /// What this session saved; wins over the order's copy until the order
  /// has been re-read.
  RiderRating? _saved;

  ({RiderRaterRole role, String subOrderId}) get _key =>
      (role: widget.role, subOrderId: widget.subOrderId);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _pickStars(int stars) {
    setState(() {
      _stars = stars;
      _error = null;
      // Praise and complaints do not mix: crossing between 3 and 4 stars
      // drops the tags of the other kind.
      _tags.removeWhere((tag) => tag.positive != (stars >= 4));
    });
  }

  void _toggleTag(RiderRatingTag tag) {
    setState(() {
      if (!_tags.remove(tag) && _tags.length < RiderRatingTag.maxPerRating) {
        _tags.add(tag);
      }
    });
  }

  void _startEditing(int stars, List<RiderRatingTag> tags, String? comment) {
    setState(() {
      _editing = true;
      _error = null;
      _stars = stars;
      _tags
        ..clear()
        ..addAll(tags);
      _comment.text = comment ?? '';
    });
  }

  Future<void> _submit() async {
    if (_stars == 0 || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(riderRatingRepositoryProvider)
        .rate(
          role: widget.role,
          subOrderId: widget.subOrderId,
          stars: _stars,
          // In the order of the list, not the order they were tapped.
          tags: [
            for (final tag in RiderRatingTag.values)
              if (_tags.contains(tag)) tag,
          ],
          comment: _comment.text,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = riderRatingErrorMessage(failure);
      }),
      (rating) {
        setState(() {
          _saving = false;
          _saved = rating;
          _editing = false;
        });
        SmSnackbar.success(context, 'Thanks — your rating was saved.');
        final onSaved = widget.onSaved;
        if (onSaved != null) unawaited(onSaved());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = widget.eligibility;
    if (eligibility == null ||
        !RiderRatingCard.isShownFor(eligibility, widget.subOrderId)) {
      return const SizedBox.shrink();
    }

    // The order carries only stars and tags; the comment and the edit window
    // are read once, and the brief stands in until (or unless) they arrive.
    final full = _saved ??
        (eligibility.rating == null
            ? null
            : ref.watch(savedRiderRatingProvider(_key)).asData?.value);
    final brief = full?.brief ?? eligibility.rating;
    final canEdit =
        eligibility.canRateRider &&
        (full?.isEditableAt(DateTime.now().toUtc()) ?? true);
    final showForm = _editing || brief == null;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: showForm
              ? DesignTokens.secondaryYellow.withValues(alpha: 0.5)
              : DesignTokens.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: _editing || brief == null
          ? _form(cancellable: brief != null)
          : _given(
              brief,
              comment: full?.comment,
              onEdit: canEdit
                  ? () => _startEditing(
                      brief.stars,
                      brief.tags,
                      full?.comment,
                    )
                  : null,
            ),
    );
  }

  Widget _header(String title, {String? subtitle}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.two_wheeler, color: DesignTokens.secondaryYellow),
      const SizedBox(width: DesignTokens.s8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: DesignTokens.h3),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
          ],
        ),
      ),
    ],
  );

  String? get _riderLine {
    final name = widget.riderName?.trim();
    if (name == null || name.isEmpty) return null;
    return switch (widget.role) {
      RiderRaterRole.buyer => '$name delivered your parcel',
      RiderRaterRole.vendor => '$name picked up this parcel',
    };
  }

  Widget _form({required bool cancellable}) {
    final choices = _stars == 0
        ? const <RiderRatingTag>[]
        : RiderRatingTag.forStars(_stars);
    final full = _tags.length >= RiderRatingTag.maxPerRating;
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(RiderRatingCard.titleFor(widget.role), subtitle: _riderLine),
        const SizedBox(height: DesignTokens.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                key: RiderRatingCard.starKey(i),
                tooltip: i == 1 ? '1 star' : '$i stars',
                onPressed: _saving ? null : () => _pickStars(i),
                iconSize: 36,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i <= _stars
                      ? DesignTokens.secondaryYellow
                      : DesignTokens.textMuted,
                ),
              ),
          ],
        ),
        if (choices.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            _stars >= 4 ? 'What went well?' : 'What went wrong?',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final tag in choices)
                FilterChip(
                  key: RiderRatingCard.tagKey(tag),
                  label: Text(tag.label),
                  selected: _tags.contains(tag),
                  onSelected: _saving || (full && !_tags.contains(tag))
                      ? null
                      : (_) => _toggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            key: RiderRatingCard.commentKey,
            controller: _comment,
            enabled: !_saving,
            maxLength: RiderRatingCard.commentLimit,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Anything else? (optional)',
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            error,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s8),
        FilledButton(
          key: RiderRatingCard.submitKey,
          onPressed: _stars == 0 || _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.primaryGreen,
            foregroundColor: DesignTokens.buttonPrimaryText,
            minimumSize: const Size.fromHeight(44),
            shape: const StadiumBorder(),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(cancellable ? 'Save changes' : 'Submit rating'),
        ),
        if (cancellable)
          TextButton(
            key: RiderRatingCard.cancelKey,
            onPressed: _saving
                ? null
                : () => setState(() {
                    _editing = false;
                    _error = null;
                  }),
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Widget _given(
    RiderRatingBrief rating, {
    required String? comment,
    required VoidCallback? onEdit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _header(
              widget.role == RiderRaterRole.buyer
                  ? 'Your rating of your rider'
                  : 'Your rating of the rider',
              subtitle: _riderLine,
            ),
          ),
          if (onEdit != null)
            TextButton(
              key: RiderRatingCard.editKey,
              onPressed: onEdit,
              child: const Text('Edit'),
            ),
        ],
      ),
      const SizedBox(height: DesignTokens.s8),
      RiderStarRow(stars: rating.stars, size: 22),
      if (rating.tags.isNotEmpty) ...[
        const SizedBox(height: DesignTokens.s8),
        RiderTagChipsView.tags(rating.tags),
      ],
      if (comment != null) ...[
        const SizedBox(height: DesignTokens.s8),
        Text('“$comment”', style: DesignTokens.smallRegular),
      ],
    ],
  );
}
