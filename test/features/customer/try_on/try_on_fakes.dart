import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';

const monthly = TryOnPlan(
  id: 'p1',
  name: 'Monthly',
  priceAmount: 199,
  currency: 'NPR',
  durationDays: 30,
);

TryOnAccess accessOf({
  bool enabled = true,
  bool hasAccess = false,
  bool trial = true,
  List<TryOnPlan> plans = const [monthly],
}) => TryOnAccess(
  serviceEnabled: enabled,
  hasAccess: hasAccess,
  source: hasAccess ? TryOnAccessSource.subscription : null,
  trialAvailable: trial,
  freeTrialDays: 7,
  disclaimer: 'Try-on is an approximation.',
  plans: plans,
);

MyTryOnSubscription subOf(TryOnSubscriptionState state) => MyTryOnSubscription(
  id: 's1',
  planId: 'p1',
  planName: 'Monthly',
  source: TryOnAccessSource.subscription,
  state: state,
  priceAmount: 199,
  currency: 'NPR',
  createdUtc: DateTime.utc(2026, 10, 14),
);

/// A scriptable [TryOnRepository]: set the next answers, read the calls.
class FakeTryOnRepository implements TryOnRepository {
  Either<TryOnFailure, TryOnAccess> access = right(accessOf());
  Either<TryOnFailure, TryOnAccess> trial = right(accessOf(hasAccess: true));
  Either<TryOnFailure, TryOnPaymentStart> subscribeResult = right(
    TryOnPaymentStart(
      subscription: subOf(TryOnSubscriptionState.pendingPayment),
      redirectUrl: 'https://pay.example/esewa',
    ),
  );
  Either<TryOnFailure, MyTryOnSubscription> confirmResult = right(
    subOf(TryOnSubscriptionState.active),
  );
  Either<TryOnFailure, BodyMeasurements?> measurements = right(null);
  Either<TryOnFailure, FitRecommendation> fit = right(
    const FitRecommendation(
      productId: 'prod',
      recommendedSize: 'M',
      confidence: 0.8,
      perSize: [
        SizeFit(
          sizeLabel: 'S',
          verdict: FitVerdict.tooSmall,
          notes: ['Chest about 4 cm tight'],
        ),
        SizeFit(sizeLabel: 'M', verdict: FitVerdict.good),
      ],
      missingMeasurements: [],
      basedOn: 'Your chest 96 cm, regular fit',
    ),
  );

  final List<String> calls = [];
  final List<String> keys = [];

  @override
  Future<Either<TryOnFailure, TryOnAccess>> getAccess() async {
    calls.add('access');
    return access;
  }

  @override
  Future<Either<TryOnFailure, TryOnAccess>> startTrial({
    required String idempotencyKey,
  }) async {
    calls.add('trial');
    keys.add(idempotencyKey);
    return trial;
  }

  @override
  Future<Either<TryOnFailure, TryOnPaymentStart>> subscribe({
    required String planId,
    required TryOnPaymentRail rail,
    required String idempotencyKey,
  }) async {
    calls.add('subscribe:$planId:${rail.wire}');
    keys.add(idempotencyKey);
    return subscribeResult;
  }

  @override
  Future<Either<TryOnFailure, MyTryOnSubscription>> confirmSubscription({
    required String subscriptionId,
    required String idempotencyKey,
  }) async {
    calls.add('confirm:$subscriptionId');
    keys.add(idempotencyKey);
    if (confirmResult.isRight()) access = right(accessOf(hasAccess: true));
    return confirmResult;
  }

  @override
  Future<Either<TryOnFailure, List<MyTryOnSubscription>>>
  mySubscriptions() async => right([subOf(TryOnSubscriptionState.active)]);

  @override
  Future<Either<TryOnFailure, BodyMeasurements?>> getMeasurements() async {
    calls.add('measurements');
    return measurements;
  }

  @override
  Future<Either<TryOnFailure, BodyMeasurements>> saveMeasurements(
    BodyMeasurements m, {
    required String idempotencyKey,
  }) async {
    calls.add('save');
    measurements = right(m);
    return right(m);
  }

  @override
  Future<Either<TryOnFailure, TryOnProduct>> getProduct(
    String productId,
  ) async => left(const TryOnFailure(TryOnFailureKind.noAccess));

  @override
  Future<Either<TryOnFailure, FitRecommendation>> getFit(
    String productId,
  ) async {
    calls.add('fit');
    return fit;
  }

  @override
  Future<Either<TryOnFailure, Unit>> recordSession({
    required String productId,
    required TryOnMode mode,
    required String idempotencyKey,
    String? chosenSize,
  }) async => right(unit);

  @override
  Future<Either<TryOnFailure, SizeChart?>> getPublicSizeChart(
    String productId,
  ) async => right(null);
}
