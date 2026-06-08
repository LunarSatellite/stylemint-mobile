import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'saved_item_dto.freezed.dart';
part 'saved_item_dto.g.dart';

/// Maps the backend SavedForLaterItemDto (CartCheckout module). Amounts are
/// `num` because System.Text.Json serializes whole `decimal`s as ints.
@freezed
abstract class SavedItemDto with _$SavedItemDto {
  const factory SavedItemDto({
    @JsonKey(name: 'id') required String id,
    required String productId,
    @JsonKey(name: 'productTitleSnapshot') required String productName,
    @JsonKey(name: 'thumbnailUrlSnapshot') String? productImageUrl,
    @JsonKey(name: 'variantLabelSnapshot') String? variantLabel,
    @JsonKey(name: 'unitPriceAmount') required num priceAmount,
    @JsonKey(name: 'unitPriceCurrency') @Default('NPR') String currency,
    @JsonKey(name: 'createdUtc') required DateTime savedAt,
  }) = _SavedItemDto;

  const SavedItemDto._();

  factory SavedItemDto.fromJson(Map<String, dynamic> json) =>
      _$SavedItemDtoFromJson(json);

  SavedItem toDomain() => SavedItem(
        id: id,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl ?? '',
        variantLabel: variantLabel,
        price: Money(amount: priceAmount.toDouble(), currency: currency),
        // SavedForLaterItemDto carries no rating; the card hides it when 0.
        rating: 0,
        savedAt: savedAt,
      );
}
