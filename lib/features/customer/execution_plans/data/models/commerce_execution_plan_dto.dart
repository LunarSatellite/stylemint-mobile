import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Parses the backend `CommerceExecutionPlanView`.
///
/// Wire shape (camelCase, ASP.NET web defaults):
/// ```json
/// { id, accountId, intent, maximumSpend?, currency, status,
///   definitionSha256,
///   definition: { schemaVersion, intent, mustCompleteByUtc?,
///                 overallBudget: { maximumSpend?, currency,
///                                  maximumToolCalls, timeoutSeconds },
///                 tasks: [ { sequence, taskKey, purpose, toolKey, approval,
///                            budget: {...}, requiredProofs: [],
///                            fallbacks: [ { trigger, action,
///                                           requiresCustomerApproval } ],
///                            completionConditions: [] } ],
///                 completionConditions: [] },
///   progress: { tasks: [ { taskKey, status, approved, proofJson?,
///                          fallbackActivated, completedUtc? } ] },
///   approvedUtc?, completedUtc?, createdUtc, updatedUtc }
/// ```
///
/// `status` and `approval` carry **no** `JsonStringEnumConverter` on the
/// backend and the host registers no global one, so they arrive as integers.
/// Names are accepted too, so a later converter cannot silently break this.
///
/// `proofJson` is deliberately not parsed. It is opaque text produced
/// elsewhere, and nothing in this app renders it.
CommerceExecutionPlan parseCommerceExecutionPlan(Map<String, dynamic> json) {
  final definition = _map(json['definition']);
  final progressByKey = <String, Map<String, dynamic>>{
    for (final task in _list(_map(json['progress'])['tasks']))
      readString(task['taskKey']): task,
  };
  final rawStatus = normalizeWireEnum(json['status']);

  return CommerceExecutionPlan(
    id: readString(json['id']),
    intent: readString(json['intent']).isNotEmpty
        ? readString(json['intent'])
        : readString(definition['intent']),
    status: _planStatus(rawStatus),
    rawStatus: rawStatus is int ? rawStatus : null,
    spendLimit: _money(json['maximumSpend'], json['currency']),
    mustCompleteByUtc: readDate(definition['mustCompleteByUtc']),
    approvedUtc: readDate(json['approvedUtc']),
    completedUtc: readDate(json['completedUtc']),
    createdUtc: readDate(json['createdUtc']) ?? DateTime.now().toUtc(),
    steps: _steps(definition, progressByKey),
  );
}

List<ExecutionStep> _steps(
  Map<String, dynamic> definition,
  Map<String, Map<String, dynamic>> progressByKey,
) {
  final steps = <ExecutionStep>[];
  for (final task in _list(definition['tasks'])) {
    final key = readString(task['taskKey']);
    if (key.isEmpty) continue;
    final progress = progressByKey[key] ?? const <String, dynamic>{};
    final budget = _map(task['budget']);
    steps.add(
      ExecutionStep(
        sequence: readInt(task['sequence']),
        taskKey: key,
        purpose: readString(task['purpose']),
        toolKey: readString(task['toolKey']),
        approval: _approval(normalizeWireEnum(task['approval'])),
        requiredProofs: _strings(task['requiredProofs']),
        completionConditions: _strings(task['completionConditions']),
        budgetCap: _money(budget['maximumSpend'], budget['currency']),
        status: _stepStatus(normalizeWireEnum(progress['status'])),
        approvedOnWire: readBool(progress['approved']),
        fallbackActivated: readBool(progress['fallbackActivated']),
        completedUtc: readDate(progress['completedUtc']),
      ),
    );
  }
  steps.sort((a, b) => a.sequence.compareTo(b.sequence));
  return List<ExecutionStep>.unmodifiable(steps);
}

/// A cap only exists when the backend sent an amount. Half a figure is no
/// figure: a missing limit stays null rather than becoming "Rs 0", which
/// would read as "may spend nothing".
Money? _money(Object? amount, Object? currency) {
  final value = readOptionalDouble(amount);
  final code = readOptionalString(currency);
  if (value == null || code == null) return null;
  return Money(amount: value, currency: code.toUpperCase());
}

ExecutionPlanStatus _planStatus(Object? raw) => switch (raw) {
  1 || 'awaitingcustomerapproval' =>
    ExecutionPlanStatus.awaitingCustomerApproval,
  2 || 'ready' => ExecutionPlanStatus.ready,
  3 || 'inprogress' => ExecutionPlanStatus.inProgress,
  4 || 'completed' => ExecutionPlanStatus.completed,
  5 || 'failed' => ExecutionPlanStatus.failed,
  6 || 'cancelled' => ExecutionPlanStatus.cancelled,
  _ => ExecutionPlanStatus.unrecognised,
};

ExecutionStepStatus _stepStatus(Object? raw) => switch (raw) {
  1 || 'pending' => ExecutionStepStatus.pending,
  2 || 'inprogress' => ExecutionStepStatus.inProgress,
  3 || 'completed' => ExecutionStepStatus.completed,
  4 || 'failed' => ExecutionStepStatus.failed,
  5 || 'skipped' => ExecutionStepStatus.skipped,
  _ => ExecutionStepStatus.unrecognised,
};

ExecutionApproval _approval(Object? raw) => switch (raw) {
  1 || 'none' => ExecutionApproval.none,
  2 || 'customerbeforeexecution' => ExecutionApproval.customerBeforeExecution,
  3 || 'customerattask' => ExecutionApproval.customerAtTask,
  _ => ExecutionApproval.unrecognised,
};

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? value) =>
    (value is List ? value : const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

List<String> _strings(Object? value) =>
    (value is List ? value : const <dynamic>[])
        .map(readString)
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
