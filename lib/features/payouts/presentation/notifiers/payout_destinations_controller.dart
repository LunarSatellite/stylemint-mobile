import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/datasources/payout_destinations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';

/// Plain (no-codegen) state for the saved payout destinations screen.
class PayoutDestinationsState {
  const PayoutDestinationsState({
    this.isLoading = true,
    this.isMutating = false,
    this.errorMessage,
    this.loadFailed = false,
    this.items = const [],
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;

  /// The last list read failed: the screen must not say "none".
  final bool loadFailed;
  final List<PayoutDestinationDto> items;

  PayoutDestinationsState copyWith({
    bool? isLoading,
    bool? isMutating,
    bool? loadFailed,
    String? errorMessage,
    bool clearError = false,
    List<PayoutDestinationDto>? items,
  }) {
    return PayoutDestinationsState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadFailed: loadFailed ?? this.loadFailed,
      items: items ?? this.items,
    );
  }
}

class PayoutDestinationsController
    extends StateNotifier<PayoutDestinationsState> {
  PayoutDestinationsController(this._ds, this._role)
    : super(const PayoutDestinationsState()) {
    load();
  }

  final PayoutDestinationsRemoteDataSource _ds;
  final int _role;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ds.list(_role);
      state = state.copyWith(isLoading: false, items: items, loadFailed: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load payment methods.',
        loadFailed: true,
      );
    }
  }

  Future<bool> add({
    required int kind,
    required String label,
    required String accountIdentifier,
    String? branchOrIfsc,
    bool makeDefault = false,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ds.create(
        role: _role,
        kind: kind,
        label: label,
        accountIdentifier: accountIdentifier,
        branchOrIfsc: branchOrIfsc,
        makeDefault: makeDefault,
      );
      await load();
      state = state.copyWith(isMutating: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: 'Could not add this payment method.',
      );
      return false;
    }
  }

  Future<void> makeDefault(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ds.setDefault(id);
      await load();
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: 'Could not set default.',
      );
    }
    state = state.copyWith(isMutating: false);
  }

  Future<void> remove(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ds.remove(id);
      await load();
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: 'Could not remove this method.',
      );
    }
    state = state.copyWith(isMutating: false);
  }
}
