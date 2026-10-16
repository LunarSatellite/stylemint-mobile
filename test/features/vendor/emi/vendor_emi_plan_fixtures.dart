import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/models/vendor_emi_plan_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/repositories/vendor_emi_repository.dart';

/// Seller EMI plan payloads as `v1/credit/vendor/plans` sends them
/// (emi-after contract v1). "Today" in these tests is 2026-10-16.
final DateTime planToday = DateTime(2026, 10, 16);

const overduePlanId = '0b5e2d9a-1f43-4c55-9a0e-2f1d7c8b6a01';
const dueSoonPlanId = '0b5e2d9a-1f43-4c55-9a0e-2f1d7c8b6a02';
const completedPlanId = '0b5e2d9a-1f43-4c55-9a0e-2f1d7c8b6a03';
const planSubOrderId = '7a2c4e6f-8b0d-4f1a-9c3e-5d7f9b1d3e5f';

class MockVendorEmiRepository extends Mock implements VendorEmiRepository {}

const notFound = EmiFailure(EmiFailureKind.notFound, statusCode: 404);

Map<String, dynamic> instalmentWire(
  int number, {
  required String dueDate,
  int state = 1,
  double amount = 16000,
  double paid = 0,
  double lateFee = 0,
}) => {
  'number': number,
  'dueDate': dueDate,
  'scheduledAmount': amount,
  'principalDue': amount,
  'interestDue': 0,
  'lateFeeDue': lateFee,
  'paid': paid,
  'outstanding': state == 3 ? 0 : amount + lateFee - paid,
  'state': state,
  'paidUtc': state == 3 ? '${dueDate}T05:00:00+00:00' : null,
  'credited': 0,
  'lateFeeWaived': 0,
};

/// One `VendorCreditApplicationDto`. [withNewFields] false leaves out
/// everything contract v1 added, as a server before the deploy would.
Map<String, dynamic> vendorPlanWire({
  String id = overduePlanId,
  int state = 3,
  List<Map<String, dynamic>>? instalments,
  double outstanding = 32500,
  double paidToDate = 28000,
  int daysPastDue = 6,
  String buyer = 'Sarah P.',
  String product = 'Leather jacket',
  String? orderNumber = 'NK2026-00101',
  String downPaymentStatus = 'paid_online',
  bool withNewFields = true,
}) {
  final schedule =
      instalments ??
      [
        instalmentWire(1, dueDate: '2026-09-10', state: 3, paid: 16000),
        instalmentWire(2, dueDate: '2026-10-10', state: 4, lateFee: 500),
        instalmentWire(3, dueDate: '2026-11-10'),
      ];
  Map<String, dynamic>? next;
  for (final i in schedule) {
    if (i['state'] != 3 && i['state'] != 5) {
      next = i;
      break;
    }
  }
  return {
    'agreement': {
      'id': id,
      'buyerAccountId': '1f67201b-7d81-4a60-93c2-b8869639dadb',
      'vendorAccountId': 'de135640-cc06-4ce7-9c2a-5804ecb88092',
      'productId': '11645bf9-cfca-4df2-88fa-7ebaec17d369',
      'variantId': 'f0a10cdf-15d7-4402-8774-9ac69f7aa421',
      'kind': 1,
      'guarantor': 1,
      'state': state,
      'stateReasons': const <String>[],
      'currency': 'NPR',
      'price': 60000,
      'downPayment': 12000,
      'financed': 48000,
      'tenureMonths': 3,
      'interestMethod': 0,
      'totalInterest': 0,
      'totalPayable': 60000,
      'aprPercent': 0,
      'outstanding': outstanding,
      'outstandingPrincipal': outstanding,
      'payoffAmountToday': outstanding,
      'daysPastDue': daysPastDue,
      'appliedUtc': '2026-08-01T06:00:00+00:00',
      'activatedUtc': '2026-08-10T06:00:00+00:00',
      'needsActivationPayment': false,
      'orderId': 'c3d4e5f6-0000-4000-8000-000000000001',
      'downPaymentOnDelivery': false,
      'instalments': schedule,
      if (withNewFields) ...{
        'paidToDate': paidToDate,
        'instalmentsPaid': 1,
        'instalmentsRemaining': 2,
        'nextInstalment': next,
        'lateFeesOutstanding': 500,
      },
    },
    'buyerDisplayName': buyer,
    'productName': product,
    'monthlyInstalment': 16000,
    'documents': const <dynamic>[],
    'riskScore': 712,
    'riskBand': 1,
    'riskReasons': const <String>[],
    if (withNewFields) ...{
      'orderNumber': orderNumber,
      'vendorSubOrderId': planSubOrderId,
      'downPaymentStatus': downPaymentStatus,
    },
  };
}

/// The three plans the list tests show: one overdue, one due in two days,
/// one paid off.
List<Map<String, dynamic>> threePlansWire() => [
  vendorPlanWire(),
  vendorPlanWire(
    id: dueSoonPlanId,
    buyer: 'Ram K.',
    product: 'Silk saree',
    orderNumber: 'NK2026-00102',
    daysPastDue: 0,
    outstanding: 48000,
    paidToDate: 12000,
    instalments: [
      instalmentWire(1, dueDate: '2026-10-18'),
      instalmentWire(2, dueDate: '2026-11-18'),
      instalmentWire(3, dueDate: '2026-12-18'),
    ],
  ),
  vendorPlanWire(
    id: completedPlanId,
    state: 4,
    buyer: 'Mina T.',
    product: 'Wool coat',
    orderNumber: 'NK2026-00090',
    daysPastDue: 0,
    outstanding: 0,
    paidToDate: 60000,
    instalments: [
      instalmentWire(1, dueDate: '2026-06-10', state: 3, paid: 16000),
      instalmentWire(2, dueDate: '2026-07-10', state: 3, paid: 16000),
      instalmentWire(3, dueDate: '2026-08-10', state: 3, paid: 16000),
    ],
  ),
];

List<VendorEmiPlan> threePlans() => readVendorEmiPlans(threePlansWire());

void stubPlans(
  MockVendorEmiRepository repo, {
  List<VendorEmiPlan>? plans,
  EmiFailure? failure,
}) {
  when(repo.getPlans).thenAnswer(
    (_) async => failure != null
        ? left<EmiFailure, List<VendorEmiPlan>>(failure)
        : right<EmiFailure, List<VendorEmiPlan>>(plans ?? threePlans()),
  );
  when(() => repo.getPlan(any())).thenAnswer((invocation) async {
    if (failure != null) return left<EmiFailure, VendorEmiPlan>(failure);
    final id = invocation.positionalArguments.first as String;
    final all = plans ?? threePlans();
    for (final p in all) {
      if (p.id == id) return right<EmiFailure, VendorEmiPlan>(p);
    }
    return left<EmiFailure, VendorEmiPlan>(notFound);
  });
}
