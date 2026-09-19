import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/memory_vault_notifier.dart';

class _MockRepository extends Mock implements MemoryVaultRepository {}

MemoryConsent _legacy(MemoryPurpose purpose) => MemoryConsent(
  purpose: purpose,
  purposeCode: purpose.wireValue,
  permitted: true,
  basis: ConsentBasis.legacyGlobalPause,
  reason: 'consent.legacy_pause_basis',
  needsDecision: true,
);

MemoryConsent _undecided(MemoryPurpose purpose) =>
    MemoryConsent.undecidedFor(purpose);

void main() {
  late _MockRepository repository;

  final consents = [
    _legacy(MemoryPurpose.companionRecall),
    _legacy(MemoryPurpose.storefrontPersonalisation),
    _undecided(MemoryPurpose.recommendations),
    _undecided(MemoryPurpose.proactiveOutreach),
  ];

  setUpAll(() {
    registerFallbackValue(MemoryPurpose.companionRecall);
  });

  setUp(() {
    repository = _MockRepository();
    when(() => repository.load()).thenAnswer(
      (_) async =>
          right(MemoryVault(paused: false, memories: [], consents: consents)),
    );
    when(
      () => repository.grantConsent(
        purpose: any(named: 'purpose'),
        explanation: any(named: 'explanation'),
      ),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.revokeConsent(any()),
    ).thenAnswer((_) async => right(unit));
    when(
      () => repository.loadConsents(),
    ).thenAnswer((_) async => right(consents));
  });

  Future<MemoryVaultNotifier> loaded() async {
    final notifier = MemoryVaultNotifier(repository);
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  MemoryVault vaultOf(MemoryVaultNotifier notifier) =>
      (notifier.state as MemoryVaultLoaded).vault;

  ConsentStanding standing(
    MemoryVaultNotifier notifier,
    MemoryPurpose purpose,
  ) => vaultOf(notifier).consentFor(purpose).standing;

  test('nothing arrives pre-granted', () async {
    final notifier = await loaded();

    expect(
      standing(notifier, MemoryPurpose.recommendations),
      ConsentStanding.undecided,
    );
    expect(
      standing(notifier, MemoryPurpose.proactiveOutreach),
      ConsentStanding.undecided,
    );
    for (final purpose in MemoryPurpose.values) {
      expect(
        vaultOf(notifier).consentFor(purpose).basis,
        isNot(ConsentBasis.purposeGrant),
      );
    }
  });

  test('each purpose grants on its own, with its own explanation', () async {
    final notifier = await loaded();

    await notifier.grantPurpose(
      MemoryPurpose.recommendations,
      MemoryPurposeCopy.explanationOf(MemoryPurpose.recommendations),
    );

    verify(
      () => repository.grantConsent(
        purpose: MemoryPurpose.recommendations,
        explanation: MemoryPurposeCopy.explanationOf(
          MemoryPurpose.recommendations,
        ),
      ),
    ).called(1);
    expect(
      standing(notifier, MemoryPurpose.recommendations),
      ConsentStanding.granted,
    );
    // The other three are untouched.
    expect(
      standing(notifier, MemoryPurpose.proactiveOutreach),
      ConsentStanding.undecided,
    );
    expect(
      standing(notifier, MemoryPurpose.companionRecall),
      ConsentStanding.legacyBasis,
    );
  });

  test('each purpose revokes on its own, by its own code', () async {
    final notifier = await loaded();

    await notifier.revokePurpose(MemoryPurpose.proactiveOutreach.wireValue);

    verify(() => repository.revokeConsent(4)).called(1);
    expect(
      standing(notifier, MemoryPurpose.proactiveOutreach),
      ConsentStanding.refused,
    );
    expect(
      standing(notifier, MemoryPurpose.recommendations),
      ConsentStanding.undecided,
      reason: 'refusing one purpose must not answer another',
    );
  });

  test('refusing is one step even where nothing was granted', () async {
    final notifier = await loaded();

    await notifier.revokePurpose(MemoryPurpose.recommendations.wireValue);

    expect(
      standing(notifier, MemoryPurpose.recommendations),
      ConsentStanding.refused,
      reason: 'undecided must be answerable with a plain no',
    );
  });

  test('a failed grant reverts instead of showing a yes', () async {
    final notifier = await loaded();
    when(
      () => repository.grantConsent(
        purpose: any(named: 'purpose'),
        explanation: any(named: 'explanation'),
      ),
    ).thenAnswer(
      (_) async => left(const NetworkExceptions.noInternetConnection()),
    );

    await notifier.grantPurpose(
      MemoryPurpose.recommendations,
      MemoryPurposeCopy.explanationOf(MemoryPurpose.recommendations),
    );

    expect(
      standing(notifier, MemoryPurpose.recommendations),
      ConsentStanding.undecided,
      reason: 'the server never took this, so the screen must not show it',
    );
    expect((notifier.state as MemoryVaultLoaded).message, isNotNull);
  });

  test('a failed withdrawal reverts too', () async {
    final notifier = await loaded();
    when(
      () => repository.revokeConsent(any()),
    ).thenAnswer((_) async => left(const NetworkExceptions.unexpectedError()));

    await notifier.revokePurpose(MemoryPurpose.companionRecall.wireValue);

    expect(
      standing(notifier, MemoryPurpose.companionRecall),
      ConsentStanding.legacyBasis,
    );
    expect((notifier.state as MemoryVaultLoaded).message, isNotNull);
  });

  test('a purpose this build cannot name is still revocable', () async {
    when(() => repository.load()).thenAnswer(
      (_) async => right(
        const MemoryVault(
          paused: false,
          memories: [],
          consents: [
            MemoryConsent(
              purposeCode: 99,
              permitted: false,
              basis: ConsentBasis.none,
              reason: 'consent.undecided',
              needsDecision: true,
            ),
          ],
        ),
      ),
    );
    final notifier = await loaded();

    expect(vaultOf(notifier).unknownConsents, hasLength(1));
    await notifier.revokePurpose(99);

    verify(() => repository.revokeConsent(99)).called(1);
  });

  test('resuming re-reads the answers the pause was hiding', () async {
    when(() => repository.load()).thenAnswer(
      (_) async =>
          right(MemoryVault(paused: true, memories: [], consents: consents)),
    );
    when(
      () => repository.setPaused(paused: any(named: 'paused')),
    ).thenAnswer((_) async => right(unit));
    final notifier = await loaded();

    await notifier.setPaused(paused: false);

    verify(() => repository.loadConsents()).called(1);
    expect(vaultOf(notifier).paused, isFalse);
  });

  test('pausing does not go looking for answers it cannot see', () async {
    when(
      () => repository.setPaused(paused: any(named: 'paused')),
    ).thenAnswer((_) async => right(unit));
    final notifier = await loaded();

    await notifier.setPaused(paused: true);

    verifyNever(() => repository.loadConsents());
    expect(vaultOf(notifier).paused, isTrue);
  });
}
