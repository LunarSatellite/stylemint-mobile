import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_dashboard_dto.freezed.dart';
part 'vendor_dashboard_dto.g.dart';

@freezed
abstract class VendorOrderSummaryDto with _$VendorOrderSummaryDto {
  const factory VendorOrderSummaryDto({
    required String id,
    required String orderNumber,
    required String itemName,
    required int quantity,
    required double amount,
    @Default('NPR') String currency,
    required String status,
    required DateTime placedAt,
  }) = _VendorOrderSummaryDto;

  const VendorOrderSummaryDto._();

  factory VendorOrderSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderSummaryDtoFromJson(json);

  VendorOrderSummary toDomain() => VendorOrderSummary(
    id: id,
    orderNumber: orderNumber,
    itemName: itemName,
    quantity: quantity,
    amount: Money(amount: amount, currency: currency),
    status: status,
    placedAt: placedAt,
  );
}

@freezed
abstract class VendorDashboardDto with _$VendorDashboardDto {
  const factory VendorDashboardDto({
    required double totalRevenue,
    @Default('NPR') String currency,
    required int totalOrders,
    required int totalProducts,
    required double averageRating,
    required List<VendorOrderSummaryDto> recentOrders,
    required int pendingFulfillment,
    required int lowStockProducts,
  }) = _VendorDashboardDto;

  const VendorDashboardDto._();

  factory VendorDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$VendorDashboardDtoFromJson(json);

  VendorDashboard toDomain() => VendorDashboard(
    totalRevenue: Money(amount: totalRevenue, currency: currency),
    totalOrders: totalOrders,
    totalProducts: totalProducts,
    averageRating: averageRating,
    recentOrders: recentOrders.map((r) => r.toDomain()).toList(growable: false),
    pendingFulfillment: pendingFulfillment,
    lowStockProducts: lowStockProducts,
  );
}
