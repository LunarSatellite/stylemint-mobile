import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

/// Every word this feature says, in one place, so the sentence a customer
/// reads when they grant authority and the sentence they read when an agent
/// is refused cannot drift apart.
abstract final class AgentCommerceCopy {
  // ── The boundary, stated where authority is granted ─────────────────────

  /// What an external agent can never do, whatever scopes it holds. These are
  /// the backend's own words from the `/.well-known/ai-commerce` manifest, and
  /// they belong on the granting screen — a customer who learns the boundary
  /// from a help page has already agreed without knowing it.
  static const String _neverPrice =
      'It can never set a price. Prices are ours and the seller’s.';
  static const String _neverStock = 'It can never reserve stock for itself.';
  static const String _neverMoney =
      'It can never move money. No card, wallet or balance of yours is '
      'reachable by it.';
  static const String _neverBuy =
      'It can never complete a purchase. An order is placed only after you '
      'confirm that exact basket here, in your own session.';
  static const String _neverImpersonate =
      'It can never say whose account it is acting for. Your identity comes '
      'from the mandate and from nowhere else.';

  /// What an external agent can never do, whatever scopes it holds. These are
  /// the backend's own words from the `/.well-known/ai-commerce` manifest, and
  /// they belong on the granting screen: a customer who learns the boundary
  /// from a help page has already agreed without knowing it.
  static const List<String> neverCan = <String>[
    _neverPrice,
    _neverStock,
    _neverMoney,
    _neverBuy,
    _neverImpersonate,
  ];

  static const String revocationPromise =
      'Revoking stops work that is already running, not just the next request. '
      'A call the agent has in flight is cut off mid-way.';

  static const String credentialWarning =
      'Shown once. You will not be able to see it again.';

  // ── Scopes ───────────────────────────────────────────────────────────────

  static String scopeTitle(AgentMandateScope scope) => switch (scope) {
    AgentMandateScope.catalogRead => 'Read the catalogue',
    AgentMandateScope.cartWrite => 'Put things in your basket',
    AgentMandateScope.checkoutPrepare => 'Prepare a checkout for your review',
    AgentMandateScope.orderSubmitAfterCustomerConfirmation =>
      'Place an order you have already confirmed',
  };

  static String scopeConsequence(AgentMandateScope scope) => switch (scope) {
    AgentMandateScope.catalogRead =>
      'Prices, stock and delivery promises — the same facts a shopper sees.',
    AgentMandateScope.cartWrite =>
      'Lines appear in your basket. Nothing is bought, and only products on '
          'your list can be added.',
    AgentMandateScope.checkoutPrepare =>
      'It works out a total and parks it here for your approval. It places '
          'no order and reserves no stock.',
    AgentMandateScope.orderSubmitAfterCustomerConfirmation =>
      'Only after you confirm that basket. This permission does not let it '
          'submit an unconfirmed one — nothing does.',
  };

  static IconData scopeIcon(AgentMandateScope scope) => switch (scope) {
    AgentMandateScope.catalogRead => Icons.menu_book_outlined,
    AgentMandateScope.cartWrite => Icons.add_shopping_cart_outlined,
    AgentMandateScope.checkoutPrepare => Icons.receipt_long_outlined,
    AgentMandateScope.orderSubmitAfterCustomerConfirmation =>
      Icons.how_to_reg_outlined,
  };

  /// What to say about scope bits this build has no name for. Honest about
  /// the count, honest about not knowing.
  static String unrecognisedScopes(int count) => count == 1
      ? 'It also holds 1 permission this version of the app does not '
            'recognise. Update the app to read it, or revoke the mandate.'
      : 'It also holds $count permissions this version of the app does not '
            'recognise. Update the app to read them, or revoke the mandate.';

  // ── Mandate state ────────────────────────────────────────────────────────

  static String mandateStateLabel(AgentMandateState state) => switch (state) {
    AgentMandateState.active => 'Active',
    AgentMandateState.revoked => 'Revoked',
    AgentMandateState.expired => 'Expired',
  };

  static MallStatusTone mandateStateTone(AgentMandateState state) =>
      switch (state) {
        AgentMandateState.active => MallStatusTone.success,
        AgentMandateState.revoked => MallStatusTone.danger,
        AgentMandateState.expired => MallStatusTone.neutral,
      };

