import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_pricing.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Tolerant readers for the bundle DTOs (contract §B5, §B6, §B9). Enums may
/// arrive as numbers or names; money as a number or `{amount, currency}`.

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

String? _media(Object? raw) {
  final url = readOptionalString(raw);
  return url == null ? null : absoluteMediaUrl(url);
}

/// A money value: a bare number (in [currency]) or `{amount, currency}`.
Money readBundleMoney(Object? raw, String currency) {
  if (raw is Map) {
    final amount = readOptionalDouble(raw['amount']) ?? 0;
    final cur = readOptionalString(raw['currency']) ?? currency;
    return Money(amount: amount, currency: cur);
  }
  return Money(amount: readOptionalDouble(raw) ?? 0, currency: currency);
}

/// One public product variant (`variants[]`).
BundleVariant? readBundleVariant(Map<String, dynamic> json, String currency) {
  final id = readString(json['id'] ?? json['variantId'] ?? json['productVariantId']);
  if (id.isEmpty) return null;
  final stockRaw = json['stockQuantity'] ?? json['availableQuantity'];
  final stock = stockRaw is num ? stockRaw.toInt() : null;
  final inStockRaw = json['inStock'] ?? json['isInStock'];
  final inStock = inStockRaw is bool ? inStockRaw : (stock ?? 1) > 0;
  final label =
      readOptionalString(json['label']) ??
      readOptionalString(json['optionLabel']) ??
      readOptionalString(json['name']) ??
      readOptionalString(json['sku']) ??
      'Standard';
  return BundleVariant(
    id: id,
    label: label,
    price: readBundleMoney(
      json['price'] ?? json['priceAmount'] ?? json['unitPrice'],
      readOptionalString(json['priceCurrency']) ?? currency,
    ),
    inStock: inStock,
    stockQuantity: stock,
    isDefault: readBool(json['isDefault']),
  );
}

BundleItem? readBundleItem(
  Map<String, dynamic> json,
  String currency,
  double discountPercent,
) {
  final product = _map(json['product']) ?? const <String, dynamic>{};
  final id = readString(json['id'] ?? json['bundleItemId']);
  final productId = readString(
    json['productId'] ?? product['productId'] ?? product['id'],
  );
  if (id.isEmpty || productId.isEmpty) return null;
  final variants = <BundleVariant>[
    if (json['variants'] is List)
      for (final row in json['variants'] as List)
        if (_map(row) case final m?)
          if (readBundleVariant(m, currency) case final v?) v,
  ];
  final quantity = readInt(json['quantity']);
  final list = readBundleMoney(
    json['listUnitPrice'] ?? product['price'] ?? product['priceAmount'],
    currency,
  );
  final bundleRaw = json['bundleUnitPrice'];
  final bundlePrice = bundleRaw == null
      ? Money(
          amount: bundleUnitPrice(list.amount, discountPercent),
          currency: list.currency,
        )
      : readBundleMoney(bundleRaw, currency);
  final available = json['available'];
  return BundleItem(
    id: id,
    productId: productId,
    vendorAccountId: readString(
      json['vendorAccountId'] ?? product['vendorAccountId'],
    ),
    shopName:
        readOptionalString(json['shopName']) ??
        readOptionalString(json['vendorName']) ??
        readOptionalString(product['vendorName']) ??
        readOptionalString(product['shopName']) ??
        readOptionalString(product['brandName']) ??
        'Shop',
    title:
        readOptionalString(json['title']) ??
        readOptionalString(product['title']) ??
        readOptionalString(product['name']) ??
        '',
    thumbnailUrl:
        _media(json['thumbnailUrl']) ??
        _media(product['thumbnailUrl']) ??
        _media(product['imageUrl']) ??
        _media(product['primaryImageUrl']),
    note: readOptionalString(json['note']),
    quantity: quantity < 1 ? 1 : quantity,
    listUnitPrice: list,
    bundleUnitPrice: bundlePrice,
    variants: List.unmodifiable(variants),
    available: available is bool ? available : true,
  );
}

BundleCurator? readBundleCurator(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  return BundleCurator(
    kind: BundleCuratorKind.fromWire(json['kind']),
    accountId: readString(json['accountId']),
    name: readOptionalString(json['name']) ?? 'StyleMint',
    handle: readOptionalString(json['handle'])?.replaceFirst('@', ''),
    avatarUrl: _media(json['avatarUrl']),
  );
}

String _currency(Map<String, dynamic> json) =>
    readOptionalString(json['currency']) ??
    readOptionalString(_map(json['totals'])?['currency']) ??
    'NPR';

/// `BundleDetailDto`.
BundleDetail readBundleDetail(Map<String, dynamic> json) {
  final id = readString(json['id'] ?? json['bundleId']);
  if (id.isEmpty) throw const FormatException('bundle without id');
  final currency = _currency(json);
  final discount = readOptionalDouble(json['discountPercent']) ?? 0;
  final items = <BundleItem>[
    if (json['items'] is List)
      for (final row in json['items'] as List)
        if (_map(row) case final m?)
          if (readBundleItem(m, currency, discount) case final i?) i,
  ];
  final purchasable = json['isPurchasable'];
  return BundleDetail(
    id: id,
    title: readOptionalString(json['title']) ?? 'Bundle',
    description: readOptionalString(json['description']),
    coverImageUrl: _media(json['coverImageUrl']),
    discountPercent: discount,
    termsVersion: readInt(json['termsVersion']),
    isPurchasable: purchasable is bool ? purchasable : true,
    unavailableReason: BundleUnavailableReason.fromWire(
      json['unavailableReason'],
    ),
    curator: readBundleCurator(json['curator']),
    items: List.unmodifiable(items),
    currency: currency,
  );
}

