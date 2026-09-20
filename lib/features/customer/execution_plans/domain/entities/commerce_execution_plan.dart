import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Where a plan stands, as the backend's `CommerceExecutionPlanStatus`
/// records it.
///
/// None of these mean "StyleMint did something". A plan is a compiled
/// proposal; every step in it is work a human still has to carry out in the
/// ordinary guarded checkout.
enum ExecutionPlanStatus {
  awaitingCustomerApproval,
  ready,
  inProgress,
  completed,
  failed,
  cancelled,

  /// A status this build has no name for. It is never guessed at, and it
  /// never unlocks a button.
  unrecognised,
}

/// Where one step stands, as the backend's `CommerceExecutionTaskStatus`
/// records it.
enum ExecutionStepStatus {
  pending,
  inProgress,
  completed,
  failed,
  skipped,
  unrecognised,
}

/// Who has to say yes before a step may be carried out, as the backend's
/// `CommerceExecutionApproval` records it.
enum ExecutionApproval {
  /// Nobody. The step reads the catalogue or arranges a basket; it touches
  /// no price, no stock and no money.
  none,

  /// Covered by the go-ahead the shopper gives the whole plan.
  customerBeforeExecution,

  /// Needs its own separate go-ahead from the shopper, on top of the plan's.
  customerAtTask,

  unrecognised,
}

/// What a step would touch if a human carried it out.
///
/// Read out of the backend's own `completionConditions` and `requiredProofs`
/// — never guessed from the step's wording. Section 5.9 of the client
/// proposal says StyleMint's AI "will not set prices, reserve stock or move
/// money", so these three are exactly the things this app must show as
/// *not yet done* and must never offer to do on the shopper's behalf.
enum ExecutionCommitment { price, stock, money }

/// One compiled step: the definition the backend fixed at compile time, and
/// whatever progress has since been recorded against it.
class ExecutionStep {
  const ExecutionStep({
    required this.sequence,
    required this.taskKey,
    required this.purpose,
    required this.toolKey,
    required this.approval,
    required this.requiredProofs,
    required this.completionConditions,
    required this.status,
    required this.approvedOnWire,
    required this.fallbackActivated,
    this.budgetCap,
    this.completedUtc,
  });

  final int sequence;
  final String taskKey;

  /// The compiler's one-line description of the step.
  final String purpose;

  /// The backend tool the step names, e.g. `checkout.prepare`.
  final String toolKey;

  final ExecutionApproval approval;

  /// Evidence a human must produce before the step may be recorded as done.
  final List<String> requiredProofs;

  /// What the backend requires to be true for the step to count.
  final List<String> completionConditions;

  /// A ceiling this step may not exceed. A cap is not a spend, and a step
  /// with no cap recorded carries null rather than zero.
  final Money? budgetCap;

  final ExecutionStepStatus status;

  /// The raw `approved` bit.
  ///
  /// **This is not "the shopper approved this step."** The backend pre-sets
  /// it to `true` for every step whose approval is not
  /// [ExecutionApproval.customerAtTask], purely to record "no separate gate
  /// here". Drawing it as a tick would tell a shopper they authorised a
  /// stock reservation they never saw. Read it only through
  /// [needsOwnApproval] and [hasOwnApproval].
  final bool approvedOnWire;

  final bool fallbackActivated;

  /// When evidence was recorded against this step, if it ever was.
  final DateTime? completedUtc;

  /// What carrying this step out would touch. Derived from the backend's own
  /// completion conditions and required proofs.
  Set<ExecutionCommitment> get commitments => <ExecutionCommitment>{
    if (completionConditions.contains('price_snapshot_frozen') ||
        requiredProofs.contains('priceSnapshot'))
      ExecutionCommitment.price,
    if (completionConditions.contains('inventory_reserved') ||
        requiredProofs.contains('inventoryHoldIds'))
      ExecutionCommitment.stock,
    if (requiredProofs.contains('paymentReceipt') ||
        completionConditions.contains('authoritative_order_created'))
      ExecutionCommitment.money,
  };

