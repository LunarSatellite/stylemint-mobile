/// Human labels for the clienteling wire enums.
///
/// Every label here describes a value the backend actually sent. Nothing
/// invents a name, a number or a status: where the backend sends no name for a
/// customer, [clientLabel] falls back to the account id it did send rather
/// than to a placeholder like "Customer".
library;

import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

/// A name for a customer built only from what the backend returned.
String clientLabel({
  required String accountId,
  String? displayName,
  String? handle,
}) {
  if (displayName != null && displayName.isNotEmpty) return displayName;
  if (handle != null && handle.isNotEmpty) return '@$handle';
  if (accountId.isEmpty) return 'Unnamed account';
  final short = accountId.length > 8 ? accountId.substring(0, 8) : accountId;
  return 'Account $short';
}

String outreachChannelLabel(ClientelingOutreachChannel channel) =>
    switch (channel) {
      ClientelingOutreachChannel.email => 'Email',
      ClientelingOutreachChannel.sms => 'SMS',
      ClientelingOutreachChannel.unknown => 'Unrecognised channel',
    };

String outreachDecisionLabel(ClientelingOutreachDecision decision) =>
    switch (decision) {
      ClientelingOutreachDecision.sent => 'Sent',
      ClientelingOutreachDecision.blockedNoConsent =>
        'Blocked — no consent to be contacted',
      ClientelingOutreachDecision.blockedQuietHours => 'Blocked — quiet hours',
      ClientelingOutreachDecision.blockedNoContactPoint =>
        'Blocked — no contact point on file',
      ClientelingOutreachDecision.blockedNotPermitted =>
        'Blocked — not permitted',
      ClientelingOutreachDecision.dispatchFailed => 'Dispatch failed',
      ClientelingOutreachDecision.unknown => 'Unrecognised decision',
    };

String assistedOutcomeStatusLabel(AssistedOutcomeStatus status) =>
    switch (status) {
      AssistedOutcomeStatus.claimed => 'Awaiting your answer',
      AssistedOutcomeStatus.confirmed => 'Confirmed by the customer',
      AssistedOutcomeStatus.rejected => 'Rejected by the customer',
      AssistedOutcomeStatus.unknown => 'Unrecognised status',
    };

/// The associate's own reading of a trail row.
String activityTypeLabel(ClientelingActivityType type) => switch (type) {
  ClientelingActivityType.briefViewed => 'Opened the client brief',
  ClientelingActivityType.sessionOpened => 'Started serving',
  ClientelingActivityType.sessionClosed => 'Finished serving',
  ClientelingActivityType.outreachAttempted => 'Requested outreach',
  ClientelingActivityType.outcomeClaimed => 'Claimed an assisted order',
  ClientelingActivityType.outcomeConfirmed => 'Claim confirmed',
  ClientelingActivityType.outcomeRejected => 'Claim rejected',
  ClientelingActivityType.accessRefused => 'Access refused',
  ClientelingActivityType.unknown => 'Unrecognised action',
};

/// The same row read from the customer's side of the record.
String customerActivityLabel(ClientelingActivityType type) => switch (type) {
  ClientelingActivityType.briefViewed => 'An associate opened your file',
  ClientelingActivityType.sessionOpened => 'An associate started serving you',
  ClientelingActivityType.sessionClosed => 'An associate finished serving you',
  ClientelingActivityType.outreachAttempted =>
    'An associate asked to contact you',
  ClientelingActivityType.outcomeClaimed =>
    'An associate claimed they assisted an order',
  ClientelingActivityType.outcomeConfirmed => 'You confirmed a claim',
  ClientelingActivityType.outcomeRejected => 'You rejected a claim',
  ClientelingActivityType.accessRefused =>
    'An associate was refused access to your account',
  ClientelingActivityType.unknown => 'Unrecognised action',
};

String assignmentStatusLabel(ClientAssignmentStatus status) => switch (status) {
  ClientAssignmentStatus.active => 'Active',
  ClientAssignmentStatus.revoked => 'Revoked',
  ClientAssignmentStatus.unknown => 'Unrecognised status',
};