/// `BundleCardDto`. Also reads a detail or summary payload, so any bundle
/// shape becomes a card.
BundleCard readBundleCard(Map<String, dynamic> json) {
  final id = readString(json['id'] ?? json['bundleId']);
  if (id.isEmpty) throw const FormatException('bundle without id');
  final currency = _currency(json);
  final totals = _map(json['totals']) ?? json;
  final discount = readOptionalDouble(json['discountPercent']) ?? 0;
  final thumbs = <String>[
    if (json['thumbnailUrls'] is List)
      for (final t in json['thumbnailUrls'] as List)
        if (_media(t) case final u?) u,
  ];
  var itemCount = readInt(json['itemCount']);
  var shopCount = readInt(json['shopCount']);
  final listRaw = totals['listTotal'] ?? json['listTotalAmount'];
  final totalRaw = totals['bundleTotal'] ?? json['bundleTotalAmount'];
  var listTotal = readBundleMoney(listRaw, currency);
  var bundleTotal = readBundleMoney(totalRaw, currency);
  if (json['items'] is List) {
    final detail = readBundleDetail(json);
    if (itemCount == 0) itemCount = detail.items.length;
    if (shopCount == 0) shopCount = detail.shopCount;
    for (final i in detail.items) {
      if (i.thumbnailUrl != null && thumbs.length < 4) thumbs.add(i.thumbnailUrl!);
    }
    if (listRaw == null || totalRaw == null) {
      final quote = quoteBundle(detail, {
        for (final i in detail.items)
          if (i.initialVariant case final v?) i.id: v.id,
      });
      listTotal = quote.listTotal;
      bundleTotal = quote.bundleTotal;
    }
  }
  final purchasable = json['isPurchasable'];
  return BundleCard(
    id: id,
    title: readOptionalString(json['title']) ?? 'Bundle',
    coverImageUrl: _media(json['coverImageUrl']),
    discountPercent: discount,
    listTotal: listTotal,
    bundleTotal: bundleTotal,
    itemCount: itemCount,
    shopCount: shopCount,
    thumbnailUrls: List.unmodifiable(thumbs),
    isPurchasable: purchasable is bool ? purchasable : true,
    curatorName:
        readBundleCurator(json['curator'])?.byline ??
        readOptionalString(json['curatorName']),
  );
}

/// One `taggedBundles[]` entry, or null when unreadable.
ReelTaggedBundle? readReelTaggedBundle(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  final bundleJson = _map(json['bundle']);
  final tagId = readString(json['taggedBundleId'] ?? json['id']);
  if (bundleJson == null || tagId.isEmpty) return null;
  try {
    return ReelTaggedBundle(
      taggedBundleId: tagId,
      bundle: readBundleCard(bundleJson),
      x: readOptionalDouble(json['x'] ?? json['overlayPositionX']),
      y: readOptionalDouble(json['y'] ?? json['overlayPositionY']),
      appearAtSeconds: readOptionalDouble(
        json['appearAt'] ?? json['appearAtSeconds'],
      ),
      disappearAtSeconds: readOptionalDouble(
        json['disappearAt'] ?? json['disappearAtSeconds'],
      ),
    );
  } on FormatException {
    return null;
  }
}

/// A reel's `taggedBundles` (absent on a server without bundles: empty).
List<ReelTaggedBundle> readReelTaggedBundles(Object? raw) {
  final rows = raw is List
      ? raw
      : raw is Map && raw['items'] is List
      ? raw['items'] as List
      : const <dynamic>[];
  return List.unmodifiable([
    for (final row in rows)
      if (readReelTaggedBundle(row) case final t?) t,
  ]);
}

/// A bare array or `{ items: [...] }`, read with [item]; one unreadable row
/// is skipped.
List<T> readBundleList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) item,
) {
  final rows = raw is List
      ? raw
      : raw is Map && raw['items'] is List
      ? raw['items'] as List
      : const <dynamic>[];
  final out = <T>[];
  for (final row in rows) {
    final m = _map(row);
    if (m == null) continue;
    try {
      out.add(item(m));
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  return List.unmodifiable(out);
}

/// Turns whatever a call threw into a [BundleFailure], keeping the RFC 7807
/// `errorCode` and the body.
BundleFailure mapBundleFailure(Object error) {
  if (error is BundleFailure) return error;
  if (error is BundleLoadException) return error.failure;
  if (error is SocketException) {
    return const BundleFailure(BundleFailureKind.offline);
  }
  if (error is! DioException) {
    return const BundleFailure(BundleFailureKind.unknown);
  }
  final response = error.response;
  if (response == null) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => const BundleFailure(
        BundleFailureKind.offline,
      ),
      _ =>
        error.error is SocketException
            ? const BundleFailure(BundleFailureKind.offline)
            : const BundleFailure(BundleFailureKind.unknown),
    };
  }
  final status = response.statusCode ?? 0;
  final body = _map(response.data) ?? const <String, dynamic>{};
  final kind = switch (status) {
    401 || 403 => BundleFailureKind.auth,
    404 => BundleFailureKind.notFound,
    409 => BundleFailureKind.conflict,
    >= 500 => BundleFailureKind.server,
    >= 400 => BundleFailureKind.rejected,
    _ => BundleFailureKind.unknown,
  };
  return BundleFailure(
    kind,
    code: readOptionalString(body['errorCode']) ?? readOptionalString(body['code']),
    message:
        readOptionalString(body['detail']) ?? readOptionalString(body['title']),
    statusCode: status,
    body: body,
  );
}

/// Runs [call] and turns whatever it throws into a [BundleFailure].
Future<Either<BundleFailure, T>> guardedBundleCall<T>(
  Future<T> Function() call,
) async {
  try {
    return right(await call());
  } on Object catch (error) {
    return left(mapBundleFailure(error));
  }
}
