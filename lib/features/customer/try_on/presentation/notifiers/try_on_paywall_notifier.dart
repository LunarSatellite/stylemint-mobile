import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_access_notifier.dart';
import 'package:uuid/uuid.dart';

part 'try_on_paywall_notifier.freezed.dart';

/// The paywall's purchase flow:
/// idle → working → (trial) unlocked
/// idle → working → awaitingPayment → confirming → unlocked
@freezed
abstract class TryOnPaywallState with _$TryOnPaywallState {
  const TryOnPaywallState._();

  const factory TryOnPaywallState.idle() = _Idle;
  const factory TryOnPaywallState.working() = _Working;

  /// The subscription exists and the provider's page has to be completed.
  /// The screen opens [redirectUrl] (when there is one) and confirms on
  /// return.
  const factory TryOnPaywallState.awaitingPayment(
    MyTryOnSubscription subscription,
    String? redirectUrl,
  ) = _AwaitingPayment;
  const factory TryOnPaywallState.confirming(MyTryOnSubscription subscription) =
      _Confirming;
  const factory TryOnPaywallState.unlocked(TryOnAccess access) = _Unlocked;

  /// [pending] is kept when the failure came from confirming, so the buyer
  /// can retry the confirm without paying again.
  const factory TryOnPaywallState.failure(
    TryOnFailure failure, {
    MyTryOnSubscription? pending,
  }) = _Failure;

  bool get isBusy => maybeWhen(
    working: () => true,
    confirming: (_) => true,
    orElse: () => false,
  );
}

class TryOnPaywallNotifier extends StateNotifier<TryOnPaywallState> {
  TryOnPaywallNotifier(this._repository, this._access)
    : super(const TryOnPaywallState.idle());

  final TryOnRepository _repository;
  final TryOnAccessNotifier _access;
  static const _uuid = Uuid();

  /// One key per subscription the buyer means to buy: a retry after a
  /// timeout reuses it (the server answers with the same subscription);
  /// picking a different plan or rail is a different purchase.
  String? _subscribeKey;
  String? _subscribeFingerprint;

  /// One key per confirm of one subscription.
  String? _confirmKey;
  String? _confirmFor;

  Future<void> startTrial() async {
    if (state.isBusy) return;
    state = const TryOnPaywallState.working();
    final result = await _repository.startTrial(idempotencyKey: _uuid.v4());
    if (!mounted) return;
    result.fold((f) => state = TryOnPaywallState.failure(f), (access) {
      _access.apply(access);
      state = access.hasAccess
          ? TryOnPaywallState.unlocked(access)
          : const TryOnPaywallState.idle();
    });
  }

  Future<void> subscribe(TryOnPlan plan, TryOnPaymentRail rail) async {
    if (state.isBusy) return;
    final fingerprint = '${plan.id}|${rail.wire}';
    if (fingerprint != _subscribeFingerprint) {
      _subscribeFingerprint = fingerprint;
      _subscribeKey = _uuid.v4();
    }
    state = const TryOnPaywallState.working();
    final result = await _repository.subscribe(
      planId: plan.id,
      rail: rail,
      idempotencyKey: _subscribeKey!,
    );
    if (!mounted) return;
    state = result.fold(
      TryOnPaywallState.failure,
      (start) {
        // A new purchase next time.
        _subscribeFingerprint = null;
        return TryOnPaywallState.awaitingPayment(
          start.subscription,
          start.redirectUrl,
        );
      },
    );
  }

  /// After the provider's page: capture + activate, then refresh access.
  Future<void> confirm(MyTryOnSubscription subscription) async {
    if (state.isBusy) return;
    if (_confirmFor != subscription.id) {
      _confirmFor = subscription.id;
      _confirmKey = _uuid.v4();
    }
    state = TryOnPaywallState.confirming(subscription);
    final result = await _repository.confirmSubscription(
      subscriptionId: subscription.id,
      idempotencyKey: _confirmKey!,
    );
    if (!mounted) return;
    await result.fold(
      (f) async => state = TryOnPaywallState.failure(f, pending: subscription),
      (confirmed) async {
        await _access.refresh();
        if (!mounted) return;
        final access = _access.state.accessOrNull;
        if (confirmed.state == TryOnSubscriptionState.active &&
            access != null &&
            access.hasAccess) {
          state = TryOnPaywallState.unlocked(access);
        } else {
          state = TryOnPaywallState.failure(
            const TryOnFailure(
              TryOnFailureKind.rejected,
              code: 'payment.not_completed',
              message:
                  'We could not confirm the payment yet. If you paid, tap '
                  '"I have paid" again in a moment.',
            ),
            pending: confirmed,
          );
        }
      },
    );
  }

  void dismissFailure() => state = const TryOnPaywallState.idle();
}
