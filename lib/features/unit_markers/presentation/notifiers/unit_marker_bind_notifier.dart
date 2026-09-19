import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/unit_marker_format.dart';

/// The order line a packer is tagging, and how far it has travelled.
///
/// The stage comes from the seller's own order screen. It is here so the bind
/// screen can *explain* a closed control before the seller presses it; the
/// backend still decides, and its sentence wins once a call has been made.
typedef BindTarget = ({
  String subOrderLineId,
  OrderLineFulfilmentStage stage,
});

sealed class UnitMarkerBindState {
  const UnitMarkerBindState();
}

final class UnitMarkerBindIdle extends UnitMarkerBindState {
  const UnitMarkerBindIdle();
}

final class UnitMarkerBindInProgress extends UnitMarkerBindState {
  const UnitMarkerBindInProgress();
}

final class UnitMarkerBindSucceeded extends UnitMarkerBindState {
  const UnitMarkerBindSucceeded(this.binding, {required this.wasCorrection});

  final UnitMarkerBinding binding;

  /// True when this row replaced an earlier one. The screen says so, because
  /// "bound" and "corrected" are different things to have done.
  final bool wasCorrection;
}

/// The backend said no, and said why. Not an error state: the sentence is the
/// answer, and for [UnitMarkerBindRefusalKind.alreadyBound] it is also the
/// prompt to record a correction instead.
final class UnitMarkerBindRefusedState extends UnitMarkerBindState {
  const UnitMarkerBindRefusedState(this.refusal);

  final UnitMarkerBindRefusal refusal;
}

/// The marker the seller typed or scanned cannot be a marker at all. Caught
/// here so an obviously malformed value never becomes a request — and never
/// reaches a log on its way to being rejected.
final class UnitMarkerBindMalformed extends UnitMarkerBindState {
  const UnitMarkerBindMalformed();
}

/// A correction was attempted with no reason. The backend requires one and
/// the app does not invent a canned string to satisfy it.
final class UnitMarkerCorrectionNeedsReason extends UnitMarkerBindState {
  const UnitMarkerCorrectionNeedsReason();
}

final class UnitMarkerBindFailed extends UnitMarkerBindState {
  const UnitMarkerBindFailed(this.failure);

  final NetworkExceptions failure;
}

/// Binds the tag in the packer's hand to an order line, and records
/// corrections.
///
/// The cleartext marker passes through [bind] and [correct] as an argument
/// and is handed straight to the repository. It is never stored on this
/// object, never placed in the state, and never written to a route.
class UnitMarkerBindNotifier extends StateNotifier<UnitMarkerBindState> {
  UnitMarkerBindNotifier(this._repository, this.target)
    : super(const UnitMarkerBindIdle());

  final UnitMarkersRepository _repository;
  final BindTarget target;

  /// Matches `UnitMarkerBinding.SupersedeReasonMaxLength`.
  static const int reasonMaxLength = 300;

  bool _inFlight = false;

  /// True while the backend would accept a bind or a correction on this line.
  bool get isOpen => target.stage.allowsBinding;

  /// Why the controls are closed, or null while they are open. Shown in place
  /// of a silently missing button.
  String? get closedReason => target.stage.bindingClosedReason;

  Future<void> bind(String marker, {required UnitBindingStage stage}) async {
    final normalized = UnitMarkerFormat.normalize(marker);
    if (normalized == null) {
      state = const UnitMarkerBindMalformed();
      return;
    }
    await _run(
      () => _repository.bind(
        marker: normalized,
        subOrderLineId: target.subOrderLineId,
        stage: stage,
      ),
      wasCorrection: false,
    );
  }

  /// Records that an existing binding was wrong and what it should have been.
  ///
  /// [reason] is the seller's own words. An empty one is refused here rather
  /// than filled in — the superseded row keeps this sentence forever, and a
  /// canned "corrected by seller" would make the trail worthless.
  Future<void> correct(
    String marker, {
    required UnitBindingStage stage,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      state = const UnitMarkerCorrectionNeedsReason();
      return;
    }
    final normalized = UnitMarkerFormat.normalize(marker);
    if (normalized == null) {
      state = const UnitMarkerBindMalformed();
      return;
    }
    await _run(
      () => _repository.correct(
        marker: normalized,
        subOrderLineId: target.subOrderLineId,
        stage: stage,
        reason: trimmedReason,
      ),
      wasCorrection: true,
    );
  }

  void reset() {
    if (_inFlight) return;
    state = const UnitMarkerBindIdle();
  }

  Future<void> _run(
    Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> Function() call, {
    required bool wasCorrection,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    state = const UnitMarkerBindInProgress();
    final result = await call();
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      UnitMarkerBindFailed.new,
      (outcome) => switch (outcome) {
        UnitMarkerBound(:final binding) => UnitMarkerBindSucceeded(
          binding,
          wasCorrection: wasCorrection,
        ),
        UnitMarkerBindRefused(:final refusal) => UnitMarkerBindRefusedState(
          refusal,
        ),
      },
    );
  }
}
