import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';

/// One binding placed in the trail around it.
///
/// A correction is **two** facts, not an edit: the row that was retired keeps
/// its reason, and the row that replaced it points back. Rendering either one
/// alone loses the thing the backend was designed to keep, so the screen is
/// given both neighbours or an explicit null.
typedef BindingTrailEntry = ({
  UnitMarkerBinding binding,

  /// The later row that superseded this one, when it is in the same response.
  /// Null when nothing replaced it — or when the replacement is genuinely not
  /// here, which the screen says rather than papering over.
  UnitMarkerBinding? replacedBy,

  /// The earlier row this one corrected. Null when this row corrected
  /// nothing.
  UnitMarkerBinding? replaces,
});

sealed class UnitMarkerBindingsState {
  const UnitMarkerBindingsState();
}

final class UnitMarkerBindingsLoading extends UnitMarkerBindingsState {
  const UnitMarkerBindingsLoading();
}

/// The history came back. An empty [trail] is this state: a minted tag that
/// no packer has bound yet has no bindings, which is normal and sayable.
final class UnitMarkerBindingsLoaded extends UnitMarkerBindingsState {
  const UnitMarkerBindingsLoaded(this.trail);

  final List<BindingTrailEntry> trail;

  bool get isEmpty => trail.isEmpty;

  /// The binding that still stands, if one does. A tag whose only binding was
  /// superseded and never replaced has none, and the screen must not promote
  /// a retired row into the answer.
  UnitMarkerBinding? get liveBinding {
    for (final entry in trail) {
      if (entry.binding.isLive) return entry.binding;
    }
    return null;
  }
}

final class UnitMarkerBindingsFailed extends UnitMarkerBindingsState {
  const UnitMarkerBindingsFailed(this.failure);

  final NetworkExceptions failure;
}

/// `GET vendor/unit-markers/{reference}/bindings` — every binding this tag
/// has ever carried, corrections included.
///
/// Keyed by the non-secret `UMxxxxxxxxxx` reference, which is what the route
/// takes and what a seller quotes to support.
///
/// The order ids on these rows are the seller's own orders. They stop here:
/// nothing on this path reaches a buyer name, an address, a price or a
/// tracking number, and there is no second call on this screen to go and find
/// them.
class UnitMarkerBindingsNotifier
    extends StateNotifier<UnitMarkerBindingsState> {
  UnitMarkerBindingsNotifier(this._repository, this.reference)
    : super(const UnitMarkerBindingsLoading()) {
    unawaited(load());
  }

  final UnitMarkersRepository _repository;
  final String reference;

  bool _inFlight = false;

  /// Pairs each row with its neighbours in the correction chain.
  ///
  /// The join is over ids already present in the response — nothing is
  /// fetched, inferred from ordering, or matched on a timestamp. A row whose
  /// counterpart is absent gets a null, and the screen renders that absence.
  static List<BindingTrailEntry> buildTrail(List<UnitMarkerBinding> rows) {
    final byId = <String, UnitMarkerBinding>{
      for (final row in rows)
        if (row.id.isNotEmpty) row.id: row,
    };
    // id of a superseded row -> the row that corrected it.
    final replacementOf = <String, UnitMarkerBinding>{
      for (final row in rows)
        if (row.correctsBindingId case final corrected?)
          if (corrected.isNotEmpty) corrected: row,
    };
    return [
      for (final row in rows)
        (
          binding: row,
          replacedBy: replacementOf[row.id],
          replaces: row.correctsBindingId == null
              ? null
              : byId[row.correctsBindingId!],
        ),
    ];
  }

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitMarkerBindingsLoading();
    final result = await _repository.bindingHistory(reference);
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      UnitMarkerBindingsFailed.new,
      (rows) => UnitMarkerBindingsLoaded(buildTrail(rows)),
    );
  }
}
