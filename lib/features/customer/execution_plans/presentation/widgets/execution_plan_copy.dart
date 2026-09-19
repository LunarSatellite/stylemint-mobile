import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

/// Every word the shopping-plan surface says, in one place.
///
/// ## The rule this file exists to hold
///
/// Section 5.9 of the client proposal commits StyleMint to AI that
/// **"will not set prices, reserve stock or move money"**. A compiled plan
/// names all three: its third step is *"Reserve inventory and freeze payable
/// terms"* and its fourth *"Create the authoritative order"*. Proposing those
/// is inside the promise. Showing them as **done, reserved or paid** is not.
///
/// So no label in this file is ever a past-tense commitment. A step that has
/// evidence against it reads "Evidence recorded", with the date — the fact
/// the backend actually holds — and never "Reserved", "Paid", "Bought" or
/// "Ordered". The word for a plan the shopper has approved is "go-ahead",
/// not "started".
abstract final class ExecutionPlanCopy {
  static const String surfaceTitle = 'Shopping plans';

  static const String surfaceIntro =
      'Describe what you want and StyleMint will work out the steps. It only '
      'writes the steps down.';

  /// The §5.9 boundary, on every plan, in the shopper's own terms. It sits
  /// above the steps rather than under a "learn more", because a shopper who
  /// reads the boundary after the plan has already read the plan as a
  /// promise.
  static const String boundaryTitle = 'A plan, not an action';
  static const String boundaryBody =
      'Nothing here has been bought, reserved or paid for. StyleMint does not '
      'set prices, hold stock or move money on your behalf — those happen '
      'only when you do them yourself in checkout.';

  static const String composeTitle = 'What are you trying to buy?';
  static const String composeHint =
      'For example: a rain jacket and boots for a trek in November';
  static const String composeLimitLabel = 'Spending limit (optional)';
  static const String composeLimitHelp =
      'A ceiling for the plan. Leave it empty and no limit is recorded.';
  static const String composeItemsLabel = 'Most items to consider';
  static const String composeSubmit = 'Work out the steps';
  static const String composeWorking = 'Working out the steps…';

  static const String emptyTitle = 'No plans yet';
  static const String emptyBody =
      'Nothing has been planned on this account. Describe what you are trying '
      'to buy and the steps will appear here.';

  static const String loadFailed =
      "Couldn't read your plans. Pull down to try again.";

  static const String stepsTitle = 'The steps it wrote down';
  static const String noSteps =
      'This plan has no steps recorded against it.';

  static const String approvePlanLabel = 'Give this plan the go-ahead';
  static const String approvePlanMeaning =
      'This records that you are happy with the steps. It buys nothing, holds '
      'nothing and pays nothing — each step still has to be done by you.';
  static const String approveStepLabel = 'Give this step the go-ahead';
  static const String cancelPlanLabel = 'Cancel this plan';
  static const String cancelPlanMeaning =
      'The steps stay on record, and nothing that has not happened will.';

  static const String spendLimitLabel = 'Your spending limit';
  static const String spendLimitMeaning = 'A ceiling, not a spend.';
  static const String noSpendLimit = 'No spending limit was recorded.';
  static const String deadlineLabel = 'You wanted this done by';

  /// What this app refuses to draw, and why. Shown in place of a plan the
  /// backend says has work recorded against it that the shopper never
  /// approved.
  static const String refusalTitle = 'This plan does not add up';
  static const String refusalBody =
      'StyleMint is reporting work recorded against this plan that you never '
      'gave the go-ahead for. Rather than show you steps as done, this app is '
      'showing you nothing. Contact support before acting on this plan.';

  // ── Plan status ──────────────────────────────────────────────────────────

  static String planStatusLabel(
    ExecutionPlanStatus status, {
    int? rawStatus,
  }) => switch (status) {
    ExecutionPlanStatus.awaitingCustomerApproval => 'Waiting on you',
    ExecutionPlanStatus.ready => 'You gave the go-ahead',
    ExecutionPlanStatus.inProgress => 'Some steps have evidence',
    ExecutionPlanStatus.completed => 'Every step has evidence',
    ExecutionPlanStatus.failed => 'Stopped',
    ExecutionPlanStatus.cancelled => 'Cancelled by you',
    ExecutionPlanStatus.unrecognised =>
      rawStatus == null
          ? 'Unrecognised status'
          : 'Unrecognised status ($rawStatus)',
  };

  static MallStatusTone planStatusTone(ExecutionPlanStatus status) =>
      switch (status) {
        ExecutionPlanStatus.awaitingCustomerApproval => MallStatusTone.caution,
        ExecutionPlanStatus.ready => MallStatusTone.info,
        ExecutionPlanStatus.inProgress => MallStatusTone.progress,
        ExecutionPlanStatus.completed => MallStatusTone.success,
        ExecutionPlanStatus.failed => MallStatusTone.danger,
        ExecutionPlanStatus.cancelled => MallStatusTone.danger,
        ExecutionPlanStatus.unrecognised => MallStatusTone.neutral,
      };

  static IconData planStatusIcon(ExecutionPlanStatus status) =>
      switch (status) {
        ExecutionPlanStatus.awaitingCustomerApproval =>
          Icons.pending_actions_outlined,
        ExecutionPlanStatus.ready => Icons.how_to_reg_outlined,
        ExecutionPlanStatus.inProgress => Icons.fact_check_outlined,
        ExecutionPlanStatus.completed => Icons.fact_check_outlined,
        ExecutionPlanStatus.failed => Icons.report_gmailerrorred_outlined,
        ExecutionPlanStatus.cancelled => Icons.do_not_disturb_on_outlined,
        ExecutionPlanStatus.unrecognised => Icons.help_outline_rounded,
      };

