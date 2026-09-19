import 'dart:async';

import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';

/// Records that a viewer opened a product, for the Home "Recently viewed"
/// rail — but only when this customer may be personalised.
///
/// **Why this is a personalisation write, not subject access.** The rail
/// looks like the customer's own history handed back to them, and one of its
/// two readers is exactly that. The other is not: the same store is read by
/// the Home service's "Picked for you" section, which takes the categories of
/// recently viewed products, ranks catalogue rows against them and labels the
/// result "Based on what you viewed". One write feeds both, and the write
/// cannot say which reader it is for. A store that trains a recommendation
/// rail is a personalisation input, so the collection is gated with the same
/// purpose as the storefront it feeds: `storefrontPersonalisation`.
///
/// Refusing does not withhold anything the customer is entitled to. Subject
/// access is a right to the data that is held, and the read endpoint still
/// returns every row collected while the purpose was live. This gate stops
/// *new* collection; it does not hide history.
///
/// **The gate sits on the write.** It is checked here, before the repository
/// is touched, not on the widget that draws the rail. A refusal that only
/// stopped the rail rendering would leave the collection running, which is
/// the same defect with a tidier surface.
///
/// Fire-and-forget: it never blocks, throws or shows an error. An unreadable
/// consent answer refuses, exactly as an explicit refusal does.
class RecentlyViewedRecorder {
  const RecentlyViewedRecorder(this._repository, this._personalizer);

  final MallHomeRepository _repository;
  final StorefrontPersonalizer _personalizer;

  void record(String productId) {
    final id = productId.trim();
    if (id.isEmpty) return;
    try {
      unawaited(
        _record(id).then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    } on Object catch (_) {
      // Best effort only.
    }
  }

  /// Asks the gate first. [StorefrontPersonalizer.allowed] already answers no
  /// for a guest, the global pause, a refused, lapsed or never-asked purpose,
  /// a purpose the backend did not report at all, and a decision that could
  /// not be read — so there is no permissive fallback to add here.
  Future<void> _record(String id) async {
    if (!await _personalizer.allowed()) return;
    await _repository.recordRecentlyViewed(id);
  }
}
