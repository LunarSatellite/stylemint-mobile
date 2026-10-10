/// Where a notification goes when it is tapped — one answer for a push
/// tapped from the tray (background or cold start), the in-app banner of a
/// push that arrived in the foreground, and a row of the notification inbox.
///
/// The server's push `data` carries `type` (the template key without its
/// channel suffix: `order.packed`, `delivery.interest`, `kyc.decided`, …)
/// plus `orderId`, `subOrderId` and `orderNumber` when the notification has
/// them. An inbox row carries the same facts as `templateKey` and its
/// variables. Before 2026-10-09 pushes carried no `type` and no ids at all;
/// those still open the app, and nothing else.
///
/// Resolution order:
///  1. an explicit link (`deepLink`, `deep_link`, `link`, `url`, `route`);
///  2. by type — KYC decision, delivery notifications (their own contract,
///     see `delivery_push.dart`), buyer orders, payment plans, payouts,
///     catalog alerts;
///  3. an untyped payload that still names an order opens that order;
///  4. otherwise null: the notification only tells the user something.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/device/push_destination.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_push.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// A backend id (GUID), as opposed to an order number.
final _guid = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _isGuid(String value) => _guid.hasMatch(value);

/// Channel suffixes a template key can carry; the push `type` never does.
const _channelSuffixes = ['.push', '.inapp', '.in_app', '.email', '.sms'];

/// [templateKey] as a notification type: trimmed, lower-case, without a
/// channel suffix. Null when empty.
String? notificationTypeFromTemplateKey(String? templateKey) {
  var key = templateKey?.trim().toLowerCase() ?? '';
  for (final suffix in _channelSuffixes) {
    if (key.endsWith(suffix)) {
      key = key.substring(0, key.length - suffix.length);
      break;
    }
  }
  return key.isEmpty ? null : key;
}

/// One notification, as routing needs it: its [type] (normalised) and the
/// facts that travel with it.
class NotificationPayload {
  const NotificationPayload({required this.type, required this.data});

  /// A push's FCM `data`.
  factory NotificationPayload.fromPushData(Map<String, dynamic> data) =>
      NotificationPayload(
        type: notificationTypeFromTemplateKey(data['type']?.toString()),
        data: data,
      );

  /// An inbox row: its template key and its variables (the decoded
  /// `variablesJson`). A `data.<name>` variable is what the server sends as
  /// `<name>` in the push, so it wins over a plain variable of that name.
  factory NotificationPayload.fromInbox({
    String? templateKey,
    Map<String, dynamic> variables = const {},
  }) {
    final data = <String, dynamic>{};
    for (final MapEntry(:key, :value) in variables.entries) {
      if (!key.startsWith('data.')) data.putIfAbsent(key, () => value);
    }
    for (final MapEntry(:key, :value) in variables.entries) {
      if (key.startsWith('data.') && key.length > 5) {
        data[key.substring(5)] = value;
      }
    }
    final type =
        notificationTypeFromTemplateKey(data['type']?.toString()) ??
        notificationTypeFromTemplateKey(templateKey);
    if (type != null) data['type'] = type;
    return NotificationPayload(type: type, data: data);
  }

  /// [NotificationPayload.fromInbox] for a raw `variablesJson`; malformed
  /// JSON is treated as no variables.
  factory NotificationPayload.fromInboxJson({
    String? templateKey,
    String? variablesJson,
  }) {
    var variables = const <String, dynamic>{};
    final raw = variablesJson?.trim() ?? '';
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) variables = decoded;
      } on FormatException {
        // No variables.
      }
    }
    return NotificationPayload.fromInbox(
      templateKey: templateKey,
      variables: variables,
    );
  }

  final String? type;
  final Map<String, dynamic> data;

  String? id(String key) {
    final raw = data[key]?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }
}

/// Which side of the app the person is on, for the notifications whose
/// landing depends on it (a vendor and a rider both get
/// `delivery.delivered`; payouts go to vendors and creators).
class NotificationViewer {
  const NotificationViewer({
    this.onVendorSide = false,
    this.onRiderSide = false,
    this.onCreatorSide = false,
    this.roles = const {},
  });

  /// From the router's current [location] and the account's JWT [roles].
  factory NotificationViewer.from({
    required String location,
    Set<String> roles = const {},
  }) => NotificationViewer(
    onVendorSide: location.startsWith('/vendor'),
    onRiderSide: location.startsWith(RouteNames.courier),
    onCreatorSide: location.startsWith('/creator'),
    roles: roles,
  );

  final bool onVendorSide;
  final bool onRiderSide;
  final bool onCreatorSide;

  /// Lower-case role names from the access token.
  final Set<String> roles;