  static IconData mandateStateIcon(AgentMandateState state) => switch (state) {
    AgentMandateState.active => Icons.verified_user_outlined,
    AgentMandateState.revoked => Icons.block_rounded,
    AgentMandateState.expired => Icons.hourglass_disabled_outlined,
  };

  // ── Proposal state ───────────────────────────────────────────────────────

  static String proposalStatusLabel(
    AgentProposalStatus status, {
    int? rawStatus,
  }) => switch (status) {
    AgentProposalStatus.pendingCustomerConfirmation => 'Waiting on you',
    AgentProposalStatus.confirmed => 'Confirmed by you',
    AgentProposalStatus.rejected => 'Rejected by you',
    AgentProposalStatus.executed => 'Ordered',
    AgentProposalStatus.expired => 'Expired',
    AgentProposalStatus.unknown =>
      rawStatus == null
          ? 'Unrecognised status'
          : 'Unrecognised status ($rawStatus)',
  };

  static MallStatusTone proposalStatusTone(AgentProposalStatus status) =>
      switch (status) {
        AgentProposalStatus.pendingCustomerConfirmation =>
          MallStatusTone.caution,
        AgentProposalStatus.confirmed => MallStatusTone.progress,
        AgentProposalStatus.rejected => MallStatusTone.danger,
        AgentProposalStatus.executed => MallStatusTone.success,
        AgentProposalStatus.expired => MallStatusTone.neutral,
        AgentProposalStatus.unknown => MallStatusTone.neutral,
      };

  static IconData proposalStatusIcon(AgentProposalStatus status) =>
      switch (status) {
        AgentProposalStatus.pendingCustomerConfirmation =>
          Icons.pending_actions_outlined,
        AgentProposalStatus.confirmed => Icons.task_alt_rounded,
        AgentProposalStatus.rejected => Icons.do_not_disturb_on_outlined,
        AgentProposalStatus.executed => Icons.inventory_2_outlined,
        AgentProposalStatus.expired => Icons.hourglass_disabled_outlined,
        AgentProposalStatus.unknown => Icons.help_outline_rounded,
      };

  static const String unknownStatusExplainer =
      'This app does not recognise what state this basket is in, so it will '
      'not offer you a button. Update the app, or ask the assistant to raise '
      'a fresh basket.';

  // ── Activity ─────────────────────────────────────────────────────────────

  /// A dotted wire verb in plain words. An action this build has never seen
  /// is shown as itself rather than guessed at.
  static String activityAction(String action) => switch (action) {
    'mandate.issue' => 'Mandate issued',
    'mandate.revoke' => 'Mandate revoked',
    'catalog.feed' => 'Read the catalogue',
    'catalog.manifest' => 'Read a product’s details',
    'cart.add' => 'Added to your basket',
    'cart.lines.add' => 'Added to your basket',
    'proposal.create' => 'Prepared a basket',
    'proposal.read' => 'Checked a basket',
    'proposal.execute' => 'Tried to place the order',
    'credential.authenticate' => 'Presented its credential',
    _ => action,
  };

  static String activityOutcome({required bool allowed}) =>
      allowed ? 'Allowed' : 'Refused';

  static MallStatusTone activityTone({required bool allowed}) =>
      allowed ? MallStatusTone.success : MallStatusTone.danger;

  static IconData activityIcon({required bool allowed}) =>
      allowed ? Icons.check_circle_outline_rounded : Icons.gpp_bad_outlined;

  /// Why a call was refused, in the customer's terms. A refusal is the proof
  /// their limits are working, so it gets a sentence rather than a code.
  static String refusalReason(String? errorCode) => switch (errorCode) {
    'external_agent.credential_missing' => 'It presented no credential.',
    'external_agent.credential_malformed' =>
      'Its credential was not in the expected form.',
    'external_agent.credential_unknown' =>
      'Its credential matched no mandate of yours.',
    'external_agent.credential_revoked' => 'You had revoked that mandate.',
    'external_agent.credential_expired' => 'That mandate had expired.',
    'external_agent.credential_ambiguous' =>
      'Its credential answered to more than one mandate, so it was refused '
          'rather than guessed at.',
    'external_agent.scope_not_granted' =>
      'You had not granted it that permission.',
    'external_agent.product_outside_mandate' =>
      'That product is not on the list you allowed.',
    'external_agent.amount_over_limit' =>
      'It was over the spending limit you set.',
    'external_agent.currency_mismatch' =>
      'It was in a currency your mandate does not cover.',
    'external_agent.identity_caller_supplied' =>
      'It tried to say which customer it was acting for. Only the mandate '
          'decides that.',
    'external_agent.human_approval_required' =>
      'It tried to place an order you had not confirmed.',
    'external_agent.mandate_withdrawn_in_flight' =>
      'You revoked the mandate while this call was running, and it was '
          'stopped.',
    'external_agent.directory_unreadable' =>
      'Its credential could not be checked, so the call was refused.',
    'system.rate_limited' => 'It called too often and was slowed down.',
    _ => 'It was refused.',
  };

