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
///  0. a seller EMI notice (`plan.vendor.*`) opens the seller's EMI plan;
///     a service vendor's booking, enquiry or appointment notice opens it
///     (see `service_notification_route.dart`); a journey notice opens the
///     journey; a return pickup notice opens the buyer's return, the
///     seller's Returns tab or the rider's job, by `audience`;
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
import 'package:stylemint_mobile_frontend/core/device/return_pickup_push.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_push.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_notification_route.dart';
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
    final keyType = notificationTypeFromTemplateKey(templateKey);
    final type =
        notificationTypeFromTemplateKey(data['type']?.toString()) ?? keyType;
    if (type != null) data['type'] = type;
    // A return notice's seller and rider wordings are their own templates
    // (`return_pickup.collected.seller`, `….rider`) under the buyer's
    // `data.type`: the key says who it is for when `audience` does not.
    final audienceSuffix = keyType?.split('.').last;
    if (data['audience'] == null &&
        ReturnPickupPush.fromData({'type': type}) != null &&
        (audienceSuffix == 'seller' || audienceSuffix == 'rider')) {
      data['audience'] = audienceSuffix;
    }
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

  /// The account holds the delivery-partner role (`Courier` on the token).
  /// The courier screens are only reachable with it, so being on them counts.
  bool get isCourier => onRiderSide || roles.contains('courier');

  /// For a return notice from a server that does not say who it is for
  /// (no `data.audience`): a courier account's notice that names a rider
  /// job (`hopId`) is the rider's, whatever screen is showing — a tap from
  /// the home screen or a cold start must not open the buyer's return, which
  /// 404s for the rider. On the courier screens a courier's notice is the
  /// rider's even without a job, as before.
  bool riderForReturnNotice({required bool namesJob}) =>
      isCourier && (namesJob || onRiderSide);
}

/// The go_router location a tapped notification opens, or null to just open
/// the app.
String? notificationLocation(
  NotificationPayload payload, {
  NotificationViewer viewer = const NotificationViewer(),
}) {
  // 0. A seller EMI notice (`plan.vendor.*`, emi-after contract v1) opens
  //    the seller's EMI plan screen (collections, schedule) even though
  //    its `deepLink` names the approval screen of the same plan.
  if (payload.type?.startsWith('plan.vendor.') ?? false) {
    return vendorEmiPlanLocation(payload);
  }

  // 0b. A service vendor's notice (`booking.vendor.*`,
  //     `service.bank.enquiry.*`, `service.bank.appointment.*`) opens the
  //     booking, lead or appointment — before any buyer `booking.*` rule.
  final pushLink = pushDestinationUri(payload.data);
  final serviceVendor = serviceVendorNotificationLocation(
    payload.type,
    payload.data,
    link: pushLink == null ? null : deepLinkLocation(pushLink),
  );
  if (serviceVendor != null) return serviceVendor;

  // 0c. A journey notice (journey reels contract v1 §6: invites, accepted,
  //     declined, left, removed, ended) opens the seller's journey screen.
  final journey = journeyNotificationLocation(
    payload.type,
    payload.data,
    link: pushLink == null ? null : deepLinkLocation(pushLink),
  );
  if (journey != null) return journey;

  // 0d. Return pickups (return pickup contract §7, return fixes contract C)
  //     route by who the notice is for, before any link: the buyer's return
  //     page is the wrong place for the seller and a 404 for the rider. A
  //     rider return request still arrives as `delivery.request` and goes to
  //     the offers screen below.
  final returnPickup = ReturnPickupPush.fromData({
    ...payload.data,
    'type': payload.type,
  });
  if (returnPickup != null) {
    return returnPickup.routeFor(
      vendor: viewer.actsAsVendor,
      rider: viewer.riderForReturnNotice(
        namesJob: returnPickup.hopId != null,
      ),
    );
  }

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

    // A refund for a return opens that return (return fixes contract C):
    // its refund line is there, the order only says "refunded".
    if (type == 'order.refunded') {
      final returnId = payload.id('returnRequestId');
      if (returnId != null) {
        return '${RouteNames.myReturns}/${Uri.encodeComponent(returnId)}';
      }
    }

    // Every `order.*` template goes to the buyer.
    if (type.startsWith('order.')) return buyerOrderLocation(payload);

    // Services. The server sends the screen as `deepLink` (handled above);
    // this is for a payload that carries only an id, or nothing at all.
    final services = servicesNotificationLocation(payload, viewer: viewer);
    if (services != null) return services;

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

/// The seller's EMI plan a `plan.vendor.*` notice is about: by its
/// `agreementId`, else the id at the end of its `deepLink`
/// (`/vendor/payment-plans/{id}`); with neither, the seller's plans list.
String vendorEmiPlanLocation(NotificationPayload payload) {
  var agreementId = payload.id('agreementId');
  if (agreementId == null || !_isGuid(agreementId)) {
    final link = pushDestinationUri(payload.data);
    final segments = link == null
        ? const <String>[]
        : deepLinkLocation(link).split('?').first.split('/');
    agreementId = segments.isEmpty ? null : segments.last;
  }
  return agreementId != null && _isGuid(agreementId)
      ? RouteNames.vendorEmiPlanDetailPath(agreementId)
      : RouteNames.vendorEmiPlans;
}

/// The buyer's booking, enquiry or appointment a Services notification is
/// about, or null when [payload] is not one.
///
///  * bookings contract v1 §7: buyer `booking.confirmed|reminder|cancelled|
///    refunded` (push `type` is `service_booking`), by `bookingId`, else the
///    buyer's bookings (under Orders). `booking.vendor.*` is the seller's.
///  * banks contract v1 §7: `service.appointment.*` by `appointmentId`,
///    `service.enquiry.*` by `leadId`; `service.bank.*` is the bank's.
String? servicesNotificationLocation(
  NotificationPayload payload, {
  NotificationViewer viewer = const NotificationViewer(),
}) {
  final type = payload.type;
  if (type == null) return null;

  final isBuyerBooking =
      (type.startsWith('booking.') && !type.startsWith('booking.vendor.')) ||
      (type == 'service_booking' && !viewer.onVendorSide);
  if (isBuyerBooking) {
    final id = payload.id('bookingId');
    return id != null && _isGuid(id)
        ? RouteNames.bookingDetailPath(id)
        : RouteNames.myBookings;
  }

  if (type.startsWith('service.appointment.') ||
      (type == 'service_appointment' && !viewer.onVendorSide)) {
    final id = payload.id('appointmentId');
    return id != null && _isGuid(id)
        ? RouteNames.bankAppointmentDetailPath(id)
        : RouteNames.myBankRequests;
  }

  if (type.startsWith('service.enquiry.') ||
      (type == 'service_lead' && !viewer.onVendorSide)) {
    final id = payload.id('leadId');
    return id != null && _isGuid(id)
        ? RouteNames.bankEnquiryDetailPath(id)
        : RouteNames.myBankRequests;
  }
  return null;
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
