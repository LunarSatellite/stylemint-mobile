import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/buy_it_again_section.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../smoke/fake_api_client.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockFollowApi extends Mock implements FollowApi {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _SignedInSession extends SessionController {
  _SignedInSession()
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
        followNotifier: FollowNotifier(_MockFollowApi()),
      ) {
    state = const AuthSessionState.authenticated('viewer-1');
  }
}

const _summary = ProfileSummary(
  displayName: 'Asha',
  email: 'asha@example.com',
  avatarUrl: '',
  savedItemsCount: 0,
  followingCount: 0,
  ordersCount: 0,
  language: 'English',
  pushEnabled: false,
);

/// Pausing personalisation used to be a one-way door.
///
/// Every link to the Memory Vault a shopper could actually reach sat behind
/// personalizationAllowedProvider: the Buy-It-Again rail on Your Orders, and
/// the three restock screens it is the only route to, whose Open Memory Vault
/// action lives in a paused-state view the rail hides on the way in. The
/// fourth link is the settings hub, which only the vendor and creator menus
/// open. So the moment a customer paused, the switch that unpauses it went
/// with the rail.
///
/// This pumps the real screens with personalisation paused and walks the
/// rendered tree, because the bug was never in any one screen source - it was
/// in what a shopper could get to from where they were standing.
void main() {
  late _MockProfileRepository profile;

  setUp(() {
    profile = _MockProfileRepository();
    when(profile.getProfileSummary).thenAnswer((_) async => right(_summary));
    when(
      () => profile.getProfileStats(_summary),
    ).thenAnswer((_) async => right(_summary));
  });

  /// The root is the screen under test; the vault is a stub, so arriving at
  /// it is proof the tap routed there, not merely that a tile was drawn.
  Widget app(Widget home) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: RouteNames.settingsMemory,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('the memory vault'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        profileRepositoryProvider.overrideWithValue(profile),
        sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
        // The pause itself: the state in which every other route to the
        // vault disappears.
        personalizationAllowedProvider.overrideWith((ref) async => false),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(app(home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a paused shopper can still open the Memory Vault', (
    tester,
  ) async {
    await pump(tester, const ProfileScreen());

    final tile = find.text('Your StyleMint Memory');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tile, findsOneWidget);

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('the memory vault'), findsOneWidget);
  });

  testWidgets('the restock surface, the other route, is gone while paused', (
    tester,
  ) async {
    await pump(tester, const Scaffold(body: BuyItAgainSection()));

    // Not a regression to fix: a rail that could only say paused is right to
    // draw nothing, and so is the entry row under it. That is exactly why
    // the Profile tile has to exist.
    expect(find.byKey(const ValueKey('restock-entry')), findsNothing);
    expect(find.byKey(const ValueKey('restock-see-all')), findsNothing);
  });
}
