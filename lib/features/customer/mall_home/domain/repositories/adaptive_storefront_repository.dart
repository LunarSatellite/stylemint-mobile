import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';

/// The adaptive storefront, as the Mall consumes it.
///
/// Neither method returns an error: personalisation that fails has to be
/// indistinguishable from a customer who simply has no history, or the
/// fallback would not be invisible. [getLayout] answers
/// [StorefrontLayout.none] for anything that goes wrong.
abstract interface class AdaptiveStorefrontRepository {
  Future<StorefrontLayout> getLayout();

  Future<void> trackInteraction(FeedSignal signal);
}
