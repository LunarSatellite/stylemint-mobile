import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';

sealed class EndlessAisleState {
  const EndlessAisleState();
}

final class EndlessAisleLoading extends EndlessAisleState {
  const EndlessAisleLoading();
}

final class EndlessAisleLoaded extends EndlessAisleState {
  const EndlessAisleLoaded(this.aisle);

  final EndlessAisle aisle;
}

/// This code has no aisle to extend: it points at a person rather than at a
/// seller's goods, or it is unknown or revoked. Nothing is drawn — the
/// shopper is already looking at a screen that worked.
final class EndlessAisleUnavailable extends EndlessAisleState {
  const EndlessAisleUnavailable();
}

final class EndlessAisleFailed extends EndlessAisleState {
  const EndlessAisleFailed(this.failure);

  final NetworkExceptions failure;
}

/// The extended assortment behind one scanned code.
///
/// Read-only: `POST {code}/resolve` already counted this scan, and this call
/// deliberately does not count another.
class EndlessAisleNotifier extends StateNotifier<EndlessAisleState> {
  EndlessAisleNotifier(this._repository, this.code)
    : super(const EndlessAisleLoading()) {
    unawaited(load());
  }

  final InStoreRepository _repository;
  final String code;

  Future<void> load() async {
    if (code.trim().isEmpty) {
      state = const EndlessAisleUnavailable();
      return;
    }
    state = const EndlessAisleLoading();
    final result = await _repository.getEndlessAisle(code);
    if (!mounted) return;
    state = result.fold(
      // A 404 is an unknown or revoked code; a 4xx with a body is the
      // backend's "this code points at a profile, not at a seller's goods".
      // Neither deserves a shopper-facing error on a screen that otherwise
      // loaded — there is simply no aisle here.
      (failure) => failure.isNotFound || failure.validationCode != null
          ? const EndlessAisleUnavailable()
          : EndlessAisleFailed(failure),
      (aisle) => aisle.isEmpty
          ? const EndlessAisleUnavailable()
          : EndlessAisleLoaded(aisle),
    );
  }
}
