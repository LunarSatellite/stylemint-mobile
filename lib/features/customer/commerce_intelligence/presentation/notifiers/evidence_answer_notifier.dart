import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/repositories/commerce_intelligence_repository.dart';

@immutable
class EvidenceAnswerState {
  const EvidenceAnswerState({
    this.asking = false,
    this.answer,
    this.error,
    this.askedQuery = '',
  });

  final bool asking;

  /// Null until a question has been answered. An answer that arrived with no
  /// evidence is still held here — the widget decides not to present it as
  /// an answer, rather than the state pretending it never came.
  final EvidenceAnswer? answer;

  final String? error;

  /// The question this state belongs to, echoed back for the header.
  final String askedQuery;

  EvidenceAnswerState copyWith({
    bool? asking,
    EvidenceAnswer? answer,
    String? error,
    String? askedQuery,
    bool clearAnswer = false,
    bool clearError = false,
  }) => EvidenceAnswerState(
    asking: asking ?? this.asking,
    answer: clearAnswer ? null : (answer ?? this.answer),
    error: clearError ? null : (error ?? this.error),
    askedQuery: askedQuery ?? this.askedQuery,
  );
}

/// Asks one question at a time and holds the answer.
///
/// It can ask and it can clear. There is no method here that mutates a cart,
/// an order, a price or stock, and the repository it holds has none either.
class EvidenceAnswerNotifier extends StateNotifier<EvidenceAnswerState> {
  EvidenceAnswerNotifier(this._repository) : super(const EvidenceAnswerState());

  final CommerceIntelligenceRepository _repository;

  /// Monotonic token so a slow first answer cannot overwrite a fast second.
  int _generation = 0;

  Future<bool> ask(String query, {DateTime? asOfUtc}) async {
    final generation = ++_generation;
    state = state.copyWith(
      asking: true,
      askedQuery: query.trim(),
      clearError: true,
      clearAnswer: true,
    );
    final result = await _repository.answer(query: query, asOfUtc: asOfUtc);
    if (!mounted || generation != _generation) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(
          asking: false,
          error: NetworkExceptions.getMessage(failure),
        );
        return false;
      },
      (answer) {
        state = state.copyWith(asking: false, answer: answer);
        return true;
      },
    );
  }

  void clear() {
    _generation++;
    state = const EvidenceAnswerState();
  }
}
