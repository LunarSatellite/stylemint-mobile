import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';

class _OrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late _OrdersRepository repository;

  setUp(() => repository = _OrdersRepository());

  test('loads disabled when the customer has not opted in', () async {
    when(repository.getReplenishmentPreference).thenAnswer(
      (_) async => right(false),
    );

    final notifier = ReplenishmentPreferenceNotifier(repository);
    await Future<void>.delayed(Duration.zero);

    final state = notifier.state as ReplenishmentPreferenceLoaded;
    expect(state.enabled, isFalse);
    expect(state.saving, isFalse);
  });

  test('persists an explicit opt in', () async {
    when(repository.getReplenishmentPreference).thenAnswer(
      (_) async => right(false),
    );
    when(() => repository.setReplenishmentPreference(true)).thenAnswer(
      (_) async => right(true),
    );
    final notifier = ReplenishmentPreferenceNotifier(repository);
    await Future<void>.delayed(Duration.zero);

    expect(await notifier.setEnabled(true), isTrue);
    expect((notifier.state as ReplenishmentPreferenceLoaded).enabled, isTrue);
    verify(() => repository.setReplenishmentPreference(true)).called(1);
  });

  test('restores the previous choice when saving fails', () async {
    when(repository.getReplenishmentPreference).thenAnswer(
      (_) async => right(true),
    );
    when(() => repository.setReplenishmentPreference(false)).thenAnswer(
      (_) async => left(const NetworkExceptions.server('unavailable')),
    );
    final notifier = ReplenishmentPreferenceNotifier(repository);
    await Future<void>.delayed(Duration.zero);

    expect(await notifier.setEnabled(false), isFalse);
    expect((notifier.state as ReplenishmentPreferenceLoaded).enabled, isTrue);
  });
}
