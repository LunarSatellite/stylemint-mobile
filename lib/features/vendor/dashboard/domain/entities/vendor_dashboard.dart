import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class VendorOrderSummary {
  const VendorOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.status,
    required this.placedAt,
  });

  final String id;
  final String orderNumber;
  final String itemName;
  final int quantity;
  final Money amount;
  final String status;
  final DateTime placedAt;

  VendorOrderSummary copyWith({
    String? id,
    String? orderNumber,
    String? itemName,
    int? quantity,
    Money? amount,
    String? status,
    DateTime? placedAt,
  }) {
    return VendorOrderSummary(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorOrderSummary &&
      other.id == id &&
      other.orderNumber == orderNumber &&
      other.itemName == itemName &&
      other.quantity == quantity &&
      other.amount == amount &&
      other.status == status &&
      other.placedAt == placedAt;

  @override
  int get hashCode => Object.hash(id, orderNumber, itemName, quantity, amount, status, placedAt);
}

class VendorDashboard {
  const VendorDashboard({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.averageRating,
    required this.recentOrders,
    required this.pendingFulfillment,
    required this.lowStockProducts,
  });

  final Money totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final double averageRating;
  final List<VendorOrderSummary> recentOrders;
  final int pendingFulfillment;
  final int lowStockProducts;

  VendorDashboard copyWith({
    Money? totalRevenue,
    int? totalOrders,
    int? totalProducts,
    double? averageRating,
    List<VendorOrderSummary>? recentOrders,
    int? pendingFulfillment,
    int? lowStockProducts,
  }) {
    return VendorDashboard(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      totalProducts: totalProducts ?? this.totalProducts,
      averageRating: averageRating ?? this.averageRating,
      recentOrders: recentOrders ?? this.recentOrders,
      pendingFulfillment: pendingFulfillment ?? this.pendingFulfillment,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorDashboard &&
      other.totalRevenue == totalRevenue &&
      other.totalOrders == totalOrders &&
      other.totalProducts == totalProducts &&
      other.averageRating == averageRating &&
      other.pendingFulfillment == pendingFulfillment &&
      other.lowStockProducts == lowStockProducts;

  @override
  int get hashCode => Object.hash(totalRevenue, totalOrders, totalProducts, averageRating, pendingFulfillment, lowStockProducts);
}