  /// True when this step would touch a price, stock or money — the three
  /// things §5.9 keeps on the human side of the line.
  bool get isCommitting => commitments.isNotEmpty;

  /// This step has its own approval gate and the shopper has not passed it.
  bool get needsOwnApproval =>
      approval == ExecutionApproval.customerAtTask && !approvedOnWire;

  /// This step has its own approval gate and the shopper has passed it.
  /// Passing the gate is a go-ahead, not an execution.
  bool get hasOwnApproval =>
      approval == ExecutionApproval.customerAtTask && approvedOnWire;

  /// StyleMint has recorded evidence against this step. Evidence is a
  /// record that a human did something elsewhere — it is never this app
  /// doing it, because this app never posts evidence.
  bool get hasRecordedEvidence =>
      status == ExecutionStepStatus.completed || completedUtc != null;

  /// Evidence recorded against a step the shopper never gave its own
  /// go-ahead to: a commitment that appeared by itself.
  ///
  /// The backend refuses to create this today — `RecordTaskEvidenceAsync`
  /// checks the approval first — so this should never be true. If it ever
  /// is, the screen stops and says so instead of drawing the step.
  bool get isUnapprovedCommitment =>
      hasRecordedEvidence &&
      approval == ExecutionApproval.customerAtTask &&
      !approvedOnWire;
}

/// A shopper's stated intent, compiled into steps somebody still has to take.
class CommerceExecutionPlan {
  const CommerceExecutionPlan({
    required this.id,
    required this.intent,
    required this.status,
    required this.steps,
    required this.createdUtc,
    this.spendLimit,
    this.mustCompleteByUtc,
    this.approvedUtc,
    this.completedUtc,
    this.rawStatus,
  });

  final String id;

  /// The shopper's own words, as they typed them.
  final String intent;

  final ExecutionPlanStatus status;

  /// The wire value, kept so an unrecognised status can name itself rather
  /// than hide.
  final int? rawStatus;

  /// The ceiling the shopper set, if they set one. Null is "no limit was
  /// recorded" — never zero.
  final Money? spendLimit;

  final DateTime? mustCompleteByUtc;

  /// When the shopper gave the whole plan its go-ahead. Null means they have
  /// not.
  final DateTime? approvedUtc;

  final DateTime? completedUtc;
  final DateTime createdUtc;

  /// In compiled order.
  final List<ExecutionStep> steps;

  bool get awaitsApproval =>
      status == ExecutionPlanStatus.awaitingCustomerApproval;

  bool get isOpen =>
      status == ExecutionPlanStatus.awaitingCustomerApproval ||
      status == ExecutionPlanStatus.ready ||
      status == ExecutionPlanStatus.inProgress;

  /// Steps still waiting on a go-ahead only the shopper can give.
  List<ExecutionStep> get stepsNeedingYou =>
      steps.where((step) => step.needsOwnApproval).toList(growable: false);

  bool get hasRecordedEvidence => steps.any((step) => step.hasRecordedEvidence);

  /// Evidence exists against a plan the shopper never approved — work that
  /// appears to have happened without them. The backend cannot produce this
  /// (`UpdateProgress` refuses unless the plan is Ready or InProgress, and
  /// only `Approve` reaches Ready), so it is a tripwire, not a state.
  bool get isUnapprovedCommitment => hasRecordedEvidence && approvedUtc == null;

  /// Any step whose recorded evidence outran its own approval gate.
  bool get hasUnapprovedStep =>
      steps.any((step) => step.isUnapprovedCommitment);

  /// True when this plan carries something this app will not draw, because
  /// drawing it would tell a shopper that a price, a hold or a payment
  /// happened on its own. See §5.9.
  bool get mustRefuseToRender => isUnapprovedCommitment || hasUnapprovedStep;
}
