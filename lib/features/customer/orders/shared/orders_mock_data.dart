// Static order data used while the real API is unavailable.
// Swap ordersRepositoryProvider back to OrdersRepositoryImpl for production.

import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Money _npr(double amount) => Money(amount: amount, currency: 'NPR');

// ── TrackedOrder list (Track Orders screen) ───────────────────────────────────

final kMockTrackedOrders = <TrackedOrder>[
  TrackedOrder(
    id: 'ord_001',
    orderNumber: 'SM20240615',
    total: _npr(3450),
    placedAt: DateTime(2024, 6, 15, 10, 30),
    itemCount: 2,
    status: OrderTrackStatus.inTransit,
  ),
  TrackedOrder(
    id: 'ord_002',
    orderNumber: 'SM20240608',
    total: _npr(1899),
    placedAt: DateTime(2024, 6, 8, 14, 15),
    itemCount: 1,
    status: OrderTrackStatus.delivered,
  ),
  TrackedOrder(
    id: 'ord_003',
    orderNumber: 'SM20240601',
    total: _npr(5200),
    placedAt: DateTime(2024, 6, 1, 9, 0),
    itemCount: 3,
    status: OrderTrackStatus.outForDelivery,
  ),
  TrackedOrder(
    id: 'ord_004',
    orderNumber: 'SM20240520',
    total: _npr(2750),
    placedAt: DateTime(2024, 5, 20, 11, 45),
    itemCount: 2,
    status: OrderTrackStatus.delivered,
  ),
  TrackedOrder(
    id: 'ord_005',
    orderNumber: 'SM20240510',
    total: _npr(1299),
    placedAt: DateTime(2024, 5, 10, 16, 20),
    itemCount: 1,
    status: OrderTrackStatus.cancelled,
  ),
];

// ── OrderDetail map (Order Detail screen) ─────────────────────────────────────

