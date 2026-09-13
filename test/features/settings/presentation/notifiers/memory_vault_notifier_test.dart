import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/memory_vault_notifier.dart';

class _MockRepository extends Mock implements MemoryVaultRepository {}

void main() {
  late _MockRepository repository;
  final memories = [
    CompanionMemory(
      id: 'a',
      content: 'Prefers size M',
      rememberedAt: DateTime(2026, 9),
      category: 'Liked',
    ),
    CompanionMemory(
      id: 'b',
      content: 'Bought: running shoes',
      rememberedAt: DateTime(2026, 9, 2),
    ),
  ];

  setUp(() {
    repository = _MockRepository();
    when(() => repository.load()).thenAnswer(
      (_) async => right(MemoryVault(paused: false, memories: memories)),
    );
  });

  Future<MemoryVaultNotifier> loaded() async {
    final notifier = MemoryVaultNotifier(repository);
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  MemoryVault vaultOf(MemoryVaultNotifier notifier) =>
      (notifier.state as MemoryVaultLoaded).vault;

  test('loads what the companion remembers', () async {
    final notifier = await loaded();
    expect(vaultOf(notifier).memories, hasLength(2));
  });

  test('a failed load offers a retry message', () async {
    when(() => repository.load()).thenAnswer(
      (_) async => left(NetworkExceptions.noInternetConnection()),
    );
    final notifier = await loaded();
    expect(notifier.state, isA<MemoryVaultFailed>());
  });

  test('forgetting a memory removes only that memory', () async {
    when(() => repository.forget('a')).thenAnswer((_) async => right(unit));
    final notifier = await loaded();

    await notifier.forget('a');

    expect(vaultOf(notifier).memories.map((m) => m.id), ['b']);
  });

  test('correcting a memory replaces its text', () async {
    when(() => repository.correct('a', 'Prefers size L')).thenAnswer(
      (_) async => right(memories.first.copyWith(content: 'Prefers size L')),
    );
    final notifier = await loaded();

    await notifier.correct('a', '  Prefers size L ');

    expect(vaultOf(notifier).memories.first.content, 'Prefers size L');
  });

  test('a failed pause keeps the old setting and explains why', () async {
    when(() => repository.setPaused(paused: true)).thenAnswer(
      (_) async => left(NetworkExceptions.noInternetConnection()),
    );
    final notifier = await loaded();

    await notifier.setPaused(paused: true);

    final state = notifier.state as MemoryVaultLoaded;
    expect(state.vault.paused, isFalse);
    expect(state.message, isNotNull);
  });

  test('forgetting everything empties the vault', () async {
    when(() => repository.forgetAll()).thenAnswer((_) async => right(unit));
    final notifier = await loaded();

    await notifier.forgetAll();

    expect(vaultOf(notifier).memories, isEmpty);
  });
}
