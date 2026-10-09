import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';

/// Where "Confirm delivery" stands.
///
/// Plain sealed classes, like the rider's proof-of-delivery states: the
/// screens switch on them exhaustively and there is nothing for codegen to
/// add.
sealed class DeliveryConfirmState {
  const DeliveryConfirmState();
}

/// Nothing sent yet, or the last attempt was cleared to try again.
final class DeliveryConfirmIdle extends DeliveryConfirmState {
  const DeliveryConfirmIdle();
}

final class DeliveryConfirmSubmitting extends DeliveryConfirmState {
  const DeliveryConfirmSubmitting();
}

/// The parcel is Delivered. Terminal.
///
/// [confirmation] is null when the server answered
/// `delivery_proof.already_confirmed` as an error rather than the contract's
/// idempotent 200 — still a success to the buyer, just without the body.
final class DeliveryConfirmDone extends DeliveryConfirmState {
  const DeliveryConfirmDone(this.confirmation);

  final DeliveryConfirmation? confirmation;
}

final class DeliveryConfirmFailed extends DeliveryConfirmState {
  const DeliveryConfirmFailed(this.failure);

  final DeliveryConfirmFailure failure;

  String get message => deliveryConfirmMessage(failure);
}

/// Sends the buyer's confirmation — the rider's scanned QR, or the package
/// number and 6-digit code — and holds the outcome for the screen.
class DeliveryConfirmNotifier extends StateNotifier<DeliveryConfirmState> {
  DeliveryConfirmNotifier(this._repository)
    : super(const DeliveryConfirmIdle());

  final DeliveryConfirmationRepository _repository;

  /// Confirms with the scanned QR link. True once the parcel is Delivered.
  Future<bool> confirmQr(String qrPayload) =>
      _run(() => _repository.confirmByQr(qrPayload.trim()));

  /// Confirms with the typed code. Spaces are dropped from the code ("482
  /// 913" is how the rider's screen shows it) and the package number is
  /// upper-cased, so what the buyer copies off the rider's screen works.
  Future<bool> confirmCode({
    required String packageNumber,
    required String code,
  }) => _run(
    () => _repository.confirmByCode(
      packageNumber: packageNumber.trim().toUpperCase(),
      code: code.replaceAll(RegExp(r'\s'), ''),
    ),
  );

  /// Back to [DeliveryConfirmIdle] after a failure, for another try.
  void reset() {
    if (state is DeliveryConfirmFailed) state = const DeliveryConfirmIdle();
  }

  Future<bool> _run(
    Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> Function()
    send,
  ) async {
    // One confirmation at a time; a second tap while one is in flight, or
    // after the parcel is already delivered, sends nothing.
    if (state is DeliveryConfirmSubmitting || state is DeliveryConfirmDone) {
      return state is DeliveryConfirmDone;
    }
    state = const DeliveryConfirmSubmitting();
    final result = await send();
    if (!mounted) return result.isRight();
    state = result.fold(
      (failure) => failure is DeliveryConfirmAlreadyConfirmed
          // Idempotent by contract: confirmed is confirmed, whoever got
          // there first.
          ? const DeliveryConfirmDone(null)
          : DeliveryConfirmFailed(failure),
      DeliveryConfirmDone.new,
    );
    return state is DeliveryConfirmDone;
  }
}

/// What to tell the buyer when a confirmation fails — what happened and
/// what to do next, never an error code.
String deliveryConfirmMessage(DeliveryConfirmFailure failure) =>
    switch (failure) {
      DeliveryConfirmNotRecipient() =>
        "This parcel isn't for your account. Only the person who placed the "
            "order can confirm it — check you're signed in to that account.",
      DeliveryConfirmExpired() =>
        'That code has expired. Ask the rider to tap "New code", then scan '
            'or type the new one.',
      DeliveryConfirmInvalid() =>
        "That code doesn't match this parcel. Check the package number and "
            "the 6 digits on the rider's screen, or scan their QR instead.",
      DeliveryConfirmTooManyAttempts() =>
        'Too many wrong codes, so confirming is locked for 15 minutes. Try '
            'again after that.',
      DeliveryConfirmAlreadyConfirmed() => 'This parcel is already delivered.',
      DeliveryConfirmOtherFailure(offline: true) =>
        "You're offline. Connect to the internet and try again.",
      DeliveryConfirmOtherFailure(:final message?) => message,
      DeliveryConfirmOtherFailure() =>
        "Couldn't confirm the delivery just now. Please try again.",
    };