  /// The side on screen decides; failing that, a vendor account is treated
  /// as the vendor — the same rule delivery routing has always used.
  bool get actsAsVendor {
    if (onRiderSide) return false;
    return onVendorSide || roles.contains('vendor');
  }
}

/// The go_router location a tapped notification opens, or null to just open
/// the app.
String? notificationLocation(
  NotificationPayload payload, {
  NotificationViewer viewer = const NotificationViewer(),
}) {
  // 1. An explicit link always wins.
  final link = pushDestinationUri(payload.data);
  if (link != null) {
    final location = deepLinkLocation(link);
    // Backend API URLs are not app routes (see _handleUri in main.dart).
    if (!location.startsWith('/v1/')) return location;
  }

  // 2. By type.
  final type = payload.type;
  if (type != null) {
    if (type == KycDecidedPush.type) return RouteNames.customerKyc;

    final delivery = DeliveryPushEvent.fromData({
      ...payload.data,
      'type': type,
    });
    if (delivery != null) {
      return delivery.routeFor(vendor: viewer.actsAsVendor);
    }

    // The inbox row carries a `deepLink` (handled above); a push only the
    // tracking number, when it carries anything.
    if (type == 'delivery.at_risk') {
      final tracking = payload.id('trackingNumber');
      return tracking == null
          ? RouteNames.orders
          : '/delivery/${Uri.encodeComponent(tracking)}/recovery';
    }

    // Vendor-facing order notifications name the vendor's sub-order.
    if (type.startsWith('vendor.') || type.contains('.vendor.')) {
      final subOrderId = payload.id('subOrderId');
      if (subOrderId != null && _isGuid(subOrderId)) {
        return '/vendor/orders/${Uri.encodeComponent(subOrderId)}';
      }
      if (type.contains('order')) return RouteNames.vendorOrders;
    }

    // Every `order.*` template goes to the buyer.
    if (type.startsWith('order.')) return buyerOrderLocation(payload);

    // Payment-plan reminders and the default notice. The server sends the
    // plan's screen as `deepLink` (handled above); this is for a payload
    // that carries only the plan's id, or nothing at all.
    if (type.startsWith('plan.')) return paymentPlanLocation(payload);

    if (type.startsWith('payout.')) {
      if (viewer.onVendorSide) return RouteNames.vendorEarnings;
      if (viewer.onCreatorSide) return RouteNames.earnings;
      if (viewer.roles.contains('vendor')) return RouteNames.vendorEarnings;
      if (viewer.roles.contains('creator')) return RouteNames.earnings;
      return null;
    }

    if (type.startsWith('catalog.') || type.startsWith('price.')) {
      final productId = payload.id('productId');
      if (productId != null) {
        return '/product/${Uri.encodeComponent(productId)}';
      }
    }
  }

  // 3. No type (or one this app does not know) that still names an order.
  if (type == null || !type.contains('.')) {
    final hasOrder =
        payload.id('orderNumber') != null ||
        payload.id('orderId') != null ||
        payload.id('subOrderId') != null;
    if (hasOrder) return buyerOrderLocation(payload);
  }
  return null;
}

/// The buyer's order for [payload].
///
/// The order screen is addressed by order number, so a real one is used
/// as-is. Otherwise an id — the order's, else the sub-order's — goes to the
/// same address, where the order screen looks it up among the buyer's
/// orders. Sub-order notifications used to put the sub-order id in
/// `orderNumber`, so a GUID there is read as a sub-order id. With nothing to
/// go on, the orders list.
String buyerOrderLocation(NotificationPayload payload) {
  final number = payload.id('orderNumber');
  if (number != null && !_isGuid(number)) {
    return '/orders/${Uri.encodeComponent(number)}';
  }
  final orderId = payload.id('orderId');
  if (orderId != null && _isGuid(orderId)) {
    return '/orders/${Uri.encodeComponent(orderId)}';
  }
  final subOrderId = payload.id('subOrderId') ?? number;
  if (subOrderId != null && _isGuid(subOrderId)) {
    return '/orders/${Uri.encodeComponent(subOrderId)}';
  }
  return RouteNames.orders;
}

/// The plan a payment-plan notification is about, by its `agreementId`;
/// with no usable id, the buyer's list of plans.
String paymentPlanLocation(NotificationPayload payload) {
  final agreementId = payload.id('agreementId');
  return agreementId != null && _isGuid(agreementId)
      ? RouteNames.paymentPlanDetailPath(agreementId)
      : RouteNames.paymentPlans;
}

/// The viewer for a notification tapped while the router shows [location]:
/// that location plus the roles on the stored access token.
Future<NotificationViewer> readNotificationViewer(
  WidgetRef ref, {
  required String location,
}) async {
  final token = await ref.read(tokenStorageProvider).accessToken;
  return NotificationViewer.from(
    location: location,
    roles: rolesFromJwt(token),
  );
}