  // ── Failures of the customer's own actions ───────────────────────────────

  static const String transportFailure = 'agent_commerce.transport_failure';

  static ({String title, String body}) actionFailure(String errorCode) =>
      switch (errorCode) {
        'external_agent.human_approval_required' => (
          title: 'That basket still needs you',
          body: 'Open it and confirm it from the basket itself.',
        ),
        'system.concurrency_conflict' => (
          title: 'Something changed while you were looking',
          body: 'Pull to refresh and read the basket again before you decide.',
        ),
        'validation.out_of_range' => (
          title: 'That is outside what a mandate may allow',
          body: 'Check the spending limit and the expiry date, then try again.',
        ),
        'validation.required' => (
          title: 'Something is missing',
          body: 'Fill in every field above and try again.',
        ),
        'auth.forbidden' => (
          title: 'That mandate is not yours',
          body: 'Pull to refresh — this list may be out of date.',
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

  /// `19 Sep 2026`. Local time — the customer sets a date in their own day.
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

  /// "in 30 days" / "today" / "3 days ago" — a length the customer can feel.
  static String daysFromNow(DateTime utc, DateTime nowUtc) {
    final days = utc.difference(nowUtc).inHours / 24;
    final whole = days.round();
    if (whole == 0) return 'today';
    if (whole > 0) return whole == 1 ? 'in 1 day' : 'in $whole days';
    final ago = -whole;
    return ago == 1 ? '1 day ago' : '$ago days ago';
  }

  /// `NPR 12,400.50`. No locale guessing: the code is pinned by the mandate,
  /// so it is written out rather than turned into a symbol.
  static String money(double amount, String currency) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first.replaceAll('-', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final sign = amount < 0 ? '-' : '';
    final code = currency.trim().isEmpty
        ? ''
        : '${currency.trim().toUpperCase()} ';
    return '$code$sign$buffer.${parts.last}';
  }

  static const Duration _maxLifetime = Duration(
    days: kAgentMandateMaxLifetimeDays,
  );

  static String expiryProblem(
    MandateExpiryProblem problem,
    DateTime nowUtc,
  ) => switch (problem) {
    MandateExpiryProblem.notInFuture =>
      'Pick a date in the future — a mandate that has already expired '
          'grants nothing.',
    MandateExpiryProblem.beyondMaxLifetime =>
      'A mandate can last at most $kAgentMandateMaxLifetimeDays days. '
          'Choose a date on or before '
          '${date(nowUtc.add(_maxLifetime))}.',
  };

  static String capProblem(MandateCapProblem problem) => switch (problem) {
    MandateCapProblem.missing =>
      'Set a spending limit. There is no unlimited option.',
    MandateCapProblem.notANumber =>
      'Write the limit in digits, for example 25000.',
    MandateCapProblem.notPositive => 'The limit has to be more than zero.',
    MandateCapProblem.aboveCeiling =>
      'That is above the highest limit StyleMint will accept '
          '(${money(kAgentMandateMaxOrderAmount, '')}).',
  };

  static String currencyProblem(MandateCurrencyProblem problem) =>
      switch (problem) {
        MandateCurrencyProblem.wrongLength =>
          'Use a three-letter currency code, such as NPR.',
        MandateCurrencyProblem.notLetters =>
          'A currency code is three letters, such as USD.',
      };

  static String allowlistSummary(int count) => switch (count) {
    0 => 'Anything in the catalogue',
    1 => '1 product only',
    _ => '$count products only',
  };
}
