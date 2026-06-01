import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/datasources/inquiries_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/models/product_inquiry_dto.dart';

class InquiriesState {
  const InquiriesState({
    this.isLoading = true,
    this.replyingId,
    this.errorMessage,
    this.items = const [],
  });

  final bool isLoading;
  final String? replyingId; // id currently being replied to
  final String? errorMessage;
  final List<ProductInquiryDto> items;

  InquiriesState copyWith({
    bool? isLoading,
    String? replyingId,
    bool clearReplying = false,
    String? errorMessage,
    bool clearError = false,
    List<ProductInquiryDto>? items,
  }) {
    return InquiriesState(
      isLoading: isLoading ?? this.isLoading,
      replyingId: clearReplying ? null : (replyingId ?? this.replyingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
    );
  }
}

class InquiriesController extends StateNotifier<InquiriesState> {
  InquiriesController(this._ds) : super(const InquiriesState()) {
    load();
  }

  final InquiriesRemoteDataSource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ds.listVendor();
      state = state.copyWith(isLoading: false, items: items);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Could not load inquiries.');
    }
  }

  Future<bool> reply(String inquiryId, String text) async {
    if (text.trim().isEmpty) return false;
    state = state.copyWith(replyingId: inquiryId, clearError: true);
    try {
      final updated = await _ds.reply(inquiryId, text.trim());
      state = state.copyWith(
        clearReplying: true,
        items: [
          for (final i in state.items) if (i.id == inquiryId) updated else i,
        ],
      );
      return true;
    } catch (_) {
      state = state.copyWith(
          clearReplying: true, errorMessage: 'Could not send your reply.');
      return false;
    }
  }
}

final _inquiriesDataSourceProvider = Provider<InquiriesRemoteDataSource>(
  (ref) => InquiriesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final inquiriesControllerProvider =
    StateNotifierProvider.autoDispose<InquiriesController, InquiriesState>(
  (ref) => InquiriesController(ref.watch(_inquiriesDataSourceProvider)),
);
