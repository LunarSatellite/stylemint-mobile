import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';

/// Where a print run has got to.
///
/// [UnitMarkersRevealed] is the **only** state that holds cleartext secrets,
/// and it holds them in memory for as long as the reveal screen is mounted
/// and not one moment longer. The notifier is registered `autoDispose`, and
/// `UnitMarkerProvisionNotifier.discardSecrets` drops them the instant the
/// seller says they have the tags out of the app.
sealed class UnitMarkerProvisionState {
  const UnitMarkerProvisionState();
}

final class UnitMarkerProvisionIdle extends UnitMarkerProvisionState {
  const UnitMarkerProvisionIdle();
}

final class UnitMarkerProvisioning extends UnitMarkerProvisionState {
  const UnitMarkerProvisioning();
}

/// The one-time reveal. Once this state is replaced the secrets are gone —
/// the platform stored only their SHA-256 digests and cannot return them
/// again.
final class UnitMarkersRevealed extends UnitMarkerProvisionState {
  const UnitMarkersRevealed(this.markers);

  final List<ProvisionedUnitMarker> markers;

  /// Deliberately does not name the secrets.
  @override
  String toString() => 'UnitMarkersRevealed(${markers.length} markers)';
}

/// The seller confirmed they have the tags. The references are kept so the
/// screen can still show which tags were minted; the secrets are gone.
final class UnitMarkerSecretsDiscarded extends UnitMarkerProvisionState {
  const UnitMarkerSecretsDiscarded(this.markers);

  final List<UnitMarker> markers;
}

final class UnitMarkerProvisionFailed extends UnitMarkerProvisionState {
  const UnitMarkerProvisionFailed(this.failure);

  final NetworkExceptions failure;
}

/// Mints a print run of tags for one variant.
///
/// §5.9: this prices nothing, reserves nothing and moves no money. Quantity
/// is how many labels to print.
class UnitMarkerProvisionNotifier
    extends StateNotifier<UnitMarkerProvisionState> {
  UnitMarkerProvisionNotifier(this._repository)
    : super(const UnitMarkerProvisionIdle());

  final UnitMarkersRepository _repository;

  /// Matches `UnitMarkerService.MaxProvisionQuantity`.
  static const int maxQuantity = 50;
  static const int minQuantity = 1;

  bool _inFlight = false;

  Future<void> provision({
    required String productVariantId,
    required int quantity,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitMarkerProvisioning();
    final result = await _repository.provision(
      productVariantId: productVariantId,
      quantity: quantity,
    );
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      UnitMarkerProvisionFailed.new,
      UnitMarkersRevealed.new,
    );
  }

  /// Drops every cleartext secret from memory, keeping the references so the
  /// screen can still say which tags were minted.
  ///
  /// Called when the seller confirms they have the tags out of the app. It is
  /// the explicit path; leaving the screen is the implicit one — the provider
  /// is `autoDispose`, so the notifier and the state holding the secrets both
  /// become unreachable the moment the route is popped. Nothing writes a
  /// secret to storage, so there is nothing left behind to erase.
  void discardSecrets() {
    final current = state;
    if (current is! UnitMarkersRevealed) return;
    state = UnitMarkerSecretsDiscarded(
      current.markers
          .map((marker) => marker.withoutSecret)
          .toList(growable: false),
    );
  }
}
