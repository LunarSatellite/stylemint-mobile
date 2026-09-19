import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

/// Every word the delegated-handover surfaces put in front of a customer.
///
/// Kept in one place on purpose: this feature asks somebody to sign away the
/// right to receive their own parcel, and the wording *is* the safety control.
/// A flag name like `VisibleDamage` on a checkbox would be a worse product
/// than no checkbox at all.
class HandoverCopy {
  const HandoverCopy._();

  // ── Backend refusal codes (StyleMint.Shared/Core/ErrorCodes.cs) ──────────
  //
  // Only the ones the *customer's* three endpoints can actually return are
  // handled by name. The door-side codes (code_rejected, parcel_mismatch,
  // presence_unconfirmed, …) belong to the courier app and are deliberately
  // not guessed at here.

  static const String codeNotFound = 'handover.delegation_not_found';
  static const String codeRevoked = 'handover.delegation_revoked';
  static const String codeAlreadyUsed = 'handover.delegation_already_used';
  static const String codeExpired = 'handover.delegation_expired';

  /// Generic `ServiceResult` codes this flow can surface.
  static const String codeOutOfRange = 'out_of_range';
  static const String codeBusinessRule = 'business_rule';
  static const String codeConflict = 'conflict';
  static const String codeTooLong = 'too_long';
  static const String codeRequired = 'required';
  static const String codeInvalidEnum = 'invalid_enum';

  /// What to tell the customer, and what they can do about it. Each code gets
  /// its own sentence and its own next step — a shared 'something went wrong'
  /// would leave them unable to act.
  static ({String title, String body}) refusal(
    String? errorCode,
  ) => switch (errorCode) {
    codeNotFound => (
      title: 'This authorisation is already gone',
      body:
          'We could not find it, so nobody can use it. Pull down to refresh '
          'the list. If you still want someone to collect this parcel, '
          'authorise them again.',
    ),
    codeRevoked => (
      title: 'Already revoked',
      body:
          'You have already withdrawn this one — its code will not open the '
          'parcel. Nothing more to do.',
    ),
    codeAlreadyUsed => (
      title: 'The parcel has already been handed over',
      body:
          'This authorisation was used at the door, so there is nothing '
          'left to revoke. Check the delivery record to see who signed for '
          'it, and contact support if that was not who you expected.',
    ),
    codeExpired => (
      title: 'The window has already closed',
      body:
          'This authorisation ran out on its own, so it can no longer let '
          'anyone take your parcel. Authorise a new window if you still '
          'need someone to collect it.',
    ),
    codeConflict => (
      title: 'Someone is already authorised for this parcel',
      body:
          'Only one person can be authorised at a time. Revoke the active '
          'authorisation below, then set up the new one.',
    ),
    codeBusinessRule => (
      title: 'This parcel can no longer be delegated',
      body:
          'It has already been delivered, or it is on its way back to the '
          'seller. There is nobody left to hand it to.',
    ),
    codeOutOfRange => (
      title: 'That time window is not allowed',
      body:
          'A handover window must be at least 15 minutes and at most 72 '
          'hours long, and must start within the next 14 days. Adjust the '
          'times and try again.',
    ),
    codeTooLong => (
      title: 'That is longer than we can store',
      body:
          'A name can be up to 120 characters and a revocation reason up to '
          '300. Shorten what you typed and try again.',
    ),
    codeRequired || codeInvalidEnum => (
      title: 'Something in the form was missing',
      body: 'Check the name, the relationship and the times, then try again.',
    ),
    _ => (
      title: 'We could not reach the delivery service',
      body:
          'Your authorisation was not created, so nobody has been given '
          'access. Check your connection and try again.',
    ),
  };

  // ── Relationship ────────────────────────────────────────────────────────

  static String relationship(DelegateRelationship value) => switch (value) {
    DelegateRelationship.familyMember => 'Someone in my household',
    DelegateRelationship.neighbour => 'A neighbour',
    DelegateRelationship.officeOrReception => 'My office or building reception',
    DelegateRelationship.pickupPoint => 'A pickup point',
    DelegateRelationship.unknown => 'Someone else',
  };

  /// The four the customer may pick. `unknown` is a parse fallback, never an
  /// option.
  static const List<DelegateRelationship> selectableRelationships =
      <DelegateRelationship>[
        DelegateRelationship.familyMember,
        DelegateRelationship.neighbour,
        DelegateRelationship.officeOrReception,
        DelegateRelationship.pickupPoint,
      ];

  // ── Exceptions ──────────────────────────────────────────────────────────

  /// The decision, phrased as the thing that would actually happen at the
  /// door — not as the flag name.
  static String exceptionTitle(DelegatedException value) => switch (value) {
    DelegatedException.substitution =>
      'Let them accept a different item than I ordered',
    DelegatedException.visibleDamage =>
      'Let them accept it even if the parcel looks damaged',
    DelegatedException.partialDelivery =>
      'Let them accept it when part of my order is missing',
  };

  /// The consequence. Every one of these costs the customer something, so it
  /// is stated rather than implied.
  static String exceptionConsequence(
    DelegatedException value,
  ) => switch (value) {
    DelegatedException.substitution =>
      'If the seller sent a different size, colour or product, it will be '
          'signed for as delivered. Sorting out the swap then falls to you.',
    DelegatedException.visibleDamage =>
      'If the box is crushed, torn or wet, it will still be signed for. '
          'Accepting visible damage can weaken a later damage claim.',
    DelegatedException.partialDelivery =>
      'If only some of your items turn up, the delivery is closed off as '
          'received. You would have to chase the rest yourself.',
  };

