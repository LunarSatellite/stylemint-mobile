import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Where an EMI plan's down payment stands (`downPaymentStatus`).
enum VendorDownPaymentStatus {
  none('none', 'No down payment'),
  due('due', 'Due online'),
  collectOnDelivery('collect_on_delivery', 'Rider collects in cash'),
  paidOnline('paid_online', 'Paid online'),
  receivedInCash('received_in_cash', 'Received in cash');

  const VendorDownPaymentStatus(this.wire, this.label);
  final String wire;
  final String label;

  bool get received => this == paidOnline || this == receivedInCash;

  static VendorDownPaymentStatus? fromWire(Object? raw) {
    if (raw is! String) return null;
    final key = raw.trim().toLowerCase();
    for (final s in values) {
      if (s.wire == key) return s;
    }
    return null;
  }

  /// What the agreement itself says, for a payload without the field.
  static VendorDownPaymentStatus of(CreditAgreement a) {
    if (a.downPayment.amount <= 0) return none;
    final started = a.activatedAt != null;
    return switch ((started, a.downPaymentOnDelivery)) {
      (false, true) => collectOnDelivery,
      (false, false) => due,
      (true, true) => receivedInCash,
      (true, false) => paidOnline,
    };
  }
}

/// How one instalment reads on the seller's schedule (the contract's
/// display rule, on the Kathmandu calendar).
enum VendorInstalmentStanding {
  paid('Paid'),
  overdue('Overdue'),
  dueToday('Due today'),
  dueSoon('Due soon'),
  upcoming('Upcoming'),
  notStarted('Starts when the plan starts');

  const VendorInstalmentStanding(this.label);
  final String label;
}

/// Today's date in Asia/Kathmandu (UTC+5:45, no daylight saving), as a
/// date-only value: what due dates are compared with.
DateTime kathmanduToday([DateTime? nowUtc]) {
  final npt = (nowUtc ?? DateTime.now()).toUtc().add(
    const Duration(hours: 5, minutes: 45),
  );
  return DateTime(npt.year, npt.month, npt.day);
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Days from [today] to [due], both read as calendar dates.
int daysUntil(DateTime due, DateTime today) =>
    _day(due).difference(_day(today)).inDays;

VendorInstalmentStanding instalmentStanding(
  PlanInstalment i,
  DateTime today,
) {
  if (i.status.isSettled) return VendorInstalmentStanding.paid;
  if (i.status == InstalmentStatus.overdue) {
    return VendorInstalmentStanding.overdue;
  }
  final due = i.dueDate;
  if (due == null) return VendorInstalmentStanding.notStarted;
  final days = daysUntil(due, today);
  if (days < 0) return VendorInstalmentStanding.overdue;
  if (days == 0) return VendorInstalmentStanding.dueToday;
  if (days <= 3) return VendorInstalmentStanding.dueSoon;
  return VendorInstalmentStanding.upcoming;
}

/// A vendor-funded EMI plan after approval, as the seller follows it
/// (`GET v1/credit/vendor/plans`). The buyer appears by display name only —
/// never a phone number or an email.
class VendorEmiPlan {
  const VendorEmiPlan({
    required this.agreement,
    required this.buyerDisplayName,
    required this.productName,
    required this.monthlyInstalment,
    required this.downPaymentStatus,
    required this.collected,
    required this.lateFeesOutstanding,
    this.nextInstalment,
    this.orderNumber,
    this.vendorSubOrderId,
  });

  final CreditAgreement agreement;
  final String buyerDisplayName;
  final String productName;
  final Money monthlyInstalment;
  final VendorDownPaymentStatus downPaymentStatus;

  /// Paid so far: the down payment once the plan started, plus every
  /// instalment payment (late fees included).
  final Money collected;
  final Money lateFeesOutstanding;

  /// The earliest instalment still owed; null when none is.
  final PlanInstalment? nextInstalment;
  final String? orderNumber;

  /// The seller's own sub-order, for their order page.
  final String? vendorSubOrderId;

  String get id => agreement.id;
  AgreementStatus get status => agreement.status;
  Money get financed => agreement.financed;

  /// Still to collect.
  Money get remaining => agreement.outstanding;

  bool get isOverdue =>
      !status.isClosed && (agreement.hasOverdue || agreement.daysPastDue > 0);

  bool get isRunning =>
      status == AgreementStatus.approved || status == AgreementStatus.active;

  bool get isCompleted => status == AgreementStatus.completed;

  /// The next instalment falls due within three days (today included).
  bool isDueSoon(DateTime today) {
    if (!isRunning || isOverdue) return false;
    final due = nextInstalment?.dueDate;
    if (due == null) return false;
    final days = daysUntil(due, today);
    return days >= 0 && days <= 3;
  }

  int get instalmentsPaid =>
      agreement.instalments.where((i) => i.status.isSettled).length;
}

/// The list screen's filters.
enum VendorEmiPlanFilter {
  active('Active'),
  overdue('Overdue'),
  dueSoon('Due soon'),
  completed('Completed'),
  all('All');

  const VendorEmiPlanFilter(this.label);
  final String label;

  bool matches(VendorEmiPlan plan, DateTime today) => switch (this) {
    active => plan.isRunning,
    overdue => plan.isOverdue,
    dueSoon => plan.isDueSoon(today),
    completed => plan.isCompleted,
    all => true,
  };
}
