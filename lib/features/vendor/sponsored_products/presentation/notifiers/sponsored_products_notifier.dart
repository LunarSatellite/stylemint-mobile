import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';

sealed class SponsoredProductsState {
  const SponsoredProductsState();
}

final class SponsoredProductsLoading extends SponsoredProductsState {
  const SponsoredProductsLoading();
}

final class SponsoredProductsLoaded extends SponsoredProductsState {
  const SponsoredProductsLoaded(
    this.listings, {
    this.pausing = const <String>{},
  });

  final List<SponsoredListing> listings;

  /// Product ids with a pause request on its way.
  final Set<String> pausing;

  bool get isEmpty => listings.isEmpty;
}

final class SponsoredProductsFailed extends SponsoredProductsState {
  const SponsoredProductsFailed(this.failure);

  final NetworkExceptions failure;
}

/// Loads the vendor's sponsorships and starts, changes, restarts or pauses
/// them.
class SponsoredProductsNotifier extends StateNotifier<SponsoredProductsState> {
  SponsoredProductsNotifier(this._repository)
    : super(const SponsoredProductsLoading()) {
    unawaited(load());
  }

  final SponsoredProductsRepository _repository;
  int _requestSeq = 0;

  /// Shows the page loader, then the list or a retryable error.
  Future<void> load() => _fetch(showLoader: true);

  /// Re-checks the list while keeping the current one on screen. If the
  /// re-check fails, the list already shown stays.
  Future<void> refresh() => _fetch(showLoader: false);

  Future<void> _fetch({required bool showLoader}) async {
    final seq = ++_requestSeq;
    if (showLoader || state is! SponsoredProductsLoaded) {
      state = const SponsoredProductsLoading();
    }
    final result = await _repository.getSponsoredListings();
    // A newer load started meanwhile; its answer wins.
    if (!mounted || seq != _requestSeq) return;
    final current = state;
    state = result.fold(
      (failure) => current is SponsoredProductsLoaded && !showLoader
          ? current
          : SponsoredProductsFailed(failure),
      (listings) => SponsoredProductsLoaded(
        listings,
        pausing: current is SponsoredProductsLoaded
            ? current.pausing
            : const <String>{},
      ),
    );
  }

  /// Pauses a sponsorship. The card switches to Paused from the backend's
  /// answer; returns the failure, or null on success.
  Future<NetworkExceptions?> pause(String productId) async {
    final before = state;
    if (before is SponsoredProductsLoaded) {
      if (before.pausing.contains(productId)) return null;
      state = SponsoredProductsLoaded(
        before.listings,
        pausing: {...before.pausing, productId},
      );
    }

    final result = await _repository.pause(productId);
    if (!mounted) return result.getLeft().toNullable();

    _setPausing(productId, pausing: false);
    return result.fold(
      (failure) {
        _refreshIfStale(failure);
        return failure;
      },
      (listing) {
        _upsert(listing);
        return null;
      },
    );
  }

  /// Starts, changes or restarts a sponsorship. On success the list shows
  /// the saved sponsorship straight away and then re-checks itself; if no
  /// list was on screen (still loading, or the load had failed) it loads
  /// afresh instead, so a single saved card never stands in for the list.
  Future<Either<NetworkExceptions, SponsoredListing>> sponsor({
    required String productId,
    required int dailyImpressionCap,
    DateTime? endsUtc,
  }) async {
    final result = await _repository.sponsor(
      productId: productId,
      dailyImpressionCap: dailyImpressionCap,
      endsUtc: endsUtc,
    );
    if (!mounted) return result;
    result.fold(_refreshIfStale, (listing) {
      if (state is SponsoredProductsLoaded) {
        _upsert(listing);
        unawaited(refresh());
      } else {
        unawaited(load());
      }
    });
    return result;
  }

  /// A 404 or 409 means the list on screen is out of date.
  void _refreshIfStale(NetworkExceptions failure) {
    if (failure.isNotFound || isSponsorshipConflict(failure)) {
      unawaited(refresh());
    }
  }

  void _upsert(SponsoredListing listing) {
    final current = state;
    if (current is! SponsoredProductsLoaded) {
      state = SponsoredProductsLoaded([listing]);
      return;
    }
    final index = current.listings.indexWhere(
      (l) => l.productId == listing.productId,
    );
    final listings = index < 0
        ? [listing, ...current.listings]
        : [
            for (var i = 0; i < current.listings.length; i++)
              i == index ? listing : current.listings[i],
          ];
    state = SponsoredProductsLoaded(listings, pausing: current.pausing);
  }

  void _setPausing(String productId, {required bool pausing}) {
    final current = state;
    if (current is! SponsoredProductsLoaded) return;
    final ids = {...current.pausing};
    if (pausing) {
      ids.add(productId);
    } else {
      ids.remove(productId);
    }
    state = SponsoredProductsLoaded(current.listings, pausing: ids);
  }
}
