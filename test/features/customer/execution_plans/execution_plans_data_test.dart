import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/datasources/execution_plans_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/models/commerce_execution_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/notifiers/execution_plans_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';

import '../../codes/support/recording_api_client.dart';

Map<String, dynamic> _budget({double? spend, String currency = 'NPR'}) =>
    <String, dynamic>{
      'maximumSpend': spend,
      'currency': currency,
      'maximumToolCalls': 3,
      'timeoutSeconds': 180,
    };

/// The four steps `CommerceIntentCompilerService.BuildDefinition` emits,
/// with the enum values the host actually serialises (integers — neither the
/// enums nor the host register a `JsonStringEnumConverter`).
Map<String, dynamic> _planJson({
  int status = 1,
  double? maximumSpend = 25000,
  String? approvedUtc,
  List<Map<String, dynamic>>? progress,
}) => <String, dynamic>{
  'id': 'plan-1',
  'accountId': 'acc-1',
  'intent': 'A rain jacket and boots for a trek in November',
  'maximumSpend': maximumSpend,
  'currency': 'NPR',
  'status': status,
  'definitionSha256': 'abc123',
  'approvedUtc': approvedUtc,
  'completedUtc': null,
  'createdUtc': '2026-09-19T08:00:00Z',
  'updatedUtc': '2026-09-19T08:00:00Z',
  'definition': <String, dynamic>{
    'schemaVersion': 1,
    'intent': 'A rain jacket and boots for a trek in November',
    'mustCompleteByUtc': '2026-10-30T00:00:00Z',
    'overallBudget': _budget(spend: maximumSpend),
    'tasks': <Map<String, dynamic>>[
      <String, dynamic>{
        'sequence': 1,
        'taskKey': 'discover',
        'purpose': 'Find evidence-backed candidates',
        'toolKey': 'catalog.search',
        'approval': 1,
        'budget': _budget(spend: 0),
        'requiredProofs': <String>['candidateIds', 'rankingReasons'],
        'fallbacks': <Map<String, dynamic>>[
          <String, dynamic>{
            'trigger': 'no_candidates',
            'action': 'broaden_query_once',
            'requiresCustomerApproval': false,
          },
        ],
        'completionConditions': <String>[
          'at_least_one_candidate',
          'all_candidates_current',
        ],
      },
      <String, dynamic>{
        'sequence': 2,
        'taskKey': 'compose_basket',
        'purpose': 'Build a bounded basket',
        'toolKey': 'basket.scenarios',
        'approval': 1,
        'budget': _budget(spend: maximumSpend),
        'requiredProofs': <String>['lineItems', 'total', 'currency'],
        'fallbacks': <Map<String, dynamic>>[],
        'completionConditions': <String>[
          'within_budget',
          'maximum_items_respected',
        ],
      },
      <String, dynamic>{
        'sequence': 3,
        'taskKey': 'prepare_checkout',
        'purpose': 'Reserve inventory and freeze payable terms',
        'toolKey': 'checkout.prepare',
        'approval': 2,
        'budget': _budget(spend: maximumSpend),
        'requiredProofs': <String>[
          'checkoutSessionId',
          'inventoryHoldIds',
          'priceSnapshot',
        ],
        'fallbacks': <Map<String, dynamic>>[],
        'completionConditions': <String>[
          'inventory_reserved',
          'price_snapshot_frozen',
        ],
      },
      <String, dynamic>{
        'sequence': 4,
        'taskKey': 'place_order',
        'purpose': 'Create the authoritative order',
        'toolKey': 'orders.place',
        'approval': 3,
        'budget': _budget(spend: maximumSpend),
        'requiredProofs': <String>[
          'orderId',
          'paymentReceipt',
          'total',
          'currency',
        ],
        'fallbacks': <Map<String, dynamic>>[],
        'completionConditions': <String>[
          'authoritative_order_created',
          'spend_within_budget',
        ],
      },
    ],
    'completionConditions': <String>[
      'all_tasks_completed',
      'authoritative_order_id_present',
      'total_spend_within_budget',
    ],
  },
  'progress': <String, dynamic>{
    'tasks':
        progress ??
        <Map<String, dynamic>>[
          for (final entry in <(String, bool)>[
            ('discover', true),
            ('compose_basket', true),
            ('prepare_checkout', true),
            ('place_order', false),
          ])
            <String, dynamic>{
              'taskKey': entry.$1,
              'status': 1,
              'approved': entry.$2,
              'proofJson': null,
              'fallbackActivated': false,
              'completedUtc': null,
            },
        ],
  },
};

