import 'dart:async';

import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';

/// Tells the server a signed-in viewer opened a product, for the Home
/// "Recently viewed" rail. Fire-and-forget: it never blocks, throws or shows
/// an error.
class RecentlyViewedRecorder {
  const RecentlyViewedRecorder(this._repository);

  final MallHomeRepository _repository;

  void record(String productId) {
    final id = productId.trim();
    if (id.isEmpty) return;
    try {
      unawaited(
        _repository
            .recordRecentlyViewed(id)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    } on Object catch (_) {
      // Best effort only.
    }
  }
}
