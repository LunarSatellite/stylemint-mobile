/// Wire mapping for `v1/clienteling/*`.
///
/// The API registers no `JsonStringEnumConverter`, so its enums arrive as the
/// C# integer values. Names are accepted too, in case that changes; anything
/// this build does not recognise becomes the `unknown` member rather than
/// silently collapsing onto a real one.
library;

import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

ClientAssignmentStatus clientAssignmentStatusFromJson(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'active' => ClientAssignmentStatus.active,
      2 || 'revoked' => ClientAssignmentStatus.revoked,
      _ => ClientAssignmentStatus.unknown,
    };

ClientelingActivityType clientelingActivityTypeFromJson(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'briefviewed' => ClientelingActivityType.briefViewed,
      2 || 'sessionopened' => ClientelingActivityType.sessionOpened,
      3 || 'sessionclosed' => ClientelingActivityType.sessionClosed,
      4 || 'outreachattempted' => ClientelingActivityType.outreachAttempted,
      5 || 'outcomeclaimed' => ClientelingActivityType.outcomeClaimed,
      6 || 'outcomeconfirmed' => ClientelingActivityType.outcomeConfirmed,
      7 || 'outcomerejected' => ClientelingActivityType.outcomeRejected,
      8 || 'accessrefused' => ClientelingActivityType.accessRefused,
      _ => ClientelingActivityType.unknown,
    };

ClientelingOutreachChannel outreachChannelFromJson(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'email' => ClientelingOutreachChannel.email,
      2 || 'sms' => ClientelingOutreachChannel.sms,
      _ => ClientelingOutreachChannel.unknown,
    };

/// The integer the API expects back. `unknown` has no wire value, so callers
/// must never offer it — the UI only ever sends a channel the brief named.
int outreachChannelToJson(ClientelingOutreachChannel channel) =>
    switch (channel) {
      ClientelingOutreachChannel.email => 1,
      ClientelingOutreachChannel.sms => 2,
      ClientelingOutreachChannel.unknown => 0,
    };

ClientelingOutreachDecision outreachDecisionFromJson(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'sent' => ClientelingOutreachDecision.sent,
      2 || 'blockednoconsent' => ClientelingOutreachDecision.blockedNoConsent,
      3 || 'blockedquiethours' => ClientelingOutreachDecision.blockedQuietHours,
      4 || 'blockednocontactpoint' =>
        ClientelingOutreachDecision.blockedNoContactPoint,
      5 ||
      'blockednotpermitted' => ClientelingOutreachDecision.blockedNotPermitted,
      6 || 'dispatchfailed' => ClientelingOutreachDecision.dispatchFailed,
      _ => ClientelingOutreachDecision.unknown,
    };

AssistedOutcomeStatus assistedOutcomeStatusFromJson(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'claimed' => AssistedOutcomeStatus.claimed,
      2 || 'confirmed' => AssistedOutcomeStatus.confirmed,
      3 || 'rejected' => AssistedOutcomeStatus.rejected,
      _ => AssistedOutcomeStatus.unknown,
    };

List<Map<String, dynamic>> _objectList(Object? raw) => raw is List
    ? raw.whereType<Map<dynamic, dynamic>>().map(readJsonObject).toList()
    : const [];

/// `ClientAssignmentVm`.
ClientAssignment clientAssignmentFromJson(Map<String, dynamic> json) =>
    ClientAssignment(
      assignmentId: readString(json['assignmentId']),
      vendorAccountId: readString(json['vendorAccountId']),
      associateAccountId: readString(json['associateAccountId']),
      customerAccountId: readString(json['customerAccountId']),
      customerDisplayName: readOptionalString(json['customerDisplayName']),
      customerHandle: readOptionalString(json['customerHandle']),
      status: clientAssignmentStatusFromJson(json['status']),
      note: readOptionalString(json['note']),
      grantedUtc: readDate(json['grantedUtc']),
      revokedUtc: readDate(json['revokedUtc']),
    );

/// `ContactabilityVm`.
Contactability contactabilityFromJson(Map<String, dynamic> json) =>
    Contactability(
      channel: outreachChannelFromJson(json['channel']),
      allowed: readBool(json['allowed']),
      decision: outreachDecisionFromJson(json['decision']),
      reason: readOptionalString(json['reason']),
    );

/// `ClientOrderSummaryVm`. `itemCount` stays null when absent — an unknown
/// count is not zero items.
ClientOrderSummary clientOrderSummaryFromJson(Map<String, dynamic> json) =>
    ClientOrderSummary(
      orderId: readString(json['orderId']),
      orderNumber: readOptionalString(json['orderNumber']),
      vendorSubOrderStatus: readOptionalString(json['vendorSubOrderStatus']),
      placedUtc: readDate(json['placedUtc']),
      itemCount: json['itemCount'] == null ? null : readInt(json['itemCount']),
    );

