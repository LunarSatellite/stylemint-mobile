import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';

sealed class UnitPassportState {
  const UnitPassportState();
}

final class UnitPassportLoading extends UnitPassportState {
  const UnitPassportLoading();
}

final class UnitPassportLoaded extends UnitPassportState {
  const UnitPassportLoaded(this.passport);

  final ProductPassport passport;
}

/// The tag is real but carries no live binding, so there is no unit passport
/// to show.
///
/// This is the 404 the passport endpoint answers with, and it is a fact, not
/// a failure: the endpoint re-checks the binding on every read, so a marker
/// nobody bound — or an id somebody guessed — lands here. The screen says
/// "this tag is not bound to a sale" and stops. It does not show an error, it
/// does not show an empty passport, and it does not go looking for another
/// endpoint to fill the space.
final class UnitPassportNotBound extends UnitPassportState {
  const UnitPassportNotBound();
}

final class UnitPassportFailed extends UnitPassportState {
  const UnitPassportFailed(this.failure);

  final NetworkExceptions failure;
}

/// Fetches `GET v1/public/unit-passports/{unitMarkerId}`.
///
/// Keyed by the **opaque marker id**, never by the marker secret. The id is
/// not a credential: the endpoint proves nothing from it and a guessed one is
/// simply unbound, which is why it is safe in a route and the secret is not.
class UnitPassportNotifier extends StateNotifier<UnitPassportState> {
  UnitPassportNotifier(this._repository, this.unitMarkerId)
    : super(const UnitPassportLoading()) {
    unawaited(load());
  }

  final UnitMarkersRepository _repository;
  final String unitMarkerId;

  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitPassportLoading();
    final result = await _repository.unitPassport(unitMarkerId);
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      UnitPassportFailed.new,
      (found) => switch (found) {
        UnitPassportFound(:final passport) => UnitPassportLoaded(passport),
        UnitPassportUnbound() => const UnitPassportNotBound(),
      },
    );
  }
}
