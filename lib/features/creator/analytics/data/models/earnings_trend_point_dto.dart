import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';

part 'earnings_trend_point_dto.freezed.dart';
part 'earnings_trend_point_dto.g.dart';

@freezed
abstract class EarningsTrendPointDto with _$EarningsTrendPointDto {
  const factory EarningsTrendPointDto({
    required DateTime date,
    required MoneyDto amount,
  }) = _EarningsTrendPointDto;

  const EarningsTrendPointDto._();

  factory EarningsTrendPointDto.fromJson(Map<String, dynamic> json) =>
      _$EarningsTrendPointDtoFromJson(json);

  EarningsTrendPoint toDomain() =>
      EarningsTrendPoint(date: date, amount: amount.toDomain());
}
