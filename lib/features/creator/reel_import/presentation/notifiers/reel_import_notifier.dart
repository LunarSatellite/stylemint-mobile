import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'reel_import_notifier.freezed.dart';

@freezed
abstract class ReelImportState with _$ReelImportState {
  const ReelImportState._();

  const factory ReelImportState.initial() = _ReelImportInitial;
  const factory ReelImportState.loadInProgress() = _ReelImportLoadInProgress;

  /// [freshness] says whether [reels] are the saved copy and why the provider
  /// was not read live. [refreshBlockedUntil] is set when a pull to refresh
  /// was skipped because the provider asked us to wait; [refreshFailure] when
  /// a refresh failed but the current list was kept. Both clear on the next
  /// refresh attempt.
  const factory ReelImportState.loadSuccess(
    List<ImportableReel> reels, {
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(ContentFreshness()) ContentFreshness freshness,
    DateTime? refreshBlockedUntil,
    NetworkExceptions? refreshFailure,
  }) = _ReelImportLoadSuccess;
  const factory ReelImportState.loadFailure(NetworkExceptions failure) =
      _ReelImportLoadFailure;
}

@freezed
abstract class ImportHistoryState with _$ImportHistoryState {
  const ImportHistoryState._();

  const factory ImportHistoryState.initial() = _ImportHistoryInitial;
  const factory ImportHistoryState.loadInProgress() =
      _ImportHistoryLoadInProgress;
  const factory ImportHistoryState.loadSuccess(
    List<ImportedReel> reels,
  ) = _ImportHistoryLoadSuccess;
  const factory ImportHistoryState.loadFailure(NetworkExceptions failure) =
      _ImportHistoryLoadFailure;
}

@freezed
abstract class ProductSearchState with _$ProductSearchState {
  const ProductSearchState._();

  const factory ProductSearchState.initial() = _ProductSearchInitial;
  const factory ProductSearchState.loadInProgress() =
      _ProductSearchLoadInProgress;
  const factory ProductSearchState.loadSuccess(
    List<TaggedProductForImport> products,
  ) = _ProductSearchLoadSuccess;
  const factory ProductSearchState.loadFailure(NetworkExceptions failure) =
      _ProductSearchLoadFailure;
}

class ReelImportNotifier extends StateNotifier<ReelImportState> {
  ReelImportNotifier(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const ReelImportState.initial());

  final ReelImportRepository _repository;
  final DateTime Function() _clock;

  String? _cursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  SocialPlatform? _platform;
  List<ImportableReel> _reels = const [];
  ContentFreshness _freshness = const ContentFreshness();

  /// Bumped whenever the list is replaced (platform load or refresh) so a
  /// response for a list that is no longer shown is dropped instead of
  /// overwriting or being appended to the new one.
  int _generation = 0;

  /// Loads the first page for [platform], replacing whatever is shown.
  /// [refresh] asks the backend for a live read instead of saved posts.
  Future<void> load(SocialPlatform platform, {bool refresh = false}) async {
    final generation = ++_generation;
    _platform = platform;
    _cursor = null;
    _hasMore = false;
    _isLoadingMore = false;
    _reels = const [];
    _freshness = const ContentFreshness();
    state = const ReelImportState.loadInProgress();
    final either = await _repository.getImportableReels(
      platform,
      refresh: refresh,
    );
    if (generation != _generation) return;
    state = either.fold(
      ReelImportState.loadFailure,
      (page) {
        _applyFirstPage(page);
        return _success();
      },
    );
  }

  /// Pull to refresh: asks for a live first page and swaps it in, keeping
  /// the current list on screen meanwhile.
  ///
  /// When the last page said the provider must not be called before
  /// `retryAfterUtc`, nothing is fetched: the list stays and the state
  /// carries [ReelImportState.loadSuccess] `refreshBlockedUntil`. A failed
  /// refresh keeps the list and reports `refreshFailure`, except a lost
  /// connection (not found), which shows the not-connected state.
  /// Without a list on screen this is a plain [load] with `refresh`.
  Future<void> refresh() async {
    final platform = _platform;
    if (platform == null || _isRefreshing) return;

    final hasList = state.maybeWhen(
      loadSuccess: (_, _, _, _, _, _) => true,
      orElse: () => false,
    );
    if (!hasList) {
      await load(platform, refresh: true);
      return;
    }

    // Clear any earlier notice first so a repeated pull reports again.
    state = _success();
    if (_freshness.isRefreshBlockedAt(_clock())) {
      state = _success(
        refreshBlockedUntil: _freshness.providerStatus?.retryAfterUtc,
      );
      return;
    }

    final generation = ++_generation;
    _isRefreshing = true;
    _isLoadingMore = false;
    state = _success();
    final either = await _repository.getImportableReels(
      platform,
      refresh: true,
    );
    _isRefreshing = false;
    if (generation != _generation) return;

    state = either.fold(
      (failure) {
        if (failure.isNotFound) {
          _reels = const [];
          _cursor = null;
          _hasMore = false;
          _freshness = const ContentFreshness();
          return ReelImportState.loadFailure(failure);
        }
        _noteProviderProblem(failure);
        return _success(refreshFailure: failure);
      },
      (page) {
        _applyFirstPage(page);
        return _success();
      },
    );
  }

