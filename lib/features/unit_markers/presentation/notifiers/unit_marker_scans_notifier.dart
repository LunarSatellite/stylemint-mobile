import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';

sealed class UnitMarkerScansState {
  const UnitMarkerScansState();
}

final class UnitMarkerScansLoading extends UnitMarkerScansState {
  const UnitMarkerScansLoading();
}

/// The readings came back. An empty [scans] is this state: a tag nobody has
/// scanned has no custody trail, which is a fact and not a failure.
final class UnitMarkerScansLoaded extends UnitMarkerScansState {
  const UnitMarkerScansLoaded(this.scans);

  final List<UnitMarkerScan> scans;

  bool get isEmpty => scans.isEmpty;
}

final class UnitMarkerScansFailed extends UnitMarkerScansState {
  const UnitMarkerScansFailed(this.failure);

  final NetworkExceptions failure;
}

/// `GET vendor/unit-markers/{reference}/scans` — where this tag has been read
/// and when, for the tag's own seller.
///
/// Keyed by the non-secret `UMxxxxxxxxxx` reference.
///
/// **There is no location in this feature.** The only place the platform can
/// state is a registered `VendorStore` whose own StyleMint code the scanner
/// presented alongside the item. No GPS, no IP-derived city, no inference
/// from a nearby store. A reading without that proof carries
/// [UnitScanPlaceKind.notStated] and renders as *no place recorded* — never
/// as a blank, never as a guess.
class UnitMarkerScansNotifier extends StateNotifier<UnitMarkerScansState> {
  UnitMarkerScansNotifier(this._repository, this.reference)
    : super(const UnitMarkerScansLoading()) {
    unawaited(load());
  }

  final UnitMarkersRepository _repository;
  final String reference;

  static const int limit = 50;

  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitMarkerScansLoading();
    final result = await _repository.scanHistory(reference, limit: limit);
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      UnitMarkerScansFailed.new,
      UnitMarkerScansLoaded.new,
    );
  }
}
