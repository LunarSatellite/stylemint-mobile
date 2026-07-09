import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';

part 'badge_award_dto.freezed.dart';
part 'badge_award_dto.g.dart';

@freezed
abstract class BadgeAwardDto with _$BadgeAwardDto {
  const factory BadgeAwardDto({
    required String id,
    @Default('') String badgeCode,
    @Default('') String badgeDisplayName,
    @Default('') String badgeIconUrl,
    @Default(1) int badgeTier,
    @Default(1) int badgeCategory,
    @Default(false) bool isShowcased,
    int? showcasedOrder,
  }) = _BadgeAwardDto;

  const BadgeAwardDto._();

  factory BadgeAwardDto.fromJson(Map<String, dynamic> json) =>
      _$BadgeAwardDtoFromJson(json);

  BadgeAward toDomain() => BadgeAward(
        id: id,
        badgeCode: badgeCode,
        badgeDisplayName: badgeDisplayName,
        badgeIconUrl: badgeIconUrl,
        badgeTier: badgeTier,
        badgeCategory: badgeCategory,
        isShowcased: isShowcased,
        showcasedOrder: showcasedOrder,
      );
}
