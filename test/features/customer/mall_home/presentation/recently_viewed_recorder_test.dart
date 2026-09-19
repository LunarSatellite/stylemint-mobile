import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/recently_viewed_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

/// Counts every write that reaches the data layer. The point of most tests
/// below is that this stays at zero.
class _FakeMallHomeRepository implements MallHomeRepository {
  final List<String> recorded = <String>[];

  @override
  Future<Either<NetworkExceptions, Unit>> recordRecentlyViewed(
    String productId,
  ) async {
    recorded.add(productId);
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, MallHome>> getHome() =>
      throw UnimplementedError();
}

/// A repository whose write always fails, to prove a failed call is still
/// swallowed rather than surfaced.
class _ThrowingMallHomeRepository implements MallHomeRepository {
  int calls = 0;

  @override
  Future<Either<NetworkExceptions, Unit>> recordRecentlyViewed(
    String productId,
  ) async {
    calls++;
    throw StateError('network down');
  }

  @override
  Future<Either<NetworkExceptions, MallHome>> getHome() =>
      throw UnimplementedError();
}

class _FakeVaultRepository implements MemoryVaultRepository {
  _FakeVaultRepository({
    this.paused = false,
    List<MemoryConsent>? consents,
    bool consentsUnreadable = false,
    this.pauseUnreadable = false,
  }) : consents = consentsUnreadable
           ? null
           : (consents ??
                 [MemoryConsent.grantedFor(
                   MemoryPurpose.storefrontPersonalisation,
                 )]);

  bool paused;
  bool pauseUnreadable;

  /// Null means `GET /memories/consents` failed — an unreadable decision,
  /// which is not an answer.
  List<MemoryConsent>? consents;

  @override
  Future<Either<NetworkExceptions, bool>> isPaused() async => pauseUnreadable
      ? left(const NetworkExceptions.serverUnavailable())
      : right(paused);

  @override
  Future<Either<NetworkExceptions, List<MemoryConsent>>> loadConsents() async {
    final rows = consents;
    return rows == null
        ? left(const NetworkExceptions.serverUnavailable())
        : right(rows);
  }

  @override
  Future<Either<NetworkExceptions, MemoryVault>> load() async =>
      right(MemoryVault(paused: paused, memories: const []));

  @override
  Future<Either<NetworkExceptions, CompanionMemory>> correct(
    String memoryId,
    String content,
  ) => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> forget(String memoryId) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> forgetAll() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> setPaused({required bool paused}) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> grantConsent({
    required MemoryPurpose purpose,
    required String explanation,
  }) => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> revokeConsent(int purposeCode) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, String>> export() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, int>> importPortableTwin(
    String bundleJson,
  ) => throw UnimplementedError();
}

class _InertStorefrontRepository implements AdaptiveStorefrontRepository {
  @override
  Future<StorefrontLayout> getLayout() async => StorefrontLayout.none;

  @override
  Future<void> trackInteraction(FeedSignal signal) async {}
}

void main() {
  const productId = 'prod-1';

  RecentlyViewedRecorder build(
    MallHomeRepository repository, {
    bool signedIn = true,
    bool paused = false,
    bool pauseUnreadable = false,
    List<MemoryConsent>? consents,
    bool consentsUnreadable = false,
  }) => RecentlyViewedRecorder(
    repository,
    StorefrontPersonalizer(
      storefront: _InertStorefrontRepository(),
      vault: _FakeVaultRepository(
        paused: paused,
        pauseUnreadable: pauseUnreadable,
        consents: consents,
        consentsUnreadable: consentsUnreadable,
      ),
      isSignedIn: () => signedIn,
    ),
  );

  /// The recorder is fire-and-forget, so the write lands a microtask later.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('RecentlyViewedRecorder gates the write, not the render', () {
    test('a granted storefront purpose records the view', () async {
      final repository = _FakeMallHomeRepository();
      build(repository).record(productId);
      await settle();

      expect(repository.recorded, [productId]);
    });

    test('a refused purpose never reaches the datasource', () async {
      final repository = _FakeMallHomeRepository();
      build(
        repository,
        consents: [
          MemoryConsent.refusedFor(
            MemoryPurpose.storefrontPersonalisation.wireValue,
          ),
        ],
      ).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test('an undecided purpose never reaches the datasource', () async {
      final repository = _FakeMallHomeRepository();
      build(
        repository,
        consents: [
          MemoryConsent.undecidedFor(MemoryPurpose.storefrontPersonalisation),
        ],
      ).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test(
      'a purpose the backend did not report is not consent',
      () async {
        final repository = _FakeMallHomeRepository();
        build(repository, consents: const []).record(productId);
        await settle();

        expect(repository.recorded, isEmpty);
      },
    );

    test('an unreadable consent list never reaches the datasource', () async {
      final repository = _FakeMallHomeRepository();
      build(repository, consentsUnreadable: true).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test('an unreadable global pause never reaches the datasource', () async {
      final repository = _FakeMallHomeRepository();
      build(repository, pauseUnreadable: true).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test(
      'the global pause overrides a granted purpose',
      () async {
        final repository = _FakeMallHomeRepository();
        build(
          repository,
          paused: true,
          consents: [
            MemoryConsent.grantedFor(MemoryPurpose.storefrontPersonalisation),
          ],
        ).record(productId);
        await settle();

        expect(repository.recorded, isEmpty);
      },
    );

    test('a guest never reaches the datasource', () async {
      final repository = _FakeMallHomeRepository();
      build(repository, signedIn: false).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test('a consent granted only for another purpose is not consent', () async {
      final repository = _FakeMallHomeRepository();
      build(
        repository,
        consents: [MemoryConsent.grantedFor(MemoryPurpose.companionRecall)],
      ).record(productId);
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test('a blank product id is dropped before the gate', () async {
      final repository = _FakeMallHomeRepository();
      build(repository).record('   ');
      await settle();

      expect(repository.recorded, isEmpty);
    });

    test('a failing write is swallowed, not surfaced', () async {
      final repository = _ThrowingMallHomeRepository();
      build(repository).record(productId);
      await settle();

      expect(repository.calls, 1);
    });
  });
}
