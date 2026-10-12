import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/models/notification_dispatch_dto.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/presentation/screens/recent_activity_screen.dart';
import 'package:stylemint_mobile_frontend/features/notifications/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

const _orderId = '3f2b8a1c-0d4e-4f5a-9b6c-7d8e9f0a1b2c';
const _subOrderId = 'aa11bb22-cc33-4d44-8e55-ff6677889900';

ActivityItem _row(String id, String templateKey, Map<String, dynamic> vars) =>
    NotificationDispatchDto.fromJson({
      'id': id,
      'templateKey': templateKey,
      'category': 2,
      'variablesJson': jsonEncode(vars),
      'queuedUtc': DateTime.now().toUtc().toIso8601String(),
    }).toDomain();

void main() {
  late _MockTokenStorage tokens;

  setUp(() {
    tokens = _MockTokenStorage();
    when(() => tokens.accessToken).thenAnswer((_) async => null);
  });

  Future<void> pumpInbox(WidgetTester tester, List<ActivityItem> rows) async {
    final router = GoRouter(
      initialLocation: RouteNames.customerRecentActivity,
      routes: [
        GoRoute(
          path: RouteNames.customerRecentActivity,
          builder: (_, _) =>
              const RecentActivityScreen(source: RecentActivitySource.inbox),
        ),
        GoRoute(
          path: RouteNames.orderDetail,
          builder: (_, state) =>
              Text('Order page ${state.pathParameters['orderId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationInboxProvider.overrideWith((ref) async => rows),
          tokenStorageProvider.overrideWithValue(tokens),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an "order packed" row opens that order', (
    tester,
  ) async {
    await pumpInbox(tester, [
      _row('n1', 'order.packed', {
        'orderNumber': _subOrderId,
        'orderId': _orderId,
        'subOrderId': _subOrderId,
      }),
    ]);

    expect(find.text('Your order is packed and ready'), findsOneWidget);
    await tester.tap(find.text('Your order is packed and ready'));
    await tester.pumpAndSettle();

    expect(find.text('Order page $_orderId'), findsOneWidget);
  });

  testWidgets('an order row with a real order number opens it by number', (
    tester,
  ) async {
    await pumpInbox(tester, [
      _row('n2', 'order.placed', {
        'orderNumber': 'SM-2026-7',
        'orderId': _orderId,
      }),
    ]);

    await tester.tap(find.text('Your order was placed'));
    await tester.pumpAndSettle();

    expect(find.text('Order page SM-2026-7'), findsOneWidget);
  });

  testWidgets('a row about nothing in particular opens nothing', (
    tester,
  ) async {
    await pumpInbox(tester, [
      _row('n3', 'comment.reply', {'title': 'Asha replied to you'}),
    ]);

    await tester.tap(find.text('Asha replied to you'));
    await tester.pumpAndSettle();

    expect(find.text('Asha replied to you'), findsOneWidget);
    expect(find.textContaining('Order page'), findsNothing);
  });

  test('the inbox DTO keeps the template key and variables for routing', () {
    final item = _row('n4', 'order.shipped.inapp', {'orderId': _orderId});
    expect(item.templateKey, 'order.shipped.inapp');
    expect(jsonDecode(item.variablesJson!), {'orderId': _orderId});
    expect(item.title, 'Your order is on its way');
    expect(activityItemOpens(item), isTrue);
  });

  test('a payment-plan row has a real title and opens the plan', () {
    const agreementId = 'b7c1d2e3-f405-4617-8829-3a4b5c6d7e8f';
    final item = _row('n5', 'plan.reminder.overdue.inapp', {
      'data.deepLink': '/payment-plans/$agreementId',
      'amount': '8000.00',
    });
    expect(item.title, 'A payment plan instalment is overdue');
    expect(activityItemOpens(item), isTrue);
    expect(
      _row('n6', 'plan.defaulted.inapp', {'daysPastDue': '90'}).title,
      'Your payment plan was closed',
    );
  });

  test('a creator activity row (no template) opens nothing', () {
    const item = ActivityItem(
      id: 'a1',
      title: 'Reel published',
      occurredAt: null,
      isRead: false,
    );
    expect(activityItemOpens(item), isFalse);
  });
}