void main() {
  group('parseCommerceExecutionPlan', () {
    test('maps the compiled plan and its four steps', () {
      final plan = parseCommerceExecutionPlan(_planJson());

      expect(plan.id, 'plan-1');
      expect(plan.intent, contains('rain jacket'));
      expect(plan.status, ExecutionPlanStatus.awaitingCustomerApproval);
      expect(plan.spendLimit?.amount, 25000);
      expect(plan.spendLimit?.currency, 'NPR');
      expect(plan.mustCompleteByUtc, isNotNull);
      expect(plan.approvedUtc, isNull);
      expect(
        plan.steps.map((s) => s.taskKey),
        <String>['discover', 'compose_basket', 'prepare_checkout',
          'place_order'],
      );
      expect(plan.steps.first.approval, ExecutionApproval.none);
      expect(
        plan.steps[2].approval,
        ExecutionApproval.customerBeforeExecution,
      );
      expect(plan.steps[3].approval, ExecutionApproval.customerAtTask);
      expect(plan.steps.every((s) => s.status == ExecutionStepStatus.pending),
          isTrue);
    });

    test('string enum names parse too, so a later converter cannot break it',
        () {
      final json = _planJson()..['status'] = 'AwaitingCustomerApproval';
      final tasks =
          (json['definition']! as Map<String, dynamic>)['tasks']! as List;
      (tasks[3] as Map<String, dynamic>)['approval'] = 'CustomerAtTask';

      final plan = parseCommerceExecutionPlan(json);

      expect(plan.status, ExecutionPlanStatus.awaitingCustomerApproval);
      expect(plan.steps[3].approval, ExecutionApproval.customerAtTask);
    });

    test('an unrecognised status names itself rather than hiding', () {
      final plan = parseCommerceExecutionPlan(_planJson()..['status'] = 99);

      expect(plan.status, ExecutionPlanStatus.unrecognised);
      expect(plan.rawStatus, 99);
      expect(
        ExecutionPlanCopy.planStatusLabel(plan.status,
            rawStatus: plan.rawStatus),
        contains('99'),
      );
    });

    test('no spending limit stays null, never zero', () {
      final plan =
          parseCommerceExecutionPlan(_planJson(maximumSpend: null));

      expect(plan.spendLimit, isNull);
      expect(plan.steps[2].budgetCap, isNull);
    });

    test('the step that reserves stock and freezes a price is marked as such',
        () {
      final plan = parseCommerceExecutionPlan(_planJson());
      final prepare = plan.steps[2];

      expect(prepare.commitments, <ExecutionCommitment>{
        ExecutionCommitment.price,
        ExecutionCommitment.stock,
      });
      expect(prepare.isCommitting, isTrue);
    });

    test('the step that would move money is marked as such', () {
      final plan = parseCommerceExecutionPlan(_planJson());

      expect(
        plan.steps[3].commitments,
        contains(ExecutionCommitment.money),
      );
    });

    test('the two read-only steps commit to nothing', () {
      final plan = parseCommerceExecutionPlan(_planJson());

      expect(plan.steps[0].isCommitting, isFalse);
      expect(plan.steps[1].isCommitting, isFalse);
    });

    test('the pre-set approved bit is never read as the shopper approving',
        () {
      final plan = parseCommerceExecutionPlan(_planJson());

      // The backend sets approved=true on every step whose gate is not
      // CustomerAtTask. That is "no separate gate", not a go-ahead.
      expect(plan.steps[2].approvedOnWire, isTrue);
      expect(plan.steps[2].hasOwnApproval, isFalse);
      expect(plan.steps[2].needsOwnApproval, isFalse);
      expect(
        ExecutionPlanCopy.approvalNote(plan.steps[2], planApproved: false),
        'Waiting on the go-ahead for the whole plan.',
      );
      expect(plan.steps[3].needsOwnApproval, isTrue);
    });

    test('evidence recorded without the shopper approving is refused', () {
      final json = _planJson(
        status: 3,
        progress: <Map<String, dynamic>>[
          <String, dynamic>{
            'taskKey': 'place_order',
            'status': 3,
            'approved': false,
            'proofJson': '{"orderId":"o-1"}',
            'fallbackActivated': false,
            'completedUtc': '2026-09-19T09:00:00Z',
          },
        ],
      );

      final plan = parseCommerceExecutionPlan(json);

      expect(plan.steps[3].isUnapprovedCommitment, isTrue);
      expect(plan.hasUnapprovedStep, isTrue);
      expect(plan.mustRefuseToRender, isTrue);
    });

    test('evidence against a plan nobody approved is refused', () {
      final json = _planJson(
        status: 3,
        progress: <Map<String, dynamic>>[
          <String, dynamic>{
            'taskKey': 'discover',
            'status': 3,
            'approved': true,
            'fallbackActivated': false,
            'completedUtc': '2026-09-19T09:00:00Z',
          },
        ],
      );

      final plan = parseCommerceExecutionPlan(json);

      expect(plan.approvedUtc, isNull);
      expect(plan.isUnapprovedCommitment, isTrue);
      expect(plan.mustRefuseToRender, isTrue);
    });

    test('a body that is not a plan does not throw', () {
      final plan = parseCommerceExecutionPlan(<String, dynamic>{});

      expect(plan.id, '');
      expect(plan.steps, isEmpty);
      expect(plan.spendLimit, isNull);
    });
  });

  group('ExecutionPlansRemoteDataSource', () {
    ExecutionPlansRemoteDataSource source(RecordingApiClient api) =>
        ExecutionPlansRemoteDataSource(apiClient: api);

    test('compile posts the intent with an Idempotency-Key', () async {
      final api = RecordingApiClient((_) => _planJson());

      await source(api).compile(
        intent: '  boots  ',
        currency: 'npr',
        maximumItems: 5,
        maximumSpend: 25000,
        idempotencyKey: 'key-1',
      );

      expect(api.last.method, 'POST');
      expect(api.last.uri, '/v1/commerce-execution-plans');
      final body = api.last.data! as Map<String, dynamic>;
      expect(body['intent'], 'boots');
      expect(body['currency'], 'NPR');
      expect(body['maximumSpend'], 25000);
      expect(api.last.header('Idempotency-Key'), 'key-1');
    });

    test('compile omits a limit that was never set', () async {
      final api = RecordingApiClient((_) => _planJson(maximumSpend: null));

      await source(api).compile(
        intent: 'boots',
        currency: 'NPR',
        maximumItems: 5,
        idempotencyKey: 'key-2',
      );

      expect(
        (api.last.data! as Map<String, dynamic>).containsKey('maximumSpend'),
        isFalse,
        reason: 'a missing ceiling is not a ceiling of zero',
      );
    });

    test('list reads the collection', () async {
      final api = RecordingApiClient((_) => <dynamic>[_planJson()]);

      final plans = await source(api).list();

      expect(api.last.method, 'GET');
      expect(api.last.uri, '/v1/commerce-execution-plans');
      expect(plans, hasLength(1));
    });

    test('approve posts to the plan, approve-step to the task', () async {
      final api = RecordingApiClient((_) => _planJson(status: 2));

      await source(api).approvePlan(planId: 'plan-1', idempotencyKey: 'k');
      expect(api.last.uri, '/v1/commerce-execution-plans/plan-1/approve');

      await source(api).approveStep(
        planId: 'plan-1',
        taskKey: 'place_order',
        idempotencyKey: 'k',
      );
      expect(
        api.last.uri,
        '/v1/commerce-execution-plans/plan-1/tasks/place_order/approve',
      );
    });

    test('there is no way to record evidence from this app', () {
      // `POST {planId}/tasks/{taskKey}/evidence` is the only route in this
      // family that turns a proposed step into a recorded one. §5.9 keeps it
      // off this client, and this asserts the door stays shut.
      final code = File(
        'lib/features/customer/execution_plans/data/datasources/'
        'execution_plans_datasource.dart',
      ).readAsLinesSync().where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('//');
      }).join('\n');

      expect(
        code.contains('evidence'),
        isFalse,
        reason: 'no evidence URL may be built anywhere in this app',
      );
    });
  });

  group('executionPlanErrorCodeOf', () {
    test('reads the backend errorCode out of an RFC 7807 body', () {
      final error = dioError(
        400,
        body: <String, dynamic>{'errorCode': 'validation.out_of_range'},
      );

      expect(executionPlanErrorCodeOf(error), 'validation.out_of_range');
      expect(
        ExecutionPlanCopy.actionFailure(
          executionPlanErrorCodeOf(error),
        ).title,
        'That is outside what a plan may hold',
      );
    });

    test('a call that never landed is a transport failure', () {
      expect(
        executionPlanErrorCodeOf(dioError(null)),
        ExecutionPlanCopy.transportFailure,
      );
      expect(
        ExecutionPlanCopy.actionFailure(
          ExecutionPlanCopy.transportFailure,
        ).body,
        contains('Nothing changed'),
      );
    });

    test('a body with no errorCode still never shows a raw exception', () {
      expect(
        executionPlanErrorCodeOf(dioError(500, body: 'boom')),
        ExecutionPlanCopy.transportFailure,
      );
    });
  });
}
