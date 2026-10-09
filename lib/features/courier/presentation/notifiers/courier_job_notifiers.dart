import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';

/// The job screen's two mutations: "Picked up" and "Complete ride".
///
/// The bool is "an action is in flight", which the screen reads to disable
/// its button. Outcomes are returned, not held, for the same reason as
/// `CourierActionsNotifier`: a shared last-result field would show one job
/// another job's error.
class CourierJobActionsNotifier extends StateNotifier<bool> {
  CourierJobActionsNotifier(this._repository) : super(false);

  final CourierRepository _repository;

  Future<Either<NetworkExceptions, CourierJob>> markPickedUp(String hopId) =>
      _run(() => _repository.markJobPickedUp(hopId));

  /// Starts proof of delivery — or, when one is live, returns it; when it
  /// expired, a fresh one. So "Show QR again" and "New code" are this call
  /// too.
  Future<Either<NetworkExceptions, DeliveryProof>> complete(String hopId) =>
      _run(() => _repository.completeJob(hopId));

  Future<Either<NetworkExceptions, T>> _run<T>(
    Future<Either<NetworkExceptions, T>> Function() body,
  ) async {
    state = true;
    try {
      return await body();
    } finally {
      if (mounted) state = false;
    }
  }
}

/// What the rider's QR screen is showing.
///
/// Plain sealed classes, like the vendor's partner sheet: the screen switches
/// on them exhaustively and there is nothing for codegen to add.
sealed class DeliveryProofState {
  const DeliveryProofState();
}

/// Reading the proof, or asking for a new one when [renewing].
final class DeliveryProofLoading extends DeliveryProofState {
  const DeliveryProofLoading({this.renewing = false});

  final bool renewing;
}

/// A live code on screen, waiting for the recipient to scan it.
final class DeliveryProofShowing extends DeliveryProofState {
  const DeliveryProofShowing(this.proof);

  final DeliveryProof proof;
}

/// The recipient confirmed. Terminal.
final class DeliveryProofConfirmed extends DeliveryProofState {
  const DeliveryProofConfirmed(this.proof);

  final DeliveryProof proof;
}

/// The code ran out before anyone scanned it. The rider asks for a new one.
final class DeliveryProofExpired extends DeliveryProofState {
  const DeliveryProofExpired(this.proof);

  final DeliveryProof? proof;
}

/// The proof could not be read or created at all.
final class DeliveryProofFailed extends DeliveryProofState {
  const DeliveryProofFailed(this.failure);

  final NetworkExceptions failure;
}

/// Shows one hop's proof of delivery and watches for the recipient's scan.
///
/// Polls every [pollInterval] while a code is live — the rider is standing at
/// the door, and "it worked" has to land within a breath of the scan — and
/// stops as soon as the answer is final (confirmed or expired) or the screen
/// closes (autoDispose disposes this, and the timer with it).
class DeliveryProofNotifier extends StateNotifier<DeliveryProofState> {
  DeliveryProofNotifier(
    this._repository,
    this.hopId, {
    DeliveryProof? initial,
    this.pollInterval = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       super(const DeliveryProofLoading()) {
    if (initial != null) {
      _apply(initial);
    } else {
      unawaited(load());
    }
  }

  final CourierRepository _repository;
  final String hopId;
  final Duration pollInterval;
  final DateTime Function() _now;

  Timer? _poll;
  bool _polling = false;

  /// Bumped by [renew], so a poll already in flight cannot land afterwards
  /// and put the expired code back over the new one.
  int _generation = 0;

  /// Whether the poll timer is running. Exposed for tests.
  bool get isPolling => _poll?.isActive ?? false;

  Future<void> load() async {
    final generation = ++_generation;
    state = const DeliveryProofLoading();
    final result = await _repository.getProof(hopId);
    if (!mounted || generation != _generation) return;
    result.fold((failure) {
      _stop();
      state = DeliveryProofFailed(failure);
    }, _apply);
  }

  /// "New code": asks the server for a fresh proof.
  Future<void> renew() async {
    final generation = ++_generation;
    _stop();
    state = const DeliveryProofLoading(renewing: true);
    final result = await _repository.completeJob(hopId);
    if (!mounted || generation != _generation) return;
    result.fold((failure) {
      state = DeliveryProofFailed(failure);
    }, _apply);
  }

  /// Called by the screen's countdown when the clock runs out, so the dead
  /// code is replaced by "New code" at once rather than at the next poll.
  void checkExpiry() {
    final current = state;
    if (current is DeliveryProofShowing && current.proof.isExpiredAt(_now())) {
      _stop();
      state = DeliveryProofExpired(current.proof);
    }
  }

  Future<void> _tick() async {
    if (_polling || state is! DeliveryProofShowing) return;
    _polling = true;
    final generation = _generation;
    try {
      final result = await _repository.getProof(hopId);
      if (!mounted || generation != _generation) return;
      // Silent on failure: the code on screen is still valid, and one missed
      // poll is not worth an error in front of the recipient.
      result.fold((_) => checkExpiry(), _apply);
    } finally {
      _polling = false;
    }
  }

  void _apply(DeliveryProof proof) {
    if (proof.status == DeliveryProofStatus.confirmed) {
      _stop();
      state = DeliveryProofConfirmed(proof);
      return;
    }
    if (proof.isExpiredAt(_now())) {
      _stop();
      state = DeliveryProofExpired(proof);
      return;
    }
    state = DeliveryProofShowing(proof);
    _poll ??= Timer.periodic(pollInterval, (_) => unawaited(_tick()));
  }

  void _stop() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
