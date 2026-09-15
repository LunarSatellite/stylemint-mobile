import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_review_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';

/// Review summary above the product page's review tabs. Null (block hidden)
/// when it cannot be loaded; it never blocks the page.
final FutureProviderFamily<ProductReviewSummary?, String>
productReviewSummaryProvider = FutureProvider.autoDispose
    .family<ProductReviewSummary?, String>((ref, productId) async {
      try {
        return await ref
            .watch(discoveryRemoteDataSourceProvider)
            .getReviewSummary(productId);
      } on Object catch (_) {
        return null;
      }
    });