/// `ClientBriefVm`.
ClientBrief clientBriefFromJson(Map<String, dynamic> json) => ClientBrief(
  assignmentId: readString(json['assignmentId']),
  vendorAccountId: readString(json['vendorAccountId']),
  associateAccountId: readString(json['associateAccountId']),
  customerAccountId: readString(json['customerAccountId']),
  customerDisplayName: readOptionalString(json['customerDisplayName']),
  customerHandle: readOptionalString(json['customerHandle']),
  customerAccountActive: readBool(json['customerAccountActive']),
  contactability: _objectList(
    json['contactability'],
  ).map(contactabilityFromJson).toList(),
  recentOrdersWithThisVendor: _objectList(
    json['recentOrdersWithThisVendor'],
  ).map(clientOrderSummaryFromJson).toList(),
  withheld: json['withheld'] is List
      ? (json['withheld']! as List)
            .map(readString)
            .where((s) => s.isNotEmpty)
            .toList()
      : const <String>[],
);

/// `AssistSessionVm`.
AssistSession assistSessionFromJson(Map<String, dynamic> json) => AssistSession(
  sessionId: readString(json['sessionId']),
  assignmentId: readString(json['assignmentId']),
  vendorAccountId: readString(json['vendorAccountId']),
  associateAccountId: readString(json['associateAccountId']),
  customerAccountId: readString(json['customerAccountId']),
  purpose: readOptionalString(json['purpose']),
  openedUtc: readDate(json['openedUtc']),
  closedUtc: readDate(json['closedUtc']),
  isOpen: readBool(json['isOpen']),
);

/// `OutreachAttemptVm`.
OutreachAttempt outreachAttemptFromJson(Map<String, dynamic> json) =>
    OutreachAttempt(
      outreachId: readString(json['outreachId']),
      customerAccountId: readString(json['customerAccountId']),
      sessionId: readOptionalString(json['sessionId']),
      channel: outreachChannelFromJson(json['channel']),
      decision: outreachDecisionFromJson(json['decision']),
      sent: readBool(json['sent']),
      subject: readOptionalString(json['subject']),
      decisionReason: readOptionalString(json['decisionReason']),
      requestedUtc: readDate(json['requestedUtc']),
    );

/// `AssistedOutcomeVm`.
AssistedOutcome assistedOutcomeFromJson(Map<String, dynamic> json) =>
    AssistedOutcome(
      outcomeId: readString(json['outcomeId']),
      sessionId: readString(json['sessionId']),
      vendorAccountId: readString(json['vendorAccountId']),
      associateAccountId: readString(json['associateAccountId']),
      customerAccountId: readString(json['customerAccountId']),
      orderId: readString(json['orderId']),
      orderNumber: readOptionalString(json['orderNumber']),
      orderPlacedUtc: readDate(json['orderPlacedUtc']),
      status: assistedOutcomeStatusFromJson(json['status']),
      note: readOptionalString(json['note']),
      claimedUtc: readDate(json['claimedUtc']),
      confirmedByAccountId: readOptionalString(json['confirmedByAccountId']),
      decidedUtc: readDate(json['decidedUtc']),
      isCredited: readBool(json['isCredited']),
    );

/// `ClientelingActivityVm`.
ClientelingActivity clientelingActivityFromJson(Map<String, dynamic> json) =>
    ClientelingActivity(
      activityId: readString(json['activityId']),
      vendorAccountId: readOptionalString(json['vendorAccountId']),
      associateAccountId: readString(json['associateAccountId']),
      customerAccountId: readString(json['customerAccountId']),
      sessionId: readOptionalString(json['sessionId']),
      type: clientelingActivityTypeFromJson(json['type']),
      detail: readOptionalString(json['detail']),
      subjectId: readOptionalString(json['subjectId']),
      occurredUtc: readDate(json['occurredUtc']),
    );

/// A bare `[...]` body of activity rows.
List<ClientelingActivity> clientelingActivityListFromJson(Object? raw) =>
    _objectList(raw).map(clientelingActivityFromJson).toList();

/// A bare `[...]` body of assisted outcomes.
List<AssistedOutcome> assistedOutcomeListFromJson(Object? raw) =>
    _objectList(raw).map(assistedOutcomeFromJson).toList();

/// The `PagedResult<ClientAssignmentVm>` envelope.
class ClientAssignmentPageDto {
  const ClientAssignmentPageDto({required this.items, this.nextCursor});

  factory ClientAssignmentPageDto.fromJson(Map<String, dynamic> json) =>
      ClientAssignmentPageDto(
        items: _objectList(
          json['items'],
        ).map(clientAssignmentFromJson).toList(),
        nextCursor: readOptionalString(json['nextCursor']),
      );

  final List<ClientAssignment> items;
  final String? nextCursor;
}