  /// Fetches the next page (a provider cursor or a saved-posts `sm1.` cursor,
  /// both opaque) and appends its (possibly zero, if that page was all
  /// non-video posts) importable reels to what's already shown. No-ops if
  /// there's no known next page or a fetch/refresh is already in flight.
  Future<void> loadMore() async {
    final platform = _platform;
    if (platform == null || !_hasMore || _isLoadingMore || _isRefreshing) {
      return;
    }

    final generation = _generation;
    _isLoadingMore = true;
    state = _success();

    final either = await _repository.getImportableReels(
      platform,
      cursor: _cursor,
    );
    if (generation != _generation) return;
    _isLoadingMore = false;
    state = either.fold(
      (failure) {
        // A live listing cannot continue from saved posts, so a throttled
        // provider fails the next page. Keep what is shown and say why.
        _noteProviderProblem(failure);
        return _success();
      },
      (page) {
        _reels = [..._reels, ...page.reels];
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
        _freshness = page.freshness;
        return _success();
      },
    );
  }

  void _applyFirstPage(ImportableReelsResult page) {
    _reels = page.reels;
    _cursor = page.nextCursor;
    _hasMore = page.nextCursor != null;
    _isLoadingMore = false;
    _freshness = page.freshness;
  }

  /// Records a provider problem from an error body on the current freshness
  /// so the banner can explain it; other failures leave it unchanged.
  void _noteProviderProblem(NetworkExceptions failure) {
    final code = failure.validationCode;
    final issue = ContentProviderIssue.fromCode(code);
    if (code == null ||
        issue == null ||
        issue == ContentProviderIssue.notConnected) {
      return;
    }
    _freshness = _freshness.withProviderStatus(
      ContentProviderStatus(
        code: code,
        message: NetworkExceptions.getMessage(failure),
      ),
    );
  }

  ReelImportState _success({
    DateTime? refreshBlockedUntil,
    NetworkExceptions? refreshFailure,
  }) => ReelImportState.loadSuccess(
    _reels,
    hasMore: _hasMore,
    isLoadingMore: _isLoadingMore,
    freshness: _freshness,
    refreshBlockedUntil: refreshBlockedUntil,
    refreshFailure: refreshFailure,
  );
}

class ImportHistoryNotifier extends StateNotifier<ImportHistoryState> {
  ImportHistoryNotifier(this._repository)
    : super(const ImportHistoryState.initial()) {
    unawaited(load());
  }

  final ReelImportRepository _repository;

  Future<void> load({int pageSize = 20, String? cursor}) async {
    state = const ImportHistoryState.loadInProgress();
    final either = await _repository.getImportHistory(
      pageSize: pageSize,
      cursor: cursor,
    );
    state = either.fold(
      ImportHistoryState.loadFailure,
      ImportHistoryState.loadSuccess,
    );
  }
}

class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  ProductSearchNotifier(this._repository)
    : super(const ProductSearchState.initial());

  final ReelImportRepository _repository;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const ProductSearchState.loadSuccess([]);
      return;
    }
    state = const ProductSearchState.loadInProgress();
    final either = await _repository.searchProducts(query.trim());
    state = either.fold(
      ProductSearchState.loadFailure,
      ProductSearchState.loadSuccess,
    );
  }
}

/// Loads and owns the suggested-products list for the currently imported
/// reel. Kept fully separate from [ProductSearchNotifier] so the search
sealed class SuggestedProductsState {
  const SuggestedProductsState();
}

class SuggestedProductsInitial extends SuggestedProductsState {
  const SuggestedProductsInitial();
}

class SuggestedProductsLoadInProgress extends SuggestedProductsState {
  const SuggestedProductsLoadInProgress();
}

class SuggestedProductsLoadSuccess extends SuggestedProductsState {
  const SuggestedProductsLoadSuccess(this.products);
  final List<TaggedProductForImport> products;
}

class SuggestedProductsLoadFailure extends SuggestedProductsState {
  const SuggestedProductsLoadFailure(this.failure);
  final NetworkExceptions failure;
}

class SuggestedProductsNotifier extends StateNotifier<SuggestedProductsState> {
  SuggestedProductsNotifier(this._repository)
    : super(const SuggestedProductsInitial());

  final ReelImportRepository _repository;

  Future<void> loadSuggestions({
    required SocialPlatform platform,
    required String externalId,
  }) async {
    state = const SuggestedProductsLoadInProgress();
    final either = await _repository.getSuggestedProducts(
      platform: platform,
      externalId: externalId,
    );
    state = either.fold(
      SuggestedProductsLoadFailure.new,
      (products) => SuggestedProductsLoadSuccess(products),
    );
  }
}

