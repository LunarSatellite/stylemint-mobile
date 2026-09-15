import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/repositories/codes_repository.dart';

sealed class MyProfileCodeState {
  const MyProfileCodeState();
}

final class MyProfileCodeLoading extends MyProfileCodeState {
  const MyProfileCodeLoading();
}

final class MyProfileCodeReady extends MyProfileCodeState {
  const MyProfileCodeReady(this.code, {this.rotating = false});

  final StyleMintCodeInfo code;

  /// A rotate request is on its way; the current code stays on screen.
  final bool rotating;
}

final class MyProfileCodeFailed extends MyProfileCodeState {
  const MyProfileCodeFailed(this.failure);

  final NetworkExceptions failure;
}

/// The signed-in person's Profile code: loads (get-or-create) and rotates.
class MyProfileCodeNotifier extends StateNotifier<MyProfileCodeState> {
  MyProfileCodeNotifier(this._repository)
    : super(const MyProfileCodeLoading()) {
    unawaited(load());
  }

  final CodesRepository _repository;

  Future<void> load() async {
    state = const MyProfileCodeLoading();
    final result = await _repository.getMyProfileCode();
    if (!mounted) return;
    state = result.fold(MyProfileCodeFailed.new, MyProfileCodeReady.new);
  }

  /// Replaces the code with a new one. Returns the failure, or null once
  /// the new code is showing. On failure the current code stays.
  Future<NetworkExceptions?> rotate() async {
    final current = state;
    if (current is! MyProfileCodeReady || current.rotating) return null;
    state = MyProfileCodeReady(current.code, rotating: true);
    final result = await _repository.rotateMyProfileCode();
    if (!mounted) return result.getLeft().toNullable();
    return result.fold(
      (failure) {
        state = MyProfileCodeReady(current.code);
        return failure;
      },
      (code) {
        state = MyProfileCodeReady(code);
        return null;
      },
    );
  }
}