  // ── Step status ──────────────────────────────────────────────────────────

  /// Deliberately free of "Done", "Reserved", "Paid" and "Ordered".
  ///
  /// The strongest thing this app will say about a step is that StyleMint
  /// holds evidence for it — which is exactly what the backend stores, and
  /// exactly as much as it can honestly claim.
  static String stepStatusLabel(ExecutionStepStatus status) =>
      switch (status) {
        ExecutionStepStatus.pending => 'Not started',
        ExecutionStepStatus.inProgress => 'Reported under way',
        ExecutionStepStatus.completed => 'Evidence recorded',
        ExecutionStepStatus.failed => 'Reported as failed',
        ExecutionStepStatus.skipped => 'Skipped',
        ExecutionStepStatus.unrecognised => 'Unrecognised status',
      };

  static MallStatusTone stepStatusTone(ExecutionStepStatus status) =>
      switch (status) {
        ExecutionStepStatus.pending => MallStatusTone.neutral,
        ExecutionStepStatus.inProgress => MallStatusTone.progress,
        ExecutionStepStatus.completed => MallStatusTone.info,
        ExecutionStepStatus.failed => MallStatusTone.danger,
        ExecutionStepStatus.skipped => MallStatusTone.neutral,
        ExecutionStepStatus.unrecognised => MallStatusTone.neutral,
      };

  static IconData stepStatusIcon(ExecutionStepStatus status) =>
      switch (status) {
        ExecutionStepStatus.pending => Icons.radio_button_unchecked,
        ExecutionStepStatus.inProgress => Icons.more_horiz_rounded,
        ExecutionStepStatus.completed => Icons.description_outlined,
        ExecutionStepStatus.failed => Icons.report_gmailerrorred_outlined,
        ExecutionStepStatus.skipped => Icons.skip_next_outlined,
        ExecutionStepStatus.unrecognised => Icons.help_outline_rounded,
      };

  // ── The §5.9 line, per step ──────────────────────────────────────────────

  /// What this step would touch, named plainly so a shopper can see which
  /// steps are theirs to carry out.
  static String commitmentLabel(ExecutionCommitment commitment) =>
      switch (commitment) {
        ExecutionCommitment.price => 'a price',
        ExecutionCommitment.stock => 'stock',
        ExecutionCommitment.money => 'money',
      };

  /// The sentence under a step that would touch a price, stock or money.
  static String commitmentNote(Set<ExecutionCommitment> commitments) {
    final parts = <ExecutionCommitment>[
      ExecutionCommitment.price,
      ExecutionCommitment.stock,
      ExecutionCommitment.money,
    ].where(commitments.contains).map(commitmentLabel).toList(growable: false);
    if (parts.isEmpty) return '';
    final named = parts.length == 1
        ? parts.single
        : '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
    return 'This step touches $named, so only you can carry it out. '
        'Nothing about it has happened yet.';
  }

  /// How a step's approval gate reads. Never the raw `approved` bit: the
  /// backend pre-sets that to true wherever there is no separate gate, and
  /// drawing it would claim a go-ahead the shopper never gave.
  static String? approvalNote(
    ExecutionStep step, {
    required bool planApproved,
  }) => switch (step.approval) {
    ExecutionApproval.none => null,
    ExecutionApproval.customerBeforeExecution => planApproved
        ? 'Covered by the go-ahead you gave this plan.'
        : 'Waiting on the go-ahead for the whole plan.',
    ExecutionApproval.customerAtTask => step.approvedOnWire
        ? 'You gave this step its own go-ahead.'
        : 'Needs its own go-ahead from you.',
    ExecutionApproval.unrecognised =>
      'This app does not recognise this step’s approval rule, so it offers '
          'you no button for it.',
  };

  // ── Failures of the shopper's own actions ────────────────────────────────

  static const String transportFailure = 'execution_plans.transport_failure';

  static ({String title, String body}) actionFailure(String errorCode) =>
      switch (errorCode) {
        'validation.required' => (
          title: 'Something is missing',
          body: 'Say what you are trying to buy, then try again.',
        ),
        'validation.out_of_range' => (
          title: 'That is outside what a plan may hold',
          body: 'Check the spending limit and the number of items.',
        ),
        'validation.invalid_state_transition' => (
          title: 'This plan has moved on',
          body: 'Pull to refresh and read it again before you decide.',
        ),
        'system.concurrency_conflict' => (
          title: 'Something changed while you were looking',
          body: 'Pull to refresh and read the plan again before you decide.',
        ),
        'auth.forbidden' => (
          title: 'That plan is not yours',
          body: 'Pull to refresh — this list may be out of date.',
        ),
        'system.not_found' => (
          title: 'That plan is no longer there',
          body: 'Pull to refresh to see what is.',
        ),
        transportFailure => (
          title: 'That did not reach StyleMint',
          body: 'Nothing changed. Check your connection and try again.',
        ),
        _ => (
          title: 'That did not go through',
          body: 'Nothing changed. Try again in a moment.',
        ),
      };

  // ── Small formatters ─────────────────────────────────────────────────────

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `19 Sep 2026`. Local time — a shopper's deadline is in their own day.
  static String date(DateTime utc) {
    final d = utc.toLocal();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// `19 Sep 2026, 14:05`.
  static String dateTime(DateTime utc) {
    final d = utc.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${date(utc)}, $hh:$mm';
  }
}
