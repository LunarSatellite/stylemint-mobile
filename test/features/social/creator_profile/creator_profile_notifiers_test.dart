import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/repositories/creator_profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeCreatorProfileRepository implements CreatorProfileRepository {
  _FakeCreatorProfileRepository({this.shouldFail = false});

  final bool shouldFail;
  String? lastAccountIdFetched;

  static const _profile = CreatorProfile(
    id: 'acc-1',
    displayName: 'Alice',
    handle: '@alice',
    bio: 'Content creator',
    tags: ['fashion', 'lifestyle'],
    niches: ['fashion'],
    followersCount: 1000,
    partnershipsCount: 3,
    reelsCount: 12,
    likesCount: 5000,
    rowVersion: 'rv-1',
  );

  @override
  Future<NetworkEither<CreatorProfile>> getCreatorProfile(
    String accountId,
  ) async {
    lastAccountIdFetched = accountId;
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_profile);
  }

  @override
  Future<NetworkEither<CreatorProfile>> updateCreatorProfile({
    required String accountId,
    required String rowVersion,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? tags,
    List<String>? niches,
  }) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_profile);
  }

  @override
  Future<NetworkEither<List<BadgeAward>>> listMyBadges() async => right(const []);

  @override
  Future<NetworkEither<List<BadgeAward>>> updateBadgeShowcase(
    List<String> awardIdsInOrder,
  ) async =>
      right(const []);

  @override
  Future<NetworkEither<List<String>>> listSpecializationCategoryIds(
    String accountId,
  ) async =>
      right(const []);

  @override
  Future<NetworkEither<void>> addSpecialization(
    String accountId,
    String categoryId,
  ) async =>
      right(null);

  @override
  Future<NetworkEither<void>> removeSpecialization(
    String accountId,
    String categoryId,
  ) async =>
      right(null);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CreatorProfileNotifier', () {
    test('forwards accountId to repository', () async {
      final repo = _FakeCreatorProfileRepository();
      final notifier = CreatorProfileNotifier(repo, 'acc-42');
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastAccountIdFetched, 'acc-42');
    });

    test('emits loadSuccess on repository success', () async {
      final notifier = CreatorProfileNotifier(
        _FakeCreatorProfileRepository(),
        'acc-1',
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadSuccess: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier = CreatorProfileNotifier(
        _FakeCreatorProfileRepository(shouldFail: true),
        'acc-1',
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('UpdateCreatorProfileNotifier', () {
    test('starts in initial state', () {
      final notifier =
          UpdateCreatorProfileNotifier(_FakeCreatorProfileRepository());
      addTearDown(notifier.dispose);

      expect(
        notifier.state
            .maybeWhen(initial: () => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits success with updated profile on repository success', () async {
      final notifier =
          UpdateCreatorProfileNotifier(_FakeCreatorProfileRepository());
      addTearDown(notifier.dispose);
      await notifier.submit(accountId: 'acc-1', rowVersion: 'rv-1');

      expect(
        notifier.state
            .maybeWhen(success: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits failure on repository error', () async {
      final notifier = UpdateCreatorProfileNotifier(
        _FakeCreatorProfileRepository(shouldFail: true),
      );
      addTearDown(notifier.dispose);
      await notifier.submit(accountId: 'acc-1', rowVersion: 'rv-1');

      expect(
        notifier.state
            .maybeWhen(failure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

  });

  group('AvatarImageNotifier', () {
    test('starts with null path', () {
      final notifier = AvatarImageNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state, isNull);
    });

    test('setPath updates state to the given path', () {
      final notifier = AvatarImageNotifier();
      addTearDown(notifier.dispose);
      notifier.setPath('/tmp/avatar.jpg');

      expect(notifier.state, '/tmp/avatar.jpg');
    });
  });

  group('CreatorProfileEditNotifier', () {
    test('starts with empty defaults', () {
      final notifier = CreatorProfileEditNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.displayName, isEmpty);
      expect(notifier.state.bio, isEmpty);
      expect(notifier.state.tags, isEmpty);
      expect(notifier.state.niches, isEmpty);
    });

    test('seed() populates state from a loaded profile', () {
      const profile = CreatorProfile(
        id: 'acc-1',
        displayName: 'Alice',
        handle: '@alice',
        bio: 'Content creator',
        tags: ['fashion'],
        niches: ['fashion'],
        followersCount: 0,
        partnershipsCount: 0,
        reelsCount: 0,
        likesCount: 0,
        rowVersion: 'rv-1',
      );
      final notifier = CreatorProfileEditNotifier();
      addTearDown(notifier.dispose);
      notifier.seed(profile);

      expect(notifier.state.displayName, 'Alice');
      expect(notifier.state.bio, 'Content creator');
      expect(notifier.state.tags, ['fashion']);
      expect(notifier.state.niches, {'fashion'});
    });

    test('update() applies changes to state', () {
      final notifier = CreatorProfileEditNotifier();
      addTearDown(notifier.dispose);
      notifier.update(
        displayName: 'Bob',
        bio: 'Traveller',
        tags: ['travel'],
        niches: {'travel'},
      );

      expect(notifier.state.displayName, 'Bob');
      expect(notifier.state.bio, 'Traveller');
    });
  });
}
