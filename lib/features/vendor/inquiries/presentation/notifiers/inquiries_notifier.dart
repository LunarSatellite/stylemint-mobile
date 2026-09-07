import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/entities/product_inquiry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';

class InquiriesState {
  const InquiriesState({
    this.isLoading = true,
    this.replyingId,
    this.errorMessage,
    this.items = const [],
  });

  final bool isLoading;
  final String? replyingId;
  final String? errorMessage;
  final List<ProductInquiry> items;

  InquiriesState copyWith({
    bool? isLoading,
    String? replyingId,
    bool clearReplying = false,
    String? errorMessage,
    bool clearError = false,
    List<ProductInquiry>? items,
  }) {
    return InquiriesState(
      isLoading: isLoading ?? this.isLoading,
      replyingId: clearReplying ? null : (replyingId ?? this.replyingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
    );
  }
}

class InquiriesNotifier extends StateNotifier<InquiriesState> {
  InquiriesNotifier(this._repository) : super(const InquiriesState()) {
    unawaited(load());
  }

  final InquiriesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final either = await _repository.listVendor();
    state = either.fold(
      (_) => state.copyWith(
          isLoading: false, errorMessage: 'Could not load inquiries.'),
      (items) => state.copyWith(isLoading: false, items: items),
    );
  }

  Future<bool> reply(String inquiryId, String text) async {
    if (text.trim().isEmpty) return false;
    state = state.copyWith(replyingId: inquiryId, clearError: true);
    final either = await _repository.reply(inquiryId, text.trim());
    return either.fold(
      (_) {
        state = state.copyWith(
            clearReplying: true, errorMessage: 'Could not send your reply.');
        return false;
      },
      (updated) {
        state = state.copyWith(
          clearReplying: true,
          items: [
            for (final i in state.items)
              if (i.id == inquiryId) updated else i,
          ],
        );
        return true;
      },
    );
  }
}
