import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';

/// A product in a store (ProductTag), or with no product the store itself
/// (Store code).
typedef VendorCodeTarget = ({String? productId, String storeId});

sealed class VendorCodeState {
  const VendorCodeState();
}

final class VendorCodeLoading extends VendorCodeState {
  const VendorCodeLoading();
}

final class VendorCodeReady extends VendorCodeState {
  const VendorCodeReady(this.code, {this.revoking = false});

  final StyleMintCodeInfo code;

  /// A revoke request is on its way.
  final bool revoking;
}

final class VendorCodeFailed extends VendorCodeState {
  const VendorCodeFailed(this.failure);

  final NetworkExceptions failure;
}

/// Gets (or makes) the code for one [VendorCodeTarget], and revokes it.
class VendorCodeNotifier extends StateNotifier<VendorCodeState> {
  VendorCodeNotifier(this._repository, this.target)
    : super(const VendorCodeLoading()) {
    unawaited(load());
  }

  final VendorCodesRepository _repository;
  final VendorCodeTarget target;

  /// Get-or-create, so after a revoke this makes a fresh code.
  Future<void> load() async {
    state = const VendorCodeLoading();
    final productId = target.productId;
    final result = productId == null
        ? await _repository.createStoreCode(target.storeId)
        : await _repository.createProductTag(
            productId: productId,
            storeId: target.storeId,
          );
    if (!mounted) return;
    state = result.fold(VendorCodeFailed.new, VendorCodeReady.new);
  }

  /// Returns the failure, or null once the revoked code shows.
  Future<NetworkExceptions?> revoke() async {
    final current = state;
    if (current is! VendorCodeReady ||
        current.revoking ||
        !current.code.isActive) {
      return null;
    }
    state = VendorCodeReady(current.code, revoking: true);
    final result = await _repository.revoke(current.code.code);
    if (!mounted) return result.getLeft().toNullable();
    return result.fold(
      (failure) {
        state = VendorCodeReady(current.code);
        return failure;
      },
      (code) {
        state = VendorCodeReady(code);
        return null;
      },
    );
  }
}
