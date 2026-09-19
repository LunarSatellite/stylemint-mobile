import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';

/// Which slice of the seller's own tags a register is showing.
///
/// The product name is carried, never derived. `GET vendor/unit-markers`
/// returns ids and no names, so a register opened without a name shows none
/// rather than inventing one or rendering a raw id at the seller.
typedef UnitMarkerRegisterFilter = ({String? productId, String? productName});

sealed class UnitMarkerRegisterState {
  const UnitMarkerRegisterState();
}

final class UnitMarkerRegisterLoading extends UnitMarkerRegisterState {
  const UnitMarkerRegisterLoading();
}

/// The page came back. **An empty [markers] is this state, not a failure**
/// and not a loading spinner that never ends — a seller who has minted
/// nothing has an empty register, which is a fact worth saying.
final class UnitMarkerRegisterLoaded extends UnitMarkerRegisterState {
  const UnitMarkerRegisterLoaded({
    required this.markers,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.revokingReference,
    this.revokedReference,
    this.revokeFailure,
  });

  final List<UnitMarker> markers;

  /// Straight from the cursor the server sent. Never guessed from the page
  /// being full.
  final bool hasMore;

  final bool isLoadingMore;

  /// A page that failed to append. The rows already on screen stay; only the
  /// tail is missing, and the screen says so rather than blanking.
  final NetworkExceptions? loadMoreFailure;

  /// The tag whose revoke call is in flight, so exactly one row can show it.
  final String? revokingReference;

  /// The tag that was just retired, so the outcome is visible afterwards
  /// rather than only implied by a changed chip.
  final String? revokedReference;

  final NetworkExceptions? revokeFailure;

  bool get isEmpty => markers.isEmpty;

  UnitMarkerRegisterLoaded copyWith({
    List<UnitMarker>? markers,
    bool? hasMore,
    bool? isLoadingMore,
    NetworkExceptions? loadMoreFailure,
    String? revokingReference,
    String? revokedReference,
    NetworkExceptions? revokeFailure,
    bool clearLoadMoreFailure = false,
    bool clearRevoking = false,
    bool clearRevoked = false,
    bool clearRevokeFailure = false,
  }) => UnitMarkerRegisterLoaded(
    markers: markers ?? this.markers,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
    revokingReference: clearRevoking
        ? null
        : (revokingReference ?? this.revokingReference),
    revokedReference: clearRevoked
        ? null
        : (revokedReference ?? this.revokedReference),
    revokeFailure: clearRevokeFailure
        ? null
        : (revokeFailure ?? this.revokeFailure),
  );
}

final class UnitMarkerRegisterFailed extends UnitMarkerRegisterState {
  const UnitMarkerRegisterFailed(this.failure);

  final NetworkExceptions failure;
}

/// The seller's own minted tags, and the one destructive action on them.
///
/// Addresses every tag by its non-secret `UMxxxxxxxxxx` reference. The list
/// route carries no credential and the response shape has no field for one,
/// so there is nothing here to leak.
///
/// §5.9: listing prices nothing and retiring a tag reserves nothing, releases
/// no stock and moves no money. Revoking stops a tag resolving — that is the
/// whole of its effect.
class UnitMarkerRegisterNotifier
    extends StateNotifier<UnitMarkerRegisterState> {
  UnitMarkerRegisterNotifier(this._repository, this.filter)
    : super(const UnitMarkerRegisterLoading()) {
    unawaited(load());
  }

  final UnitMarkersRepository _repository;
  final UnitMarkerRegisterFilter filter;

  static const int pageSize = 20;

  String? _nextCursor;
  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitMarkerRegisterLoading();
    final result = await _repository.listMarkers(
      productId: filter.productId,
      pageSize: pageSize,
    );
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(UnitMarkerRegisterFailed.new, (page) {
      _nextCursor = page.nextCursor;
      return UnitMarkerRegisterLoaded(
        markers: page.items,
        hasMore: page.hasMore,
      );
    });
  }

  /// Appends the next page. A failure here leaves the rows already loaded
  /// alone; losing the tail must not blank a register the seller is reading.
  Future<void> loadMore() async {
    final current = state;
    if (current is! UnitMarkerRegisterLoaded) return;
    if (_inFlight || !current.hasMore) return;
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty) return;

    _inFlight = true;
    state = current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true);
    final result = await _repository.listMarkers(
      productId: filter.productId,
      cursor: cursor,
      pageSize: pageSize,
    );
    _inFlight = false;
    if (!mounted) return;
    final latest = state;
    if (latest is! UnitMarkerRegisterLoaded) return;
    state = result.fold(
      (failure) =>
          latest.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      (page) {
        _nextCursor = page.nextCursor;
        return latest.copyWith(
          markers: [...latest.markers, ...page.items],
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      },
    );
  }

  /// Retires one tag by its reference.
  ///
  /// Irreversible in effect: a revoked tag stops resolving for anyone who
  /// scans it, and there is no un-revoke route. The screen confirms before
  /// calling this; the notifier does not confirm on the screen's behalf.
  ///
  /// The row is replaced with the marker the server returned, so the new
  /// status on screen is the server's answer rather than an optimistic guess.
  Future<void> revoke(String reference) async {
    final current = state;
    if (current is! UnitMarkerRegisterLoaded) return;
    if (current.revokingReference != null) return;

    state = current.copyWith(
      revokingReference: reference,
      clearRevoked: true,
      clearRevokeFailure: true,
    );
    final result = await _repository.revoke(reference);
    if (!mounted) return;
    final latest = state;
    if (latest is! UnitMarkerRegisterLoaded) return;
    state = result.fold(
      (failure) => latest.copyWith(clearRevoking: true, revokeFailure: failure),
      (updated) => latest.copyWith(
        markers: [
          for (final row in latest.markers)
            if (row.reference == updated.reference) updated else row,
        ],
        clearRevoking: true,
        revokedReference: updated.reference,
      ),
    );
  }

  /// Drops the "just retired" banner once the seller has read it.
  void acknowledgeRevoke() {
    final current = state;
    if (current is! UnitMarkerRegisterLoaded) return;
    state = current.copyWith(clearRevoked: true, clearRevokeFailure: true);
  }
}
