import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';

/// Cards the viewer marked "Not interested". Changes apply to the screen at
/// once and roll back if the server refuses them.
class NotInterestedNotifier extends StateNotifier<Set<NotInterestedTarget>> {
  NotInterestedNotifier(this._repository) : super(const {});

  final DiscoverRepository _repository;
  final Map<NotInterestedTarget, Future<bool>> _pendingHides = {};

  /// Merges the signals already stored for the account, so listings the
  /// server doesn't filter stay consistent with Home.
  Future<void> loadSaved() async {
    final result = await _repository.getNotInterested();
    if (!mounted) return;
    result.fold((_) {}, (signals) {
      state = {...state, for (final signal in signals) signal.target};
    });
  }

  /// Hides [target] now; true once the server stored it.
  Future<bool> hide(NotInterestedTarget target, {String? reason}) {
    state = {...state, target};
    final pending = _hide(target, reason);
    _pendingHides[target] = pending;
    return pending;
  }

  /// Shows [target] again; waits for its hide to land first so the DELETE
  /// can't overtake the POST. True unless the server refused.
  Future<bool> undo(NotInterestedTarget target) async {
    state = {...state}..remove(target);
    final pending = _pendingHides.remove(target);
    if (pending != null && !await pending) return true;
    final result = await _repository.undoNotInterested(target);
    if (result.isRight()) return true;
    if (mounted) state = {...state, target};
    return false;
  }

  Future<bool> _hide(NotInterestedTarget target, String? reason) async {
    final result = await _repository.markNotInterested(target, reason: reason);
    if (result.isRight()) return true;
    if (mounted) state = {...state}..remove(target);
    return false;
  }
}
