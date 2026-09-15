import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';

/// Finds the SKU to save for a product when the caller has none (a card only
/// knows the product): the product's default variant, or null.
typedef DefaultVariantResolver = Future<String?> Function(String productId);

/// The viewer's saved products, as every save heart sees them.
@immutable
class SavedProductsState {
  const SavedProductsState({this.entries = const {}, this.isLoaded = false});

  /// Product id → its saved row.
  final Map<String, SavedForLaterEntry> entries;

  /// Whether the server list has been read this session.
  final bool isLoaded;

  bool isSaved(String productId) => entries.containsKey(productId);

  Set<String> get productIds => entries.keys.toSet();

  Set<String> get variantIds => {
    for (final entry in entries.values)
      if (entry.variantId.isNotEmpty) entry.variantId,
  };
}

/// Saved-for-later product ids shared by the Mall home, listings, collections,
/// storefronts and the product page, so a heart toggled on one screen is
/// already filled on the next.
///
/// The list is read once when the provider is created for a signed-in viewer
/// (a new sign-in recreates it). Toggles are optimistic: the heart changes at
/// once and rolls back if the request fails.
class SavedProductsNotifier extends StateNotifier<SavedProductsState> {
  SavedProductsNotifier(
    this._api, {
    required bool signedIn,
    required DefaultVariantResolver resolveDefaultVariant,
  }) : _resolveDefaultVariant = resolveDefaultVariant,
       super(const SavedProductsState()) {
    if (signedIn) unawaited(load());
  }

  /// Read lazily, so building a heart never builds the HTTP client.
  final SavedForLaterApi Function() _api;
  final DefaultVariantResolver _resolveDefaultVariant;

  /// Products toggled this session; a late server list can't overwrite them.
  final Set<String> _touched = <String>{};
  final Set<String> _inFlight = <String>{};

  Future<void> load() async {
    try {
      final rows = await _api().list();
      if (!mounted) return;
      final next = <String, SavedForLaterEntry>{
        for (final row in rows) row.productId: row,
      };
      for (final productId in _touched) {
        final current = state.entries[productId];
        if (current == null) {
          next.remove(productId);
        } else {
          next[productId] = current;
        }
      }
      state = SavedProductsState(entries: next, isLoaded: true);
    } on Object catch (_) {
      // Hearts stay as they are; the list is read again next session.
    }
  }

  /// Saves or unsaves [productId]. [variantId] defaults to the product's
  /// default variant.
  ///
  /// Returns false after a rollback. A tap while the previous request for the
  /// same product is still running is ignored and returns true.
  Future<bool> toggle(String productId, {String? variantId}) async {
    if (productId.isEmpty) return false;
    if (_inFlight.contains(productId)) return true;
    _touched.add(productId);
    _inFlight.add(productId);
    try {
      final existing = state.entries[productId];
      return existing == null
          ? await _save(productId, variantId)
          : await _remove(existing);
    } finally {
      _inFlight.remove(productId);
    }
  }

  Future<bool> _save(String productId, String? variantId) async {
    _put(
      SavedForLaterEntry(
        savedItemId: '',
        productId: productId,
        variantId: variantId ?? '',
      ),
    );
    try {
      final variant = variantId != null && variantId.isNotEmpty
          ? variantId
          : await _resolveDefaultVariant(productId);
      if (variant == null || variant.isEmpty) {
        throw StateError('No variant to save for $productId.');
      }
      final saved = await _api().save(productId: productId, variantId: variant);
      if (mounted) _put(saved);
      return true;
    } on Object catch (_) {
      if (mounted) _drop(productId);
      return false;
    }
  }

  Future<bool> _remove(SavedForLaterEntry entry) async {
    _drop(entry.productId);
    try {
      var savedItemId = entry.savedItemId;
      if (savedItemId.isEmpty) {
        final rows = await _api().list();
        savedItemId =
            rows
                .where((row) => row.productId == entry.productId)
                .firstOrNull
                ?.savedItemId ??
            '';
      }
      if (savedItemId.isNotEmpty) await _api().remove(savedItemId);
      return true;
    } on Object catch (_) {
      if (mounted) _put(entry);
      return false;
    }
  }

  void _put(SavedForLaterEntry entry) {
    state = SavedProductsState(
      entries: {...state.entries, entry.productId: entry},
      isLoaded: state.isLoaded,
    );
  }

  void _drop(String productId) {
    if (!state.entries.containsKey(productId)) return;
    state = SavedProductsState(
      entries: {...state.entries}..remove(productId),
      isLoaded: state.isLoaded,
    );
  }
}
