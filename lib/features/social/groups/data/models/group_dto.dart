import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'group_dto.freezed.dart';
part 'group_dto.g.dart';

@freezed
abstract class GroupProductDto with _$GroupProductDto {
  const factory GroupProductDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required double amount,
    @Default('NPR') String currency,
    required String recommenderName,
  }) = _GroupProductDto;

  const GroupProductDto._();

  factory GroupProductDto.fromJson(Map<String, dynamic> json) =>
      _$GroupProductDtoFromJson(json);

  GroupProduct toDomain() => GroupProduct(
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
    recommenderName: recommenderName,
  );
}

@freezed
abstract class StyleGroupDto with _$StyleGroupDto {
  const factory StyleGroupDto({
    required String id,
    required String name,
    required String description,
    required String coverImageUrl,
    required String category,
    @Default(0) int memberCount,
    @Default(false) bool isJoined,
    @Default(false) bool isPrivate,
    required DateTime createdAt,
    @Default(<GroupProductDto>[]) List<GroupProductDto> topProducts,
  }) = _StyleGroupDto;

  const StyleGroupDto._();

  factory StyleGroupDto.fromJson(Map<String, dynamic> json) =>
      _$StyleGroupDtoFromJson(json);

  StyleGroup toDomain() => StyleGroup(
    id: id,
    name: name,
    description: description,
    coverImageUrl: coverImageUrl,
    category: category,
    memberCount: memberCount,
    isJoined: isJoined,
    isPrivate: isPrivate,
    createdAt: createdAt,
    topProducts:
        topProducts.map((dto) => dto.toDomain()).toList(growable: false),
  );
}

@freezed
abstract class GroupPostDto with _$GroupPostDto {
  const factory GroupPostDto({
    required String id,
    required String groupId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    @Default(<String>[]) List<String> images,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    required DateTime createdAt,
  }) = _GroupPostDto;

  const GroupPostDto._();

  factory GroupPostDto.fromJson(Map<String, dynamic> json) =>
      _$GroupPostDtoFromJson(json);

  GroupPost toDomain() => GroupPost(
    id: id,
    groupId: groupId,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    content: content,
    images: images,
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: createdAt,
  );
}
