import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'saved_item_dto.freezed.dart';
part 'saved_item_dto.g.dart';

@freezed
abstract class SavedItemDto with _$SavedItemDto {
  const factory SavedItemDto({
    required String id,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double priceAmount,
    @Default('NPR') String currency,
    @Default(0) double rating,
    required DateTime savedAt,
  }) = _SavedItemDto;

  const SavedItemDto._();

  factory SavedItemDto.fromJson(Map<String, dynamic> json) =>
      _$SavedItemDtoFromJson(json);

  SavedItem toDomain() => SavedItem(
    id: id,
    productId: productId,
    productName: productName,
    productImageUrl: productImageUrl,
    price: Money(amount: priceAmount, currency: currency),
    rating: rating,
    savedAt: savedAt,
  );
}