// ── Submit state (plain sealed — no codegen required) ────────────────────────

sealed class ReelSubmitState {}

class ReelSubmitIdle extends ReelSubmitState {}

class ReelSubmitInProgress extends ReelSubmitState {}

class ReelSubmitSuccess extends ReelSubmitState {
  ReelSubmitSuccess(this.reelId);

  /// The backend-generated reel UUID (not the external platform post ID).
  /// May be null if the reel was already imported previously (409 conflict),
  /// since that response doesn't carry the existing reel's ID.
  final String? reelId;
}

class ReelSubmitFailure extends ReelSubmitState {
  ReelSubmitFailure(this.message);
  final String message;
}

class ReelSubmitNotifier extends StateNotifier<ReelSubmitState> {
  ReelSubmitNotifier(this._repository) : super(ReelSubmitIdle());

  final ReelImportRepository _repository;

  /// [caption] is the StyleMint caption composed on the Review screen; it is
  /// what the import request stores (the platform caption is only a seed).
  Future<void> submit(
    ImportableReel reel,
    List<TaggedProductForImport> taggedProducts, {
    String? caption,
  }) async {
    state = ReelSubmitInProgress();

    final importResult = await _repository.importReel(reel, caption: caption);
    if (importResult.isLeft()) {
      final failure = importResult.getLeft().toNullable()!;
      // 409 means this reel was already imported — treat as success
      final alreadyImported = failure.maybeWhen(
        conflict: () => true,
        orElse: () => false,
      );
      if (alreadyImported) {
        state = ReelSubmitSuccess(null);
        return;
      }
      state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
      return;
    }
    final importedReel = importResult.getRight().toNullable()!;

    for (final product in taggedProducts) {
      final tagResult = await _repository.tagProduct(
        reelId: importedReel.id,
        productId: product.productId,
      );
      if (tagResult.isLeft()) {
        final failure = tagResult.getLeft().toNullable()!;
        state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
        return;
      }
    }

    final publishResult = await _repository.publishReel(
      reelId: importedReel.id,
    );
    if (publishResult.isLeft()) {
      final failure = publishResult.getLeft().toNullable()!;
      state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
      return;
    }

    state = ReelSubmitSuccess(importedReel.id);
  }
}

sealed class BulkImportState {}

class BulkImportIdle extends BulkImportState {}

class BulkImportInProgress extends BulkImportState {}

class BulkImportSuccess extends BulkImportState {
  BulkImportSuccess(this.result);
  final BulkImportResult result;
}

class BulkImportFailure extends BulkImportState {
  BulkImportFailure(this.message);
  final String message;
}

class BulkImportNotifier extends StateNotifier<BulkImportState> {
  BulkImportNotifier(this._repository) : super(BulkImportIdle());
  final ReelImportRepository _repository;

  Future<void> submit(List<ImportableReel> reels) async {
    if (reels.isEmpty) return;
    state = BulkImportInProgress();
    final either = await _repository.importBulk(reels);
    state = either.fold(
      (failure) => BulkImportFailure(NetworkExceptions.getMessage(failure)),
      BulkImportSuccess.new,
    );
  }

  void reset() => state = BulkImportIdle();
}

sealed class ReelIntentNotifierState {}

class ReelIntentNotifierIdle extends ReelIntentNotifierState {}

class ReelIntentNotifierInProgress extends ReelIntentNotifierState {}

class ReelIntentNotifierLaunched extends ReelIntentNotifierState {
  ReelIntentNotifierLaunched(this.intent);
  final ReelIntent intent;
}

class ReelIntentNotifierCompleted extends ReelIntentNotifierState {
  ReelIntentNotifierCompleted(this.intent);
  final ReelIntent intent;
}

class ReelIntentNotifierFailure extends ReelIntentNotifierState {
  ReelIntentNotifierFailure(this.message);
  final String message;
}

class ReelIntentNotifier extends StateNotifier<ReelIntentNotifierState> {
  ReelIntentNotifier(this._repository) : super(ReelIntentNotifierIdle());
  final ReelImportRepository _repository;

  Future<void> launch(SocialPlatform platform) async {
    state = ReelIntentNotifierInProgress();
    final either = await _repository.launchReelIntent(platform);
    state = either.fold(
      (failure) =>
          ReelIntentNotifierFailure(NetworkExceptions.getMessage(failure)),
      ReelIntentNotifierLaunched.new,
    );
  }

  Future<void> complete({
    required String intentId,
    required String resultingReelId,
  }) async {
    state = ReelIntentNotifierInProgress();
    final either = await _repository.completeReelIntent(
      intentId: intentId,
      resultingReelId: resultingReelId,
    );
    state = either.fold(
      (failure) =>
          ReelIntentNotifierFailure(NetworkExceptions.getMessage(failure)),
      ReelIntentNotifierCompleted.new,
    );
  }

  void reset() => state = ReelIntentNotifierIdle();
}
