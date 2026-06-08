import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_form_dto.freezed.dart';
part 'product_form_dto.g.dart';

/// A selectable catalog category (GET /v1/public/categories). The backend
/// product wizard takes a single `categoryId`, so the picker resolves the
/// vendor's choice to one of these real Guids.
@freezed
abstract class CategoryOptionDto with _$CategoryOptionDto {
  const factory CategoryOptionDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'nameEn') required String name,
    @JsonKey(name: 'parentCategoryId') String? parentCategoryId,
    @Default(0) int displayOrder,
  }) = _CategoryOptionDto;

  factory CategoryOptionDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryOptionDtoFromJson(json);
}

@freezed
abstract class ImageUploadResponseDto with _$ImageUploadResponseDto {
  const factory ImageUploadResponseDto({
    required String url,
  }) = _ImageUploadResponseDto;

  const ImageUploadResponseDto._();

  factory ImageUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadResponseDtoFromJson(json);
}
