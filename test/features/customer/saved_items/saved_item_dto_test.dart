import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/models/saved_item_dto.dart';

Map<String, dynamic> _payload({
  bool? trackInventory,
  bool? allowOverselling,
  int? quantityOnHand,
}) {
  final payload = <String, dynamic>{
    'id': 'saved-1',
    'productId': 'product-1',
    'productTitleSnapshot': 'Travel mug',
    'unitPriceAmount': 750,
    'createdUtc': '2026-09-07T08:00:00Z',
  };
  if (trackInventory != null) payload['trackInventory'] = trackInventory;
  if (allowOverselling != null) payload['allowOverselling'] = allowOverselling;
  if (quantityOnHand != null) payload['quantityOnHand'] = quantityOnHand;
  return payload;
}

void main() {
  test('renders an out-of-stock saved item from tracked inventory', () {
    final item = SavedItemDto.fromJson(
      _payload(
        trackInventory: true,
        allowOverselling: false,
        quantityOnHand: 0,
      ),
    ).toDomain();

    expect(item.stockStatus, 'outOfStock');
  });

  test('does not mark an untracked or unknown item out of stock', () {
    final untracked = SavedItemDto.fromJson(
      _payload(trackInventory: false, quantityOnHand: 0),
    ).toDomain();
    final unknown = SavedItemDto.fromJson(_payload()).toDomain();

    expect(untracked.stockStatus, 'inStock');
    expect(unknown.stockStatus, 'inStock');
  });
}
