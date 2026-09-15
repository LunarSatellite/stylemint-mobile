import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/last_import_platform_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

SocialAccount _account(SocialPlatform platform, {bool connected = true}) =>
    SocialAccount(
      id: platform.name,
      platform: platform,
      handle: '@creator',
      username: 'creator',
      displayName: 'Creator',
      avatarUrl: '',
      followerCount: 0,
      isConnected: connected,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastImportPlatformNotifier', () {
    test('restores null when nothing was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = LastImportPlatformNotifier();

      expect(await notifier.restored, isNull);
      expect(notifier.state, isNull);
    });

    test('persists the chosen platform for the next launch', () async {
      SharedPreferences.setMockInitialValues({});
      final first = LastImportPlatformNotifier();
      await first.restored;

      await first.setPlatform(SocialPlatform.tiktok);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(lastImportPlatformKey), 'tiktok');

      final next = LastImportPlatformNotifier();
      expect(await next.restored, SocialPlatform.tiktok);
      expect(next.state, SocialPlatform.tiktok);
    });

    test('ignores an unknown saved value', () async {
      SharedPreferences.setMockInitialValues({
        lastImportPlatformKey: 'myspace',
      });
      final notifier = LastImportPlatformNotifier();

      expect(await notifier.restored, isNull);
    });

    test('a choice made while restoring wins over the saved value', () async {
      SharedPreferences.setMockInitialValues({lastImportPlatformKey: 'tiktok'});
      final notifier = LastImportPlatformNotifier();

      final choice = notifier.setPlatform(SocialPlatform.youtube);
      final restored = await notifier.restored;
      await choice;

      expect(restored, SocialPlatform.youtube);
      expect(notifier.state, SocialPlatform.youtube);
    });
  });

  group('resolveImportPlatform', () {
    test('uses the saved platform first', () {
      expect(
        resolveImportPlatform(
          saved: SocialPlatform.facebook,
          accounts: [_account(SocialPlatform.tiktok)],
        ),
        SocialPlatform.facebook,
      );
    });

    test('falls back to the first connected account', () {
      expect(
        resolveImportPlatform(
          accounts: [
            _account(SocialPlatform.instagram, connected: false),
            _account(SocialPlatform.youtube),
            _account(SocialPlatform.tiktok),
          ],
        ),
        SocialPlatform.youtube,
      );
    });

    test('falls back to Instagram when nothing is connected', () {
      expect(resolveImportPlatform(), SocialPlatform.instagram);
      expect(
        resolveImportPlatform(
          accounts: [_account(SocialPlatform.tiktok, connected: false)],
        ),
        SocialPlatform.instagram,
      );
    });
  });
}
