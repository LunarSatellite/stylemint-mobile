import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/repositories/codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/code_target.dart';

/// A code to open, and how it was opened.
typedef CodeResolveRequest = ({String code, CodeScanVia via});

sealed class CodeResolveState {
  const CodeResolveState();
}

final class CodeResolving extends CodeResolveState {
  const CodeResolving();
}

final class CodeResolved extends CodeResolveState {
  const CodeResolved(this.code, this.target);

  final ResolvedCode code;
  final CodeTarget target;
}

/// Unknown, revoked, malformed, or pointing at nothing this app can show.
final class CodeNotActive extends CodeResolveState {
  const CodeNotActive();
}

final class CodeResolveFailed extends CodeResolveState {
  const CodeResolveFailed(this.failure);

  final NetworkExceptions failure;
}

/// Resolves one opened code (recording the scan) and works out where it
/// leads.
class CodeResolveNotifier extends StateNotifier<CodeResolveState> {
  CodeResolveNotifier(this._repository, CodeResolveRequest request)
    : _code = StyleMintCodeFormat.normalize(request.code),
      _via = request.via,
      super(const CodeResolving()) {
    unawaited(resolve());
  }

  final CodesRepository _repository;
  final String? _code;
  final CodeScanVia _via;
  bool _inFlight = false;

  Future<void> resolve() async {
    final code = _code;
    if (code == null) {
      // Not a code at all: nothing to ask the backend.
      state = const CodeNotActive();
      return;
    }
    if (_inFlight) return;
    _inFlight = true;
    state = const CodeResolving();
    final result = await _repository.resolve(code, _via);
    _inFlight = false;
    if (!mounted) return;
    state = result.fold(
      (failure) => failure.isNotFound
          ? const CodeNotActive()
          : CodeResolveFailed(failure),
      (resolved) {
        final target = codeTargetFor(resolved);
        return target == null
            ? const CodeNotActive()
            : CodeResolved(resolved, target);
      },
    );
  }
}