final kMockOrderDetails = <String, OrderDetail>{
  // ── Order 1: In Transit — can cancel ──────────────────────────────────────
  'ord_001': OrderDetail(
    id: 'ord_001',
    orderNumber: 'SM20240615',
    status: OrderTrackStatus.inTransit,
    placedAt: DateTime(2024, 6, 15, 10, 30),
    estimatedDelivery: DateTime(2024, 6, 20),
    trackingNumber: 'TRK-9823671',
    items: [
      OrderDetailItem(
        productId: 'p_001',
        productName: 'Classic Linen Button-Up Shirt',
        imageUrl: 'https://picsum.photos/seed/linen-shirt/400/400',
        variantName: 'Size M / White',
        qty: 1,
        unitPrice: _npr(1950),
        status: 'active',
      ),
      OrderDetailItem(
        productId: 'p_002',
        productName: 'Slim Fit Chinos',
        imageUrl: 'https://picsum.photos/seed/chinos/400/400',
        variantName: 'Size 32 / Khaki',
        qty: 1,
        unitPrice: _npr(1350),
        status: 'active',
      ),
    ],
    subtotal: _npr(3300),
    shipping: _npr(100),
    tax: _npr(50),
    total: _npr(3450),
    shippingAddress: 'Sailesh Aryal, Baneshwor-10, Kathmandu 44600, Nepal',
    paymentMethod: 'eSewa',
    canCancel: true,
    canReturn: false,
  ),

  // ── Order 2: Delivered — can return ───────────────────────────────────────
  'ord_002': OrderDetail(
    id: 'ord_002',
    orderNumber: 'SM20240608',
    status: OrderTrackStatus.delivered,
    placedAt: DateTime(2024, 6, 8, 14, 15),
    estimatedDelivery: DateTime(2024, 6, 13),
    trackingNumber: 'TRK-8801234',
    items: [
      OrderDetailItem(
        productId: 'p_003',
        productName: 'Premium Leather Crossbody Bag',
        imageUrl: 'https://picsum.photos/seed/leather-bag/400/400',
        variantName: 'One Size / Tan',
        qty: 1,
        unitPrice: _npr(1799),
        status: 'active',
      ),
    ],
    subtotal: _npr(1799),
    shipping: _npr(100),
    tax: _npr(0),
    total: _npr(1899),
    shippingAddress: 'Sailesh Aryal, Baneshwor-10, Kathmandu 44600, Nepal',
    paymentMethod: 'Cash on Delivery',
    canCancel: false,
    canReturn: true,
  ),

  // ── Order 3: Out for Delivery — can cancel ────────────────────────────────
  'ord_003': OrderDetail(
    id: 'ord_003',
    orderNumber: 'SM20240601',
    status: OrderTrackStatus.outForDelivery,
    placedAt: DateTime(2024, 6, 1, 9, 0),
    estimatedDelivery: DateTime(2024, 6, 5),
    trackingNumber: null,
    items: [
      OrderDetailItem(
        productId: 'p_004',
        productName: 'Oversized Graphic Tee',
        imageUrl: 'https://picsum.photos/seed/graphic-tee/400/400',
        variantName: 'Size L / Black',
        qty: 2,
        unitPrice: _npr(899),
        status: 'active',
      ),
      OrderDetailItem(
        productId: 'p_005',
        productName: 'High-Waist Mom Jeans',
        imageUrl: 'https://picsum.photos/seed/mom-jeans/400/400',
        variantName: 'Size 28 / Light Blue',
        qty: 1,
        unitPrice: _npr(1699),
        status: 'active',
      ),
      OrderDetailItem(
        productId: 'p_001',
        productName: 'Classic Linen Button-Up Shirt',
        imageUrl: 'https://picsum.photos/seed/linen-shirt/400/400',
        variantName: 'Size S / Cream',
        qty: 1,
        unitPrice: _npr(1453),
        status: 'active',
      ),
    ],
    subtotal: _npr(4950),
    shipping: _npr(150),
    tax: _npr(100),
    total: _npr(5200),
    shippingAddress: 'Sailesh Aryal, Baneshwor-10, Kathmandu 44600, Nepal',
    paymentMethod: 'eSewa',
    canCancel: true,
    canReturn: false,
  ),

  // ── Order 4: Delivered — can return ───────────────────────────────────────
  'ord_004': OrderDetail(
    id: 'ord_004',
    orderNumber: 'SM20240520',
    status: OrderTrackStatus.delivered,
    placedAt: DateTime(2024, 5, 20, 11, 45),
    estimatedDelivery: DateTime(2024, 5, 25),
    trackingNumber: 'TRK-7712903',
    items: [
      OrderDetailItem(
        productId: 'p_006',
        productName: 'Structured Blazer',
        imageUrl: 'https://picsum.photos/seed/blazer/400/400',
        variantName: 'Size M / Navy',
        qty: 1,
        unitPrice: _npr(2200),
        status: 'active',
      ),
      OrderDetailItem(
        productId: 'p_007',
        productName: 'Ribbed Tank Top (Pack of 2)',
        imageUrl: 'https://picsum.photos/seed/tank-top/400/400',
        variantName: 'One Size / White',
        qty: 1,
        unitPrice: _npr(300),
        status: 'active',
      ),
    ],
    subtotal: _npr(2500),
    shipping: _npr(150),
    tax: _npr(100),
    total: _npr(2750),
    shippingAddress: 'Sailesh Aryal, Baneshwor-10, Kathmandu 44600, Nepal',
    paymentMethod: 'eSewa',
    canCancel: false,
    canReturn: true,
  ),

  // ── Order 5: Cancelled ────────────────────────────────────────────────────
  'ord_005': OrderDetail(
    id: 'ord_005',
    orderNumber: 'SM20240510',
    status: OrderTrackStatus.cancelled,
    placedAt: DateTime(2024, 5, 10, 16, 20),
    estimatedDelivery: DateTime(2024, 5, 15),
    trackingNumber: 'TRK-5540219',
    items: [
      OrderDetailItem(
        productId: 'p_008',
        productName: 'Floral Wrap Dress',
        imageUrl: 'https://picsum.photos/seed/wrap-dress/400/400',
        variantName: 'Size S / Rose Print',
        qty: 1,
        unitPrice: _npr(1199),
        status: 'cancelled',
      ),
    ],
    subtotal: _npr(1199),
    shipping: _npr(100),
    tax: _npr(0),
    total: _npr(1299),
    shippingAddress: 'Sailesh Aryal, Baneshwor-10, Kathmandu 44600, Nepal',
    paymentMethod: 'Cash on Delivery',
    canCancel: false,
    canReturn: false,
  ),
};