  /// What 'none selected' means — shown so the safe default is not silent.
  static const String noExceptionsExplainer =
      'By default they can only accept a complete, undamaged parcel that '
      'matches your order. Anything else will wait for you.';

  static String exceptionSummary(Set<DelegatedException> chosen) {
    if (chosen.isEmpty) return 'Complete, undamaged orders only';
    final parts = <String>[
      if (chosen.contains(DelegatedException.substitution)) 'substitutions',
      if (chosen.contains(DelegatedException.visibleDamage)) 'visible damage',
      if (chosen.contains(DelegatedException.partialDelivery))
        'partial deliveries',
    ];
    return 'May also accept: ${parts.join(', ')}';
  }

  // ── Status ──────────────────────────────────────────────────────────────

  /// Exactly the four statuses the API returns, plus an honest fallback for a
  /// value this build does not recognise. Nothing is invented.
  static String statusLabel(HandoverDelegationStatus status) =>
      switch (status) {
        HandoverDelegationStatus.active => 'Active',
        HandoverDelegationStatus.consumed => 'Used',
        HandoverDelegationStatus.revoked => 'Revoked',
        HandoverDelegationStatus.expired => 'Expired',
        HandoverDelegationStatus.unknown => 'Unavailable',
      };

  /// Tone *and* glyph differ per status, so the four are told apart on a
  /// greyscale screen and by a colour-blind reader — the Mall kit's pill
  /// always draws the glyph.
  static MallStatusTone statusTone(HandoverDelegationStatus status) =>
      switch (status) {
        HandoverDelegationStatus.active => MallStatusTone.progress,
        HandoverDelegationStatus.consumed => MallStatusTone.success,
        HandoverDelegationStatus.revoked => MallStatusTone.danger,
        HandoverDelegationStatus.expired => MallStatusTone.caution,
        HandoverDelegationStatus.unknown => MallStatusTone.neutral,
      };

  /// Spoken form, so a screen reader announces the state rather than the
  /// pill's decoration.
  static String statusSemantics(HandoverDelegationStatus status) =>
      switch (status) {
        HandoverDelegationStatus.active =>
          'Status: active. This authorisation can be used right now.',
        HandoverDelegationStatus.consumed =>
          'Status: used. The parcel was handed over.',
        HandoverDelegationStatus.revoked =>
          'Status: revoked. You withdrew this authorisation.',
        HandoverDelegationStatus.expired =>
          'Status: expired. The window closed without it being used.',
        HandoverDelegationStatus.unknown => 'Status: unavailable.',
      };

  // ── Window ──────────────────────────────────────────────────────────────

  /// One sentence per broken rule. Distinct messages, because "invalid
  /// window" would leave the customer guessing which of four rules they hit.
  static String windowProblem(HandoverWindowProblem problem) =>
      switch (problem) {
        HandoverWindowProblem.endsBeforeStart =>
          'The window has to end after it starts. Move the end time later.',
        HandoverWindowProblem.tooShort =>
          'That window is shorter than 15 minutes. Give the courier at least '
              '15 minutes to arrive.',
        HandoverWindowProblem.tooLong =>
          'That window is longer than 72 hours. Nobody can hold your parcel '
              'open for more than 3 days — shorten it.',
        HandoverWindowProblem.alreadyPast =>
          'That window has already closed. Pick times that are still ahead of '
              'you.',
        HandoverWindowProblem.tooFarAhead =>
          'That window starts more than 14 days from now. You can only '
              'authorise someone up to 2 weeks ahead.',
      };

  static final DateFormat _day = DateFormat('EEE d MMM');
  static final DateFormat _time = DateFormat('h:mm a');

  /// The window as a person reads it: local times, with the length spelled
  /// out, so 'when does this permission start and stop' needs no arithmetic.
  static String windowSentence(DateTime startUtc, DateTime endUtc) {
    final start = startUtc.toLocal();
    final end = endUtc.toLocal();
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final head = sameDay
        ? '${_day.format(start)}, ${_time.format(start)} to '
              '${_time.format(end)}'
        : '${_day.format(start)} ${_time.format(start)} to '
              '${_day.format(end)} ${_time.format(end)}';
    return '$head  ·  ${durationWords(end.difference(start))}';
  }

  /// '1 hour 30 minutes', '3 days', '45 minutes'.
  static String durationWords(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 60) return '$minutes ${_plural(minutes, 'minute')}';
    if (minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return '$days ${_plural(days, 'day')}';
    }
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final hoursText = '$hours ${_plural(hours, 'hour')}';
    return rest == 0
        ? hoursText
        : '$hoursText $rest ${_plural(rest, 'minute')}';
  }

  /// The line under an active delegation: what is true right now.
  static String activeWindowState(HandoverDelegation d, DateTime nowUtc) {
    if (nowUtc.isBefore(d.windowStartUtc)) {
      return 'Starts in ${durationWords(d.windowStartUtc.difference(nowUtc))}';
    }
    return 'Open now · ends in '
        '${durationWords(d.windowEndUtc.difference(nowUtc))}';
  }

  static String _plural(int n, String word) => n == 1 ? word : '${word}s';
}
