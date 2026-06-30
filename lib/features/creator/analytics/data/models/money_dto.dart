import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'money_dto.freezed.dart';
part 'money_dto.g.dart';

@freezed
abstract class MoneyDto with _$MoneyDto {
  const factory MoneyDto({
    @Default(0.0) double amount,
    @Default('NPR') String currency,
  }) = _MoneyDto;

  const MoneyDto._();

  factory MoneyDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyDtoFromJson(json);

  Money toDomain() => Money(amount: amount, currency: currency);
}
