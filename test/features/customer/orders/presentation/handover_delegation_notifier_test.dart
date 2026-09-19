import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/handover_delegation_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/handover_delegation_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_copy.dart';

class _MockDataSource extends Mock implements HandoverDelegationDataSource {}

const _tracking = 'SM-D-00000001';
final DateTime _now = DateTime.utc(2026, 9, 19, 12);

HandoverDelegation _delegation({
  String id = 'del-1',
  HandoverDelegationStatus status = HandoverDelegationStatus.active,
  DateTime? start,
  DateTime? end,
}) => HandoverDelegation(
  id: id,
  trackingNumber: _tracking,
  delegateDisplayName: 'Amina',
  relationship: DelegateRelationship.neighbour,
  allowedExceptions: const <DelegatedException>{},
  windowStartUtc: start ?? _now,
  windowEndUtc: end ?? _now.add(const Duration(hours: 4)),
  status: status,
  createdUtc: _now,
);

DioException _refusal(String errorCode) {
  final request = RequestOptions(path: '/v1/deliveries/$_tracking');
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: 409,
      data: <String, dynamic>{'errorCode': errorCode},
    ),
  );
}

void main() {
  late _MockDataSource dataSource;

  HandoverDelegationNotifier build() => HandoverDelegationNotifier(
    dataSource: dataSource,
    trackingNumber: _tracking,
    clock: () => _now,
  );

  setUp(() => dataSource = _MockDataSource());

  test('the state type has no place to put a verification code', () {
    // Enforced structurally: `HandoverDelegation` carries no code, so a
    // provider that outlives the screen cannot hold one even by mistake.
    const state = HandoverDelegationState();
    expect(state.delegations, isEmpty);
    expect(state.failure, isNull);
  });

  test('load splits the live one from the finished ones', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [
        _delegation(id: 'used', status: HandoverDelegationStatus.consumed),
        _delegation(id: 'live'),
        _delegation(id: 'gone', status: HandoverDelegationStatus.revoked),
      ],
    );
    final notifier = build();
    await notifier.load();
    expect(notifier.state.activeAt(_now)!.id, 'live');
    expect(
      notifier.state.historyAt(_now).map((d) => d.id),
      containsAll(<String>['used', 'gone']),
    );
  });

  test('an active row whose window closed is not treated as active', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [
        _delegation(
          start: _now.subtract(const Duration(hours: 6)),
          end: _now.subtract(const Duration(hours: 1)),
        ),
      ],
    );
    final notifier = build();
    await notifier.load();
    expect(notifier.state.activeAt(_now), isNull);
    expect(notifier.state.historyAt(_now), hasLength(1));
  });

  test('revoke succeeds and replaces the row in place', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [_delegation()],
    );
    when(
      () => dataSource.revoke(
        trackingNumber: any(named: 'trackingNumber'),
        delegationId: any(named: 'delegationId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer(
      (_) async => _delegation(status: HandoverDelegationStatus.revoked),
    );

    final notifier = build();
    await notifier.load();
    expect(await notifier.revoke('del-1'), isTrue);
    expect(notifier.state.activeAt(_now), isNull);
    expect(notifier.state.lastRevoked, isNotNull);
    expect(notifier.state.isRevoking, isFalse);
  });

  test('a retried revoke reuses one idempotency key', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [_delegation()],
    );
    final keys = <String>[];
    when(
      () => dataSource.revoke(
        trackingNumber: any(named: 'trackingNumber'),
        delegationId: any(named: 'delegationId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((invocation) async {
      keys.add(invocation.namedArguments[#idempotencyKey] as String);
      throw _refusal('unreachable');
    });

    final notifier = build();
    await notifier.load();
    await notifier.revoke('del-1');
    await notifier.revoke('del-1');
    expect(keys, hasLength(2));
    expect(keys.first, keys.last, reason: 'one attempt, one key');
  });

  test('a refused revoke keeps its message through the re-read', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [_delegation(status: HandoverDelegationStatus.consumed)],
    );
    when(
      () => dataSource.revoke(
        trackingNumber: any(named: 'trackingNumber'),
        delegationId: any(named: 'delegationId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        reason: any(named: 'reason'),
      ),
    ).thenThrow(_refusal(HandoverCopy.codeAlreadyUsed));

    final notifier = build();
    await notifier.load();
    expect(await notifier.revoke('del-1'), isFalse);
    // The reload that follows must not wipe the explanation.
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.failure, HandoverCopy.codeAlreadyUsed);
  });

  test('a failed background read stays quiet', () async {
    // The card appears unprompted, so a read nobody asked for must not put a
    // red box on the order screen.
    when(() => dataSource.list(_tracking)).thenThrow(Exception('offline'));
    final notifier = build();
    await notifier.load();
    expect(notifier.state.loadFailed, isTrue);
    expect(notifier.state.failure, isNull);
    expect(notifier.state.loaded, isTrue);
  });

  test('a transport failure on an action gets its own sentinel', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [_delegation()],
    );
    when(
      () => dataSource.revoke(
        trackingNumber: any(named: 'trackingNumber'),
        delegationId: any(named: 'delegationId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        reason: any(named: 'reason'),
      ),
    ).thenThrow(Exception('offline'));
    final notifier = build();
    await notifier.load();
    expect(await notifier.revoke('del-1'), isFalse);
    expect(notifier.state.failure, kHandoverTransportFailure);
    expect(
      HandoverCopy.refusal(kHandoverTransportFailure).body,
      contains('was not created'),
    );
  });

  test('refresh takes no delegation argument', () async {
    // The signature is the guarantee: the sheet cannot hand this notifier the
    // issued object, so the code has no route into provider scope.
    when(() => dataSource.list(_tracking)).thenAnswer((_) async => []);
    final notifier = build();
    await notifier.refresh();
    verify(() => dataSource.list(_tracking)).called(1);
  });

  test('one revoke at a time', () async {
    when(() => dataSource.list(_tracking)).thenAnswer(
      (_) async => [_delegation(), _delegation(id: 'del-2')],
    );
    var calls = 0;
    when(
      () => dataSource.revoke(
        trackingNumber: any(named: 'trackingNumber'),
        delegationId: any(named: 'delegationId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _delegation(status: HandoverDelegationStatus.revoked);
    });

    final notifier = build();
    await notifier.load();
    final first = notifier.revoke('del-1');
    final second = notifier.revoke('del-2');
    await Future.wait(<Future<bool>>[first, second]);
    expect(
      calls,
      1,
      reason: 'the second tap is ignored while one is in flight',
    );
  });
}
