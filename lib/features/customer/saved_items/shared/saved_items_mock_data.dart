// ponytail: static stub while backend is down, remove when /v1/cart/saved-for-later is stable
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

final kMockSavedItems = <SavedItem>[
  SavedItem(
    id: 'si_001',
    productId: 'prod_001',
    productName: 'Chocolate Oreo Raspberry Cake',
    productImageUrl: '',
    variantLabel: '1 Pound',
    price: const Money(amount: 5000, currency: 'NPR'),
    originalPrice: const Money(amount: 6250, currency: 'NPR'),
    isFreeShipping: true,
    stockStatus: 'inStock',
    rating: 0,
    savedAt: DateTime(2025, 6, 1),
  ),
  SavedItem(
    id: 'si_002',
    productId: 'prod_002',
    productName: 'Nike Air Jordan Travis Scott Limited Edition',
    productImageUrl: '',
    variantLabel: 'Coffee Brown Color • 42 Size',
    price: const Money(amount: 25000, currency: 'NPR'),
    stockStatus: 'lowStock',
    rating: 0,
    savedAt: DateTime(2025, 6, 5),
  ),
  SavedItem(
    id: 'si_003',
    productId: 'prod_003',
    productName: 'Cera Ve Alpine Apple Berry Foaming Facewash 500ml',
    productImageUrl: '',
    price: const Money(amount: 2500, currency: 'NPR'),
    originalPrice: const Money(amount: 3000, currency: 'NPR'),
    priceDrop: const Money(amount: 500, currency: 'NPR'),
    stockStatus: 'outOfStock',
    rating: 0,
    savedAt: DateTime(2025, 6, 10),
  ),
];
