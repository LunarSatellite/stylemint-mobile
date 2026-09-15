import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/repositories/brand_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';

/// The hero of a brand's storefront.
sealed class BrandStorefrontState {
  const BrandStorefrontState();
}

final class BrandStorefrontLoading extends BrandStorefrontState {
  const BrandStorefrontLoading();
}

/// Unknown brand, or not approved.
final class BrandStorefrontNotFound extends BrandStorefrontState {
  const BrandStorefrontNotFound();
}

final class BrandStorefrontFailure extends BrandStorefrontState {
  const BrandStorefrontFailure(this.failure);

  final NetworkExceptions failure;
}

final class BrandStorefrontLoaded extends BrandStorefrontState {
  const BrandStorefrontLoaded({required this.brand});

  final PublicBrandProfile brand;
}

/// Loads a brand's public profile and, alongside, whether the viewer
/// follows it (seeds the follow button; a failure there is ignored).
class BrandStorefrontNotifier extends StateNotifier<BrandStorefrontState> {
  BrandStorefrontNotifier(
    this._repository,
    this._storefront, {
    required this.vendorAccountId,
    this.onFollowSummary,
  }) : super(const BrandStorefrontLoading()) {
    unawaited(load());
  }

  final BrandStorefrontRepository _repository;
  final StorefrontRepository _storefront;
  final String vendorAccountId;
  final void Function(StorefrontFollowSummary summary)? onFollowSummary;

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    state = const BrandStorefrontLoading();
    final brandCall = _repository.getBrand(vendorAccountId);
    final followCall = _storefront.getFollowSummary(vendorAccountId);
    final brand = await brandCall;
    final follow = await followCall;
    if (!mounted || generation != _generation) return;

    final next = brand.fold<BrandStorefrontState>(
      (failure) => failure.isNotFound
          ? const BrandStorefrontNotFound()
          : BrandStorefrontFailure(failure),
      (value) => BrandStorefrontLoaded(brand: value),
    );
    state = next;
    if (next is BrandStorefrontLoaded) {
      follow.fold((_) {}, (summary) => onFollowSummary?.call(summary));
    }
  }
}
