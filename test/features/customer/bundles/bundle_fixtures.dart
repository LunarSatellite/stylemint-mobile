/// Wire fixtures for the bundle tests (shop bundles contract §B6).
library;

Map<String, dynamic> bundleDetailWire({
  bool purchasable = true,
  String? reason,
  int termsVersion = 3,
}) => {
  'id': 'b-1',
  'title': 'Trekking kit',
  'description': 'Everything for a weekend on the trail.',
  'discountPercent': 10,
  'termsVersion': termsVersion,
  'isPurchasable': purchasable,
  'unavailableReason': reason,
  'currency': 'NPR',
  'curator': {
    'kind': 'Creator',
    'accountId': 'c-1',
    'name': 'Asha',
    'handle': 'asha',
  },
  'items': [
    {
      'id': 'bi-jacket',
      'productId': 'p-jacket',
      'vendorAccountId': 'v-peak',
      'quantity': 1,
      'listUnitPrice': 12000,
      'bundleUnitPrice': 10800,
      'product': {
        'productId': 'p-jacket',
        'title': 'Down jacket',
        'vendorName': 'Peak Gear',
      },
      'variants': [
        {'id': 'v-jacket-m', 'label': 'M', 'price': 12000, 'inStock': true},
        {'id': 'v-jacket-l', 'label': 'L', 'price': 13000, 'inStock': true},
        {'id': 'v-jacket-xl', 'label': 'XL', 'price': 13000, 'inStock': false},
      ],
    },
    {
      'id': 'bi-socks',
      'productId': 'p-socks',
      'vendorAccountId': 'v-sock',
      'quantity': 2,
      'listUnitPrice': 500,
      'bundleUnitPrice': 450,
      'product': {
        'productId': 'p-socks',
        'title': 'Wool socks',
        'vendorName': 'Sock Co',
      },
      'variants': [
        {'id': 'v-socks', 'label': 'One size', 'price': 500, 'inStock': true},
      ],
    },
  ],
};

/// A cart with one bundle (two lines from two shops) and one ordinary line.
Map<String, dynamic> bundleCartWire({
  bool purchasable = true,
  List<Map<String, dynamic>> notices = const [],
  bool withBundle = true,
  bool withLoose = true,
}) => {
  'accountId': 'acc-1',
  'lines': [
    if (withBundle) ...[
      {
        'lineId': 'l-jacket',
        'productId': 'p-jacket',
        'productTitleSnapshot': 'Down jacket',
        'variantLabelSnapshot': 'M',
        'quantity': 1,
        'unitPriceAmount': 10800,
        'productVariantId': 'v-jacket-m',
        'bundleId': 'b-1',
        'bundleGroupId': 'g-1',
        'bundleItemId': 'bi-jacket',
        'bundleListUnitPrice': 12000,
        'bundleTitleSnapshot': 'Trekking kit',
        'vendorAccountId': 'v-peak',
        'vendorName': 'Peak Gear',
      },
      {
        'lineId': 'l-socks',
        'productId': 'p-socks',
        'productTitleSnapshot': 'Wool socks',
        'quantity': 2,
        'unitPriceAmount': 450,
        'productVariantId': 'v-socks',
        'bundleId': 'b-1',
        'bundleGroupId': 'g-1',
        'bundleItemId': 'bi-socks',
        'bundleListUnitPrice': 500,
        'bundleTitleSnapshot': 'Trekking kit',
        'vendorAccountId': 'v-sock',
        'vendorName': 'Sock Co',
      },
    ] else ...[
      {
        'lineId': 'l-jacket',
        'productId': 'p-jacket',
        'productTitleSnapshot': 'Down jacket',
        'quantity': 1,
        'unitPriceAmount': 12000,
        'productVariantId': 'v-jacket-m',
      },
      {
        'lineId': 'l-socks',
        'productId': 'p-socks',
        'productTitleSnapshot': 'Wool socks',
        'quantity': 2,
        'unitPriceAmount': 500,
        'productVariantId': 'v-socks',
      },
    ],
    if (withLoose) {
      'lineId': 'l-cap',
      'productId': 'p-cap',
      'productTitleSnapshot': 'Sun cap',
      'quantity': 1,
      'unitPriceAmount': 800,
      'productVariantId': 'v-cap',
    },
  ],
  'subtotalAmount': 12500,
  'shippingAmount': 0,
  'taxAmount': 0,
  'grandTotalAmount': 12500,
  'bundles': [
    if (withBundle)
      {
        'groupId': 'g-1',
        'bundleId': 'b-1',
        'title': 'Trekking kit',
        'quantity': 1,
        'listTotal': 13000,
        'total': 11700,
        'saving': 1300,
        'isPurchasable': purchasable,
        'unavailableReason': purchasable ? null : 'paused',
      },
  ],
  'notices': notices,
};
