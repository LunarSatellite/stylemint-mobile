import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';

class _FakeRepository implements SocialConnectRepository {
  _FakeRepository({this.accounts, this.disconnectResult});

  NetworkEither<List<SocialAccount>>? accounts;
  NetworkEither<Unit>? disconnectResult;

  int loadCalls = 0;
  int disconnectCalls = 0;

  @override
  Future<NetworkEither<List<SocialAccount>>> getConnectedAccounts() async {
    loadCalls++;
    return accounts ?? networkRight([_account()]);
  }

  @override
  Future<NetworkEither<SocialAuthorization>> beginConnect(
    SocialPlatform platform,
  ) async =>
      networkRight(
        const SocialAuthorization(authorizationUrl: 'https://x', state: 's'),
      );

  @override
  Future<NetworkEither<Unit>> disconnectPlatform(
    SocialPlatform platform,
  ) async {
    disconnectCalls++;
    return disconnectResult ?? networkRight(unit);
  }
}

SocialAccount _account({
  SocialPlatform platform = SocialPlatform.instagram,
}) =>
    SocialAccount(
      id: 'a1',
      platform: platform,
      handle: 'creator',
      username: 'creator',
      displayName: 'Creator',
      avatarUrl: '',
      followerCount: 100,
      isConnected: true,
    );

/// The notifier kicks off a load from its constructor, so settle that before
/// asserting on anything.
Future<SocialConnectNotifier> _settled(_FakeRepository repo) async {
  final notifier = SocialConnectNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('SocialConnectNotifier', () {
    test('loads connected accounts on construction', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      expect(repo.loadCalls, 1);
      expect(notifier.state, isA<SocialConnectState>());
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (accounts) => accounts.length,
          orElse: () => -1,
        ),
        1,
      );
    });

    test('a load failure is surfaced rather than shown as empty', () async {
      final repo = _FakeRepository(
        accounts: networkLeft(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = await _settled(repo);

      expect(
        notifier.state.maybeWhen(
          loadFailure: (failure) => NetworkExceptions.getMessage(failure),
          orElse: () => null,
        ),
        'No internet connection.',
      );
    });

    test('a successful disconnect refreshes the account list', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      await notifier.disconnect(SocialPlatform.instagram);
      await Future<void>.delayed(Duration.zero);

      expect(repo.disconnectCalls, 1);
      expect(repo.loadCalls, 2, reason: 'reloads after a successful disconnect');
    });

    test('a failed disconnect does not refresh or clear the list', () async {
      final repo = _FakeRepository(
        disconnectResult:
            networkLeft(const NetworkExceptions.unexpectedError()),
      );
      final notifier = await _settled(repo);

      await notifier.disconnect(SocialPlatform.instagram);
      await Future<void>.delayed(Duration.zero);

      expect(repo.disconnectCalls, 1);
      expect(repo.loadCalls, 1, reason: 'no reload when the disconnect failed');
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (accounts) => accounts.length,
          orElse: () => -1,
        ),
        1,
        reason: 'the previously loaded accounts must survive',
      );
    });

    test('load() can be called again to refresh', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      await notifier.load();

      expect(repo.loadCalls, 2);
    });
  });
}
