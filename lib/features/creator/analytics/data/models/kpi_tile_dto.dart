import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/kpi_tile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'kpi_tile_dto.freezed.dart';
part 'kpi_tile_dto.g.dart';

@freezed
abstract class MoneyKpiTileDto with _$MoneyKpiTileDto {
  const factory MoneyKpiTileDto({
    required MoneyDto current,
    MoneyDto? previous,
    double? deltaPercent,
  }) = _MoneyKpiTileDto;

  const MoneyKpiTileDto._();

  factory MoneyKpiTileDto.fromJson(Map<String, dynamic> json) =>
      _$MoneyKpiTileDtoFromJson(json);

  KpiTile<Money> toDomain() => KpiTile(
    current: current.toDomain(),
    previous: previous?.toDomain(),
    deltaPercent: deltaPercent,
  );
}

@freezed
abstract class IntKpiTileDto with _$IntKpiTileDto {
  const factory IntKpiTileDto({
    @Default(0) int current,
    int? previous,
    double? deltaPercent,
  }) = _IntKpiTileDto;

  const IntKpiTileDto._();

  factory IntKpiTileDto.fromJson(Map<String, dynamic> json) =>
      _$IntKpiTileDtoFromJson(json);

  KpiTile<int> toDomain() => KpiTile(
    current: current,
    previous: previous,
    deltaPercent: deltaPercent,
  );
}

@freezed
abstract class DoubleKpiTileDto with _$DoubleKpiTileDto {
  const factory DoubleKpiTileDto({
    @Default(0.0) double current,
    double? previous,
    double? deltaPercent,
  }) = _DoubleKpiTileDto;

  const DoubleKpiTileDto._();

  factory DoubleKpiTileDto.fromJson(Map<String, dynamic> json) =>
      _$DoubleKpiTileDtoFromJson(json);

  KpiTile<double> toDomain() => KpiTile(
    current: current,
    previous: previous,
    deltaPercent: deltaPercent,
  );
}
